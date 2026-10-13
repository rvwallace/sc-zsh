#!/usr/bin/env bash
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$ROOT/scripts/install-paths.sh"
sc_install_paths || exit 1
[[ $# == 0 ]] || { printf 'Usage: bash doctor.sh\n' >&2; exit 1; }
failures=0
warnings=0
pass() { printf 'PASS: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*"; failures=$((failures + 1)); }
warn() { printf 'WARN: %s\n' "$*"; warnings=$((warnings + 1)); }

if ZSH_BIN=$(command -v zsh) && sc_zsh_version_supported "$ZSH_BIN"; then
    pass 'Zsh 5.9 or later is available'
else
    fail 'Zsh 5.9 or later is required'
fi
git_available=false
if command -v git >/dev/null; then git_available=true; pass 'Git is available'; else fail 'Git is missing'; fi
version=unknown
if [[ -r "$ROOT/VERSION" ]]; then
    version=$(<"$ROOT/VERSION")
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        fail 'VERSION must contain a numeric major.minor.patch version'
        version=unknown
    fi
else
    fail 'VERSION is missing or unreadable'
fi
revision='unavailable (archive or non-Git checkout)'
if "$git_available"; then
    git_root=$(git --no-optional-locks -C "$ROOT" rev-parse --show-toplevel 2>/dev/null) || git_root=''
    if [[ -n "$git_root" && "$git_root" -ef "$ROOT" ]]; then
        revision=$(git --no-optional-locks -C "$ROOT" rev-parse --short HEAD 2>/dev/null) || revision=unavailable
        if changes=$(git --no-optional-locks -C "$ROOT" status --porcelain 2>/dev/null); then
            [[ -z "$changes" ]] || revision="$revision (modified)"
        else
            warn 'Cannot inspect checkout modifications'
        fi
    fi
fi
printf 'sc-zsh %s | Git: %s\n' "$version" "$revision"
for file in "$ROOT/.zshenv" "$ROOT/.zshrc"; do
    [[ -f "$file" && -r "$file" ]] || fail "Repository startup file is missing: $file"
done
for include in defaults paths exports cache plugins options keybindings app_integrations gnu_utils aliases; do
    [[ -r "$ROOT/includes/$include.zsh" ]] || fail "Repository include is missing: $include.zsh"
done
if [[ -L "$SC_INSTALL_HOME/.zshenv" && "$SC_INSTALL_HOME/.zshenv" -ef "$ROOT/.zshenv" ]]; then
    pass 'The home bootstrap links to this checkout'
else
    fail 'The home .zshenv does not link to this checkout'
fi
for file in "$SC_INSTALL_HOME/.zshrc.local.pre" "$SC_INSTALL_HOME/.zshrc.local.post"; do
    if [[ -f "$file" && -r "$file" ]]; then
        pass "Personal file exists: $file"
        mode=$(LC_ALL=C ls -ldL "$file")
        mode=${mode%% *}
        if [[ ${mode:4:1} == r || ${mode:7:1} == r ]]; then
            warn "Personal file is readable by group or others: $file"
        fi
    else
        fail "Personal file is missing or unreadable: $file"
    fi
done
for directory in "$SC_INSTALL_USER_DIR" "$SC_INSTALL_FUNCTIONS_DIR" "$SC_INSTALL_COMPLETIONS_DIR"; do
    if [[ -d "$directory" ]]; then pass "Directory exists: $directory"; else fail "Directory is missing: $directory"; fi
done
if [[ -d "$SC_INSTALL_CACHE_DIR" && -w "$SC_INSTALL_CACHE_DIR" ]]; then
    pass 'The Zsh cache directory is writable'
else
    warn 'The Zsh cache directory is missing or read-only'
fi

# Inspect trusted repository metadata, never personal configuration contents.
source "$ROOT/scripts/plugin-manifest.zsh"
for (( i=0; i < ${#SC_PLUGINS[@]}; i+=3 )); do
    name=${SC_PLUGINS[i]}
    revision=${SC_PLUGINS[i+2]}
    target="$SC_INSTALL_PLUGIN_DIR/$name"
    if [[ ! -d "$target/.git" ]]; then
        fail "Plugin is missing: $name"
    elif "$git_available"; then
        current=$(git --no-optional-locks -C "$target" rev-parse HEAD 2>/dev/null) || current=''
        if [[ "$current" == "$revision" ]]; then pass "Plugin matches its pin: $name"; else fail "Plugin revision differs from its pin: $name"; fi
        if ! changes=$(git --no-optional-locks -C "$target" status --porcelain 2>/dev/null); then
            fail "Cannot inspect the plugin checkout: $name"
        elif [[ -n "$changes" ]]; then
            warn "Plugin contains local changes: $name"
        fi
    fi
done
for tool in starship fzf carapace zoxide eza uv; do
    if command -v "$tool" >/dev/null; then pass "Optional tool is available: $tool"; else warn "Optional tool is missing: $tool"; fi
done
printf 'Doctor: %s problem(s), %s warning(s).\n' "$failures" "$warnings"
if (( failures )); then printf 'Run bash "%s/setup.sh" to repair the installation.\n' "$ROOT"; exit 1; fi
