#!/usr/bin/env python3
"""Tests for contextual Commander usage trace review."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_contextual_usage_trace_reviewer as reviewer


def generator_report(rows: dict[str, dict[str, object]]) -> dict[str, object]:
    return {
        "status": "contextual_usage_trace_generated_all_current_usage_review_required",
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "aggregate_card_trace": rows,
    }


class GlobalCommanderContextualUsageTraceReviewerTests(unittest.TestCase):
    def _json(self, root: Path, payload: dict[str, object]) -> Path:
        path = root / "generator.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_usage_observed_blocks_value_safe_reclassification(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        report = self._json(
            root,
            generator_report(
                {
                    "Diabolic Intent": {
                        "usage_event_count": 2,
                        "exposure_event_count": 0,
                        "decision_trace_count": 1,
                        "event_types": {"spell_resolved": 1},
                    }
                }
            ),
        )

        payload = reviewer.build_report(trace_generator_report=report)

        self.assertEqual(payload["status"], "contextual_usage_trace_review_blocks_value_safe_reclassification")
        self.assertFalse(payload["value_safe_reclassification_allowed_now"])
        self.assertFalse(payload["candidate_copy_allowed_now"])
        self.assertEqual(payload["summary"]["usage_blocked_cards"], ["Diabolic Intent"])
        self.assertEqual(payload["review_rows"][0]["decision"], "not_value_safe_from_current_trace")
        self.assertIn("contextual_cards_used_by_target_deck:Diabolic Intent", payload["candidate_copy_blockers"])

    def test_not_seen_requires_more_trace(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        report = self._json(
            root,
            generator_report(
                {
                    "Ornithopter of Paradise": {
                        "usage_event_count": 0,
                        "exposure_event_count": 0,
                        "decision_trace_count": 0,
                        "event_types": {},
                    }
                }
            ),
        )

        payload = reviewer.build_report(trace_generator_report=report)

        self.assertEqual(payload["status"], "contextual_usage_trace_review_needs_more_trace")
        self.assertEqual(payload["summary"]["next_gate"], "increase_seed_count_or_force_access_trace_for_contextual_cards")
        self.assertEqual(payload["review_rows"][0]["decision"], "insufficient_evidence")


if __name__ == "__main__":
    unittest.main()
