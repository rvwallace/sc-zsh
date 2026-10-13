#!/usr/bin/env zsh
emulate -LR zsh
setopt err_exit pipe_fail
local root="${0:A:h:h}"
source "$root/scripts/plugin-manifest.zsh"
local operation="${1:-install}"
[[ "$operation" == install || "$operation" == update ]] || {
    print -u2 'Usage: zsh scripts/plugins.zsh install|update'
    exit 1
}
(( $# <= 1 && $#SC_PLUGINS % 3 == 0 )) || { print -u2 'Invalid arguments or plugin manifest'; exit 1; }
local destination="${SC_PLUGIN_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/sc-zsh/plugins}"
local legacy="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/plugins"
[[ "$destination" == /* ]] || { print -u2 'SC_PLUGIN_DIR must be absolute'; exit 1; }
destination="${destination:A}"
[[ "$destination" != / ]] || { print -u2 'SC_PLUGIN_DIR cannot be /'; exit 1; }
local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ "$cache" == /* ]] || { print -u2 'XDG_CACHE_HOME must be absolute'; exit 1; }
local -i changed=0
local staged=''
_sc_plugins_cleanup() {
    local result="$1" signature
    if [[ -n "$staged" && "${staged:h}" == "$destination" && "${staged:t}" == .sc-zsh-plugin.* ]]; then
        command rm -rf -- "$staged"
    fi
    if (( changed )); then
        for signature in "$cache"/zcompdump-*.fpath(N); do command rm -f -- "$signature"; done
    fi
    return "$result"
}
trap '_sc_plugins_cleanup $?' EXIT
_sc_plugins_clean() {
    local changes
    changes=$(git --no-optional-locks -C "$1" status --porcelain) || return 1
    [[ -z "$changes" ]]
}
mkdir -p "$destination"
local name repository revision target previous current i
for (( i=1; i <= $#SC_PLUGINS; i+=3 )); do
    name="$SC_PLUGINS[i]" repository="$SC_PLUGINS[i+1]" revision="$SC_PLUGINS[i+2]"
    [[ "$name" =~ '^[A-Za-z0-9][A-Za-z0-9._-]*$' && "$revision" =~ '^[0-9a-fA-F]{40}$' ]] || {
        print -u2 -- "Invalid plugin name or pinned revision: $name"
        exit 1
    }
    revision="${revision:l}"
    target="$destination/$name"
    if [[ -d "$target/.git" ]]; then
        current=$(git -C "$target" rev-parse HEAD)
        _sc_plugins_clean "$target" || {
            print -u2 -- "Refusing to overwrite modified or unreadable plugin: $target"
            exit 1
        }
        if [[ "$current" != "$revision" ]]; then
            git -C "$target" cat-file -e "$revision^{commit}" 2>/dev/null || git -C "$target" fetch --depth=1 origin "$revision"
            git -C "$target" checkout --quiet --detach "$revision"
            changed=1
        fi
    elif [[ -e "$target" || -L "$target" ]]; then
        print -u2 -- "Expected a Git plugin checkout: $target"
        exit 1
    else
        previous="$legacy/${repository//\//---}"
        staged=$(mktemp -d "$destination/.sc-zsh-plugin.XXXXXX")
        if [[ -d "$previous/.git" && "$(git -C "$previous" rev-parse HEAD)" == "$revision" ]] &&
           _sc_plugins_clean "$previous" 2>/dev/null; then
            cp -R "$previous/." "$staged/"
        else
            git -C "$staged" init --quiet
            git -C "$staged" remote add origin "https://github.com/$repository.git"
            git -C "$staged" fetch --quiet --depth=1 origin "$revision"
            git -C "$staged" checkout --quiet --detach "$revision"
        fi
        mv "$staged" "$target"
        staged=''
        changed=1
    fi
    print -r -- "$name $revision"
done
print 'Plugins match the manifest. Start a new shell to load them.'
