#!/usr/bin/env python3
"""Tests for manual current-deck negative trace review."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_manual_negative_trace_reviewer as reviewer


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


class GlobalCommanderExternalNonpayoffManualNegativeTraceReviewerTests(unittest.TestCase):
    def test_static_and_land_seen_without_usage_do_not_clear_negative_review(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        router = write_json(
            root,
            "router.json",
            {
                "current_deck_negative_review_rows": [
                    {
                        "card_name": "Grand Abolisher",
                        "type_line": "Creature - Human Cleric",
                        "local_role_evidence_terms": ["can't cast spells"],
                    },
                    {
                        "card_name": "Arena of Glory",
                        "type_line": "Land",
                        "local_role_evidence_terms": ["add {r}"],
                    },
                    {
                        "card_name": "Silence",
                        "type_line": "Instant",
                        "local_role_evidence_terms": ["can't cast spells this turn"],
                    },
                ]
            },
        )
        negative = write_json(
            root,
            "negative.json",
            {
                "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
                "input_artifacts": {"recovery_router_report": str(router)},
                "review_rows": [
                    {
                        "card_name": "Grand Abolisher",
                        "target_cut_role": "haste_protection_silence",
                        "status": "external_current_deck_candidate_seen_without_usage_needs_manual_negative_review",
                        "usage_event_count": 0,
                        "exposure_event_count": 1,
                        "decision_trace_count": 2,
                        "event_types": {"turn_end": 1},
                    },
                    {
                        "card_name": "Arena of Glory",
                        "target_cut_role": "mana_acceleration",
                        "status": "external_current_deck_candidate_seen_without_usage_needs_manual_negative_review",
                        "usage_event_count": 0,
                        "exposure_event_count": 19,
                        "decision_trace_count": 1,
                        "event_types": {"land_played": 7},
                    },
                    {
                        "card_name": "Silence",
                        "target_cut_role": "haste_protection_silence",
                        "status": "external_current_deck_candidate_used_by_target_blocks_negative_review",
                        "usage_event_count": 12,
                        "exposure_event_count": 1,
                        "decision_trace_count": 18,
                        "event_types": {"spell_cast": 3},
                    },
                ],
            },
        )

        report = reviewer.build_report(negative_review_report=negative)

        self.assertEqual(report["status"], "external_nonpayoff_manual_negative_trace_review_blocks_current_deck_cuts")
        self.assertEqual(report["summary"]["manual_negative_review_cleared_count"], 0)
        statuses = {row["card_name"]: row["manual_review_status"] for row in report["review_rows"]}
        self.assertEqual(
            statuses["Grand Abolisher"],
            "manual_negative_trace_review_blocks_static_silence_without_activation",
        )
        self.assertEqual(
            statuses["Arena of Glory"],
            "manual_negative_trace_review_blocks_land_lane_seen_without_usage",
        )
        self.assertEqual(
            statuses["Silence"],
            "manual_negative_trace_review_blocks_used_current_deck_card",
        )
        self.assertFalse(report["candidate_copy_allowed_now"])


if __name__ == "__main__":
    unittest.main()
