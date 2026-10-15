# ハーネス調査ログ

`/harness-improve` の各実行を記録する。新しいエントリを上に追記すること。

<!-- エントリのテンプレート:

## YYYY-MM-DD

- 確認した範囲: CHANGELOG vX.Y.Z まで / 記事 YYYY-MM-DD まで
- 主な発見: （1〜3行で要約）
- 提案: 起案 n 件（採用 x / 却下 y / 保留 z）→ proposals/ 参照

-->

## 2026-10-15

- 確認した範囲: CHANGELOG v2.1.300 まで（v2.1.220〜v2.1.300、バグ修正中心の v2.1.221〜283 は機能追加のみ抽出）/ 公式ドキュメント hooks・sub-agents・settings-reference・slash-commands（2026-10-15 時点）/ Anthropic news 2026-10-14 まで、Engineering blog は 2026-05-25 が最新で更新なし / コミュニティは claudeissues.com を 2026-01〜2026-08-23 の範囲で確認（ウィンドウ内の新規投稿は issue #88995 のみ）。Reddit・Hacker News Algolia API は本環境のプロキシから到達不可で今回も調査不能
- 主な発見: (1) `advisorModel` が公式に `"fable"` を受け付けると settings-reference に明記され、2026-08 時点で「Fable は advisor に選べない」としていた既知の制約が解消された。(2) v2.1.295+ でフックハンドラ共通フィールド `onFailure`（既定 `"continue"`）が追加され、guard.sh のような PreToolUse ガードが異常終了した場合に素通りする経路が設定レベルで塞げるようになった。(3) Agent ツール呼び出し単位で `effort` を指定できる機能（v2.1.292、frontmatter より優先・resume 後も保持）を確認。(4) コミュニティ側では v2.1.163（2026-06-04）以降 SubagentStop の `additionalContext` 返却がフックエラー扱いされないことが裏付けられ、既存の保留提案（`20260719-subagent-report-contract.md`）の実装方針を補強した一方、未解決の SubagentStop イベント信頼性の穴（issue #88995、agent_type 空・transcript 不在）も確認した。(5) 2026年6-7月に集中したサブエージェント再帰的増殖バグ（計画した3〜5体が最大583体に増殖、Windows で CPU 100% ハング）は v2.1.217（2026-07-21/22）で既定動作（ネスト不可・同時実行数20キャップ）として修正済みであり、本リポジトリの「並列2〜4推奨」ルールを裏付ける実例として記録（既に修正済みのため新規提案はしない）
- 提案: 新規起案 3 件（いずれも status: proposed）→ `20261015-advisor-fable.md`、`20261015-hook-onfailure-block.md`、`20261015-agent-call-effort-param.md`。既存の保留提案 `20260719-subagent-report-contract.md` には新たな裏付け情報と実装時の注意点を判断記録に追記（起案数には含めない、status は proposed のまま）
- 備考: `sandbox.network.strictAllowlist`（user/managed スコープ）や `maxEffortLevel` / `allowedProviders` 等の新設定も確認したが、具体的な適用先（許可すべきホスト一覧の精査等）が今回の調査だけでは詰められず起案は見送った。次回サイクルで深掘りする価値がある。今回はフェーズ1・2・5のみを実施し、フェーズ3（レビュー）・4（実装）は行っていない（定期実行の制約）

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

