#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
CLASSIFIER = REPO_ROOT / "scripts" / "manaloom_staged_ui_scope.py"
AFFECTS_UI = "AFFECTS_UI"
NOT_APPLICABLE = "N/A_UI_SOURCE_UNCHANGED_STAGED_SCOPE"
BOOTSTRAP = "BOOTSTRAP_STAGED_UI_SCOPE_CONTROL_PLANE"
OID = re.compile(r"[0-9a-f]{40}|[0-9a-f]{64}")
BOOTSTRAP_SOURCE_PATHS = {
    ".githooks/pre-commit",
    "AGENTS.md",
    "docs/MANALOOM_E2E_RELEASE_CONTRACT.md",
    "scripts/manaloom_local_ci.sh",
    "scripts/manaloom_staged_ui_scope.py",
    "server/test/local_ci_contract_test.dart",
    "server/test/local_ci_staged_scope_dispatcher_test.py",
    "server/test/staged_ui_scope_classifier_test.py",
}
BOOTSTRAP_GENERATED_PATHS = {
    "project_logic_manifest.json",
    "docs/generated/CURRENT_SYSTEM.md",
    "docs/generated/TASK_REGISTRY.json",
    "docs/generated/openapi.generated.json",
}


def digest_source(*roots: str) -> str:
    entries = "\n".join(f'  "{root}"' for root in roots)
    return f"""#!/usr/bin/env bash
set -euo pipefail

SOURCE_ROOTS=(
{entries}
)

printf '%s\\n' digest
"""


class GitFixture:
    def __init__(
        self, *, commit_base: bool = True, classifier_in_head: bool = True
    ) -> None:
        self._temporary = tempfile.TemporaryDirectory(
            prefix="manaloom-staged-ui-scope."
        )
        self.root = Path(self._temporary.name)
        self.git("init", "-q")
        self.git("symbolic-ref", "HEAD", "refs/heads/main")
        self.git("config", "user.name", "ManaLoom Test")
        self.git("config", "user.email", "manaloom-test@example.invalid")
        self.git("config", "core.hooksPath", ".git/hooks")
        self.write(
            "scripts/manaloom_ui_source_digest.sh",
            digest_source("app/lib", "app/web", "exact.file"),
        )
        self.write("app/lib/existing.dart", "base\n")
        self.write("docs/control.txt", "base\n")
        self.write("exact.file", "base\n")
        for path in sorted(BOOTSTRAP_SOURCE_PATHS - {str(CLASSIFIER.relative_to(REPO_ROOT))}):
            self.write(path, f"base {path}\n")
        if classifier_in_head:
            self.write("scripts/manaloom_staged_ui_scope.py", "base classifier\n")
        for path in sorted(BOOTSTRAP_GENERATED_PATHS):
            self.write(path, f"base {path}\n")
        if commit_base:
            self.git("add", "--all")
            self.git("commit", "-q", "--no-gpg-sign", "-m", "base")

    def close(self) -> None:
        self._temporary.cleanup()

    def environment(self, **overrides: str) -> dict[str, str]:
        environment = os.environ.copy()
        for key in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE"):
            environment.pop(key, None)
        environment.update(overrides)
        return environment

    def git(
        self,
        *arguments: str,
        environment: dict[str, str] | None = None,
        expected: int = 0,
    ) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            ["git", *arguments],
            cwd=self.root,
            env=environment or self.environment(),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if result.returncode != expected:
            raise AssertionError(
                f"git {' '.join(arguments)} returned {result.returncode}: "
                f"{result.stderr}"
            )
        return result

    def write(self, relative_path: str, contents: str) -> Path:
        path = self.root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding="utf-8")
        return path

    def classify(
        self, *, environment: dict[str, str] | None = None
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", str(CLASSIFIER)],
            cwd=self.root,
            env=environment or self.environment(),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def stage_bootstrap(self, *, omit: str | None = None, extra: str | None = None) -> None:
        for path in sorted(BOOTSTRAP_SOURCE_PATHS | BOOTSTRAP_GENERATED_PATHS):
            if path == omit:
                continue
            self.write(path, f"bootstrap {path}\n")
            self.git("add", "--", path)
        if extra is not None:
            self.write(extra, "unexpected\n")
            self.git("add", "--", extra)


class StagedUiScopeClassifierTest(unittest.TestCase):
    def fixture(
        self, *, commit_base: bool = True, classifier_in_head: bool = True
    ) -> GitFixture:
        fixture = GitFixture(
            commit_base=commit_base,
            classifier_in_head=classifier_in_head,
        )
        self.addCleanup(fixture.close)
        return fixture

    def assert_status(
        self,
        fixture: GitFixture,
        status: str,
        *,
        environment: dict[str, str] | None = None,
    ) -> tuple[str, str]:
        result = fixture.classify(environment=environment)
        self.assertEqual(result.returncode, 0, result.stderr)
        fields = result.stdout.rstrip("\n").split("\t")
        self.assertEqual(len(fields), 3, result.stdout)
        self.assertEqual(fields[0], status)
        self.assertTrue(fields[1] == "UNBORN" or OID.fullmatch(fields[1]))
        self.assertIsNotNone(OID.fullmatch(fields[2]))
        self.assertEqual(result.stderr, "")
        return fields[1], fields[2]

    def assert_fail_closed(
        self,
        fixture: GitFixture,
        *,
        environment: dict[str, str] | None = None,
    ) -> None:
        result = fixture.classify(environment=environment)
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stdout, "")
        self.assertIn("staged UI scope classification failed:", result.stderr)

    def test_exact_first_bootstrap_and_rejects_missing_or_extra_path(self) -> None:
        valid = self.fixture(classifier_in_head=False)
        valid.stage_bootstrap()
        self.assert_status(valid, BOOTSTRAP)

        missing = self.fixture(classifier_in_head=False)
        missing.stage_bootstrap(omit="AGENTS.md")
        self.assert_fail_closed(missing)

        extra = self.fixture(classifier_in_head=False)
        extra.stage_bootstrap(extra="docs/unexpected.txt")
        self.assert_fail_closed(extra)

    def test_post_bootstrap_scope_control_self_changes_require_ui(self) -> None:
        for path in sorted(BOOTSTRAP_SOURCE_PATHS):
            with self.subTest(path=path):
                fixture = self.fixture()
                fixture.write(path, f"changed {path}\n")
                fixture.git("add", "--", path)
                self.assert_status(fixture, AFFECTS_UI)

    def test_add_modify_delete_and_mixed_ui_changes_are_detected(self) -> None:
        cases = ("add", "modify", "delete", "mixed")
        for case in cases:
            with self.subTest(case=case):
                fixture = self.fixture()
                if case == "add":
                    fixture.write("app/lib/new.dart", "new\n")
                elif case == "modify":
                    fixture.write("app/lib/existing.dart", "modified\n")
                elif case == "delete":
                    (fixture.root / "app/lib/existing.dart").unlink()
                else:
                    fixture.write("docs/control.txt", "control changed\n")
                    fixture.write("app/web/index.html", "ui\n")
                fixture.git("add", "--all")
                self.assert_status(fixture, AFFECTS_UI)

    def test_type_change_and_renames_in_both_directions_cannot_hide_ui(self) -> None:
        type_fixture = self.fixture()
        typed_path = type_fixture.root / "app/lib/existing.dart"
        typed_path.unlink()
        os.symlink("replacement.dart", typed_path)
        type_fixture.git("add", "--all")
        self.assert_status(type_fixture, AFFECTS_UI)

        out_fixture = self.fixture()
        (out_fixture.root / "docs/renamed").mkdir(parents=True)
        out_fixture.git("mv", "app/lib/existing.dart", "docs/renamed/existing.dart")
        self.assert_status(out_fixture, AFFECTS_UI)

        in_fixture = self.fixture()
        in_fixture.git("mv", "docs/control.txt", "app/lib/moved-inside.dart")
        self.assert_status(in_fixture, AFFECTS_UI)

    def test_exact_file_prefix_boundary_and_special_names(self) -> None:
        exact = self.fixture()
        exact.write("exact.file", "changed\n")
        exact.git("add", "exact.file")
        self.assert_status(exact, AFFECTS_UI)

        boundary = self.fixture()
        boundary.write("exact.file.child", "outside\n")
        boundary.git("add", "--all")
        self.assert_status(boundary, NOT_APPLICABLE)

        directory_boundary = self.fixture()
        directory_boundary.write("app/library/not-ui.dart", "outside\n")
        directory_boundary.git("add", "--all")
        self.assert_status(directory_boundary, NOT_APPLICABLE)

        special = self.fixture()
        special.write("app/lib/line\nbreak.dart", "inside\n")
        special.git("add", "--all")
        self.assert_status(special, AFFECTS_UI)

    def test_alternate_index_is_authoritative(self) -> None:
        fixture = self.fixture()
        alternate_index = fixture.root / ".git/alternate.index"
        shutil.copy2(fixture.root / ".git/index", alternate_index)
        fixture.write("app/lib/alternate.dart", "alternate\n")
        alternate_environment = fixture.environment(GIT_INDEX_FILE=str(alternate_index))
        fixture.git(
            "add",
            "app/lib/alternate.dart",
            environment=alternate_environment,
        )
        self.assert_status(fixture, AFFECTS_UI, environment=alternate_environment)

    def test_old_and_new_source_root_union_is_behavioral(self) -> None:
        specification = importlib.util.spec_from_file_location(
            "manaloom_staged_ui_scope", CLASSIFIER
        )
        self.assertIsNotNone(specification)
        self.assertIsNotNone(specification.loader)
        module = importlib.util.module_from_spec(specification)
        specification.loader.exec_module(module)
        self.assertTrue(
            module.paths_affect_ui(
                [b"old/root/file.dart"], {b"old/root"}, {b"new/root"}
            )
        )
        self.assertTrue(
            module.paths_affect_ui(
                [b"new/root/file.dart"], {b"old/root"}, {b"new/root"}
            )
        )
        self.assertFalse(
            module.paths_affect_ui([b"other/file.dart"], {b"old/root"}, {b"new/root"})
        )

    def test_digest_index_and_worktree_divergence_fail_closed(self) -> None:
        index_bad = self.fixture()
        original = (index_bad.root / "scripts/manaloom_ui_source_digest.sh").read_text()
        index_bad.write("scripts/manaloom_ui_source_digest.sh", "SOURCE_ROOTS=(\n  $HOME\n)\n")
        index_bad.git("add", "scripts/manaloom_ui_source_digest.sh")
        index_bad.write("scripts/manaloom_ui_source_digest.sh", original)
        self.assert_fail_closed(index_bad)

        worktree_bad = self.fixture()
        worktree_bad.write(
            "scripts/manaloom_ui_source_digest.sh",
            digest_source("app/lib", "app/web", "exact.file") + "# valid staged\n",
        )
        worktree_bad.git("add", "scripts/manaloom_ui_source_digest.sh")
        worktree_bad.write("scripts/manaloom_ui_source_digest.sh", "SOURCE_ROOTS=(\n  $HOME\n)\n")
        self.assert_fail_closed(worktree_bad)

    def test_parser_rejects_ambiguous_or_unsafe_source_arrays(self) -> None:
        invalid_sources = {
            "duplicate-array": digest_source("app/lib")
            + "\nSOURCE_ROOTS=(\n  \"second\"\n)\n",
            "expansion": digest_source("$HOME/app"),
            "duplicate-root": digest_source("app/lib", "app/lib"),
            "unclosed": "SOURCE_ROOTS=(\n  \"app/lib\"\n",
            "glob": digest_source("app/*"),
            "comment-only": "SOURCE_ROOTS=(\n  # só comentário\n)\n",
            "trailing-comment": 'SOURCE_ROOTS=(\n  "app/lib" # no fim\n)\n',
        }
        for label, source in invalid_sources.items():
            with self.subTest(label=label):
                fixture = self.fixture()
                fixture.write("scripts/manaloom_ui_source_digest.sh", source)
                fixture.git("add", "scripts/manaloom_ui_source_digest.sh")
                self.assert_fail_closed(fixture)

    def test_parser_ignores_full_line_comments_like_bash(self) -> None:
        specification = importlib.util.spec_from_file_location(
            "manaloom_staged_ui_scope", CLASSIFIER
        )
        self.assertIsNotNone(specification)
        self.assertIsNotNone(specification.loader)
        module = importlib.util.module_from_spec(specification)
        specification.loader.exec_module(module)
        blob = (
            'SOURCE_ROOTS=(\n  "app/lib"\n  # comentário com "aspas" e )\n'
            '  "scripts/lib/pin.sh"\n)\n'
        ).encode("utf-8")
        self.assertEqual(
            module._parse_source_roots(blob, "fixture digest"),
            {b"app/lib", b"scripts/lib/pin.sh"},
        )
        # O script real do repositório tem comentário dentro do array desde
        # 2026-09-21 (pin do ChromeDriver); o parser precisa aceitá-lo.
        repo_digest = (REPO_ROOT / "scripts/manaloom_ui_source_digest.sh").read_bytes()
        roots = module._parse_source_roots(repo_digest, "repo digest")
        self.assertIn(b"scripts/lib/manaloom_chromedriver.sh", roots)
        self.assertIn(b"app/lib", roots)

    def test_partial_staging_and_untracked_worktree_fail_closed(self) -> None:
        partial = self.fixture()
        partial.write("scripts/manaloom_local_ci.sh", "staged version\n")
        partial.git("add", "scripts/manaloom_local_ci.sh")
        partial.write("scripts/manaloom_local_ci.sh", "unstaged version\n")
        self.assert_fail_closed(partial)

        untracked = self.fixture()
        untracked.write("untracked.txt", "not staged\n")
        self.assert_fail_closed(untracked)

    def test_unborn_head_fails_without_exact_bootstrap(self) -> None:
        unborn = self.fixture(commit_base=False)
        unborn.git("add", "--all")
        self.assert_fail_closed(unborn)

    def test_default_and_alternate_index_conflicts_fail_closed(self) -> None:
        conflict = self.fixture()
        conflict.write("conflict.txt", "base\n")
        conflict.git("add", "conflict.txt")
        conflict.git("commit", "-q", "--no-gpg-sign", "-m", "conflict base")
        conflict.git("switch", "-q", "-c", "other")
        conflict.write("conflict.txt", "other\n")
        conflict.git("add", "conflict.txt")
        conflict.git("commit", "-q", "--no-gpg-sign", "-m", "other")
        conflict.git("switch", "-q", "main")
        conflict.write("conflict.txt", "main\n")
        conflict.git("add", "conflict.txt")
        conflict.git("commit", "-q", "--no-gpg-sign", "-m", "main")
        conflict.git("merge", "other", expected=1)
        alternate_index = conflict.root / ".git/conflict.index"
        shutil.copy2(conflict.root / ".git/index", alternate_index)
        self.assert_fail_closed(conflict)
        conflict.git("merge", "--abort")
        self.assert_fail_closed(
            conflict,
            environment=conflict.environment(GIT_INDEX_FILE=str(alternate_index)),
        )

    def test_malformed_alternate_index_fails_closed(self) -> None:
        malformed = self.fixture()
        malformed_index = malformed.root / ".git/malformed.index"
        malformed_index.write_bytes(b"not-a-git-index")
        self.assert_fail_closed(
            malformed,
            environment=malformed.environment(GIT_INDEX_FILE=str(malformed_index)),
        )

    def test_source_contract_preserves_union_nul_diff_binding_and_identity(self) -> None:
        source = CLASSIFIER.read_text(encoding="utf-8")
        self.assertIn("old_roots | new_roots", source)
        self.assertIn('"--no-renames"', source)
        self.assertIn('"--cached"', source)
        self.assertIn('"-z"', source)
        self.assertIn('"write-tree"', source)
        self.assertIn("_verify_worktree_index_binding(root)", source)
        self.assertIn("BOOTSTRAP_PATHS - path_texts", source)
        self.assertNotIn("shell=True", source)


if __name__ == "__main__":
    unittest.main(verbosity=2)
