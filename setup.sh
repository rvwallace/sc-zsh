#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$ROOT/scripts/install-paths.sh"
install_plugins=true
case "${1:-}" in
    '') ;;
    --skip-plugins) install_plugins=false ;;
    --help) printf 'Usage: bash setup.sh [--skip-plugins]\n'; exit 0 ;;
    *) printf 'Usage: bash setup.sh [--skip-plugins]\n' >&2; exit 1 ;;
esac
[[ $# -le 1 ]] || { printf 'Unexpected setup arguments.\n' >&2; exit 1; }
sc_install_paths
[[ -r "$ROOT/.zshenv" && -r "$ROOT/.zshrc" ]] || { printf 'ERROR: Repository startup files are missing.\n' >&2; exit 1; }
ZSH_BIN=$(command -v zsh) || { printf 'ERROR: Install Zsh 5.9 or later first.\n' >&2; exit 1; }
sc_zsh_version_supported "$ZSH_BIN" || { printf 'ERROR: Zsh 5.9 or later is required.\n' >&2; exit 1; }
if "$install_plugins"; then
    command -v git >/dev/null || { printf 'ERROR: Git is required for plugin installation.\n' >&2; exit 1; }
fi

# Check conflicts before changing the bootstrap link or personal files.
for file in "$SC_INSTALL_HOME/.zshrc.local.pre" "$SC_INSTALL_HOME/.zshrc.local.post"; do
    if [[ -e "$file" || -L "$file" ]]; then
        [[ -f "$file" && -r "$file" ]] || {
            printf 'ERROR: Preserve and repair this unreadable personal file: %s\n' "$file" >&2
            exit 1
        }
    fi
done
for directory in "$SC_INSTALL_USER_DIR" "$SC_INSTALL_FUNCTIONS_DIR" \
    "$SC_INSTALL_COMPLETIONS_DIR" "$SC_INSTALL_PLUGIN_DIR" "$SC_INSTALL_CACHE_DIR"; do
    if [[ -e "$directory" || -L "$directory" ]]; then
        [[ -d "$directory" ]] || { printf 'ERROR: Expected a directory: %s\n' "$directory" >&2; exit 1; }
    fi
done
mkdir -p "$SC_INSTALL_USER_DIR" "$SC_INSTALL_FUNCTIONS_DIR" \
    "$SC_INSTALL_COMPLETIONS_DIR" "$SC_INSTALL_PLUGIN_DIR" "$SC_INSTALL_CACHE_DIR"

target="$SC_INSTALL_HOME/.zshenv"
if [[ -L "$target" && "$target" -ef "$ROOT/.zshenv" ]]; then
    printf 'Already linked: %s\n' "$target"
else
    if [[ -e "$target" || -L "$target" ]]; then
        backup="$target.bak.$(date +%Y%m%d%H%M%S)"
        counter=1
        while [[ -e "$backup" || -L "$backup" ]]; do
            backup="$target.bak.$(date +%Y%m%d%H%M%S).$counter"
            counter=$((counter + 1))
        done
        mv -- "$target" "$backup"
        printf 'Backed up: %s -> %s\n' "$target" "$backup"
    fi
    ln -s "$ROOT/.zshenv" "$target"
    printf 'Linked: %s -> %s\n' "$target" "$ROOT/.zshenv"
fi

for phase in pre post; do
    file="$SC_INSTALL_HOME/.zshrc.local.$phase"
    if [[ -e "$file" || -L "$file" ]]; then
        printf 'Preserved personal file: %s\n' "$file"
    else
        (umask 077; set -C; printf '# Personal sc-zsh %s configuration.\n# See .zshrc.local.%s.example in the repository.\n' "$phase" "$phase" > "$file")
        printf 'Created personal file: %s\n' "$file"
    fi
done
if "$install_plugins"; then
    SC_PLUGIN_DIR="$SC_INSTALL_PLUGIN_DIR" "$ZSH_BIN" -df "$ROOT/scripts/plugins.zsh" install
else
    printf 'Skipped plugins. Run: zsh "%s/scripts/plugins.zsh" install\n' "$ROOT"
fi
printf 'Setup complete. Run bash "%s/doctor.sh", then start a fresh Zsh session.\n' "$ROOT"
