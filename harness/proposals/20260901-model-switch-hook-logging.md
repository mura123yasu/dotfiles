---
title: PreModelSwitch/PostModelSwitch フックでモデル切替を可視化する
date: 2026-09-01
status: proposed
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md
  - https://code.claude.com/docs/en/hooks
---

## 概要

`PreModelSwitch` / `PostModelSwitch` フックイベント（CHANGELOG v2.1.251 で追加、
`code.claude.com/docs/en/hooks` に正式仕様化済み）を使い、モデル切替が発生した際に
`~/.claude/logs/` 等へ1行ログを残す軽量スクリプトを追加する。

## 動機

- `claude/rules/model-routing.md` は `fallbackModel: ["opus", "sonnet"]` を運用しているが、
  実際にいつ・何回フォールバックが発動したか（過負荷・Fable安全分類器による拒否等）を
  確認する手段が現状ない。research-log.md の過去エントリでも「advisor tool が Fable を
  選べない」等モデル関連の挙動を推測ベースで扱っており、実測ログがあれば裏取りが容易になる
- `PreModelSwitch` は `permissionDecision` でブロックも可能な仕様だが、今回はまず観測（ログ）
  のみに留め、ブロック用途は使わない（安全側に倒す）

## 変更内容

- `claude/hooks/model-switch-log.sh` を新規作成: PreModelSwitch/PostModelSwitch の入力 JSON
  から切替前後のモデル名と理由（分かれば）を1行 JSON で `~/.claude/logs/model-switches.log`
  に追記する（jq + bash のみ、両 OS 共用）。何も deny/block しない（`exit 0` のみ）
- `claude/settings.json` の `hooks` に `PreModelSwitch` / `PostModelSwitch` エントリを追加
- `claude/rules/model-routing.md` の fallbackModel 節に、ログで運用実態を確認できる旨を1行追記

## リスク・影響

- ログファイルが際限なく肥大化する可能性 → ローテーション等は初期実装では省略し、
  問題が出たら別途対応（過剰設計を避ける）
- PreModelSwitch 側で万一 JSON 出力を誤ると意図せぬ block 扱いになるリスクがあるため、
  実装時は「何も出力しない＝許可」の仕様を確認してから書く
- 個人 dotfiles のため他ユーザーへの影響はなし。両 OS（install.sh / install.wsl.sh）で
  スクリプトのリンクを通す必要がある
