---
title: PreToolUse（guard.sh）に onFailure block を設定し、フック異常終了時をフェイルクローズにする
date: 2026-10-15
status: proposed
sources:
  - https://code.claude.com/docs/en/hooks
---

## 概要

`claude/settings.json` の `hooks.PreToolUse`（matcher: Bash, guard.sh 実行）エントリに
`"onFailure": "block"` を追加する。guard.sh 自体が異常終了した場合、危険コマンドが
素通りする（フェイルオープン）のではなく、ブロックされる（フェイルクローズ）ようにする。

## 動機

2026-10-15 の公式ドキュメント調査（code.claude.com/docs/en/hooks）で、フックハンドラの
実行自体（スクリプトのクラッシュ・異常終了等）が失敗した場合の挙動を制御する
`onFailure` フィールド（v2.1.295+ で追加）が存在し、既定値は `"continue"` であることを
確認した。

guard.sh は `rm -rf`・force push・`.env` アクセス等の破壊的操作をブロックする唯一の
PreToolUse ガードレールであり、CLAUDE.md の「main への直接 commit・push は禁止」等の
方針も実質的にこのフックで強制されている。現状の既定動作（`continue`）では、
guard.sh が依存コマンド不在やスクリプトのバグで異常終了した場合に、本来ブロックすべき
危険な Bash コマンドがそのまま実行されてしまう。安全側の既定（フェイルクローズ）に
明示的に倒すべき箇所である。

## 変更内容

- `claude/settings.json` の `hooks.PreToolUse[].hooks[]` 内、guard.sh を実行するエントリに
  `"onFailure": "block"` を追加する
- OS 固有の変更ではないため `install.sh` / `install.wsl.sh` への変更は不要
  （`settings.json` 側の設定のみ）

## リスク・影響

- guard.sh が想定外の理由で非ゼロ終了する場合（スクリプト自体のバグ、依存コマンド
  （jq 等）の不在など）、これまで素通りしていた Bash コマンドが一律ブロックされる
  ようになる。導入前に guard.sh の exit code の扱いと、Mac/WSL 両方で依存コマンドが
  揃っていることを再確認する必要がある
- guard.sh が誤って恒常的に失敗する状態に陥ると、Bash 実行自体が常にブロックされる
  「詰み」状態になりうる。導入直後のセッションで動作確認を行うこと
- 変更は settings.json の1フィールド追加のみで、両 OS 共通に効く
