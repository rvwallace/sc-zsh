#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Exercise startup through a real PTY and measure prompt readiness."""
import argparse
import errno
import fcntl
import os
import re
import select
import shutil
import signal
import statistics
import struct
import subprocess
import tempfile
import termios
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ZSH = shutil.which("zsh") or "/bin/zsh"
ANSI = re.compile(rb"\x1b\[[0-?]*[ -/]*[@-~]|\x1b\][^\x07]*(?:\x07|\x1b\\)")


class Shell:
    def __init__(self, env, cwd, login=False, system_rc=False):
        self.output = b""
        self.started = time.perf_counter()
        self.pid, self.fd = os.forkpty()
        if not self.pid:
            os.chdir(cwd)
            os.execve(ZSH, [ZSH] + ([] if system_rc else ["-d"]) + ["-li" if login else "-i"], env)
        fcntl.ioctl(self.fd, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 160, 0, 0))
        self.until(lambda data: b"\x1b[?2004h" in data, 15)
        self.first_prompt = (time.perf_counter() - self.started) * 1000

    def until(self, predicate, timeout=10):
        end = time.monotonic() + timeout
        while not predicate(self.output):
            if time.monotonic() > end:
                raise AssertionError("PTY timeout: " + clean(self.output)[-2000:])
            if select.select([self.fd], [], [], min(0.1, end - time.monotonic()))[0]:
                try:
                    chunk = os.read(self.fd, 65536)
                except OSError as error:
                    if error.errno == errno.EIO:
                        raise AssertionError("Shell exited: " + clean(self.output)[-2000:]) from error
                    raise
                if not chunk:
                    raise AssertionError("Shell closed its terminal")
                self.output += chunk
        return self.output

    def command(self, command):
        self.output = b""
        # hist_ignore_space keeps test commands out of personal history.
        os.write(self.fd, b"\x1b[200~ " + command.encode() + b"\x1b[201~\n")
        self.until(lambda data: "\nSC_DONE\n" in clean(data))
        self.until(lambda data: b"\x1b[?2004h" in data)
        return clean(self.output)

    def close(self):
        try:
            os.write(self.fd, b" exit\n")
            end = time.monotonic() + 2
            while time.monotonic() < end:
                if os.waitpid(self.pid, os.WNOHANG)[0]:
                    return
                if select.select([self.fd], [], [], 0.02)[0]:
                    try:
                        os.read(self.fd, 65536)
                    except OSError:
                        pass
            os.kill(self.pid, signal.SIGKILL)
            os.close(self.fd)
            self.fd = -1
            end = time.monotonic() + 1
            while time.monotonic() < end:
                if os.waitpid(self.pid, os.WNOHANG)[0]:
                    break
                time.sleep(0.02)
        finally:
            if self.fd >= 0:
                os.close(self.fd)


def clean(output):
    return ANSI.sub(b"", output).decode(errors="replace").replace("\r", "")


def environment(home, repo=ROOT, personal=False):
    env = dict(os.environ)
    for key in list(env):
        if key.startswith("ZINIT") or key in (
            "FPATH", "ZPFX", "TOOLBOX_LOADED", "SC_PROFILE", "TMUX", "TMUX_PANE",
            "STARSHIP_SHELL", "STARSHIP_SESSION_KEY", "FAST_WORK_DIR",
        ):
            env.pop(key, None)
    if not personal:
        env.update(HOME=str(home), XDG_CACHE_HOME=str(home / "cache"),
                   XDG_CONFIG_HOME=str(home / "config"))
        env.pop("STARSHIP_CONFIG", None)
    env.update(ZDOTDIR=str(repo), TERM="tmux-256color", TERM_PROGRAM="sc-test",
               SC_PLUGIN_DIR=str(Path(os.environ.get("SC_PLUGIN_DIR",
                   str(Path.home() / ".local/share/sc-zsh/plugins")))))
    return env


def functional(home):
    env = environment(home)
    shell = Shell(env, home)
    try:
        initial = clean(shell.output)
        assert not re.search(r"error|failed|not found|can't change", initial, re.I), initial
        checks = (
            "[[ $TERM == tmux-256color && $HISTSIZE == 10000 && $SAVEHIST == 10000 ]]",
            "[[ $widgets[edit-command-line] == user:* && $(bindkey -M emacs '^O') == *edit-command-line* ]]",
            "[[ $(bindkey -M viins '^O') == *edit-command-line* && $(bindkey '^X^E') == *edit-command-line* ]]",
            "(( $+functions[compdef] && $+functions[_fzf_complete] && $+functions[fzf-history-widget] ))",
            "(( $+functions[enable-fzf-tab] && $+functions[_zsh_autosuggest_start] && $+functions[_zsh_highlight] ))",
            "(( $+functions[history-substring-search-up] && $+functions[z] && $+functions[zi] ))",
            "[[ $(whence -w cd) == 'cd: builtin' ]]",
            "[[ $functions[ql] == *autoload* && $functions[rm.dstore] == *autoload* ]]",
            "[[ $_comps[ql] == _ql && $_comps[rm.dstore] == _rm.dstore && $_comps[cd] == _cd ]]",
        )
        command = "; ".join(f"{check} || print SC_FAIL:{index}" for index, check in enumerate(checks))
        result = shell.command(command + "; print SC_DONE")
        assert not re.search(r"\nSC_FAIL:", result), result
        result = shell.command("JUMPCLOUD_KEY='/dummy/key'; JUMPCLOUD_USER=dummy; ssh() { printf 'SC_ARG=%s\\n' \"$@\"; }; ssh -i $JUMPCLOUD_KEY $JUMPCLOUD_USER@server1; unfunction ssh; print SC_DONE")
        assert "SC_ARG=/dummy/key\nSC_ARG=dummy@server1" in result, result
        result = shell.command("source $ZDOTDIR/includes/paths.zsh; before=$PATH; source $ZDOTDIR/includes/paths.zsh; [[ $PATH == $before ]] || print SC_FAIL:path; print SC_DONE")
        assert "\nSC_FAIL:" not in result, result
        # Type a dummy command and verify that the highlighter runs in ZLE.
        result = shell.command("_sc_test_highlight() { print -r -- SC_REGIONS:${#region_highlight}; zle -M 'SC_HIGHLIGHT'; }; zle -N _sc_test_highlight; bindkey '^Xh' _sc_test_highlight; print SC_DONE")
        shell.output = b""
        os.write(shell.fd, b"echo dummy")
        shell.until(lambda data: bool(data))
        time.sleep(0.1)
        os.write(shell.fd, b"\x18h")
        shell.until(lambda data: b"SC_HIGHLIGHT" in data)
        assert re.search(r"SC_REGIONS:[1-9]", clean(shell.output)), clean(shell.output)
        shell.output = b""
        os.write(shell.fd, b"\x03")
        shell.until(lambda data: b"\x1b[?2004h" in data)
        shell.command("EDITOR='zsh '" + str(ROOT / "tests/fixtures/editor.zsh") + "; print SC_DONE")
        shell.output = b""
        os.write(shell.fd, b"echo original\x0f")
        shell.until(lambda data: b"SC_EDITOR" in data)
        shell.until(lambda data: "print SC_EDITED" in clean(data))
        os.write(shell.fd, b"\n")
        shell.until(lambda data: "\nSC_EDITED\n" in clean(data))
        shell.until(lambda data: b"\x1b[?2004h" in data)
        shell.command("command cp $ZDOTDIR/tests/fixtures/gnu-tool.zsh sc-fzf-choice; FZF_DEFAULT_OPTS='--filter=sc-fzf-choice'; print SC_DONE")
        shell.output = b""
        os.write(shell.fd, b"print -r -- **\t")
        shell.until(lambda data: b"sc-fzf-choice" in data)
        os.write(shell.fd, b"\n")
        shell.until(lambda data: "\nsc-fzf-choice\n" in clean(data))
        shell.until(lambda data: b"\x1b[?2004h" in data)
    finally:
        shell.close()
    assert list((home / "cache/zsh").glob("zcompdump-*.zwc")), "Missing compiled completion dump"
    warm = Shell(env, home)
    try:
        result = warm.command("[[ $_comps[ql] == _ql && $_comps[rm.dstore] == _rm.dstore && $_comps[cd] == _cd ]] || print SC_FAIL:warm-completion; print SC_DONE")
        assert "\nSC_FAIL:" not in result, result
    finally:
        warm.close()
    missing_env = dict(env, SC_PLUGIN_DIR=str(home / "uninstalled-plugins"))
    missing = Shell(missing_env, home)
    try:
        initial = clean(missing.output)
        assert "Missing plugin" in initial, initial
        assert not re.search(r"unhandled|definition file not found|can't change", initial, re.I), initial
        result = missing.command("[[ $+functions[compdef] == 1 && $(whence -w cd) == 'cd: builtin' ]] || print SC_FAIL:fallback; print SC_DONE")
        assert "\nSC_FAIL:" not in result, result
    finally:
        missing.close()
    # Noninteractive initialization must not load interactive plugins.
    result = subprocess.run([ZSH, "-d", "-c", "print $+functions[compdef]"], env=env,
                            capture_output=True, text=True, check=True)
    assert result.stdout.strip() == "0" and not result.stderr, result
    print("PASS: PTY startup, widgets, native cd, Zoxide, PATH, history, SSH arguments, and noninteractive guard")


def benchmark(home, repo, samples, personal=False, login=False, system_rc=False):
    env = environment(home, repo, personal)
    prompt, complete, following = [], [], []
    cold = None
    for iteration in range(samples + 1):
        shell = Shell(env, home, login, system_rc)
        try:
            if iteration == 0:
                cold = shell.first_prompt
            else:
                prompt.append(shell.first_prompt)
            while True:
                toolbox = " && ${TOOLBOX_LOADED:-0}" if personal else ""
                result = shell.command("if (( $+functions[_fzf_complete] && $+functions[z] + $+functions[__zoxide_z] && $+functions[enable-fzf-tab] && $+functions[_zsh_highlight]" + toolbox + " )); then print SC_READY; fi; print SC_DONE")
                if "\nSC_READY\n" in result:
                    break
                if time.perf_counter() - shell.started > 10:
                    raise AssertionError("Features did not become ready")
                time.sleep(0.1)
            if iteration:
                complete.append((time.perf_counter() - shell.started) * 1000)
            start = time.perf_counter()
            shell.command("print SC_DONE")
            if iteration:
                following.append((time.perf_counter() - start) * 1000)
        finally:
            shell.close()
    print(f"{repo.name} {'personal' if personal else 'core'} {'login' if login else 'interactive'} first run: {cold:.1f}ms")
    for label, values in [("first prompt", prompt), ("features confirmed", complete), ("following prompt", following)]:
        values.sort()
        print(f"{repo.name} {'personal' if personal else 'core'} {'login' if login else 'interactive'} {label}: median={statistics.median(values):.1f}ms p95={values[min(len(values)-1, int(len(values)*.95))]:.1f}ms")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--benchmark", action="store_true")
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--personal", action="store_true")
    parser.add_argument("--system-rc", action="store_true")
    parser.add_argument("--samples", type=int, default=10)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="sc-zsh-test-") as directory:
        home = Path(directory)
        if args.benchmark:
            for repo in ([args.baseline, ROOT] if args.baseline else [ROOT]):
                for login in [False, True]:
                    benchmark(home, repo, args.samples, args.personal, login, args.system_rc)
        else:
            functional(home)


if __name__ == "__main__":
    main()
