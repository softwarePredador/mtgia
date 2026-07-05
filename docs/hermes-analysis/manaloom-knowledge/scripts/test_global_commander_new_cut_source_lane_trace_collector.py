#!/usr/bin/env python3
"""Tests for remaining cut-source trace collection."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_new_cut_source_lane_trace_collector as collector


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def write_jsonl(root: Path, name: str, rows: list[dict[str, object]]) -> Path:
    path = root / name
    path.write_text("\n".join(json.dumps(row) for row in rows) + "\n", encoding="utf-8")
    return path


def model_payload() -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "remaining_cut_source_lane_rows": [
            {
                "cut_card": "Sunforger",
                "cut_roles": ["tutors_access"],
                "maximum_evidence_burden": 3,
                "recommended_next_route": "collect_attack_window_same_lane_replacement_trace",
            },
            {
                "cut_card": "Dark Ritual",
                "cut_roles": ["mana_acceleration"],
                "maximum_evidence_burden": 5,
                "recommended_next_route": "collect_structural_staple_same_lane_or_equal_gate_proof",
            },
        ],
    }


class GlobalCommanderNewCutSourceLaneTraceCollectorTests(unittest.TestCase):
    def test_target_usage_blocks_remaining_cut_and_ignores_opponent_event(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        events = write_jsonl(
            root,
            "events.jsonl",
            [
                {"event": "spell_cast", "player": "Opponent", "card": "Dark Ritual", "turn": 2},
                {"event": "spell_cast", "player": "Kaalia of the Vast", "card": "Sunforger", "turn": 4},
            ],
        )
        decisions = write_jsonl(root, "decisions.jsonl", [])
        trace = write_json(
            root,
            "trace.json",
            {
                "summary": {"commander": "Kaalia of the Vast"},
                "seed_reports": [{"seed": 42, "events_path": str(events), "decisions_path": str(decisions)}],
            },
        )
        model = write_json(root, "model.json", model_payload())

        payload = collector.build_report(same_lane_model_report=model, trace_generator_report=trace)

        self.assertEqual(payload["status"], "new_cut_source_lane_trace_blocks_used_remaining_cuts")
        self.assertEqual(payload["summary"]["usage_blocked_remaining_cut_count"], 1)
        self.assertEqual(payload["summary"]["not_seen_count"], 1)
        sunforger = next(row for row in payload["review_rows"] if row["cut_card"] == "Sunforger")
        dark_ritual = next(row for row in payload["review_rows"] if row["cut_card"] == "Dark Ritual")
        self.assertEqual(sunforger["status"], "remaining_cut_used_by_target_trace_blocks_value_safe")
        self.assertEqual(dark_ritual["status"], "remaining_cut_not_seen_needs_forced_access_or_more_trace")
        self.assertFalse(payload["candidate_copy_allowed_now"])

    def test_decision_only_trace_requires_negative_review(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        events = write_jsonl(root, "events.jsonl", [])
        decisions = write_jsonl(
            root,
            "decisions.jsonl",
            [{"decision_type": "mulligan_decision", "player": "Kaalia of the Vast", "reason": "Dark Ritual"}],
        )
        trace = write_json(
            root,
            "trace.json",
            {
                "summary": {"commander": "Kaalia of the Vast"},
                "seed_reports": [{"seed": 42, "events_path": str(events), "decisions_path": str(decisions)}],
            },
        )
        model = write_json(root, "model.json", model_payload())

        payload = collector.build_report(same_lane_model_report=model, trace_generator_report=trace)

        dark_ritual = next(row for row in payload["review_rows"] if row["cut_card"] == "Dark Ritual")
        self.assertEqual(dark_ritual["status"], "remaining_cut_seen_without_usage_needs_negative_review")
        self.assertEqual(payload["summary"]["seen_without_usage_count"], 1)
        self.assertFalse(payload["value_safe_reclassification_allowed_now"])


if __name__ == "__main__":
    unittest.main()
