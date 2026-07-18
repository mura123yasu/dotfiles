# Global Rules

## Git Workflow（必須）

- **main への直接 commit・push は禁止**（PreToolUse hook でも強制される）。
- 作業は必ず新しいブランチを切ってから行い、PR を作成して main にマージすること。
- ユーザーから「main に直接 push して」と明示指示された場合でも、リスクを説明した上で確認を求めること。

## モデルルーティングとサブエージェント方針

詳細は `~/.claude/rules/model-routing.md` を参照。要点:

- 広域探索・大量ログ読解・並列調査 → サブエージェント（haiku/sonnet）に委譲
- 小さな編集・通常の実装・会話 → main セッションで直接（委譲しない）
- 設計判断・レビュー → 最上位モデル（fable、不可なら opus）

## マルチリポジトリ統合管理

- 全リポジトリの進捗・バックログは `~/ghq/github.com/mura123yasu/local-workspace` で統合管理している。
- 「次何すればいい？」と聞かれたら local-workspace の `/next` スキルとバックログを参照すること。
