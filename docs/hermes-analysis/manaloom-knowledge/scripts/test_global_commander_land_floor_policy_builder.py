#!/usr/bin/env python3
"""Tests for global Commander land floor policy builder."""

from __future__ import annotations

import unittest

import global_commander_land_floor_policy_builder as audit


def role_policy(top_role: str = "land", top_status: str = "role_axis_policy_ready_for_floor_calibration") -> dict:
    return {
        "summary": {
            "top_policy_role": top_role,
            "top_policy_status": top_status,
            "next_gate": "calibrate_land_floor_policy_before_candidate_copy",
        },
        "axis_policy_rows": [
            {
                "role": top_role,
                "status": top_status,
                "next_gate": "calibrate_land_floor_policy_before_candidate_copy",
            }
        ],
    }


def mana_profile(status: str = "mana_profile_ready_for_named_land_candidate_pool") -> dict:
    return {
        "profiles": [
            {
                "deck_id": "900",
                "deck_name": "Deck 900",
                "commander": "Test Commander",
                "status": status,
                "current_land_count": 32,
                "target_land_floor": 34,
                "land_gap": 2,
                "recommended_land_classes": ["add_land_quantity_before_spell_slots"],
            }
        ]
    }


def named_land_pool() -> dict:
    return {
        "candidate_pools": [
            {
                "deck_id": "900",
                "deck_name": "Deck 900",
                "commander": "Test Commander",
                "candidate_count": 2,
                "top_candidates": [
                    {"card_name": "Battlefield Forge", "score": 94, "status": "review_only_named_land_candidate"}
                ],
            }
        ]
    }


def land_cut_model(status: str = "review_cut_pool_ready", pairs: list[dict] | None = None) -> dict:
    if pairs is None:
        pairs = [
            {
                "add": "Battlefield Forge",
                "cut": "Expensive Engine",
                "pair_score": 120,
                "status": "review_only_land_add_cut_pair",
                "mutation_allowed": False,
            }
        ]
    return {
        "deck_cut_pools": [
            {
                "deck_id": "900",
                "deck_name": "Deck 900",
                "commander": "Test Commander",
                "status": status,
                "cut_candidate_count": 3,
                "pair_hypotheses": pairs,
            }
        ]
    }


class GlobalCommanderLandFloorPolicyBuilderTests(unittest.TestCase):
    def test_land_floor_policy_builds_preflight_queue_without_opening_copy(self) -> None:
        payload = audit.build_report(
            role_axis_policy_payload=role_policy(),
            mana_profile_payload=mana_profile(),
            named_land_pool_payload=named_land_pool(),
            land_cut_model_payload=land_cut_model(),
        )

        self.assertEqual(payload["status"], "land_floor_policy_ready_no_deck_action")
        self.assertFalse(payload["mutation_allowed"])
        self.assertFalse(payload["candidate_copy_allowed_now"])
        self.assertEqual(payload["summary"]["ready_pair_preflight_deck_count"], 1)
        self.assertEqual(payload["summary"]["top_deck_id"], "900")
        self.assertEqual(payload["summary"]["top_pair_add"], "Battlefield Forge")
        self.assertEqual(payload["summary"]["top_pair_cut"], "Expensive Engine")
        self.assertEqual(
            payload["summary"]["next_gate"],
            "run_candidate_copy_materializer_for_land_floor_pair_after_commander_source_lane",
        )
        [row] = payload["deck_policy_rows"]
        self.assertEqual(row["status"], audit.LAND_POLICY_READY_STATUS)
        self.assertFalse(row["battle_gate_allowed"])

    def test_non_land_role_axis_policy_blocks_land_floor_calibration(self) -> None:
        payload = audit.build_report(
            role_axis_policy_payload=role_policy(top_role="ramp", top_status="role_axis_policy_holds_exhausted_role_axis"),
            mana_profile_payload=mana_profile(),
            named_land_pool_payload=named_land_pool(),
            land_cut_model_payload=land_cut_model(),
        )

        self.assertEqual(payload["status"], audit.LAND_POLICY_BLOCKED_STATUS)
        [row] = payload["deck_policy_rows"]
        self.assertEqual(row["status"], "blocked_role_axis_policy_not_land_floor")
        self.assertEqual(payload["summary"]["ready_pair_preflight_deck_count"], 0)

    def test_missing_reviewable_cut_pool_blocks_candidate_copy_preflight(self) -> None:
        payload = audit.build_report(
            role_axis_policy_payload=role_policy(),
            mana_profile_payload=mana_profile(),
            named_land_pool_payload=named_land_pool(),
            land_cut_model_payload=land_cut_model(status="needs_commander_specific_cut_source_lane", pairs=[]),
        )

        self.assertEqual(payload["status"], audit.LAND_POLICY_BLOCKED_STATUS)
        [row] = payload["deck_policy_rows"]
        self.assertEqual(row["status"], "blocked_no_reviewable_land_cut_pool")
        self.assertEqual(row["next_gate"], "repair_land_floor_policy_inputs_before_candidate_copy")

    def test_protected_baseline_feedback_blocks_repeating_failed_land_pair(self) -> None:
        payload = audit.build_report(
            role_axis_policy_payload=role_policy(),
            mana_profile_payload={
                "profiles": [
                    {
                        "deck_id": "900",
                        "deck_name": "Deck 900",
                        "commander": "Test Commander",
                        "status": "mana_profile_ready_for_named_land_candidate_pool",
                        "current_land_count": 31,
                        "target_land_floor": 34,
                        "land_gap": 3,
                    },
                    {
                        "deck_id": "901",
                        "deck_name": "Deck 901",
                        "commander": "Other Commander",
                        "status": "mana_profile_ready_for_named_land_candidate_pool",
                        "current_land_count": 33,
                        "target_land_floor": 34,
                        "land_gap": 1,
                    },
                ]
            },
            named_land_pool_payload={
                "candidate_pools": [
                    {
                        "deck_id": "900",
                        "deck_name": "Deck 900",
                        "commander": "Test Commander",
                        "candidate_count": 1,
                        "top_candidates": [{"card_name": "Battlefield Forge", "score": 94}],
                    },
                    {
                        "deck_id": "901",
                        "deck_name": "Deck 901",
                        "commander": "Other Commander",
                        "candidate_count": 1,
                        "top_candidates": [{"card_name": "Boros Garrison", "score": 80}],
                    },
                ]
            },
            land_cut_model_payload={
                "deck_cut_pools": [
                    {
                        "deck_id": "900",
                        "deck_name": "Deck 900",
                        "commander": "Test Commander",
                        "status": "review_cut_pool_ready",
                        "cut_candidate_count": 1,
                        "pair_hypotheses": [
                            {
                                "add": "Battlefield Forge",
                                "cut": "Expensive Engine",
                                "pair_score": 140,
                            }
                        ],
                    },
                    {
                        "deck_id": "901",
                        "deck_name": "Deck 901",
                        "commander": "Other Commander",
                        "status": "review_cut_pool_ready",
                        "cut_candidate_count": 1,
                        "pair_hypotheses": [
                            {
                                "add": "Boros Garrison",
                                "cut": "Low Impact Spell",
                                "pair_score": 70,
                            }
                        ],
                    },
                ]
            },
            battle_feedback_payload={
                "package_feedback": [
                    {
                        "deck_id": "900",
                        "package_status": "package_blocked_by_protected_baseline_gate",
                        "recommendation": "block_package_until_new_source_lane_cut_or_strategy",
                        "added_cards": ["Battlefield Forge", "Boros Signet"],
                        "cut_cards": ["Expensive Engine", "Slow Finisher"],
                        "primary_evidence": {
                            "artifact_path": "reports/failed_gate.json",
                            "classification": "package_improved_weak_base_but_failed_protected_baseline",
                            "candidate_vs_immediate_base_win_delta": 1,
                            "candidate_vs_protected_win_delta": -6,
                            "protected_baseline_key": "deck_607",
                        },
                    }
                ]
            },
        )

        self.assertEqual(payload["status"], "land_floor_policy_ready_no_deck_action")
        self.assertEqual(payload["summary"]["top_deck_id"], "901")
        self.assertEqual(payload["summary"]["battle_feedback_blocked_land_preflight_count"], 1)
        rows_by_deck = {row["deck_id"]: row for row in payload["deck_policy_rows"]}
        blocked = rows_by_deck["900"]
        self.assertEqual(blocked["status"], audit.BATTLE_FEEDBACK_BLOCKED_STATUS)
        self.assertEqual(blocked["next_gate"], audit.BATTLE_FEEDBACK_NEXT_GATE)
        self.assertEqual(blocked["battle_feedback"]["candidate_vs_protected_win_delta"], -6)
        self.assertIn(
            "battle_feedback_blocked_land_preflight_requires_new_source_lane_or_cut_set",
            payload["candidate_copy_blockers"],
        )


if __name__ == "__main__":
    unittest.main()
