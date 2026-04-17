# dotfiles

Mac の初期セットアップ記録と設定ファイル管理。

## セットアップ手順

### 1. アプリのインストール（手動）

以下を公式サイトからインストール：

- [Chrome](https://www.google.com/chrome/)
- [Google 日本語入力](https://www.google.co.jp/ime/)
- [Slack](https://slack.com/downloads/mac)
- [1Password](https://1password.com/downloads/mac/)
- [Xcode](https://apps.apple.com/jp/app/xcode/id497799835)

### 2. git の初期設定

```sh
git config --global user.name "mura123yasu"
git config --global user.email "mura123yasu@gmail.com"
```

### 3. Homebrew のインストール

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 4. パッケージのインストール

```sh
brew bundle
```

> `Brewfile` を使って一括インストール。

### 5. fzf のシェル統合

```sh
$(brew --prefix)/opt/fzf/install
```

### 6. dotfiles のセットアップ

```sh
# リポジトリを clone
ghq get mura123yasu/dotfiles

# シンボリックリンクを作成
ln -sf ~/ghq/github.com/mura123yasu/dotfiles/.zshrc ~/.zshrc
ln -sf ~/ghq/github.com/mura123yasu/dotfiles/.claude/settings.json ~/.claude/settings.json
ln -sf ~/ghq/github.com/mura123yasu/dotfiles/.claude/statusline-command.sh ~/.claude/statusline-command.sh
```

## dotfiles の構成

| ファイル   | 説明                                |
| ---------- | ----------------------------------- |
| `.zshrc`   | zsh の設定（ghq + fzf の統合など）  |
| `Brewfile` | Homebrew でインストールするパッケージ一覧 |
| `.claude/settings.json` | Claude Code のグローバル設定（ステータスライン等） |
| `.claude/statusline-command.sh` | ステータスライン表示スクリプト |

## インストール済みツール

| ツール  | 用途                          |
| ------- | ----------------------------- |
| gh      | GitHub CLI                    |
| ghq     | リポジトリ管理                |
| tig     | Git ログの TUI ビューアー     |
| fzf     | ファジーファインダー          |
| alfred  | ランチャー                    |
| ghostty | ターミナルエミュレーター      |
