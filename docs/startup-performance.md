# Startup measurements: 2026-10-12

Measurements use Apple Silicon, macOS 27.0.1, Zsh 5.9.2, Starship 1.26.0, FZF 0.74.5, Carapace 1.8.0, and Zoxide 0.10.0.

The baseline is commit `f28aff7`. Each warm result uses five samples after a separate first run. Both configurations include macOS system startup files. PTYs use `tmux-256color`. The working directory is an empty temporary directory.

## Personal configuration

These runs use the active home pre/post files, the existing Starship configuration, installed plugins, and Toolbox.

| Measurement | Baseline median / p95 | New median / p95 |
| --- | --- | --- |
| Non-login first prompt | 95.9 / 97.6 ms | 220.3 / 224.5 ms |
| Non-login feature confirmation | 1915.7 / 2041.4 ms | 248.7 / 253.4 ms |
| Non-login following prompt | 22.6 / 22.9 ms | 20.5 / 21.4 ms |
| Login first prompt | 98.2 / 100.6 ms | 218.1 / 222.2 ms |
| Login feature confirmation | 1999.2 / 2043.4 ms | 245.1 / 248.4 ms |
| Login following prompt | 23.0 / 24.1 ms | 20.3 / 21.0 ms |

The old configuration displayed its prompt before delayed integrations and Toolbox loaded. The new configuration loads those features before displaying the prompt. Feature confirmation includes a test command and its next prompt, so it is an upper bound on readiness.

The confirmation time decreased by about 87 percent. The first visible prompt takes longer because personal configuration now runs synchronously. Subsequent prompt latency remains about 20 ms.

## Core configuration and cold caches

Core measurements use a temporary home without personal pre/post configuration. They include Starship's default prompt, integrations, plugins, and system startup files.

| Measurement | Median / p95 |
| --- | --- |
| Non-login first prompt | 100.3 / 103.7 ms |
| Login first prompt | 100.8 / 104.5 ms |
| Non-login feature confirmation | 127.6 / 132.3 ms |
| Login feature confirmation | 127.1 / 131.7 ms |

A fresh core cache took 594.1 ms to display its first prompt. A fresh personal cache took 996.2 ms. Cold startup includes integration generation, completion audit/rebuild, and cache compilation. It does not download plugins.

The warm core is close to the 100 ms target. The 50 ms stretch target was not reached. These results depend on the machine, prompt configuration, working directory, installed tools, and personal modules.

## Reproduction and checks

```zsh
zsh tests/test-startup.zsh --benchmark --system-rc --samples 5
zsh tests/test-startup.zsh --benchmark --personal --system-rc --samples 5
zsh tests/test-startup.zsh --benchmark --baseline /absolute/path/to/baseline --personal --system-rc --samples 5
zsh tests/test-startup.zsh
zsh tests/test-cache.zsh
zsh tests/test-tmux.zsh --personal
```

The functional tests check immediate feature availability, actual Ctrl-O editing, FZF `**<Tab>`, highlighting, native navigation, custom completion precedence, compiled dump reuse, missing-plugin fallback, and dummy environment-variable SSH arguments.

Cache tests cover executable and argument changes, failed or malformed output, concurrent generation, and read-only fallback. The isolated tmux test checks the active prompt, terminal capabilities, widgets, and Toolbox availability.

History settings remain unchanged. Tmux's 100,000-line scrollback is separate from Zsh's 10,000 command entries. These measurements preceded the later installation of coreutils, GNU sed, and GNU tar. The built-in GNU integration maps installed prefixed binaries and does not install packages.
