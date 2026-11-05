# shellcheck shell=zsh
# OSC 133 is shell lifecycle metadata, independent of Starship's visible prompt.
[[ -o interactive && -t 1 && -n ${REX_SERVER:-} && -n ${REX_BLOCK:-} ]] || return 0
[[ -z ${TMUX:-} && ${TERM:-} != dumb ]] || return 0
# Avoid adding a second marker producer when another integration is already loaded.
(( ! ${+_ghostty_state} && ! ${+_ksi_state} && ! ${+_sc_rex_osc133_loaded} )) || return 0

typeset -g _sc_rex_osc133_loaded=1
typeset -gi _sc_rex_command_running=0
typeset -g _sc_rex_prompt_start=$'%{\e]133;A\a%}'
typeset -g _sc_rex_prompt_end=$'%{\e]133;B\a%}'

_sc_rex_precmd() {
    local command_status=$?
    if (( _sc_rex_command_running )); then
        builtin printf '\e]133;D;%d\a' "$command_status"
        _sc_rex_command_running=0
    fi
    # Themes can rebuild PROMPT in precmd; reapply only if our wrapper is absent.
    # %{...%} keeps the nonprinting sequences out of ZLE's width calculation.
    if [[ $PROMPT != "$_sc_rex_prompt_start"* ]]; then
        PROMPT="${_sc_rex_prompt_start}${PROMPT}${_sc_rex_prompt_end}"
    fi
    return 0
}

_sc_rex_preexec() {
    builtin printf '\e]133;C\a'
    _sc_rex_command_running=1
    return 0
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _sc_rex_precmd
add-zsh-hook preexec _sc_rex_preexec
