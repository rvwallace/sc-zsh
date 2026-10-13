# AGENTS.md

## Repository and ownership

sc-zsh is a modular Zsh configuration. Keep personal configuration outside Git. Shared CLI tools and AWS, Git, and Terraform modules belong in Toolbox.

Every behavioral change needs an entry in `CHANGELOG.md` under today's `### YYYY-MM-DD` heading. Use the file modification date for backdated changes. Do not log formatting-only or typo changes.

`VERSION` records the configuration release version, starting at `0.1.0`. Keep pending entries under `Unreleased`. Version releases rather than individual commits. On an authorized release, add the version heading and release date, preserve dated subsections, and tag the committed release as `v<version>`. Plugin pins and cache formats have independent revisions.

## Startup contract

- `.zshenv` resolves the repository through its symlink and exports `ZDOTDIR`.
- It sources `~/.zshrc.local.pre` for all shells. This file can contain secrets. Do not display its contents.
- Interactive `.zshrc` loads defaults, function paths, PATH, exports, and the integration cache.
- `includes/plugins.zsh` initializes completion once and loads history substring search.
- Options, keybindings, app integrations, GNU mappings, aliases, and the active `~/.zshrc.local.post` load synchronously.
- fzf-tab loads after FZF and `compinit`. Autosuggestions and highlighting load after personal widgets.
- All retained core features must work at the first prompt. Do not introduce arbitrary timers or background installation.
- Preserve inherited terminal capabilities, including `TERM=tmux-256color`.
- Native `cd` must remain available. Zoxide supplies `z` and `zi`.
- Keep shell history and tmux scrollback settings separate. Preserve existing history behavior.

## Plugins and caches

Use `bash setup.sh` for repeatable installation and `bash doctor.sh` for read-only checks. Setup preserves personal files and backs up conflicting bootstrap links. Doctor must not source private configuration or generate caches. Honor exported custom paths in both commands.

For plugin additions, upgrades, and load-order changes, use [sc-zsh-plugins](skills/sc-zsh-plugins/SKILL.md). Read its instructions before editing the manifest or loader.

Plugin revisions live in `scripts/plugin-manifest.zsh`. Run `zsh scripts/plugins.zsh install|update` explicitly. Plugin checkouts live in `SC_PLUGIN_DIR`, outside the repository. Startup never downloads or updates plugins.

Keep the old Zinit installation for rollback. The current configuration does not load Zinit or OMZ snippets. GNU command mappings live in `includes/gnu_utils.zsh`.

The completion loader uses a versioned dump in `ZSH_CACHE_DIR`. It audits directories on rebuild, skips insecure directories, and reuses the dump for up to 24 hours. Changes to `fpath` or plugin maintenance invalidate it. Do not call `compinit` elsewhere.

`_sc_evalcache` and its `_evalcache` compatibility wrapper cache initialization output. Use executable metadata and generation settings for invalidation. Keep warm startup free of external hash and version commands. Use atomic writes. Failed generation must not replace working cache data.

## Code conventions

- Use underscore-prefixed global helpers for initialization, such as `_source` and `_path_prepend`.
- Use namespaced commands for user-facing functions.
- Built-in `functions/` and personal `~/.sc-zsh/functions/` files are discovered automatically. Use one autoload body per file.
- Add paired completion files under `completions/` or the personal completion directory.
- Keep manual PATH deduplication at the integration that changes PATH. Do not introduce global cleanup timers or `typeset -U path`.
- Preserve user aliases and Zsh built-ins when selecting GNU commands.
- Function errors use `return 1` and stderr. Sourced file errors use `return 1 2>/dev/null || exit 1` when direct execution also needs support.
- Guard interactive integrations and optional commands. A missing optional tool must not prevent shell startup.

## Tests and documentation

Use the `uv` skill for Python execution and dependency handling. Run standalone Python scripts with `uv run --script`. Declare repository script dependencies with PEP 723 inline metadata. For external helpers without metadata, supply dependencies through `--with` instead of editing those helpers or installing packages globally.

Run syntax checks for each changed shell file. Run `zsh tests/test-startup.zsh`, `zsh tests/test-cache.zsh`, `uv run --script tests/test-setup.py`, `zsh tests/test-tmux.zsh --personal`, and `git diff --check`.

Use the PTY benchmark for interactive readiness. Do not sum nested source timings or compare interactive startup with `nu -c`. Report cold-cache and warm-cache results separately. Include personal configuration and prompt rendering when claiming real terminal startup speed.

Test Ctrl-O, FZF `**<Tab>`, fzf-tab, history search, highlighting, suggestions, native `cd`, and Zoxide in a terminal. Also test the active configuration in an isolated tmux server. Do not change the user's running tmux server.

Keep README and examples consistent with the implementation. Preserve the active personal post file before changing it. Do not replace it with an ignored repository copy.

Inspect the worktree and recent history before commits. Stage only reviewed files. Do not push without explicit authorization.
