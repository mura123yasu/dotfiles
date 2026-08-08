#!/usr/bin/env zsh
# =============================================================================
# drift-check.sh - dotfiles と実環境のドリフト検出
#
# 使い方:
#   zsh scripts/drift-check.sh                    検出結果を表示。ドリフトありなら exit 1
#   zsh scripts/drift-check.sh --quiet            出力抑制（シェル起動時のバックグラウンド実行用）
#   zsh scripts/drift-check.sh --update-baseline  現環境から apt ベースラインを再生成（WSL のみ）
#
# 検出結果は ~/.local/state/dotfiles-drift/report.txt にも書き出す。
# ドリフトへの対処（リポジトリ更新の要否判断）は Claude Code の
# /dotfiles-drift-check スキルが行う。
# =============================================================================

set -u

DOTFILES_DIR="${0:A:h:h}"
STATE_DIR="${DOTFILES_DRIFT_STATE_DIR:-$HOME/.local/state/dotfiles-drift}"
IGNORE_FILE="$DOTFILES_DIR/scripts/drift-ignore.txt"
APT_BASELINE="$DOTFILES_DIR/scripts/snapshot/apt-manual.wsl.txt"

QUIET=0
UPDATE_BASELINE=0
for arg in "$@"; do
    case "$arg" in
        --quiet) QUIET=1 ;;
        --update-baseline) UPDATE_BASELINE=1 ;;
    esac
done

# 状態ディレクトリに書けない環境（sandbox 実行等）では一時ディレクトリへフォールバック
if ! mkdir -p "$STATE_DIR" 2>/dev/null || [[ ! -w "$STATE_DIR" ]]; then
    STATE_DIR="$(mktemp -d)"
fi
REPORT="$STATE_DIR/report.txt"

if [[ "$(uname)" == "Darwin" ]]; then
    OS=mac
    INSTALL_SCRIPT="$DOTFILES_DIR/install.sh"
else
    OS=wsl
    INSTALL_SCRIPT="$DOTFILES_DIR/install.wsl.sh"
fi

# --- ベースライン再生成モード ---
if (( UPDATE_BASELINE )); then
    if [[ "$OS" == "wsl" ]]; then
        mkdir -p "${APT_BASELINE:h}"
        apt-mark showmanual | sort > "$APT_BASELINE"
        echo "[OK] apt ベースラインを更新: $APT_BASELINE"
    else
        echo "[INFO] Mac のベースラインは Brewfile そのもの。brew bundle dump で更新すること。"
    fi
    exit 0
fi

findings=()
add() { findings+=("$1") }

# ignore ファイル（1行1パターン、部分一致。# 始まりと空行は無視）にマッチする項目は報告しない
is_ignored() {
    [[ -f "$IGNORE_FILE" ]] || return 1
    grep -v -e '^#' -e '^$' "$IGNORE_FILE" | while IFS= read -r pat; do
        [[ "$1" == *"$pat"* ]] && return 0
    done
    return 1
}

# =============================================================================
# 1. シンボリックリンクの健全性
#    install スクリプトの link 行を読み取り、実際のリンク状態と突き合わせる
# =============================================================================
sed -nE 's|^[[:space:]]*link "\$DOTFILES_DIR/([^"]+)"[[:space:]]+"\$HOME/([^"]+)".*|\1;\2|p' "$INSTALL_SCRIPT" |
while IFS=';' read -r rel_src rel_dst; do
    src="$DOTFILES_DIR/$rel_src"
    dst="$HOME/$rel_dst"

    if [[ ! -e "$src" ]]; then
        add "LINK | リポジトリ側のリンク元が存在しない: $rel_src（${INSTALL_SCRIPT:t} に記載）"
    elif [[ -L "$dst" ]]; then
        target="$(readlink "$dst")"
        [[ "$target" != "$src" ]] && add "LINK | リンク先が想定と異なる: $dst -> $target（想定: $src）"
    elif [[ -e "$dst" ]]; then
        if diff -rq "$src" "$dst" >/dev/null 2>&1; then
            add "LINK | 実ファイル化（内容は一致）: $dst。install スクリプトの再実行で復旧可"
        else
            add "LINK | 実ファイル化かつ内容差分あり: $dst（リポジトリ側: $rel_src）。環境側の変更をリポジトリへ取り込むか判断が必要"
        fi
    else
        add "LINK | リンク未作成: $dst（install スクリプト未実行の可能性）"
    fi
done

# =============================================================================
# 2. パッケージドリフト
# =============================================================================
if [[ "$OS" == "wsl" ]]; then
    # 2a. apt 手動インストールパッケージをベースラインと比較
    if [[ -f "$APT_BASELINE" ]]; then
        current="$(apt-mark showmanual | sort)"
        added="$(comm -23 <(echo "$current") "$APT_BASELINE")"
        removed="$(comm -13 <(echo "$current") "$APT_BASELINE")"
        for pkg in ${(f)added}; do
            add "PKG | ベースラインにない apt パッケージ: $pkg。install.wsl.sh への追加要否を判断すること"
        done
        for pkg in ${(f)removed}; do
            add "PKG | ベースラインにあるが削除された apt パッケージ: $pkg。install.wsl.sh やベースラインからの削除要否を判断すること"
        done
    else
        add "PKG | apt ベースライン未初期化。scripts/drift-check.sh --update-baseline を実行すること"
    fi

    # 2b. install.wsl.sh が導入するコマンドの存在確認
    for cmd in zsh fzf direnv batcat tig tmux jq gh eza starship mise ghq; do
        command -v "$cmd" >/dev/null 2>&1 || add "PKG | install.wsl.sh 導入対象のコマンドが見つからない: $cmd"
    done
else
    # 2c. Mac: Brewfile と実環境の差分
    if command -v brew >/dev/null 2>&1; then
        if ! brew bundle check --file="$DOTFILES_DIR/Brewfile" >/dev/null 2>&1; then
            add "PKG | Brewfile 記載のパッケージに未インストールあり（brew bundle check 失敗）"
        fi
        dump_diff="$(brew bundle dump --file=- 2>/dev/null | sort | comm -23 - <(sort "$DOTFILES_DIR/Brewfile"))"
        for line in ${(f)dump_diff}; do
            add "PKG | Brewfile にないインストール済みパッケージ: $line。Brewfile への追加要否を判断すること"
        done
    else
        add "PKG | brew コマンドが見つからない"
    fi
fi

# =============================================================================
# 3. ~/.claude 配下の未管理ファイル
#    リポジトリ由来のシンボリックリンク以外のスキル等は取り込み候補
# =============================================================================
for f in "$HOME/.claude/skills"/*(N); do
    if [[ -L "$f" ]]; then
        if [[ ! -e "$f" ]]; then
            add "CLAUDE | リンク切れのスキル: $f。手動削除が必要"
        elif [[ "$(readlink "$f")" != "$DOTFILES_DIR"/* ]]; then
            add "CLAUDE | リポジトリ外を指すスキル: $f"
        fi
    else
        add "CLAUDE | dotfiles 未管理のスキル: $f。リポジトリへの取り込み要否を判断すること"
    fi
done

# =============================================================================
# 結果出力
# =============================================================================
# ignore フィルタ適用
filtered=()
for f in "${findings[@]}"; do
    is_ignored "$f" || filtered+=("$f")
done

touch "$STATE_DIR/last-check"

if (( ${#filtered[@]} == 0 )); then
    : > "$REPORT"
    (( QUIET )) || echo "[OK] ドリフトなし（OS: $OS）"
    exit 0
fi

{
    echo "# dotfiles ドリフトレポート（OS: $OS / $(date '+%Y-%m-%d %H:%M')）"
    printf '%s\n' "${filtered[@]}"
} > "$REPORT"

if (( ! QUIET )); then
    cat "$REPORT"
    echo ""
    echo "対処するには dotfiles リポジトリで /dotfiles-drift-check を実行してください。"
fi
exit 1
