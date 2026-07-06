#!/usr/bin/env python3
"""Tests for ramp cut follow-up router."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_ramp_cut_followup_router as router


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def scout_payload() -> dict[str, object]:
    return {
        "status": "ramp_cut_usage_same_lane_proof_blocks_candidate_copy",
        "candidate_copy_blockers": [
            "usage_observed_blocks_ramp_cuts:Arcane Signet",
            "missing_current_scope_usage_trace_for_ramp_cuts:Basalt Monolith",
            "no_explicit_same_lane_replacement_route_for_ramp_cut_pairs",
        ],
        "cut_evidence_rows": [
            {
                "card_name": "Arcane Signet",
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "status": "ramp_cut_usage_observed_blocks_candidate_copy",
                "trace_group": "usage_blocked",
                "roles": ["ramp"],
                "matching_excess_roles": ["ramp"],
            },
            {
                "card_name": "Basalt Monolith",
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "status": "ramp_cut_missing_current_scope_usage_trace",
                "trace_group": "not_seen_or_no_trace",
                "roles": ["ramp"],
                "matching_excess_roles": ["ramp"],
            },
            {
                "card_name": "Grim Monolith",
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "status": "ramp_cut_text_trace_candidate_needs_structured_review",
                "trace_group": "not_seen_or_no_trace",
                "roles": ["ramp"],
                "matching_excess_roles": ["ramp"],
            },
        ],
        "pair_review_rows": [
            {
                "add": "Feed the Swarm",
                "cut": "Arcane Signet",
                "status": "ramp_cut_pair_blocks_candidate_copy",
                "candidate_role": "removal",
                "cut_roles": ["ramp"],
                "explicit_same_lane_roles": [],
                "blockers": ["cut_card_used_by_target_trace", "no_explicit_same_lane_replacement_route"],
            },
            {
                "add": "Feed the Swarm",
                "cut": "Basalt Monolith",
                "status": "ramp_cut_pair_blocks_candidate_copy",
                "candidate_role": "removal",
                "cut_roles": ["ramp"],
                "explicit_same_lane_roles": [],
                "blockers": ["cut_card_missing_current_scope_usage_trace", "no_explicit_same_lane_replacement_route"],
            },
            {
                "add": "Feed the Swarm",
                "cut": "Grim Monolith",
                "status": "ramp_cut_pair_blocks_candidate_copy",
                "candidate_role": "removal",
                "cut_roles": ["ramp"],
                "explicit_same_lane_roles": [],
                "blockers": ["cut_card_text_trace_needs_structured_review", "no_explicit_same_lane_replacement_route"],
            },
        ],
    }


class GlobalCommanderRampCutFollowupRouterTests(unittest.TestCase):
    def test_routes_trace_structured_review_and_replacement_required_cuts(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            scout = write_json(root, "scout.json", scout_payload())
            report = router.build_report(scout_report=scout)

        self.assertEqual(report["status"], "ramp_cut_followup_router_blocks_candidate_copy")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["summary"]["cut_count"], 3)
        self.assertEqual(report["summary"]["usage_blocked_cut_count"], 1)
        self.assertEqual(report["summary"]["missing_trace_cut_count"], 1)
        self.assertEqual(report["summary"]["structured_trace_review_required_count"], 1)
        self.assertEqual(report["summary"]["replacement_required_count"], 1)
        self.assertEqual(report["summary"]["trace_plan_count"], 1)
        self.assertEqual(report["summary"]["structured_review_count"], 1)
        self.assertEqual(report["summary"]["pair_ready_count"], 0)
        self.assertEqual(report["summary"]["no_explicit_same_lane_pair_count"], 3)
        self.assertEqual(
            report["summary"]["next_gate"],
            "run_trace_plan_structured_review_and_replacement_search_before_candidate_copy",
        )

        by_card = {row["card_name"]: row for row in report["cut_followup_rows"]}
        self.assertEqual(by_card["Arcane Signet"]["route_kind"], "replacement_required")
        self.assertEqual(by_card["Basalt Monolith"]["route_kind"], "trace_required")
        self.assertEqual(by_card["Grim Monolith"]["route_kind"], "structured_trace_review_required")
        blockers = report["candidate_copy_blockers"]
        self.assertIn("trace_required_for_ramp_cuts:Basalt Monolith", blockers)
        self.assertIn("structured_trace_review_required_for_ramp_cuts:Grim Monolith", blockers)
        self.assertIn("replacement_required_for_used_ramp_cuts:Arcane Signet", blockers)

    def test_no_same_lane_pair_keeps_pair_gate_closed(self) -> None:
        report = router.build_pair_followups(scout_payload(), router.build_cut_followups(scout_payload()))

        self.assertEqual(len(report), 3)
        self.assertTrue(all(not row["candidate_copy_allowed"] for row in report))
        self.assertTrue(
            all(
                row["pair_next_gate"]
                == "find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy"
                for row in report
            )
        )


if __name__ == "__main__":
    unittest.main()
