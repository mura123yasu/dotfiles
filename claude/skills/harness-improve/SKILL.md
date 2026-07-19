---
description: Claude Code の新機能・ベストプラクティスを調査し、ハーネス（skills / agents / hooks / rules / settings）の拡張を立案 → ユーザーレビュー → 実装するサイクルを回す
argument-hint: なし（オプションで「調査のみ」「proposals/XXX を実装」等）
---

## Context

- ハーネス構成: !`ls -R ~/ghq/github.com/mura123yasu/dotfiles/claude`
- 調査ログ（直近）: !`head -40 ~/ghq/github.com/mura123yasu/dotfiles/harness/research-log.md 2>/dev/null || echo "（ログなし＝初回実行）"`
- 既存の提案と状態: !`grep -H '^status:' ~/ghq/github.com/mura123yasu/dotfiles/harness/proposals/*.md 2>/dev/null || echo "（提案なし）"`

## Your task

dotfiles リポジトリ（`~/ghq/github.com/mura123yasu/dotfiles`）の Claude Code ハーネスを、
最新情報に追従して改善するサイクルを1周回す。仕組みの全体像は `harness/README.md` を参照。
引数で「調査のみ」「proposals/XXX を実装」等の指示があれば、該当フェーズだけ実施する。

### 1. 調査（harness-researcher に委譲）

- 調査ログの最新エントリから前回の確認範囲（日付・CHANGELOG バージョン）を読み取り、それ以降を調査対象とする。初回は直近3ヶ月
- `harness-researcher` エージェントを **2並列** で起動する:
  - 公式情報担当: CHANGELOG・公式ドキュメント・Anthropic ブログの更新
  - コミュニティ担当: tips・ベストプラクティス・活用事例
- main セッションでは Web 調査しない（context 汚染回避。model-routing ルール準拠）
- status: proposed のまま残っている過去の保留提案があれば、このフェーズと並行して内容を再確認しておく

### 2. 立案

調査結果を Context のハーネス構成・CLAUDE.md・claude/rules と突き合わせ、
このリポジトリに取り込む価値のある拡張案を **0〜5件** 起案する。

- 過去に status: rejected になった提案と同内容のものは再提案しない（却下理由を必ず読む）
- 価値のある案がなければ起案ゼロで構わない。無理に作らない
- 各案は `harness/proposals/YYYYMMDD-<slug>.md` に以下の形式で書く:

```markdown
---
title: <一言タイトル>
date: YYYY-MM-DD
status: proposed
sources:
  - <根拠となった出典 URL>
---

## 概要

（何をどう変えるか、1〜3文）

## 動機

（調査で得た根拠。なぜ今このリポジトリに必要か）

## 変更内容

（対象ファイルと変更の概要。箇条書き）

## リスク・影響

（壊れうるもの、他 OS への影響、運用負荷の増減）
```

### 3. レビュー（ユーザー判断）

- 各提案の要点（1〜2文＋変更対象ファイル）を提示し、AskUserQuestion で採否を確認する（採用 / 却下 / 保留）
- 却下されたら理由を確認し、提案ファイルに `status: rejected` と却下理由を記録する（将来の再提案防止）
- 保留は `status: proposed` のまま残す（次回実行時に再提示される）
- **ユーザーの判断なしに実装へ進まない**

### 4. 実装

採用された提案をハーネスに実装し、提案ファイルを `status: done` に更新する。よくある対象:

- `claude/skills/<name>/SKILL.md` — 新スキル。**install.sh / install.wsl.sh の両方にリンク行を追加**し、自端末分は実際にリンクを張る
- `claude/agents/<name>.md` — 新エージェント（ディレクトリごとリンク済みのため追加のみで反映される）
- `claude/hooks/` + `claude/settings.json` — フック追加
- `claude/rules/`・`CLAUDE.md` — ルール変更
- 変更したら README.md の該当箇所（ファイル管理方針の表・機構の説明）も更新する

### 5. 記録と PR

- `harness/research-log.md` の先頭に今回のエントリを追記する（日付・確認した範囲・主な発見の要約・提案数と採否）
- **main への直接 commit は禁止**。`feature/harness-improve-YYYYMMDD` ブランチで、提案ファイル・調査ログ・実装をまとめてコミットし、PR を作成する（起案ゼロならログ更新のみを `chore/harness-log-YYYYMMDD` で PR）
- 最終報告: 主な発見、各提案の採否、PR の URL、ユーザーに残る作業（他端末でのリンク展開等）を簡潔にまとめる
