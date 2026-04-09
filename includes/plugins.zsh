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

# OMZ git plugin (loaded early, no wait - provides aliases/functions)
zinit snippet OMZ::plugins/git/git.plugin.zsh

# Fast core plugins with for-syntax (using light mode for better performance)
zinit wait"0" lucid light-mode for \
    zsh-users/zsh-syntax-highlighting \
    zsh-users/zsh-autosuggestions \
    chrissicool/zsh-256color

# Completions (loaded last with zicompinit + zicdreplay for optimal performance)
zinit wait"0" lucid light-mode blockf \
    atpull'zinit creinstall -q .' \
    atload"zicompinit; zicdreplay" for \
        zsh-users/zsh-completions

# -----------------
# 4. Utilities
# -----------------

# FZF tab completion (conditional on fzf being available)
zinit ice wait"1" lucid has'fzf'
zinit light Aloxaf/fzf-tab

# Alias reminder - tells you when you type a command you have an alias for
zinit ice wait"1" lucid
zinit light MichaelAquilina/zsh-you-should-use

# FZF tab configuration (only if fzf-tab loaded)
if (( ${+functions[fzf-tab-complete]} )); then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview "ls \$realpath"
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview "ls \$realpath"
fi

# History substring search
zinit ice wait"1" lucid
zinit light zsh-users/zsh-history-substring-search

# Keybindings for history search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# -----------------
# 5. OMZ Snippets
# -----------------
mkdir -p "$ZSH_CACHE_DIR/completions"

zinit wait"1" lucid for \
    OMZP::eza \
    OMZP::extract \
    OMZP::gitignore \
    OMZP::gnu-utils 
# Eza plugin configuration
zstyle ':omz:plugins:eza' 'dirs-first' yes
zstyle ':omz:plugins:eza' 'icons' yes
zstyle ':omz:plugins:eza' 'git-status' yes
zstyle ':omz:plugins:eza' 'header' yes
zstyle ':omz:plugins:eza' 'size-prefix' binary