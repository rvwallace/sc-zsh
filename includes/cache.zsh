# shellcheck shell=zsh
zmodload zsh/stat

_sc_cache_hash() {
    local text="$1" char
    local -i hash=5381 code i
    for (( i=1; i <= ${#text}; i++ )); do
        char="$text[i]"
        printf -v code '%d' "'$char"
        (( hash = ((hash * 33) ^ code) & 0x7fffffff ))
    done
    printf -v REPLY '%d' "$hash"
}

_sc_evalcache() {
    local -a assignments=()
    while [[ "$1" =~ '^[A-Za-z_][A-Za-z0-9_]*=' ]]; do
        assignments+=("$1")
        shift
    done
    (( $# )) || return 1
    local tool="$1" executable="${commands[$1]:-}"
    [[ "$tool" == */* ]] && executable="$tool"
    [[ -n "$executable" && -x "$executable" ]] || return 1
    local resolved="${executable:A}" fingerprint cache generated temporary REPLY header
    local -A metadata
    zstat -H metadata "$resolved" 2>/dev/null || return 1
    fingerprint="v1|$ZSH_VERSION|$resolved|$metadata[inode]|$metadata[size]|$metadata[mtime]|$metadata[ctime]|${(j: :)${(q)@}}|${(j: :)assignments}|$HOME|${CARAPACE_BRIDGES:-}"
    _sc_cache_hash "$fingerprint"
    cache="$ZSH_CACHE_DIR/init-${tool:t}-$REPLY.zsh"
    if [[ -s "$cache" ]]; then
        IFS= read -r header < "$cache"
        if [[ "$header" == "# ${(q)fingerprint}" ]]; then
            source "$cache"
            return $?
        fi
    fi
    generated="$(
        local assignment
        for assignment in "${assignments[@]}"; do export "$assignment"; done
        command "$@"
    )" || return $?
    [[ -n "$generated" ]] || return 0
    command zsh -dfn <<< "$generated" || return 1
    temporary="$cache.$$.${RANDOM}"
    if { (umask 077; print -rl -- "# ${(q)fingerprint}" "$generated" >| "$temporary") } 2>/dev/null; then
        if command mv -f -- "$temporary" "$cache"; then
            source "$cache"
            return $?
        fi
        command rm -f -- "$temporary"
    fi
    eval "$generated"
}

_evalcache() { _sc_evalcache "$@"; }
