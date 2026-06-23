#!/usr/bin/env python3
from __future__ import annotations

import unittest

import xmage_reference_test_scenario_builder as builder


class XMageReferenceTestScenarioBuilderTests(unittest.TestCase):
    def test_builds_cost_reduction_scenario(self) -> None:
        scenarios = builder.build_suggested_test_scenarios(
            {"card_name": "Pearl Medallion"},
            {
                "primary_candidate": {
                    "effect_json": {"effect": "static_cost_reduction"},
                    "suggested_tests": ["matching spell is cheaper"],
                }
            },
        )

        self.assertEqual(scenarios[0]["card_name"], "Pearl Medallion")
        self.assertEqual(scenarios[0]["effect"], "static_cost_reduction")
        self.assertIn("matching spell", scenarios[0]["actions"])
        self.assertEqual(scenarios[0]["status"], "draft_requires_manual_review")

    def test_builds_other_turn_mana_rock_scenario(self) -> None:
        scenarios = builder.build_suggested_test_scenarios(
            {"card_name": "Bender's Waterskin"},
            {
                "primary_candidate": {
                    "effect_json": {"effect": "other_turn_untapping_any_color_mana_rock"},
                    "suggested_tests": ["untaps on each other player's untap step"],
                }
            },
        )

        self.assertIn("another player's untap step", scenarios[0]["actions"])
        self.assertIn("chosen color", scenarios[0]["assertions"])

    def test_builds_surge_to_victory_scenario(self) -> None:
        scenarios = builder.build_suggested_test_scenarios(
            {"card_name": "Surge to Victory"},
            {
                "primary_candidate": {
                    "effect_json": {"effect": "exile_instant_sorcery_boost_combat_damage_copy_cast"},
                    "suggested_tests": ["combat damage copies exiled card"],
                }
            },
        )

        self.assertIn("instant or sorcery in graveyard", scenarios[0]["setup"])
        self.assertIn("castable free copy", scenarios[0]["assertions"])


if __name__ == "__main__":
    unittest.main()
