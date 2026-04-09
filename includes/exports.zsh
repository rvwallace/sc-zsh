# shellcheck shell=zsh
# Environment Variables
# ---------------------

export TERM=xterm-256color
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PAGER=less

# Set EDITOR to the first available editor
local editor
for editor in nvim hx vim vi nano; do
    if command -v "$editor" &> /dev/null; then
        export EDITOR="$editor"
        break
    fi
done
unset editor