# Changelog
 
This file documents all notable changes to the `sc-zsh` configuration.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### 2026-09-03

- Added OpenCode binary path (`~/.opencode/bin`) to `includes/paths.zsh` via `_path_prepend`

### 2026-08-28

- Updated documentation in [README.md](file:///home/rwallace/silentcastle/projects/sc-zsh/README.md) and [AGENTS.md](file:///home/rwallace/silentcastle/projects/sc-zsh/AGENTS.md) to replace obsolete `zinit list` subcommand with `zinit plugins` and `zinit snippets`

### 2026-08-27

- Removed `--hyperlink` flag from `eza` alias in `includes/aliases.zsh` due to an upstream parser issue in `ansi-to-tui` (used by `tmux-snaglord`), where OSC 8 hyperlink sequences terminated by `ST` (`\x1b\`) cause subsequent filenames in directory listings to be swallowed and omitted from TUI rendering

### 2026-08-25

- Removed stale `ENABLE_GNU_SED`/`ENABLE_GNU_TAR` entries from the `README.md` Configuration Variables reference (unused since the OMZ `gnu-utils` plugin took over; not defined anywhere in code)
- Removed inert untracked `.zprofile` (contained only a commented-out `rbenv init` line; not part of version control)
- Removed 21 unused aliases from `includes/aliases.zsh` (`batcat`, `cat.img`, `find.big`, `tar.gz`, `tar.xz`, `tar.ungz`, `tar.unxz`, `lsof.listen`, `lsof.ports`, `term.reset`, `term.sane`, `timestamp`, `datestamp`, `now`, `nowdate`, `venv`, `top.mem` (both branches), `wifi.password.current`, `wifi.password.find`, `finder.files.show`, `finder.files.hide`) after checking 22 months of `.zsh_history` showed zero usage; kept `truncate` and `uv.exp` at user request despite zero recorded use
- Removed now-empty "Archive & Compression" and "Time & Date" alias section headers and the dead Linux `else` branch in the MacOS Specific alias block

### 2026-08-22

- Removed `MichaelAquilina/zsh-you-should-use` plugin from `includes/plugins.zsh` and cleaned up startup error filter in tests
- Removed OMZ git plugin snippet (`OMZ::plugins/git/git.plugin.zsh`) from `includes/plugins.zsh`
- Migrated `cmux` and `tmux` ZLE keybindings from `includes/keybindings.zsh` to `toolbox/shell/modules/{cmux,tmux}.zsh`
- Migrated AWS token TTL prompt caching from `includes/app_integrations.zsh` to `toolbox/shell/modules/aws.zsh`
- Migrated Ansible `uv` aliases from `includes/aliases.zsh` to `toolbox/shell/modules/ansible.sh`
- Removed dead `scripts/completions` fpath check and hardcoded bun completions from `.zshrc`
- Removed redundant completion directory creation from `includes/plugins.zsh`
- Updated integration test suite in `tests/test-startup.zsh` to verify `ql` and `rm.dstore`
- Moved documentation from `docs/README.md` to root `README.md` and extracted Change Log to `CHANGELOG.md`
- Updated documentation to reference [toolbox](https://github.com/rvwallace/toolbox) and the `.zshrc.local.post` integration
- Moved `.zcompdump` completion cache from `$ZDOTDIR/.zcompdump` to `~/.cache/zsh/zcompdump` via `zicompinit -d`
- Defined `ZSH_CACHE_DIR` (`${XDG_CACHE_HOME:-$HOME/.cache}/zsh`) in `includes/defaults.zsh`

### 2026-08-20

- Removed git flags (`--git`, `--git-repos`) from default `ls` alias in `includes/aliases.zsh` to prevent latency in directories with many git repositories
- Added `lg` alias (`ll --git --git-repos`) in `includes/aliases.zsh` for on-demand git status listings
- Fixed terminal suspension (`SIGTTIN`/`SIGTTOU`) by guarding `ttyctl -f` in `.zshrc` to interactive terminals and disabling job control (`+m </dev/null`) during subshell integration tests

### 2026-08-19

- Removed redundant `OMZP::eza` snippet from `includes/plugins.zsh` to prevent deferred loading from overwriting custom `eza` aliases
- Added `--git-repos` flag to `eza` alias in `includes/aliases.zsh` to show repository status on directory listings

### 2026-08-11

- Staggered deferred Zinit jobs to prevent plugins, app integrations, and local customizations from blocking ZLE at the same one-second boundary
- Prevented deferred `atload` callbacks from temporarily changing the shell directory while tmux may inspect the pane path
- Removed toolbox redundant completion initialization while preserving its deferred `compdef` registrations
- Applied fzf-tab preview styles when the deferred plugin loads instead of checking for it before it is available

### 2026-06-08

- Documented Starship `SC_AWS_TOKEN_TTL` configuration and cache behavior
- Removed stale Shell-GPT app integration documentation
- Added cached AWS token TTL prompt variable refreshed from Zsh instead of running the token helper on every Starship render
- Changed feature flags in `includes/defaults.zsh` to preserve existing environment overrides
- Loaded `zsh-history-substring-search` before `fast-syntax-highlighting` so history widgets exist before highlighter widget binding
- Filtered evalcache cache-miss notices from startup while preserving other stderr output
- Swapped `zsh-users/zsh-syntax-highlighting` for `zdharma-continuum/fast-syntax-highlighting`
- Added `mroth/evalcache` and routed generated app init output through `_evalcache` where available
- Bound terminfo-derived Up/Down arrow sequences to `zsh-history-substring-search` widgets for portable history search behavior

### 2026-05-22

- Removed Terraform aliases from `includes/aliases.zsh` (now in `toolbox/shell/modules/terraform.sh`, MR helpers in `docs/terraform.md`)
- Consolidated `tfswitch` chpwd hook under toolbox `terraform` stem (`terraform.zsh` / `terraform.bash`, retired `tfswitch.zsh`)

### 2026-04-22

- Removed directory stack persistence setup and hooks from `includes/options.zsh`

### 2026-04-09

- Added a short README setup section covering the `~/.zshenv` symlink and `.zshrc.local.{pre,post}` example-file bootstrap flow
- Moved `.zshrc.local.pre` sourcing from `.zshrc` to `.zshenv` so API keys and exports reach all shells, including non-interactive shells
- Prepended `/opt/homebrew/opt/ruby/bin` to `PATH` for Homebrew Ruby precedence over macOS Ruby 2.6 (required by Mason for `rubocop`)
- Removed `docs/todo/` (code-review-report.md, tasks.json, progress.txt) after completing all Jan 2026 code review tasks
- Removed empty `lib/` directory

### 2026-04-02

- Migrated `lib/aws-regions.zsh` and `lib/aws-profiles-cache.zsh` + `aws.caller_identity` to `toolbox/shell/modules/aws.sh`
- Migrated zsh completions for `aws.env`, `chef.env`, `k.env` to `toolbox/shell/modules/{aws,chef,kube}.zsh`
- Migrated zmx shell functions to `toolbox/shell/modules/zmx.sh` + `zmx.zsh`
- Migrated `tfswitch` chpwd auto-switch hook to toolbox (`terraform.zsh`, later unified under `terraform` stem)
- Migrated `tp` tmux popup helper to `toolbox/shell/modules/tmux.sh` + `tmux.zsh`
- Migrated cmux zsh completions to `toolbox/shell/modules/cmux.zsh`
- Updated `aliases.zsh` and `defaults.zsh` to remove items migrated to toolbox

### 2026-04-01

- Migrated git helper functions (`git.ignore.add`, `git.cdroot`, `git.undo`, `git.commit-amend`, `git.branch-list`, `git.diff-staged`, `git.log-all`, `git.delete-merged-branches`, `git.stats`) to `toolbox/shell/modules/git.sh`
- Migrated aichat ZLE widget (Alt-e) to `toolbox/shell/modules/ai.zsh`

### 2026-03-27

- Migrated zmx keybindings (Alt-a attach, Alt-d detach) from `includes/keybindings.zsh` to `toolbox/shell/modules/zmx.zsh`
- Removed Shell-GPT / aichat widget from `includes/app_integrations.zsh` (migrated to toolbox)

### 2026-03-18

- Extracted `claude.monitor` alias to `toolbox/shell/modules/ai.sh`
- Extracted network functions and aliases to `toolbox/shell/modules/net.sh`

### 2026-02-14

- Refined `plugins.zsh`: improved zinit dependency guard with explicit error message if `plugins.zsh` was not sourced before `app_integrations.zsh` (ARCH-001)

### 2026-01-24

- Added integration test suite (`tests/test-startup.zsh`) covering startup time, error-free load, function availability, PATH, and ZDOTDIR (TEST-001)
- Fixed history file TOCTOU race condition in `options.zsh`: replaced `touch + chmod` with atomic `(umask 077; touch)` (SEC-003)
- Fixed silent `cd` failure on directory stack restore in `options.zsh`: now logs error to stderr on failure (BUG-002)
- Added `# shellcheck shell=zsh` directives to `exports.zsh`, `options.zsh`, `paths.zsh` (SEC-002)
- Added `# shellcheck disable=SC2296` annotation to `paths.zsh` for valid Zsh join syntax (BUG-001)
- Added code review report to `docs/todo/code-review-report.md`

### 2025-12-15

- Simplified completion strategy using Carapace as primary handler
- Removed `includes/completions.zsh` (Carapace handles most tools)
- Reduced OMZ plugins from 13 to 5 (kept: git, eza, extract, gitignore, gnu-utils)
- Removed OMZ plugins now handled by Carapace: gh, chezmoi, k9s, knife, knife_ssh, systemadmin, tailscale, terraform
- Updated documentation to emphasize Carapace-first completion approach
- Simplified architecture by relying on Carapace completion engine

### 2025-12-14

- Initial consolidated documentation
- Added Zinit optimizations (0.9s → 0.17s startup)
- Added terminfo keybindings
- Added directory stack feature
- Added completion menu select
- Added terminal stability (ttyctl -f)
- Added zsh-you-should-use plugin
- Established architecture and decision log
