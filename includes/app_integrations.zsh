# shellcheck shell=zsh
[[ -o interactive ]] || return 0

if (( $+commands[starship] )) && [[ "$ENABLE_STARSHIP" == true ]]; then
    export STARSHIP_LOG=error
    _sc_evalcache starship init zsh
fi
if (( $+commands[fzf] )); then
    if [[ -z "$FZF_DEFAULT_COMMAND" ]]; then
        if (( $+commands[fd] )); then
            export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
        elif (( $+commands[rg] )); then
            export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git/*"'
        elif (( $+commands[ag] )); then
            export FZF_DEFAULT_COMMAND='ag -l --hidden -g "" --ignore .git'
        fi
    fi
    # FZF restores ZLE options that Zsh cannot change without a terminal.
    [[ -t 0 ]] && _sc_evalcache fzf --zsh
fi
if (( $+commands[carapace] )); then
    _path_prepend "$HOME/Library/Application Support/carapace/bin"
    export CARAPACE_BRIDGES='gen,zsh,fish,bash,inshellisense'
    _sc_evalcache carapace _carapace zsh
fi
local command_name completion
if (( $+functions[compdef] && ${#_SC_CUSTOM_COMPLETIONS} )); then
    for command_name completion in "${(@kv)_SC_CUSTOM_COMPLETIONS}"; do
        compdef "$completion" "$command_name"
    done
fi
(( $+commands[zoxide] )) && _sc_evalcache zoxide init zsh
if [[ -n "$HOMEBREW_REPOSITORY" ]]; then
    local handler="$HOMEBREW_REPOSITORY/Library/Homebrew/command-not-found/handler.sh"
    [[ -r "$handler" ]] && source "$handler"
fi
return 0
