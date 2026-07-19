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
| `config/mise/config.toml` | `~/.config/mise/config.toml` | mise グローバルツール設定（node 等） |
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

## ドリフト検出（定期チェック機構）

実環境（インストール済みパッケージ・シンボリックリンク・`~/.claude` 配下）が
このリポジトリの管理内容から乖離していないかを定期的に検出する仕組み。

### 構成

| コンポーネント | 役割 |
| -------------- | ---- |
| `scripts/drift-check.sh` | 決定的なドリフト検出。リンク健全性 / パッケージ差分（WSL: apt ベースライン比較、Mac: Brewfile 比較）/ `~/.claude/skills` の未管理ファイルを検出し、`~/.local/state/dotfiles-drift/report.txt` に出力 |
| `scripts/snapshot/apt-manual.wsl.txt` | apt 手動インストールパッケージのベースライン（WSL）。`--update-baseline` で再生成 |
| `scripts/drift-ignore.txt` | 環境固有として無視するパターンのリスト |
| `.zshrc` の起動フック | 週1回バックグラウンドで自動チェックし、ドリフトがあれば起動時に警告 |
| `/dotfiles-drift-check` スキル | 検出結果を分類し、要変更ならリポジトリを更新して PR を作成（Claude Code） |

### 使い方

```sh
# 手動チェック
zsh scripts/drift-check.sh

# 対処（Claude Code で。分類・リポジトリ更新・PR 作成まで行う）
/dotfiles-drift-check
```

シェル起動時に「⚠ dotfiles ドリフト検出」と表示されたら `/dotfiles-drift-check` を実行する。

> 原則: ドリフト対応で変更するのは**実行した端末の OS 用ファイルのみ**（WSL なら install.wsl.sh 等、Mac なら install.sh / Brewfile 等）。他 OS 分は当該端末で `/dotfiles-drift-check` を実行して追従する。

## ハーネス自己改善サイクル

Claude Code のハーネス（`claude/` 配下と CLAUDE.md）を、公式アップデートや
コミュニティのベストプラクティスに継続的に追従させる仕組み。詳細は `harness/README.md` を参照。

### 構成

| コンポーネント | 役割 |
| -------------- | ---- |
| `claude/agents/harness-researcher.md` | 調査エージェント。公式 CHANGELOG・ドキュメント・ブログ・コミュニティ知見を Web 調査 |
| `claude/skills/harness-improve/` | `/harness-improve` スキル。調査 → 立案 → レビュー → 実装 → PR のサイクルを回す |
| `harness/proposals/` | 拡張提案の記録（採用 / 却下 / 保留を frontmatter で管理。却下理由も残し再提案を防ぐ） |
| `harness/research-log.md` | 調査ログ。前回の確認範囲を記録し、次回は差分だけ調査する |

### 使い方

```sh
# Claude Code で（月1〜2回程度）
/harness-improve

# 調査だけしたい場合
/harness-improve 調査のみ
```

提案の採否は必ずユーザーが判断する（勝手に実装はされない）。実装は PR 経由で main にマージする。

## インストール済みツール

| ツール  | 用途                          |
| ------- | ----------------------------- |
| gh      | GitHub CLI                    |
| ghq     | リポジトリ管理                |
| tig     | Git ログの TUI ビューアー     |
| fzf     | ファジーファインダー          |
| alfred  | ランチャー                    |
| ghostty | ターミナルエミュレーター      |
