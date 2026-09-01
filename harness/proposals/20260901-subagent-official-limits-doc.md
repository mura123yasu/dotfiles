---
title: サブエージェントの公式上限（同時実行数・ネスト深度）を model-routing.md に反映する
date: 2026-09-01
status: proposed
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md
  - https://code.claude.com/docs/en/sub-agents
---

## 概要

サブエージェントの同時実行数上限（デフォルト20、`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` で変更可）
とネスト深度上限（デフォルト3、`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` で変更可）が
`code.claude.com/docs/en/sub-agents` で正式文書化されたことを受け、
`claude/rules/model-routing.md` の「委譲後の運用」節にこれを追記する。

## 動機

- 現行ルールは「並列は2〜4体を目安にする」と運用上の目安のみを記載しており、
  製品側に機械的な上限が存在すること自体が明記されていない
- ネスト深度上限（3）は、strategist から更にサブエージェントへ委譲するような
  多段委譲を設計する際に踏み抜きうる制約であり、知らずに設計すると想定外の失敗になる
- ドキュメント追記のみで実装リスクがなく、確度の高い公式ソース（CHANGELOG バージョン番号付き
  + 公式ドキュメント本文）に基づく変更のため、今回のサイクルで反映して問題ない

## 変更内容

- `claude/rules/model-routing.md` の「委譲後の運用」節に以下を追記:
  - 同時実行数のデフォルト上限（20）と環境変数での変更方法
  - ネスト深度のデフォルト上限（3）と環境変数での変更方法。特に strategist 等からの
    多段委譲を設計する際にこの上限を意識する旨の一言

## リスク・影響

- ドキュメント追記のみ。スクリプト・設定ファイルの動作変更はなし
- 数値（20 / 3）は執筆時点の公式ドキュメント記載値であり、将来変更されうる。
  記載時に「執筆時点のデフォルト値」である旨を明記し、鵜呑みにされないようにする
