# sc-zsh: Modular Zsh Configuration

sc-zsh loads plugins, completions, and personal configuration before the first prompt. It uses Zsh syntax for existing shell commands and environment-variable snippets.

The configuration keeps shell setup separate from personal tools in [Toolbox](https://github.com/rvwallace/toolbox). [sc-nu](https://github.com/rvwallace/sc-nu) is the related Nushell configuration.

## Setup

Requirements: Zsh 5.9 or later, Git for plugin setup, and uv for tests. Starship, FZF, Carapace, Zoxide, Eza, and Homebrew are optional.

From this checkout, run:

```sh
bash setup.sh
bash doctor.sh
```

Setup checks Zsh and Git, then repairs the `~/.zshenv` link. It backs up conflicting bootstrap files and links with collision-safe names. A correct link remains unchanged, including relative links.

Setup preserves existing personal pre/post files. Missing files get comment-only templates with mode `600`. The example files show optional settings and integrations. Setup also creates personal function/completion directories and the Zsh cache directory.

Setup installs the pinned plugins through the existing installer. For offline preparation, use `bash setup.sh --skip-plugins`, then install plugins separately. Missing plugins remain blocking findings in doctor until installed.

These commands do not install system packages or change the login shell. Start a fresh Zsh session after setup.

Doctor checks prerequisites, the bootstrap link, startup files, directories, plugin pins, and optional tools. It reports local plugin edits and broadly readable personal files as warnings. It does not source personal configuration, write files, or generate caches. Blocking findings return exit status `1`. Warnings alone return `0`.

Both commands honor exported `SC_USER_DIR`, `SC_USER_FUNCTIONS_DIR`, `SC_USER_COMPLETIONS_DIR`, `SC_PLUGIN_DIR`, `XDG_DATA_HOME`, and `XDG_CACHE_HOME`. Paths must be absolute. If private configuration sets unexported overrides, pass the same values when running setup or doctor.

The installer copies matching, unmodified Zinit checkouts when available. Otherwise, it fetches only the pinned revision with shallow history. It preserves the old Zinit installation and removes incomplete temporary checkouts after failures.

## Startup and configuration

`.zshenv` sets `ZDOTDIR` and sources `~/.zshrc.local.pre` for all shells, including noninteractive shells. Keep exports and feature flags there. PATH helpers are not available at this stage.

Interactive shells then load these components:

1. Defaults, function paths, lazy autoload declarations, PATH, and environment settings.
2. The integration cache, native completion initialization, and history substring search.
3. History options, keybindings, Starship, FZF, Carapace, Zoxide, GNU utilities, and aliases.
4. `~/.zshrc.local.post`, including Toolbox and personal widgets.
5. fzf-tab, autosuggestions, and syntax highlighting, after the other widgets exist.

No plugin installation, update, or timed loading occurs during startup. Missing plugins produce a setup message. Built-in completion remains available.

| Setting | Default | Purpose |
| --- | --- | --- |
| `SC_USER_DIR` | `~/.sc-zsh` | Personal functions and completions |
| `SC_USER_FUNCTIONS_DIR` | `$SC_USER_DIR/functions` | Lazy autoload functions |
| `SC_USER_COMPLETIONS_DIR` | `$SC_USER_DIR/completions` | Personal completion files |
| `SC_PLUGIN_DIR` | `${XDG_DATA_HOME:-$HOME/.local/share}/sc-zsh/plugins` | Installed plugin checkouts |
| `SC_COMPLETION_MAX_AGE` | `86400` | Completion dump lifetime in seconds |
| `ENABLE_STARSHIP` | `true` | Use Starship when installed |
| `ENABLE_FASTFETCH` | `false` | Show Fastfetch before the prompt |
| `SC_PROFILE` | unset | Set to `1` for source timings and `zprof` |

`ZSH_CACHE_DIR` is `${XDG_CACHE_HOME:-$HOME/.cache}/zsh`. Personal post configuration runs synchronously, so its cost is part of startup.

## Plugins and completion

The retained plugins are history substring search, autosuggestions, fast syntax highlighting, zsh-completions, and fzf-tab. Their source files load directly.

Carapace supplies completion for CLI tools. Zsh supplies native path, variable, and function completion. FZF supplies `**<Tab>`, Ctrl-R history search, Ctrl-T file selection, and Alt-C directory selection. fzf-tab supplies the ordinary Tab selection menu.

FZF loads before fzf-tab. fzf-tab loads after `compinit` and before autosuggestions and highlighting, as required by its [installation instructions](https://github.com/Aloxaf/fzf-tab).

FZF's ZLE integration runs only with terminal input. Interactive command invocations without a terminal still load native completion and other integrations.

Add a plugin's name, repository, and reviewed revision to `scripts/plugin-manifest.zsh`. Add its source call to the appropriate loading stage. Then run:

```zsh
zsh scripts/plugins.zsh update
```

Both `install` and `update` reconcile installed checkouts with the manifest. They do not advance plugins to unreviewed upstream revisions. Modified plugin checkouts are preserved, and the command stops with an error.

Unchanged installs preserve completion cache signatures and plugin indexes. A successful plugin change invalidates completion data, including when a later plugin fails to install.

For an assistant-managed plugin change, use the repository's [sc-zsh-plugins skill](skills/sc-zsh-plugins/SKILL.md). For example:

```text
Use $sc-zsh-plugins to add author/repository to this configuration.
```

The skill handles revision selection, load order, installation, behavior checks, startup measurements, and documentation. `AGENTS.md` also directs assistants to this workflow.

Rebuild completion data without deleting history:

```zsh
SC_COMPLETION_MAX_AGE=0 zsh
```

The completion loader audits directories when rebuilding. It excludes insecure directories. It reuses an audited dump for up to 24 hours unless `fpath` changes. Plugin maintenance invalidates the dump signature. A read-only cache uses completion without saving a dump.

## Integration cache

`_sc_evalcache command arguments...` stores generated Zsh initialization scripts. `_evalcache` remains available for older personal snippets.

```zsh
if (( $+commands[mise] )); then
    _sc_evalcache mise activate zsh
fi
```

Cache identities include the resolved executable, its inode and timestamps, size, generation arguments, Zsh version, home directory, and Carapace bridge setting. Warm startup does not run tool version commands or external hash commands.

Generation uses a temporary file and an atomic rename. Failed or malformed output does not replace an existing script. A read-only cache initializes the current shell without saving the script. Old cache entries remain available until removed manually.

Use this helper for shell initialization output, not commands that contain credentials. Keep secrets in the personal pre file.

## Navigation, GNU utilities, and tmux

`cd` remains the Zsh built-in. Zoxide supplies `z` and `zi`. The configuration preserves existing history settings: 10,000 command entries, shared history, and duplicate filtering. Tmux scrollback is independent of shell history.

Installed GNU-prefixed commands, such as `gsed` and `gdate`, also resolve under their ordinary names through command hashes. Shell built-ins and user aliases retain precedence. A pre-command hook restores these mappings after PATH changes or `rehash`. sc-zsh does not install GNU packages.

On macOS, install missing GNU tools separately when needed:

```zsh
brew install coreutils findutils gnu-sed gnu-tar grep gawk
```

The inherited `TERM` is preserved, including `tmux-256color`. Zinit and zsh-256color no longer alter terminal setup. The configuration does not change [tmux-conf](https://github.com/rvwallace/tmux-conf), its scrollback, or Starship's prompt layout.

| Key | Action |
| --- | --- |
| Ctrl-O or Ctrl-X Ctrl-E | Edit the command line in `$EDITOR` |
| Up/Down or Ctrl-P/Ctrl-N | Search history by substring |
| Alt-S | Toggle `sudo` on the command line |
| Ctrl-X L | Show the current directory |
| Ctrl-X G | Show Git status |
| Ctrl-X C | Copy the command line |

Terminfo supplies Home, End, Delete, and history navigation keys. Existing Toolbox widgets remain available before the first prompt.

## Personal functions and Toolbox

Add one autoload body per file in `~/.sc-zsh/functions/`. The filename is the command name. Both built-in and personal functions are discovered automatically and load on first use.

```zsh
# ~/.sc-zsh/functions/git.root-cd
emulate -L zsh
local root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
cd -- "$root"
```

Add completion files named `_command-name` to `~/.sc-zsh/completions/`. Built-in examples are `ql` and `rm.dstore`.

Source Toolbox from the personal post file:

```zsh
if [[ -z "${TOOLBOX_LOADED:-}" && -f "$HOME/silentcastle/projects/toolbox/shell/init.sh" ]]; then
    source "$HOME/silentcastle/projects/toolbox/shell/init.sh"
fi
```

Toolbox owns AWS, Git, and Terraform helpers, including automatic Terraform switching. Do not add duplicate directory-change hooks here.

Toolbox can also supply `SC_AWS_TOKEN_TTL` to Starship. Its AWS module refreshes the value before prompts. Keep the Starship configuration outside sc-zsh:

```toml
[env_var.SC_AWS_TOKEN_TTL]
format = "[$symbol$env_value]($style) "
style = "bold blue"
symbol = "⌛️ "
variable = "SC_AWS_TOKEN_TTL"
```

## Tests and performance

```zsh
zsh tests/test-startup.zsh
zsh tests/test-cache.zsh
uv run --script tests/test-setup.py
zsh tests/test-tmux.zsh --personal
zsh tests/test-startup.zsh --benchmark --samples 10
zsh tests/test-startup.zsh --benchmark --personal --samples 10
zsh tests/test-startup.zsh --benchmark --personal --system-rc --samples 10
SC_PROFILE=1 zsh
```

The PTY benchmark measures the first rendered prompt and confirms feature readiness. It also measures the next prompt after a command. Personal measurements include the active pre/post files, Toolbox, and Starship configuration.

Cold-cache startup includes integration generation and completion rebuilds. Warm measurements reuse these artifacts. Prompt rendering and the current directory can materially affect results.

The previous reported 170 ms startup excluded delayed features. The new measurements must not be compared with Nushell's noninteractive `nu -c` timing. See [tests/README.md](tests/README.md) for test coverage and benchmark details.

The [measured startup report](docs/startup-performance.md) records about 100 ms for the core prompt and 220 ms for the full personal prompt. All retained features are available at that prompt. The previous personal configuration took about two seconds to finish delayed loading.

## Versioning

`VERSION` starts at `0.1.0`, the first formally versioned configuration. Earlier configurations remain part of the unversioned Git and changelog history.

Versions identify releases, not individual commits. Doctor displays the configuration version, Git revision, and whether the checkout contains modifications. Archive copies display the version without a Git revision.

Use major versions for breaking configuration changes, minor versions for features, and patch versions for fixes. During `0.x`, minor releases can include documented breaking changes. Plugin pins and cache format revisions remain separate from the configuration version.

Keep pending changes under `Unreleased`. When a release is ready, move its entries under a version heading and release date. Retain the existing dated subsections. Commit the version and changelog together, then tag that commit as `v0.1.0`. Later releases follow the same convention with their chosen version.

## Migration and rollback

Run `bash setup.sh` again to repair links and missing directories. It preserves existing personal files and does not rebuild completion data when plugins are unchanged.

Zinit, evalcache, zsh-256color, and OMZ extract/gitignore snippets are no longer loaded. GNU command selection is built into sc-zsh. Existing aliases and history settings remain in place.

Back up personal files before editing them. Existing Zinit files and generated caches remain intact. To restore the previous setup, restore the personal post backup and select the previous Git branch. Start a fresh shell after either change.

See [CHANGELOG.md](CHANGELOG.md) for change history and the [Zsh manual](https://zsh.sourceforge.io/Doc/Release/) for shell behavior.
