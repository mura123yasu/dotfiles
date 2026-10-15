---
title: advisorModel に fable を設定する（Fable が advisor として公式サポートされた）
date: 2026-10-15
status: proposed
sources:
  - https://code.claude.com/docs/en/settings-reference
---

## 概要

`claude/settings.json` に `"advisorModel": "fable"` を追加し、main セッション（Opus 系）が
判断に迷う場面で Fable の第二意見をその場で得られるようにする。合わせて
`claude/rules/model-routing.md` の「advisor tool を採用しない理由」節を、Fable が advisor
として選択可能になった現状に合わせて更新する。

## 動機

`model-routing.md` には既知の制約として「現時点では Fable を advisor に選べない
（`/advisor` で "Fable 5 (temporarily unavailable)" として無効表示）」こと、main が Opus の場合
advisor も Opus 止まりで「より強いモデルへの昇格」にならずトークンだけ増えるため見送る、
という判断記録が残っている。同時に「ロールアウトで Fable が advisor に開放されたら
`"advisorModel": "fable"` を再検討する」と明記されている。

2026-10-15 の公式ドキュメント調査（code.claude.com/docs/en/settings-reference）で、
`advisorModel` 設定（`/advisor` コマンドでも同等の設定が可能）が `"fable"` / `"opus"` /
`"sonnet"` / フルモデルIDを受け付けると明記されていることを確認した。Fable 利用には
事前に `/model fable` でのクレジット同意が必要、`--advisor` での1セッション限定の上書きも
可能、とある。再検討の前提条件（Fable が advisor に開放されたこと）が満たされたため、
見送り判断を更新する時期に来ている。

## 変更内容

- `claude/settings.json` に `"advisorModel": "fable"` を追加
- `claude/rules/model-routing.md` の「advisor tool を採用しない理由（将来の再検討メモ）」節を
  更新: 既知の制約（Fable 選択不可）が解消されたことを記録し、
  - advisor（その場で第二意見を聞く、会話全体を読ませる軽量な確認）と
  - strategist への委譲（持ち場を渡して任せる、昇格トリガーに該当する重い判断）
  の役割分担を明文化する

## リスク・影響

- Fable 利用には事前のクレジット同意（`/model fable`）が必要。ユーザー側で未同意の場合、
  advisor 呼び出し時に失敗する可能性がある → 導入時にユーザーへの事前確認が必要
- advisor は会話全体を読ませる機能のためトークン消費が増える。判断点でのみ呼ばれる想定だが、
  呼び出し頻度が高くなるとコスト増につながる
- strategist による委譲と役割が重複しうる。「その場の確認」と「持ち場を渡す委譲」の違いを
  ルールに明記しないと、使い分けが曖昧になり効果が薄れる
