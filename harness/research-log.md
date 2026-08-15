# ハーネス調査ログ

`/harness-improve` の各実行を記録する。新しいエントリを上に追記すること。

<!-- エントリのテンプレート:

## YYYY-MM-DD

- 確認した範囲: CHANGELOG vX.Y.Z まで / 記事 YYYY-MM-DD まで
- 主な発見: （1〜3行で要約）
- 提案: 起案 n 件（採用 x / 却下 y / 保留 z）→ proposals/ 参照

-->

## 2026-08-15

- 確認した範囲: CHANGELOG v2.1.233 まで（v2.1.220 以降を精査、インストール済みバージョンと一致）/ 公式ドキュメント（changelog, sub-agents, settings, tools-reference, hooks, self-hosted-environments-quickstart）を本日時点で確認 / Anthropic ブログ・ニュースは 2026-07-24（Opus 5）以降を WebSearch 経由で確認（www.anthropic.com への直接 WebFetch はプロキシで EGRESS_BLOCKED）、2026-08-11頃の Compliance API 拡大まで / コミュニティは gist.github.com/techygarg（コンテンツ改訂は 2026-07-17 が最新で更新なし）・github.com/shanraisshan/claude-code-best-practice（2026-08-14 まではバッジ更新のみで実質更新なし）を確認、公式 Weekly Digest（code.claude.com/docs/en/whats-new/2026-w32）で 2026-08-03〜07 分を確認
- 主な発見: (1) v2.1.232 でサブエージェント fork mode が対話セッションのデフォルトになったが、claude-code-guide エージェントによる裏取りの結果、`.claude/agents/*.md` で `tools:` を明示したカスタムエージェント（explorer/mechanic/reviewer/strategist/harness-researcher）には非適用と判明。model-routing.md の「サブエージェントは fresh context で起動する」前提は現状維持で問題なく、起案は見送った。(2) v2.1.233（インストール済みバージョンと一致）で Opus 4.8 / Sonnet 5 / Fable 5 / Mythos 5 以降のモデルで TaskCreate/TaskUpdate/TodoWrite 等が既定無効化されると判明、`CLAUDE_CODE_ENABLE_TODO_TOOLS=1` で復元可能なことを CHANGELOG 直接確認で検証した。本リポジトリのメイン/strategist は両方対象モデルに該当するため起案。(3) v2.1.233 で `claude plugin validate` が skills frontmatter を検証できるようになったため、harness-improve のフェーズ4手順に検証ステップを追加提案。(4) `permissions.defaultMode: "auto"` は 2026-08-14 に Pro/Max/Team の新規セッション既定になったが、本リポジトリは settings.json で既に明示設定済みのため対応不要。(5) Bash/PowerShell の権限バイパス複数修正（v2.1.223/224/232 等）は Claude Code 本体側のバグ修正であり guard.sh 側の変更は不要と判断した
- 提案: 新規起案 2 件（いずれも status: proposed）→ `20260815-todo-tools-env-restore.md`、`20260815-plugin-validate-skill-check.md`。保留中の `20260719-subagent-report-contract.md` は今回フェーズ3（レビュー）を実施しないため判断持ち越し（技術的前提に変更なし）
- 備考: 今回は定期実行（非対話）のためフェーズ1・2・5のみを実施し、フェーズ3（レビュー）・フェーズ4（実装）は行っていない。次回ローカルで `/harness-improve` を実行した際に、今回の起案2件と保留中の1件（`20260719-subagent-report-contract.md`）をまとめてレビュー・採否判断・実装すること

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

