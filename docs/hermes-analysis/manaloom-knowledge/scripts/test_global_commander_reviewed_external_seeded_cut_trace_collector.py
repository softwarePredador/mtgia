#!/usr/bin/env python3
"""Tests for reviewed external seeded cut trace collection."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_reviewed_external_seeded_cut_trace_collector as collector


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def write_jsonl(root: Path, name: str, rows: list[dict[str, object]]) -> Path:
    path = root / name
    path.write_text("\n".join(json.dumps(row) for row in rows) + "\n", encoding="utf-8")
    return path


def miner_payload() -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "fresh_seeded_same_lane_cut_sources": [
            {
                "card_name": "Basalt Monolith",
                "target_cut_role": "mana_acceleration",
                "score": 58,
                "source_reasons": ["fresh_same_lane_mana_acceleration"],
            },
            {
                "card_name": "Monologue Tax",
                "target_cut_role": "mana_acceleration",
                "score": 58,
                "source_reasons": ["fresh_same_lane_mana_acceleration"],
            },
        ],
    }


def trace_payload(events: Path, decisions: Path) -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "seed_reports": [{"seed": 42, "events_path": str(events), "decisions_path": str(decisions)}],
    }


class GlobalCommanderReviewedExternalSeededCutTraceCollectorTests(unittest.TestCase):
    def test_target_usage_blocks_seeded_hypothesis_cut(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        events = write_jsonl(
            root,
            "events.jsonl",
            [
                {"event": "spell_cast", "player": "Kaalia of the Vast", "card": "Basalt Monolith", "turn": 4},
                {"event": "spell_cast", "player": "Opponent", "card": "Monologue Tax", "turn": 5},
            ],
        )
        decisions = write_jsonl(root, "decisions.jsonl", [])

        report = collector.build_report(
            seeded_miner_report=write_json(root, "miner.json", miner_payload()),
            trace_generator_report=write_json(root, "trace.json", trace_payload(events, decisions)),
        )

        rows = {row["cut_card"]: row for row in report["review_rows"]}
        self.assertEqual(report["status"], "reviewed_external_seeded_cut_trace_blocks_used_hypotheses")
        self.assertEqual(rows["Basalt Monolith"]["status"], "reviewed_seeded_cut_hypothesis_used_by_target_trace_blocks_cut")
        self.assertEqual(rows["Monologue Tax"]["status"], "reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace")
        self.assertFalse(report["candidate_copy_allowed_now"])

    def test_seen_without_usage_requires_negative_review(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        events = write_jsonl(
            root,
            "events.jsonl",
            [{"event": "card_drawn", "player": "Kaalia of the Vast", "card": "Monologue Tax", "turn": 3}],
        )
        decisions = write_jsonl(root, "decisions.jsonl", [])

        report = collector.build_report(
            seeded_miner_report=write_json(root, "miner.json", miner_payload()),
            trace_generator_report=write_json(root, "trace.json", trace_payload(events, decisions)),
        )

        rows = {row["cut_card"]: row for row in report["review_rows"]}
        self.assertEqual(report["status"], "reviewed_external_seeded_cut_trace_needs_negative_review")
        self.assertEqual(
            rows["Monologue Tax"]["status"],
            "reviewed_seeded_cut_hypothesis_seen_without_usage_needs_negative_review",
        )
        self.assertEqual(report["summary"]["seen_without_usage_count"], 1)
        self.assertFalse(report["value_safe_reclassification_allowed_now"])

    def test_unseen_hypotheses_need_force_access(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        events = write_jsonl(root, "events.jsonl", [])
        decisions = write_jsonl(root, "decisions.jsonl", [])

        report = collector.build_report(
            seeded_miner_report=write_json(root, "miner.json", miner_payload()),
            trace_generator_report=write_json(root, "trace.json", trace_payload(events, decisions)),
        )

        self.assertEqual(report["status"], "reviewed_external_seeded_cut_trace_needs_force_access")
        self.assertEqual(report["summary"]["not_seen_count"], 2)
        self.assertEqual(report["summary"]["next_gate"], "force_access_or_expand_replay_window_for_seeded_hypotheses")
        self.assertFalse(report["battle_gate_allowed_now"])


if __name__ == "__main__":
    unittest.main()
