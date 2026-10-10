#!/usr/bin/env python3
"""BT-GATE-001/002/003: contrato do `local_ci` estrito.

Roda o `scripts/manaloom_local_ci.sh` real num repositório descartável, com as
etapas trocadas por dublês. Cada regra tem um teste:

- skip/PARTIAL numa etapa nunca vira sucesso (exit 3) e BLOCKED vira exit 2;
- cada etapa nomeada grava o receipt forte (SHA, tree, digest, resultado);
- o receipt só diz PASS se todo o catálogo passou no mesmo SHA;
- o gate Deck/IA/Learning roda uma vez no full e no release, reaproveitando as
  fatias do local_ci, e o release exige o receipt do PG de produção.

Nada aqui abre rede nem lê credencial. O mutador fica em
`local_ci_strict_gate_mutation_test.py`.
"""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[1]


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


dispatcher = _load("local_ci_dispatcher_fixture", HERE / "local_ci_staged_scope_dispatcher_test.py")
receipt_tool = _load(
    "manaloom_gate_run_receipt_for_strict_test",
    REPO_ROOT / "scripts" / "manaloom_gate_run_receipt.py",
)

# Dublê de quality_gate.sh: registra a chamada e, no modo deck-ai-learning,
# exerce o reaproveitamento real contra o ledger do local_ci.
QUALITY_GATE_DOUBLE = """#!/usr/bin/env bash
set -euo pipefail
printf '%s|%s|reuse=%s\\n' "$1" "${2:-}" "${MANALOOM_GATE_REUSE_STEPS:-}" >>"$MANALOOM_TEST_GATE_CALLS"
case "$1" in
  deck-ai-learning)
    if [[ "${MANALOOM_TEST_DECK_BEHAVIOR:-pass}" == "blocked" ]]; then
      echo "BLOCKED: MANALOOM_DECK_AI_RELEASE_RECEIPT must point to a readable canonical v2 receipt"
      exit 2
    fi
    root="$(git rev-parse --show-toplevel)"
    for pair in "project_logic.drift_check:project-logic,full-quality" \\
                "audit.operational_surface_alignment:guardrail-audits"; do
      slice="${pair%%:*}"
      candidates="${pair#*:}"
      if used="$(python3 "$root/scripts/manaloom_gate_run_receipt.py" reuse \\
          --repo "$root" --steps "$MANALOOM_GATE_REUSE_STEPS" --check "$candidates")"; then
        printf 'REUSED %s from %s\\n' "$slice" "$used"
        printf '%s|reused|%s\\n' "$slice" "$used" >>"$MANALOOM_TEST_GATE_CALLS"
      else
        printf '%s|ran\\n' "$slice" >>"$MANALOOM_TEST_GATE_CALLS"
      fi
    done
    ;;
  e2e)
    exit "${MANALOOM_TEST_E2E_EXIT:-0}"
    ;;
esac
exit 0
"""


class StrictFixture(dispatcher.LocalCiFixture):
    def __init__(self) -> None:
        super().__init__()
        self.gate_calls = self.root / ".git" / "gate-calls.log"
        self.gate_calls.write_text("", encoding="utf-8")
        self.write("scripts/quality_gate.sh", QUALITY_GATE_DOUBLE)
        (self.root / "scripts/quality_gate.sh").chmod(0o755)
        self.git("add", "--all")
        self.git("commit", "-q", "--no-gpg-sign", "-m", "strict doubles")
        self.pg_receipt = self.root.parent / f"{self.root.name}.pg-receipt.json"
        self.pg_env = self.root.parent / f"{self.root.name}.server.env"
        self.pg_receipt.write_text("{}\n", encoding="utf-8")
        self.pg_env.write_text("# fixture, sem segredo\n", encoding="utf-8")

    def close(self) -> None:
        super().close()
        self.pg_receipt.unlink(missing_ok=True)
        self.pg_env.unlink(missing_ok=True)

    def environment(self, **overrides: str) -> dict[str, str]:
        environment = super().environment(**overrides)
        if hasattr(self, "gate_calls"):
            environment["MANALOOM_TEST_GATE_CALLS"] = str(self.gate_calls)
        return environment

    def release_env(self) -> dict[str, str]:
        return {
            "MANALOOM_DECK_AI_RELEASE_RECEIPT": str(self.pg_receipt),
            "MANALOOM_NEW_SERVER_ENV": str(self.pg_env),
        }

    def calls(self) -> list[str]:
        return [line for line in self.gate_calls.read_text(encoding="utf-8").splitlines() if line]

    def receipt(self) -> dict:
        found = self.receipts()
        assert len(found) == 1, found
        return json.loads(found[0].read_text(encoding="utf-8"))


class LocalCiStrictGateTest(unittest.TestCase):
    def fixture(self) -> StrictFixture:
        fixture = StrictFixture()
        self.addCleanup(fixture.close)
        return fixture

    # --- BT-GATE-001: skip e BLOCKED -------------------------------------

    def test_skip_marker_in_a_step_is_partial_exit_3_never_pass(self) -> None:
        fixture = self.fixture()
        result = fixture.run("full", MANALOOM_TEST_QUALITY_BEHAVIOR="skip_marker")
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertNotIn("PASS: gate local", result.stdout)
        self.assertIn("PARTIAL", result.stderr)
        receipt = fixture.receipt()
        self.assertEqual(receipt["status"], "PARTIAL")
        self.assertFalse(receipt["gate_eligible"])
        by_id = {check["id"]: check["status"] for check in receipt["checks"]}
        self.assertEqual(by_id["full-quality"], "PARTIAL")
        # PARTIAL é inventariado e o gate segue: o resto do full rodou.
        self.assertEqual(by_id["schema-gate"], "PASS")
        self.assertEqual(receipt["summary"]["partial"], 1)

    def test_uninventoried_test_skip_counter_is_partial(self) -> None:
        fixture = self.fixture()
        result = fixture.run("full", MANALOOM_TEST_QUALITY_BEHAVIOR="skip_counter")
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertNotIn("PASS: gate local", result.stdout)

    def test_blocked_marker_with_zero_exit_is_blocked_not_success(self) -> None:
        fixture = self.fixture()
        result = fixture.run("full", MANALOOM_TEST_QUALITY_BEHAVIOR="blocked_marker")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertNotIn("PASS: gate local", result.stdout)
        receipt = fixture.receipt()
        self.assertEqual(receipt["status"], "BLOCKED")
        # BLOCKED encerra o gate: nada depois de full-quality rodou.
        self.assertEqual(receipt["checks"][-1]["id"], "full-quality")
        self.assertEqual(fixture.calls(), [])

    def test_step_exit_codes_map_to_blocked_partial_and_fail(self) -> None:
        for behavior, expected, status in (
            ("exit2", 2, "BLOCKED"),
            ("exit3", 3, "PARTIAL"),
            ("fail", 1, "FAIL"),
        ):
            with self.subTest(behavior=behavior):
                fixture = self.fixture()
                result = fixture.run("full", MANALOOM_TEST_QUALITY_BEHAVIOR=behavior)
                self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
                self.assertNotIn("PASS: gate local", result.stdout)
                self.assertEqual(fixture.receipt()["status"], status)

    def test_quick_manual_and_staged_both_reject_a_skip(self) -> None:
        manual = self.fixture()
        manual.write(
            "scripts/manaloom_secret_scan.sh",
            "#!/usr/bin/env bash\necho 'SKIP: scanner opcional ausente'\n",
        )
        (manual.root / "scripts/manaloom_secret_scan.sh").chmod(0o755)
        manual.git("add", "--all")
        manual.git("commit", "-q", "--no-gpg-sign", "-m", "skip secret scan")
        result = manual.run("quick")
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertNotIn("PASS: gate local", result.stdout)
        self.assertEqual(manual.receipt()["status"], "PARTIAL")

        staged = self.fixture()
        staged.write(
            "scripts/manaloom_secret_scan.sh",
            "#!/usr/bin/env bash\necho 'SKIP: scanner opcional ausente'\n",
        )
        (staged.root / "scripts/manaloom_secret_scan.sh").chmod(0o755)
        staged.git("add", "--all")
        staged.git("commit", "-q", "--no-gpg-sign", "-m", "skip secret scan")
        staged.stage("docs/control.txt", "changed\n")
        result = staged.run("quick", "--staged-scope")
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertEqual(staged.receipts(), [])

    # --- BT-GATE-002: receipt por etapa ------------------------------------

    def test_full_pass_writes_one_eligible_receipt_with_every_named_step(self) -> None:
        fixture = self.fixture()
        result = fixture.run("full")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("PASS: gate local", result.stdout)
        found = fixture.receipts()
        self.assertEqual(len(found), 1)
        receipt = json.loads(found[0].read_text(encoding="utf-8"))
        head = fixture.git("rev-parse", "HEAD").stdout.strip()
        tree = fixture.git("rev-parse", "HEAD^{tree}").stdout.strip()
        self.assertEqual(receipt["status"], "PASS")
        self.assertTrue(receipt["gate_eligible"])
        self.assertEqual(receipt["git_sha"], head)
        self.assertEqual(receipt["git_tree"], tree)
        self.assertEqual(
            [check["id"] for check in receipt["checks"]],
            list(receipt_tool.LOCAL_CI_CHECKS["full"]),
        )
        for check in receipt["checks"]:
            with self.subTest(check=check["id"]):
                self.assertEqual(check["status"], "PASS")
                self.assertEqual(check["exit_code"], 0)
                self.assertEqual(check["source"]["git_sha"], head)
                self.assertEqual(check["source"]["git_tree"], tree)
                self.assertEqual(
                    check["source"]["worktree_digest_sha256"],
                    receipt["worktree_digest_sha256"],
                )
                self.assertRegex(check["log_sha256"], r"^[0-9a-f]{64}$")
        validated = subprocess.run(
            ["python3", str(fixture.root / "scripts/manaloom_gate_run_receipt.py"),
             "validate", str(found[0]), "--repo", str(fixture.root),
             "--gate", "local_ci", "--mode", "full"],
            text=True, capture_output=True,
        )
        self.assertEqual(validated.returncode, 0, validated.stderr)

    def test_a_step_that_moves_the_source_turns_the_receipt_into_fail(self) -> None:
        fixture = self.fixture()
        result = fixture.run("full", MANALOOM_TEST_MUTATE_INDEX="1")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertNotIn("PASS: gate local", result.stdout)
        receipt = fixture.receipt()
        self.assertEqual(receipt["status"], "FAIL")
        self.assertFalse(receipt["gate_eligible"])
        self.assertTrue(any(reason.startswith("source_changed") for reason in receipt["reasons"]))
        self.assertTrue(any(reason.startswith("step_source_drift") for reason in receipt["reasons"]))

    def test_staged_scope_writes_no_receipt(self) -> None:
        fixture = self.fixture()
        fixture.stage("docs/control.txt", "changed\n")
        result = fixture.run("quick", "--staged-scope")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(fixture.receipts(), [])

    def test_quick_and_schema_modes_use_their_closed_catalog(self) -> None:
        for mode in ("quick", "schema"):
            with self.subTest(mode=mode):
                fixture = self.fixture()
                result = fixture.run(mode)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                receipt = fixture.receipt()
                self.assertEqual(
                    [check["id"] for check in receipt["checks"]],
                    list(receipt_tool.LOCAL_CI_CHECKS[mode]),
                )
                self.assertTrue(receipt["gate_eligible"])

    # --- BT-GATE-003: Deck/IA/Learning no full e no release --------------

    def test_full_runs_the_deck_ai_learning_gate_once_in_local_profile(self) -> None:
        fixture = self.fixture()
        result = fixture.run("full")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        gate_calls = [call for call in fixture.calls() if call.startswith("deck-ai-learning|")]
        self.assertEqual(len(gate_calls), 1)
        self.assertTrue(gate_calls[0].startswith("deck-ai-learning|local|reuse="))
        self.assertIn("deck-ai-learning", [c["id"] for c in fixture.receipt()["checks"]])

    def test_deck_gate_reuses_slices_the_local_ci_already_proved(self) -> None:
        fixture = self.fixture()
        result = fixture.run("full")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = fixture.calls()
        self.assertIn("project_logic.drift_check|reused|full-quality", calls)
        self.assertIn("audit.operational_surface_alignment|reused|guardrail-audits", calls)
        self.assertNotIn("project_logic.drift_check|ran", calls)
        self.assertNotIn("audit.operational_surface_alignment|ran", calls)

    def test_deck_gate_runs_the_slice_when_the_local_ci_did_not_pass_it(self) -> None:
        fixture = self.fixture()
        result = fixture.run("full", MANALOOM_TEST_QUALITY_BEHAVIOR="skip_marker")
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        calls = fixture.calls()
        # full-quality ficou PARTIAL: a drift de project logic não é reaproveitada.
        self.assertIn("project_logic.drift_check|ran", calls)
        self.assertIn("audit.operational_surface_alignment|reused|guardrail-audits", calls)

    def test_release_requires_the_production_pg_receipt_before_any_step(self) -> None:
        fixture = self.fixture()
        result = fixture.run("release")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("MANALOOM_DECK_AI_RELEASE_RECEIPT", result.stderr)
        self.assertNotIn("PASS: gate local", result.stdout)
        self.assertEqual(fixture.calls(), [])
        self.assertEqual(fixture.receipts(), [])

        missing_env = self.fixture()
        env = missing_env.release_env()
        env.pop("MANALOOM_NEW_SERVER_ENV")
        result = missing_env.run("release", **env)
        self.assertEqual(result.returncode, 2)

    def test_release_runs_the_deck_gate_in_read_only_profile(self) -> None:
        fixture = self.fixture()
        result = fixture.run("release", **fixture.release_env())
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        gate_calls = [call for call in fixture.calls() if call.startswith("deck-ai-learning|")]
        self.assertEqual(len(gate_calls), 1)
        self.assertTrue(gate_calls[0].startswith("deck-ai-learning|release-read-only|"))
        receipt = fixture.receipt()
        self.assertEqual(
            [check["id"] for check in receipt["checks"]],
            list(receipt_tool.LOCAL_CI_CHECKS["release"]),
        )

    def test_release_blocked_by_the_deck_gate_is_never_success(self) -> None:
        fixture = self.fixture()
        result = fixture.run(
            "release", MANALOOM_TEST_DECK_BEHAVIOR="blocked", **fixture.release_env()
        )
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertNotIn("PASS: gate local", result.stdout)
        self.assertEqual(fixture.receipt()["status"], "BLOCKED")

    def test_e2e_mode_propagates_the_strict_e2e_exit_code(self) -> None:
        for code, status in ((3, "PARTIAL"), (2, "BLOCKED"), (1, "FAIL")):
            with self.subTest(code=code):
                fixture = self.fixture()
                result = fixture.run("e2e", MANALOOM_TEST_E2E_EXIT=str(code))
                self.assertEqual(result.returncode, code, result.stdout + result.stderr)
                self.assertNotIn("PASS: gate local", result.stdout)
                self.assertEqual(fixture.receipt()["status"], status)


if __name__ == "__main__":
    unittest.main(verbosity=2)
