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
                    "cards": [
                        {
                            "active_rule_count": 2,
                            "card_name": "Reprieve",
                            "deck_count": 3,
                            "deck_ids": [612, 613, 615],
                            "effects": ["counter", "draw_cards"],
                            "findings": [
                                {
                                    "code": "generic_effect_without_model_scope",
                                    "severity": "high",
                                },
                                {
                                    "code": "trusted_rule_without_oracle_hash",
                                    "severity": "medium",
                                },
                            ],
                            "impact_tier": "battle_critical",
                            "priority_score": 7153,
                            "severity": "high",
                            "total_quantity": 3,
                            "trusted_executable_rule_count": 1,
                        },
                        {
                            "card_name": "Sheoldred, the Apocalypse",
                            "deck_count": 4,
                            "deck_ids": [617, 618],
                            "findings": [
                                {
                                    "code": "no_trusted_executable_rule",
                                    "severity": "high",
                                }
                            ],
                            "priority_score": 7204,
                            "severity": "high",
                            "total_quantity": 4,
                        },
                        {
                            "card_name": "Goliath Daydreamer",
                            "deck_count": 3,
                            "deck_ids": [613, 614, 615],
                            "findings": [
                                {
                                    "code": "no_trusted_executable_rule",
                                    "severity": "high",
                                }
                            ],
                            "priority_score": 7153,
                            "severity": "high",
                            "total_quantity": 3,
                            "trusted_executable_rule_count": 0,
                        },
                        {
                            "card_name": "Taunt from the Rampart",
                            "deck_count": 2,
                            "deck_ids": [612, 615],
                            "findings": [
                                {
                                    "code": "no_trusted_executable_rule",
                                    "severity": "high",
                                }
                            ],
                            "priority_score": 7102,
                            "severity": "high",
                            "total_quantity": 2,
                            "trusted_executable_rule_count": 0,
                        },
                        {
                            "card_name": "Semblance Anvil",
                            "deck_count": 2,
                            "deck_ids": [612, 615],
                            "findings": [
                                {
                                    "code": "no_trusted_executable_rule",
                                    "severity": "high",
                                }
                            ],
                            "priority_score": 7101,
                            "severity": "high",
                            "total_quantity": 2,
                            "trusted_executable_rule_count": 0,
                        },
                        {
                            "card_name": "Planetarium of Wan Shi Tong",
                            "deck_count": 2,
                            "deck_ids": [611, 613],
                            "findings": [
                                {
                                    "code": "no_trusted_executable_rule",
                                    "severity": "high",
                                }
                            ],
                            "priority_score": 7100,
                            "severity": "high",
                            "total_quantity": 2,
                            "trusted_executable_rule_count": 0,
                        },
                        {
                            "card_name": "Invincible Hymn",
                            "deck_count": 2,
                            "deck_ids": [610, 614],
                            "findings": [
                                {
                                    "code": "no_trusted_executable_rule",
                                    "severity": "high",
                                }
                            ],
                            "priority_score": 7099,
                            "severity": "high",
                            "total_quantity": 2,
                            "trusted_executable_rule_count": 0,
                        },
                        {
                            "card_name": "Heroes Remembered",
                            "deck_count": 2,
                            "deck_ids": [614, 615],
                            "findings": [
                                {
                                    "code": "no_trusted_executable_rule",
                                    "severity": "high",
                                }
                            ],
                            "priority_score": 7098,
                            "severity": "high",
                            "total_quantity": 2,
                            "trusted_executable_rule_count": 0,
                        },
                        {
                            "card_name": "Beacon of Immortality",
                            "deck_count": 2,
                            "deck_ids": [610, 615],
                            "findings": [
                                {
                                    "code": "no_trusted_executable_rule",
                                    "severity": "high",
                                }
                            ],
                            "priority_score": 7097,
                            "severity": "high",
                            "total_quantity": 2,
                            "trusted_executable_rule_count": 0,
                        },
                        {
                            "card_name": "Boros Reckoner",
                            "deck_count": 2,
                            "deck_ids": [612, 616],
                            "findings": [
                                {
                                    "code": "no_active_battle_rule",
                                    "severity": "high",
                                }
                            ],
                            "priority_score": 7096,
                            "severity": "high",
                            "total_quantity": 2,
                            "trusted_executable_rule_count": 0,
                        },
                        {
                            "active_rule_count": 2,
                            "card_name": "Verge Rangers",
                            "deck_count": 3,
                            "deck_ids": [609, 611, 613],
                            "effects": ["topdeck_manipulation"],
                            "findings": [
                                {
                                    "code": "no_trusted_executable_rule",
                                    "severity": "high",
                                },
                                {
                                    "code": "review_only_or_needs_review_rule",
                                    "severity": "high",
                                },
                            ],
                            "impact_tier": "battle_critical",
                            "priority_score": 7153,
                            "severity": "high",
                            "total_quantity": 3,
                            "trusted_executable_rule_count": 0,
                        },
                    ],
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
            coherence_issue = next(
                row
                for row in report["action_queue"]
                if row["issue_type"] == "coherence_critical_high_findings"
            )
            evidence = coherence_issue["examples"][0]["evidence"]
            self.assertIn(
                "Reprieve",
                {row["card_name"] for row in evidence["top_lorehold_cards"]},
            )
            self.assertNotIn(
                "Sheoldred, the Apocalypse",
                {row["card_name"] for row in evidence["top_lorehold_cards"]},
            )
            top_codes = {row["code"]: row["count"] for row in evidence["top_finding_codes"]}
            self.assertEqual(top_codes["generic_effect_without_model_scope"], 1)
            self.assertEqual(top_codes["no_active_battle_rule"], 1)
            self.assertEqual(top_codes["no_trusted_executable_rule"], 9)
            self.assertEqual(evidence["top_lorehold_runtime_missing_cards"], [])
            waived_cards = {
                row["card_name"]: row["gap_kind"]
                for row in evidence["top_lorehold_runtime_waived_cards"]
            }
            self.assertEqual(
                waived_cards["Verge Rangers"],
                "runtime_waived_pending_pg_promotion",
            )
            self.assertEqual(
                waived_cards["Goliath Daydreamer"],
                "runtime_waived_pending_pg_promotion",
            )
            self.assertEqual(
                waived_cards["Taunt from the Rampart"],
                "runtime_waived_pending_pg_promotion",
            )
            self.assertEqual(
                waived_cards["Semblance Anvil"],
                "runtime_waived_pending_pg_promotion",
            )
            self.assertEqual(
                waived_cards["Planetarium of Wan Shi Tong"],
                "runtime_waived_pending_pg_promotion",
            )
            self.assertEqual(
                waived_cards["Invincible Hymn"],
                "runtime_waived_pending_pg_promotion",
            )
            self.assertEqual(
                waived_cards["Heroes Remembered"],
                "runtime_waived_pending_pg_promotion",
            )
            self.assertEqual(
                waived_cards["Beacon of Immortality"],
                "runtime_waived_pending_pg_promotion",
            )
            self.assertEqual(
                waived_cards["Boros Reckoner"],
                "runtime_waived_pending_pg_promotion",
            )

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

    def test_markdown_blocks_without_active_marker_do_not_create_blocked_noise(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_name:
            tmp = Path(tmp_name)
            (tmp / "historical_notes.md").write_text(
                "Old package was blocked in a previous discussion, but this is narrative history.\n",
                encoding="utf-8",
            )
            (tmp / "current_gate.md").write_text(
                "- status: `needs_more_evidence`\n",
                encoding="utf-8",
            )

            report = audit.build_audit(tmp, max_files=None, include_patterns=[])

            blocked = [row for row in report["action_queue"] if row["issue_type"] == "text_blocked"]
            self.assertEqual(len(blocked), 1)
            self.assertEqual(blocked[0]["count"], 1)

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

    def test_build_audit_ignores_prior_log_learning_audit_reports(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_name:
            tmp = Path(tmp_name)
            write_json(
                tmp / "manaloom_log_learning_audit_20260628_v5.json",
                {
                    "severity_counts": {"critical": 2, "high": 81},
                    "action_queue": [
                        {
                            "severity": "critical",
                            "category": "runtime_rule_gap",
                            "issue_type": "coherence_critical_high_findings",
                        }
                    ],
                },
            )
            write_json(
                tmp / "deck_card_battle_rule_coherence_audit_current.json",
                {
                    "deck_id": 608,
                    "cards": [
                        {
                            "card_name": "Goliath Daydreamer",
                            "deck_ids": [613, 614, 615],
                            "findings": [
                                {
                                    "code": "no_trusted_executable_rule",
                                    "severity": "high",
                                }
                            ],
                            "priority_score": 7153,
                            "severity": "high",
                            "trusted_executable_rule_count": 0,
                        }
                    ],
                    "severity_counts": {"high": 1},
                },
            )

            report = audit.build_audit(tmp, max_files=None, include_patterns=[])

            self.assertEqual(report["files_scanned"], 1)
            sources = {
                Path(example["source_path"]).name
                for row in report["action_queue"]
                for example in row.get("examples", [])
            }
            self.assertNotIn("manaloom_log_learning_audit_20260628_v5.json", sources)
            self.assertIn("deck_card_battle_rule_coherence_audit_current.json", sources)

    def test_write_report_uses_requested_output_dir(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_name:
            tmp = Path(tmp_name)
            report = {
                "action_queue": [],
                "category_counts": {},
                "files_scanned": 0,
                "generated_at": "2026-06-28T00:00:00Z",
                "issue_count": 0,
                "postgres_writes": False,
                "reports_dir": str(tmp),
                "severity_counts": {},
                "source_db_mutated": False,
            }

            json_path, md_path = audit.write_report(report, "custom_report", tmp)

            self.assertEqual(json_path.parent, tmp)
            self.assertEqual(md_path.parent, tmp)
            self.assertTrue(json_path.exists())
            self.assertTrue(md_path.exists())


if __name__ == "__main__":
    unittest.main()
