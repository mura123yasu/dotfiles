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

## 2026-10-15

- 確認した範囲: CHANGELOG v2.1.300 まで（v2.1.220〜v2.1.300、バグ修正中心の v2.1.221〜283 は機能追加のみ抽出）/ 公式ドキュメント hooks・sub-agents・settings-reference・slash-commands（2026-10-15 時点）/ Anthropic news 2026-10-14 まで、Engineering blog は 2026-05-25 が最新で更新なし / コミュニティは claudeissues.com を 2026-01〜2026-08-23 の範囲で確認（ウィンドウ内の新規投稿は issue #88995 のみ）。Reddit・Hacker News Algolia API は本環境のプロキシから到達不可で今回も調査不能
- 主な発見: (1) `advisorModel` が公式に `"fable"` を受け付けると settings-reference に明記され、2026-08 時点で「Fable は advisor に選べない」としていた既知の制約が解消された。(2) v2.1.295+ でフックハンドラ共通フィールド `onFailure`（既定 `"continue"`）が追加され、guard.sh のような PreToolUse ガードが異常終了した場合に素通りする経路が設定レベルで塞げるようになった。(3) Agent ツール呼び出し単位で `effort` を指定できる機能（v2.1.292、frontmatter より優先・resume 後も保持）を確認。(4) コミュニティ側では v2.1.163（2026-06-04）以降 SubagentStop の `additionalContext` 返却がフックエラー扱いされないことが裏付けられ、既存の保留提案（`20260719-subagent-report-contract.md`）の実装方針を補強した一方、未解決の SubagentStop イベント信頼性の穴（issue #88995、agent_type 空・transcript 不在）も確認した。(5) 2026年6-7月に集中したサブエージェント再帰的増殖バグ（計画した3〜5体が最大583体に増殖、Windows で CPU 100% ハング）は v2.1.217（2026-07-21/22）で既定動作（ネスト不可・同時実行数20キャップ）として修正済みであり、本リポジトリの「並列2〜4推奨」ルールを裏付ける実例として記録（既に修正済みのため新規提案はしない）
- 提案: 新規起案 3 件（いずれも status: proposed）→ `20261015-advisor-fable.md`、`20261015-hook-onfailure-block.md`、`20261015-agent-call-effort-param.md`。既存の保留提案 `20260719-subagent-report-contract.md` には新たな裏付け情報と実装時の注意点を判断記録に追記（起案数には含めない、status は proposed のまま）
- 備考: `sandbox.network.strictAllowlist`（user/managed スコープ）や `maxEffortLevel` / `allowedProviders` 等の新設定も確認したが、具体的な適用先（許可すべきホスト一覧の精査等）が今回の調査だけでは詰められず起案は見送った。次回サイクルで深掘りする価値がある。今回はフェーズ1・2・5のみを実施し、フェーズ3（レビュー）・4（実装）は行っていない（定期実行の制約）

## 2026-10-01

- 確認した範囲: CHANGELOG v2.1.221〜v2.1.286（最新）まで / 公式ドキュメント（hooks, sub-agents,
  settings, best-practices）を 2026-08-02 時点からの差分で確認 / Anthropic News・Engineering
  ブログ 2026-07-24〜2026-09-29（最新確認記事は "Giving companies more control over their AI
  agents, with NVIDIA"）/ コミュニティは gist.github.com/techygarg（2026-08-14 更新）・
  github.com/shanraisshan/claude-code-best-practice（2026-09-30 更新バッジ）・GitHub issue 検索
  まで。news.ycombinator.com は egress proxy でブロックされ WebSearch のスニペットのみ、
  Reddit/dev.to/Substack 等も個別記事の WebFetch は不可で検索結果のみ参照（過去サイクルと同様の制約）
- 主な発見: (1) v2.1.273 でサブエージェント frontmatter に `omitClaudeMd` が追加され、
  CLAUDE.md の自動読み込みをスキップできるようになった。`model-routing.md` の
  「コンテキスト移送コスト」軸にそのまま適用できる。(2) v2.1.284 で `/doctor prompt-audit`
  （CLAUDE.md・skills・agents・commands の旧世代プロンプトパターン監査）が追加された。
  (3) v2.1.275 で claude.ai アカウント側のスキル・プラグインを端末セッションに自動同期する
  機能が追加され、`syncClaudeAiSkills` / `syncClaudeAiPlugins` で無効化できる。本リポジトリは
  dotfiles 経由の再現性を前提にしているため無効化が方針と整合する。(4) `PreModelSwitch` /
  `PostModelSwitch` hook、auto mode のサーバーサイド分類器デフォルト化とそれに伴う
  セキュリティ論争（The Register, Cybernews 報道）、Agent Teams・Agent view・`/batch`
  （5〜30並列ファンアウト）等の新機能を確認したが、本リポジトリの現状の構成への具体的な
  適用先が弱いか、既存方針（並列2〜4体目安等）との優先度を比較してこのサイクルでは見送った。
  (5) 公式ベストプラクティスガイドの改訂内容（Explore→Plan→Implement→Commit、アドバーサリアル
  レビュー等）は `reviewer` エージェント・`code-review` スキルの既存設計とおおむね整合することを
  確認（新規差分は小さい）
- 提案: 新規起案 3 件（いずれも status: proposed、今回はフェーズ3・4未実施のため採否判断なし）→
  `20261001-omit-claude-md-for-mechanical-agents.md`、
  `20261001-doctor-prompt-audit-in-harness-improve.md`、
  `20261001-disable-claude-ai-sync.md`。保留中の `20260719-subagent-report-contract.md` は
  今回新たな技術的差分なし（前回までの確認内容から変化なし）のため判断記録への追記は省略
- 備考: 本サイクルは定期・非対話実行のため、フェーズ3（レビュー）・フェーズ4（実装）は行わず、
  起案（status: proposed）と記録・PR作成のみ実施。レビューと実装は次回ローカルでの
  `/harness-improve` 実行に委ねる

## 2026-09-15

- 確認した範囲: CHANGELOG v2.1.271 まで（前回確認済みの v2.1.220 以降、v2.1.257〜v2.1.271 を重点確認。v2.1.221〜v2.1.256 の中間区間は要約ツールの制約で個別バレット未確認の可能性があり次回要再確認）/ 公式ドキュメント hooks・sub-agents・skills・settings-reference・model-config を確認 / Anthropic news・engineering は `anthropic.com`/`claude.com` への直接 WebFetch がこの実行環境のプロキシで遮断され本文未読（WebSearch のスニペットのみ。2026-09-14 付の CI 記事を検知したがハーネス関連度は低）/ コミュニティは WebSearch ベースで 2026-09-09 まで確認（Reddit/HN 系サイトへの直接 WebFetch は前回同様ほぼ 403）
- 主な発見: (1) v2.1.271 で agent frontmatter に `omitClaudeMd`（CLAUDE.md 読み込み省略）が追加されたが、公式 sub-agents リファレンスにはまだ未掲載でドキュメント反映待ちと判明。(2) 公式 sub-agents リファレンスで `isolation: worktree`（サブエージェントを一時 git worktree に隔離実行）を確認、コミュニティ複数ソースも「ファイル書き込み系 subagent にはデフォルトで付けるべき」と一致。(3) `maxEffortLevel`（v2.1.267、settings.json、値は effortLevel と同じ low/medium/high/xhigh）はサブエージェント frontmatter の `effort` も含めて上限キャップすることを公式ドキュメントで確認 — `strategist` の `effort: max` を弱める方向に働くため本リポジトリでは非採用と判断（起案せず）。(4) `bashOutputMaxChars`/`taskOutputMaxChars`（v2.1.261、既定 8000/16000 文字、上限 128K）を確認したが、具体的な支障事例がなく起案は見送り。(5) Claude Fable 5.1（v2.1.257）関連のバグ（`model: fable` エージェントの context window タグ無視・プロンプトキャッシュ無効化等）は v2.1.260 で解消済みと確認、本リポジトリはエイリアス指定（`model: fable`）のため影響なし・対応不要。(6) コミュニティで「Claude Mods」（TypeScript製ミドルウェア方式の新 hook、`CLAUDE_ENABLE_FUNCTION_HOOKS=1` で先行テスト可、2026-09-09 時点で「数週間以内に出荷」予告）の動きを検知。未リリースの実験的機能のため今回は起案せず、次回サイクルで追跡する
- 提案: 新規起案 2 件（いずれも status: proposed）→ `20260915-mechanic-isolation-worktree.md`、`20260915-omit-claude-md-explorer-mechanic.md`。既存の保留提案 `20260719-subagent-report-contract.md` は今回のフェーズ3（レビュー）非実施のため判断せず `status: proposed` のまま維持
- 備考: 今回は定期実行のため、フェーズ3（レビュー）・フェーズ4（実装）は行っていない。両提案とも `/harness-improve` 実行時にローカルでレビュー・採否判断が必要

## 2026-09-01

- 確認した範囲: CHANGELOG v2.1.252 まで（前回範囲 v2.1.220 からの差分を精査）/ 公式ドキュメント hooks・skills・settings・sub-agents を2026-09-01時点で再確認 / Anthropic News 2026-08-28（学区向けプラン）まで、Engineering ブログは2026-04-23以降更新なしを再確認 / コミュニティは github.com/shanraisshan/claude-code-best-practice（2026-08-31更新）・github.com/FlorianBruniaux/claude-code-ultimate-guide（2026-09-01更新, v3.43.0）・github.com/karanb192/claude-code-hooks まで直接確認。他は WebFetch egress遮断のため WebSearch スニペット止まり（確度は中〜低と明記）
- 主な発見: (1) `PreModelSwitch`/`PostModelSwitch` フックイベントが v2.1.251 で追加・正式仕様化（モデル切替の前後で発火、Pre側はブロック可能）。(2) sub-agents ドキュメントでフォークモードのキャッシュ完全継承デフォルトON（v2.1.232）、agent frontmatter の `experimental.cacheTtl`（v2.1.248）、同時実行数上限（デフォルト20、`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`）とネスト深度上限（デフォルト3、`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`）が正式文書化された。(3) `/effort` がv2.1.251でモデルごとに保存される仕様に変更。(4) コミュニティ（複数の日付付き記事、確度は中程度、egress制約でスニペット止まり）で「Claude Code Auto Mode」が2026-08-14にPro/Max/Teamの新規セッションでデフォルト化されたという言及を複数確認したが、一次情報源（code.claude.com・CHANGELOG）では未確認のため今回は起案見送り、次回サイクルで高確度ソースでの裏取りを推奨。(5) コミュニティで SubagentStop×「納品契約」パターンへの言及を確認し、保留中の既存提案 `20260719-subagent-report-contract.md` を補強（判断記録に追記、status変更なし）
- 提案: 新規起案 2 件（いずれも status: proposed）→ `20260901-model-switch-hook-logging.md`（PreModelSwitch/PostModelSwitch でモデル切替をログ化）、`20260901-subagent-official-limits-doc.md`（同時実行数・ネスト深度の公式上限を model-routing.md に追記）。レビュー・実装は次回 `/harness-improve` ローカル実行時に判断
- 備考: 今回はフェーズ1・2・5のみの定期実行（スケジュール実行、AskUserQuestion 不可のためフェーズ3レビューなし、フェーズ4実装なし）。過去の rejected 提案は0件（既存5件はすべて done または proposed）で、再提案回避の確認対象なし。Auto Mode の件は次回サイクルでの最優先調査候補として引き継ぐ

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

