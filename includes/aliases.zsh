# shellcheck shell=zsh

# ------------------------------------------------------------------------------
# Core & File System
# ------------------------------------------------------------------------------
# [[ "${ENABLE_GNU_SED:-false}" == "true" ]] && alias sed='gsed' # Should be handled by gnu-utils plugin
alias rm='rm -i'                                       # Interactive removal
alias grep='grep --color=auto'                         # Colored grep output
alias less='less -FSRXc'                               # Enhanced less defaults
alias truncate=': >'                                   # Truncate file to 0 size
alias bat='bat --theme="Dracula" --italic-text=always --paging=always --color=always'
alias batcat='batcat --theme="Dracula" --italic-text=always --paging=always --color=always'
alias cat.img='kitty +kitten icat'

# Listing & Navigation
# --------------------
alias ll='ls -l'                                       # Long format
alias la='ls -la'                                      # Show hidden files
alias ppath='echo -e ${PATH//:/\\n}'                   # PATH entries
alias find.big='find . -type f -size +100M'            # Large files

# Eza (if installed)
if command -v eza &> /dev/null; then
    alias ls='eza --icons --git --group-directories-first --hyperlink'
    alias lt='ls --tree'
fi

# Archive & Compression
# ---------------------
# [[ "${ENABLE_GNU_TAR:-false}" == "true" ]] && alias tar='gtar' # Should be handled by gnu-utils plugin
alias tar.gz='tar -czvf'                               # Create tar.gz archive
alias tar.xz='tar -cJvf'                               # Create tar.xz archive
alias tar.ungz='tar -xzvf'                             # Extract tar.gz archive
alias tar.unxz='tar -xJvf'                             # Extract tar.xz archive

# ------------------------------------------------------------------------------
# Network & Connectivity
# ------------------------------------------------------------------------------
alias ip.if="netstat -nr | grep '^default' | grep -v 'fe80' | head -n1 | awk '{print \$NF}'"
alias ip.gw="netstat -nr | grep '^default' | grep -v 'fe80' | head -n1 | awk '{print \$2}'"
alias ip.lan='ifconfig | grep -E "inet (addr:)?" | grep -v "127.0.0.1" | awk "{print \$2}"'
alias ip.wan='dig +short myip.opendns.com @resolver1.opendns.com || echo "Failed to fetch IP"; echo'
alias lsof.listen='sudo lsof -iTCP -sTCP:LISTEN -n -P'
alias lsof.ports='lsof -i'

# HTTP & Downloads
alias wget='wget -c'                                   # Resume downloads
alias http.chk='curl -o /dev/null -s -w "%{http_code}\n"' # Status code
alias http.time='curl -o /dev/null -s -w "DNS: %{time_namelookup} \nConnect: %{time_connect} \nPre-transfer: %{time_pretransfer} \nStart Transfer: %{time_starttransfer} \nTotal Time: %{time_total} \n"'

# ------------------------------------------------------------------------------
# System & Monitoring
# ------------------------------------------------------------------------------
alias term.reset='echo -e "\033c"'                     # Full reset
alias term.sane='stty sane'                            # Sane defaults
alias font.list='fc-list'                              # All fonts
alias font.list.family='fc-list : family'              # Font families

# ------------------------------------------------------------------------------
# Time & Date
# ------------------------------------------------------------------------------
alias timestamp='date "+%Y%m%dT%H%M%S"'                # YYYYMMDDThhmmss
alias datestamp='date "+%Y%m%d"'                       # YYYYMMDD
alias now='date +"%T"'                                 # HH:MM:SS
alias nowdate='date +"%d-%m-%Y"'                       # DD-MM-YYYY

# ------------------------------------------------------------------------------
# Development
# ------------------------------------------------------------------------------

# Python
alias python='python3'
alias pip='python3 -m pip'
alias venv='python3 -m venv'
alias activate='source ./.venv/bin/activate'
alias ipy='python3 -m IPython'
alias uv.exp='uv export --format requirements-txt --no-hashes --output-file requirements.txt --quiet'

# Ansible
# Run via uv to ensure isolated, reproducible environments and no messy global deps
alias ansible='uv run --with ansible-core ansible'
alias ansible-playbook='uv run --with ansible-core ansible-playbook'
alias ansible-vault='uv run --with ansible-core ansible-vault'
alias ansible-galaxy='uv run --with ansible-core ansible-galaxy'
alias ansible-lint='uv run --with ansible-lint ansible-lint'

# Terraform
alias tf='terraform'
alias tf.plan='tf plan -out=tfplan'
alias tf.apply='tf apply tfplan'
alias tf.destroy.plan='tf plan -destroy -out=tfplan'
alias tfswitch='tfswitch -b ~/.local/bin/terraform'


# Homebrew
alias brew.bundle="brew bundle dump --global --force"

# ------------------------------------------------------------------------------
# MacOS Specific
# ------------------------------------------------------------------------------
if [[ "$(uname)" == "Darwin" ]]; then
    alias top='top -R -F -s 5'                             # Enhanced display (macOS)
    alias top.mem='top -o mem'                             # Sort by memory (macOS)
    alias dns='scutil --dns'
    alias ip.info='scutil --nwi'
    alias wifi.password.current='security find-generic-password -ga `networksetup -getairportnetwork en0 | cut -d ":" -f 2 | tr -d " "` 2>&1 | grep "password:" | cut -d "\"" -f 2'
    alias wifi.password.find='security find-generic-password -wa'
    alias finder.files.show='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
    alias finder.files.hide='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
else
    # Linux-specific top aliases
    alias top.mem='top -o %MEM'                            # Sort by memory (Linux)
fi
