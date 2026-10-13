#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Test setup, doctor, and plugin repairs with local Git fixtures."""
import hashlib
import os
import shlex
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run(args, env, success=True):
    result = subprocess.run(args, env=env, text=True, capture_output=True)
    assert (result.returncode == 0) == success, result.stdout + result.stderr
    return result


def snapshot(directory):
    return {
        str(path.relative_to(directory)): (
            path.lstat().st_mtime_ns,
            path.lstat().st_mode,
            os.readlink(path) if path.is_symlink() else (
                hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
            ),
        )
        for path in directory.rglob("*")
    }


def main():
    with tempfile.TemporaryDirectory(prefix="sc-zsh-setup-") as temporary:
        base = Path(temporary).resolve()
        repo = base / "repo with spaces"
        home = base / "home with spaces"
        upstream = base / "upstream/plugin.git"
        repo.mkdir()
        home.mkdir()
        upstream.mkdir(parents=True)
        for file in [".zshenv", ".zshrc", "setup.sh", "doctor.sh", "VERSION"]:
            shutil.copy2(ROOT / file, repo / file)
        for folder in ["scripts", "includes"]:
            shutil.copytree(ROOT / folder, repo / folder)
        env = dict(os.environ)
        for key in list(env):
            if key.startswith(("SC_", "XDG_", "GIT_")) or key in ["ZDOTDIR", "FPATH", "ZPFX"]:
                env.pop(key, None)
        env.update(HOME=str(home), XDG_DATA_HOME=str(home / "custom data"),
                   XDG_CACHE_HOME=str(home / "custom cache"),
                   SC_USER_DIR=str(home / "custom user"),
                   SC_USER_FUNCTIONS_DIR=str(home / "custom functions"),
                   SC_USER_COMPLETIONS_DIR=str(home / "custom completions"),
                   SC_PLUGIN_DIR=str(home / "custom plugins"))
        run(["git", "init", "--quiet", str(upstream)], env)
        for key, value in [("user.name", "sc-zsh fixture"), ("user.email", "fixture@example.invalid"), ("commit.gpgsign", "false")]:
            run(["git", "-C", str(upstream), "config", key, value], env)
        revisions = []
        for number in [1, 2, 3]:
            (upstream / "fixture.plugin.zsh").write_text(f"# fixture revision {number}\n")
            run(["git", "-C", str(upstream), "add", "fixture.plugin.zsh"], env)
            run(["git", "-C", str(upstream), "commit", "--quiet", "-m", f"fixture {number}"], env)
            revisions.append(run(["git", "-C", str(upstream), "rev-parse", "HEAD"], env).stdout.strip())
        env.update(GIT_CONFIG_COUNT="1",
                   GIT_CONFIG_KEY_0=f"url.{(base / 'upstream').as_uri()}/.insteadOf",
                   GIT_CONFIG_VALUE_0="https://github.com/fixture/")

        def manifest(revision, entries=None):
            triples = entries or f"fixture fixture/plugin {revision}"
            (repo / "scripts/plugin-manifest.zsh").write_text(f"typeset -a SC_PLUGINS=( {triples} )\n")

        manifest(revisions[1])
        run(["bash", str(repo / "doctor.sh")], env, success=False)
        assert not list(home.iterdir()), "Doctor changed an unconfigured home"
        run(["bash", str(repo / "setup.sh"), "--skip-plugins"], env)
        assert (home / ".zshenv").resolve() == repo / ".zshenv"
        for phase in ["pre", "post"]:
            file = home / f".zshrc.local.{phase}"
            assert file.stat().st_mode & 0o777 == 0o600
            assert all(not line or line.startswith("#") for line in file.read_text().splitlines())
        for path in [env["SC_USER_DIR"], env["SC_USER_FUNCTIONS_DIR"], env["SC_USER_COMPLETIONS_DIR"]]:
            assert Path(path).is_dir(), path
        run(["bash", str(repo / "doctor.sh")], env, success=False)
        run(["bash", str(repo / "setup.sh")], env)
        plugin = Path(env["SC_PLUGIN_DIR"]) / "fixture"
        assert run(["git", "-C", str(plugin), "rev-parse", "HEAD"], env).stdout.strip() == revisions[1]
        assert run(["git", "-C", str(plugin), "rev-list", "--count", "HEAD"], env).stdout.strip() == "1"
        # Matching legacy checkouts are reusable even without a reachable remote.
        legacy = Path(env["XDG_DATA_HOME"]) / "zinit/plugins/fixture---plugin"
        legacy.parent.mkdir(parents=True)
        run(["git", "clone", "--quiet", "https://github.com/fixture/plugin.git", str(legacy)], env)
        run(["git", "-C", str(legacy), "checkout", "--quiet", "--detach", revisions[1]], env)
        legacy_before = snapshot(legacy)
        reuse_env = dict(env, SC_PLUGIN_DIR=str(home / "reused plugins"),
                         GIT_CONFIG_KEY_0=f"url.{(base / 'missing upstream').as_uri()}/.insteadOf")
        run(["zsh", "-df", str(repo / "scripts/plugins.zsh"), "install"], reuse_env)
        assert snapshot(legacy) == legacy_before, "Legacy migration modified its source"
        assert (home / "reused plugins/fixture/fixture.plugin.zsh").read_text() == "# fixture revision 2\n"
        before = snapshot(home)
        result = run(["bash", str(repo / "doctor.sh")], env)
        assert f"sc-zsh {(repo / 'VERSION').read_text().strip()} | Git: unavailable" in result.stdout
        assert snapshot(home) == before, "Doctor changed installed files"
        version_file = repo / "VERSION"
        original_version = version_file.read_text()
        version_file.write_text("invalid-version\n")
        run(["bash", str(repo / "doctor.sh")], env, success=False)
        version_file.unlink()
        run(["bash", str(repo / "doctor.sh")], env, success=False)
        version_file.write_text(original_version)

        signature = Path(env["XDG_CACHE_HOME"]) / "zsh/zcompdump-test.fpath"
        signature.write_text("preserve this cache signature\n")
        pre = home / ".zshrc.local.pre"
        pre.write_text('touch "$HOME/private-executed"\n')
        before = snapshot(home)
        run(["bash", str(repo / "setup.sh")], env)
        assert snapshot(home) == before, "Repeated setup changed installed files"
        run(["bash", str(repo / "doctor.sh")], env)
        assert snapshot(home) == before, "Doctor executed private configuration"

        # A relative but correct link must remain unchanged.
        link = home / ".zshenv"
        link.unlink()
        link.symlink_to(os.path.relpath(repo / ".zshenv", home))
        old_link = os.readlink(link)
        run(["bash", str(repo / "setup.sh")], env)
        assert os.readlink(link) == old_link
        # Preserve regular files and dangling links as backups before repair.
        link.unlink()
        link.write_text("# previous bootstrap\n")
        run(["bash", str(repo / "setup.sh")], env)
        assert any(file.read_text() == "# previous bootstrap\n" for file in home.glob(".zshenv.bak.*") if file.is_file())
        link.unlink()
        link.symlink_to("missing-bootstrap")
        run(["bash", str(repo / "setup.sh")], env)
        assert any(file.is_symlink() and os.readlink(file) == "missing-bootstrap" for file in home.glob(".zshenv.bak.*"))

        # Local changes must stop an upgrade and preserve both files and cache.
        manifest(revisions[2])
        entrypoint = plugin / "fixture.plugin.zsh"
        entrypoint.write_text("# local edits\n")
        run(["zsh", "-df", str(repo / "scripts/plugins.zsh"), "update"], env, success=False)
        assert entrypoint.read_text() == "# local edits\n" and signature.exists()
        entrypoint.write_text("# fixture revision 2\n")
        run(["zsh", "-df", str(repo / "scripts/plugins.zsh"), "update"], env)
        assert not signature.exists(), "Changed plugins did not invalidate completion data"
        assert run(["git", "-C", str(plugin), "rev-parse", "HEAD"], env).stdout.strip() == revisions[2]

        # Failed fetches must clean temporary checkouts without invalidating a no-op cache.
        manifest(revisions[2], f"missing fixture/missing {revisions[2]}")
        signature.write_text("preserve\n")
        run(["zsh", "-df", str(repo / "scripts/plugins.zsh"), "install"], env, success=False)
        assert signature.exists() and not list(Path(env["SC_PLUGIN_DIR"]).glob(".sc-zsh-plugin.*"))
        # An earlier successful change still needs invalidation if a later fetch fails.
        manifest(revisions[2], f"second fixture/plugin {revisions[2]} missing fixture/missing {revisions[2]}")
        run(["zsh", "-df", str(repo / "scripts/plugins.zsh"), "install"], env, success=False)
        assert not signature.exists() and not list(Path(env["SC_PLUGIN_DIR"]).glob(".sc-zsh-plugin.*"))

        # Validate paths and prerequisites before creating configuration files.
        clean_home = base / "fresh home"
        clean_home.mkdir()
        bad_env = dict(env, HOME=str(clean_home), XDG_CACHE_HOME="relative-cache")
        run(["bash", str(repo / "setup.sh")], bad_env, success=False)
        assert not list(clean_home.iterdir())

        missing_bin = base / "fake bin"
        missing_bin.mkdir()
        fake_zsh = missing_bin / "zsh"
        fake_zsh.write_text("#!/bin/sh\nexit 1\n")
        fake_zsh.chmod(0o755)
        bad_env = dict(env, HOME=str(clean_home), PATH=str(missing_bin) + os.pathsep + env["PATH"])
        run(["bash", str(repo / "setup.sh")], bad_env, success=False)
        assert not list(clean_home.iterdir())

        # A working Zsh without Git must fail before filesystem changes.
        real_zsh = shutil.which("zsh", path=env["PATH"])
        real_bash = shutil.which("bash", path=env["PATH"])
        fake_zsh.write_text(f"#!/bin/sh\nexec {shlex.quote(real_zsh)} \"$@\"\n")
        (missing_bin / "dirname").symlink_to(shutil.which("dirname", path=env["PATH"]))
        bad_env = dict(env, HOME=str(clean_home), PATH=str(missing_bin))
        result = run([real_bash, str(repo / "setup.sh")], bad_env, success=False)
        assert "Git is required" in result.stderr and not list(clean_home.iterdir())

        # Refuse invalid customization files, preserving the existing bootstrap.
        (clean_home / ".zshrc.local.pre").mkdir()
        old = clean_home / ".zshenv"
        old.write_text("# retain\n")
        run(["bash", str(repo / "setup.sh")], dict(env, HOME=str(clean_home)), success=False)
        assert old.read_text() == "# retain\n"
    print("PASS: setup repair, idempotence, custom paths, read-only doctor, pinned shallow fetches, and failure cleanup")


if __name__ == "__main__":
    main()
