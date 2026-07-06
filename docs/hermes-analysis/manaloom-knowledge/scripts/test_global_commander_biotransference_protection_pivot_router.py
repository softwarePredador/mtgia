#!/usr/bin/env python3
"""Tests for Biotransference protection pivot router."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_biotransference_protection_pivot_router as router


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def type_conversion_payload() -> dict[str, object]:
    return {
        "summary": {"ready_type_conversion_candidate_count": 0},
        "source_candidate_rows": [
            {
                "card_name": "Biotransference",
                "already_in_current_deck": True,
                "status": "exact_artifact_type_conversion_source_blocked",
            }
        ],
    }


def engine_policy_payload() -> dict[str, object]:
    return {
        "pool_policy_rows": [
            {
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "policy_cut_rows": [
                    {
                        "card_name": "Biotransference",
                        "roles": ["engine"],
                        "policy_status": "engine_axis_policy_review_cut_pressure_ready",
                        "policy_bucket": "engine_only_excess_cut_pressure",
                    },
                    {
                        "card_name": "Archaeomancer's Map",
                        "roles": ["engine", "tutor"],
                        "policy_status": "engine_axis_policy_review_cut_pressure_ready",
                        "policy_bucket": "engine_overlap_excess_cut_pressure",
                    },
                    {
                        "card_name": "Maskwood Nexus",
                        "roles": ["engine"],
                        "policy_status": "engine_axis_policy_blocks_cut_until_source_lane_review",
                        "policy_bucket": "protected_engine_cut_pressure",
                        "policy_blockers": ["engine_card_has_commander_plan_signal:kaalia_trigger_or_type_enabler"],
                    },
                ],
            }
        ]
    }


def trace_reviewer_payload() -> dict[str, object]:
    return {
        "trace_review_rows": [
            {
                "card_name": "Archaeomancer's Map",
                "review_status": "trace_review_blocks_negative_clearance_equal_score_tutor_candidate",
                "reason": "card_was_equal_or_better_tutor_candidate",
            }
        ]
    }


class GlobalCommanderBiotransferenceProtectionPivotRouterTests(unittest.TestCase):
    def test_protects_biotransference_and_pivots_when_no_engine_cut_is_viable(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            type_report = write_json(root, "type.json", type_conversion_payload())
            policy_report = write_json(root, "policy.json", engine_policy_payload())
            trace_report = write_json(root, "trace.json", trace_reviewer_payload())
            report = router.build_report(
                type_conversion_report=type_report,
                engine_policy_report=policy_report,
                trace_reviewer_report=trace_report,
            )

        self.assertEqual(report["status"], "biotransference_protected_engine_axis_exhausted_pivot_required")
        self.assertTrue(report["summary"]["biotransference_protected"])
        self.assertEqual(report["summary"]["viable_non_biotransference_engine_cut_count"], 0)
        by_name = {row["card_name"]: row for row in report["engine_cut_route_rows"]}
        self.assertEqual(
            by_name["Biotransference"]["status"],
            "biotransference_protected_no_outside_type_conversion_replacement",
        )
        self.assertIn(
            "trace_review_blocks_negative_clearance_equal_score_tutor_candidate",
            by_name["Archaeomancer's Map"]["blockers"],
        )
        self.assertFalse(report["candidate_copy_allowed_now"])


if __name__ == "__main__":
    unittest.main()
