---
title: 無人実行向けに github-push スキルを permissions.allow に追加する
date: 2026-11-15
status: proposed
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md（v2.1.325）
---

## 概要

`claude/settings.json` の `permissions.allow` に `"Skill(github-push)"` を追加する。

## 動機

- 公式 CHANGELOG v2.1.325 で、`allowed-tools` や `hooks` を宣言するスキルをスケジュールタスク・
  `/loop` が無人実行する前に確認を求めるようになったと確認した。無人実行を継続するには
  `permissions.allow` に `Skill(<name>)` を追加する必要がある
- 本リポジトリの `claude/skills/github-push/SKILL.md` は frontmatter に `allowed-tools`
  （`Bash(git ...)`, `Bash(gh pr create:*)` 等）を宣言しており、この新しい確認ゲートの対象になる
- `github-push` は PR 作成を伴う作業の最終段で使われるため、`/loop` や将来のスケジュールタスクで
  無人実行される可能性がある。確認待ちで無人実行がブロックされると、タスクが完了できずに終わる
  （今回のサイクル自体もスケジュールタスクとして動いている）
- 他スキル（`harness-improve`, `dotfiles-drift-check`, `park`, `wip`）は現状 `allowed-tools` /
  `hooks` を宣言していないため、今回の変更の対象外と確認した

## 変更内容

- `claude/settings.json` の `permissions.allow` に `"Skill(github-push)"` を追加
- `claude/rules/model-routing.md` または `harness/README.md` に一文追記: 今後
  `allowed-tools` / `hooks` を宣言する新スキルを追加する際は、無人実行させる想定があれば
  同時に `permissions.allow` へ `Skill(<name>)` を追加すること

## リスク・影響

- `Skill(<name>)` 許可の正確な効果（スキル実行そのものの確認のみを免除するのか、内部で使う
  個々のコマンドの permissions まで拘束するのか）は settings-reference の記述を実装前に
  `claude-code-guide` エージェントで確認すること（SKILL.md Gotchas 準拠）。
  スキル内部の各 Bash コマンドは `allowed-tools` と既存の `permissions.allow/ask/deny` で
  別途制御されているため、過剰な権限付与にはならない見込みだが未確証
- 両 OS（macOS / WSL）で共通の `settings.json` のため、影響範囲は両端末
