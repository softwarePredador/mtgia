from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path

import manaloom_log_learning_audit as audit


def write_json(path: Path, payload: dict) -> None:
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


class ManaLoomLogLearningAuditTest(unittest.TestCase):
    def test_build_audit_finds_unobserved_candidate_and_prior_flags(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_name:
            tmp = Path(tmp_name)
            write_json(
                tmp / "prior_compare.json",
                {
                    "comparison": {
                        "flags": [
                            {"metric": "spell_action_entries", "ratio": 3.0},
                            {
                                "card": "Birgi, God of Storytelling",
                                "metric": "candidate_observation",
                            },
                        ]
                    },
                    "observed_summary": {
                        "candidate_observations": {
                            "Birgi, God of Storytelling": {
                                "evidence_level": "library_only",
                                "observed": False,
                                "trace_count": 11,
                            }
                        }
                    },
                },
            )

            report = audit.build_audit(tmp, max_files=None, include_patterns=[])

            issue_types = {row["issue_type"] for row in report["action_queue"]}
            self.assertIn("candidate_unobserved", issue_types)
            self.assertIn("prior_rhythm_flags", issue_types)
            self.assertFalse(report["postgres_writes"])

    def test_build_audit_finds_coherence_and_xmage_gaps(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_name:
            tmp = Path(tmp_name)
            write_json(
                tmp / "deck_card_battle_rule_coherence_audit.json",
                {
                    "deck_id": 607,
                    "finding_counts": {"no_active_battle_rule": 2},
                    "severity_counts": {"critical": 1, "high": 2},
                },
            )
            write_json(
                tmp / "xmage_current_replay_batch_pipeline.json",
                {
                    "summary": {
                        "blocked_missing_xmage_source_count": 3,
                        "manual_or_blocked_count": 19,
                        "missing_xmage_class_count": 1,
                    }
                },
            )

            report = audit.build_audit(tmp, max_files=None, include_patterns=[])

            issue_types = {row["issue_type"] for row in report["action_queue"]}
            self.assertIn("coherence_critical_high_findings", issue_types)
            self.assertIn("missing_xmage_source_or_class", issue_types)
            self.assertIn("manual_or_blocked_rules", issue_types)

    def test_build_audit_finds_text_failures(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_name:
            tmp = Path(tmp_name)
            (tmp / "runtime_test.out").write_text(
                "Traceback: runtime_error\noperation timed out\nFAILED test_case\n",
                encoding="utf-8",
            )
            (tmp / "narrative.md").write_text(
                "Prior packages failed, but --game-timeout-seconds is only a parameter.\n",
                encoding="utf-8",
            )

            report = audit.build_audit(tmp, max_files=None, include_patterns=[])

            issue_types = {row["issue_type"] for row in report["action_queue"]}
            self.assertIn("text_runtime_traceback", issue_types)
            self.assertIn("text_timeout", issue_types)
            test_failures = [
                row for row in report["action_queue"] if row["issue_type"] == "text_test_failure"
            ]
            self.assertEqual(test_failures[0]["count"], 1)

    def test_later_pass_supersedes_old_text_failure(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_name:
            tmp = Path(tmp_name)
            failed = tmp / "runtime_test_1.out"
            passed = tmp / "runtime_test_2.out"
            failed.write_text(
                "Traceback\n  File \"x.py\", line 10, in test_kinnan_runtime\nAssertionError\nFAILED test_kinnan_runtime\n",
                encoding="utf-8",
            )
            passed.write_text("PASS test_kinnan_runtime\n", encoding="utf-8")
            os.utime(failed, (1000, 1000))
            os.utime(passed, (2000, 2000))

            report = audit.build_audit(tmp, max_files=None, include_patterns=[])

            issue_types = {row["issue_type"] for row in report["action_queue"]}
            self.assertNotIn("text_test_failure", issue_types)
            self.assertNotIn("text_runtime_traceback", issue_types)
            self.assertEqual(report["superseded_issue_count"], 2)


if __name__ == "__main__":
    unittest.main()
