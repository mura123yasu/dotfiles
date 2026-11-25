---
title: CLAUDE_CODE_ENABLE_TODO_TOOLS を settings.json に設定し Task/TodoWrite 系ツールを復元する
date: 2026-08-15
status: proposed
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md（v2.1.233）
  - https://code.claude.com/docs/en/settings
---

## 概要

`claude/settings.json` の `env` キーに `CLAUDE_CODE_ENABLE_TODO_TOOLS: "1"` を追加し、
v2.1.233 以降デフォルトで無効化された TaskCreate / TaskGet / TaskUpdate / TaskList / TodoWrite を
メインセッション・サブエージェントの両方で復元する。

## 動機

- v2.1.233（今回の調査時点でのインストール済みバージョンと一致、2026-08-14 リリース）で、
  Opus 4.8 / Sonnet 5 / Fable 5 / Mythos 5 以降のモデルにおいて Task/TodoWrite 系ツールが
  既定提供されなくなった。CHANGELOG の記載内容を claude-code-guide エージェントで直接検証し、
  環境変数名・設定方法（`env` キー経由で恒久化可能）を確認済み
- 本リポジトリのメインセッション推奨モデルは Sonnet 5 / Opus 5、`strategist` は Fable 5 で運用しており、
  いずれも今回の対象モデルに該当する
- タスク進行管理・ユーザーへの状態可視化に使うツール群が暗黙に使えなくなるのは運用上の後退。
  復元コストは env 変数1つの追加で済み、リスクは低い

## 変更内容

- `claude/settings.json` のトップレベルに `"env": {"CLAUDE_CODE_ENABLE_TODO_TOOLS": "1"}` を追加

## リスク・影響

- 既知の副作用は報告されていない。機能を既定復元するだけのフラグであり、両 OS（Mac/WSL）共通で影響なし
- 将来 Claude Code 側の既定仕様が「有効」に戻った場合は無害な冗長設定になるだけ（実害なし）
- settings.json への新規キー追加のため、SKILL.md の Gotchas 記載通り、実装時に
  claude-code-guide エージェントでキー名・値形式（文字列 `"1"` か真偽値か等）を最終確認すること
  （起案時点では CHANGELOG ベースで `"1"`（文字列）と確認済みだが、実装フェーズでの再確認を推奨）
