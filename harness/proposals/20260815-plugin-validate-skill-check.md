---
title: harness-improve フェーズ4に claude plugin validate によるスキル frontmatter 検証を追加
date: 2026-08-15
status: proposed
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md（v2.1.233）
---

## 概要

`claude/skills/harness-improve/SKILL.md` のフェーズ4（実装）に、スキルファイルを新規追加・変更した際は
`claude plugin validate` を実行して frontmatter の妥当性を機械的に確認してからコミットする手順を追加する。

## 動機

- v2.1.233（インストール済みバージョンと一致）で `claude plugin validate` コマンドが
  `.claude/skills` 配下の frontmatter を検証できるようになった
- 本リポジトリは `/harness-improve` サイクル自体で新規スキルを追加する運用をしており
  （例: 過去のサイクルで `dotfiles-drift-check` を追加）、frontmatter の記述ミスを
  コミット前に機械的に検出できる価値がある
- 現状のフェーズ4手順は「変更したら README.md の該当箇所も更新する」で終わっており、
  スキル追加・変更時の検証ステップが明文化されていない

## 変更内容

- `claude/skills/harness-improve/SKILL.md` のフェーズ4節に、スキルファイル
  （`claude/skills/<name>/SKILL.md`）を追加・変更した場合は `claude plugin validate` を実行し、
  警告が出ないことを確認してからコミットする旨の一文を追加する

## リスク・影響

- ドキュメント追記のみで、既存の動作・他 OS への影響はない
- `claude plugin validate` コマンドが実行環境に存在しない場合は手順がスキップされるだけで、
  既存フローを壊さない
