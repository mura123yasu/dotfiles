#!/usr/bin/env bash
# herdr のサイドバーとタブに Claude Code のセッション名（/rename で付けた名前）を出し、
# 名前が付いた・変わったときにセッションをカテゴリのスペースへ振り分ける。
#
# statusline-command.sh から、statusline の入力 JSON を stdin に渡して呼ばれる。
# herdr の外（HERDR_PANE_ID が無い）では何もしない。
#
# - pane に `$session` トークンを送る（表示位置は ~/.config/herdr/config.toml の [ui.sidebar.agents]）
# - いまのスペースがカテゴリでなければ（起動直後の個別スペースなど）、カテゴリを決めて
#   そのスペースへタブとして移す（画面もついていく）。カテゴリのスペースが無ければ作る
#   - カテゴリはまず herdr-categories.tsv のルールで決め、当たらなければ haiku に選ばせる
#   - haiku が新しく作ったカテゴリ名は ~/.local/state/herdr/categories に覚える
# - すでにカテゴリのスペースにいるなら動かさず、タブ名だけセッション名にする

[ -n "${HERDR_PANE_ID:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0

# LANG のロケール（ja_JP.UTF-8 など）が入っていない環境では C ロケールになり、
# sed や ${#var} が日本語をバイト単位で扱ってカテゴリ名を壊す。必ず入っている C.UTF-8 に固定する
export LC_ALL=C.UTF-8

script_dir=$(dirname "$(readlink -f "$0")")
rules_file="$script_dir/herdr-categories.tsv"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/herdr"
learned_file="$state_dir/categories"
default_category="よろず"

input=$(cat)
name=$(printf '%s' "$input" | jq -r '.session_name // empty' 2>/dev/null)
if [ -z "$name" ]; then
  transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
  if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    name=$(tac "$transcript" | grep -m1 -o '"customTitle":"[^"]*"' | sed 's/^"customTitle":"//; s/"$//')
  fi
fi

# 前回送った値と同じなら何もしない（statusline は頻繁に走るため）
cache_dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/herdr-session-label"
mkdir -p "$cache_dir" 2>/dev/null || exit 0
key="${HERDR_PANE_ID//[^A-Za-z0-9]/_}"
cache="$cache_dir/$key"
[ -f "$cache" ] && [ "$(cat "$cache")" = "$name" ] && exit 0

# 判定に数秒かかるので、その間に走った statusline が二重に動かないようにする
lock="$cache_dir/$key.lock"
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock" 2>/dev/null' EXIT

herdr pane report-metadata "$HERDR_PANE_ID" --source claude-session-name --token "session=$name" >/dev/null 2>&1 || exit 0
# 処理済みの印（$cache）は振り分けが終わってから書く。途中で失敗したら次の statusline で再挑戦する
mark_done() { printf '%s' "$name" >"$cache"; }
# 名前が空なら振り分けるものが無い
if [ -z "$name" ]; then
  mark_done
  exit 0
fi

pane_json=$(herdr pane get "$HERDR_PANE_ID" 2>/dev/null) || exit 0
pane_id=$(printf '%s' "$pane_json" | jq -r '.result.pane.pane_id // empty')
tab_id=$(printf '%s' "$pane_json" | jq -r '.result.pane.tab_id // empty')
ws_id=$(printf '%s' "$pane_json" | jq -r '.result.pane.workspace_id // empty')
pane_cwd=$(printf '%s' "$pane_json" | jq -r '.result.pane.cwd // empty')
[ -n "$pane_id" ] && [ -n "$ws_id" ] || exit 0

# 既知のカテゴリ = ルールのカテゴリ + 学習したカテゴリ（重複なし・出現順）
known_categories() {
  {
    grep -v '^[[:space:]]*#' "$rules_file" 2>/dev/null | awk -F '\t' 'NF >= 2 && $2 != "" { print $2 }'
    printf '%s\n' "$default_category"
    cat "$learned_file" 2>/dev/null
  } | awk 'NF && !seen[$0]++'
}

is_category() {
  known_categories | grep -qxF -- "$1"
}

ws_list=$(herdr workspace list 2>/dev/null) || exit 0
current_label=$(printf '%s' "$ws_list" | jq -r --arg w "$ws_id" '.result.workspaces[] | select(.workspace_id == $w) | .label')

# すでにカテゴリのスペースにいる: 動かさず、タブ名だけ合わせる
if is_category "$current_label"; then
  [ -n "$tab_id" ] && herdr tab rename "$tab_id" "$name" >/dev/null 2>&1
  mark_done
  exit 0
fi

# 1) ルールで決める
category=""
shopt -s nocasematch
while IFS=$'\t' read -r pattern cat_name; do
  [[ -z "$pattern" || "$pattern" == \#* || -z "$cat_name" ]] && continue
  if [[ "$name" =~ $pattern ]]; then
    category="$cat_name"
    break
  fi
done <"$rules_file"
shopt -u nocasematch

# 2) 当たらなければ haiku に選ばせる（herdr のフックや statusline を子プロセスで動かさないよう HERDR_* を外す）
if [ -z "$category" ] && command -v claude >/dev/null 2>&1; then
  list=$(known_categories | paste -sd '/' - | sed 's#/# / #g')
  prompt="Claude Code の作業セッションを、ターミナルのスペース（作業ジャンル別のグループ）に振り分けます。
既存のスペース: ${list}
セッション名: ${name}
作業ディレクトリ: ${pane_cwd}

既存のスペースに合うものがあれば、その名前を一字一句そのまま出力してください。
どれにも合わず、今後も同じジャンルのセッションが増えそうなら、新しいスペース名（作業ジャンルを表す日本語 12 文字以内。セッション名そのものにはしない）を出力してください。
単発の雑多な作業なら「${default_category}」を出力してください。
出力はスペース名 1 行だけ。説明や記号は付けないこと。"
  answer=$(cd "${TMPDIR:-/tmp}" && env -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_SOCKET_PATH -u HERDR_WORKSPACE_ID -u HERDR_TAB_ID \
    timeout 60 claude -p --model haiku --tools "" --no-session-persistence --strict-mcp-config \
    --settings '{"disableAllHooks":true}' "$prompt" 2>/dev/null | awk 'NF' | tail -n 1)
  answer=$(printf '%s' "$answer" | sed 's/^[[:space:]「"]*//; s/[[:space:]」"。]*$//')
  if [ -n "$answer" ] && [ "${#answer}" -le 20 ] && [[ "$answer" != */* ]]; then
    category="$answer"
    if ! is_category "$category"; then
      mkdir -p "$state_dir" && printf '%s\n' "$category" >>"$learned_file"
    fi
  fi
fi
[ -n "$category" ] || category="$default_category"

# 動作確認用: HERDR_CATEGORY_DRY_RUN=1 なら判定結果を出すだけで動かさない
if [ -n "${HERDR_CATEGORY_DRY_RUN:-}" ]; then
  printf '%s\n' "$category"
  exit 0
fi

# 3) カテゴリのスペースへタブとして移す（無ければ作る）
target_ws=$(printf '%s' "$ws_list" | jq -r --arg l "$category" '[.result.workspaces[] | select(.label == $l)][0].workspace_id // empty')
created_root_tab=""
if [ -z "$target_ws" ]; then
  created=$(herdr workspace create --label "$category" --cwd "${pane_cwd:-$HOME}" --no-focus 2>/dev/null) || exit 0
  target_ws=$(printf '%s' "$created" | jq -r '.result.workspace.workspace_id // empty')
  created_root_tab=$(printf '%s' "$created" | jq -r '.result.tab.tab_id // empty')
  [ -n "$target_ws" ] || exit 0
fi

herdr pane move "$pane_id" --new-tab --workspace "$target_ws" --label "$name" --focus >/dev/null 2>&1 || exit 0
mark_done
# workspace create が作った空のシェルのタブは要らない
[ -n "$created_root_tab" ] && herdr tab close "$created_root_tab" >/dev/null 2>&1
exit 0
