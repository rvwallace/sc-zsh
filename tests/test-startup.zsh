#!/usr/bin/env zsh
emulate -LR zsh
exec uv run --script "${0:A:h}/test-startup.py" "$@"
