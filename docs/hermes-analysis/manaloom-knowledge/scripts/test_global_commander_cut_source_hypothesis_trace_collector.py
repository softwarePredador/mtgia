#!/usr/bin/env python3
"""Tests for Commander cut-source hypothesis trace collection."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_cut_source_hypothesis_trace_collector as collector


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
        "fresh_cut_source_hypotheses": [
            {"card_name": "Biotransference", "score": 60, "reasons": ["off_profile_or_unclassified_slot"]},
            {"card_name": "Maskwood Nexus", "score": 60, "reasons": ["off_profile_or_unclassified_slot"]},
        ],
    }


class GlobalCommanderCutSourceHypothesisTraceCollectorTests(unittest.TestCase):
    def test_target_usage_blocks_hypothesis_value_safe_reclassification(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        events = write_jsonl(
            root,
            "events.jsonl",
            [
                {"event": "spell_cast", "player": "Kaalia of the Vast", "card": "Biotransference", "turn": 3},
                {"event": "spell_cast", "player": "Opponent", "card": "Maskwood Nexus", "turn": 4},
            ],
        )
        decisions = write_jsonl(root, "decisions.jsonl", [])
        trace = write_json(
            root,
            "trace.json",
            {
                "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
                "seed_reports": [{"seed": 1, "events_path": str(events), "decisions_path": str(decisions)}],
            },
        )

        payload = collector.build_report(
            miner_report=write_json(root, "miner.json", miner_payload()),
            trace_generator_report=trace,
        )

        self.assertEqual(payload["status"], "cut_source_hypothesis_trace_blocks_used_hypotheses")
        rows = {row["cut_card"]: row for row in payload["review_rows"]}
        self.assertEqual(rows["Biotransference"]["status"], "hypothesis_used_by_target_trace_blocks_value_safe")
        self.assertEqual(rows["Maskwood Nexus"]["status"], "hypothesis_not_seen_needs_more_trace_or_force_access")
        self.assertFalse(payload["candidate_copy_allowed_now"])

    def test_unseen_hypotheses_require_more_trace(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        events = write_jsonl(root, "events.jsonl", [])
        decisions = write_jsonl(root, "decisions.jsonl", [])
        trace = write_json(
            root,
            "trace.json",
            {
                "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
                "seed_reports": [{"seed": 1, "events_path": str(events), "decisions_path": str(decisions)}],
            },
        )

        payload = collector.build_report(
            miner_report=write_json(root, "miner.json", miner_payload()),
            trace_generator_report=trace,
        )

        self.assertEqual(payload["status"], "cut_source_hypothesis_trace_needs_more_replay")
        self.assertEqual(payload["summary"]["not_seen_count"], 2)
        self.assertEqual(payload["summary"]["next_gate"], "expand_replay_window_or_force_access_for_unseen_hypotheses")
        self.assertFalse(payload["value_safe_reclassification_allowed_now"])


if __name__ == "__main__":
    unittest.main()
