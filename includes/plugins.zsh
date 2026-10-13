# shellcheck shell=zsh
[[ -o interactive ]] || return 0

_sc_plugin_source() {
    local file="$SC_PLUGIN_DIR/$1/$2"
    if [[ -r "$file" ]]; then
        _source "$file"
    else
        print -u2 -- "[sc-zsh] Missing plugin $1. Run: zsh $ZDOTDIR/scripts/plugins.zsh install"
        return 1
    fi
}

[[ -d "$SC_PLUGIN_DIR/zsh-completions/src" ]] && fpath=("$SC_PLUGIN_DIR/zsh-completions/src" $fpath)
autoload -Uz compinit
zmodload zsh/stat
zmodload zsh/datetime
local dump="$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"
local signature="${(j:\n:)fpath}" cached_signature='' now=$EPOCHSECONDS
local -A dump_stat
[[ -r "$dump.fpath" ]] && cached_signature="$(<"$dump.fpath")"
if [[ -s "$dump" ]] && zstat -H dump_stat "$dump" 2>/dev/null &&
   [[ "$cached_signature" == "$signature" ]] &&
   (( now - dump_stat[mtime] < SC_COMPLETION_MAX_AGE )); then
    compinit -C -d "$dump"
else
    # Audit on rebuild. -i excludes insecure directories without prompting.
    local temporary="$dump.$$.${RANDOM}"
    if [[ -w "$ZSH_CACHE_DIR" ]]; then
        compinit -i -d "$temporary"
    else
        compinit -i -D
    fi
    if [[ -s "$temporary" ]]; then
        print -r -- "$signature" >| "$temporary.fpath"
        command rm -f -- "$dump.zwc"
        command mv -f -- "$temporary" "$dump" 2>/dev/null
        command mv -f -- "$temporary.fpath" "$dump.fpath" 2>/dev/null
    fi
fi
if [[ -s "$dump" && ! -s "$dump.zwc" && -w "$ZSH_CACHE_DIR" ]]; then
    local compiled="$dump.$$.${RANDOM}.zwc"
    if zcompile -R "$compiled" "$dump" 2>/dev/null; then
        command mv -f -- "$compiled" "$dump.zwc" 2>/dev/null || command rm -f -- "$compiled"
    fi
fi

# Carapace must not replace repository or personal completion definitions.
typeset -gA _SC_CUSTOM_COMPLETIONS=()
local -a custom_functions=("$ZDOTDIR"/completions/_*(N:t) "$SC_USER_COMPLETIONS_DIR"/_*(N:t))
local command_name completion
for command_name completion in "${(@kv)_comps}"; do
    if (( ${custom_functions[(Ie)$completion]} )); then
        _SC_CUSTOM_COMPLETIONS[$command_name]="$completion"
    fi
done

_sc_plugin_source zsh-history-substring-search zsh-history-substring-search.zsh
if (( $+widgets[history-substring-search-up] )); then
    bindkey -M emacs '^P' history-substring-search-up
    bindkey -M emacs '^N' history-substring-search-down
    bindkey -M vicmd k history-substring-search-up
    bindkey -M vicmd j history-substring-search-down
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
fi

_sc_load_widgets() {
    if (( $+commands[fzf] )); then
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'command ls "$realpath"'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'command ls "$realpath"'
        _sc_plugin_source fzf-tab fzf-tab.plugin.zsh
    fi
    _sc_plugin_source zsh-autosuggestions zsh-autosuggestions.zsh
    _sc_plugin_source fast-syntax-highlighting fast-syntax-highlighting.plugin.zsh
}
