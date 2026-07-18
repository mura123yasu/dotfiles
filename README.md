# dotfiles

Mac / WSL (Ubuntu) の初期セットアップ記録と設定ファイル管理。

## WSL セットアップ手順

### 1. git の初期設定

```sh
git config --global user.name "mura123yasu"
git config --global user.email "mura123yasu@gmail.com"
```

### 2. リポジトリを clone

```sh
mkdir -p ~/ghq/github.com/mura123yasu
git clone https://github.com/mura123yasu/dotfiles ~/ghq/github.com/mura123yasu/dotfiles
```

### 3. セットアップスクリプトを実行

```sh
zsh ~/ghq/github.com/mura123yasu/dotfiles/install.wsl.sh
```

スクリプトが以下を自動で行います：
- 必要パッケージのインストール（gh, eza, fzf, starship, mise, direnv, bat 等）
- デフォルトシェルを zsh に変更
- dotfiles のシンボリックリンク展開

---

## Mac セットアップ手順

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

## ファイル管理方針（共用 / OS 別）

Mac と WSL で無理に設定ファイルを共用せず、差分が出るものは OS 別ファイルに切り出して管理する。
**新しいファイルを追加・変更したら、必ずこの表を更新すること。**

### 両 OS で共用

| ファイル | リンク先 | 説明 |
| -------- | -------- | ---- |
| `home/.tmux.conf` | `~/.tmux.conf` | tmux 設定 |
| `config/starship.toml` | `~/.config/starship.toml` | プロンプト設定 |
| `config/git/ignore` | `~/.config/git/ignore` | グローバル gitignore |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code グローバル設定（permissions / sandbox / hooks 等）。macOS 専用の deny ルール（`pbcopy` 等）は WSL では発火しないだけで無害 |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | ステータスライン表示スクリプト |
| `claude/skills/` | `~/.claude/skills/` 以下 | Claude Code スキル |
| `claude/hooks/` | `~/.claude/hooks` | PreToolUse ガードフック |
| `claude/rules/` | `~/.claude/rules` | モデルルーティング等のルール |
| `claude/agents/` | `~/.claude/agents` | カスタムエージェント定義 |
| `CLAUDE.md` | （リポジトリ直下） | Claude Code 向けグローバルルール |

### Mac 専用

| ファイル | 説明 |
| -------- | ---- |
| `install.sh` | Mac 向けリンク展開スクリプト |
| `home/.zshrc` | Mac 用 zsh 設定（Homebrew 前提。`cw` は `local-workspace` へ） |
| `home/.zprofile` | Homebrew の shellenv 読み込み |
| `Brewfile` | Homebrew パッケージ一覧 |
| `config/ghostty/config` | Ghostty ターミナル設定 |

### WSL 専用

| ファイル | 説明 |
| -------- | ---- |
| `install.wsl.sh` | WSL 向けセットアップスクリプト（apt パッケージ導入 + リンク展開） |
| `home/.zshrc.wsl` | WSL 用 zsh 設定（apt/mise 前提。`cw` は `local-workspace-win` へ） |

> 注意: `install.sh`（Mac 用）を WSL で実行しないこと。`~/.zshrc` が Mac 用の `home/.zshrc` に張り替えられてしまう。WSL では必ず `install.wsl.sh` を使う。

## インストール済みツール

| ツール  | 用途                          |
| ------- | ----------------------------- |
| gh      | GitHub CLI                    |
| ghq     | リポジトリ管理                |
| tig     | Git ログの TUI ビューアー     |
| fzf     | ファジーファインダー          |
| alfred  | ランチャー                    |
| ghostty | ターミナルエミュレーター      |
