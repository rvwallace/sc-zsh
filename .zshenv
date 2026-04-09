# Resolve this file's directory, even through symlinks
__zroot=${${(%):-%N}:A:h}
export ZDOTDIR="$__zroot"
unset __zroot

# Load local env vars (API keys, tokens, exports) for all shells including non-interactive
[[ -f $HOME/.zshrc.local.pre ]] && source $HOME/.zshrc.local.pre

