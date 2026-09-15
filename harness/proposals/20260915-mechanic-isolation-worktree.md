---
title: mechanic に isolation: worktree を付与する
date: 2026-09-15
status: proposed
sources:
  - https://code.claude.com/docs/en/sub-agents.md（Supported frontmatter fields / isolation）
  - https://www.totalum.app/blog/claude-code-subagents-totalum
  - https://www.tembo.io/blog/claude-code-subagents
---

## 概要

`claude/agents/mechanic.md` の frontmatter に `isolation: worktree` を追加し、
ファイル編集を行う `mechanic` の実行を一時的な git worktree 上に隔離する。

## 動機

- 公式ドキュメント（sub-agents リファレンス）に、サブエージェント frontmatter で
  `isolation: worktree` を指定すると、既定ブランチから分岐した一時 worktree の
  独立コピー上でそのサブエージェントを実行できると明記されている
- コミュニティのプロダクション運用プレイブック複数（totalum, tembo）で、
  「ファイルを書き込む subagent には `isolation: worktree` をデフォルトで付けるべき」
  という合意が共有されている。コストはほぼゼロで、並列 agent 間のファイル衝突
  （同一 checkout への同時編集）を防げるとされる
- `claude/rules/model-routing.md` は並列委譲を「2〜4体を目安にする」と定めており、
  `mechanic`（Edit/Write ツールを持つ）が並列実行された場合に同一チェックアウトへの
  書き込み競合が起きうる。`explorer`/`strategist`/`reviewer`/`harness-researcher` は
  読み取り専用ツールのみなので対象外

## 変更内容

- `claude/agents/mechanic.md` の frontmatter に `isolation: worktree` を追加する
- 変更したら `harness/README.md` の該当説明（あれば）も更新する

## リスク・影響

- worktree 隔離下では、`mechanic` が変更を加えなかった場合は worktree が自動的に
  クリーンアップされるが、変更を加えた場合は worktree のパスとブランチが結果として
  返る。呼び出し元（main セッション）は、その変更をメインの checkout に取り込む
  追加の一手間（マージ・チェリーピック等）が必要になる。「機械的作業を投げっぱなしで
  終わらせる」という `mechanic` の軽量さと、この一手間がトレードオフになる点は
  実装時にレビューが必要
- worktree はメインの checkout から独立したコピーであるため、`mechanic` が
  メインチェックアウトのファイルパスに直接アクセスしようとするコマンドは失敗する
  （公式ドキュメントに明記）。`mechanic` の想定タスク（rename・一括置換・
  フォーマット適用・テスト実行・lint 修正）はすべて worktree 内で完結するはずだが、
  実装時に実タスクで動作確認が必要
- 両 OS（Mac/WSL）で git worktree 機能自体は共通のため、OS 差分リスクは低い
- 運用負荷: 変更が発生した mechanic 実行のたびに worktree の後始末（マージ後の
  worktree 削除等）が増える可能性がある
