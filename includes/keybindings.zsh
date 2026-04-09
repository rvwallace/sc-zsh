# shellcheck shell=zsh
# Key Bindings
# ------------

if [[ ! -o interactive && "${SC_PROFILE:-}" != 1 ]]; then
    return
fi

# Terminfo-based key bindings for better portability
# Load terminfo module
zmodload zsh/terminfo

# Create associative array for key mappings
typeset -g -A key

key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[Backspace]="${terminfo[kbs]}"

# Bind terminfo keys
[[ -n "${key[Home]}" ]] && bindkey -- "${key[Home]}" beginning-of-line
[[ -n "${key[End]}" ]] && bindkey -- "${key[End]}" end-of-line
[[ -n "${key[Insert]}" ]] && bindkey -- "${key[Insert]}" overwrite-mode
[[ -n "${key[Delete]}" ]] && bindkey -- "${key[Delete]}" delete-char
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}" backward-delete-char
[[ -n "${key[PageUp]}" ]] && bindkey -- "${key[PageUp]}" beginning-of-buffer-or-history
[[ -n "${key[PageDown]}" ]] && bindkey -- "${key[PageDown]}" end-of-buffer-or-history

# Standard Control-key bindings (not terminal-dependent)
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# -----------------
# ZLE Widgets
# -----------------

# Editor Integration (Edit command line in EDITOR)
# only wire up keybinds and zle widgets when the line editor is around (or when profiling)
autoload -Uz edit-command-line; zle -N edit-command-line
# Bind to both emacs and viins to ensure functionality regardless of zinit-loaded vi-mode status
bindkey -M emacs '\C-x\C-e' edit-command-line
bindkey -M viins '\C-x\C-e' edit-command-line

# Sudo Toggle
# Toggles 'sudo ' at the start of the current command line
sudo-command-line() {
    if [[ -z $BUFFER ]]; then
        zle up-history
    fi
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    elif [[ $BUFFER == sudo ]]; then
        LBUFFER=""
    else
        LBUFFER="sudo $LBUFFER"
    fi
    zle redisplay
}
zle -N sudo-command-line
# Bind to Esc-Esc (Double Escape)
bindkey -M emacs '\e\e' sudo-command-line
bindkey -M viins '\e\e' sudo-command-line

# Cmux Integrations
if [[ -n "$CMUX_WORKSPACE_ID" ]]; then

    # Open current pane scrollback in $EDITOR
    # Bind: ^Xv (Ctrl-X, v)
    _cmux_pane_to_editor() {
        local tmpfile
        tmpfile=$(mktemp /tmp/cmux-pane-XXXXXX.txt)
        cmux capture-pane --scrollback | sed 's/[[:space:]]*$//' | sed '/./,$!d' > "$tmpfile"
        zle -I
        $EDITOR "$tmpfile"
        rm -f "$tmpfile"
    }
    zle -N _cmux_pane_to_editor
    bindkey -M emacs "^Xv" _cmux_pane_to_editor
    bindkey -M viins "^Xv" _cmux_pane_to_editor

    # Flash current pane border (visual "where am I" marker)
    # Bind: ^Xf (Ctrl-X, f)
    _cmux_flash() {
        cmux trigger-flash &>/dev/null
        zle reset-prompt
    }
    zle -N _cmux_flash
    bindkey -M emacs "^Xf" _cmux_flash
    bindkey -M viins "^Xf" _cmux_flash

fi

# Tmux Popup Toggle
# Toggles wrapping the command to run in a tmux display-popup
# Note: For multi-statement commands (cmd1; cmd2), the toggle wraps everything.
#       For standalone tp function, quote multi-commands: tp 'cmd1; cmd2'
# Bind: ^Xp (Ctrl-X, p)
if (( $+commands[tmux] )); then
    _tmux_popup_toggle() {
        if [[ -z $BUFFER ]]; then
            zle up-history
        fi

        local popup_prefix="tmux display-popup -- "

        if [[ $BUFFER == ${popup_prefix}* ]]; then
            # Remove popup wrapper
            BUFFER="${BUFFER#${popup_prefix}}"
        elif [[ $BUFFER == "tmux display-popup"* ]]; then
            # Handle variations (e.g., user added flags manually)
            zle -M "Complex popup command - edit manually"
        else
            # Add popup wrapper
            BUFFER="${popup_prefix}${BUFFER}"
        fi
        zle redisplay
    }
    zle -N _tmux_popup_toggle
    bindkey -M emacs "^Xp" _tmux_popup_toggle
    bindkey -M viins "^Xp" _tmux_popup_toggle
fi

# -----------------
# Utility Widgets
# -----------------


# Quick LS
# Runs 'ls -F' on current directory while keeping the current prompt\command line
# Bind: ^Xl (Ctrl-X, l)
_quick_ls() {
    zle -I
    # Use standard ls with colors and indicators
    if [[ "$OSTYPE" == "darwin"* ]]; then
        command ls -GF
    else
        command ls --color=auto -F
    fi
}
zle -N _quick_ls
bindkey -M emacs "^Xl" _quick_ls
bindkey -M viins "^Xl" _quick_ls

# Quick Git Status
# Runs 'git status -sb' below the current prompt
# Bind: ^Xg (Ctrl-X, g)
_quick_git_status() {
    # Check if we are in a git repo to avoid ugliness
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        zle -I
        git status -sb
    else
        zle -M "Not a git repository"
    fi
}
zle -N _quick_git_status
bindkey -M emacs "^Xg" _quick_git_status
bindkey -M viins "^Xg" _quick_git_status

# Copy Buffer to Clipboard
# Copies the current command line to the system clipboard
# Bind: ^Xc (Ctrl-X, c)
_copy_buffer() {
    if [[ -z "$BUFFER" ]]; then
        zle -M "Buffer empty"
        return
    fi
    local clipboard_cmd=""
    local msg=""
    
    if (( $+commands[pbcopy] )); then
        clipboard_cmd="pbcopy"
        msg="Copied to clipboard (pbcopy)"
    elif (( $+commands[wl-copy] )); then
        clipboard_cmd="wl-copy"
        msg="Copied to clipboard (wl-copy)"
    elif (( $+commands[xclip] )); then
        clipboard_cmd="xclip -selection clipboard"
        msg="Copied to clipboard (xclip)"
    fi

    if [[ -n "$clipboard_cmd" ]]; then
        print -rn -- "$BUFFER" | $clipboard_cmd
        zle -I
        print -P "%F{green}✔ $msg%f"
    else
        zle -M "Clipboard utility (pbcopy/wl-copy/xclip) not found"
    fi
}
zle -N _copy_buffer
bindkey -M emacs "^X\\" _copy_buffer
bindkey -M viins "^X\\" _copy_buffer

