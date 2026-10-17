#!/usr/bin/env zsh
emulate -LR zsh
setopt err_exit pipe_fail
unsetopt bg_nice
local root="${0:A:h:h}"
local tmp_root=${TMPDIR:-/tmp}
tmp_root=${tmp_root%/}
local test_dir
test_dir=$(mktemp -d "$tmp_root/sc-zsh-cache.XXXXXX") || exit 1
trap '[[ -n "$test_dir" && "$test_dir" == "$tmp_root"/sc-zsh-cache.* ]] && chmod -R u+w "$test_dir" && rm -rf -- "$test_dir"' EXIT
export SC_TEST_CALLS="$test_dir/calls"
export ZSH_CACHE_DIR="$test_dir/cache"
mkdir -p "$ZSH_CACHE_DIR" "$test_dir/bin"
cp "$root/tests/fixtures/cache-tool.zsh" "$test_dir/bin/cache-tool"
chmod +x "$test_dir/bin/cache-tool"
path=("$test_dir/bin" $path)
source "$root/includes/cache.zsh"
calls() { local -a lines=("${(@f)$(<"$SC_TEST_CALLS")}"); print $#lines; }
check() { [[ "$1" == "$2" ]] || { print -u2 -- "FAIL: $3 ($1 != $2)"; exit 1; }; }

_sc_evalcache cache-tool first
check "$SC_CACHE_VALUE" first 'initial generation'
_sc_evalcache cache-tool first
check "$(calls)" 1 'cache reuse'
_sc_evalcache cache-tool second
check "$SC_CACHE_VALUE" second 'argument invalidation'
CARAPACE_BRIDGES=test _sc_evalcache cache-tool second
check "$(calls)" 3 'setting invalidation'
cp "$test_dir/bin/cache-tool" "$test_dir/bin/replacement"
mv "$test_dir/bin/replacement" "$test_dir/bin/cache-tool"
rehash
_sc_evalcache cache-tool second
check "$(calls)" 4 'executable replacement'
if _sc_evalcache cache-tool fail 2>/dev/null; then print -u2 'FAIL: failed generator accepted'; exit 1; fi
if _sc_evalcache cache-tool malformed 2>/dev/null; then print -u2 'FAIL: malformed output accepted'; exit 1; fi
_sc_evalcache cache-tool first
check "$SC_CACHE_VALUE" first 'working cache after failure'
chmod u-w "$ZSH_CACHE_DIR"
_sc_evalcache cache-tool readonly
check "$SC_CACHE_VALUE" readonly 'read-only cache fallback'
if _sc_evalcache cache-tool malformed 2>/dev/null; then print -u2 'FAIL: read-only cache accepted malformed output'; exit 1; fi
chmod u+w "$ZSH_CACHE_DIR"
for i in {1..8}; do
    ZSH_CACHE_DIR="$ZSH_CACHE_DIR" zsh -dfc 'source "$1/includes/cache.zsh"; _sc_evalcache cache-tool concurrent; [[ $SC_CACHE_VALUE == concurrent ]]' -- "$root" &
done
wait
_sc_evalcache cache-tool concurrent
check "$SC_CACHE_VALUE" concurrent 'concurrent generation'
for file in "$ZSH_CACHE_DIR"/*.zsh(N); do zsh -dfn "$file"; done

for name in gsed gdate gwhoami gmake gprintf; do
    cp "$root/tests/fixtures/gnu-tool.zsh" "$test_dir/bin/$name"
    chmod +x "$test_dir/bin/$name"
done
rehash
source "$root/includes/gnu_utils.zsh"
check "$(command sed sample)" $'gsed\nsample' 'GNU sed mapping'
check "$(command date)" gdate 'GNU date mapping'
check "$(whence -w printf)" 'printf: builtin' 'built-in preservation'
rehash
_sc_gnu_preexec
check "$(command sed sample)" $'gsed\nsample' 'GNU mapping after rehash'
ZDOTDIR="$root" zsh -dfi +m -c 'path=(); source "$ZDOTDIR/includes/cache.zsh"; source "$ZDOTDIR/includes/app_integrations.zsh"; [[ $+functions[_fzf_complete] == 0 && $+functions[z] == 0 ]]' </dev/null
print 'PASS: cache reuse, invalidation, failure, read-only fallback, concurrency, and GNU mappings'
