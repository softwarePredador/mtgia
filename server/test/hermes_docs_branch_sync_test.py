#!/usr/bin/env python3
"""Regression tests for Hermes docs branch sync workspace restoration."""

from __future__ import annotations

import os
import subprocess
import tempfile
import time
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "bin" / "hermes_docs_branch_sync.sh"


def _run(
    args: list[str],
    *,
    cwd: Path,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        cwd=str(cwd),
        env={**os.environ, **(env or {})},
        text=True,
        capture_output=True,
        check=False,
    )


def _git(cwd: Path, *args: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    result = _run(["git", *args], cwd=cwd, env=env)
    if result.returncode != 0:
        raise AssertionError(
            f"git {' '.join(args)} failed in {cwd}\nstdout={result.stdout}\nstderr={result.stderr}"
        )
    return result


def _git_output(cwd: Path, *args: str, env: dict[str, str] | None = None) -> str:
    return _git(cwd, *args, env=env).stdout.strip()


class HermesDocsBranchSyncTest(unittest.TestCase):
    def _seed_remote(self, root: Path, *, advance_master: bool) -> tuple[Path, Path]:
        remote = root / "remote.git"
        seed = root / "seed"
        work = root / "work"

        _git(root, "init", "--bare", str(remote))
        _git(root, "clone", str(remote), str(seed))

        git_env = {
            "GIT_AUTHOR_NAME": "Test Bot",
            "GIT_AUTHOR_EMAIL": "test@example.com",
            "GIT_COMMITTER_NAME": "Test Bot",
            "GIT_COMMITTER_EMAIL": "test@example.com",
        }

        (seed / "README.md").write_text("master v1\n", encoding="utf-8")
        _git(seed, "add", "README.md")
        _git(seed, "commit", "-m", "initial master", env=git_env)
        _git(seed, "push", "origin", "HEAD:master")

        _git(seed, "checkout", "-b", "codex/hermes-analysis-docs")
        docs_dir = seed / "docs" / "hermes-analysis"
        docs_dir.mkdir(parents=True, exist_ok=True)
        (docs_dir / "PROJECT_MEMORY.md").write_text("docs branch\n", encoding="utf-8")
        _git(seed, "add", "docs/hermes-analysis/PROJECT_MEMORY.md")
        _git(seed, "commit", "-m", "docs branch seed", env=git_env)
        _git(seed, "push", "origin", "HEAD:codex/hermes-analysis-docs")

        if advance_master:
            _git(seed, "checkout", "master")
            (seed / "CHANGELOG.md").write_text("master v2\n", encoding="utf-8")
            _git(seed, "add", "CHANGELOG.md")
            _git(seed, "commit", "-m", "advance master", env=git_env)
            _git(seed, "push", "origin", "HEAD:master")

        _git(root, "clone", str(remote), str(work))
        _git(work, "checkout", "master")
        return remote, work

    def _script_env(self, root: Path, work: Path) -> dict[str, str]:
        return {
            "MANALOOM_WORKSPACE": str(work),
            "HERMES_STATE_DIR": str(root / "state"),
            "HERMES_DOCS_SYNC_REPORT_DIR": str(root / "reports"),
            "HERMES_DOCS_SYNC_ALLOW_ROOT": "1",
            "HERMES_GIT_REMOTE": "origin",
            "HERMES_MASTER_BRANCH": "master",
            "HERMES_DOCS_BRANCH": "codex/hermes-analysis-docs",
            "HERMES_REPO_REF": "master",
            "GIT_AUTHOR_NAME": "Test Bot",
            "GIT_AUTHOR_EMAIL": "test@example.com",
            "GIT_COMMITTER_NAME": "Test Bot",
            "GIT_COMMITTER_EMAIL": "test@example.com",
        }

    def test_restores_master_after_dry_run(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, work = self._seed_remote(root, advance_master=True)
            env = self._script_env(root, work)
            env["HERMES_DOCS_SYNC_DRY_RUN"] = "1"
            env["HERMES_DOCS_SYNC_PUSH"] = "0"

            result = _run(["bash", str(SCRIPT)], cwd=work, env=env)
            self.assertEqual(result.returncode, 0, msg=result.stderr)
            self.assertEqual(_git_output(work, "branch", "--show-current"), "master")

            report = max((root / "reports").glob("docs_branch_sync_*.md"))
            report_text = report.read_text(encoding="utf-8")
            self.assertIn("status: would_merge", report_text)
            self.assertIn("origin/master", report_text)

    def test_restores_master_after_merge_without_push(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, work = self._seed_remote(root, advance_master=True)
            env = self._script_env(root, work)
            env["HERMES_DOCS_SYNC_DRY_RUN"] = "0"
            env["HERMES_DOCS_SYNC_PUSH"] = "0"

            result = _run(["bash", str(SCRIPT)], cwd=work, env=env)
            self.assertEqual(result.returncode, 0, msg=result.stderr)
            self.assertEqual(_git_output(work, "branch", "--show-current"), "master")

            report = max((root / "reports").glob("docs_branch_sync_*.md"))
            report_text = report.read_text(encoding="utf-8")
            self.assertIn("status: merged", report_text)

            ancestor = _run(
                ["git", "merge-base", "--is-ancestor", "origin/master", "codex/hermes-analysis-docs"],
                cwd=work,
            )
            self.assertEqual(ancestor.returncode, 0, msg=ancestor.stderr)

    def test_recovers_diverged_local_docs_branch_by_resetting_to_remote(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, work = self._seed_remote(root, advance_master=True)
            env = self._script_env(root, work)
            env["HERMES_DOCS_SYNC_DRY_RUN"] = "0"
            env["HERMES_DOCS_SYNC_PUSH"] = "0"

            first = _run(["bash", str(SCRIPT)], cwd=work, env=env)
            self.assertEqual(first.returncode, 0, msg=first.stderr)
            _git(work, "checkout", "codex/hermes-analysis-docs")
            local_only = work / "docs" / "hermes-analysis" / "LOCAL_ONLY.md"
            local_only.write_text("must not be pushed\n", encoding="utf-8")
            _git(work, "add", "docs/hermes-analysis/LOCAL_ONLY.md")
            _git(work, "commit", "-m", "local only docs state")
            local_docs_sha = _git_output(work, "rev-parse", "codex/hermes-analysis-docs")
            _git(work, "checkout", "master")
            remote_docs_sha = _git_output(work, "rev-parse", "origin/codex/hermes-analysis-docs")
            self.assertNotEqual(local_docs_sha, remote_docs_sha)

            env["HERMES_DOCS_SYNC_PUSH"] = "1"
            second = _run(["bash", str(SCRIPT)], cwd=work, env=env)
            self.assertEqual(second.returncode, 0, msg=second.stderr)
            self.assertEqual(_git_output(work, "branch", "--show-current"), "master")

            _git(work, "fetch", "origin", "codex/hermes-analysis-docs")
            pushed_docs_sha = _git_output(work, "rev-parse", "origin/codex/hermes-analysis-docs")
            self.assertNotEqual(pushed_docs_sha, local_docs_sha)
            remote_show = _run(
                [
                    "git",
                    "show",
                    "origin/codex/hermes-analysis-docs:docs/hermes-analysis/LOCAL_ONLY.md",
                ],
                cwd=work,
            )
            self.assertNotEqual(remote_show.returncode, 0)
            self.assertEqual(
                _run(
                    [
                        "git",
                        "merge-base",
                        "--is-ancestor",
                        "origin/master",
                        "origin/codex/hermes-analysis-docs",
                    ],
                    cwd=work,
                ).returncode,
                0,
            )

            report = max((root / "reports").glob("docs_branch_sync_*.md"))
            report_text = report.read_text(encoding="utf-8")
            self.assertIn("status: merged", report_text)

    def test_quarantines_untracked_files_before_branch_sync(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, work = self._seed_remote(root, advance_master=True)
            env = self._script_env(root, work)
            env["HERMES_DOCS_SYNC_DRY_RUN"] = "1"
            env["HERMES_DOCS_SYNC_PUSH"] = "0"

            generated_report = (
                work
                / "docs"
                / "hermes-analysis"
                / "master_optimizer_reports"
                / "generated.md"
            )
            generated_report.parent.mkdir(parents=True, exist_ok=True)
            generated_report.write_text("generated artifact\n", encoding="utf-8")
            loose_script = work / "server" / "bin" / "patch_slot_optimizer.py"
            loose_script.parent.mkdir(parents=True, exist_ok=True)
            loose_script.write_text("print('old scratch')\n", encoding="utf-8")

            result = _run(["bash", str(SCRIPT)], cwd=work, env=env)
            self.assertEqual(result.returncode, 0, msg=result.stderr)
            self.assertEqual(_git_output(work, "branch", "--show-current"), "master")
            self.assertFalse(generated_report.exists())
            self.assertFalse(loose_script.exists())

            quarantine_dirs = list((root / "reports").glob("untracked_quarantine_*"))
            self.assertEqual(len(quarantine_dirs), 1)
            quarantine_dir = quarantine_dirs[0]
            self.assertTrue(
                (
                    quarantine_dir
                    / "docs"
                    / "hermes-analysis"
                    / "master_optimizer_reports"
                    / "generated.md"
                ).exists()
            )
            self.assertTrue(
                (quarantine_dir / "server" / "bin" / "patch_slot_optimizer.py").exists()
            )

            report = max((root / "reports").glob("docs_branch_sync_*.md"))
            report_text = report.read_text(encoding="utf-8")
            self.assertIn("status: would_merge", report_text)
            self.assertIn("Quarantined 2 untracked file(s)", report_text)

    def test_reports_missing_github_push_token_without_hanging(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, work = self._seed_remote(root, advance_master=True)
            env = self._script_env(root, work)
            env["HERMES_DOCS_SYNC_PUSH"] = "1"
            env.pop("HERMES_GITHUB_TOKEN", None)
            env.pop("GITHUB_TOKEN", None)
            env.pop("GH_TOKEN", None)
            _git(work, "remote", "set-url", "--push", "origin", "https://github.com/softwarePredador/mtgia.git")

            result = _run(["bash", str(SCRIPT)], cwd=work, env=env)
            self.assertEqual(result.returncode, 0, msg=result.stderr)
            self.assertEqual(_git_output(work, "branch", "--show-current"), "master")

            report = max((root / "reports").glob("docs_branch_sync_*.md"))
            report_text = report.read_text(encoding="utf-8")
            self.assertIn("status: would_merge_push_token_missing", report_text)
            self.assertIn("HERMES_GITHUB_TOKEN", report_text)

    def test_recovers_stale_lock_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, work = self._seed_remote(root, advance_master=True)
            env = self._script_env(root, work)
            env["HERMES_DOCS_SYNC_DRY_RUN"] = "1"
            env["HERMES_DOCS_SYNC_PUSH"] = "0"
            env["HERMES_DOCS_SYNC_STALE_LOCK_SECONDS"] = "1"
            lock_dir = root / "state" / "docs_branch_sync.lock"
            lock_dir.mkdir(parents=True)
            old = time.time() - 60
            os.utime(lock_dir, (old, old))

            result = _run(["bash", str(SCRIPT)], cwd=work, env=env)
            self.assertEqual(result.returncode, 0, msg=result.stderr)
            self.assertEqual(_git_output(work, "branch", "--show-current"), "master")
            self.assertFalse(lock_dir.exists())

            report = max((root / "reports").glob("docs_branch_sync_*.md"))
            report_text = report.read_text(encoding="utf-8")
            self.assertIn("status: would_merge", report_text)

    def test_blocks_tracked_modifications(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, work = self._seed_remote(root, advance_master=True)
            env = self._script_env(root, work)
            env["HERMES_DOCS_SYNC_PUSH"] = "0"
            (work / "README.md").write_text("local uncommitted edit\n", encoding="utf-8")

            result = _run(["bash", str(SCRIPT)], cwd=work, env=env)
            self.assertEqual(result.returncode, 2)
            self.assertEqual(_git_output(work, "branch", "--show-current"), "master")

            report = max((root / "reports").glob("docs_branch_sync_*.md"))
            report_text = report.read_text(encoding="utf-8")
            self.assertIn("status: blocked_dirty_worktree", report_text)
            self.assertIn("tracked uncommitted changes", report_text)

    def test_uses_github_token_for_push_url_without_printing_secret(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            remote, work = self._seed_remote(root, advance_master=False)
            env = self._script_env(root, work)
            env["HERMES_DOCS_SYNC_DRY_RUN"] = "1"
            env["HERMES_DOCS_SYNC_PUSH"] = "0"
            env["HERMES_GITHUB_TOKEN"] = "ghp_test_secret_value"
            _git(work, "remote", "set-url", "origin", "git@github.com:softwarePredador/mtgia.git")
            _git(work, "remote", "set-url", "--push", "origin", str(remote))

            result = _run(["bash", str(SCRIPT)], cwd=work, env=env)
            self.assertEqual(result.returncode, 0, msg=result.stderr)
            push_url = _git_output(work, "remote", "get-url", "--push", "origin")
            self.assertEqual(
                push_url,
                "https://x-access-token:ghp_test_secret_value@github.com/softwarePredador/mtgia.git",
            )

            report = max((root / "reports").glob("docs_branch_sync_*.md"))
            report_text = report.read_text(encoding="utf-8")
            self.assertNotIn("ghp_test_secret_value", report_text)


if __name__ == "__main__":
    unittest.main()
