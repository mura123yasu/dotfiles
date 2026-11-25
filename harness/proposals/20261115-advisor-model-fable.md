---
title: advisorModel に fable を設定する（Fable の advisor 制約が解消）
date: 2026-11-15
status: proposed
sources:
  - https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md（v2.1.277）
  - https://code.claude.com/docs/en/settings-reference
---

## 概要

`claude/settings.json` に `"advisorModel": "fable"` を追加する。`claude/rules/model-routing.md`
の「advisor tool を採用しない理由」セクションも、制約解消を反映して更新する。

## 動機

- `model-routing.md` には「Fable を advisor に選べない（`/model` で "temporarily unavailable"）ため
  見送り、ロールアウトで開放されたら再検討する」という将来の再検討メモが明記されている
- 公式 CHANGELOG v2.1.277 で、Fable は「組織が無効化しない限り常に `/model` に表示される」ように
  なったと確認した。2026-08-02 時点の利用不可制約は解消済み
- advisor は主モデル以上の能力が必要という制約があるとされる。main セッションは `model` キーを
  置かず推奨モデルに追随しているため、advisor（fable）が主モデル以上であることは満たせる見込み

## 変更内容

- `claude/settings.json` の `permissions` 等と同階層に `"advisorModel": "fable"` を追加
- `claude/rules/model-routing.md` の「advisor tool を採用しない理由」セクションを、
  制約解消済みである旨と、採用した場合の運用（いつ advisor が呼ばれるか、追加コストの扱い）に更新

## リスク・影響

- `advisorModel` の正確なキー名・発火条件（判断点ごとに常時呼ばれるのか、明示的な `/advisor`
  呼び出し時のみか）は settings-reference の記述を実装前に `claude-code-guide` エージェントで
  再確認すること（SKILL.md Gotchas 準拠）
- advisor 呼び出しは追加のモデル利用（≒追加コスト）を伴う可能性がある。効果（判断品質の向上）と
  コストのバランスを、実装後に実際の使用感で検証する必要がある
- 使用クレジット同意が必要な場合、先に `/model fable` を一度実行しないと `/advisor` での選択が
  保存されない旨の注意がある（CLI 設定時の手順に影響する可能性）

## 統合メモ（2026-11-26）

同じテーマの `20261015-advisor-fable.md`（PR #55）をこのファイルに統合した。そちらにだけあった論点:
- advisor（その場の第二意見。会話全体を読ませる）と strategist（持ち場ごと委譲する）の役割分担を、
  採用時に model-routing.md へ明文化すること
- 2つの役割が重なり、使い分けが曖昧になるリスク
