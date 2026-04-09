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

# Load Homebrew (Explicitly check standard locations to avoid circular dependency)
# SECURITY NOTE: This uses eval with Homebrew output, which is a known trust boundary.
# Homebrew is considered trusted software installed by the system administrator.
# In high-security environments, verify Homebrew binary integrity before sourcing.
# The eval executes `brew shellenv zsh` output to set HOMEBREW_* environment variables and PATH.
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv zsh)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

# User specific paths (Prepended last to ensure highest priority)
_path_prepend "$HOME/.cargo/bin"
_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/go/bin"
_path_prepend "$HOME/.npm-global/bin"

# Export the updated PATH from the array
# Note: (j/:/) is Zsh join syntax - joins array elements with ':' delimiter
# shellcheck disable=SC2296  # Zsh join syntax is valid
export PATH=${(j/:/)path}
