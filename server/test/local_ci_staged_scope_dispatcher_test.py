#!/usr/bin/env python3
from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
LOCAL_CI = REPO_ROOT / "scripts" / "manaloom_local_ci.sh"
CLASSIFIER = REPO_ROOT / "scripts" / "manaloom_staged_ui_scope.py"


def digest_source() -> str:
    return """#!/usr/bin/env bash
set -euo pipefail
SOURCE_ROOTS=(
  "app/lib"
)
printf '%s\\n' digest
"""


class LocalCiFixture:
    _BASH_CONTRACT_PATHS = {
        ".githooks/pre-push",
        "scripts/manaloom_e2e_suite.sh",
        "scripts/quality_gate.sh",
        "scripts/manaloom_ui_live_evidence_gate.sh",
        "scripts/manaloom_tbls_local_gate.sh",
        "scripts/manaloom_install_local_hooks.sh",
        "scripts/manaloom_external_engine_delta_weekly.sh",
        "scripts/manaloom_install_external_engine_delta_schedule.sh",
        "scripts/manaloom_xmage_pin_transition_audit.sh",
        "services/xmage-sidecar/bin/verify_product_scope_semantic_tests.sh",
    }

    def __init__(self) -> None:
        self._temporary = tempfile.TemporaryDirectory(
            prefix="manaloom-local-ci-dispatcher."
        )
        self.root = Path(self._temporary.name)
        self.git("init", "-q")
        self.git("symbolic-ref", "HEAD", "refs/heads/main")
        self.git("config", "user.name", "ManaLoom Test")
        self.git("config", "user.email", "manaloom-test@example.invalid")
        self.git("config", "core.hooksPath", ".git/hooks")

        self.write("scripts/manaloom_local_ci.sh", LOCAL_CI.read_text())
        self.write("scripts/manaloom_staged_ui_scope.py", CLASSIFIER.read_text())
        self.write("scripts/manaloom_ui_source_digest.sh", digest_source())
        self.write(
            ".githooks/pre-commit",
            (REPO_ROOT / ".githooks/pre-commit").read_text(),
        )
        self.write("AGENTS.md", "dispatcher fixture\n")
        self.write("docs/MANALOOM_E2E_RELEASE_CONTRACT.md", "dispatcher fixture\n")
        self.write("server/test/local_ci_contract_test.dart", "void main() {}\n")
        self.write(
            "server/test/staged_ui_scope_classifier_test.py",
            "raise SystemExit(0)\n",
        )
        self.write(
            "server/test/local_ci_staged_scope_dispatcher_test.py",
            "raise SystemExit(0)\n",
        )
        self.write("project_logic_manifest.json", "{}\n")
        self.write("docs/generated/CURRENT_SYSTEM.md", "fixture\n")
        self.write("docs/generated/TASK_REGISTRY.json", "{}\n")
        self.write("docs/generated/openapi.generated.json", "{}\n")
        self.write("app/lib/existing.dart", "base\n")
        self.write("docs/control.txt", "base\n")
        self.write("docs/mutate.txt", "base\n")

        for path in self._BASH_CONTRACT_PATHS:
            self.write(path, "#!/usr/bin/env bash\nexit 0\n")
        self.write(
            "scripts/manaloom_ui_live_evidence_gate.sh",
            """#!/usr/bin/env bash
set -euo pipefail
printf 'ui\\n' >>"$MANALOOM_TEST_CALL_LOG"
""",
        )
        self.write(
            "scripts/manaloom_secret_scan.sh",
            """#!/usr/bin/env bash
set -euo pipefail
if [[ "${MANALOOM_TEST_MUTATE_INDEX:-0}" == "1" ]]; then
  root="$(git rev-parse --show-toplevel)"
  printf 'mutated\\n' >"$root/docs/mutate.txt"
  git -C "$root" add -- docs/mutate.txt
fi
""",
        )
        self.write(
            "scripts/manaloom_dart_mcp_preflight.sh",
            "#!/usr/bin/env bash\nexit 0\n",
        )
        self.write(
            "scripts/manaloom_project_logic.sh",
            "#!/usr/bin/env bash\nexit 0\n",
        )
        self.write(
            "scripts/lib/manaloom_dart_toolchain.sh",
            """resolve_manaloom_dart() {
  MANALOOM_DART_BIN_RESOLVED="$MANALOOM_TEST_DART_BIN"
}
""",
        )
        self.write(
            "docs/hermes-analysis/manaloom-knowledge/scripts/sync_game_changers_to_dart.py",
            "raise SystemExit(0)\n",
        )
        (self.root / "tools/project_logic").mkdir(parents=True, exist_ok=True)

        for script in self.root.rglob("*.sh"):
            script.chmod(0o755)
        for hook in (self.root / ".githooks").iterdir():
            hook.chmod(0o755)

        self.bin_dir = self.root / ".git/test-bin"
        self.bin_dir.mkdir(parents=True)
        for name in ("node", "flutter", "dart"):
            path = self.bin_dir / name
            path.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
            path.chmod(0o755)
        self.call_log = self.root / ".git/ui-calls.log"
        self.call_log.write_text("", encoding="utf-8")

        self.git("add", "--all")
        self.git("commit", "-q", "--no-gpg-sign", "-m", "base")

    def close(self) -> None:
        self._temporary.cleanup()

    def write(self, relative_path: str, contents: str) -> Path:
        path = self.root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding="utf-8")
        return path

    def git(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            ["git", *arguments],
            cwd=self.root,
            env=self.environment(),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if result.returncode != 0:
            raise AssertionError(
                f"git {' '.join(arguments)} returned {result.returncode}: {result.stderr}"
            )
        return result

    def environment(self, **overrides: str) -> dict[str, str]:
        environment = os.environ.copy()
        for key in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE"):
            environment.pop(key, None)
        if hasattr(self, "bin_dir"):
            environment.update(
                {
                    "MANALOOM_NODE_BIN": str(self.bin_dir / "node"),
                    "MANALOOM_FLUTTER_BIN": str(self.bin_dir / "flutter"),
                    "MANALOOM_TEST_DART_BIN": str(self.bin_dir / "dart"),
                    "MANALOOM_TEST_CALL_LOG": str(self.call_log),
                    "PATH": f"{self.bin_dir}:{environment['PATH']}",
                }
            )
        environment.update(overrides)
        return environment

    def stage(self, path: str, contents: str) -> None:
        self.write(path, contents)
        self.git("add", "--", path)

    def run(
        self, *arguments: str, **environment_overrides: str
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["/bin/bash", "scripts/manaloom_local_ci.sh", *arguments],
            cwd=self.root,
            env=self.environment(**environment_overrides),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def ui_call_count(self) -> int:
        return len(self.call_log.read_text(encoding="utf-8").splitlines())


class LocalCiStagedScopeDispatcherTest(unittest.TestCase):
    def fixture(self) -> LocalCiFixture:
        fixture = LocalCiFixture()
        self.addCleanup(fixture.close)
        return fixture

    def test_manual_quick_runs_ui_once(self) -> None:
        fixture = self.fixture()
        result = fixture.run("quick")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(fixture.ui_call_count(), 1)
        self.assertIn("PASS: gate local", result.stdout)

    def test_staged_non_ui_runs_ui_zero_times_and_has_non_credit_terminal(self) -> None:
        fixture = self.fixture()
        fixture.stage("docs/control.txt", "changed\n")
        result = fixture.run("quick", "--staged-scope")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(fixture.ui_call_count(), 0)
        self.assertNotIn("PASS: gate local", result.stdout)
        terminal = [line for line in result.stdout.splitlines() if line][-1]
        self.assertIn('"status":"ACCEPTED_STAGED_NON_UI_SCOPE"', terminal)
        self.assertIn('"commit_gate_only":true', terminal)
        self.assertIn('"ui_pass_claimed":false', terminal)
        self.assertIn('"local_completion_credit":false', terminal)
        self.assertIn('"release_credit":false', terminal)

    def test_staged_ui_runs_ui_once(self) -> None:
        fixture = self.fixture()
        fixture.stage("app/lib/existing.dart", "changed\n")
        result = fixture.run("quick", "--staged-scope")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(fixture.ui_call_count(), 1)
        self.assertIn('"status":"AFFECTS_UI"', result.stdout)
        self.assertIn("PASS: gate local", result.stdout)

    def test_invalid_scope_arguments_return_two(self) -> None:
        for arguments in (
            ("quick", "--invalid"),
            ("full", "--staged-scope"),
            ("quick", "--staged-scope", "extra"),
        ):
            with self.subTest(arguments=arguments):
                fixture = self.fixture()
                result = fixture.run(*arguments)
                self.assertEqual(result.returncode, 2)

    def test_index_change_during_gate_fails_before_acceptance(self) -> None:
        fixture = self.fixture()
        fixture.stage("docs/control.txt", "changed\n")
        result = fixture.run(
            "quick", "--staged-scope", MANALOOM_TEST_MUTATE_INDEX="1"
        )
        self.assertEqual(result.returncode, 2)
        self.assertNotIn("ACCEPTED_STAGED_NON_UI_SCOPE", result.stdout)
        self.assertIn("mudou durante o gate", result.stderr)

    def test_worktree_index_divergence_fails_before_any_gate(self) -> None:
        fixture = self.fixture()
        fixture.stage("docs/control.txt", "staged\n")
        fixture.write("docs/control.txt", "unstaged\n")
        result = fixture.run("quick", "--staged-scope")
        self.assertEqual(result.returncode, 2)
        self.assertEqual(fixture.ui_call_count(), 0)
        self.assertNotIn("ACCEPTED_STAGED_NON_UI_SCOPE", result.stdout)
        self.assertIn("tracked worktree bytes differ", result.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
