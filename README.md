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

### 2. Homebrew のインストール

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3. パッケージのインストール

```sh
brew bundle
```

> `Brewfile` を使って一括インストール。

### 4. fzf のシェル統合

```sh
$(brew --prefix)/opt/fzf/install
```

### 5. dotfiles のセットアップ

```sh
# リポジトリを clone
ghq get y-murata/dotfiles

# シンボリックリンクを作成
ln -sf ~/ghq/github.com/y-murata/dotfiles/.zshrc ~/.zshrc
```

## dotfiles の構成

| ファイル   | 説明                                |
| ---------- | ----------------------------------- |
| `.zshrc`   | zsh の設定（ghq + fzf の統合など）  |
| `Brewfile` | Homebrew でインストールするパッケージ一覧 |

## インストール済みツール

| ツール  | 用途                          |
| ------- | ----------------------------- |
| gh      | GitHub CLI                    |
| ghq     | リポジトリ管理                |
| tig     | Git ログの TUI ビューアー     |
| fzf     | ファジーファインダー          |
| ghostty | ターミナルエミュレーター      |
