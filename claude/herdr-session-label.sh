#!/usr/bin/env bash
# herdr のサイドバーに Claude Code のセッション名（/rename で付けた名前）を出す。
#
# statusline-command.sh から、statusline の入力 JSON を stdin に渡して呼ばれる。
# herdr の外（HERDR_PANE_ID が無い）では何もしない。
# 送るのは pane の `$session` トークン（表示位置は ~/.config/herdr/config.toml の
# [ui.sidebar.agents] の rows）。あわせて、その pane が入っているタブの名前もセッション名にする。
# workspace はカテゴリ単位で複数セッションが入るため、workspace には送らない。

[ -n "${HERDR_PANE_ID:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0

input=$(cat)
name=$(printf '%s' "$input" | jq -r '.session_name // empty' 2>/dev/null)
if [ -z "$name" ]; then
  transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
  if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    name=$(tac "$transcript" | grep -m1 -o '"customTitle":"[^"]*"' | sed 's/^"customTitle":"//; s/"$//')
  fi
fi

# 前回送った値と同じなら送らない（statusline は頻繁に走るため）
cache_dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/herdr-session-label"
mkdir -p "$cache_dir" 2>/dev/null || exit 0
cache="$cache_dir/${HERDR_PANE_ID//[^A-Za-z0-9]/_}"
[ -f "$cache" ] && [ "$(cat "$cache")" = "$name" ] && exit 0

source_id="claude-session-name"
herdr pane report-metadata "$HERDR_PANE_ID" --source "$source_id" --token "session=$name" >/dev/null 2>&1 || exit 0
# pane move でタブを移ると HERDR_TAB_ID は古いままなので、現在のタブは pane から引く
if [ -n "$name" ]; then
  tab_id=$(herdr pane get "$HERDR_PANE_ID" 2>/dev/null | jq -r '.result.pane.tab_id // empty' 2>/dev/null)
  [ -n "$tab_id" ] && herdr tab rename "$tab_id" "$name" >/dev/null 2>&1
fi
printf '%s' "$name" >"$cache"
