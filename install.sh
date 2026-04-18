#!/usr/bin/env zsh
# =============================================================================
# install.sh - dotfiles シンボリックリンク展開スクリプト
# 使い方: zsh install.sh
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

    # 既存ファイル/リンクが存在する場合はバックアップ
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

# ---- ホームディレクトリの dotfiles ----
info "ホームディレクトリの dotfiles をリンク中..."
link "$DOTFILES_DIR/home/.zshrc"    "$HOME/.zshrc"
link "$DOTFILES_DIR/home/.zprofile" "$HOME/.zprofile"
link "$DOTFILES_DIR/home/.tmux.conf" "$HOME/.tmux.conf"

# ---- ~/.config 以下の設定 ----
info "~/.config の設定をリンク中..."
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/git"

link "$DOTFILES_DIR/config/starship.toml"  "$HOME/.config/starship.toml"
link "$DOTFILES_DIR/config/ghostty/config" "$HOME/.config/ghostty/config"
link "$DOTFILES_DIR/config/git/ignore"     "$HOME/.config/git/ignore"

# ---- Claude Code 設定 ----
info "Claude Code 設定をリンク中..."
mkdir -p "$HOME/.claude/skills"
link "$DOTFILES_DIR/claude/settings.json"           "$HOME/.claude/settings.json"
link "$DOTFILES_DIR/claude/statusline-command.sh"   "$HOME/.claude/statusline-command.sh"
link "$DOTFILES_DIR/claude/skills/github-push.md"   "$HOME/.claude/skills/github-push.md"

echo ""
info "完了。ターミナルを再起動してください。"
