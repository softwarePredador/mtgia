#!/usr/bin/env python3
"""Tests for Commander cut-hypothesis same-lane proof modeling."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_cut_hypothesis_same_lane_proof as model


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def trace_payload(status: str = "hypothesis_used_by_target_trace_blocks_value_safe") -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "review_rows": [
            {
                "cut_card": "Necropotence",
                "status": status,
                "profile_roles": ["card_draw_selection", "dedicated_win_conditions"],
                "usage_event_count": 2 if "used" in status else 0,
                "exposure_event_count": 0,
                "decision_trace_count": 1,
            }
        ],
    }


def miner_payload() -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "fresh_cut_source_hypotheses": [
            {
                "card_name": "Necropotence",
                "score": 51,
                "profile_roles": ["card_draw_selection", "dedicated_win_conditions"],
                "reasons": ["above_target_card_draw_selection"],
            }
        ],
    }


class GlobalCommanderCutHypothesisSameLaneProofTests(unittest.TestCase):
    def _run_model(
        self,
        *,
        package_payload: dict[str, object],
        trace: dict[str, object] | None = None,
    ) -> dict[str, object]:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        return model.build_report(
            trace_collector_report=write_json(root, "trace.json", trace or trace_payload()),
            miner_report=write_json(root, "miner.json", miner_payload()),
            package_synthesis_report=write_json(root, "package.json", package_payload),
        )

    def test_incidental_profile_overlap_does_not_create_same_lane_route(self) -> None:
        payload = self._run_model(
            package_payload={
                "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
                "selected_add_package": [
                    {
                        "card_name": "Dragon Mage",
                        "profile_roles": ["angels_demons_dragons_payoffs", "card_draw_selection"],
                        "covered_axes": ["angels_demons_dragons_payoffs"],
                        "selected_for_axis": "angels_demons_dragons_payoffs",
                        "score": 98,
                    }
                ],
            }
        )

        self.assertEqual(payload["status"], "cut_hypothesis_same_lane_proof_routes_to_more_mining")
        self.assertEqual(payload["summary"]["explicit_same_lane_route_count"], 0)
        self.assertEqual(payload["summary"]["incidental_role_overlap_count"], 1)
        self.assertFalse(payload["candidate_copy_allowed_now"])
        self.assertEqual(
            payload["hypothesis_same_lane_rows"][0]["decision"],
            "blocked_no_explicit_same_lane_route_for_used_hypothesis",
        )

    def test_explicit_same_lane_route_still_requires_proof_before_copy(self) -> None:
        payload = self._run_model(
            package_payload={
                "selected_add_package": [
                    {
                        "card_name": "Dedicated Draw Replacement",
                        "profile_roles": ["card_draw_selection"],
                        "covered_axes": ["card_draw_selection"],
                        "selected_for_axis": "card_draw_selection",
                        "score": 80,
                    }
                ],
            }
        )

        self.assertEqual(payload["status"], "cut_hypothesis_same_lane_proof_needs_explicit_evidence")
        self.assertEqual(payload["summary"]["explicit_same_lane_route_count"], 1)
        self.assertFalse(payload["same_lane_replacement_proof_allowed_now"])
        self.assertFalse(payload["value_safe_reclassification_allowed_now"])
        self.assertFalse(payload["battle_gate_allowed_now"])
        self.assertEqual(
            payload["hypothesis_same_lane_rows"][0]["decision"],
            "explicit_same_lane_route_found_but_proof_still_required",
        )

    def test_seen_without_usage_requires_negative_review_without_copy(self) -> None:
        payload = self._run_model(
            trace=trace_payload("hypothesis_seen_without_usage_needs_negative_review"),
            package_payload={"selected_add_package": []},
        )

        self.assertEqual(payload["status"], "cut_hypothesis_same_lane_proof_needs_negative_review")
        self.assertEqual(payload["summary"]["seen_without_usage_count"], 1)
        self.assertEqual(
            payload["summary"]["next_gate"],
            "manual_negative_review_or_force_access_for_seen_hypotheses",
        )
        self.assertFalse(payload["candidate_copy_allowed_now"])


if __name__ == "__main__":
    unittest.main()
