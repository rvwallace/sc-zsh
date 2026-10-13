# Shared paths for setup and read-only installation checks.
sc_install_paths() {
    if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
        printf 'ERROR: HOME must identify an existing home directory.\n' >&2
        return 1
    fi
    SC_INSTALL_HOME=$(cd "$HOME" && pwd -P) || return 1
    [[ "$SC_INSTALL_HOME" != / ]] || {
        printf 'ERROR: Refusing to use the filesystem root as HOME.\n' >&2
        return 1
    }
    SC_INSTALL_USER_DIR="${SC_USER_DIR:-$SC_INSTALL_HOME/.sc-zsh}"
    SC_INSTALL_FUNCTIONS_DIR="${SC_USER_FUNCTIONS_DIR:-$SC_INSTALL_USER_DIR/functions}"
    SC_INSTALL_COMPLETIONS_DIR="${SC_USER_COMPLETIONS_DIR:-$SC_INSTALL_USER_DIR/completions}"
    SC_INSTALL_PLUGIN_DIR="${SC_PLUGIN_DIR:-${XDG_DATA_HOME:-$SC_INSTALL_HOME/.local/share}/sc-zsh/plugins}"
    SC_INSTALL_CACHE_DIR="${XDG_CACHE_HOME:-$SC_INSTALL_HOME/.cache}/zsh"
    local directory
    for directory in "$SC_INSTALL_USER_DIR" "$SC_INSTALL_FUNCTIONS_DIR" \
        "$SC_INSTALL_COMPLETIONS_DIR" "$SC_INSTALL_PLUGIN_DIR" "$SC_INSTALL_CACHE_DIR" \
        "${XDG_DATA_HOME:-$SC_INSTALL_HOME/.local/share}" "${XDG_CACHE_HOME:-$SC_INSTALL_HOME/.cache}"; do
        case "$directory" in
            /*) ;;
            *) printf 'ERROR: Installation paths must be absolute: %s\n' "$directory" >&2; return 1 ;;
        esac
        [[ "$directory" != / ]] || { printf 'ERROR: Installation directory cannot be /.\n' >&2; return 1; }
    done
}

sc_zsh_version_supported() {
    "$1" -dfc 'parts=(${(s:.:)ZSH_VERSION}); (( parts[1] > 5 || (parts[1] == 5 && parts[2] >= 9) ))'
}
