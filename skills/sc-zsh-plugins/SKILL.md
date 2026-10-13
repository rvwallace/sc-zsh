---
name: sc-zsh-plugins
description: Add or upgrade Zsh plugins in sc-zsh through its pinned manifest and direct loader. Use for plugin installation, version changes, and plugin-specific load-order adjustments in this repository.
---

# sc-zsh Plugins

Use this workflow for requested plugin changes in sc-zsh. An explanation or review request does not authorize installation or configuration changes.

## Inspect the current setup

Locate the repository and read `AGENTS.md`. Inspect these integration points before editing:

- `scripts/plugin-manifest.zsh`: plugin name, GitHub repository, and full commit SHA.
- `scripts/plugins.zsh`: installation and revision reconciliation outside startup.
- `includes/plugins.zsh`: completion setup, `_sc_plugin_source`, and `_sc_load_widgets`.
- `.zshrc`: app integrations and personal configuration load before widget wrappers.

Preserve unrelated worktree changes. Record a startup baseline when the requested change affects loading cost.

## Select the plugin and revision

Use the repository and revision supplied by the user. Resolve ambiguous plugin names before changing the manifest.

If the user does not specify a revision, prefer the latest stable upstream release. If no stable release exists, use the upstream default branch. Resolve that revision to a full commit SHA.

Read the upstream installation instructions and source at the selected revision. Confirm the entrypoint filename, dependencies, completion directories, initialization commands, and required load order from those files.

## Add or upgrade the plugin

Add one triple to `SC_PLUGINS`, or change only the requested plugin's revision:

```zsh
plugin-name author/repository FULL_COMMIT_SHA
```

Load source files through the existing helper:

```zsh
_sc_plugin_source plugin-name actual-entrypoint.zsh
```

Choose placement from the plugin's requirements:

- Add completion directories to `fpath` before the existing `compinit` call. Do not initialize completion again.
- Load plugins that call `compdef` after completion initialization.
- Load widgets before autosuggestions and highlighting wrap them. `_sc_load_widgets` runs after personal widgets exist.
- Preserve FZF initialization before fzf-tab. Keep fzf-tab before other widget wrappers.
- Use `_sc_evalcache` for generated initialization output when appropriate.

Resolve overlapping keybindings and features from upstream instructions and the user's requested behavior. Do not silently disable retained core features.

Keep plugins ready at the first prompt. Do not add timed loading, startup downloads, or a new plugin manager. Guard optional external dependencies when the plugin requires them.

Run the existing installer from the repository:

```zsh
zsh scripts/plugins.zsh install
# For a revision change:
zsh scripts/plugins.zsh update
```

Both commands reconcile the whole manifest. They do not select newer upstream revisions. Keep other manifest entries unchanged. If a plugin checkout contains local changes, preserve it and report the installer's failure.

Use `bash setup.sh` when the shell installation also needs bootstrap repair. Use `bash doctor.sh` for read-only installation checks. Unchanged plugin installs must preserve completion signatures.

## Verify and document

Test the plugin's actual behavior in a fresh terminal before declaring it installed. Check its feature at the first prompt. Include tmux when the plugin changes terminal output or keys.

Run the repository checks:

```zsh
zsh tests/test-startup.zsh
zsh tests/test-cache.zsh
uv run --script tests/test-setup.py
zsh tests/test-tmux.zsh --personal
git diff --check
```

Run `zsh -n` separately for each changed Zsh file. Add focused coverage when the plugin changes an existing startup contract or introduces a fragile integration.

Use `uv run --script` for standalone Python helpers. Declare repository script dependencies in PEP 723 metadata. Supply external helper dependencies through `--with`.

Compare warm startup with the baseline when loading cost changes:

```zsh
zsh tests/test-startup.zsh --benchmark --personal --system-rc --samples 5
```

Report cold generation separately from warm startup. Do not sum nested source timings or compare interactive startup with `nu -c`.

Update README for plugin behavior, dependencies, and keybindings. Add the required dated changelog entry. Report the chosen repository, pinned revision, load placement, installation result, behavior checks, and measured startup impact. Distinguish completed checks from limitations.

Keep commits and pushes within the user's authorization. Do not change the login shell, tmux server, personal configuration, or unrelated plugin revisions to complete a plugin request.
