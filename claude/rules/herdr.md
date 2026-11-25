# herdr の中でセッションを立ち上げる

環境変数 `HERDR_PANE_ID` がある＝herdr（AI エージェント向けターミナルワークスペース）の中で動いている。
このとき「新しいセッションを立ち上げて」「別セッションで〜して」と頼まれたら、**`cc-new` で herdr の中に開く**。
`wt.exe`（Windows Terminal）で別ウィンドウ・別タブを開いてはいけない。

```
cc-new <セッション名> [--cwd パス] [--prompt 最初の指示] [--resume セッションID] [--no-focus]
```

- herdr のソケットを使うので `dangerouslyDisableSandbox: true` で実行する
- セッション名は必ず付ける（`/rename` と同じ名前になる）。名前でカテゴリのスペース
  （dotfiles `claude/herdr-categories.tsv`）へ自動で振り分けられる。名前が無いと「新規: 名前なし」スペースに残る
- 頼まれた作業の内容は `--prompt` で最初の指示として渡せる
- 起動直後にフォルダの信頼確認などで止まることがある。そのときはスペースは残るので、ユーザーに答えてもらう
- 再起動後の一括復元は `/sessions`（`cc-sessions restore --open`）。herdr の中なら同じく herdr に開く
