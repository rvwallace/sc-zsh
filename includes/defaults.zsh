# shellcheck shell=zsh
# Configuration Defaults
# ----------------------
# Internal configuration flags for the zsh setup.

# Cache directory (XDG compliant with macOS fallback)
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR" 2>/dev/null
SC_PLUGIN_DIR="${SC_PLUGIN_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/sc-zsh/plugins}"
SC_COMPLETION_MAX_AGE="${SC_COMPLETION_MAX_AGE:-86400}"

# User customization directory (can be overridden in .zshrc.local.pre)
SC_USER_DIR="${SC_USER_DIR:-$HOME/.sc-zsh}"
SC_USER_FUNCTIONS_DIR="${SC_USER_FUNCTIONS_DIR:-${SC_USER_DIR}/functions}"
SC_USER_COMPLETIONS_DIR="${SC_USER_COMPLETIONS_DIR:-${SC_USER_DIR}/completions}"


# Feature flags (Used in app_integrations.zsh and user config files)
# shellcheck disable=SC2034
ENABLE_STARSHIP="${ENABLE_STARSHIP:-true}"
# shellcheck disable=SC2034
ENABLE_FASTFETCH="${ENABLE_FASTFETCH:-false}"
