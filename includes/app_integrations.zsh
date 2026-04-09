# shellcheck shell=zsh
# Application Integrations
# ------------------------
# This file loads integrations for external tools (Starship, FZF, etc.).
# It is guarded to strictly run only in interactive shells or when profiling.
# Most integrations are deferred using zinit's wait mechanism for faster startup.
# Starship loads synchronously to ensure it's ready for the first prompt.

if [[ ! -o interactive && "${SC_PROFILE:-}" != 1 ]]; then
    return
fi

# Ensure zinit is available (it should be loaded from plugins.zsh before this file)
if ! command -v zinit &> /dev/null; then
    echo "[SilentCastle zsh] ERROR: zinit not loaded. Ensure plugins.zsh is sourced before app_integrations.zsh" >&2
    echo "  Expected source order: plugins.zsh → app_integrations.zsh" >&2
    return 1 2>/dev/null || exit 1
fi

# -----------------
# 1. Prompt (Starship)
# -----------------
# Load synchronously - must be ready before first prompt renders
if (( $+commands[starship] )) && [[ "${ENABLE_STARSHIP:-true}" == "true" ]]; then
    export STARSHIP_LOG="error" # suppress warnings
    eval "$(starship init zsh)"
fi

# -----------------
# 2. System Info
# -----------------
# Load after prompt (wait"1") - fastfetch only runs once on startup
if (( $+commands[fastfetch] )) && [[ "${ENABLE_FASTFETCH:-false}" == "true" ]]; then
    zinit ice wait"1" lucid atload'fastfetch'
    zinit light zdharma-continuum/null
fi

# -----------------
# 3. Navigation & Completion
# -----------------
# FZF - Load after prompt (wait"1")
if (( $+commands[fzf] )); then
    zinit ice wait"1" lucid atload'eval "$(fzf --zsh)"'
    zinit light zdharma-continuum/null
    if [[ -z "$FZF_DEFAULT_COMMAND" ]]; then
        if (( $+commands[fd] )); then
            export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
        elif (( $+commands[rg] )); then
            export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git/*"'
        elif (( $+commands[ag] )); then
            export FZF_DEFAULT_COMMAND='ag -l --hidden -g "" --ignore .git'
        fi
    fi
fi

# Carapace (Completion Bridge) - Load after prompt (wait"1")
if (( $+commands[carapace] )); then
    zinit ice wait"1" lucid atload'
        export CARAPACE_BRIDGES="gen,zsh,fish,bash,inshellisense"
        source <(carapace _carapace zsh)
    '
    zinit light zdharma-continuum/null
fi

# Zoxide (Smart Directory Jumper) - Load after prompt (wait"1")
if (( $+commands[zoxide] )); then
    zinit ice wait"1" lucid atload'eval "$(zoxide init --cmd cd zsh)"'
    zinit light zdharma-continuum/null
fi

# -----------------
# 4. Utilities
# -----------------
# Homebrew command not found handler - Load after prompt (wait"1")
if (( $+commands[brew] )); then
    zinit ice wait"1" lucid atload'
        HOMEBREW_COMMAND_NOT_FOUND_HANDLER="$(brew --repository)/Library/Homebrew/command-not-found/handler.sh"
        if [ -f "$HOMEBREW_COMMAND_NOT_FOUND_HANDLER" ]; then
            source "$HOMEBREW_COMMAND_NOT_FOUND_HANDLER"
        fi
    '
    zinit light zdharma-continuum/null
fi
