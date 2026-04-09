# AGENTS.md

This file provides guidance to AI assistants when working with code in this repository.

## Repository Overview

sc-zsh is a modular, performance-optimized Zsh configuration system. Current startup time: ~0.17s (81% improvement from 0.9s baseline).

**Core Philosophy:**

- Simple, not over-engineered
- Modular with clear separation of concerns
- Performance-first (turbo mode, deferred loading, caching)
- User customizations separate from version-controlled config

## Architecture

### Startup Sequence

1. `.zshenv` → Sets `ZDOTDIR`, sources `~/.zshrc.local.pre` (**all shells including non-interactive**)
2. `.zshrc` → Main orchestrator:
   - Profiling setup (`SC_PROFILE=1`)
   - Terminal stability (`ttyctl -f`)
   - `includes/defaults.zsh` → Configuration defaults
   - fpath setup (functions/completions)
   - User function autoload
   - `includes/paths.zsh` → PATH management
   - `includes/exports.zsh` → Environment variables
   - `includes/plugins.zsh` → Zinit plugin management
   - `includes/options.zsh` → Zsh options, history, dirstack
   - `includes/keybindings.zsh` → Terminfo-based bindings
   - `includes/app_integrations.zsh` → External tools (including Carapace for completions)
   - `includes/aliases.zsh` → Command aliases
   - Built-in functions (dynamically autoloaded)
   - `.zshrc.local.post` → **User late customizations** (deferred)

### Directory Structure

**Version-controlled** (`~/silentcastle/projects/sc-zsh/`):

- `.zshenv`, `.zshrc` - Bootstrap files
- `.zshrc.local.pre`, `.zshrc.local.post` - User override points (not in git)
- `includes/` - Sourced configuration files (`*.zsh`)
- `functions/` - Built-in autoload functions
- `lib/` - Removed (content migrated to toolbox)
- `completions/` - Built-in completions
- `docs/` - Documentation

**User-specific** (`~/.sc-zsh/` - NOT in git):

- `functions/` - User autoload functions (auto-loaded)
- `completions/` - Custom/generated completions

## Key Components

### Plugin System (Zinit)

**Location:** `includes/plugins.zsh`
**Installation:** `~/.local/share/zinit/zinit.git` (auto-installs)

**Loading Strategy:**

- **No wait:** Critical (OMZ git plugin)
- **wait"0":** Core (syntax-highlighting, autosuggestions, completions)
- **wait"1":** Utilities (fzf-tab, history-search, you-should-use)

**Optimization techniques:**

- Turbo mode: `wait"0"`, `wait"1"`
- Light mode: `light-mode` (no reporting overhead)
- For-syntax: Consolidate similar plugins
- `zicompinit; zicdreplay` in completions plugin (50-80% faster)

**Current plugins:**

- zsh-syntax-highlighting, zsh-autosuggestions, zsh-completions
- zsh-256color, fzf-tab, zsh-history-substring-search
- zsh-you-should-use
- OMZ snippets: eza, extract, gitignore, gnu-utils

**Note:** Completions are primarily handled by Carapace (loaded in `app_integrations.zsh`), which provides comprehensive completion support across multiple shells and tools.

**Eza plugin configuration:**
- dirs-first: yes
- icons: yes
- git-status: yes
- header: yes
- size-prefix: binary

### Autoload Functions

**Built-in** (`functions/`):

- Auto-loaded via loop in `.zshrc`
- Namespace pattern for complex tools
- Paired with completions in `completions/_function_name`

**User** (`~/.sc-zsh/functions/`):

- Auto-loaded via loop in `.zshrc`
- All files auto-discovered and loaded

### App Integrations

**Location:** `includes/app_integrations.zsh`

Loads integrations for external tools with deferred loading (except Starship). All integrations are guarded to run only in interactive shells.

**Current integrations:**

- **Starship** (wait: none) - Prompt theme, loaded synchronously for first prompt
- **Fastfetch** (wait"1") - System info display on startup (optional, default: disabled)
- **FZF** (wait"1") - Fuzzy finder with auto-detection of fd/rg/ag for default command
- **Carapace** (wait"1") - **Primary completion handler** supporting multiple shells and tools (gen, zsh, fish, bash, inshellisense). Replaces individual OMZ completion plugins for a unified, comprehensive completion system.
- **Zoxide** (wait"1") - Smart directory jumper, replaces `cd` command
- **Homebrew** (wait"1") - Command-not-found handler

All tools except Starship use Zinit's deferred loading (`wait"1"`) for faster startup.

**Completion Strategy:** This configuration uses Carapace as the primary completion system instead of managing individual completion files or OMZ completion plugins. This simplifies the setup while providing broad tool coverage.

### Configuration Variables

**Defined in `includes/defaults.zsh`, override in `.zshrc.local.pre`:**

```zsh
SC_USER_DIR="${SC_USER_DIR:-$HOME/.sc-zsh}"
SC_USER_FUNCTIONS_DIR="${SC_USER_FUNCTIONS_DIR:-${SC_USER_DIR}/functions}"
SC_USER_COMPLETIONS_DIR="${SC_USER_COMPLETIONS_DIR:-${SC_USER_DIR}/completions}"

# Feature flags
ENABLE_STARSHIP=true
# ENABLE_GNU_SED=true    # Handled by OMZ gnu-utils plugin
# ENABLE_GNU_TAR=true    # Handled by OMZ gnu-utils plugin
ENABLE_FASTFETCH=false

# Profiling
SC_PROFILE=1  # Enable startup profiling
```

### PATH Management

**File:** `includes/paths.zsh`
**Helper functions:**

- `_path_remove()` - Remove directory from PATH
- `_path_prepend()` - Add to beginning (highest priority)
- `_path_append()` - Add to end (lowest priority)

**Note:** Manual deduplication (no `typeset -U path`)

### Performance Features

**Current optimizations:**

- Zinit turbo mode with deferred loading
- 24-hour completion cache (`.zcompdump`)
- Deferred `.zshrc.local.post` (Zinit wait"1")
- Directory stack persistence (`~/.cache/zsh/dirs`)
- Terminal stability (`ttyctl -f`)
- Non-interactive guard in `plugins.zsh`

**Profiling:**

```bash
SC_PROFILE=1 zsh
```

## Common Development Tasks

### Adding a Plugin

**File:** `includes/plugins.zsh`

```zsh
# Single plugin
zinit ice wait"1" lucid
zinit light author/plugin-name

# Multiple plugins with same options (for-syntax)
zinit wait"1" lucid light-mode for \
    author1/plugin1 \
    author2/plugin2
```

**Test:** `exec zsh`

### Adding a Function

**User function** (`~/.sc-zsh/functions/`):

```zsh
# ~/.sc-zsh/functions/git.env
git.root-cd() {
    local root=$(git rev-parse --show-toplevel 2>/dev/null)
    [[ -n "$root" ]] && cd "$root"
}
```

Auto-loaded on next shell start.

**Built-in function** (`functions/`):

1. Create function file
2. Add completion to `completions/_function_name`
3. Explicitly autoload in `.zshrc`: `autoload -Uz function-name`

### Adding Aliases

**File:** `includes/aliases.zsh` (built-in) or `.zshrc.local.post` (personal)

```zsh
alias shortcut='long command'
```

**Organization:** Aliases are organized by category:
- Core & File System (rm, grep, less, bat, eza, archives)
- Network & Connectivity (ip, lsof, http utilities)
- System & Monitoring (terminal reset, fonts)
- Time & Date (timestamp, datestamp, now)
- Development (Git, Python, Terraform, Kubernetes, Homebrew)
- MacOS Specific (top, dns, wifi, finder utilities)

**Philosophy:** Only add aliases you'll use. `zsh-you-should-use` plugin reminds you of existing aliases.

### Adding Completions

**Completion sources:**
- **Carapace** - Primary completion system (handles most tools automatically)
- **Built-in function completions:** `completions/_function_name` (for dynamically autoloaded functions)
- **User completions:** `~/.sc-zsh/completions/_command_name` (for custom tools)

**Completion strategy:**

Most completions are handled automatically by Carapace (configured in `app_integrations.zsh`). Carapace provides comprehensive completion support for hundreds of CLI tools without needing individual completion files.

For custom autoload functions, create completion files in:
- `completions/_function_name` (built-in)
- `~/.sc-zsh/completions/_command_name` (user)

**Rebuild cache if completions aren't working:**

```bash
rm ~/.zcompdump && exec zsh
```

### Testing Changes

**Safe workflow:**

1. Make changes
2. Profile: `SC_PROFILE=1 zsh` (checks errors + timing)
3. Reload: `exec zsh`
4. Check for errors

**Clean test:**

```bash
zsh -f  # No rc files
```

## Critical Paths

- **Main config:** `~/silentcastle/projects/sc-zsh/`
- **User config:** `~/.sc-zsh/`
- **Documentation:** `docs/README.md` (comprehensive guide)
- **Zinit:** `~/.local/share/zinit/zinit.git`
- **Completion cache:** `~/.zcompdump`
- **Directory stack:** `~/.cache/zsh/dirs`
- **History:** `~/.zsh_history`

## Debugging Commands

```bash
# Profile startup
SC_PROFILE=1 zsh

# Reload shell
exec zsh

# Rebuild completions
rm ~/.zcompdump && exec zsh

# List loaded plugins
zinit list

# Update all plugins
zinit update

# Check fpath
echo $fpath

# Test function loading
autoload -Uz function-name
which function-name

# Test completion
complete -p command-name
```

## Common Issues

**Completions not working:**

1. Check file starts with `_` (`_command-name`)
2. Verify directory in fpath: `echo $fpath`
3. Rebuild: `rm ~/.zcompdump && exec zsh`

**Slow startup:**

1. Profile: `SC_PROFILE=1 zsh`
2. Check plugins without turbo mode
3. Review `.zshrc.local.post` for heavy operations

**Functions not loading:**

1. Check directory in fpath
2. Verify filename matches function name
3. Test: `autoload -Uz function-name`

**Plugin errors:**

1. Check loading order (dependencies first)
2. Update: `zinit update`
3. Check: `zinit list`

## Changelog

**File:** `docs/README.md` — "Change Log" section at the bottom

**Rule:** Every change to this repo must get a changelog entry. Add it under a `### YYYY-MM-DD` heading (create the heading if it doesn't exist for today). Use the file's modification date — not today's date — when backdating entries for changes that were already made.

**What to log:**
- Files added, removed, or significantly changed
- Functions/aliases/integrations moved to or from toolbox
- New features or behaviors
- Removals or deprecations

**Format:** One bullet per logical change, e.g.:
```
### 2026-04-02
- Migrated `git.helper` to `toolbox/shell/modules/git.sh`
- Removed `aliases.zsh` network section (moved to toolbox)
```

**Do not log:** Typo/comment fixes, formatting-only changes, or anything already described by a commit message with no behavioral impact.

---

## Version Control

**Tracked (in git):**

- `.zshenv`, `.zshrc`
- `includes/` - All sourced config files
- `functions/`, `completions/`, `docs/`, `tests/`

**Not tracked (.gitignore):**

- `.zshrc.local.pre`
- `.zshrc.local.post`
- `.zsh_history`
- `.zcompdump`
- `~/.sc-zsh/` (user directory)

## Key Patterns

### Namespace Functions

```zsh
# Good: namespace.command
git.root-cd
ssh.add_key

# Avoid: flat names
gitroot
```

### Global Helper Functions

**Underscore prefix convention** for shell-level utilities:

```zsh
# Good: underscore prefix for global helpers
_source()         # Profiling-aware source wrapper
_path_prepend()   # Add directory to start of PATH
_path_append()    # Add directory to end of PATH
_path_remove()    # Remove directory from PATH

# Avoid: no prefix for shell-level helpers
source_file()
add_to_path()
```

**Design rationale:**

- **Underscore prefix:** Indicates these are internal/helper functions, not user-facing commands
- **Global scope:** Intentionally remain in global scope for performance (no function cleanup needed)
- **Interactive shell context:** These helpers are only used during shell initialization and remain available for user customization files
- **No cleanup required:** In interactive shells, keeping these functions available is acceptable and useful

**Current global helpers:**

- `_source()` (`.zshrc:12`) - Wraps `source` with optional profiling (`SC_PROFILE=1`)
- `_path_remove()` (`includes/paths.zsh:8`) - Remove directory from PATH array
- `_path_prepend()` (`includes/paths.zsh:13`) - Add directory to beginning of PATH (highest priority)
- `_path_append()` (`includes/paths.zsh:20`) - Add directory to end of PATH (lowest priority)

**When to use this pattern:**

- Shell initialization helpers that need to be called from multiple files
- PATH manipulation utilities used in both core config and user config files
- Profiling or debugging wrappers used throughout startup sequence

**When NOT to use this pattern:**

- User-facing commands (use namespace.command pattern instead)
- Functions only used within a single file (define locally or with local scope)
- Functions used only within autoload functions (prefix with underscore but keep in function scope)

### Autoload Function Structure

```zsh
#autoload
# Description

emulate -L zsh  # Local options

_helper() {
    # Private helper (underscore prefix)
}

# Main logic
case "$1" in
    cmd) _helper "$@" ;;
    *) echo "Usage: ..." ;;
esac
```

### Plugin Loading Order

1. OMZ git (no wait - provides aliases)
2. Core plugins (wait"0" - syntax, completion)
3. Utilities (wait"1" - nice-to-haves)
4. OMZ snippets (wait"1")

### Error Handling

**Sourced files** (includes/*.zsh, lib/*.zsh):

Use `return 1 2>/dev/null || exit 1` for error conditions:

```zsh
if ! command -v required_tool &> /dev/null; then
    echo "[SilentCastle zsh] ERROR: required_tool not found" >&2
    return 1 2>/dev/null || exit 1
fi
```

**Rationale:** Sourced files need to handle both sourcing (`source file.zsh`) and direct execution (`zsh file.zsh`). The pattern attempts `return 1` first (works when sourced), and if that fails (non-zero exit when executed directly), uses `exit 1` instead.

**Functions** (functions/*, helpers in files):

Use simple `return 1` for error conditions:

```zsh
function_name() {
    if [[ ! -d "$directory" ]]; then
        echo "Error: Directory not found" >&2
        return 1
    fi
    # function logic
}
```

**Rationale:** Functions always run in a function context where `return` is valid. No need for the `|| exit` fallback.

**Examples from codebase:**

- Sourced file error: `includes/plugins.zsh:12,20,26`
- Silent early return: `includes/app_integrations.zsh:10` (non-interactive guard)

**When to echo to stderr:**

- Critical errors that prevent functionality: Use `>&2`
- Silent guard clauses (non-interactive, missing features): No output
- Validation failures in user-facing functions: Use `>&2`

## Performance Targets

- **Startup:** <0.2s (current: ~0.17s)
- **Completion rebuild:** Triggered max once per 24 hours
- **Plugin loading:** Deferred with turbo mode
- **User functions:** Lazy autoload

## Security Considerations

**Homebrew eval (Trust Boundary):**
- **Location:** `includes/paths.zsh:32-36`
- **Risk:** Uses `eval` with Homebrew command output
- **Mitigation:** Homebrew is trusted software installed by system administrator. Only executes on verified Homebrew binary existence (`-x` check).
- **High-security environments:** Verify Homebrew binary integrity (checksum/signature) before sourcing configuration.

**History file permissions:**
- **Location:** `includes/options.zsh:13`
- **Protection:** History file created with 600 permissions atomically using umask in subshell
- **Prevents:** TOCTOU race condition, unauthorized access to command history

## Notes

- **Completions use zicompinit:** Don't call `compinit` manually (handled by Zinit)
- **Directory stack:** Auto-saves on `cd`, navigate with `cd -<TAB>`
- **Terminfo keys:** Portable across terminals (not hardcoded escape sequences)
- **User separation:** Personal code in `~/.sc-zsh/`, not in repo
- **Customization points:** `.zshrc.local.pre` (sourced in `.zshenv` — available to all shells) and `.zshrc.local.post` (late, interactive only)

See `docs/README.md` for comprehensive documentation including architecture decisions, migration guides, and best practices.
