#!/usr/bin/env zsh
# =============================================================================
# install.wsl.sh - WSL (Ubuntu) 向け dotfiles セットアップスクリプト
# 使い方: zsh install.wsl.sh
# =============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---- ユーティリティ ----
info()    { echo "[INFO] $*" }
success() { echo "[OK]   $*" }
warn()    { echo "[WARN] $*" }

# バックアップ付きシンボリックリンク作成
link() {
    local src="$1"
    local dst="$2"

    if [[ -e "$dst" && ! -L "$dst" ]]; then
        local backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
        warn "既存ファイルをバックアップ: $dst -> $backup"
        mv "$dst" "$backup"
    elif [[ -L "$dst" ]]; then
        rm "$dst"
    fi

    ln -sfn "$src" "$dst"
    success "リンク作成: $dst -> $src"
}

# コマンドが存在するか確認
has() { command -v "$1" &>/dev/null }

# =============================================================================
# 1. パッケージのインストール
# =============================================================================
info "apt パッケージをインストール中..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    zsh \
    fzf \
    direnv \
    bat \
    tig \
    tmux \
    jq \
    bubblewrap \
    socat \
    zsh-autosuggestions \
    zsh-syntax-highlighting

# gh (GitHub CLI)
if ! has gh; then
    info "GitHub CLI をインストール中..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq gh
    success "gh インストール完了"
fi

# eza
if ! has eza; then
    info "eza をインストール中..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
    sudo chmod 644 /etc/apt/sources.list.d/gierens.list
    sudo apt-get update -qq
    sudo apt-get install -y -qq eza
    success "eza インストール完了"
fi

# starship
if ! has starship; then
    info "starship をインストール中..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
    success "starship インストール完了"
fi

# mise
if ! has mise; then
    info "mise をインストール中..."
    curl https://mise.run | sh
    success "mise インストール完了"
fi

# ghq
if ! has ghq; then
    info "ghq をインストール中..."
    GOBIN="$HOME/.local/bin" go install github.com/x-motemen/ghq@latest
    success "ghq インストール完了"
fi

# =============================================================================
# 2. デフォルトシェルを zsh に変更
# =============================================================================
if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "デフォルトシェルを zsh に変更中..."
    chsh -s "$(which zsh)"
    success "デフォルトシェル変更完了（次回ログインから有効）"
fi

# =============================================================================
# 3. dotfiles シンボリックリンク展開
# =============================================================================
info "ホームディレクトリの dotfiles をリンク中..."
link "$DOTFILES_DIR/home/.zshrc.wsl" "$HOME/.zshrc"
link "$DOTFILES_DIR/home/.tmux.conf" "$HOME/.tmux.conf"

info "~/.config の設定をリンク中..."
mkdir -p "$HOME/.config/git"

link "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES_DIR/config/git/ignore"    "$HOME/.config/git/ignore"

info "Claude Code 設定をリンク中..."
mkdir -p "$HOME/.claude/skills"
link "$DOTFILES_DIR/claude/settings.json"           "$HOME/.claude/settings.json"
link "$DOTFILES_DIR/claude/statusline-command.sh"   "$HOME/.claude/statusline-command.sh"
link "$DOTFILES_DIR/claude/skills/github-push.md"   "$HOME/.claude/skills/github-push.md"
link "$DOTFILES_DIR/claude/hooks"                   "$HOME/.claude/hooks"
link "$DOTFILES_DIR/claude/rules"                   "$HOME/.claude/rules"
link "$DOTFILES_DIR/claude/agents"                  "$HOME/.claude/agents"

# =============================================================================
echo ""
info "完了。ターミナルを再起動してください。"
