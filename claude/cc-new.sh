#!/usr/bin/env bash
# 新しい Claude Code セッションを立ち上げる。herdr の中なら herdr のスペースとして、外なら Windows Terminal で開く。
# ~/.local/bin/cc-new にリンクされる（install.sh / install.wsl.sh）。
#
#   cc-new [セッション名] [--cwd パス] [--prompt 最初の指示] [--resume セッションID] [--no-focus]
#
# herdr の中では:
# - 「新規: <セッション名>」という仮のスペースを作り、そこで claude を起動する
# - 名前が付いていれば、herdr-session-label.sh（statusline から呼ばれる）がカテゴリのスペースへ
#   タブとして移す。仮のスペースは空になって消える
# - 名前が無ければ「新規: 名前なし」スペースのまま残る（あとで /rename すれば振り分けられる）
# - いまいるカテゴリのスペースに直接作らないのは、カテゴリのスペースにいるセッションは振り分けの
#   対象外になり、ジャンル違いでもそこに残ってしまうため

set -euo pipefail
export LC_ALL=C.UTF-8

name="" cwd="$PWD" prompt="" resume="" focus="--focus"
while [ $# -gt 0 ]; do
  case "$1" in
    --cwd) cwd="$2"; shift 2 ;;
    --prompt) prompt="$2"; shift 2 ;;
    --resume) resume="$2"; shift 2 ;;
    --no-focus) focus="--no-focus"; shift ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "cc-new: 不明なオプション: $1" >&2; exit 2 ;;
    *) name="$1"; shift ;;
  esac
done
cwd=$(cd "$cwd" && pwd)

# claude に渡す引数
claude_args=()
if [ -n "$resume" ]; then
  claude_args+=(--resume "$resume")
else
  [ -n "$name" ] && claude_args+=(-n "$name")
  [ -n "$prompt" ] && claude_args+=("$prompt")
fi

in_herdr() {
  [ -n "${HERDR_PANE_ID:-}" ] && command -v herdr >/dev/null 2>&1 && herdr workspace list >/dev/null 2>&1
}

if in_herdr; then
  # 仮のスペース名はカテゴリ名とかぶらないよう「新規: 」を付ける（かぶると振り分けの対象外になる）
  label="新規: ${name:-名前なし}"
  # herdr agent start は claude のコマンドをシェルにキー入力する。LANG のロケールが入っていない環境
  # （WSL の ja_JP.UTF-8 など）では zsh が日本語の入力を '?' に変えるので、新しいペインは C.UTF-8 にする
  created=$(herdr workspace create --label "$label" --cwd "$cwd" --env LC_ALL=C.UTF-8 "$focus")
  pane=$(printf '%s' "$created" | jq -r '.result.root_pane.pane_id // empty')
  ws=$(printf '%s' "$created" | jq -r '.result.workspace.workspace_id // empty')
  if [ -z "$pane" ]; then
    echo "cc-new: herdr のスペースを作れませんでした: $created" >&2
    exit 1
  fi
  # シェルのプロンプトが出るのを待ってから claude を起動し、入力できる状態になるまで待つ。
  # herdr のエージェント名は英小文字・数字・-_ の 32 文字までなので、表示名とは別に機械的に付ける
  agent_name="cc-$(date +%s)-$$"
  if ! out=$(herdr agent start "$agent_name" --kind claude --pane "$pane" --timeout 60000 -- "${claude_args[@]}" 2>&1); then
    # フォルダの信頼確認などで止まっているだけなら、起動はできている。画面で答えてもらう
    if printf '%s' "$out" | grep -q 'agent_not_ready'; then
      echo "herdr のスペース「$label」（$ws）で起動しました。確認画面で止まっているので、そのスペースで答えてください"
      exit 0
    fi
    echo "cc-new: claude の起動を確認できませんでした: $out" >&2
    herdr workspace close "$ws" >/dev/null 2>&1 || true
    exit 1
  fi
  echo "herdr のスペース「$label」（$ws）で起動しました"
  exit 0
fi

# herdr の外: Windows Terminal の新しいタブで開く（WSL のとき）
if command -v wt.exe >/dev/null 2>&1; then
  distro="${WSL_DISTRO_NAME:-Ubuntu}"
  shell="${SHELL:-/bin/bash}"
  profile="${CC_SESSIONS_WT_PROFILE:-$distro}"
  cmd="claude"
  for a in "${claude_args[@]}"; do cmd+=" $(printf '%q' "$a")"; done
  wt.exe -w 0 new-tab -p "$profile" --title "${name:-claude}" wsl.exe -d "$distro" --cd "$cwd" -- \
    "$shell" -lic "$cmd && exec $shell || exec $shell" >/dev/null 2>&1 &
  echo "Windows Terminal の新しいタブで起動しました"
  exit 0
fi

echo "cc-new: herdr の中でも WSL でもないので、自動では開けません。次を実行してください:" >&2
printf 'cd %q && claude' "$cwd" >&2
for a in "${claude_args[@]}"; do printf ' %q' "$a" >&2; done
echo >&2
exit 1
