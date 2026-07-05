#!/usr/bin/env python3
"""Tests for Commander profile blocker repair planning."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_profile_blocker_repair_plan as repair


def matrix_payload(*, blockers: list[str]) -> dict[str, object]:
    return {
        "status": "package_strategy_blocks_battle" if blockers else "package_strategy_ready_for_battle_probe",
        "battle_gate_allowed_now": not blockers,
        "summary": {"deck_id": "619", "commander": "Kaalia of the Vast"},
        "blocker_reasons": blockers,
        "target_evaluations": [
            {
                "role": "lands",
                "candidate_count": 34,
                "min": 35,
                "max": 37,
                "candidate_status": "below_target",
            },
            {
                "role": "spot_interaction",
                "candidate_count": 6,
                "min": 8,
                "max": 12,
                "candidate_status": "below_target",
            },
            {
                "role": "tutors_access",
                "candidate_count": 18,
                "min": 4,
                "max": 8,
                "candidate_status": "above_target_review",
            },
        ],
        "candidate_expected_package_presence": {
            "interaction_and_resets": {
                "missing_cards": ["Anguished Unmaking", "Despark"],
            },
            "commander_attack_enablers": {
                "missing_cards": ["Lightning Greaves", "Swiftfoot Boots"],
            },
        },
        "package_delta": [
            {
                "action": "cut",
                "card": "Genji Glove",
                "risk_flags": ["attack_window_or_extra_combat_cut"],
            }
        ],
    }


class GlobalCommanderProfileBlockerRepairPlanTests(unittest.TestCase):
    def _report_path(self, payload: dict[str, object]) -> Path:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        path = Path(tmp.name) / "matrix.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_core_floor_blocker_maps_to_specific_role_from_package_chain(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        chain = root / "chain.json"
        chain.write_text(
            json.dumps(
                {
                    "summary": {
                        "final_role_counts": {"removal": 3, "draw": 10},
                        "final_role_statuses": {"removal": "below_floor", "draw": "in_range"},
                    }
                }
            ),
            encoding="utf-8",
        )
        payload = matrix_payload(blockers=["package_core_floor_not_repaired"])
        payload["input_artifacts"] = {"package_chain_report": str(chain)}
        matrix = root / "matrix.json"
        matrix.write_text(json.dumps(payload), encoding="utf-8")

        report = repair.build_report(strategy_matrix_report=matrix)

        self.assertEqual(report["status"], "profile_blocker_repair_plan_ready")
        self.assertEqual(report["summary"]["repair_action_count"], 1)
        action = report["repair_actions"][0]
        self.assertEqual(action["blocker"], "package_core_floor_not_repaired")
        self.assertEqual(action["repair_axis"], "core_removal_floor")
        self.assertEqual(action["candidate_count"], 3)
        self.assertEqual(action["target_min"], 6)
        self.assertEqual(action["shortfall_to_min"], 3)
        self.assertIn("oracle_targeted_interaction_filter", action["source_lanes"])
        self.assertIn("Anguished Unmaking", action["missing_expected_package_cards"])
        self.assertIn(
            "repair_core_removal_floor_with_spot_interaction_source_lane",
            report["recommended_repair_sequence"],
        )

    def test_blocks_battle_and_maps_profile_and_attack_window_repairs(self) -> None:
        path = self._report_path(
            matrix_payload(
                blockers=[
                    "profile_lands_below_target",
                    "profile_spot_interaction_below_target",
                    "attack_window_cut_without_replacement",
                ]
            )
        )

        report = repair.build_report(strategy_matrix_report=path)

        self.assertEqual(report["status"], "profile_blocker_repair_plan_ready")
        self.assertFalse(report["battle_gate_allowed_now"])
        self.assertEqual(report["summary"]["next_gate"], "materialize_profile_repair_candidate_copy")
        blockers = {action["blocker"] for action in report["repair_actions"]}
        self.assertEqual(
            blockers,
            {
                "profile_lands_below_target",
                "profile_spot_interaction_below_target",
                "attack_window_cut_without_replacement",
            },
        )
        spot_action = next(
            action for action in report["repair_actions"] if action["blocker"] == "profile_spot_interaction_below_target"
        )
        self.assertEqual(spot_action["shortfall_to_min"], 2)
        self.assertIn("Anguished Unmaking", spot_action["missing_expected_package_cards"])
        attack_action = next(
            action for action in report["repair_actions"] if action["blocker"] == "attack_window_cut_without_replacement"
        )
        self.assertEqual(attack_action["cut_cards"][0]["card"], "Genji Glove")
        self.assertIn(
            "repair_or_restore_commander_attack_window_before_more_interaction",
            report["recommended_repair_sequence"],
        )
        self.assertEqual(report["over_target_review_roles"][0]["role"], "tutors_access")

    def test_ready_strategy_matrix_needs_no_repair_and_keeps_battle_gate_signal(self) -> None:
        path = self._report_path(matrix_payload(blockers=[]))

        report = repair.build_report(strategy_matrix_report=path)

        self.assertEqual(report["status"], "profile_strategy_ready_no_repair_needed")
        self.assertTrue(report["battle_gate_allowed_now"])
        self.assertEqual(report["repair_actions"], [])
        self.assertEqual(report["summary"]["next_gate"], "run_equal_battle_probe_with_replay_exposure")


if __name__ == "__main__":
    unittest.main()
