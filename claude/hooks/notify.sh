#!/bin/bash
# Notification / Stop フック — 確認待ちとタスク完了を音で知らせる
#
# 入力: stdin に Notification / Stop イベントの JSON（hook_event_name を含む）
# 出力: なし。常に exit 0（音が鳴らせなくてもセッションは止めない）
#
# 鳴らし分け:
#   Notification（権限確認プロンプト・60秒アイドルの入力待ち） -> 確認音
#   Stop（応答完了 = タスク完了）                              -> 完了音
#
# 再生手段は OS で分岐する。WSL は powershell.exe 経由で Windows のシステム音、
# macOS は afplay。どちらも使えない環境ではターミナルベルにフォールバックする。
# 再生はバックグラウンドに投げるため、フックはセッションをブロックしない。

set -u

input=$(cat 2>/dev/null || true)
event=$(printf '%s' "$input" | jq -r '.hook_event_name // empty' 2>/dev/null)
[ -n "$event" ] || event="${1:-Stop}"

case "$event" in
  Notification)
    wav_name="notify.wav"
    mac_sound="/System/Library/Sounds/Funk.aiff"
    ;;
  *)
    wav_name="chimes.wav"
    mac_sound="/System/Library/Sounds/Glass.aiff"
    ;;
esac

is_wsl() {
  [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null
}

# ターミナルベル（最終フォールバック）。Windows Terminal の bellStyle 既定値 audible で鳴る。
bell() {
  [ -w /dev/tty ] && printf '\a' > /dev/tty 2>/dev/null
}

play_macos() {
  [ "$(uname -s)" = "Darwin" ] || return 1
  [ -x /usr/bin/afplay ] && [ -f "$mac_sound" ] || return 1
  ( /usr/bin/afplay "$mac_sound" >/dev/null 2>&1 & )
  return 0
}

play_wsl() {
  is_wsl || return 1
  local ps wav_unix wav_win
  ps=$(command -v powershell.exe) \
    || ps="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
  [ -x "$ps" ] || return 1
  wav_unix="/mnt/c/Windows/Media/${wav_name}"
  wav_win="C:\\Windows\\Media\\${wav_name}"
  [ -f "$wav_unix" ] || return 1
  # PlaySync でないと powershell 終了時に再生が切れる。setsid + timeout でハングを防ぐ。
  ( setsid timeout 10 "$ps" -NoProfile -NonInteractive -Command \
      "(New-Object Media.SoundPlayer '${wav_win}').PlaySync()" >/dev/null 2>&1 & )
  return 0
}

play_macos || play_wsl || bell

exit 0
