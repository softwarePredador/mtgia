#!/usr/bin/env python3
"""Tests for Commander same-lane replacement modeling."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_same_lane_replacement_model as model


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def usage_report(card_name: str = "Professional Face-Breaker") -> dict[str, object]:
    return {
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "review_rows": [
            {
                "card_name": card_name,
                "status": "usage_observed_blocks_value_safe_reclassification",
                "usage_event_count": 4,
                "decision_trace_count": 2,
            }
        ],
    }


def cut_report(card_name: str = "Professional Face-Breaker") -> dict[str, object]:
    return {
        "stage_only_cut_candidates": [
            {
                "card_name": card_name,
                "profile_roles": ["card_draw_selection", "mana_acceleration"],
                "matching_over_target_roles": ["mana_acceleration"],
                "stage_reasons": ["contextual_staple_requires_stage_review"],
                "score": 61,
            },
            {
                "card_name": "Jeska's Will",
                "profile_roles": ["mana_acceleration"],
                "matching_over_target_roles": ["mana_acceleration"],
                "stage_reasons": ["structural_foundation_staple_requires_same_lane_or_battle_proof"],
                "score": 60,
            },
        ]
    }


def plan_report(card_name: str = "Professional Face-Breaker") -> dict[str, object]:
    return {
        "evidence_plan_rows": [
            {
                "card_name": card_name,
                "matching_over_target_roles": ["mana_acceleration"],
                "maximum_evidence_burden": 1,
                "evidence_lanes": ["contextual_staple_same_lane_usage_review"],
            },
            {
                "card_name": "Jeska's Will",
                "matching_over_target_roles": ["mana_acceleration"],
                "maximum_evidence_burden": 5,
                "evidence_lanes": ["structural_staple_same_lane_or_equal_gate_proof"],
            },
        ]
    }


class GlobalCommanderSameLaneReplacementModelTests(unittest.TestCase):
    def _run_model(
        self,
        *,
        package_payload: dict[str, object],
        usage_payload: dict[str, object] | None = None,
    ) -> dict[str, object]:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        usage_path = write_json(root, "usage.json", usage_payload or usage_report())
        plan_path = write_json(root, "plan.json", plan_report())
        cut_path = write_json(root, "cut.json", cut_report())
        package_path = write_json(root, "package.json", package_payload)
        return model.build_report(
            usage_reviewer_report=usage_path,
            stage_only_cut_evidence_plan=plan_path,
            cut_source_lane_report=cut_path,
            package_synthesis_report=package_path,
        )

    def test_incidental_overlap_does_not_create_same_lane_proof(self) -> None:
        payload = self._run_model(
            package_payload={
                "selected_add_package": [
                    {
                        "card_name": "Bonehoard Dracosaur",
                        "profile_roles": ["angels_demons_dragons_payoffs", "mana_acceleration"],
                        "covered_axes": ["angels_demons_dragons_payoffs"],
                        "selected_for_axis": "angels_demons_dragons_payoffs",
                        "score": 97,
                    }
                ]
            }
        )

        self.assertEqual(payload["status"], "same_lane_replacement_model_routes_to_new_cut_source_lane")
        self.assertEqual(payload["summary"]["same_lane_replacement_route_count"], 0)
        self.assertEqual(payload["summary"]["incidental_role_overlap_count"], 1)
        self.assertFalse(payload["candidate_copy_allowed_now"])
        self.assertEqual(
            payload["usage_blocked_replacement_rows"][0]["decision"],
            "blocked_no_same_lane_replacement_route",
        )
        self.assertEqual(payload["remaining_cut_source_lane_rows"][0]["cut_card"], "Jeska's Will")

    def test_explicit_same_lane_route_still_requires_proof_before_copy(self) -> None:
        payload = self._run_model(
            package_payload={
                "selected_add_package": [
                    {
                        "card_name": "Dedicated Ramp Replacement",
                        "profile_roles": ["mana_acceleration"],
                        "covered_axes": ["mana_acceleration"],
                        "selected_for_axis": "mana_acceleration",
                        "score": 80,
                    }
                ]
            }
        )

        self.assertEqual(payload["status"], "same_lane_replacement_model_needs_proof_before_candidate_copy")
        self.assertEqual(payload["summary"]["same_lane_replacement_route_count"], 1)
        self.assertFalse(payload["same_lane_replacement_proof_allowed_now"])
        self.assertFalse(payload["value_safe_reclassification_allowed_now"])
        self.assertFalse(payload["battle_gate_allowed_now"])
        self.assertEqual(
            payload["usage_blocked_replacement_rows"][0]["decision"],
            "same_lane_replacement_route_found_but_unproven",
        )


if __name__ == "__main__":
    unittest.main()
