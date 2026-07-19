# ハーネス自己改善サイクル

Claude Code のハーネス（`claude/` 配下の skills / agents / hooks / rules / settings と CLAUDE.md）を、
公式アップデートやコミュニティのベストプラクティスに継続的に追従させるための仕組み。

## サイクル

```
調査 → 立案 → レビュー（ユーザー判断） → 実装 → 記録・PR
```

1. **調査**: `harness-researcher` エージェント（`claude/agents/harness-researcher.md`）が
   公式 CHANGELOG・ドキュメント・Anthropic ブログ・コミュニティ知見を Web 調査する
2. **立案**: 調査結果と本リポジトリの現状を突き合わせ、拡張案を `proposals/` に起案する
3. **レビュー**: ユーザーが各提案を採用 / 却下 / 保留で判断する。**勝手に実装はしない**
4. **実装**: 採用された提案だけをハーネスに反映し、PR を作成する
5. **記録**: `research-log.md` に確認範囲を記録し、次回は差分だけ調査する

実行方法: Claude Code で `/harness-improve`（月1〜2回程度の実行を想定）。

## ディレクトリ構成

| パス | 役割 |
| ---- | ---- |
| `proposals/YYYYMMDD-<slug>.md` | 拡張提案。frontmatter の `status` で状態管理 |
| `research-log.md` | 調査ログ。前回の確認範囲（CHANGELOG バージョン・日付）を記録し、差分調査の起点にする |

## 提案の status

| status | 意味 |
| ------ | ---- |
| `proposed` | 起案済み・未判断（保留含む）。次回実行時に再提示される |
| `rejected` | 却下。理由を本文に記録し、同内容の再提案を防ぐ |
| `done` | 採用・実装済み |

却下済み・実装済みの提案ファイルも削除せず残す（判断の履歴として機能するため）。
