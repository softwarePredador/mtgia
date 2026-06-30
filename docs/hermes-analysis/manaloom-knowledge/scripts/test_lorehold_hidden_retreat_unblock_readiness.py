import json
import tempfile
import unittest
from pathlib import Path
from subprocess import CompletedProcess
from unittest.mock import patch

import lorehold_hidden_retreat_unblock_readiness as readiness


def write_json(path: Path, payload: dict):
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def fixture_files(tmpdir: Path) -> dict[str, Path]:
    precheck = tmpdir / "pg271_precheck.sql"
    precheck.write_text("SELECT 1;\n", encoding="utf-8")
    manifest = tmpdir / "manifest.json"
    write_json(
        manifest,
        {
            "deploy_id": "pg271",
            "status": "prepared_read_only_pending_apply_approval",
            "apply_gate": "Do not run apply SQL without explicit approval for the exact command.",
            "selected_card_names": ["Hidden Retreat"],
            "mutations_performed": [],
            "files": {"precheck": str(precheck)},
        },
    )
    access_model = tmpdir / "access.json"
    write_json(
        access_model,
        {
            "summary": {
                "preflight_access_candidate_ready_count": 0,
                "hidden_retreat_package_status": "prepared_read_only_pending_apply_approval",
                "hidden_retreat_runtime_model_status": "runtime_proposal_overlay_active",
                "recommended_next_action": "no_access_swap_ready; apply_or_sync_hidden_retreat_package_then_gate_new_seed_safe_cut",
            }
        },
    )
    focus_queue = tmpdir / "focus.json"
    write_json(
        focus_queue,
        {
            "summary": {
                "gate_ready_package_count": 0,
                "recommended_next_action": "do_not_create_blind_swap; run focused trace/runtime/cut-model work first",
            }
        },
    )
    outcome_audit = tmpdir / "outcome.json"
    write_json(
        outcome_audit,
        {
            "summary": {
                "deeper_gate_candidate_count": 0,
                "rejected_current_pair_count": 11,
                "inconclusive_no_used_sample_count": 8,
                "decision_counts": {"missing_per_card_outcome_data": 44},
                "recommended_next_action": "avoid_repeating_rejected_pairs_and_generate_new_trace_targeted_package",
            }
        },
    )
    return {
        "manifest": manifest,
        "access_model": access_model,
        "focus_queue": focus_queue,
        "outcome_audit": outcome_audit,
        "precheck": precheck,
    }


def mark_hidden_retreat_synced(access_model: Path):
    payload = json.loads(access_model.read_text(encoding="utf-8"))
    payload["summary"]["hidden_retreat_package_status"] = "applied_synced"
    payload["summary"]["hidden_retreat_runtime_model_status"] = "local_db_active"
    payload["summary"]["recommended_next_action"] = "no_access_swap_ready; build_new_seed_safe_cut"
    write_json(access_model, payload)


class FakeRunner:
    def __init__(self, results):
        self.results = list(results)
        self.calls = []

    def __call__(self, args, **kwargs):
        self.calls.append((args, kwargs))
        if not self.results:
            return CompletedProcess(args=args, returncode=0, stdout="", stderr="")
        return self.results.pop(0)


class LoreholdHiddenRetreatUnblockReadinessTest(unittest.TestCase):
    def test_blocks_blind_gate_when_no_preflight_or_deeper_candidate(self):
        with tempfile.TemporaryDirectory() as tmp:
            files = fixture_files(Path(tmp))

            payload = readiness.build_report(
                manifest_path=files["manifest"],
                access_model_path=files["access_model"],
                focus_queue_path=files["focus_queue"],
                outcome_audit_path=files["outcome_audit"],
            )

            self.assertFalse(payload["summary"]["safe_to_run_battle_gate_now"])
            self.assertEqual(payload["summary"]["gate_ready_package_count"], 0)
            self.assertEqual(
                payload["summary"]["readiness_status"],
                "blocked_pending_pg_precheck_apply_and_no_safe_cut",
            )
            self.assertIn("Do not run blind", payload["guardrails"][0])

    def test_read_only_precheck_failure_is_sanitized_and_blocks(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            files = fixture_files(root)
            env_file = root / ".env"
            env_file.write_text("DATABASE_URL=postgres://example\n", encoding="utf-8")
            runner = FakeRunner(
                [
                    CompletedProcess(args=[], returncode=0, stdout="database_url_present\n", stderr=""),
                    CompletedProcess(
                        args=[],
                        returncode=2,
                        stdout="",
                        stderr=(
                            'psql: error: connection to server at "143.198.230.247", '
                            "port 5433 failed: server closed the connection unexpectedly\n"
                        ),
                    ),
                ]
            )

            with patch.object(readiness.shutil, "which", return_value="/opt/homebrew/bin/psql"):
                payload = readiness.build_report(
                    manifest_path=files["manifest"],
                    access_model_path=files["access_model"],
                    focus_queue_path=files["focus_queue"],
                    outcome_audit_path=files["outcome_audit"],
                    env_path=env_file,
                    run_pg_precheck=True,
                    runner=runner,
                )

            attempt = payload["postgres_precheck"]["attempts"][0]
            self.assertEqual(attempt["classification"], "failed_connection_closed")
            self.assertNotIn("143.198.230.247", attempt["stderr_excerpt"])
            self.assertNotIn("5433", attempt["stderr_excerpt"])
            self.assertEqual(payload["summary"]["readiness_status"], "blocked_db_precheck_and_no_safe_cut")
            self.assertFalse(payload["summary"]["safe_to_run_battle_gate_now"])

    def test_pg_precheck_success_still_requires_safe_cut_before_battle(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            files = fixture_files(root)
            env_file = root / ".env"
            env_file.write_text("DATABASE_URL=postgres://example\n", encoding="utf-8")
            runner = FakeRunner(
                [
                    CompletedProcess(args=[], returncode=0, stdout="database_url_present\n", stderr=""),
                    CompletedProcess(args=[], returncode=0, stdout="precheck ok\n", stderr=""),
                ]
            )

            with patch.object(readiness.shutil, "which", return_value="/opt/homebrew/bin/psql"):
                payload = readiness.build_report(
                    manifest_path=files["manifest"],
                    access_model_path=files["access_model"],
                    focus_queue_path=files["focus_queue"],
                    outcome_audit_path=files["outcome_audit"],
                    env_path=env_file,
                    run_pg_precheck=True,
                    runner=runner,
                )

            self.assertEqual(payload["postgres_precheck"]["attempts"][0]["classification"], "success")
            self.assertEqual(
                payload["summary"]["readiness_status"],
                "pg_precheck_success_but_cut_model_still_blocks_battle",
            )
            self.assertFalse(payload["summary"]["safe_to_run_battle_gate_now"])

    def test_synced_hidden_retreat_routes_to_cut_work_not_pg_apply(self):
        with tempfile.TemporaryDirectory() as tmp:
            files = fixture_files(Path(tmp))
            mark_hidden_retreat_synced(files["access_model"])

            payload = readiness.build_report(
                manifest_path=files["manifest"],
                access_model_path=files["access_model"],
                focus_queue_path=files["focus_queue"],
                outcome_audit_path=files["outcome_audit"],
            )

            self.assertEqual(
                payload["summary"]["readiness_status"],
                "hidden_retreat_synced_no_gate_ready_package",
            )
            self.assertEqual(payload["summary"]["hidden_retreat_package_status"], "applied_synced")
            self.assertEqual(
                payload["summary"]["recommended_next_action"],
                "continue_trace_targeted_cut_model_or_runtime_gap_work_before_more_battles",
            )
            self.assertIn("product_truth_confirmed", payload["blocker_chain"][2]["blocker"])
            self.assertIn("Do not rerun PG271", payload["guardrails"][3])

    def test_recovery_mode_precheck_error_is_classified(self):
        self.assertEqual(
            readiness.classify_psql_error(2, "FATAL:  the database system is in recovery mode"),
            "failed_database_recovery_mode",
        )

    def test_markdown_contains_precheck_and_blocker_contract(self):
        with tempfile.TemporaryDirectory() as tmp:
            files = fixture_files(Path(tmp))
            payload = readiness.build_report(
                manifest_path=files["manifest"],
                access_model_path=files["access_model"],
                focus_queue_path=files["focus_queue"],
                outcome_audit_path=files["outcome_audit"],
            )

            markdown = readiness.render_markdown(payload)

            self.assertIn("Lorehold Hidden Retreat Unblock Readiness", markdown)
            self.assertIn("Precheck Status", markdown)
            self.assertIn("Blocker Chain", markdown)


if __name__ == "__main__":
    unittest.main()
