# ハーネス調査ログ

`/harness-improve` の各実行を記録する。新しいエントリを上に追記すること。

<!-- エントリのテンプレート:

## YYYY-MM-DD

- 確認した範囲: CHANGELOG vX.Y.Z まで / 記事 YYYY-MM-DD まで
- 主な発見: （1〜3行で要約）
- 提案: 起案 n 件（採用 x / 却下 y / 保留 z）→ proposals/ 参照

-->

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

