---
name: wip
description: いま動いている Claude Code セッションをすべて棚卸しし、どれを閉じてよいか・どれに作業が残っているかを一覧で返す。「wip」「セッション整理」「どれ閉じていい？」「再起動したい」で使う。
---

# wip: 動いているセッションの棚卸し

自分自身のセッションだけを見るなら `/park` を使う。

## 1. 一覧を取る

**local-workspace-win（WSL）の場合**は `cc-sessions` を使う。セッション一覧の保存も同時に行うので、
再起動後の復元（local-workspace-win の `/sessions` スキル）の材料になる。

```bash
~/ghq/github.com/mura123yasu/local-workspace-win/bin/cc-sessions --json
```

`/proc` を読むので **`dangerouslyDisableSandbox: true` で実行する**（読み取りと保存だけ）。

**`cc-sessions` が無い環境**では、Claude Code が書く `~/.claude/sessions/<pid>.json` から作る。

- 各ファイルの `pid` が生きているか（`ps -p <pid>`）を確かめ、生きているものだけを対象にする。
  同じ `sessionId` が複数あれば `updatedAt` が新しいものを使う。
- `name`・`status`（busy / idle）・`cwd`・`sessionId` を拾う。
- 直近のやりとりは `~/.claude/projects/<cwd の / と . を - にしたもの>/<sessionId>.jsonl` の末尾から読む。
  最後のユーザーの依頼と、最後のアシスタントの応答テキスト、`pr-link` があればその URL。
  セッションが多くトランスクリプトが長いときは、読むのを explorer に任せて要約だけ受け取る。

## 2. 判定する

自分自身（`sessionId` が `$CLAUDE_CODE_SESSION_ID` と一致、`--json` なら `isCurrent: true`）は
「このセッション」と書き、判定から外す。

| 判定 | 条件の目安 |
| --- | --- |
| 🔴 閉じない | `status` が `busy`（実行中）。または直近の応答がユーザーへの質問・確認依頼で終わっている |
| 🟡 作業が残っている | 応答に「次は〜」「残り」「未マージ」「あとで」など続きが明示されている。PR が開いたまま |
| 🟢 閉じてよい | 依頼が完了報告で終わっていて、続きの話が無い |

- 迷ったら 🟡 に倒す。閉じて困るのは文脈を失うことだけで、`claude --resume` で戻れる。
- PR がマージ済みかは `gh pr view <url> --json state` で裏を取ってよい。
- 🟡 でも、続きが対象リポジトリの `docs/STATUS.md` に書いてあれば「閉じても困らない」と添える。

## 3. 報告する

日本語で、表にする: 「セッション名 | 判定 | 一言の理由（何が残っているか）」。

最後に:

- 🟢 は閉じてよいこと。普通に閉じたセッションは再起動後の復元候補から外れるので、
  再起動前に閉じておくと復元が「本当に開き直したいもの」だけになる。
- 🔴 があれば、再起動の前に片付けるよう促す。
- 🟡 のセッションでは、閉じる前にそのセッションで `/park` を打つと、STATUS.md への
  書き残しまで済ませられる。
- WSL で `cc-sessions` を使った場合は、一覧は保存済みなのでそのまま再起動してよく、
  再起動後は local-workspace-win で「再起動した」と言えば開き直せる。
