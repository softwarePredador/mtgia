#!/usr/bin/env python3
"""Tests for current-deck external nonpayoff negative review collection."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_external_nonpayoff_current_deck_negative_review_collector as collector


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def write_jsonl(root: Path, name: str, rows: list[dict[str, object]]) -> Path:
    path = root / name
    path.write_text("\n".join(json.dumps(row) for row in rows) + "\n", encoding="utf-8")
    return path


def router_payload() -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "current_deck_negative_review_rows": [
            {"card_name": "Arcane Signet", "target_cut_role": "mana_acceleration", "review_status": "current_deck"},
            {"card_name": "Demonic Tutor", "target_cut_role": "tutors_access", "review_status": "current_deck"},
        ],
    }


def trace_payload(events: Path, decisions: Path) -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "seed_reports": [{"seed": 42, "events_path": str(events), "decisions_path": str(decisions)}],
    }


class GlobalCommanderExternalNonpayoffCurrentDeckNegativeReviewCollectorTests(unittest.TestCase):
    def test_usage_blocks_negative_review(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        events = write_jsonl(
            root,
            "events.jsonl",
            [{"event": "spell_cast", "player": "Kaalia of the Vast", "card": "Arcane Signet", "turn": 2}],
        )
        decisions = write_jsonl(root, "decisions.jsonl", [])

        report = collector.build_report(
            recovery_router_report=write_json(root, "router.json", router_payload()),
            trace_generator_report=write_json(root, "trace.json", trace_payload(events, decisions)),
        )

        rows = {row["card_name"]: row for row in report["review_rows"]}
        self.assertEqual(report["status"], "external_current_deck_negative_review_blocks_used_candidates")
        self.assertEqual(rows["Arcane Signet"]["status"], "external_current_deck_candidate_used_by_target_blocks_negative_review")
        self.assertFalse(report["candidate_copy_allowed_now"])

    def test_seen_without_usage_requires_manual_review(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        events = write_jsonl(
            root,
            "events.jsonl",
            [{"event": "card_drawn", "player": "Kaalia of the Vast", "card": "Demonic Tutor", "turn": 3}],
        )
        decisions = write_jsonl(root, "decisions.jsonl", [])

        report = collector.build_report(
            recovery_router_report=write_json(root, "router.json", router_payload()),
            trace_generator_report=write_json(root, "trace.json", trace_payload(events, decisions)),
        )

        rows = {row["card_name"]: row for row in report["review_rows"]}
        self.assertEqual(report["status"], "external_current_deck_negative_review_needs_manual_review")
        self.assertEqual(
            rows["Demonic Tutor"]["status"],
            "external_current_deck_candidate_seen_without_usage_needs_manual_negative_review",
        )
        self.assertFalse(report["negative_review_cleared_now"])

    def test_unseen_candidates_need_force_access_or_broader_trace(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        events = write_jsonl(root, "events.jsonl", [])
        decisions = write_jsonl(root, "decisions.jsonl", [])

        report = collector.build_report(
            recovery_router_report=write_json(root, "router.json", router_payload()),
            trace_generator_report=write_json(root, "trace.json", trace_payload(events, decisions)),
        )

        self.assertEqual(report["status"], "external_current_deck_negative_review_needs_force_access")
        self.assertEqual(report["summary"]["not_seen_count"], 2)
        self.assertEqual(report["summary"]["next_gate"], "force_access_or_expand_replay_window_for_external_current_deck_candidates")
        self.assertFalse(report["battle_gate_allowed_now"])


if __name__ == "__main__":
    unittest.main()
