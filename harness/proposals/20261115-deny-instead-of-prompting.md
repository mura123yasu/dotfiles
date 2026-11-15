---
title: 無人実行時に ask 項目を安全側（deny）に倒す denyInsteadOfPrompting の検討
date: 2026-11-15
status: proposed
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md（v2.1.319）
  - https://code.claude.com/docs/en/settings-reference
---

## 概要

`claude/settings.json` に `permissions.denyInsteadOfPrompting` を設定し、現在
`permissions.ask` に置かれている3項目（`gh pr merge *` / `gh repo delete *` / `launchctl *`）が、
人間が応答できない無人実行下で黙って deny されるようにすることを検討する。

## 動機

- 本リポジトリではスケジュールタスクや `/loop` による無人実行が実際に発生する（今回のハーネス
  調査サイクル自体がその一例）。`ask` は人間の応答を前提にしており、人間がいない状況での挙動
  （ハング・タイムアウト・既定動作）が現在の settings.json 上は保証されていない
- 公式 CHANGELOG v2.1.319 で `permissions.denyInsteadOfPrompting` という設定キーが追加されたと
  確認した。既存の `ask` リストを無人実行に対して安全側に倒せる可能性がある

## 変更内容

- `claude/settings.json` の `permissions` に `"denyInsteadOfPrompting": true`（キー名・型は
  実装前に要確認）を追加する案
- 併せて `ask` リストの3項目それぞれについて、deny に倒れても実害がないか
  （`gh pr merge` は自動化で使っていないか、`launchctl` は macOS 側の運用で本当に不要か）を洗い出す

## リスク・影響

- **最大のリスク**: この設定が「無人実行時のみ」ではなく常時 `ask` を `deny` に変える挙動だった
  場合、対話セッション中の確認フロー（人間が判断して許可する運用）そのものを壊す。
  公式ドキュメントで「無人実行時限定」か「常時適用」かを実装前に `claude-code-guide` エージェント
  で正確に確認すること（SKILL.md Gotchas 準拠）。常時適用だった場合はこの提案自体を却下すべき
  可能性が高い
- 対象は macOS / WSL 共通の `settings.json`。`launchctl` は WSL には存在しないため、
  OS 間での実害の非対称性がある
