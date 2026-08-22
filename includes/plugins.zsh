# shellcheck shell=zsh
# Zinit Installation & Plugin Management
# --------------------------------------

# -----------------
# 1. Bootstrapping
# -----------------
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if ! command -v git &> /dev/null; then
    echo "[SilentCastle zsh] git is required to manage zinit; exiting." >&2
    return 1 2>/dev/null || exit 1
fi

# Install zinit if not already installed
if [[ ! -d "$ZINIT_HOME" ]]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    if ! git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"; then
        echo "[SilentCastle zsh] failed to clone zinit repository; exiting." >&2
        return 1 2>/dev/null || exit 1
    fi
fi

if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
    echo "[SilentCastle zsh] zinit installation incomplete; exiting." >&2
    return 1 2>/dev/null || exit 1
fi

_source "$ZINIT_HOME/zinit.zsh"

# Direct completion dump to user cache directory
typeset -gA ZINIT
ZINIT[ZCOMPDUMP_PATH]="$ZSH_CACHE_DIR/zcompdump"

# -----------------
# 2. Guard Clause
# -----------------
# Stop here if non-interactive (unless profiling)
if [[ ! -o interactive && "${SC_PROFILE:-}" != 1 ]]; then
    return
fi

# -----------------
# 3. Core Plugins
# -----------------

# History substring search widgets must exist before the syntax highlighter
# binds ZLE widgets, otherwise the highlighter reports unhandled widget names.
zinit ice lucid
zinit light zsh-users/zsh-history-substring-search

# Keybindings for history search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Fast core plugins with for-syntax (using light mode for better performance)
zinit wait"0" lucid light-mode for \
    zdharma-continuum/fast-syntax-highlighting \
    zsh-users/zsh-autosuggestions \
    chrissicool/zsh-256color

# Cache generated shell init output for synchronous app integrations.
zinit ice lucid
zinit light mroth/evalcache

# Completions (loaded last with zicompinit + zicdreplay for optimal performance)
zinit wait"0" lucid light-mode nocd blockf \
    atpull'zinit creinstall -q zsh-users/zsh-completions' \
    atload"zicompinit; zicdreplay" for \
        zsh-users/zsh-completions

# -----------------
# 4. Utilities
# -----------------

# FZF tab completion (conditional on fzf being available)
zinit ice wait"1" lucid nocd has'fzf' atload'
    zstyle ":fzf-tab:complete:cd:*" fzf-preview "ls \$realpath"
    zstyle ":fzf-tab:complete:__zoxide_z:*" fzf-preview "ls \$realpath"
'
zinit light Aloxaf/fzf-tab

# -----------------
# 5. OMZ Snippets
# -----------------
zinit wait"3" lucid for \
    OMZP::extract \
    OMZP::gitignore \
    OMZP::gnu-utils

