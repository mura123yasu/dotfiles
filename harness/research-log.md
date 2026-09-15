# ハーネス調査ログ

`/harness-improve` の各実行を記録する。新しいエントリを上に追記すること。

<!-- エントリのテンプレート:

## YYYY-MM-DD

- 確認した範囲: CHANGELOG vX.Y.Z まで / 記事 YYYY-MM-DD まで
- 主な発見: （1〜3行で要約）
- 提案: 起案 n 件（採用 x / 却下 y / 保留 z）→ proposals/ 参照

-->

## 2026-09-15

- 確認した範囲: CHANGELOG v2.1.271 まで（前回確認済みの v2.1.220 以降、v2.1.257〜v2.1.271 を重点確認。v2.1.221〜v2.1.256 の中間区間は要約ツールの制約で個別バレット未確認の可能性があり次回要再確認）/ 公式ドキュメント hooks・sub-agents・skills・settings-reference・model-config を確認 / Anthropic news・engineering は `anthropic.com`/`claude.com` への直接 WebFetch がこの実行環境のプロキシで遮断され本文未読（WebSearch のスニペットのみ。2026-09-14 付の CI 記事を検知したがハーネス関連度は低）/ コミュニティは WebSearch ベースで 2026-09-09 まで確認（Reddit/HN 系サイトへの直接 WebFetch は前回同様ほぼ 403）
- 主な発見: (1) v2.1.271 で agent frontmatter に `omitClaudeMd`（CLAUDE.md 読み込み省略）が追加されたが、公式 sub-agents リファレンスにはまだ未掲載でドキュメント反映待ちと判明。(2) 公式 sub-agents リファレンスで `isolation: worktree`（サブエージェントを一時 git worktree に隔離実行）を確認、コミュニティ複数ソースも「ファイル書き込み系 subagent にはデフォルトで付けるべき」と一致。(3) `maxEffortLevel`（v2.1.267、settings.json、値は effortLevel と同じ low/medium/high/xhigh）はサブエージェント frontmatter の `effort` も含めて上限キャップすることを公式ドキュメントで確認 — `strategist` の `effort: max` を弱める方向に働くため本リポジトリでは非採用と判断（起案せず）。(4) `bashOutputMaxChars`/`taskOutputMaxChars`（v2.1.261、既定 8000/16000 文字、上限 128K）を確認したが、具体的な支障事例がなく起案は見送り。(5) Claude Fable 5.1（v2.1.257）関連のバグ（`model: fable` エージェントの context window タグ無視・プロンプトキャッシュ無効化等）は v2.1.260 で解消済みと確認、本リポジトリはエイリアス指定（`model: fable`）のため影響なし・対応不要。(6) コミュニティで「Claude Mods」（TypeScript製ミドルウェア方式の新 hook、`CLAUDE_ENABLE_FUNCTION_HOOKS=1` で先行テスト可、2026-09-09 時点で「数週間以内に出荷」予告）の動きを検知。未リリースの実験的機能のため今回は起案せず、次回サイクルで追跡する
- 提案: 新規起案 2 件（いずれも status: proposed）→ `20260915-mechanic-isolation-worktree.md`、`20260915-omit-claude-md-explorer-mechanic.md`。既存の保留提案 `20260719-subagent-report-contract.md` は今回のフェーズ3（レビュー）非実施のため判断せず `status: proposed` のまま維持
- 備考: 今回は定期実行のため、フェーズ3（レビュー）・フェーズ4（実装）は行っていない。両提案とも `/harness-improve` 実行時にローカルでレビュー・採否判断が必要

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

