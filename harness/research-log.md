# ハーネス調査ログ

`/harness-improve` の各実行を記録する。新しいエントリを上に追記すること。

<!-- エントリのテンプレート:

## YYYY-MM-DD

- 確認した範囲: CHANGELOG vX.Y.Z まで / 記事 YYYY-MM-DD まで
- 主な発見: （1〜3行で要約）
- 提案: 起案 n 件（採用 x / 却下 y / 保留 z）→ proposals/ 参照

-->

## 2026-11-01

- 確認した範囲: CHANGELOG は v2.1.316 まで存在を確認（詳細に内容を精査したのは v2.1.284〜v2.1.316。
  v2.1.220〜v2.1.283 は分量の都合で今回は個別確認せず、次回サイクルへ持ち越し）/ 公式ドキュメント
  （hooks, sub-agents, skills, settings）を現行版で確認 / Anthropic News は 2026-09-09〜2026-10-28
  の全項目を確認 / Anthropic Engineering は 2026-04-23 以降の更新有無のみ確認（記事本文は未読）/
  コミュニティは WebFetch 制約（dev.to 等への `ENOTFOUND` が前回同様継続）の中で検索スニペット中心に
  2026-11-01 時点まで確認
- 主な発見: (1) hooks に `onFailure: "block"` が追加され、command/http タイプの hook が
  クラッシュ・タイムアウト・不正出力を返した場合の挙動を「素通り」から「ブロック」に変更できるように
  なった（CHANGELOG v2.1.295）→ 最終防壁として設計されている guard.sh のフェイルオープンな現状の
  ギャップとして起案。(2) Haiku 5.5 / Sonnet 5.5 / Opus 5.5 がリリースされ各エイリアスのデフォルトに
  なったが、本リポジトリはモデルをエイリアス指定のみで運用しているため変更なしで追従済みと確認。
  (3) `CLAUDE_CODE_SUBAGENT_MODEL` / `_FORCE` 系環境変数・`CLAUDE_CODE_EFFORT_LEVEL` によるモデル/
  effort の強制を再確認したが、本リポジトリの `.zshrc` 等にはいずれも未設定で現状問題なし。
  (4) Auto Mode（新しい自動権限承認モード、`--enable-auto-mode`）の発表を確認したが、本リポジトリは
  明示的な permissions allow/ask/deny と guard.sh による手動管理を継続する方針のため採用検討は見送り
  （有効化もしていないことを確認）。(5) 実験的 hook handler type `agent` はガード判定の柔軟化に
  使えそうだが experimental のため今回は見送り
- 提案: 起案 1 件（新規、status: proposed）→ `20261101-guard-hook-onfailure-block.md`。既存の保留提案
  `20260719-subagent-report-contract.md` は今回フェーズ3（レビュー）を実施しないため判断せず、保留継続
- 備考: CHANGELOG の v2.1.220〜v2.1.283 区間は未精査のまま残っている。次回サイクルでこの区間の
  見落としがないか優先的に確認すること。コミュニティ情報源の WebFetch 制約（dev.to / Reddit /
  Hacker News 本文へのアクセス不可）は今回も継続しており、環境側のプロキシ許可ドメイン拡張の検討は
  依然ペンディング

## 2026-08-08

- 確認した範囲: 新規の Web 調査なし（フェーズ3・4 のみ実施）。PR #38 でマージ済みの起案2件と、保留中だった `20260719-subagent-report-contract.md` の採否を判断した。実装前の裏取りとして公式ドキュメント hooks（SubagentStop セクション）と settings スキーマを再確認
- 主な発見: (1) `fallbackModel` は設定スキーマ上「model name or alias」を受け付けるため、モデル ID を pin せずエイリアスで世代追随させられる。(2) main の推奨モデルが Opus 5 になったことで、fallback を Opus 5 に pin すると過負荷時の逃げ先が primary と同一モデルになり fallback として機能しなくなる。(3) SubagentStop の入力 JSON に `last_assistant_message` / `agent_id` / `agent_type` が存在し、matcher はエージェント種別で絞れることを再確認
- 提案: 新規起案 0 件。既存3件を判断（採用 2 / 却下 0 / 保留 1）→ `20260802-fallback-model-opus5.md`（変形採用）、`20260802-subagent-delegation-practices.md`（採用）、`20260719-subagent-report-contract.md`（保留継続）
- 備考: 同サイクルで settings.json の `"model": "default"` が無効値であることが判明し PR #41 で削除した（`default` が指定解除として通るのは `/model` コマンド・`--model` フラグ・`fallbackModel` の要素だけで、`model` キーでは未知のモデル名として扱われ context window を 200k と誤認する）。この経験から fallbackModel も pin ではなくエイリアス指定を選択した。また main のブランチ保護は classic branch protection ではなく ruleset で設定済みであることを確認（`branches/*/protection` API は ruleset 保護下でも 404 を返すため、確認は `rulesets` API を使うこと）

## 2026-08-02

- 確認した範囲: CHANGELOG v2.1.220 まで（v2.1.215〜220 を精査）/ 公式ドキュメント hooks（SubagentStop セクション直接確認）・sub-agents・settings / Anthropic News 2026-07-24（Opus 5 発表）まで・Engineering ブログは 2026-04-23 以降更新なし / コミュニティは日付確度高く確認できたもので gist.github.com（2026-08-01 更新）・github.com/shanraisshan/claude-code-best-practice（2026-08-01 更新バッジ）まで
- 主な発見: (1) SubagentStop フックの入力 JSON に `last_assistant_message`（サブエージェント最終報告本文そのもの）が存在すると確認、前回保留提案の技術的不確実性を解消。(2) Claude Opus 5 が 2026-07-24 リリース・Claude Code のデフォルト Opus に。価格は旧 Opus 4.8 と同額でフロンティア性能が Fable 5 に近づいたとされる。(3) v2.1.219 で `sandbox.network.strictAllowlist`・`DirectoryAdded` hook・`workflowSizeGuideline`・サブエージェントのネスト深さ3対応が追加されたが、本リポジトリで具体的な適用先がなく起案は見送り。(4) コミュニティ知見（gist、2026-08-01）でサブエージェント委譲の運用ノウハウ（並列バッチサイズ2〜4推奨、スキルはサブエージェントに自動継承されない、完了待ちにステータスポーリングをしない）を確認
- 提案: 起案 2 件（新規、いずれも status: proposed）→ `20260802-fallback-model-opus5.md`、`20260802-subagent-delegation-practices.md`。既存の保留提案 `20260719-subagent-report-contract.md` は判断記録に技術的不確実性の解消を追記（起案数には含めない）
- 備考: 調査フェーズで使用したサブエージェントの1体（コミュニティ担当）が起動6分後にインタラプトされ、完了通知が来ないまま約24時間放置される事象が発生（再実行して復旧）。原因はこのセッションを動かすコンテナの一時停止・再開に巻き込まれたためと推測される。また、この実行環境の WebFetch は `code.claude.com` / `github.com` / `gist.github.com` 系以外（Reddit・Hacker News Algolia API・dev.to・Substack・Medium 等）へのアクセスがほぼ全て 403 で失敗し、コミュニティ調査の情報源が制約された。次回サイクルでは環境側のプロキシ許可ドメイン拡張を検討するか、既存の許可ドメイン内で完結する情報源を優先すること

## 2026-07-19

- 確認した範囲: CHANGELOG v2.1.214 まで / 公式ドキュメント（hooks, skills, settings, sub-agents）・Anthropic ブログ 2026-07-19 時点 / コミュニティ記事 marmelab（2026-04-24）ほか
- 主な発見: 組み込み Explore のセッションモデル継承化（v2.1.198）、`fallbackModel` 設定（v2.1.166）、SKILL.md 新フロントマター群（context: fork / paths / disallowed-tools）と skillOverrides、hooks イベント大幅拡張（SubagentStop / Stop の completion gate パターン）、Gotchas セクション運用、commands の skills 統合
- 提案: 起案 3 件（採用 2 / 却下 0 / 保留 1）→ proposals/ 参照
- 備考: guard.sh のブロックメッセージ改善（次アクション明示）は確認の結果すでに満たしており起案せず。`context: fork` は既知バグ（Issue #49559）のため見送り

