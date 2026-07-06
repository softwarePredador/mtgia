#!/usr/bin/env python3
"""Tests for engine cut trace/replacement reviewer."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_engine_cut_trace_replacement_reviewer as reviewer


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def trace_replacement_payload() -> dict[str, object]:
    return {
        "status": "engine_cut_trace_replacement_gate_needs_trace_review",
        "trace_review_rows": [
            {
                "card_name": "Archaeomancer's Map",
                "status": "engine_cut_natural_trace_seen_without_usage_needs_manual_negative_review",
                "usage_event_count": 0,
                "exposure_event_count": 0,
                "decision_trace_count": 1,
                "first_decision_trace": {
                    "chosen_option_score": 85,
                    "chosen_option": {"card": "The One Ring"},
                    "rejected_options": [
                        {"card": "Archaeomancer's Map", "score": 85, "effect": "ramp_engine"}
                    ],
                },
            }
        ],
        "replacement_candidate_rows": [
            {
                "card_name": "Storm-Kiln Artist",
                "status": "same_lane_engine_candidate_needs_source_trace_review",
                "role_signals": ["artifact_engine_overlap", "treasure_engine"],
                "type_line": "Creature — Dwarf Shaman",
                "oracle_excerpt": "Whenever you cast or copy an instant or sorcery spell, create a Treasure token.",
            },
            {
                "card_name": "Mind Stone",
                "status": "adjacent_engine_candidate_needs_explicit_same_lane_proof",
                "role_signals": ["artifact_engine_overlap"],
                "type_line": "Artifact",
                "oracle_excerpt": "{T}: Add {C}. {1}, {T}, Sacrifice this artifact: Draw a card.",
            },
        ],
    }


class GlobalCommanderEngineCutTraceReplacementReviewerTests(unittest.TestCase):
    def test_equal_score_tutor_candidate_blocks_negative_clearance(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = write_json(root, "trace.json", trace_replacement_payload())
            report = reviewer.build_report(trace_replacement_report=source)

        self.assertEqual(report["status"], "engine_cut_trace_replacement_review_blocks_candidate_copy")
        self.assertFalse(report["candidate_copy_allowed_now"])
        trace = report["trace_review_rows"][0]
        self.assertEqual(
            trace["review_status"],
            "trace_review_blocks_negative_clearance_equal_score_tutor_candidate",
        )
        self.assertEqual(trace["score_gap_vs_chosen"], 0.0)
        self.assertEqual(report["summary"]["explicit_same_lane_replacement_proof_count"], 0)
        self.assertIn("no_exact_artifact_spell_engine_replacement_proof", report["candidate_copy_blockers"])

    def test_exact_artifact_spell_engine_candidate_is_counted(self) -> None:
        payload = trace_replacement_payload()
        payload["replacement_candidate_rows"] = [
            {
                "card_name": "Exact Engine",
                "status": "same_lane_engine_candidate_needs_source_trace_review",
                "type_line": "Artifact Creature",
                "oracle_excerpt": "Whenever you cast an artifact spell, create a Treasure token.",
            }
        ]

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = write_json(root, "trace.json", payload)
            report = reviewer.build_report(trace_replacement_report=source)

        self.assertEqual(report["summary"]["exact_artifact_engine_candidate_count"], 1)
        self.assertEqual(report["summary"]["explicit_same_lane_replacement_proof_count"], 1)
        self.assertEqual(
            report["replacement_review"]["next_gate"],
            "source_trace_exact_artifact_engine_candidates_before_candidate_copy",
        )


if __name__ == "__main__":
    unittest.main()
