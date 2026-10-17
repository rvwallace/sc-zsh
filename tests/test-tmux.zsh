#!/usr/bin/env zsh
emulate -LR zsh
setopt err_exit pipe_fail
local root="${0:A:h:h}"
local tmp_root=${TMPDIR:-/tmp}
tmp_root=${tmp_root%/}
local test_dir
test_dir=$(mktemp -d "$tmp_root/sc-zsh-tmux.XXXXXX") || exit 1
local socket="$test_dir/socket"
trap 'tmux -S "$socket" kill-server 2>/dev/null || true; [[ -n "$test_dir" && "$test_dir" == "$tmp_root"/sc-zsh-tmux.* ]] && rm -rf -- "$test_dir"' EXIT
local -a launch=(env -u FPATH -u TOOLBOX_LOADED -u ZPFX -u FAST_WORK_DIR)
if [[ "${1:-}" != --personal ]]; then
    launch+=("HOME=$test_dir" "XDG_CACHE_HOME=$test_dir/cache" "XDG_CONFIG_HOME=$test_dir/config")
fi
launch+=("SC_PLUGIN_DIR=${SC_PLUGIN_DIR:-$HOME/.local/share/sc-zsh/plugins}" "ZDOTDIR=$root" zsh -li)
SHELL="${commands[zsh]}" tmux -S "$socket" -f "$root/tests/fixtures/tmux.conf" new-session -d -s sc-test -x 160 -y 40 -c "$test_dir" "${launch[@]}"
local pane='%0' output i
for i in {1..100}; do
    output=$(tmux -S "$socket" capture-pane -p -t "$pane")
    [[ "$output" == *'CMD>'* || "$output" == *'❯'* ]] && break
    sleep 0.05
done
[[ "$output" == *'CMD>'* || "$output" == *'❯'* ]] || { print -u2 'No prompt in isolated tmux pane'; exit 1; }
tmux -S "$socket" send-keys -l -t "$pane" ' [[ $TERM == tmux-256color && $(whence -w cd) == "cd: builtin" ]] && (( $+functions[_fzf_complete] && $+functions[enable-fzf-tab] && $+functions[z] && $+functions[_zsh_highlight] )) && [[ $(bindkey ^O) == *edit-command-line* ]] && print SC_TMUX_OK'
tmux -S "$socket" send-keys -t "$pane" Enter
for i in {1..100}; do
    output=$(tmux -S "$socket" capture-pane -p -t "$pane")
    [[ "$output" == *$'\nSC_TMUX_OK\n'* ]] && break
    sleep 0.05
done
[[ "$output" == *$'\nSC_TMUX_OK\n'* ]] || { print -u2 'tmux feature check failed'; exit 1; }
if [[ "${1:-}" == --personal ]]; then
    tmux -S "$socket" send-keys -l -t "$pane" ' [[ $TOOLBOX_LOADED == 1 && $+functions[terraform.plan.save] == 1 ]] && print SC_TOOLBOX_OK'
    tmux -S "$socket" send-keys -t "$pane" Enter
    for i in {1..100}; do
        output=$(tmux -S "$socket" capture-pane -p -t "$pane")
        [[ "$output" == *$'\nSC_TOOLBOX_OK\n'* ]] && break
        sleep 0.05
    done
    [[ "$output" == *$'\nSC_TOOLBOX_OK\n'* ]] || { print -u2 'Toolbox check failed'; exit 1; }
fi
print 'PASS: isolated tmux prompt, TERM, immediate features, and Ctrl-O binding'
