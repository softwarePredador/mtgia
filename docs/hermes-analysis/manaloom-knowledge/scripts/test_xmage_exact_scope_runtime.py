#!/usr/bin/env python3
"""Focused runtime tests for exact XMage adapter scopes."""

from __future__ import annotations

import importlib.util
import random
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_xmage_exact_scope_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class XMageExactScopeRuntimeTest(unittest.TestCase):
    def setUp(self) -> None:
        self.battle = load_battle()
        self.events = []
        self.previous_handler = self.battle.REPLAY_EVENT_HANDLER
        self.battle.REPLAY_EVENT_HANDLER = lambda event, data: self.events.append((event, data))

    def tearDown(self) -> None:
        self.battle.REPLAY_EVENT_HANDLER = self.previous_handler

    def test_fixed_source_controller_draw_spell_draws_requested_cards(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Card A"}, {"name": "Card B"}, {"name": "Card C"}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        effect = {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
            "count": 2,
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Draw", "type_line": "Instant", "oracle_text": "Draw two cards."},
            turn=1,
            rng=random.Random(1),
            effect_data_override=effect,
        )

        self.assertEqual(len(active.hand), 2)
        self.assertEqual(len(active.library), 1)
        self.assertTrue(
            any(
                event == "draw_cards_resolved"
                and data.get("cards_drawn") == 2
                and data.get("card") == "Fixture Draw"
                for event, data in self.events
            )
        )

    def test_fixed_damage_target_spell_deals_numeric_damage_to_player(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        opponent.life = 5
        effect = {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
            "amount": 3,
            "damage": 3,
            "target": "opponent",
            "target_constraints": {"scope": "opponent"},
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Burn",
                "type_line": "Instant",
                "oracle_text": "Fixture Burn deals 3 damage to target opponent.",
            },
            turn=2,
            rng=random.Random(2),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.life, 2)
        self.assertTrue(
            any(
                event == "damage_resolved"
                and data.get("amount") == 3
                and data.get("result") == "player_damage"
                and data.get("card") == "Fixture Burn"
                for event, data in self.events
            )
        )

    def test_fixed_damage_target_spell_damages_planeswalker_as_planeswalker(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        planeswalker = {
            "name": "Target Walker",
            "type_line": "Legendary Planeswalker - Test",
            "loyalty": 3,
        }
        opponent.battlefield.append(planeswalker)
        effect = {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
            "amount": 3,
            "damage": 3,
            "target": "creature_or_planeswalker",
            "target_constraints": {"card_types": ["creature", "planeswalker"]},
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Rebuke",
                "type_line": "Instant",
                "oracle_text": "Fixture Rebuke deals 3 damage to target creature or planeswalker.",
            },
            turn=2,
            rng=random.Random(22),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Target Walker"])
        self.assertTrue(
            any(
                event == "damage_resolved"
                and data.get("card") == "Fixture Rebuke"
                and data.get("target") == "Target Walker"
                and data.get("permanent_type") == "planeswalker"
                and data.get("result") == "planeswalker_destroyed"
                and data.get("loyalty_before") == 3
                and data.get("loyalty_after") == 0
                for event, data in self.events
            )
        )

    def test_fixed_damage_any_target_does_not_treat_artifact_as_damage_target(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        opponent.life = 5
        artifact = {"name": "Target Relic", "type_line": "Artifact", "cmc": 2}
        opponent.battlefield.append(artifact)
        effect = {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
            "amount": 3,
            "damage": 3,
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Bolt",
                "type_line": "Instant",
                "oracle_text": "Fixture Bolt deals 3 damage to any target.",
            },
            turn=2,
            rng=random.Random(23),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.battlefield, [artifact])
        self.assertEqual(opponent.life, 2)
        self.assertEqual(opponent.graveyard, [])
        self.assertTrue(
            any(
                event == "damage_resolved"
                and data.get("card") == "Fixture Bolt"
                and data.get("result") == "player_damage"
                for event, data in self.events
            )
        )

    def test_target_constraints_keep_creature_enchantment_planeswalker_scope(self) -> None:
        effect = {"target_constraints": {"card_types": ["creature", "enchantment", "planeswalker"]}}

        self.assertEqual(
            self.battle._target_type_from_constraints(effect),
            "creature_enchantment_or_planeswalker",
        )

    def test_destroy_target_spell_moves_creature_to_graveyard(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Target Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        opponent.battlefield.append(target)
        effect = {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "destination": "graveyard",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Destroy",
                "type_line": "Sorcery",
                "oracle_text": "Destroy target creature.",
            },
            turn=3,
            rng=random.Random(3),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Target Bear"])
        self.assertTrue(
            any(
                event == "removal_resolved"
                and data.get("card") == "Fixture Destroy"
                and data.get("target") == "Target Bear"
                and data.get("destination") == "graveyard"
                for event, data in self.events
            )
        )


if __name__ == "__main__":
    unittest.main()
