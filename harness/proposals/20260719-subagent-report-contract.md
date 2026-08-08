---
title: SubagentStop フックでサブエージェント報告の「納品契約」を強制する
date: 2026-07-19
status: proposed
sources:
  - https://www.totalum.app/blog/claude-code-hooks-totalum
  - https://code.claude.com/docs/en/hooks
---

## 概要

SubagentStop フックを追加し、カスタムサブエージェント（reviewer / explorer / harness-researcher）の
報告が各エージェント定義の必須形式（`path:line` の根拠、出典 URL 等）を満たしているかを検査する。
満たしていなければ `additionalContext` で親セッションに再実行・却下を促す。

## 動機

- 各エージェント定義には報告形式の指示があるが、守られなかった場合の強制手段がない
  （例: reviewer が根拠位置なしで指摘する、researcher が出典 URL なしで報告する）
- コミュニティで「Skills/Agents が手順を教え、Hooks がそれを強制する」パターンとして推奨されている
- hooks は現状 PreToolUse ガード1本のみで、出力品質側のガードレールが存在しない

## 変更内容

- `claude/hooks/subagent-contract.sh` を新規作成: SubagentStop イベントの JSON から
  エージェント種別と最終報告を読み取り、種別ごとの必須パターン（reviewer → `path:line`、
  harness-researcher → URL）を欠く場合に `additionalContext` で警告を返す
- `claude/settings.json`: hooks に SubagentStop エントリを追加

## リスク・影響

- 3提案の中で最も実装が重い。SubagentStop の入力 JSON からの報告本文の取り出しは
  実装時に仕様確認が必要（取り出せない場合は機械的チェックが緩くなる）
- 誤検知（正当な「発見なし」報告を形式違反と判定する等）があると再実行ループでトークンを浪費する。
  警告は deny でなく additionalContext に留め、強制力を弱めに設計することで緩和する
- 検査はローカルスクリプトのみで完結し、両 OS 共用（bash + jq のみ使用）

## 判断記録

- 2026-07-19: 保留。効果は見込めるが実装が重く、SubagentStop の入力 JSON 仕様
  （最終報告本文を取り出せるか）の確認が先。次回サイクルで再検討
