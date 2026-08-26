# sc-zsh Documentation

**Philosophy:** Simple, modular, fast, and separated by concern.

---

## Setup

Quick start:

1. Link `"$HOME/silentcastle/projects/sc-zsh/.zshenv"` to `~/.zshenv`.
2. Copy `.zshrc.local.pre.example` to `~/.zshrc.local.pre`.
3. Copy `.zshrc.local.post.example` to `~/.zshrc.local.post`.
4. Start a new `zsh` session.

The bootstrap entrypoint is `~/.zshenv`. When linked, it sets `ZDOTDIR` to this repository and loads pre-configuration from `~/.zshrc.local.pre`. Interactive shell startup continues through `.zshrc`. Late personal overrides load from `~/.zshrc.local.post`.

---

## Quick Links

- [Architecture](#architecture) - Structure of sc-zsh
- [Performance](#performance) - Optimization results and tips
- [Customization](#customization) - Ways to extend sc-zsh
- [Migration Guide](#migration-guide) - Moving from legacy setups
- [Decision Log](#decision-log) - Key architectural decisions

---

## Architecture

### Core Principles

1. **Simple** - Avoid unnecessary abstraction.
2. **Modular** - Keep concerns separate.
3. **Fast** - Maintain fast startup (currently ~0.17s).
4. **Lean startup** - Keep heavy tools separate from the shell core.
5. **Toolbox integration** - Keep shell modules and CLI tools in [toolbox](https://github.com/rvwallace/toolbox).

### Directory Structure

```
~/silentcastle/projects/sc-zsh/     # Main repo (version controlled)
├── .zshenv                          # Sets ZDOTDIR; sources ~/.zshrc.local.pre for all shells
├── .zshrc                           # Main loader/orchestrator (interactive shells)
├── .zshrc.local.pre.example         # Template for pre-config env vars (API keys, exports)
├── .zshrc.local.post.example        # Template for late customizations & toolbox sourcing
├── AGENTS.md                        # AI assistant guidance for this repo
├── CLAUDE.md                        # Claude Code configuration
├── README.md                        # Documentation (this file)
├── CHANGELOG.md                     # Change log
│
├── includes/                        # Sourced configuration files
│   ├── defaults.zsh                # Default config values & ZSH_CACHE_DIR
│   ├── paths.zsh                   # PATH management
│   ├── exports.zsh                 # Environment variables
│   ├── plugins.zsh                 # Zinit plugin management
│   ├── options.zsh                 # Zsh options & completion styling
│   ├── keybindings.zsh             # Terminfo-based keybindings
│   ├── app_integrations.zsh        # External app integrations (Starship, FZF, Carapace)
│   └── aliases.zsh                 # Command aliases
│
├── functions/                       # Built-in autoload functions
│   ├── ql                          # Quick Look helper
│   └── rm.dstore                   # Remove .DS_Store files
│
├── completions/                     # Built-in completions
│   ├── _ql
│   └── _rm.dstore
│
└── tests/                           # Integration tests
    ├── test-startup.zsh            # Startup time, errors, functions, PATH, ZDOTDIR, cache
    └── README.md                   # Test documentation
```

### User Customizations (Separate from Repo)

```
~/.sc-zsh/                          # User-specific (NOT in git)
├── functions/                      # User autoload functions
│   ├── git.env                    # Custom git helpers
│   └── ssh.env                    # Custom SSH helpers
│
└── completions/                    # Custom completions
    └── _my-tool                   # Custom completion scripts
```

### Configuration Variables

Defined in `defaults.zsh`, override in `.zshrc.local.pre`:

```zsh
SC_USER_DIR="${SC_USER_DIR:-$HOME/.sc-zsh}"
SC_USER_FUNCTIONS_DIR="${SC_USER_FUNCTIONS_DIR:-${SC_USER_DIR}/functions}"
SC_USER_COMPLETIONS_DIR="${SC_USER_COMPLETIONS_DIR:-${SC_USER_DIR}/completions}"
```

---

## Performance

### Current Metrics

- **Startup time:** ~0.17s (reduced from 0.9s)
- **Improvement:** 81% faster
- **Method:** Run `SC_PROFILE=1 zsh` to profile startup.

### Optimizations Applied

1. **Zinit turbo mode** - Staggered deferred loading (`wait"0"` through `wait"4"`)
2. **Light mode** - Fast plugin loading without reporting overhead
3. **For-syntax** - Consolidated plugin declarations
4. **zicompinit and zicdreplay** - Fast completion initialization
5. **24-hour completion cache** - Cache rebuilt at most once each day
6. **Deferred .zshrc.local.post** - Non-critical customizations load after core integrations

Deferred Zinit jobs run in the main shell process rather than in the background. Staggering jobs reduces ZLE pauses by avoiding a single large timer boundary. Deferred `atload` callbacks use `nocd` so tmux cannot observe a plugin directory as the active pane directory during callback execution.

### Performance Features

- **Built-in profiling:** Run `SC_PROFILE=1 zsh`.
- **Non-interactive guard:** Skips plugins in non-interactive shells.
- **Terminal stability:** Freezes terminal state with `ttyctl -f`.
- **Directory stack caching:** Retains directory history across sessions.

---

## Customization

### Adding Aliases

**Target file:** `includes/aliases.zsh` (built-in) or `~/.zshrc.local.post` (personal)

**Rule:** Add only aliases that you use.

### Adding Functions

**For personal functions:**

1. Create a file in `~/.sc-zsh/functions/`.
2. Use the namespace pattern: `namespace.function-name`.
3. Functions auto-load when the shell starts.

**Example:**

```zsh
# ~/.sc-zsh/functions/git.env
git.root-cd() {
    local root=$(git rev-parse --show-toplevel 2>/dev/null)
    [[ -n "$root" ]] && cd "$root"
}
```

**For built-in functions:**

1. Add the function file to the `functions/` directory.
2. Add the completion file to `completions/`.
3. Autoload the function in `.zshrc` (`autoload -Uz function-name`).

### Adding Plugins

**Target file:** `includes/plugins.zsh`

**Pattern:**

```zsh
zinit ice wait"1" lucid
zinit light author/plugin-name
```

**Current plugins:**

- fast-syntax-highlighting
- zsh-autosuggestions
- zsh-completions
- zsh-256color
- evalcache
- fzf-tab
- zsh-history-substring-search
- OMZ snippets: extract, gitignore, gnu-utils

**Note:** Carapace handles most completions (`includes/app_integrations.zsh`).

### Adding Completions

**Completion sources:**

- **Carapace** - Primary completion engine (handles most tools automatically).
- **Built-in completions** - For autoload functions in `completions/` (`_ql`, `_rm.dstore`).
- **User completions** - Custom completions in `~/.sc-zsh/completions/`.

**Strategy:**

Carapace completes most CLI tools automatically without separate completion files.

**When to add manual completions:**

- Custom autoload functions (such as `ql` and `rm.dstore`)
- Tools not supported by Carapace
- Specialized custom commands

**To rebuild the completion cache:**

```bash
rm -f ~/.cache/zsh/zcompdump && exec zsh
```

### Adding Scripts and Tools

Custom scripts, shared shell functions, and CLI tools live in [toolbox](https://github.com/rvwallace/toolbox).

**Organization:**

- **Shell Modules and Functions:** Add files to `toolbox/shell/modules/` (for example, `git.sh`, `aws.sh`, `terraform.sh`).
- **CLI Tools and Python Packages:** Manage tools in [toolbox](https://github.com/rvwallace/toolbox) with dedicated package environments or entrypoints.
- **Machine-Specific Scripts:** Put simple glue scripts or local overrides in `~/.zshrc.local.post`.

**Integrating Toolbox via `.zshrc.local.post`:**

Source toolbox modules from your `~/.zshrc.local.post` file (see `.zshrc.local.post.example`):

```zsh
# Toolbox (personal CLI tools and shell modules)
if [[ -z "${TOOLBOX_LOADED:-}" && -f "$HOME/silentcastle/projects/toolbox/shell/init.sh" ]]; then
    source "$HOME/silentcastle/projects/toolbox/shell/init.sh"
fi
```

Because `sc-zsh` defers loading `.zshrc.local.post` with Zinit (`wait"2"`), toolbox shell modules load asynchronously without blocking prompt startup.

---

## Key Features

### Directory Stack

Navigate directory history with `cd -<TAB>`:

```bash
cd ~/Documents
cd ~/Downloads
cd ~/Desktop
cd -<TAB>          # Shows history
cd -2              # Jump to second item
```

Zsh saves directory history to `~/.cache/zsh/dirs` across sessions.

### Completion Menu

Select completions with arrow keys:

```bash
git <TAB>          # Use arrow keys to select
```

### Terminfo Keybindings

Standard keybindings work consistently across terminal emulators:

- Home / End - Move to start or end of line
- Delete - Delete character
- PageUp / PageDown - Navigate command history

### App Integrations

- **Starship** - Prompt theme (loads synchronously)
- **fzf** - Fuzzy finder (loads with `wait"1"`)
- **zoxide** - Directory jumper (loads with `wait"1"`)
- **eza** - Directory listing with file and git metadata (configured in `includes/aliases.zsh`)
- **Carapace** - Multi-tool completion engine (loads with `wait"1"`)
- **Homebrew** - Command-not-found handler (loads with `wait"3"`)

**Completion Strategy:** Carapace completes CLI tools directly. This removes the need for individual OMZ completion plugins and separate completion files.

#### Starship AWS Token TTL

The `toolbox/shell/modules/aws.zsh` module caches the remaining AWS token time in `SC_AWS_TOKEN_TTL` before each prompt. The cache refreshes at most once every 60 seconds by reading `x_security_token_expires` from `~/.aws/credentials`. This avoids running a Python or `uv` process on every prompt.

Starship can show the cached value with this configuration:

```toml
[env_var.SC_AWS_TOKEN_TTL]
format = "[$symbol$env_value]($style) "
style = "bold blue"
symbol = "⌛️ "
variable = "SC_AWS_TOKEN_TTL"
```

Optional configuration overrides:

```zsh
SC_AWS_TOKEN_CACHE_SECONDS=30   # Default: 60
SC_AWS_TOKEN_PROFILE=techops    # Default: techops
```

---

## Migration Guide

### Migrating to sc-zsh

**Status:** Optional. sc-zsh is complete without migration.

**Priority order for custom functions:**

1. **Git functions**
   - Location: `~/.sc-zsh/functions/git.env`
   - Pattern: `namespace.command` (for example, `git.root-cd`)

2. **SSH functions**
   - Location: `~/.sc-zsh/functions/ssh.env`
   - Pattern: `namespace.command` (for example, `ssh.add_key`)

**Note:** `aws.env`, `chef.env`, `k.env`, and Terraform helpers live in `toolbox/shell/modules/`. Do not add them to `sc-zsh`.

**Items to keep out of sc-zsh:**

- Shell modules, AWS/Git/Terraform helpers, and CLI utilities (maintained in [toolbox](https://github.com/rvwallace/toolbox))
- Large alias collections
- Complex legacy scripts

### Toolbox Integration

**Decision:** Keep core shell configuration separate from user tools and modules.

- **sc-zsh:** Pure shell orchestration, plugin lifecycle, completion engine, and baseline configuration.
- **toolbox:** Personal CLI tools, Python packages, and modular shell extensions (`toolbox/shell/modules/`) sourced in `~/.zshrc.local.post`.

---

## Decision Log

### Why not Oh-My-Zsh?

**Decision:** Use Zinit with selected OMZ snippets.

**Rationale:**

- Zinit loads faster with turbo mode and parallel execution.
- Loads OMZ plugins via snippets without framework overhead.
- Gives full control over plugin load order.
- Removes unused framework features.

**Result:** Fast shell startup with selective OMZ plugins.

### Why autoload functions instead of plugins?

**Decision:** Use autoload functions for custom code.

**Rationale:**

- Uses fewer system resources.
- Works with any plugin manager.
- Loads lazily on first function call.
- Easy to maintain.

**Exception:** Use plugins for third-party tools.

### Why separate user customizations?

**Decision:** Use `~/.sc-zsh/` for user-specific code.

**Rationale:**

- Clean separation between core and personal configuration.
- Simple to back up or version separately.
- Keeps repository portable without personal files.
- Location is configurable with `SC_USER_DIR`.

### Why Zinit for-syntax?

**Decision:** Consolidate similar plugins with for-syntax.

**Before:**

```zsh
zinit ice wait"0" lucid
zinit load plugin1
zinit ice wait"0" lucid
zinit load plugin2
```

**After:**

```zsh
zinit wait"0" lucid light-mode for \
    plugin1 \
    plugin2
```

**Result:** Cleaner configuration with equal performance.

### Why zicompinit instead of compinit?

**Decision:** Let Zinit handle completion initialization.

**Rationale:**

- `zicompinit` and `zicdreplay` run 50% to 80% faster.
- Integrates directly with the Zinit completion cache.
- Gives a single point of initialization.

**Performance:** Startup time improved from 0.9s to ~0.17s.

---

## Troubleshooting

### Completions not working

1. Check fpath: `echo $fpath`
2. Rebuild cache: `rm -f ~/.cache/zsh/zcompdump && exec zsh`
3. Verify that the completion file name starts with an underscore (`_command-name`).

### Slow startup

1. Profile startup: `SC_PROFILE=1 zsh`
2. Check plugins loaded without turbo mode.
3. Review `~/.zshrc.local.post` for slow commands.

### Functions not loading

1. Check directory in fpath: `echo $fpath | grep sc-zsh`
2. Verify that the function name matches the file name.
3. Test function manually: `autoload -Uz function-name`

### Plugin errors

1. Check Zinit status: `zinit list`
2. Update plugins: `zinit update`
3. Check loading order (dependencies must load first).

---

## Best Practices

### 1. Keep It Simple

- Do not add features that you will not use.
- Prefer built-in Zsh features over plugins.
- Use aliases only for frequent commands.

### 2. Modular Organization

- Put one concern in each file (`aliases.zsh`, `keybindings.zsh`, etc.).
- Use functions for complex logic.
- Keep personal configuration separate from shared configuration.

### 3. Performance First

- Profile regularly (`SC_PROFILE=1 zsh`).
- Use turbo mode for plugins.
- Defer non-critical startup tasks.
- Cache expensive operations.

### 4. Right Tool for the Job

- Use shell scripts for simple tasks.
- Use toolbox CLI utilities for complex logic.
- Use autoload functions for shell helpers.
- Use plugins for third-party integrations.

### 5. Documentation

- Comment non-obvious configurations.
- Keep `README.md` and `CHANGELOG.md` updated.
- Document custom functions.

---

## Resources

- [Zinit Documentation](https://github.com/zdharma-continuum/zinit)
- [Zsh Manual](https://zsh.sourceforge.io/Doc/)
- [Arch Wiki - Zsh](https://wiki.archlinux.org/title/Zsh)
- [toolbox Repository](https://github.com/rvwallace/toolbox)

---

## Quick Reference

### Useful Commands

```bash
# Profile startup
SC_PROFILE=1 zsh

# List loaded plugins
zinit list

# Update plugins
zinit update

# Reload shell
exec zsh

# Test directory stack
cd -<TAB>

# Check fpath
echo $fpath

# Rebuild completions
rm -f ~/.cache/zsh/zcompdump && exec zsh
```

### File Locations

- **Main config:** `~/silentcastle/projects/sc-zsh/`
- **User config:** `~/.sc-zsh/`
- **Personal overrides:** `~/.zshrc.local.pre` (env vars, sourced in `.zshenv` for all shells) or `~/.zshrc.local.post` (interactive late)
- **Toolbox (CLI tools and modules):** [https://github.com/rvwallace/toolbox](https://github.com/rvwallace/toolbox) (sourced via `~/.zshrc.local.post`)
- **Completions cache:** `~/.cache/zsh/zcompdump`
- **Directory stack cache:** `~/.cache/zsh/dirs`

### Configuration Variables

```zsh
SC_PROFILE=1                    # Enable profiling
ZSH_CACHE_DIR                   # Cache directory (~/.cache/zsh)
SC_USER_DIR                     # User customizations location
SC_USER_FUNCTIONS_DIR           # User functions directory
SC_USER_COMPLETIONS_DIR         # User completions directory
ENABLE_STARSHIP                 # Enable Starship prompt
ENABLE_FASTFETCH                # Enable fastfetch on startup
```

---

## Change Log

See [CHANGELOG.md](CHANGELOG.md) for full change history and release notes.
