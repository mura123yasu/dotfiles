# =============================================================================
# Zsh Configuration for Mac
# =============================================================================

# --- 1. Path & Environment Variables ---
# Apple Silicon Homebrew Path
eval "$(/opt/homebrew/bin/brew shellenv)"

# 言語設定
export LANG=ja_JP.UTF-8

# エディタ設定
export EDITOR="code --wait"

export PATH="$HOME/.local/bin:$PATH"

# --- 2. Zsh Completion ---
# 補完システムの初期化（git補完などを有効化）
autoload -Uz compinit && compinit

# --- 3. Zsh Plugins ---
# Homebrewでインストールしたzshプラグインの読み込み
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- 4. UI & Prompt (Starship) ---
eval "$(starship init zsh)"

# --- 5. Tool Initializations ---
# mise (Node.js等のバージョン管理)
eval "$(mise activate zsh)"

# direnv
eval "$(direnv hook zsh)"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# --- 6. Aliases ---
# lsをモダンなezaに置き換え
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -la --icons'

# catをモダンなbatに置き換え
alias cat='bat'

# よく使うディレクトリへのショートカット
alias cdd='cd ~/Downloads'

# MRマージ後にmainへ戻ってpullする
alias gomain='git checkout main && git pull'

# claude-workspace用のalias（~/claude-workspace で Claude を起動）
alias cw='cd ~/claude-workspace && claude'

# --- 7. Functions ---

# ghq + fzf: リポジトリ一覧を検索して移動
function g() {
  local dir
  dir=$(ghq list > /dev/null | fzf +m) &&
  cd $(ghq root)/$dir
}

# 履歴をfzfで検索して再実行
function fzf-select-history() {
  BUFFER=$(history -n -r 1 | fzf --no-sort +m --query "$LBUFFER" --prompt="History > ")
  CURSOR=$#BUFFER
}
zle -N fzf-select-history
bindkey '^R' fzf-select-history
