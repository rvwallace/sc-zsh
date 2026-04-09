# shellcheck shell=zsh
# Zsh Options
# -----------

# ---------------------
# 1. History
# ---------------------
HISTSIZE=10000
HISTFILE="$HOME/.zsh_history"
# shellcheck disable=SC2034  # Used by Zsh history system
SAVEHIST=$HISTSIZE
# shellcheck disable=SC2034  # Used by Zsh history system
HISTDUP=erase
# Set restrictive permissions on history file (atomic umask approach prevents TOCTOU)
if [[ ! -f "$HISTFILE" ]]; then (umask 077; touch "$HISTFILE"); fi
setopt extendedhistory          # Save timestamp of command
setopt appendhistory            # Append history to the history file
setopt sharehistory             # Share history between all sessions
setopt hist_ignore_space        # Ignore commands that start with a space
setopt hist_ignore_all_dups     # Delete old recorded duplicates
setopt hist_save_no_dups        # Do not save duplicates
setopt hist_ignore_dups         # Ignore duplicates
setopt hist_find_no_dups        # Do not display duplicates
setopt hist_expire_dups_first   # Expire duplicates first when trimming history

# ---------------------
# 2. Directory Stack
# ---------------------
# Automatically push directories onto the stack
setopt AUTO_PUSHD           # Push directories onto stack
setopt PUSHD_SILENT         # Don't print directory stack
setopt PUSHD_TO_HOME        # Have pushd with no args act like 'pushd $HOME'
setopt PUSHD_IGNORE_DUPS    # Don't push duplicates

# Persistent directory stack across sessions
DIRSTACKFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/dirs"
if [[ -f "$DIRSTACKFILE" ]] && (( ${#dirstack} == 0 )); then
    dirstack=("${(@f)"$(< "$DIRSTACKFILE")"}")
    if [[ -d "${dirstack[1]}" ]]; then
        cd -- "${dirstack[1]}" || echo "[sc-zsh] Failed to restore directory: ${dirstack[1]}" >&2
    fi
fi

# Save directory stack on directory change
autoload -Uz add-zsh-hook
function _save_dirstack() {
    # Ensure cache directory exists
    mkdir -p "${DIRSTACKFILE:h}"
    print -l -- "$PWD" "${(u)dirstack[@]}" > "$DIRSTACKFILE"
}
add-zsh-hook chpwd _save_dirstack

# ---------------------
# 3. Completion Styling
# ---------------------
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select  # Enable arrow-key driven menu selection
