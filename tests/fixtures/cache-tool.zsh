#!/usr/bin/env zsh
print -r -- called >> "$SC_TEST_CALLS"
case "$1" in
    fail) print -u2 'Expected generation failure'; exit 7 ;;
    malformed) print 'if then'; exit 0 ;;
    empty) exit 0 ;;
    *) print -r -- "export SC_CACHE_VALUE=${(q)1}" ;;
esac
