#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Exercise OSC 133 hooks in isolated real Zsh PTYs, without personal files."""
import errno
import os
from pathlib import Path
import pty
import re
import select
import shutil
import signal
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
OSC = b'\x1b]133;'


class Shell:
    def __init__(self, *, starship=False, rex=True, tmux=False):
        self.temp = tempfile.TemporaryDirectory(prefix='sc-rex-test-')
        folder = Path(self.temp.name)
        config = folder / 'starship.toml'
        config.write_text('add_newline = false\nformat = "$status CMD> "\n[status]\ndisabled = false\nformat = "$status"\n')
        init = f'eval "$({shutil.which("starship")} init zsh)"' if starship else "PROMPT=$'directory\\nCMD> '"
        rc = f'''{init}
source {str(ROOT / 'includes/rex_integration.zsh')!r}
source {str(ROOT / 'includes/rex_integration.zsh')!r}
'''
        (folder / '.zshrc').write_text(rc)
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            env = os.environ.copy()
            for key in ('REX_SERVER', 'REX_BLOCK', 'TMUX', 'GHOSTTY_RESOURCES_DIR', 'ZSH_EXECUTION_STRING'):
                env.pop(key, None)
            env.update(HOME=str(folder), ZDOTDIR=str(folder), STARSHIP_CONFIG=str(config), TERM='xterm-256color')
            if rex:
                env.update(REX_SERVER='test', REX_BLOCK='test')
            if tmux:
                env['TMUX'] = 'test'
            os.execve(shutil.which('zsh'), ['zsh', '-d', '-i'], env)
        self.active = rex and not tmux

    def read_until(self, marker, timeout=8):
        data = b''
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            ready, _, _ = select.select([self.fd], [], [], max(0, end - time.monotonic()))
            if ready:
                try:
                    chunk = os.read(self.fd, 65536)
                except OSError as error:
                    if error.errno == errno.EIO:
                        break
                    raise
                if not chunk:
                    break
                data += chunk
                if marker in data:
                    return data
        raise AssertionError(f'Missing marker {marker!r}: {data!r}')

    def prompt(self):
        return self.read_until(OSC + b'B\x07' if self.active else b'CMD> ')

    def command(self, command):
        os.write(self.fd, command.encode() + b'\n')
        return self.prompt()

    def close(self):
        # Only terminate the isolated child created by this test.
        try:
            os.kill(self.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        os.waitpid(self.pid, 0)
        os.close(self.fd)
        self.temp.cleanup()


class RexIntegrationTests(unittest.TestCase):
    def exercise(self, starship):
        shell = Shell(starship=starship)
        try:
            first = shell.prompt()
            self.assertEqual(first.count(OSC + b'A\x07'), 1)
            self.assertEqual(first.count(OSC + b'B\x07'), 1)
            for command, code in [('false', 1), ('true', 0), ("printf '%s\\n' \\\nmultiline", 0)]:
                data = shell.command(command)
                expected = [b'C', b'D;' + str(code).encode(), b'A', b'B']
                self.assertEqual(re.findall(rb'\x1b\]133;([^\x07]+)\x07', data), expected)
                if starship and code == 1:
                    plain = re.sub(rb'\x1b\[[0-9;?]*[A-Za-z]', b'', data)
                    self.assertIn(b'1 CMD>', plain)
            blank = shell.command('')
            self.assertNotIn(OSC + b'C\x07', blank)
            self.assertNotIn(OSC + b'D;', blank)
            self.assertEqual(blank.count(OSC + b'A\x07'), 1)
            os.write(shell.fd, b'sleep 30\n')
            shell.read_until(OSC + b'C\x07')
            # C is emitted before Zsh transfers terminal control to the job.
            deadline = time.monotonic() + 2
            while os.tcgetpgrp(shell.fd) == shell.pid:
                if time.monotonic() > deadline:
                    self.fail('Zsh did not hand the terminal to sleep')
                time.sleep(0.01)
            os.write(shell.fd, b'\x03')
            interrupted = shell.prompt()
            self.assertIn(OSC + b'D;130\x07', interrupted)
        finally:
            shell.close()

    def test_plain_multiline_prompt(self):
        self.exercise(False)

    @unittest.skipUnless(shutil.which('starship'), 'Starship not installed')
    def test_starship_status_and_markers(self):
        self.exercise(True)

    def test_other_terminal_unchanged(self):
        shell = Shell(rex=False)
        try:
            self.assertNotIn(OSC, shell.prompt())
            self.assertNotIn(OSC, shell.command('true'))
        finally:
            shell.close()

    def test_nested_tmux_unchanged(self):
        shell = Shell(tmux=True)
        try:
            self.assertNotIn(OSC, shell.prompt())
            self.assertNotIn(OSC, shell.command('true'))
        finally:
            shell.close()


if __name__ == '__main__':
    unittest.main()
