# shellcheck shell=zsh
# Zsh Options
# -----------

# ---------------------
# History
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
# Completion Styling
# ---------------------
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select  # Enable arrow-key driven menu selection
