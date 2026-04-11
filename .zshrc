export PATH="$HOME/.local/bin:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ghq + fzf でリポジトリに移動（プレビュー付き）
function fzf-ghq() {
  local selected
  selected=$(ghq list | fzf --prompt "ghq > " --preview "ls $(ghq root)/{}")
  if [ -n "$selected" ]; then
    cd "$(ghq root)/$selected"
  fi
}
alias g='fzf-ghq'