#!/usr/bin/env python3
"""BT-GATE-002: receipt forte do local_ci e da suíte E2E."""

from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
TOOL_PATH = REPO_ROOT / "scripts" / "manaloom_gate_run_receipt.py"
SPEC = importlib.util.spec_from_file_location("manaloom_gate_run_receipt", TOOL_PATH)
assert SPEC is not None and SPEC.loader is not None
tool = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(tool)


def git(repo: Path, *args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ).stdout.strip()


class GateRunReceiptTest(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="manaloom-gate-receipt-repo.")
        self.addCleanup(temporary.cleanup)
        self.repo = Path(temporary.name)
        git(self.repo, "init", "-q")
        git(self.repo, "config", "user.name", "ManaLoom Test")
        git(self.repo, "config", "user.email", "manaloom-test@example.invalid")
        (self.repo / "project_logic_manifest.json").write_text(
            json.dumps({"source_digest_sha256": "b" * 64}) + "\n", encoding="utf-8"
        )
        (self.repo / "tracked.txt").write_text("base\n", encoding="utf-8")
        git(self.repo, "add", "--all")
        git(self.repo, "commit", "-q", "--no-gpg-sign", "-m", "base")

        # Raiz durável: fora de /tmp e fora do worktree, como a padrão em ~/.manaloom.
        durable_parent = Path.home() / ".cache"
        durable_parent.mkdir(parents=True, exist_ok=True)
        durable = tempfile.TemporaryDirectory(
            prefix="manaloom-gate-receipt-durable.", dir=durable_parent
        )
        self.addCleanup(durable.cleanup)
        self.durable_root = Path(durable.name)
        work = tempfile.TemporaryDirectory(prefix="manaloom-gate-receipt-run.")
        self.addCleanup(work.cleanup)
        self.work = Path(work.name)

    def start(self) -> Path:
        path = self.work / "source-start.json"
        path.write_text(json.dumps(tool.capture_source_state(self.repo)), encoding="utf-8")
        return path

    def steps(self, *rows: tuple[str, str, int], source_overrides=None) -> Path:
        """steps.tsv no formato local-ci-v2: cada etapa leva o estado-fonte do fim dela."""
        lines = []
        source_overrides = source_overrides or {}
        for step_id, status, exit_code in rows:
            log = self.work / f"{step_id}.log"
            log.write_text(f"log of {step_id}\n", encoding="utf-8")
            source = self.work / f"{step_id}.source.json"
            state = tool.capture_source_state(self.repo)
            state.update(source_overrides.get(step_id, {}))
            source.write_text(json.dumps(state), encoding="utf-8")
            lines.append(f"{step_id}\t{status}\t{exit_code}\t{log}\t{source}")
        path = self.work / "steps.tsv"
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        return path

    def finalize(
        self,
        *,
        status: str = "PASS",
        root: Path | None = None,
        rows=None,
        start=None,
        mode: str = "schema",
        source_overrides=None,
    ):
        self.run_counter = getattr(self, "run_counter", 0) + 1
        return tool.finalize(
            repo=self.repo,
            gate="local_ci",
            mode=mode,
            run_id=f"20261005T000000Z_schema_{self.run_counter}",
            started_at=datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            source_start_path=start or self.start(),
            steps_path=self.steps(
                *(rows or tuple((step, "PASS", 0) for step in tool.LOCAL_CI_CHECKS[mode])),
                source_overrides=source_overrides,
            ),
            steps_format="local-ci-v2",
            status=status,
            receipt_root=root or self.durable_root,
        )

    def rewrite(self, path: Path, mutate) -> None:
        receipt = json.loads(path.read_text(encoding="utf-8"))
        mutate(receipt)
        path.write_text(json.dumps(receipt), encoding="utf-8")

    def assert_rejected(self, path: Path, message: str, **kwargs) -> None:
        with self.assertRaisesRegex(tool.ReceiptValidationError, message):
            tool.validate(path, repo=self.repo, **kwargs)

    def test_capture_reads_real_checkout(self) -> None:
        clean = tool.capture_source_state(self.repo)
        self.assertEqual(clean["git_sha"], git(self.repo, "rev-parse", "HEAD"))
        self.assertRegex(clean["git_sha"], r"^[0-9a-f]{40}$")
        self.assertEqual(clean["git_tree"], git(self.repo, "rev-parse", "HEAD^{tree}"))
        self.assertFalse(clean["git_dirty"])

        (self.repo / "untracked.txt").write_text("new\n", encoding="utf-8")
        untracked = tool.capture_source_state(self.repo)
        self.assertTrue(untracked["git_dirty"])
        self.assertNotEqual(untracked["worktree_digest_sha256"], clean["worktree_digest_sha256"])

        os.symlink("tracked.txt", self.repo / "link")
        linked = tool.capture_source_state(self.repo)
        self.assertNotEqual(linked["worktree_digest_sha256"], untracked["worktree_digest_sha256"])

        (self.repo / "tracked.txt").write_text("edited\n", encoding="utf-8")
        edited = tool.capture_source_state(self.repo)
        self.assertNotEqual(edited["worktree_digest_sha256"], linked["worktree_digest_sha256"])

    def test_pass_receipt_round_trips(self) -> None:
        path, receipt = self.finalize()
        self.assertEqual(receipt["status"], "PASS")
        self.assertTrue(receipt["durable"])
        self.assertTrue(receipt["gate_eligible"])
        self.assertEqual(path.parent.parent.name, receipt["git_sha"])
        validated = tool.validate(path, repo=self.repo, require_clean=True, expected_gate="local_ci", expected_mode="schema")
        self.assertEqual(validated["git_sha"], git(self.repo, "rev-parse", "HEAD"))

    def test_temporary_root_is_never_eligible(self) -> None:
        path, receipt = self.finalize(root=self.work / "receipts")
        self.assertFalse(receipt["durable"])
        self.assertFalse(receipt["gate_eligible"])
        self.assert_rejected(path, "not gate eligible")

    def test_root_inside_worktree_is_never_eligible(self) -> None:
        path, receipt = self.finalize(root=self.repo / ".receipts")
        self.assertFalse(receipt["durable"])
        self.assert_rejected(path, "not gate eligible")

    def test_source_change_during_gate_turns_pass_into_fail(self) -> None:
        start = self.start()
        (self.repo / "tracked.txt").write_text("changed during gate\n", encoding="utf-8")
        _, receipt = self.finalize(start=start)
        self.assertEqual(receipt["status"], "FAIL")
        self.assertFalse(receipt["source"]["stable"])
        self.assertIn("source_changed:git_dirty,worktree_digest_sha256", receipt["reasons"])
        self.assertFalse(receipt["gate_eligible"])

    def test_pass_status_with_failed_check_is_fail(self) -> None:
        _, receipt = self.finalize(rows=(("shell-contracts", "PASS", 0), ("schema-gate", "FAIL", 1)))
        self.assertEqual(receipt["status"], "FAIL")
        self.assertIn("non_pass_check_with_pass_status", receipt["reasons"])

    def test_checkout_drift_after_gate_is_rejected(self) -> None:
        path, _ = self.finalize()
        (self.repo / "tracked.txt").write_text("next\n", encoding="utf-8")
        git(self.repo, "commit", "-q", "--no-gpg-sign", "-am", "next")
        self.assert_rejected(path, "source drift against checkout: git_sha")

    def test_project_logic_drift_is_rejected(self) -> None:
        path, _ = self.finalize()
        (self.repo / "project_logic_manifest.json").write_text(
            json.dumps({"source_digest_sha256": "c" * 64}) + "\n", encoding="utf-8"
        )
        git(self.repo, "commit", "-q", "--no-gpg-sign", "-am", "digest")
        self.assert_rejected(path, "source drift against checkout")

    def test_require_clean_rejects_dirty_run(self) -> None:
        (self.repo / "untracked.txt").write_text("dirty\n", encoding="utf-8")
        path, receipt = self.finalize()
        self.assertTrue(receipt["gate_eligible"])
        tool.validate(path, repo=self.repo)
        self.assert_rejected(path, "clean worktree", require_clean=True)

    def test_same_size_log_tamper_is_rejected_by_hash(self) -> None:
        path, receipt = self.finalize()
        log = Path(receipt["evidence_root"]) / receipt["artifacts"][0]["path"]
        original = log.read_bytes()
        log.write_bytes(original[:-2] + b"X\n")
        self.assertEqual(log.stat().st_size, len(original))
        self.assert_rejected(path, "artifact hash drift")

    def test_manifest_digest_tamper_is_rejected(self) -> None:
        path, _ = self.finalize()
        self.rewrite(path, lambda r: r.update(artifact_manifest_sha256="d" * 64))
        self.assert_rejected(path, "artifact_manifest_sha256 drift")

    def test_forged_single_check_is_rejected(self) -> None:
        path, _ = self.finalize()

        def forge(receipt):
            receipt["checks"] = receipt["checks"][:1]
            receipt["summary"]["check_count"] = 1
            receipt["summary"]["passed"] = 1

        self.rewrite(path, forge)
        self.assert_rejected(path, "artifact not referenced|check catalog drift")
        # Um receipt honesto, mas com um check só, não cobre o modo.
        path2, receipt2 = self.finalize(rows=(("shell-contracts", "PASS", 0),))
        self.assertEqual(receipt2["status"], "FAIL")
        self.assertIn("check_catalog_mismatch", receipt2["reasons"])
        self.assert_rejected(path2, "status must be exactly")

    def test_reordered_catalog_is_rejected(self) -> None:
        path, _ = self.finalize()
        self.rewrite(path, lambda r: r.update(checks=list(reversed(r["checks"]))))
        self.assert_rejected(path, "check catalog drift")

    def test_check_rules_are_enforced(self) -> None:
        cases = {
            "check did not pass": lambda r: r["checks"][0].update(status="SKIP"),
            "exit code is not 0": lambda r: r["checks"][0].update(exit_code=1),
            "has no log artifact": lambda r: r["checks"][0].update(artifact_ids=[]),
            "unknown artifact": lambda r: r["checks"][0].update(artifact_ids=["log.ghost"]),
            "summary does not match": lambda r: r["summary"].update(failed=1),
            "status must be exactly": lambda r: r.update(status="PARTIAL"),
            "different SHA/tree/digest": lambda r: r["checks"][0]["source"].update(git_sha="f" * 40),
            "log_sha256 does not match": lambda r: r["checks"][0].update(log_sha256="e" * 64),
            "carries no reasons": lambda r: r.update(reasons=["x"]),
        }
        for message, mutate in cases.items():
            with self.subTest(message=message):
                path, _ = self.finalize()
                self.rewrite(path, mutate)
                self.assert_rejected(path, message)
                import shutil

                shutil.rmtree(path.parent)

    def test_freshness_is_enforced(self) -> None:
        path, receipt = self.finalize()
        generated = datetime.fromisoformat(receipt["generated_at"].replace("Z", "+00:00"))
        self.assert_rejected(path, "stale", now=generated + timedelta(hours=25))
        self.assert_rejected(path, "future", now=generated - timedelta(hours=1))
        self.rewrite(path, lambda r: r.update(started_at="2099-01-01T00:00:00Z"))
        self.assert_rejected(path, "out of order")

    def test_symlinked_log_is_rejected(self) -> None:
        path, receipt = self.finalize()
        log = Path(receipt["evidence_root"]) / receipt["artifacts"][0]["path"]
        target = log.with_suffix(".real")
        log.rename(target)
        os.symlink(target, log)
        self.assert_rejected(path, "symlink")

    def test_existing_evidence_root_is_not_overwritten(self) -> None:
        self.finalize()
        self.run_counter -= 1
        with self.assertRaisesRegex(tool.ReceiptValidationError, "already exists"):
            self.finalize()

    def test_local_ci_catalog_matches_script_order(self) -> None:
        script = (REPO_ROOT / "scripts" / "manaloom_local_ci.sh").read_text(encoding="utf-8")
        if "run_named_step" not in script:
            # O local_ci é plano de controle do escopo staged: a ligação dele ao
            # receipt entra num commit próprio, que exige a prova de UI inteira
            # (BT-UIEV-001). Até lá o catálogo vale só para o receipt.
            self.skipTest("local_ci ainda não grava o receipt")
        import re

        def calls(body: str) -> list[str]:
            ids = []
            for line in body.splitlines():
                line = line.strip()
                if line == "run_full":
                    ids.extend(tool.LOCAL_CI_CHECKS["full"])
                match = re.match(r"run_named_step ([a-z0-9-]+) ", line)
                if match:
                    ids.append(match.group(1))
            return ids

        run_full = script.split("run_full() {", 1)[1].split("\n}", 1)[0]
        self.assertEqual(calls(run_full), list(tool.LOCAL_CI_CHECKS["full"]))
        quick = script.split("run_quick() {", 1)[1].split("\n}\n", 1)[0]
        self.assertEqual(
            list(dict.fromkeys(calls(quick))), list(tool.LOCAL_CI_CHECKS["quick"])
        )
        dispatch = script.rsplit('case "$MODE" in', 1)[1].split("esac", 1)[0]
        for mode in ("schema", "e2e", "release"):
            body = dispatch.split(f"  {mode})", 1)[1].split(";;", 1)[0]
            self.assertEqual(calls(body), list(tool.LOCAL_CI_CHECKS[mode]), mode)

    def test_e2e_steps_format(self) -> None:
        log = self.work / "web.log"
        log.write_text("web\n", encoding="utf-8")
        steps = self.work / "e2e.tsv"
        steps.write_text(
            f"PASS\tPublic web product E2E\t0\t{log}\t\n"
            "SKIP\tFlutter live runtime integration E2E\t\t\toptional\n",
            encoding="utf-8",
        )
        parsed = tool.parse_steps(steps, "e2e-v1")
        self.assertEqual(
            [(step["id"], step["status"], step["exit_code"]) for step in parsed],
            [
                ("public_web_product_e2e", "PASS", 0),
                ("flutter_live_runtime_integration_e2e", "SKIP", None),
            ],
        )

    def test_cli_finalize_exit_code_follows_source_stability(self) -> None:
        start = self.start()
        steps = self.steps(*((step, "PASS", 0) for step in tool.LOCAL_CI_CHECKS["schema"]))
        base = [
            "python3", str(TOOL_PATH), "finalize", "--repo", str(self.repo),
            "--gate", "local_ci", "--mode", "schema",
            "--started-at", datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "--source-start", str(start), "--steps", str(steps),
            "--steps-format", "local-ci-v2", "--status", "PASS",
            "--receipt-root", str(self.durable_root),
        ]
        stable = subprocess.run(base + ["--run-id", "stable"], text=True, capture_output=True)
        self.assertEqual(stable.returncode, 0, stable.stderr)
        receipt = json.loads(stable.stdout)["receipt"]
        check = subprocess.run(
            ["python3", str(TOOL_PATH), "validate", receipt, "--repo", str(self.repo)],
            text=True,
            capture_output=True,
        )
        self.assertEqual(check.returncode, 0, check.stderr)
        (self.repo / "tracked.txt").write_text("moved\n", encoding="utf-8")
        moved = subprocess.run(base + ["--run-id", "moved"], text=True, capture_output=True)
        self.assertEqual(moved.returncode, 1)
        self.assertFalse(json.loads(moved.stdout)["source_stable"])

    # BT-GATE-001/002/003: PARTIAL, SHA por etapa e reaproveitamento por fatia.

    def test_partial_step_never_yields_pass_or_eligibility(self) -> None:
        rows = tuple(
            (step, "PARTIAL" if step == "schema-gate" else "PASS", 3 if step == "schema-gate" else 0)
            for step in tool.LOCAL_CI_CHECKS["schema"]
        )
        path, receipt = self.finalize(rows=rows)
        self.assertEqual(receipt["status"], "FAIL")
        self.assertIn("non_pass_check_with_pass_status", receipt["reasons"])
        self.assertFalse(receipt["gate_eligible"])
        self.assertEqual(receipt["summary"]["partial"], 1)
        path2, receipt2 = self.finalize(rows=rows, status="PARTIAL")
        self.assertEqual(receipt2["status"], "PARTIAL")
        self.assertFalse(receipt2["gate_eligible"])
        self.assert_rejected(path2, "status must be exactly")

    def test_step_on_another_sha_turns_the_receipt_into_fail(self) -> None:
        step = tool.LOCAL_CI_CHECKS["schema"][1]
        for key, value in (
            ("git_sha", "f" * 40),
            ("git_tree", "e" * 40),
            ("worktree_digest_sha256", "d" * 64),
        ):
            with self.subTest(key=key):
                _, receipt = self.finalize(source_overrides={step: {key: value}})
                self.assertEqual(receipt["status"], "FAIL")
                self.assertIn(f"step_source_drift:{step}", receipt["reasons"])
                self.assertFalse(receipt["gate_eligible"])

    def test_tree_drift_after_gate_is_rejected(self) -> None:
        path, _ = self.finalize()
        self.rewrite(path, lambda r: r.update(git_tree="0" * 40))
        self.assert_rejected(path, "git_tree drift")

    def test_full_catalog_carries_the_deck_ai_learning_slice_once(self) -> None:
        for mode in ("full", "e2e", "release"):
            with self.subTest(mode=mode):
                self.assertEqual(tool.LOCAL_CI_CHECKS[mode].count("deck-ai-learning"), 1)
        self.assertNotIn("deck-ai-learning", tool.LOCAL_CI_CHECKS["quick"])
        self.assertNotIn("deck-ai-learning", tool.LOCAL_CI_CHECKS["schema"])

    def test_reuse_requires_pass_on_the_same_sha_tree_and_digest(self) -> None:
        rows = (("project-logic", "PASS", 0), ("full-quality", "PASS", 0))
        steps = self.steps(*rows)
        self.assertEqual(
            tool.reusable_check(steps_path=steps, repo=self.repo, candidate_ids=["project-logic", "full-quality"]),
            "project-logic",
        )
        # etapa que não passou não é reaproveitada
        steps = self.steps(("project-logic", "PARTIAL", 3), ("full-quality", "PASS", 0))
        self.assertEqual(
            tool.reusable_check(steps_path=steps, repo=self.repo, candidate_ids=["project-logic", "full-quality"]),
            "full-quality",
        )
        steps = self.steps(("project-logic", "FAIL", 1))
        with self.assertRaisesRegex(tool.ReceiptValidationError, "no local_ci check"):
            tool.reusable_check(steps_path=steps, repo=self.repo, candidate_ids=["project-logic"])
        # etapa ausente
        with self.assertRaisesRegex(tool.ReceiptValidationError, "no local_ci check"):
            tool.reusable_check(steps_path=steps, repo=self.repo, candidate_ids=["guardrail-audits"])

    def test_reuse_is_refused_after_the_worktree_moves(self) -> None:
        steps = self.steps(("guardrail-audits", "PASS", 0))
        (self.repo / "tracked.txt").write_text("moved after the step\n", encoding="utf-8")
        with self.assertRaisesRegex(tool.ReceiptValidationError, "no local_ci check"):
            tool.reusable_check(steps_path=steps, repo=self.repo, candidate_ids=["guardrail-audits"])

    def test_cli_reuse_exit_codes(self) -> None:
        steps = self.steps(("guardrail-audits", "PASS", 0))
        base = ["python3", str(TOOL_PATH), "reuse", "--repo", str(self.repo), "--steps", str(steps)]
        ok = subprocess.run(base + ["--check", "guardrail-audits"], text=True, capture_output=True)
        self.assertEqual((ok.returncode, ok.stdout.strip()), (0, "guardrail-audits"))
        missing = subprocess.run(base + ["--check", "full-quality"], text=True, capture_output=True)
        self.assertEqual(missing.returncode, 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
