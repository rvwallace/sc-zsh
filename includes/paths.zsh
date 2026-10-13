# shellcheck shell=zsh
# Update PATH to include tool directories

# WARNING: Do not use `typeset -U path` here as it causes issues with the current setup.
# We manually handle deduplication in the helper functions below.

# Remove a directory from the path
function _path_remove() {
    # shellcheck disable=SC2296  # Zsh array expansion with pattern removal
    path=("${(@)path:#$1}")
}

# Prepend a directory to the path (removing it first if it exists)
function _path_prepend() {
    [[ -d "$1" ]] || return
    _path_remove "$1"
    # shellcheck disable=SC2128,SC2206  # Zsh array expansion without index is intentional
    path=("$1" $path)
}

# Append a directory to the path (removing it first if it exists)
function _path_append() {
    [[ -d "$1" ]] || return
    _path_remove "$1"
    # shellcheck disable=SC2128,SC2206  # Zsh array expansion without index is intentional
    path=($path "$1")
}

# Use the same standard locations as Homebrew, without launching brew or Bash.
_sc_homebrew_env() {
    local brew_file
    if [[ -x /opt/homebrew/bin/brew ]]; then
        brew_file=/opt/homebrew/bin/brew
    elif [[ -x /usr/local/bin/brew ]]; then
        brew_file=/usr/local/bin/brew
    elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        brew_file=/home/linuxbrew/.linuxbrew/bin/brew
    fi
    if [[ -n "$brew_file" ]]; then
        export HOMEBREW_PREFIX="${brew_file:h:h}"
        export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
        export HOMEBREW_REPOSITORY="${brew_file:A:h:h}"
        [[ -d /usr/local/Homebrew && "$HOMEBREW_PREFIX" == /usr/local ]] && export HOMEBREW_REPOSITORY=/usr/local/Homebrew
        local brew_completions="$HOMEBREW_PREFIX/share/zsh/site-functions"
        [[ -d "$brew_completions" && ${fpath[(Ie)$brew_completions]} == 0 ]] && fpath=("$brew_completions" $fpath)
        export FPATH
        if [[ -n "$MANPATH" ]]; then
            while [[ "$MANPATH" == :* ]]; do MANPATH="${MANPATH#:}"; done
            while [[ "$MANPATH" == *: ]]; do MANPATH="${MANPATH%:}"; done
            export MANPATH=":$MANPATH"
        fi
        local info="$HOMEBREW_PREFIX/share/info"
        local -a info_paths=("${(@s/:/)INFOPATH}")
        info_paths=("${(@)info_paths:#$info}")
        export INFOPATH="$info:${(j/:/)info_paths}"
        _path_prepend "$HOMEBREW_PREFIX/sbin"
        _path_prepend "$HOMEBREW_PREFIX/bin"
    fi
}
_sc_homebrew_env

# User specific paths (Prepended last to ensure highest priority)
_path_prepend "$HOME/.cargo/bin"
_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/go/bin"
_path_prepend "$HOME/.npm-global/bin"
_path_prepend "$HOME/.opencode/bin"
_path_prepend "/opt/homebrew/opt/ruby/bin"

# Export the updated PATH from the array
# Note: (j/:/) is Zsh join syntax - joins array elements with ':' delimiter
# shellcheck disable=SC2296  # Zsh join syntax is valid
export PATH=${(j/:/)path}
