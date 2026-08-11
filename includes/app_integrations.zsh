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

_sc_evalcache() {
    (( ${+functions[_evalcache]} )) || return 1

    _evalcache "$@" 2> >(
        command grep -v '^evalcache: .* initialization not cached, caching output of:' >&2
    )
}

_sc_aws_token_ttl() {
    emulate -L zsh -o extended_glob

    local profile=${SC_AWS_TOKEN_PROFILE:-techops}
    local credentials_file=${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}
    local line section expires

    [[ -r "$credentials_file" ]] || return 1

    while IFS= read -r line; do
        if [[ "$line" == \[*\] ]]; then
            section="${line#\[}"
            section="${section%\]}"
            continue
        fi

        if [[ "$section" == "$profile" && "$line" == x_security_token_expires[[:space:]]#=* ]]; then
            expires="${line#*=}"
            expires="${expires##[[:space:]]#}"
            expires="${expires%%[[:space:]]#}"
            break
        fi
    done < "$credentials_file"

    [[ -n "$expires" ]] || return 1

    local normalized=$expires
    if [[ "$normalized" == *[+-][0-9][0-9]:[0-9][0-9] ]]; then
        normalized="${normalized%:*}${normalized##*:}"
    fi

    local expires_epoch
    expires_epoch=$(strftime -r "%Y-%m-%dT%H:%M:%S%z" "$normalized" 2>/dev/null) ||
        expires_epoch=$(strftime -r "%Y-%m-%dT%H%M%S%z" "$normalized" 2>/dev/null) ||
        return 1

    local remaining_seconds=$((expires_epoch - EPOCHSECONDS))
    local abs_seconds=${remaining_seconds#-}
    local hours=$((abs_seconds / 3600))
    local minutes=$(((abs_seconds % 3600) / 60))
    local seconds=$((abs_seconds % 60))
    local formatted

    printf -v formatted "%02d:%02d:%02d" "$hours" "$minutes" "$seconds"
    (( remaining_seconds < 0 )) && formatted="-$formatted"
    print -r -- "$formatted"
}

_sc_refresh_aws_token_ttl() {
    [[ -n "$AWS_PROFILE" ]] || {
        unset SC_AWS_TOKEN_TTL
        return
    }

    local now=${EPOCHSECONDS:-0}
    local cache_seconds=${SC_AWS_TOKEN_CACHE_SECONDS:-60}

    (( now > 0 )) || return
    (( now - ${SC_AWS_TOKEN_LAST_CHECK:-0} < cache_seconds )) && return

    typeset -g SC_AWS_TOKEN_LAST_CHECK=$now
    export SC_AWS_TOKEN_TTL
    SC_AWS_TOKEN_TTL="$(_sc_aws_token_ttl)" || unset SC_AWS_TOKEN_TTL
}

zmodload zsh/datetime 2>/dev/null
autoload -Uz add-zsh-hook
add-zsh-hook precmd _sc_refresh_aws_token_ttl

# -----------------
# 1. Prompt (Starship)
# -----------------
# Load synchronously - must be ready before first prompt renders
if (( $+commands[starship] )) && [[ "${ENABLE_STARSHIP:-true}" == "true" ]]; then
    export STARSHIP_LOG="error" # suppress warnings
    if (( ${+functions[_evalcache]} )); then
        _sc_evalcache starship init zsh
    else
        eval "$(starship init zsh)"
    fi
fi

# -----------------
# 2. System Info
# -----------------
# Load after optional integrations (wait"4") - fastfetch only runs once on startup
if (( $+commands[fastfetch] )) && [[ "${ENABLE_FASTFETCH:-false}" == "true" ]]; then
    zinit ice wait"4" lucid nocd atload'fastfetch'
    zinit light zdharma-continuum/null
fi

# -----------------
# 3. Navigation & Completion
# -----------------
# FZF - Load after prompt (wait"1")
if (( $+commands[fzf] )); then
    zinit ice wait"1" lucid nocd atload'
        if (( ${+functions[_evalcache]} )); then
            _sc_evalcache fzf --zsh
        else
            eval "$(fzf --zsh)"
        fi
    '
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
    zinit ice wait"1" lucid nocd atload'
        export CARAPACE_BRIDGES="gen,zsh,fish,bash,inshellisense"
        if (( ${+functions[_evalcache]} )); then
            _sc_evalcache carapace _carapace zsh
        else
            source <(carapace _carapace zsh)
        fi
    '
    zinit light zdharma-continuum/null
fi

# Zoxide (Smart Directory Jumper) - Load after prompt (wait"1")
if (( $+commands[zoxide] )); then
    zinit ice wait"1" lucid nocd atload'
        if (( ${+functions[_evalcache]} )); then
            _sc_evalcache zoxide init --cmd cd zsh
        else
            eval "$(zoxide init --cmd cd zsh)"
        fi
    '
    zinit light zdharma-continuum/null
fi

# -----------------
# 4. Utilities
# -----------------
# Homebrew command not found handler - Load after other utilities (wait"3")
if (( $+commands[brew] )); then
    zinit ice wait"3" lucid nocd atload'
        HOMEBREW_COMMAND_NOT_FOUND_HANDLER="$(brew --repository)/Library/Homebrew/command-not-found/handler.sh"
        if [ -f "$HOMEBREW_COMMAND_NOT_FOUND_HANDLER" ]; then
            source "$HOMEBREW_COMMAND_NOT_FOUND_HANDLER"
        fi
    '
    zinit light zdharma-continuum/null
fi
