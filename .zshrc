# Profiling
if [[ "$SC_PROFILE" == "1" ]]; then
    zmodload zsh/zprof
    typeset -F SECONDS=0
fi

# Terminal Stability
# Freeze terminal state to prevent program crashes from corrupting the terminal
ttyctl -f

# Source a file if it exists
function _source() {
    local file="$1"
    if [[ -f "$file" ]]; then
        if [[ "$SC_PROFILE" == "1" ]]; then # setup profiling for sourcing files
            local start=$SECONDS
            source "$file"
            local end=$SECONDS
            local duration=$((end - start))
            printf "SOURCED %-30s %0.4fs\n" "$(basename "$file")" "$duration"
        else
            source "$file"
        fi
    fi
}

_zshrc_local_post="$HOME/.zshrc.local.post"

_source "$ZDOTDIR/includes/defaults.zsh"

# Ensure function/completion paths are available before autoloads or plugins
# Completions and Functions
fpath=("$ZDOTDIR/functions" "$ZDOTDIR/completions" $fpath)

# Add script completions to fpath (if directory exists)
if [[ -d "$ZDOTDIR/scripts/completions" ]]; then
    fpath=("$ZDOTDIR/scripts/completions" $fpath)
fi

# Built-in Functions
if [[ -d "$ZDOTDIR/functions" ]]; then
    # Autoload all built-in functions
    for func_file in "$ZDOTDIR/functions"/*(.N); do
        autoload -Uz "${func_file:t}"
    done
fi

# User Custom Functions
if [[ -d "$SC_USER_FUNCTIONS_DIR" ]]; then
    fpath=("$SC_USER_FUNCTIONS_DIR" $fpath)
    # Autoload all user functions
    for func_file in "$SC_USER_FUNCTIONS_DIR"/*(.N); do
        autoload -Uz "${func_file:t}"
    done
fi

# User Custom Completions
if [[ -d "$SC_USER_COMPLETIONS_DIR" ]]; then
    fpath=("$SC_USER_COMPLETIONS_DIR" $fpath)
fi

# Note: compinit is now handled by Zinit via zicompinit; zicdreplay
# (see includes/plugins.zsh - atload on zsh-completions plugin for optimal performance)


_source "$ZDOTDIR/includes/paths.zsh"
_source "$ZDOTDIR/includes/exports.zsh"
_source "$ZDOTDIR/includes/plugins.zsh"
_source "$ZDOTDIR/includes/options.zsh"
_source "$ZDOTDIR/includes/keybindings.zsh"
_source "$ZDOTDIR/includes/app_integrations.zsh"
_source "$ZDOTDIR/includes/aliases.zsh"

# Defer loading of user's local post-config (customizations that don't need to block startup)
# This is safe to defer as it's user-specific customizations, not core functionality
if [[ -f "$_zshrc_local_post" ]] && command -v zinit &> /dev/null; then
    zinit ice wait"1" lucid atload"source '$_zshrc_local_post'"
    zinit light zdharma-continuum/null
elif [[ -f "$_zshrc_local_post" ]]; then
    # Fallback if zinit isn't available (shouldn't happen, but safe fallback)
    source "$_zshrc_local_post"
fi

if [[ "$SC_PROFILE" == "1" ]]; then
    zprof
fi


# bun completions
[ -s "/Users/robertwallace/.bun/_bun" ] && source "/Users/robertwallace/.bun/_bun"
