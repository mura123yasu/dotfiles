#!/bin/sh
# Claude Code status line — mirrors Starship prompt style
# Colors from starship.toml: #3B4252 (dir bg), #5E81AC (git bg), #E5E9F0 (dir fg), #ECEFF4 (git fg)
# Segment layout (when in a git repo):
#   [Dir] [Branch[*]] [Context %] [Session %] [Model (effort)] [Time]

input=$(cat)

# --- Extract fields ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty' 2>/dev/null)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
session_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
current_time=$(date +%H:%M)

# --- Effort level: try status JSON first, then fall back to settings.json ---
effort_raw=$(echo "$input" | jq -r '.effortLevel // .thinking.effort // .effort // empty' 2>/dev/null)
if [ -z "$effort_raw" ] && [ -f "$HOME/.claude/settings.json" ]; then
  effort_raw=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
fi
# absent = auto
if [ -z "$effort_raw" ]; then
  effort_raw="auto"
fi
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
if git_dir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null); then
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

# --- ANSI truecolor segment colors (Nord + Catppuccin) ---
DIR_BG="\033[48;2;59;66;82m"       # #3B4252
DIR_FG="\033[38;2;229;233;240m"    # #E5E9F0
GIT_BG="\033[48;2;94;129;172m"     # #5E81AC
GIT_FG="\033[38;2;236;239;244m"    # #ECEFF4
CTX_BG="\033[48;2;163;190;140m"    # #A3BE8C
CTX_FG="\033[38;2;35;38;46m"
SES_BG="\033[48;2;235;203;139m"    # #EBCB8B
SES_FG="\033[38;2;35;38;46m"
MODEL_BG="\033[48;2;137;180;250m"  # #89B4FA
MODEL_FG="\033[38;2;30;30;46m"
TIME_BG="\033[48;2;180;142;173m"   # #B48EAD
TIME_FG="\033[38;2;35;38;46m"

SEP_DIR_GIT_FG="\033[38;2;59;66;82m"
SEP_GIT_CTX_FG="\033[38;2;94;129;172m"
SEP_CTX_SES_FG="\033[38;2;163;190;140m"
SEP_SES_MODEL_FG="\033[38;2;235;203;139m"
SEP_MODEL_TIME_FG="\033[38;2;137;180;250m"
SEP_TIME_END_FG="\033[38;2;180;142;173m"
SEP_DIR_CTX_FG="\033[38;2;59;66;82m"

RESET="\033[0m"

line=""

# Directory segment
line="${line}${DIR_BG}${DIR_FG} ${dir_display} ${RESET}"

if [ -n "$git_branch" ]; then
  line="${line}${GIT_BG}${SEP_DIR_GIT_FG}${RESET}${GIT_BG}${GIT_FG} ${git_branch}${git_dirty} ${RESET}"

  if [ -n "$used_pct" ]; then
    used_int=$(printf "%.0f" "$used_pct")
    ctx_bar=$(make_bar "$used_pct")
    ctx_display="${used_int}%ctx ${ctx_bar}"
  else
    ctx_display="ctx ░░░░░░░░░░"
  fi
  line="${line}${CTX_BG}${SEP_GIT_CTX_FG}${RESET}${CTX_BG}${CTX_FG} ${ctx_display} ${RESET}"

  if [ -n "$session_pct" ]; then
    session_int=$(printf "%.0f" "$session_pct")
    session_bar=$(make_bar "$session_pct")
    reset_label=$(make_reset_label "$session_resets_at")
    ses_display="${session_int}%ses ${session_bar}${reset_label}"
  else
    ses_display="ses ░░░░░░░░░░"
  fi
  line="${line}${SES_BG}${SEP_CTX_SES_FG}${RESET}${SES_BG}${SES_FG} ${ses_display} ${RESET}"

  line="${line}${MODEL_BG}${SEP_SES_MODEL_FG}${RESET}${MODEL_BG}${MODEL_FG} ${model}${effort_label} ${RESET}"
  line="${line}${TIME_BG}${SEP_MODEL_TIME_FG}${RESET}${TIME_BG}${TIME_FG} ${current_time} ${RESET}"
  line="${line}${SEP_TIME_END_FG}${RESET}"

else
  # No git repo
  if [ -n "$used_pct" ]; then
    used_int=$(printf "%.0f" "$used_pct")
    ctx_bar=$(make_bar "$used_pct")
    ctx_display="${used_int}%ctx ${ctx_bar}"
  else
    ctx_display="ctx ░░░░░░░░░░"
  fi
  line="${line}${CTX_BG}${SEP_DIR_CTX_FG}${RESET}${CTX_BG}${CTX_FG} ${ctx_display} ${RESET}"

  if [ -n "$session_pct" ]; then
    session_int=$(printf "%.0f" "$session_pct")
    session_bar=$(make_bar "$session_pct")
    reset_label=$(make_reset_label "$session_resets_at")
    ses_display="${session_int}%ses ${session_bar}${reset_label}"
  else
    ses_display="ses ░░░░░░░░░░"
  fi
  line="${line}${SES_BG}${SEP_CTX_SES_FG}${RESET}${SES_BG}${SES_FG} ${ses_display} ${RESET}"

  line="${line}${MODEL_BG}${SEP_SES_MODEL_FG}${RESET}${MODEL_BG}${MODEL_FG} ${model}${effort_label} ${RESET}"
  line="${line}${TIME_BG}${SEP_MODEL_TIME_FG}${RESET}${TIME_BG}${TIME_FG} ${current_time} ${RESET}"
  line="${line}${SEP_TIME_END_FG}${RESET}"
fi

printf "%b" "$line"
