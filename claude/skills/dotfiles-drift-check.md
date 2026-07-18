---
description: dotfiles と実環境のドリフトを検出し、要変更ならリポジトリを更新して PR を作成する
argument-hint: なし（オプションで「レポートのみ」等の指示）
---

## Context

- ドリフト検出結果: !`zsh ~/ghq/github.com/mura123yasu/dotfiles/scripts/drift-check.sh; true`

## Your task

dotfiles リポジトリ（`~/ghq/github.com/mura123yasu/dotfiles`）を実環境に追従させる。
上記の検出結果を起点に、以下を実施すること。

### 1. 決定的チェックの結果を分類する

検出された各項目を次の4つに分類する:

| 分類 | 対処 |
|---|---|
| (a) リポジトリに取り込むべき | install スクリプト / Brewfile / リポジトリ内ファイルを更新する |
| (b) 環境側を直すべき | リポジトリは変更せず、修正コマンドをユーザーに提示する（実行はしない） |
| (c) 環境固有のノイズ | `scripts/drift-ignore.txt` にパターンを追記する |
| (d) 判断がつかない | PR 本文・最終報告に記載してユーザーに委ねる |

分類の目安:
- 汎用 CLI ツールの新規インストール（例: htop, tree）→ (a) install スクリプトへ追加
- 特定マシン・特定業務でしか使わないもの → (c) ignore へ
- リンクの実ファイル化で内容差分あり → 差分を読み、意図的な設定変更なら (a) リポジトリ側へ反映、事故なら (b)
- 大掛かりなセットアップを伴うもの（例: docker）→ 追加手順の妥当性を確認した上で (a)、自信がなければ (d)

### 2. 判断スイープ（決定的チェックが拾えないドリフト）

スクリプトは既知の管理対象しか見ない。以下も確認すること:

- `~/.config` 配下に dotfiles 管理する価値のある未追跡設定がないか（例: `~/.config/mise/config.toml`）
- install スクリプトに記載のないセットアップ手順が必要になっていないか（新しいツールの初期化コマンド等）
- `claude/` 配下（settings.json, hooks, rules, agents, skills）と `~/.claude` の実体に乖離がないか

### 3. リポジトリを更新して PR を作成する

- **main への直接 commit は禁止**。`chore/drift-sync-YYYYMMDD` 等のブランチを切ること
- (a)(c) の変更を適用する。apt パッケージを install.wsl.sh に追加・削除した場合や新規パッケージを取り込み済みにする場合は `zsh scripts/drift-check.sh --update-baseline` でベースラインを更新して一緒にコミットする
- **install.sh を変更したら install.wsl.sh も追従させる**（OS 別ファイル管理方針は README 参照）
- 変更後に `zsh scripts/drift-check.sh` を再実行し、(a)(c) 対象の検出が消えたことを確認する
- PR を作成し、本文に「取り込んだもの / ignore にしたもの / (b)(d) でユーザー判断待ちのもの」を明記する

### 4. 最終報告

ドリフトがなかった場合はその旨だけ報告する。あった場合は分類結果と PR の URL、ユーザーに残された判断・作業を簡潔にまとめる。
