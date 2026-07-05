#!/usr/bin/env python3
"""Tests for Commander external cut-source research planning."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_external_cut_source_research_plan as plan


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def same_lane_payload() -> dict[str, object]:
    return {
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "usage_blocked_hypothesis_count": 1,
            "seen_without_usage_count": 1,
            "explicit_same_lane_route_count": 0,
            "package_explicit_add_axes": ["angels_demons_dragons_payoffs"],
        },
        "hypothesis_same_lane_rows": [
            {
                "cut_card": "Necropotence",
                "trace_group": "usage_blocked",
                "cut_roles": ["card_draw_selection"],
                "same_lane_replacement_routes": [],
                "incidental_role_overlaps": [{"add_card": "Dragon Mage"}],
            },
            {
                "cut_card": "Puresteel Paladin",
                "trace_group": "seen_without_usage",
                "cut_roles": ["card_draw_selection"],
                "same_lane_replacement_routes": [],
                "incidental_role_overlaps": [],
            },
        ],
    }


class GlobalCommanderExternalCutSourceResearchPlanTests(unittest.TestCase):
    def test_external_research_plan_keeps_deck_actions_closed(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        payload = plan.build_report(
            same_lane_proof_report=write_json(root, "same_lane.json", same_lane_payload()),
            package_synthesis_report=write_json(root, "package.json", {"selected_add_package": []}),
        )

        self.assertEqual(payload["status"], "external_cut_source_research_plan_ready_no_deck_action")
        self.assertEqual(payload["summary"]["next_gate"], "collect_external_commander_reference_corpus_for_cut_candidates")
        self.assertEqual(payload["summary"]["external_source_count"], len(plan.EXTERNAL_SOURCE_SNAPSHOTS))
        self.assertFalse(payload["candidate_copy_allowed_now"])
        self.assertFalse(payload["value_safe_reclassification_allowed_now"])
        self.assertFalse(payload["battle_gate_allowed_now"])
        rows = {row["cut_card"]: row for row in payload["hypothesis_external_research_rows"]}
        self.assertEqual(
            rows["Necropotence"]["research_status"],
            "external_research_cannot_override_target_usage",
        )
        self.assertEqual(
            rows["Puresteel Paladin"]["research_status"],
            "external_research_requires_negative_trace_review_first",
        )


if __name__ == "__main__":
    unittest.main()
