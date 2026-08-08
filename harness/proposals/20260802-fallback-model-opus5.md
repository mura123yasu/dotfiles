---
title: fallbackModel を Opus 5 に更新する
date: 2026-08-02
status: done
sources:
  - https://www.anthropic.com/news/claude-opus-5
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md（v2.1.219）
---

## 概要

`claude/settings.json` の `fallbackModel` を現行の `claude-opus-4-8` から `claude-opus-5` に更新する。

## 動機

- 2026-07-24 に Claude Opus 5（1M コンテキスト、$5/$25 per Mtok）がリリースされ、Claude Code の
  デフォルト Opus モデルとなった（CHANGELOG v2.1.219、Anthropic 公式発表）
- 価格は旧 Opus 4.8 と同額のまま、フロンティア性能が Fable 5（$10/$50）に近づいたとされており、
  fallback 先として旧世代モデル（Opus 4.8）を指定し続ける理由がない
- `model-routing.md` は「最上位モデル（fable。opus へのフォールバックは settings.json の
  fallbackModel で決定論的に設定済み）」と明記しており、fallback 先は常に現行最新の Opus であるべき

## 変更内容

- `claude/settings.json`: `"fallbackModel": ["claude-opus-4-8"]` → `"fallbackModel": ["claude-opus-5"]`

## リスク・影響

- 設定値1行の変更のみ。両 OS 共用ファイルで install スクリプトへの影響なし
- Opus 5 は Claude Code 上で Opus 4.8 と互換（モデル ID 差し替えのみで移行可能、と公式発表内で言及）
  のため、フォールバック時の互換性リスクは低いと考えられる
- 将来さらに新しい Opus 世代がリリースされた場合、同様の更新が再度必要になる（運用上の恒常コスト）

## 判断記録

- 2026-08-08: 採用。ただし提案どおりの `["claude-opus-5"]` ではなく **`["opus", "sonnet"]`** に変形した。
  理由は2点。(1) 提案自身が「将来さらに新しい Opus 世代が出たら再更新が必要（運用上の恒常コスト）」と
  挙げていた懸念を、エイリアス指定にすれば構造的に解消できる。`fallbackModel` は設定スキーマ上
  「model name or alias」を受け付ける。(2) main セッションの推奨モデルが Opus 5 になったため、
  fallback も Opus 5 に pin すると過負荷時の逃げ先が primary と同一モデルになり fallback として
  機能しない。Sonnet を2段目に置くことで、Fable が安全分類器に弾かれたら Opus、Opus も
  落ちていたら Sonnet、という2段構えになる。
- 同サイクルで `model: "default"` の pin 解除（PR #41）を行っており、「推奨に追随させ、
  特定バージョンを pin しない」という方針とも一貫する。
