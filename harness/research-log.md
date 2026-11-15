# ハーネス調査ログ

`/harness-improve` の各実行を記録する。新しいエントリを上に追記すること。

<!-- エントリのテンプレート:

## YYYY-MM-DD

- 確認した範囲: CHANGELOG vX.Y.Z まで / 記事 YYYY-MM-DD まで
- 主な発見: （1〜3行で要約）
- 提案: 起案 n 件（採用 x / 却下 y / 保留 z）→ proposals/ 参照

-->

## 2026-11-15

- 確認した範囲: CHANGELOG v2.1.268〜v2.1.325（最新。v2.1.221〜267 は未精査のまま残っており次回継続可）/
  公式ドキュメント hooks・sub-agents・settings・settings-reference を本日時点で確認 /
  Anthropic News を 2026-11-15 時点のトップページまで確認（Fable 5.2 / Mythos 5.2 発表の
  2026-11-09 まで。Claude Code 単体の機能ブログは該当期間内で発見なし）/ コミュニティは
  前回確認済みの gist（techygarg）・shanraisshan リポジトリの更新有無を再確認（実質更新なし）に加え、
  サブエージェント設計・SKILL.md ベストプラクティス・hooks 品質ゲートパターン・モデル世代比較・
  Agent Teams に関する複数の2026年記事を確認（日付不明な記事が多く個別の公開日は未検証のものを含む）
- 主な発見: (1) Opus 5.5（2026-09-22）・Sonnet 5.5（2026-09-28）・Haiku 5.5（2026-10-07）・
  Fable 5.2（2026-11-09、同時に vetted 組織限定の Mythos 5.2 も発表）が各世代デフォルトとして
  順次リリース。本リポジトリはモデル指定を alias（`fable`/`opus`/`sonnet`）か未指定で統一して
  おり pin していないため、このモデル更新自体は追従不要と確認（2026-08-08 の判断方針が機能した）。
  (2) v2.1.277 で Fable が advisor から恒常的に選択可能になり、`model-routing.md` の
  「advisor tool を採用しない理由」メモが前提としていた制約（Fable が advisor で
  temporarily unavailable）が解消済みと確認。(3) v2.1.325 で、`allowed-tools`/`hooks` を
  宣言するスキルを scheduled tasks / `/loop` が無人実行する前に確認を求めるようになり、継続には
  `permissions.allow` への `Skill(<name>)` 追加が必要。本リポジトリの `github-push` スキルが
  対象（`harness-improve` 等は allowed-tools/hooks 未宣言のため対象外）。(4) v2.1.319 で
  `permissions.denyInsteadOfPrompting` が追加（無人実行時の `ask` 項目の扱いに関係しうるが、
  常時適用かどうかは要確認）。(5) hooks イベントが33種に拡充（`PreCompact`/`PostCompact`/
  `PreModelSwitch`/`ConfigChange`/`DirectoryAdded` 等）。(6) SubagentHandback の返却形式が
  v2.1.278 でインデント付きヘッダー区切りになり、report 本文が指示として誤解釈されない
  フレーミングが入った（本サイクルの調査サブエージェント自身の報告でも実際に観測）。
  (7) コミュニティ側では「サブエージェントの自己申告を信用せず hooks で決定的に検証する」
  パターン（quality-gate-keeper 等）が複数ソースで紹介されていたが、個人運用の本リポジトリでは
  commit ブロック等の強制までは過剰と判断し起案は見送り
- 提案: 起案 3 件（新規、いずれも status: proposed）→
  `20261115-advisor-model-fable.md`、`20261115-unattended-skill-permission.md`、
  `20261115-deny-instead-of-prompting.md`。既存の保留提案
  `20260719-subagent-report-contract.md` は判断記録に新知見（SubagentHandback のフレーミング
  強化は別軸であり本提案の必要性は変わらない）を追記（起案数には含めない）。
  `20260720-autoloop.md` は本サイクルの調査範囲に関連する新情報なし
- 備考: 本サイクルは定期実行（スケジュールタスク）のため、フェーズ1・2・5のみを実施し、
  フェーズ3（レビュー・AskUserQuestion）とフェーズ4（実装、claude/ 配下・CLAUDE.md・install
  スクリプトの変更）は行っていない。起案3件はすべて status: proposed のまま。レビューは
  この PR をマージ後、ローカルで `/harness-improve` を実行して採否判断する想定

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

