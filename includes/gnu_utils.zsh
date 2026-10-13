# shellcheck shell=zsh
# Command hashes leave Zsh built-ins and user aliases in control.
_sc_gnu_utils() {
    local name
    typeset -g _SC_GNU_SENTINEL=''
    local -a names=('[' base64 basename cat chcon chgrp chmod chown chroot cksum comm
        cp csplit cut date dd df dir dircolors dirname du echo env expand expr factor
        false fmt fold groups head hostid id indent install join kill link ln
        logname ls md5sum mkdir mkfifo mknod mktemp mv nice nl nohup nproc od
        paste pathchk pinky pr printenv printf ptx pwd readlink rm rmdir runcon
        seq sha1sum sha224sum sha256sum sha384sum sha512sum shred shuf sleep sort
        split stat stty sum sync tac tail tee test timeout touch tr true truncate
        tsort tty uname unexpand uniq unlink uptime users vdir wc who whoami yes
        find xargs locate sed tar time make hostname awk)
    for name in "${names[@]}"; do
        if (( $+commands[g$name] )); then
            hash "$name=${commands[g$name]}"
            [[ -n "$_SC_GNU_SENTINEL" ]] || _SC_GNU_SENTINEL="$name"
        fi
    done
    return 0
}
_sc_gnu_preexec() {
    [[ -z "$_SC_GNU_SENTINEL" ]] && return 0
    [[ "${commands[$_SC_GNU_SENTINEL]}" == "${commands[g$_SC_GNU_SENTINEL]}" ]] || _sc_gnu_utils
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _sc_gnu_preexec
_sc_gnu_utils
