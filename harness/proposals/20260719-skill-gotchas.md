---
title: スキルに Gotchas セクションを導入し、失敗知見を蓄積する運用にする
date: 2026-07-19
status: done
sources:
  - https://github.com/shanraisshan/claude-code-best-practice
---

## 概要

各スキル（SKILL.md）に「## Gotchas」セクションを設け、スキル実行中に踏んだ失敗・詰まりを
セッションのたびに追記して育てる運用を導入する。あわせて description を
「何をするか」の要約から「いつ発火すべきか」のトリガー条件を含む書き方に見直す。

## 動機

- コミュニティのベストプラクティスで「Gotchas セクションは SKILL.md 内で最も情報価値が高い」とされる。
  同じ失敗をセッションごとに繰り返すコスト（例: 本セッションで踏んだ「`git add -A` が
  `.bash_profile` で失敗する」「`~/.claude/skills` への ln はサンドボックス外実行が必要」）を削減できる
- 蓄積の受け皿（セクション）と運用ルールがないと知見が消えていくため、仕組みとして明文化する価値がある

## 変更内容

- `claude/skills/dotfiles-drift-check/SKILL.md`・`claude/skills/harness-improve/SKILL.md`:
  末尾に「## Gotchas」セクションを追加し、既知の失敗知見（上記2件など）を初期投入する
- `CLAUDE.md`: 「スキル実行中に失敗・詰まりを踏んだら、そのスキルの Gotchas に1行追記して
  同じ PR に含める」という運用ルールを追記する
- 各スキルの description を発火条件が伝わる書き方に微修正する（大きな書き換えはしない）

## リスク・影響

- Gotchas が肥大化すると context 圧迫要因になる。「1件1行・古くなったら削除」を運用ルールに含めて抑制する
- スキル本体の動作には影響しない（追記のみ）

## 判断記録

- 2026-07-19: 採用・実装。提案時の対象2スキルに加え github-push にも Gotchas を追加
  （git add -A / sandbox の失敗知見が該当するため）。description の書き換えは、確認の結果
  既存3スキルとも発火条件が伝わる書き方になっていたため見送り
