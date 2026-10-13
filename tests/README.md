# sc-zsh Tests

Requirements: Zsh 5.9 or later, uv, and installed sc-zsh plugins. Install plugins with `zsh scripts/plugins.zsh install` first.

The startup wrapper uses `uv run --script`. Inline metadata declares Python 3.9 or later and no third-party dependencies.

## Functional tests

```zsh
zsh tests/test-startup.zsh
zsh tests/test-cache.zsh
uv run --script tests/test-setup.py
zsh tests/test-tmux.zsh
zsh tests/test-tmux.zsh --personal
```

The startup test opens a real pseudo-terminal with a temporary home. It tests feature availability at the first prompt, completion widgets, highlighting, Ctrl-O editing, FZF `**<Tab>`, native `cd`, Zoxide, history settings, PATH initialization, and dummy SSH arguments. Noninteractive shells must not load interactive completion.

The cache test uses mock commands in a temporary directory. It tests cache reuse, executable replacement, argument and setting changes, failed and malformed output, concurrent generation, and read-only fallback. It also tests GNU mappings and built-in preservation after `rehash`.

The tests do not delete personal history, caches, or plugin installations.

Setup tests use local Git repositories, temporary homes, and paths with spaces. They check fresh/offline setup, repeat runs, bootstrap backups, private file modes, custom directories, read-only doctor behavior, shallow pinned fetches, dirty plugins, partial failures, and temporary checkout cleanup. No GitHub download is needed.

The tmux test creates its own temporary server. It checks prompt rendering, terminal capabilities, feature readiness, and Ctrl-O. Personal mode also checks Toolbox. It does not change an existing tmux server.

## Benchmarks

```zsh
zsh tests/test-startup.zsh --benchmark --samples 10
zsh tests/test-startup.zsh --benchmark --personal --samples 10
zsh tests/test-startup.zsh --benchmark --personal --system-rc --samples 10
```

The benchmark reports median and p95 elapsed times for the first rendered prompt, feature confirmation, and a subsequent prompt. It tests login and non-login shells. Feature confirmation includes the test command and its next prompt, so it is an upper bound on readiness.

Default measurements skip system-wide rc files to isolate the repository. Add `--system-rc` to include `/etc/zshrc` and login setup. The tmux test includes those files.

The benchmark reports the first run separately, then collects warm samples. The first non-login run in a temporary home includes cold-cache work. Login runs share that cache. Personal runs use existing home caches and can refresh them. Do not publish environment-variable contents or terminal output from private configuration.

An optional `--baseline /absolute/path/to/old-checkout` compares an older configuration with the current one. Supply an `XDG_DATA_HOME` containing installed legacy plugins when testing a Zinit baseline with a temporary home. Never permit baseline startup to install dependencies as part of a benchmark.

Profile source and function costs separately:

```zsh
SC_PROFILE=1 zsh
```

Source timings include nested calls. Do not add them together to calculate elapsed startup time. The PTY benchmark measures process elapsed time instead.
