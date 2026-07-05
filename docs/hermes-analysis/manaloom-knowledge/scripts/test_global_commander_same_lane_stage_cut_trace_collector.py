#!/usr/bin/env python3
"""Tests for same-lane stage cut trace collection."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_same_lane_stage_cut_trace_collector as collector


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def write_jsonl(root: Path, name: str, rows: list[dict[str, object]]) -> Path:
    path = root / name
    path.write_text("\n".join(json.dumps(row) for row in rows) + "\n", encoding="utf-8")
    return path


def evidence_plan(root: Path, cards: list[str]) -> Path:
    return write_json(
        root,
        "evidence_plan.json",
        {
            "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
            "evidence_plan_rows": [
                {
                    "card_name": card,
                    "target_cut_role": "tutors_access",
                    "status": "same_lane_stage_only_cut_needs_evidence",
                    "score": 50,
                    "stage_reasons": ["contextual_staple_requires_stage_review"],
                    "evidence_lanes": ["contextual_staple_usage_and_replacement_review"],
                    "maximum_evidence_burden": 4,
                }
                for card in cards
            ],
        },
    )


def trace_report(root: Path, events: Path, decisions: Path) -> Path:
    return write_json(
        root,
        "trace_generator.json",
        {
            "status": "test_trace_generator",
            "seed_reports": [
                {
                    "seed": 42,
                    "events_path": str(events),
                    "decisions_path": str(decisions),
                }
            ],
        },
    )


class GlobalCommanderSameLaneStageCutTraceCollectorTests(unittest.TestCase):
    def test_usage_trace_blocks_value_safe_reclassification(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        plan = evidence_plan(root, ["Diabolic Intent", "Ornithopter of Paradise"])
        events = write_jsonl(
            root,
            "events.jsonl",
            [
                {"event": "spell_cast", "player": "Kaalia of the Vast", "card": "Diabolic Intent"},
                {"event": "card_drawn", "player": "Kaalia of the Vast", "card": "Ornithopter of Paradise"},
            ],
        )
        decisions = write_jsonl(
            root,
            "decisions.jsonl",
            [{"decision_type": "keep", "player": "Kaalia of the Vast", "card": "Ornithopter of Paradise"}],
        )

        report = collector.build_report(
            evidence_plan_report=plan,
            trace_generator_report=trace_report(root, events, decisions),
            scan_roots=[root],
        )

        self.assertEqual(report["status"], "same_lane_stage_cut_trace_collection_blocks_used_cuts")
        self.assertEqual(report["summary"]["usage_blocked_count"], 1)
        self.assertEqual(report["summary"]["seen_without_usage_count"], 1)
        by_card = {row["card_name"]: row for row in report["review_rows"]}
        self.assertEqual(by_card["Diabolic Intent"]["status"], "same_lane_stage_cut_usage_trace_blocks_value_safe")
        self.assertEqual(
            by_card["Ornithopter of Paradise"]["status"],
            "same_lane_stage_cut_seen_without_usage_needs_negative_review",
        )
        self.assertFalse(report["candidate_copy_allowed_now"])

    def test_external_reference_alone_needs_internal_trace(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        plan = evidence_plan(root, ["Smothering Tithe"])
        external = root / "external_reference_corpus.md"
        external.write_text("EDHREC corpus mentions Smothering Tithe in Kaalia shells.\n", encoding="utf-8")

        report = collector.build_report(
            evidence_plan_report=plan,
            trace_generator_report=None,
            scan_roots=[root],
        )

        self.assertEqual(report["status"], "same_lane_stage_cut_trace_collection_has_external_references_only")
        self.assertEqual(report["summary"]["external_reference_only_count"], 1)
        self.assertEqual(report["review_rows"][0]["status"], "same_lane_stage_cut_external_reference_needs_internal_trace")
        self.assertFalse(report["value_safe_reclassification_allowed_now"])

    def test_missing_trace_and_external_routes_to_trace_generation(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        plan = evidence_plan(root, ["Hammer of Nazahn"])

        report = collector.build_report(
            evidence_plan_report=plan,
            trace_generator_report=None,
            scan_roots=[root],
        )

        self.assertEqual(report["status"], "same_lane_stage_cut_trace_collection_needs_trace_generation")
        self.assertEqual(report["summary"]["needs_trace_or_external_research_count"], 1)
        self.assertEqual(report["summary"]["next_gate"], "generate_or_import_same_lane_stage_cut_usage_traces")


if __name__ == "__main__":
    unittest.main()
