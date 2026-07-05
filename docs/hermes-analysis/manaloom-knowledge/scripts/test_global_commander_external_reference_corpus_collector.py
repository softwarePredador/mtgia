#!/usr/bin/env python3
"""Tests for Commander external reference corpus collection."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_external_reference_corpus_collector as collector


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def research_plan_payload() -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "hypothesis_external_research_rows": [
            {
                "cut_card": "Necropotence",
                "trace_group": "usage_blocked",
                "cut_roles": ["card_draw_selection"],
                "research_lane": "card_draw_selection",
            },
            {
                "cut_card": "Biotransference",
                "trace_group": "usage_blocked",
                "cut_roles": [],
                "research_lane": "off_profile_or_unclassified_cut_lane",
            },
            {
                "cut_card": "Puresteel Paladin",
                "trace_group": "seen_without_usage",
                "cut_roles": ["card_draw_selection"],
                "research_lane": "card_draw_selection",
            },
        ],
    }


def same_lane_payload() -> dict[str, object]:
    return {
        "hypothesis_same_lane_rows": [
            {
                "cut_card": "Necropotence",
                "trace_group": "usage_blocked",
                "cut_roles": ["card_draw_selection"],
            },
            {
                "cut_card": "Biotransference",
                "trace_group": "usage_blocked",
                "cut_roles": [],
            },
            {
                "cut_card": "Puresteel Paladin",
                "trace_group": "seen_without_usage",
                "cut_roles": ["card_draw_selection"],
            },
        ]
    }


class GlobalCommanderExternalReferenceCorpusCollectorTests(unittest.TestCase):
    def test_external_corpus_keeps_cut_permissions_closed(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        payload = collector.build_report(
            research_plan_report=write_json(root, "research.json", research_plan_payload()),
            same_lane_proof_report=write_json(root, "same_lane.json", same_lane_payload()),
        )

        self.assertEqual(payload["status"], "external_reference_corpus_collected_no_cut_permission")
        self.assertEqual(payload["summary"]["next_gate"], "map_external_corpus_to_cut_policy_before_rerun_miner")
        self.assertFalse(payload["candidate_copy_allowed_now"])
        self.assertFalse(payload["value_safe_reclassification_allowed_now"])
        self.assertFalse(payload["battle_gate_allowed_now"])

        rows = {row["cut_card"]: row for row in payload["card_corpus_rows"]}
        self.assertEqual(
            rows["Necropotence"]["corpus_status"],
            "external_corpus_supports_preserve_or_strict_same_lane_proof",
        )
        self.assertEqual(
            rows["Biotransference"]["corpus_status"],
            "external_absence_cannot_override_target_usage",
        )
        self.assertEqual(
            rows["Puresteel Paladin"]["corpus_status"],
            "external_absence_plus_seen_without_usage_requires_negative_review",
        )
        self.assertEqual(payload["summary"]["corpus_present_count"], 1)
        self.assertEqual(payload["summary"]["corpus_absent_count"], 2)


if __name__ == "__main__":
    unittest.main()
