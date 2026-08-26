# shellcheck shell=zsh

# ------------------------------------------------------------------------------
# Core & File System
# ------------------------------------------------------------------------------
alias rm='rm -i'                                       # Interactive removal
alias grep='grep --color=auto'                         # Colored grep output
alias less='less -FSRXc'                               # Enhanced less defaults
alias truncate=': >'                                   # Truncate file to 0 size
alias bat='bat --theme="Dracula" --italic-text=always --paging=always --color=always'

# Listing & Navigation
# --------------------
alias ll='ls -l'                                       # Long format
alias la='ls -la'                                      # Show hidden files
alias ppath='echo -e ${PATH//:/\\n}'                   # PATH entries

# Eza (if installed)
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first --hyperlink'
    alias lt='ls --tree'
    alias lg='ll --git --git-repos'
fi

# ------------------------------------------------------------------------------
# Network & Connectivity
# ------------------------------------------------------------------------------
alias ip.if="netstat -nr | grep '^default' | grep -v 'fe80' | head -n1 | awk '{print \$NF}'"
alias ip.gw="netstat -nr | grep '^default' | grep -v 'fe80' | head -n1 | awk '{print \$2}'"
alias ip.lan='ifconfig | grep -E "inet (addr:)?" | grep -v "127.0.0.1" | awk "{print \$2}"'
alias ip.wan='dig +short myip.opendns.com @resolver1.opendns.com || echo "Failed to fetch IP"; echo'

# HTTP & Downloads
alias wget='wget -c'                                   # Resume downloads
alias http.chk='curl -o /dev/null -s -w "%{http_code}\n"' # Status code
alias http.time='curl -o /dev/null -s -w "DNS: %{time_namelookup} \nConnect: %{time_connect} \nPre-transfer: %{time_pretransfer} \nStart Transfer: %{time_starttransfer} \nTotal Time: %{time_total} \n"'

# ------------------------------------------------------------------------------
# System & Monitoring
# ------------------------------------------------------------------------------
alias font.list='fc-list'                              # All fonts
alias font.list.family='fc-list : family'              # Font families

# ------------------------------------------------------------------------------
# Development
# ------------------------------------------------------------------------------

# Python
alias python='python3'
alias pip='python3 -m pip'
alias activate='source ./.venv/bin/activate'
alias ipy='python3 -m IPython'
alias uv.exp='uv export --format requirements-txt --no-hashes --output-file requirements.txt --quiet'

# Homebrew
alias brew.bundle="brew bundle dump --global --force"

# ------------------------------------------------------------------------------
# MacOS Specific
# ------------------------------------------------------------------------------
if [[ "$(uname)" == "Darwin" ]]; then
    alias top='top -R -F -s 5'                             # Enhanced display (macOS)
    alias dns='scutil --dns'
    alias ip.info='scutil --nwi'
fi
