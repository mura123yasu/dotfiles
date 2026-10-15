---
title: model-routing.md に Agent 呼び出し単位の effort 指定（v2.1.292）を追記する
date: 2026-10-15
status: proposed
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md
---

## 概要

Agent ツールの呼び出しごとに `effort` を指定できる機能（v2.1.292 で追加。agent frontmatter の
`effort` より優先され、resume 後も保持される）を `claude/rules/model-routing.md` の
「effort 選択」節に追記し、strategist への昇格トリガーに満たない単発の委譲で
一時的に effort を上げる選択肢として明文化する。

## 動機

公式 CHANGELOG（v2.1.292）で、main セッションが Agent ツールでサブエージェントを呼ぶ際、
呼び出しごとに effort パラメータを指定できるようになったことを確認した。これは
frontmatter の effort より優先され、resume 後も保持される。

現行の `model-routing.md` は effort を「役割ごとに frontmatter で固定宣言する」運用を
前提としており（explorer/mechanic → low、reviewer → xhigh、strategist → max）、
呼び出し単位で動的に上書きする手段への言及がない。strategist の昇格トリガー
（後戻りできない設計判断・根本原因調査等）に該当しないが、通常の `reviewer` 等
sonnet/opus 系エージェントの単発タスクで一時的に effort を上げたい中間的な難易度の
委譲に使える手段として、ルールに位置付ける価値がある。

## 変更内容

- `model-routing.md` の「effort 選択」節の表に、Agent 呼び出し時の `effort` パラメータの
  優先順位（frontmatter より優先、resume 後も保持）を追記する
- 「その場」行（`/effort <level>`、セッション限り）と役割ベースの frontmatter 指定の
  間に、「単発の委譲でだけ一時的に上げる」選択肢として Agent 呼び出し単位の指定を追記する

## リスク・影響

- 低リスク。ドキュメント更新のみでコード変更はない
- 使いどころを誤ると、本来 strategist へ昇格すべき判断を、Agent 呼び出しの effort
  引き上げで安易に済ませてしまう懸念がある → 「昇格トリガーに当てはまる場合は
  必ず strategist に委譲する」という既存ルールが優先される旨を明記して緩和する
