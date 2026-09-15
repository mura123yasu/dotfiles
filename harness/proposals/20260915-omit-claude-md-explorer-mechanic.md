---
title: explorer / mechanic に omitClaudeMd を付与し CLAUDE.md 読み込みを省略する
date: 2026-09-15
status: proposed
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md（v2.1.271）
---

## 概要

`claude/agents/explorer.md` と `claude/agents/mechanic.md` の frontmatter に
`omitClaudeMd: true` を追加し、ユーザー/プロジェクトの CLAUDE.md 読み込みを
省略してコンテキスト移送コストを下げる。

## 動機

- CHANGELOG v2.1.271: 「Added `omitClaudeMd` to agent frontmatter and `--agents`
  JSON, letting custom and plugin subagents run without user, project and local
  CLAUDE.md files; managed policy files still load」と明記されている
- `claude/rules/model-routing.md` の委譲判断は「コンテキスト移送コスト」と
  「必要な推論能力」の2軸を掲げている。`explorer`（広域コード探索・要約）と
  `mechanic`（rename・一括置換・テスト実行等の機械的作業）はどちらも
  fresh context で起動し、対象リポジトリの CLAUDE.md が定めるような
  ワークフロー規約（git 運用・モデルルーティング方針等）を読む必要のない
  純粋な事実確認・定型作業を担う。CLAUDE.md 読み込みの省略はこの2軸のうち
  「コンテキスト移送コスト」を直接下げる
- このリポジトリの `install.sh` / `install.wsl.sh` で `explorer`/`mechanic` は
  他リポジトリにもリンクされて使われる想定であり、リンク先リポジトリの
  CLAUDE.md が長い場合ほど省略の効果が大きい

## 変更内容

- `claude/agents/explorer.md` の frontmatter に `omitClaudeMd: true` を追加
- `claude/agents/mechanic.md` の frontmatter に `omitClaudeMd: true` を追加
- `strategist` / `reviewer` / `harness-researcher` は対象外とする
  （`strategist` は設計判断のため CLAUDE.md の規約を踏まえる必要がある。
  `reviewer` はコードレビューでプロジェクト規約との整合を見る必要がある。
  `harness-researcher` は Web 調査主体で CLAUDE.md の要否が薄く、今回は
  変更の影響範囲を絞るため対象外とした）

## リスク・影響

- **ドキュメント未反映のリスク**: `omitClaudeMd` は CHANGELOG (v2.1.271) には
  記載があるが、調査時点（2026-09-15）で公式サブエージェントリファレンス
  （https://code.claude.com/docs/en/sub-agents.md）の frontmatter フィールド表には
  未掲載だった。ドキュメント反映待ちの可能性があるため、実装前に値の型
  （boolean 以外の可能性）・挙動を再確認すること（SKILL.md Gotchas の
  「settings.json に新しい設定キーを追加する提案は実装前に claude-code-guide
  エージェントで確認する」に準じ、frontmatter フィールドについても同様に扱う）
- `explorer`/`mechanic` が CLAUDE.md 由来のプロジェクト固有規約
  （例: 特定リポジトリだけのコーディング規約・禁止コマンド等）を知らずに
  作業する副作用がありうる。ただし両エージェントとも「指示にない改善はしない」
  「判断を要する変更は保留」という設計のため、規約逸脱のリスクは限定的
- managed policy files は引き続き読み込まれるため、`claude/settings.json` の
  permissions/hooks によるガードレール（`guard.sh` 等）は影響を受けない
