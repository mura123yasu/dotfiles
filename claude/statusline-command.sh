#!/usr/bin/env bash
# Claude Code status line — mirrors Starship prompt style
# Colors from starship.toml: #3B4252 (dir bg), #5E81AC (git bg), #E5E9F0 (dir fg), #ECEFF4 (git fg)
# Segment layout:
#   [Dir] [Branch[*]] [Context %] [Session %] [Model (effort)] [Time]
#
# Segments are packed into as many rows as needed to fit $COLUMNS, so nothing
# is clipped on narrow terminals. Claude Code renders each printed line as its
# own status row and exports COLUMNS/LINES before running this script
# (requires Claude Code v2.1.153+).

# ${#var} counts characters only under a UTF-8 locale; force one if absent so
# multibyte paths/branches don't blow up the width math.
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *UTF-8*|*utf-8*|*utf8*) ;;
  *) export LC_ALL=en_US.UTF-8 ;;
esac

input=$(cat)

# --- Extract fields ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
session_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
current_time=$(date +%H:%M)

# --- Effort level: .effort.level is the live session value (survives /effort) ---
effort_raw=$(echo "$input" | jq -r '(.effort.level // .effortLevel // .thinking.effort // empty)' 2>/dev/null)
if [ -z "$effort_raw" ] && [ -f "$HOME/.claude/settings.json" ]; then
  effort_raw=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
fi
# absent = auto
[ -z "$effort_raw" ] && effort_raw="auto"
effort_label=" [${effort_raw}]"

# --- Directory (truncate to 3 path components, like starship) ---
home_replaced="${cwd/#$HOME/\~}"
IFS='/' read -ra parts <<EOF
$home_replaced
EOF
total=${#parts[@]}
if [ "$total" -gt 4 ]; then
  dir_display="…/${parts[$((total-3))]}/${parts[$((total-2))]}/${parts[$((total-1))]}"
else
  dir_display="$home_replaced"
fi

# --- Git branch ---
git_branch=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# --- Git dirty state ---
git_dirty=""
if [ -n "$git_branch" ] && [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ]; then
  git_dirty="*"
fi

# --- Helper: remaining time label from unix epoch resets_at ---
make_reset_label() {
  resets_at="$1"
  [ -z "$resets_at" ] && return
  now=$(date +%s)
  remaining=$(( resets_at - now ))
  [ "$remaining" -le 0 ] && return
  h=$(( remaining / 3600 ))
  m=$(( (remaining % 3600) / 60 ))
  if [ "$h" -gt 0 ] && [ "$m" -gt 0 ]; then
    printf " %dh%dm" "$h" "$m"
  elif [ "$h" -gt 0 ]; then
    printf " %dh" "$h"
  else
    printf " %dm" "$m"
  fi
}

# --- Helper: 10-cell progress bar (█ / ░) ---
make_bar() {
  pct="$1"
  cells=10
  filled=$(printf "%.0f" "$(echo "$pct $cells" | awk '{printf "%.6f", $1 / 100 * $2}')")
  bar=""
  i=0
  while [ "$i" -lt "$cells" ]; do
    if [ "$i" -lt "$filled" ]; then
      bar="${bar}█"
    else
      bar="${bar}░"
    fi
    i=$((i + 1))
  done
  printf "%s" "$bar"
}

# --- Segment palette (Nord + Catppuccin), as "R;G;B" triples ---
RGB_DIR_BG="59;66;82"       # #3B4252
RGB_DIR_FG="229;233;240"    # #E5E9F0
RGB_GIT_BG="94;129;172"     # #5E81AC
RGB_GIT_FG="236;239;244"    # #ECEFF4
RGB_CTX_BG="163;190;140"    # #A3BE8C
RGB_SES_BG="235;203;139"    # #EBCB8B
RGB_MODEL_BG="137;180;250"  # #89B4FA
RGB_TIME_BG="180;142;173"   # #B48EAD
RGB_DARK_FG="35;38;46"
RGB_MODEL_FG="30;30;46"

RESET="\033[0m"

# --- Display width of user-supplied text (paths, branch names) ---
# Codepoint inspection is unreliable on bash 3.2, so approximate instead:
# every extra UTF-8 byte beyond the character count means one continuation
# byte, and CJK/kana/fullwidth characters (3 bytes, 2 cells) dominate here.
# Over-estimating only causes an earlier wrap, which is the safe direction.
disp_width() {
  local s="$1" chars bytes
  chars=${#s}
  bytes=$(printf '%s' "$s" | wc -c)
  bytes=${bytes//[^0-9]/}
  echo $(( chars + (bytes - chars) / 2 ))
}

# --- Collect segments ---
seg_text=()
seg_bg=()
seg_fg=()
seg_w=()
# add_seg <text> <bg> <fg> [display_width]
# Width defaults to the character count, which is exact for the ASCII and
# box-drawing text this script generates itself.
add_seg() {
  seg_text+=("$1")
  seg_bg+=("$2")
  seg_fg+=("$3")
  seg_w+=("${4:-${#1}}")
}

add_seg "$dir_display" "$RGB_DIR_BG" "$RGB_DIR_FG" "$(disp_width "$dir_display")"

if [ -n "$git_branch" ]; then
  branch_display="${git_branch}${git_dirty}"
  add_seg "$branch_display" "$RGB_GIT_BG" "$RGB_GIT_FG" "$(disp_width "$branch_display")"
fi

if [ -n "$used_pct" ]; then
  ctx_display="$(printf "%.0f" "$used_pct")%ctx $(make_bar "$used_pct")"
else
  ctx_display="ctx ░░░░░░░░░░"
fi
add_seg "$ctx_display" "$RGB_CTX_BG" "$RGB_DARK_FG"

if [ -n "$session_pct" ]; then
  ses_display="$(printf "%.0f" "$session_pct")%ses $(make_bar "$session_pct")$(make_reset_label "$session_resets_at")"
else
  ses_display="ses ░░░░░░░░░░"
fi
add_seg "$ses_display" "$RGB_SES_BG" "$RGB_DARK_FG"

add_seg "${model}${effort_label}" "$RGB_MODEL_BG" "$RGB_MODEL_FG"
add_seg "$current_time" "$RGB_TIME_BG" "$RGB_DARK_FG"

# --- Pack segments into rows that fit the terminal ---
# Width per segment: 1 leading separator (except first in row) + space + text + space.
# Each row also ends with 1 trailing separator .
cols=${COLUMNS:-80}
case "$cols" in
  ''|*[!0-9]*) cols=80 ;;
esac
[ "$cols" -lt 20 ] && cols=80

row=""          # accumulated escape sequences for the current row
row_used=0      # visible width consumed by the current row
prev_bg=""      # bg of the previous segment, used to draw the separator

flush_row() {
  [ -z "$row" ] && return
  printf "%b\n" "${row}\033[38;2;${prev_bg}m${RESET}"
  row=""
  row_used=0
  prev_bg=""
}

for i in "${!seg_text[@]}"; do
  text="${seg_text[$i]}"
  bg="${seg_bg[$i]}"
  fg="${seg_fg[$i]}"
  tw="${seg_w[$i]}"

  width=$(( tw + 2 ))
  [ -n "$row" ] && width=$(( width + 1 ))

  # Wrap when this segment plus the row's trailing separator would overflow.
  if [ -n "$row" ] && [ $(( row_used + width + 1 )) -gt "$cols" ]; then
    flush_row
    width=$(( tw + 2 ))
  fi

  # Last resort: a segment wider than an entire row gets an ellipsis so the
  # row still ends with its separator instead of being cut mid-escape.
  if [ $(( width + 1 )) -gt "$cols" ]; then
    keep_cells=$(( cols - 4 ))
    [ "$keep_cells" -lt 1 ] && keep_cells=1
    # Scale cells back to characters when the text is wider than 1 cell/char.
    keep=$(( keep_cells * ${#text} / tw ))
    [ "$keep" -lt 1 ] && keep=1
    text="${text:0:$keep}…"
    width=$(( keep_cells + 3 ))
  fi

  if [ -z "$prev_bg" ]; then
    row="${row}\033[48;2;${bg}m\033[38;2;${fg}m ${text} ${RESET}"
  else
    row="${row}\033[48;2;${bg}m\033[38;2;${prev_bg}m${RESET}\033[48;2;${bg}m\033[38;2;${fg}m ${text} ${RESET}"
  fi
  row_used=$(( row_used + width ))
  prev_bg="$bg"
done

flush_row
