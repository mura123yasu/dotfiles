---
title: harness-improve の調査フェーズに /doctor prompt-audit を組み込む
date: 2026-10-01
status: proposed
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md（v2.1.284）
---

## 概要

`claude/skills/harness-improve/SKILL.md` の「1. 調査」フェーズに、新しく追加された
`/doctor prompt-audit`（`/checkup prompt-audit`）の実行を組み込む。CLAUDE.md・
`claude/skills/**/SKILL.md`・`claude/agents/*.md` を対象に、旧世代モデル向けの
書き方が残っていないかを機械的に検出してから Web 調査に入るようにする。

## 動機

- v2.1.284 で、CLAUDE.md・skills・agents・commands を対象に「旧世代モデル向けに
  書かれたプロンプトパターン」を監査する `/doctor prompt-audit` コマンドが追加された
- `harness-improve` サイクルは現状、Web 調査（公式 CHANGELOG・ドキュメント・コミュニティ知見）
  だけを起点に改善点を見つけている。しかし本リポジトリ自身の CLAUDE.md・5エージェント定義・
  3スキルが「現行のベストプラクティスに対して古い書き方になっていないか」を直接検査する
  手段がこれまで存在せず、Web 調査側の守備範囲外になっていた
- 本リポジトリは `claude/agents/` に5つの、`claude/skills/` に3つのカスタム定義を持ち、
  今後も `harness-improve` サイクルで増えていく見込みのため、増加に比例してこの種の
  陳腐化リスクも増える。機械的に検出できるものを人手（Web 調査との突き合わせ）に
  頼り続けるのは非効率

## 変更内容

- `claude/skills/harness-improve/SKILL.md` の「### 1. 調査」節に以下を追記:
  - harness-researcher への委譲と並行して（または直前に）`/doctor prompt-audit` を実行する
  - 検出された指摘は、Web 調査の結果と同様に「2. 立案」フェーズの材料として扱う
    （指摘ごとに提案を起案するかはこれまで通り価値判断する）
- `harness/README.md` の「サイクル」節の「調査」の説明に一言追記
  （`harness-researcher` による Web 調査に加えて `/doctor prompt-audit` による
  自己診断も行う旨）

## リスク・影響

- `/doctor prompt-audit` はリポジトリ内のファイルを読むだけの診断コマンドで、
  破壊的な変更は行わない想定（公式ドキュメントで実行時の挙動詳細までは未確認のため、
  実装時に一度 `--help` 相当の確認を行うこと）
- 誤検知（本リポジトリの意図的な書き方を「旧式」と誤判定する）があっても、
  従来通り「2. 立案」フェーズで価値判断するため実害は小さい
- SKILL.md・README.md のみの変更で、install スクリプトへの影響なし
