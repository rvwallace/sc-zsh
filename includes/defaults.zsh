# shellcheck shell=zsh
# Configuration Defaults
# ----------------------
# Internal configuration flags for the zsh setup.

# User customization directory (can be overridden in .zshrc.local.pre)
SC_USER_DIR="${SC_USER_DIR:-$HOME/.sc-zsh}"
SC_USER_FUNCTIONS_DIR="${SC_USER_FUNCTIONS_DIR:-${SC_USER_DIR}/functions}"
SC_USER_COMPLETIONS_DIR="${SC_USER_COMPLETIONS_DIR:-${SC_USER_DIR}/completions}"


# Feature flags (Used in app_integrations.zsh and user config files)
# shellcheck disable=SC2034
ENABLE_STARSHIP=true
# ENABLE_GNU_SED=true
# ENABLE_GNU_TAR=true
# shellcheck disable=SC2034
ENABLE_FASTFETCH=false