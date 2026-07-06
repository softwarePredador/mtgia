#!/usr/bin/env python3
"""Tests for Commander payoff package synthesis."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import global_commander_payoff_package_synthesizer as synthesizer


def add(name: str, axis: str, roles: list[str], score: int) -> dict[str, object]:
    status = (
        "review_only_commander_payoff_source_candidate"
        if axis in synthesizer.SUPPORTED_PAYOFF_AXES
        else "review_only_profile_repair_add_candidate"
    )
    if axis == synthesizer.LAND_AXIS:
        status = "review_only_named_land_candidate"
    return {
        "card_name": name,
        "score": score,
        "status": status,
        "profile_roles": roles,
        "mutation_allowed": False,
    }


def cut(name: str, score: int = 50) -> dict[str, object]:
    return {
        "card_name": name,
        "score": score,
        "status": "review_only_profile_repair_cut_candidate",
        "matching_over_target_roles": ["tutors_access"],
        "cut_reasons": ["over_target_tutors_access"],
        "mutation_allowed": False,
    }


def profile_payload(*, payoff_shortfall: int, spot_shortfall: int, cuts: int) -> dict[str, object]:
    return {
        "status": "profile_repair_candidate_model_blocks_materialization",
        "summary": {
            "deck_id": "619",
            "commander": "Kaalia of the Vast",
            "commander_color_identity": ["W", "B", "R"],
        },
        "repair_axis_pools": [
            {
                "repair_axis": synthesizer.LAND_AXIS,
                "blocker": "profile_lands_below_target",
                "shortfall_to_min": 1,
                "top_add_candidates": [
                    add("Ash Barrens", synthesizer.LAND_AXIS, ["lands"], 75),
                ],
            },
            {
                "repair_axis": synthesizer.PAYOFF_AXIS,
                "blocker": "profile_angels_demons_dragons_payoffs_below_target",
                "shortfall_to_min": payoff_shortfall,
                "top_add_candidates": [],
            },
            {
                "repair_axis": synthesizer.SPOT_AXIS,
                "blocker": "profile_spot_interaction_below_target",
                "shortfall_to_min": spot_shortfall,
                "top_add_candidates": [
                    add("Despark", synthesizer.SPOT_AXIS, ["spot_interaction"], 140),
                    add("Anguished Unmaking", synthesizer.SPOT_AXIS, ["spot_interaction"], 130),
                ],
            },
            {
                "repair_axis": synthesizer.ATTACK_AXIS,
                "blocker": "attack_window_cut_without_replacement",
                "shortfall_to_min": 0,
                "top_add_candidates": [
                    add(
                        "Arena of Glory",
                        synthesizer.ATTACK_AXIS,
                        ["haste_protection_silence", "lands"],
                        135,
                    ),
                    add("Swiftfoot Boots", synthesizer.ATTACK_AXIS, ["haste_protection_silence"], 120),
                ],
            },
            {
                "repair_axis": synthesizer.REANIMATION_AXIS,
                "blocker": "profile_reanimation_plan_b_below_target",
                "shortfall_to_min": 0,
                "top_add_candidates": [
                    add("Reanimate", synthesizer.REANIMATION_AXIS, ["reanimation_plan_b"], 125),
                ],
            },
        ],
        "global_cut_review_pool": [cut(f"Cut {index}", score=60 - index) for index in range(cuts)],
    }


def payoff_payload(count: int) -> dict[str, object]:
    return {
        "status": "commander_payoff_source_lane_expanded",
        "summary": {"ready_candidate_count": count, "shortfall_to_min": count},
        "top_payoff_candidates": [
            add(f"Dragon {index}", synthesizer.PAYOFF_AXIS, ["angels_demons_dragons_payoffs"], 120 - index)
            for index in range(count)
        ],
    }


def lorehold_profile_payload() -> dict[str, object]:
    return {
        "status": "profile_repair_candidate_model_blocks_materialization",
        "summary": {
            "deck_id": "609",
            "commander": "Lorehold, the Historian",
            "commander_color_identity": ["W", "R"],
        },
        "repair_axis_pools": [
            {
                "repair_axis": synthesizer.LAND_AXIS,
                "blocker": "profile_lands_below_target",
                "shortfall_to_min": 2,
                "top_add_candidates": [
                    add("Bant Panorama", synthesizer.LAND_AXIS, ["lands"], 90),
                    add("Evolving Wilds", synthesizer.LAND_AXIS, ["lands"], 80),
                ],
            },
            {
                "repair_axis": synthesizer.SPELL_PAYOFF_AXIS,
                "blocker": "profile_spell_payoffs_copy_engines_below_target",
                "shortfall_to_min": 1,
                "top_add_candidates": [],
            },
        ],
        "global_cut_review_pool": [
            {
                **cut("Lorehold Spell Payoff Cut", score=95),
                "profile_roles": [synthesizer.SPELL_PAYOFF_AXIS],
                "matching_over_target_roles": [synthesizer.SPELL_PAYOFF_AXIS],
            },
            *[cut(f"Lorehold Cut {index}", score=70 - index) for index in range(3)],
        ],
    }


def lorehold_payoff_payload() -> dict[str, object]:
    return {
        "status": "commander_payoff_source_lane_expanded",
        "summary": {
            "repair_axis": synthesizer.SPELL_PAYOFF_AXIS,
            "ready_candidate_count": 2,
            "shortfall_to_min": 1,
        },
        "top_payoff_candidates": [
            add("Double Vision", synthesizer.SPELL_PAYOFF_AXIS, ["spell_payoffs_copy_engines"], 145),
            add("Young Pyromancer", synthesizer.SPELL_PAYOFF_AXIS, ["spell_payoffs_copy_engines"], 135),
        ],
    }


class GlobalCommanderPayoffPackageSynthesizerTests(unittest.TestCase):
    def _json(self, root: Path, name: str, payload: dict[str, object]) -> Path:
        path = root / name
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_blocks_large_package_with_insufficient_cuts_and_cross_axis_land_attack(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        profile = self._json(root, "profile.json", profile_payload(payoff_shortfall=10, spot_shortfall=2, cuts=4))
        payoffs = self._json(root, "payoffs.json", payoff_payload(10))

        report = synthesizer.build_report(
            repair_candidate_model_report=profile,
            payoff_source_lane_report=payoffs,
        )

        self.assertEqual(report["status"], "commander_payoff_package_synthesis_blocks_candidate_copy")
        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertEqual(report["selected_add_package"][0]["card_name"], "Arena of Glory")
        self.assertIn(synthesizer.LAND_AXIS, report["selected_add_package"][0]["covered_axes"])
        self.assertEqual(report["summary"]["initial_axis_requirements"][synthesizer.LAND_AXIS], 1)
        self.assertEqual(report["summary"]["remaining_axis_requirements"][synthesizer.LAND_AXIS], 0)
        self.assertIn(
            "insufficient_reviewable_cuts_for_full_profile_package:required_13_ready_4",
            report["candidate_copy_blockers"],
        )
        self.assertIn(
            "package_size_exceeds_materializer_review_limit:required_13_limit_8",
            report["candidate_copy_blockers"],
        )
        self.assertEqual(report["summary"]["next_gate"], "expand_commander_cut_source_lane_for_full_profile_package")

    def test_small_fully_covered_package_can_open_candidate_copy_without_battle(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        profile = self._json(root, "profile.json", profile_payload(payoff_shortfall=1, spot_shortfall=1, cuts=3))
        payoffs = self._json(root, "payoffs.json", payoff_payload(1))

        report = synthesizer.build_report(
            repair_candidate_model_report=profile,
            payoff_source_lane_report=payoffs,
        )

        self.assertEqual(report["status"], "commander_payoff_package_synthesis_ready_for_candidate_copy")
        self.assertTrue(report["candidate_copy_allowed_now"])
        self.assertFalse(report["battle_gate_allowed_now"])
        self.assertEqual(report["summary"]["selected_add_count"], 3)
        self.assertEqual(report["summary"]["selected_cut_count"], 3)
        self.assertEqual(report["candidate_copy_blockers"], [])
        self.assertEqual(report["summary"]["next_gate"], "materialize_synthesized_commander_package_chain_copy")

    def test_reanimation_shortfall_is_selected_before_candidate_copy_ready(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        profile_payload_with_reanimation = profile_payload(payoff_shortfall=1, spot_shortfall=0, cuts=2)
        for pool in profile_payload_with_reanimation["repair_axis_pools"]:
            if pool["repair_axis"] == synthesizer.LAND_AXIS:
                pool["shortfall_to_min"] = 0
            if pool["repair_axis"] == synthesizer.ATTACK_AXIS:
                pool["blocker"] = "no_attack_window_blocker"
            if pool["repair_axis"] == synthesizer.REANIMATION_AXIS:
                pool["shortfall_to_min"] = 1
        profile = self._json(root, "profile.json", profile_payload_with_reanimation)
        payoffs = self._json(root, "payoffs.json", payoff_payload(1))

        report = synthesizer.build_report(
            repair_candidate_model_report=profile,
            payoff_source_lane_report=payoffs,
        )

        self.assertEqual(report["status"], "commander_payoff_package_synthesis_ready_for_candidate_copy")
        self.assertEqual(report["summary"]["initial_axis_requirements"][synthesizer.REANIMATION_AXIS], 1)
        selected_names = [row["card_name"] for row in report["selected_add_package"]]
        self.assertIn("Reanimate", selected_names)

    def test_lorehold_spell_payoff_axis_uses_source_lane_axis(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        profile = self._json(root, "lorehold_profile.json", lorehold_profile_payload())
        payoffs = self._json(root, "lorehold_payoffs.json", lorehold_payoff_payload())

        report = synthesizer.build_report(
            repair_candidate_model_report=profile,
            payoff_source_lane_report=payoffs,
        )

        self.assertEqual(report["status"], "commander_payoff_package_synthesis_ready_for_candidate_copy")
        self.assertEqual(report["summary"]["payoff_axis"], synthesizer.SPELL_PAYOFF_AXIS)
        self.assertEqual(report["summary"]["initial_axis_requirements"][synthesizer.SPELL_PAYOFF_AXIS], 1)
        selected_names = [row["card_name"] for row in report["selected_add_package"]]
        self.assertEqual(selected_names, ["Bant Panorama", "Evolving Wilds", "Double Vision"])
        selected_cuts = [row["card_name"] for row in report["selected_cut_package"]]
        self.assertNotIn("Lorehold Spell Payoff Cut", selected_cuts)
        self.assertIn(synthesizer.SPELL_PAYOFF_AXIS, report["selected_add_package"][2]["covered_axes"])


if __name__ == "__main__":
    unittest.main()
