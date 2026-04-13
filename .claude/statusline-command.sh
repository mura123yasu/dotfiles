#!/usr/bin/env bash
input=$(cat)

# ── Parse JSON fields ────────────────────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // "unknown"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Rate limits (Claude.ai subscribers)
five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# ── ANSI color helpers ───────────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Foreground colors
FG_CYAN="\033[36m"
FG_GREEN="\033[32m"
FG_YELLOW="\033[33m"
FG_RED="\033[31m"
FG_MAGENTA="\033[35m"
FG_BLUE="\033[34m"
FG_WHITE="\033[97m"
FG_ORANGE="\033[38;5;214m"
FG_BRIGHT_GREEN="\033[92m"
FG_BRIGHT_CYAN="\033[96m"

SEP="${DIM}${FG_WHITE} │ ${RESET}"

# ── Left segment: directory ──────────────────────────────────────────────────
# Shorten home dir to ~
short_cwd="${cwd/#$HOME/~}"
dir_seg=$(printf "${BOLD}${FG_BRIGHT_CYAN} %s${RESET}" "$short_cwd")

# ── Left segment: git branch + diff stats ────────────────────────────────────
git_seg=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

  # Diff stats: added / deleted lines (index vs working tree combined)
  diff_stat=$(git -C "$cwd" diff --no-lock-index --shortstat HEAD 2>/dev/null)
  added=$(echo "$diff_stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')
  deleted=$(echo "$diff_stat" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+')

  git_seg=$(printf "${FG_GREEN} %s${RESET}" "${branch:-HEAD}")
  if [ -n "$added" ] || [ -n "$deleted" ]; then
    [ -n "$added" ]   && git_seg="${git_seg} ${FG_BRIGHT_GREEN}+${added}${RESET}"
    [ -n "$deleted" ] && git_seg="${git_seg} ${FG_RED}-${deleted}${RESET}"
  fi
fi

# ── Right segment: model name ────────────────────────────────────────────────
model_seg=$(printf "${BOLD}${FG_MAGENTA}%s${RESET}" "$model")

# ── Right segment: block/rate-limit time remaining ──────────────────────────
block_seg=""
if [ -n "$five_hour_pct" ] && [ -n "$five_hour_resets" ]; then
  now=$(date +%s)
  secs_left=$(( five_hour_resets - now ))
  if [ "$secs_left" -gt 0 ]; then
    hrs=$(( secs_left / 3600 ))
    mins=$(( (secs_left % 3600) / 60 ))
    block_seg=$(printf "${FG_BLUE}Block: %dh %dm${RESET}" "$hrs" "$mins")
  else
    block_seg=$(printf "${FG_BLUE}Block: resetting${RESET}")
  fi
fi

# ── Right segment: context usage ─────────────────────────────────────────────
ctx_seg=""
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  # Color shifts: green → yellow → orange → red as usage grows
  if [ "$used_int" -lt 50 ]; then
    color="${FG_BRIGHT_GREEN}"
  elif [ "$used_int" -lt 75 ]; then
    color="${FG_YELLOW}"
  elif [ "$used_int" -lt 90 ]; then
    color="${FG_ORANGE}"
  else
    color="${FG_RED}"
  fi
  ctx_seg=$(printf "${color}Ctx: %d%%${RESET}" "$used_int")
fi

# ── Assemble the status line ─────────────────────────────────────────────────
left="${dir_seg}"
[ -n "$git_seg" ] && left="${left}${SEP}${git_seg}"

right="${model_seg}"
[ -n "$block_seg" ] && right="${right}${SEP}${block_seg}"
[ -n "$ctx_seg" ]   && right="${right}${SEP}${ctx_seg}"

printf "${left}${SEP}${right}\n"
