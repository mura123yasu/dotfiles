#!/bin/bash
# PreToolUse guard hook — Bash コマンドの最終防壁
# settings.json の deny ルール（プレフィックスマッチ）をすり抜ける変種を regex で捕捉する。
# deny 判定は --dangerously-skip-permissions 下でも有効。
#
# 入力: stdin に PreToolUse イベントの JSON
# 出力: 危険コマンドなら permissionDecision: deny の JSON を返す。それ以外は何も出力しない（通常フローへ）。

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

[ -z "$command" ] && exit 0

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# --- 破壊的なファイル削除 ---
# rm の recursive+force 変種 (-rf, -fr, -Rf, --recursive --force, フルパス起動 /bin/rm 含む)
if echo "$command" | grep -qE '(^|[;&|]\s*|\s)(/bin/|/usr/bin/)?rm\s+(-[a-zA-Z]*[rR][a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*[rR]|--recursive\s+--force|--force\s+--recursive)'; then
  deny "rm の recursive+force は禁止。個別ファイル削除か trash を使うこと。"
fi
# ホーム・ルート・親ディレクトリを対象にした rm
if echo "$command" | grep -qE '(^|[;&|]\s*|\s)rm\s+.*\s(~/?|/|\.\.)(\s|$)'; then
  deny "ホーム/ルート/親ディレクトリへの rm は禁止。"
fi

# --- 権限昇格 ---
if echo "$command" | grep -qE '(^|[;&|]\s*)(sudo|su)\s'; then
  deny "sudo/su は禁止。必要なら人間が手動で実行する。"
fi

# --- Git の破壊的操作 ---
if echo "$command" | grep -qE 'git\s+push\s+.*(--force|-f)(\s|$)' && ! echo "$command" | grep -q 'force-with-lease'; then
  deny "force push は禁止（--force-with-lease も要相談）。"
fi
# main/master への直接 push（グローバルルールの決定論的強制）
# ref として単体で現れる main/master のみ対象（feature/main-fix 等の枝名は許可）
if echo "$command" | grep -qE 'git\s+push\s+[^;&|]*(\s|:)(main|master)(\s|$)'; then
  deny "main/master への直接 push は禁止。ブランチを切って PR を作成すること。"
fi
if echo "$command" | grep -qE 'git\s+reset\s+--hard' ; then
  deny "git reset --hard は禁止。stash か新ブランチ退避を使うこと。"
fi
if echo "$command" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f'; then
  deny "git clean -f は禁止。対象を確認の上、個別に削除すること。"
fi

# --- リモートコード実行 ---
if echo "$command" | grep -qE '(curl|wget)\s+[^|;&]*\|\s*(ba|z|da)?sh'; then
  deny "リモートスクリプトのパイプ実行 (curl | sh) は禁止。ダウンロードして内容確認後に実行すること。"
fi

# --- システム破壊 ---
if echo "$command" | grep -qE '(^|[;&|]\s*)dd\s+.*of=/dev/|mkfs|diskutil\s+(erase|partition)'; then
  deny "ディスク直接操作は禁止。"
fi
if echo "$command" | grep -qE 'chmod\s+(-[a-zA-Z]*R[a-zA-Z]*\s+)?(777|a\+rwx)'; then
  deny "chmod 777 は禁止。必要最小限の権限を指定すること。"
fi

# --- 機密ファイルへのアクセス（bash 経由の迂回対策） ---
if echo "$command" | grep -qE '(cat|less|head|tail|cp|scp|base64|xxd|strings)\s+[^;&|]*(\.env(\.[a-z]+)?(\s|$)|id_rsa|id_ed25519|\.aws/credentials|\.ssh/)'; then
  deny "機密ファイル (.env / SSH鍵 / AWS認証情報) へのアクセスは禁止。"
fi
if echo "$command" | grep -qE 'security\s+(find|dump)-generic-password'; then
  deny "Keychain からの秘密情報読み出しは禁止。"
fi

exit 0
