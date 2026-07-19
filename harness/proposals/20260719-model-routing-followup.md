---
title: モデルルーティングの公式挙動への追従（Explore 記述修正 + fallbackModel 設定）
date: 2026-07-19
status: done
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md（v2.1.166, v2.1.198）
  - https://code.claude.com/docs/en/settings
---

## 概要

Claude Code 本体の挙動変更にモデルルーティングルールと settings.json を追従させる。
(1) 組み込み Explore がメインセッションのモデルを継承するようになったため、rules の記述を修正。
(2) 「fable → opus フォールバック」方針を `fallbackModel` 設定として決定論的に実装。

## 動機

- v2.1.198 で組み込み Explore エージェントはメインセッションのモデルを継承するようになった。
  `claude/rules/model-routing.md` は「組み込み Explore または `explorer`（haiku）」と併記しており、
  組み込み Explore を使うとトークン節約にならない（fable で探索してしまう）。ルールの意図と実挙動が乖離している
- v2.1.166 で `fallbackModel` 設定（最大3モデルのフォールバックチェーン）が追加された。
  model-routing.md の「fable。使えなくなったら opus にフォールバック」は現状 Claude の自己判断頼みで、
  設定として実装すれば決定論的になる

## 変更内容

- `claude/rules/model-routing.md`: 広域探索の推奨を `explorer`（haiku）に一本化し、
  「組み込み Explore はセッションモデルを継承するためトークン節約にならない」と明記
- `claude/settings.json`: `"fallbackModel": ["claude-opus-4-8"]` を追加

## リスク・影響

- rules の文言修正はリスクなし
- fallbackModel はファイル間でマージされず最優先ファイルが全体を上書きする仕様のため、
  プロジェクト側 settings で fallbackModel を定義すると打ち消される点に注意（現状該当なし）
- 両 OS 共用ファイルのみの変更で、install スクリプトへの影響なし

## 判断記録

- 2026-07-19: 採用・実装。`fallbackModel` の仕様（配列・最大3件・ユーザー settings.json で有効）は
  claude-code-guide エージェントで公式ドキュメントを確認済み
