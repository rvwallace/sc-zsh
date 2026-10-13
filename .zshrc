# Profiling
if [[ "$SC_PROFILE" == "1" ]]; then
    zmodload zsh/zprof
    typeset -F SECONDS=0
fi

# Terminal Stability
# Freeze terminal state to prevent program crashes from corrupting the terminal
if [[ -t 0 && -o interactive ]]; then
    ttyctl -f 2>/dev/null || true
fi

# Source a file if it exists
function _source() {
    local file="$1"
    if [[ -f "$file" ]]; then
        if [[ "$SC_PROFILE" == "1" ]]; then # setup profiling for sourcing files
            local start=$SECONDS
            source "$file"
            local end=$SECONDS
            local duration=$((end - start))
            printf "SOURCED %-30s %0.4fs\n" "${file:t}" "$duration" >&2
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

_source "$ZDOTDIR/includes/paths.zsh"
_source "$ZDOTDIR/includes/exports.zsh"
_source "$ZDOTDIR/includes/cache.zsh"
_source "$ZDOTDIR/includes/plugins.zsh"
_source "$ZDOTDIR/includes/options.zsh"
_source "$ZDOTDIR/includes/keybindings.zsh"
_source "$ZDOTDIR/includes/app_integrations.zsh"
_source "$ZDOTDIR/includes/gnu_utils.zsh"
_source "$ZDOTDIR/includes/aliases.zsh"

_source "$_zshrc_local_post"
# Personal PATH changes can invalidate GNU command hashes.
_sc_gnu_utils

# Bind wrappers after every integration and personal widget exists.
_sc_load_widgets

if (( $+commands[fastfetch] )) && [[ "$ENABLE_FASTFETCH" == true ]]; then
    fastfetch
fi

if [[ "$SC_PROFILE" == "1" ]]; then
    zprof
fi
