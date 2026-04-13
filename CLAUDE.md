# Git Workflow Rules

## ブランチ・PR 必須ルール

- **main への直接 commit・push は禁止。**
- 作業は必ず新しいブランチを切ってから行うこと。
  ```
  git checkout -b <branch-name>
  ```
- 変更を commit したら、PR を作成して main にマージすること。
  ```
  gh pr create ...
  ```
- これはユーザーから明示的に「main に直接 push して」と指示された場合でも、
  リスクを説明した上で確認を求めること。
