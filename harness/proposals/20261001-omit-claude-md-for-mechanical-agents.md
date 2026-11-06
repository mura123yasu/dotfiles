---
title: explorer / mechanic に omitClaudeMd を設定し、委譲のコンテキスト移送コストをさらに下げる
date: 2026-10-01
status: proposed
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md（v2.1.273）
  - https://code.claude.com/docs/en/sub-agents
---

## 概要

`claude/agents/explorer.md` と `claude/agents/mechanic.md` のフロントマターに
`omitClaudeMd: true` を追加する。両エージェントは起動時に user/project/local の
CLAUDE.md を読み込まなくなり、委譲時のコンテキスト移送コストがさらに下がる。

## 動機

- v2.1.273 でカスタム/プラグインサブエージェントのフロントマターに `omitClaudeMd` が追加され、
  `true` にすると CLAUDE.md の自動読み込みをスキップできるようになった
- `claude/rules/model-routing.md` は委譲判断を「コンテキスト移送コスト」と「必要な推論能力」の
  2軸で行うと明記しており、`explorer`（広域探索・要約）と `mechanic`（rename・一括置換・
  lint修正などの機械的作業）はどちらも「指示文だけで完結する」低コンテキスト・低推論の
  タスクを担う haiku エージェントとして設計されている
- 現状の両エージェント定義は依頼文とツール出力だけで完結する手順書になっており、
  本リポジトリの Git ワークフロー・モデルルーティング・スキル運用・マルチリポジトリ管理
  といった CLAUDE.md の内容を読む必要性が乏しい。読み込み自体は小さくても、
  「委譲先に不要な情報を渡さない」という同ルールの方針に忠実な設定変更である
- `strategist` と `reviewer` は対象外とする。`strategist` は昇格トリガー経由で呼ばれる際に
  main の判断文脈（CLAUDE.md が定めるルールそのもの）を踏まえた判断が必要になりうる場面があり、
  `reviewer` もコードレビュー観点でリポジトリ固有のルール逸脱（例: Git ワークフロー違反）を
  検出対象に含めうるため、CLAUDE.md を読める状態を維持する方が安全

## 変更内容

- `claude/agents/explorer.md` フロントマターに `omitClaudeMd: true` を追加
- `claude/agents/mechanic.md` フロントマターに `omitClaudeMd: true` を追加
- `claude/rules/model-routing.md` のエージェント一覧表の近くに、両エージェントが
  `omitClaudeMd: true` である旨を一言注記する

## リスク・影響

- 両エージェントは元々「指示文に書かれた範囲だけをやる」設計（mechanic.md:
  「指示にない『ついでの改善』は行わない」）のため、CLAUDE.md 不読込による
  振る舞い劣化のリスクは小さい
- もし将来 CLAUDE.md 側のルール（例: Git ワークフロー禁止事項）を explorer/mechanic にも
  守らせたい場面が出た場合は、該当ルールを依頼文に明示的に書き下ろす必要がある
  （`model-routing.md` が既に述べる「スキルは自動継承されない」と同種の制約）
- 両 OS 共用ファイル（`claude/agents/`）の変更のみで、install スクリプトへの影響なし
