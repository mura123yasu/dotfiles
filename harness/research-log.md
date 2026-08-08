# ハーネス調査ログ

`/harness-improve` の各実行を記録する。新しいエントリを上に追記すること。

<!-- エントリのテンプレート:

## YYYY-MM-DD

- 確認した範囲: CHANGELOG vX.Y.Z まで / 記事 YYYY-MM-DD まで
- 主な発見: （1〜3行で要約）
- 提案: 起案 n 件（採用 x / 却下 y / 保留 z）→ proposals/ 参照

-->

## 2026-07-19

- 確認した範囲: CHANGELOG v2.1.214 まで / 公式ドキュメント（hooks, skills, settings, sub-agents）・Anthropic ブログ 2026-07-19 時点 / コミュニティ記事 marmelab（2026-04-24）ほか
- 主な発見: 組み込み Explore のセッションモデル継承化（v2.1.198）、`fallbackModel` 設定（v2.1.166）、SKILL.md 新フロントマター群（context: fork / paths / disallowed-tools）と skillOverrides、hooks イベント大幅拡張（SubagentStop / Stop の completion gate パターン）、Gotchas セクション運用、commands の skills 統合
- 提案: 起案 3 件（採用 2 / 却下 0 / 保留 1）→ proposals/ 参照
- 備考: guard.sh のブロックメッセージ改善（次アクション明示）は確認の結果すでに満たしており起案せず。`context: fork` は既知バグ（Issue #49559）のため見送り

