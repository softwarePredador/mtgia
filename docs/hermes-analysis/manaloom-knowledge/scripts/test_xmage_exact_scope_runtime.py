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

    def test_static_controlled_power_toughness_boost_applies_without_accumulating(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        anthem = {
            "name": "Glorious Anthem",
            "type_line": "Enchantment",
            "effect": "passive",
            "battle_model_scope": "xmage_static_controlled_power_toughness_boost_v1",
            "static_effect": "controlled_power_toughness_boost",
            "static_power_bonus": 1,
            "static_toughness_bonus": 1,
            "static_exclude_source": False,
        }
        bear = {"name": "Active Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        enemy = {"name": "Enemy Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        active.battlefield = [anthem, bear]
        opponent.battlefield = [enemy]

        self.battle.refresh_controlled_static_power_toughness_bonuses(
            active,
            turn=1,
            phase="test",
            emit_events=True,
        )
        self.battle.refresh_controlled_static_power_toughness_bonuses(
            active,
            turn=1,
            phase="test",
            emit_events=True,
        )

        self.assertEqual(bear["power"], 3)
        self.assertEqual(bear["toughness"], 3)
        self.assertEqual(enemy["power"], 2)
        self.assertEqual(enemy["toughness"], 2)
        self.assertEqual(bear["static_power_toughness_sources"], ["Glorious Anthem"])
        self.assertTrue(
            any(
                event == "static_power_toughness_boost_changed"
                and data.get("card") == "Active Bear"
                and data.get("power_after") == 3
                for event, data in self.events
            )
        )

    def test_static_controlled_power_toughness_boost_reverts_when_source_leaves(self) -> None:
        active = self.battle.Player("Active", None, [])
        anthem = {
            "name": "Glorious Anthem",
            "type_line": "Enchantment",
            "effect": "passive",
            "battle_model_scope": "xmage_static_controlled_power_toughness_boost_v1",
            "static_effect": "controlled_power_toughness_boost",
            "static_power_bonus": 1,
            "static_toughness_bonus": 1,
        }
        bear = {"name": "Active Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        active.battlefield = [anthem, bear]

        self.battle.refresh_controlled_static_power_toughness_bonuses(active)
        active.battlefield.remove(anthem)
        self.battle.refresh_controlled_static_power_toughness_bonuses(active)

        self.assertEqual(bear["power"], 2)
        self.assertEqual(bear["toughness"], 2)
        self.assertNotIn("static_power_toughness_sources", bear)
        self.assertNotIn("_static_controlled_pt_power_bonus", bear)

    def test_static_controlled_power_toughness_boost_respects_exclude_source_and_artifact_filter(self) -> None:
        active = self.battle.Player("Active", None, [])
        chief = {
            "name": "Chief of the Foundry",
            "type_line": "Artifact Creature - Construct",
            "effect": "creature",
            "power": 2,
            "toughness": 3,
            "battle_model_scope": "xmage_static_controlled_power_toughness_boost_v1",
            "static_effect": "controlled_power_toughness_boost",
            "static_power_bonus": 1,
            "static_toughness_bonus": 1,
            "static_exclude_source": True,
            "static_artifact_creature": True,
        }
        construct = {
            "name": "Ally Construct",
            "type_line": "Artifact Creature - Construct",
            "power": 2,
            "toughness": 2,
        }
        bear = {"name": "Ally Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        active.battlefield = [chief, construct, bear]

        self.battle.refresh_controlled_static_power_toughness_bonuses(active)

        self.assertEqual(chief["power"], 2)
        self.assertEqual(chief["toughness"], 3)
        self.assertEqual(construct["power"], 3)
        self.assertEqual(construct["toughness"], 3)
        self.assertEqual(bear["power"], 2)
        self.assertEqual(bear["toughness"], 2)

    def test_static_controlled_power_toughness_boost_respects_subtype_filter(self) -> None:
        active = self.battle.Player("Active", None, [])
        lord = {
            "name": "Pride of the Perfect",
            "type_line": "Enchantment",
            "effect": "passive",
            "battle_model_scope": "xmage_static_controlled_power_toughness_boost_v1",
            "static_effect": "controlled_power_toughness_boost",
            "static_power_bonus": 2,
            "static_toughness_bonus": 0,
            "static_required_subtypes": ["elf"],
        }
        elf = {"name": "Ally Elf", "type_line": "Creature - Elf Warrior", "power": 1, "toughness": 1}
        goblin = {"name": "Ally Goblin", "type_line": "Creature - Goblin", "power": 1, "toughness": 1}
        active.battlefield = [lord, elf, goblin]

        self.battle.refresh_controlled_static_power_toughness_bonuses(active)

        self.assertEqual(elf["power"], 3)
        self.assertEqual(elf["toughness"], 1)
        self.assertEqual(goblin["power"], 1)
        self.assertEqual(goblin["toughness"], 1)

    def test_static_graveyard_count_power_toughness_counts_controller_graveyard_and_counters(self) -> None:
        active = self.battle.Player("Active", None, [])
        active.graveyard = [
            {"name": "Creature A", "type_line": "Creature - Bear"},
            {"name": "Creature B", "type_line": "Artifact Creature - Construct"},
            {"name": "Instant A", "type_line": "Instant"},
        ]
        wurm = {
            "name": "Boneyard Wurm",
            "type_line": "Creature - Wurm",
            "effect": "creature",
            "power": 0,
            "toughness": 0,
            "plus_one_counters": 1,
            "battle_model_scope": "xmage_static_source_power_toughness_equal_graveyard_count_v1",
            "static_effect": "source_power_toughness_equal_graveyard_count",
            "static_power_toughness_source": "graveyard_count",
            "graveyard_count_scope": "controller_graveyard",
            "graveyard_count_card_types": ["creature"],
        }
        active.battlefield = [wurm]

        self.battle.refresh_graveyard_count_creature_statics_for_player(
            active,
            turn=2,
            phase="test",
            emit_events=True,
        )

        self.assertEqual(wurm["static_graveyard_count_power_toughness_current"], 2)
        self.assertEqual(wurm["power"], 3)
        self.assertEqual(wurm["toughness"], 3)
        self.assertTrue(
            any(
                event == "static_graveyard_count_power_toughness_changed"
                and data.get("card") == "Boneyard Wurm"
                and data.get("graveyard_count") == 2
                for event, data in self.events
            )
        )

    def test_static_graveyard_count_power_toughness_counts_all_graveyards_and_zero_toughness_sba(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard = [{"name": "Active Artifact", "type_line": "Artifact"}]
        opponent.graveyard = [{"name": "Opponent Artifact Creature", "type_line": "Artifact Creature - Construct"}]
        fiend = {
            "name": "Slag Fiend",
            "type_line": "Creature - Phyrexian Construct",
            "effect": "creature",
            "power": 0,
            "toughness": 0,
            "battle_model_scope": "xmage_static_source_power_toughness_equal_graveyard_count_v1",
            "static_effect": "source_power_toughness_equal_graveyard_count",
            "static_power_toughness_source": "graveyard_count",
            "graveyard_count_scope": "all_graveyards",
            "graveyard_count_card_types": ["artifact"],
        }
        active.battlefield = [fiend]

        self.battle.refresh_graveyard_count_creature_statics_for_player(
            active,
            turn=2,
            phase="test",
            emit_events=True,
            all_players=[active, opponent],
        )

        self.assertEqual(fiend["power"], 2)
        self.assertEqual(fiend["toughness"], 2)
        active.graveyard.clear()
        opponent.graveyard.clear()
        self.battle.refresh_graveyard_count_creature_statics_for_player(
            active,
            turn=3,
            phase="test",
            emit_events=True,
            all_players=[active, opponent],
        )

        self.assertNotIn(fiend, active.battlefield)
        self.assertIn(fiend, active.graveyard)
        self.assertTrue(
            any(
                event == "state_based_action_zero_toughness"
                and data.get("card") == "Slag Fiend"
                for event, data in self.events
            )
        )

    def test_static_graveyard_threshold_source_boost_toggles_without_cumulative_bonus(self) -> None:
        active = self.battle.Player("Active", None, [])
        active.graveyard = [
            {"name": f"Card {idx}", "type_line": "Instant"}
            for idx in range(6)
        ]
        barkripper = {
            "name": "Anurid Barkripper",
            "type_line": "Creature - Frog Beast",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "battle_model_scope": "xmage_static_source_boost_if_graveyard_threshold_v1",
            "static_effect": "source_power_toughness_boost_if_graveyard_count",
            "graveyard_count_scope": "controller_graveyard",
            "graveyard_count_card_types": ["card"],
            "graveyard_count_threshold": 7,
            "static_power_bonus": 2,
            "static_toughness_bonus": 2,
        }
        active.battlefield = [barkripper]

        self.battle.refresh_graveyard_count_creature_statics_for_player(active, turn=2, phase="test")
        self.assertFalse(barkripper["_static_graveyard_threshold_active"])
        self.assertEqual(barkripper["power"], 2)
        self.assertEqual(barkripper["toughness"], 2)

        active.graveyard.append({"name": "Card 7", "type_line": "Sorcery"})
        self.battle.refresh_graveyard_count_creature_statics_for_player(
            active,
            turn=3,
            phase="test",
            emit_events=True,
        )
        self.assertTrue(barkripper["_static_graveyard_threshold_active"])
        self.assertEqual(barkripper["power"], 4)
        self.assertEqual(barkripper["toughness"], 4)

        self.battle.refresh_graveyard_count_creature_statics_for_player(active, turn=4, phase="test")
        self.assertEqual(barkripper["power"], 4)
        self.assertEqual(barkripper["toughness"], 4)

        active.graveyard.pop()
        self.battle.refresh_graveyard_count_creature_statics_for_player(active, turn=5, phase="test")
        self.assertFalse(barkripper["_static_graveyard_threshold_active"])
        self.assertEqual(barkripper["power"], 2)
        self.assertEqual(barkripper["toughness"], 2)
        self.assertTrue(
            any(
                event == "static_graveyard_threshold_source_boost_changed"
                and data.get("card") == "Anurid Barkripper"
                and data.get("graveyard_count") == 7
                and data.get("active") is True
                for event, data in self.events
            )
        )

    def test_static_graveyard_threshold_source_boost_counts_permanent_cards_only(self) -> None:
        active = self.battle.Player("Active", None, [])
        active.graveyard = [
            {"name": "Creature A", "type_line": "Creature - Bear"},
            {"name": "Artifact A", "type_line": "Artifact"},
            {"name": "Land A", "type_line": "Land"},
            {"name": "Instant A", "type_line": "Instant"},
        ]
        capybara = {
            "name": "Basking Capybara",
            "type_line": "Creature - Capybara",
            "effect": "creature",
            "power": 3,
            "toughness": 2,
            "battle_model_scope": "xmage_static_source_boost_if_graveyard_threshold_v1",
            "static_effect": "source_power_toughness_boost_if_graveyard_count",
            "graveyard_count_scope": "controller_graveyard",
            "graveyard_count_card_types": ["permanent"],
            "graveyard_count_threshold": 4,
            "static_power_bonus": 3,
            "static_toughness_bonus": 0,
        }
        active.battlefield = [capybara]

        self.battle.refresh_graveyard_count_creature_statics_for_player(active, turn=2, phase="test")
        self.assertFalse(capybara["_static_graveyard_threshold_active"])
        self.assertEqual(capybara["static_graveyard_threshold_count_current"], 3)
        self.assertEqual(capybara["power"], 3)
        self.assertEqual(capybara["toughness"], 2)

        active.graveyard.append({"name": "Enchantment A", "type_line": "Enchantment"})
        self.battle.refresh_graveyard_count_creature_statics_for_player(active, turn=3, phase="test")
        self.assertTrue(capybara["_static_graveyard_threshold_active"])
        self.assertEqual(capybara["static_graveyard_threshold_count_current"], 4)
        self.assertEqual(capybara["power"], 6)
        self.assertEqual(capybara["toughness"], 2)

    def test_static_graveyard_count_source_boost_counts_controller_graveyard_without_cumulative_bonus(self) -> None:
        active = self.battle.Player("Active", None, [])
        active.graveyard = [
            {"name": "Creature A", "type_line": "Creature - Bear"},
            {"name": "Artifact Creature A", "type_line": "Artifact Creature - Construct"},
            {"name": "Instant A", "type_line": "Instant"},
        ]
        elite = {
            "name": "Liliana's Elite",
            "type_line": "Creature - Zombie",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
            "battle_model_scope": "xmage_static_source_boost_equal_graveyard_count_v1",
            "static_effect": "source_power_toughness_boost_equal_graveyard_count",
            "graveyard_count_scope": "controller_graveyard",
            "graveyard_count_card_types": ["creature"],
            "static_power_bonus_per_graveyard_count": 1,
            "static_toughness_bonus_per_graveyard_count": 1,
        }
        active.battlefield = [elite]

        self.battle.refresh_graveyard_count_creature_statics_for_player(
            active,
            turn=2,
            phase="test",
            emit_events=True,
        )
        self.assertEqual(elite["static_graveyard_count_boost_current"], 2)
        self.assertEqual(elite["power"], 3)
        self.assertEqual(elite["toughness"], 3)

        self.battle.refresh_graveyard_count_creature_statics_for_player(active, turn=3, phase="test")
        self.assertEqual(elite["power"], 3)
        self.assertEqual(elite["toughness"], 3)

        active.graveyard.pop(0)
        self.battle.refresh_graveyard_count_creature_statics_for_player(active, turn=4, phase="test")
        self.assertEqual(elite["static_graveyard_count_boost_current"], 1)
        self.assertEqual(elite["power"], 2)
        self.assertEqual(elite["toughness"], 2)
        self.assertTrue(
            any(
                event == "static_graveyard_count_source_boost_changed"
                and data.get("card") == "Liliana's Elite"
                and data.get("graveyard_count") == 2
                for event, data in self.events
            )
        )

    def test_static_graveyard_count_source_boost_counts_artifacts_power_only(self) -> None:
        active = self.battle.Player("Active", None, [])
        active.graveyard = [
            {"name": "Artifact A", "type_line": "Artifact"},
            {"name": "Artifact Creature A", "type_line": "Artifact Creature - Construct"},
            {"name": "Creature A", "type_line": "Creature - Bear"},
        ]
        slasher = {
            "name": "Salvage Slasher",
            "type_line": "Artifact Creature - Human Rogue",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
            "battle_model_scope": "xmage_static_source_boost_equal_graveyard_count_v1",
            "static_effect": "source_power_toughness_boost_equal_graveyard_count",
            "graveyard_count_scope": "controller_graveyard",
            "graveyard_count_card_types": ["artifact"],
            "static_power_bonus_per_graveyard_count": 1,
            "static_toughness_bonus_per_graveyard_count": 0,
        }
        active.battlefield = [slasher]

        self.battle.refresh_graveyard_count_creature_statics_for_player(active, turn=2, phase="test")
        self.assertEqual(slasher["static_graveyard_count_boost_current"], 2)
        self.assertEqual(slasher["power"], 3)
        self.assertEqual(slasher["toughness"], 1)

    def test_static_graveyard_count_source_boost_counts_artifact_or_enchantment(self) -> None:
        active = self.battle.Player("Active", None, [])
        active.graveyard = [
            {"name": "Artifact A", "type_line": "Artifact"},
            {"name": "Enchantment A", "type_line": "Enchantment"},
            {"name": "Artifact Creature A", "type_line": "Artifact Creature - Construct"},
            {"name": "Creature A", "type_line": "Creature - Bear"},
        ]
        trash_bot = {
            "name": "Runaway Trash-Bot",
            "type_line": "Artifact Creature - Construct",
            "effect": "creature",
            "power": 0,
            "toughness": 4,
            "battle_model_scope": "xmage_static_source_boost_equal_graveyard_count_v1",
            "static_effect": "source_power_toughness_boost_equal_graveyard_count",
            "graveyard_count_scope": "controller_graveyard",
            "graveyard_count_card_types": ["artifact", "enchantment"],
            "static_power_bonus_per_graveyard_count": 1,
            "static_toughness_bonus_per_graveyard_count": 0,
        }
        active.battlefield = [trash_bot]

        self.battle.refresh_graveyard_count_creature_statics_for_player(active, turn=2, phase="test")
        self.assertEqual(trash_bot["static_graveyard_count_boost_current"], 3)
        self.assertEqual(trash_bot["power"], 3)
        self.assertEqual(trash_bot["toughness"], 4)

    def test_static_graveyard_count_source_boost_counts_noncreature_nonland(self) -> None:
        active = self.battle.Player("Active", None, [])
        active.graveyard = [
            {"name": "Instant A", "type_line": "Instant"},
            {"name": "Artifact A", "type_line": "Artifact"},
            {"name": "Enchantment Creature A", "type_line": "Enchantment Creature - Spirit"},
            {"name": "Land A", "type_line": "Land"},
        ]
        xande = {
            "name": "Xande, Dark Mage",
            "type_line": "Legendary Creature - Human Wizard",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
            "battle_model_scope": "xmage_static_source_boost_equal_graveyard_count_v1",
            "static_effect": "source_power_toughness_boost_equal_graveyard_count",
            "graveyard_count_scope": "controller_graveyard",
            "graveyard_count_card_types": ["noncreature_nonland"],
            "static_power_bonus_per_graveyard_count": 1,
            "static_toughness_bonus_per_graveyard_count": 1,
        }
        active.battlefield = [xande]

        self.battle.refresh_graveyard_count_creature_statics_for_player(active, turn=2, phase="test")
        self.assertEqual(xande["static_graveyard_count_boost_current"], 2)
        self.assertEqual(xande["power"], 5)
        self.assertEqual(xande["toughness"], 5)

    def test_static_graveyard_count_source_boost_counts_opponents_graveyards(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard = [{"name": "Own Creature", "type_line": "Creature - Bear"}]
        opponent.graveyard = [
            {"name": "Opponent Creature A", "type_line": "Creature - Zombie"},
            {"name": "Opponent Artifact Creature", "type_line": "Artifact Creature - Construct"},
            {"name": "Opponent Artifact", "type_line": "Artifact"},
        ]
        wight = {
            "name": "Wight of Precinct Six",
            "type_line": "Creature - Zombie",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
            "battle_model_scope": "xmage_static_source_boost_equal_graveyard_count_v1",
            "static_effect": "source_power_toughness_boost_equal_graveyard_count",
            "graveyard_count_scope": "opponents_graveyards",
            "graveyard_count_card_types": ["creature"],
            "static_power_bonus_per_graveyard_count": 1,
            "static_toughness_bonus_per_graveyard_count": 1,
        }
        active.battlefield = [wight]

        self.battle.refresh_graveyard_count_creature_statics_for_player(
            active,
            turn=2,
            phase="test",
            all_players=[active, opponent],
        )
        self.assertEqual(wight["static_graveyard_count_boost_current"], 2)
        self.assertEqual(wight["power"], 3)
        self.assertEqual(wight["toughness"], 3)

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

    def test_fixed_source_controller_draw_spell_pays_creature_sacrifice_cost(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Card A"}, {"name": "Card B"}, {"name": "Card C"}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        sacrifice = {
            "name": "Spare Creature",
            "type_line": "Creature - Citizen",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
        }
        active.battlefield.append(sacrifice)
        effect = {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
            "count": 2,
            "requires_sacrifice_creature": True,
            "additional_cost": "sacrifice_creature",
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Reap",
                "type_line": "Instant",
                "oracle_text": "As an additional cost to cast this spell, sacrifice a creature. Draw two cards.",
            },
            turn=1,
            rng=random.Random(11),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Card A", "Card B"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Spare Creature", "Fixture Reap"])
        self.assertEqual(active.battlefield, [])
        self.assertTrue(
            any(
                event == "additional_cost_paid"
                and data.get("card") == "Fixture Reap"
                and data.get("cost") == "sacrifice_creature"
                and data.get("sacrificed") == "Spare Creature"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "draw_cards_resolved"
                and data.get("card") == "Fixture Reap"
                and data.get("cards_drawn") == 2
                for event, data in self.events
            )
        )

    def test_fixed_source_controller_draw_spell_pays_discard_card_cost(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Card A"}, {"name": "Card B"}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.hand.append({"name": "Discard Me", "type_line": "Creature - Citizen"})
        effect = {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
            "count": 2,
            "requires_discard_card": True,
            "additional_cost": "discard_card",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Voice",
                "type_line": "Sorcery",
                "oracle_text": "As an additional cost to cast this spell, discard a card. Draw two cards.",
            },
            turn=2,
            rng=random.Random(12),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Card A", "Card B"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Discard Me", "Fixture Voice"])
        self.assertTrue(
            any(
                event == "additional_cost_paid"
                and data.get("card") == "Fixture Voice"
                and data.get("cost") == "discard_card"
                and data.get("discarded") == "Discard Me"
                for event, data in self.events
            )
        )

    def test_dig_to_hand_respects_instant_or_sorcery_filter(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Large Creature", "type_line": "Creature - Giant", "cmc": 8},
                {"name": "Useful Instant", "type_line": "Instant", "cmc": 2},
                {"name": "Basic Land", "type_line": "Basic Land - Island", "cmc": 0},
                {"name": "Big Sorcery", "type_line": "Sorcery", "cmc": 6},
            ],
        )
        effect = {
            "effect": "dig_to_hand",
            "battle_model_scope": "xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1",
            "look_count": 4,
            "pick_count": 2,
            "pick_target": "instant_or_sorcery",
            "rest_destination": "graveyard",
        }

        self.battle.resolve_dig_to_hand(
            active,
            {"name": "Pieces of the Puzzle", "type_line": "Sorcery"},
            effect,
            turn=3,
        )

        self.assertEqual({card["name"] for card in active.hand}, {"Useful Instant", "Big Sorcery"})
        self.assertEqual({card["name"] for card in active.graveyard}, {"Large Creature", "Basic Land"})
        self.assertTrue(
            any(
                event == "dig_to_hand_resolved"
                and data.get("pick_target") == "instant_or_sorcery"
                and data.get("eligible_count") == 2
                for event, data in self.events
            )
        )

    def test_dig_to_hand_all_matching_snow_permanent_filter(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Snow-Covered Plains", "type_line": "Basic Snow Land - Plains", "cmc": 0},
                {"name": "Snow Relic", "type_line": "Snow Artifact", "cmc": 2},
                {"name": "Snow Instant", "type_line": "Snow Instant", "cmc": 1},
                {"name": "Regular Creature", "type_line": "Creature - Bear", "cmc": 2},
            ],
        )
        effect = {
            "effect": "dig_to_hand",
            "battle_model_scope": "xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1",
            "look_count": 4,
            "pick_count": 4,
            "pick_target": "snow_permanent",
            "pick_all_matching": True,
            "rest_destination": "graveyard",
        }

        self.battle.resolve_dig_to_hand(
            active,
            {"name": "Glacial Revelation", "type_line": "Sorcery"},
            effect,
            turn=4,
        )

        self.assertEqual({card["name"] for card in active.hand}, {"Snow-Covered Plains", "Snow Relic"})
        self.assertEqual({card["name"] for card in active.graveyard}, {"Snow Instant", "Regular Creature"})
        self.assertTrue(
            any(
                event == "dig_to_hand_resolved"
                and data.get("pick_all_matching") is True
                and data.get("eligible_count") == 2
                for event, data in self.events
            )
        )

    def test_creature_etb_library_pick_moves_one_to_hand_and_rest_to_graveyard(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Low Value Creature", "type_line": "Creature - Scout", "cmc": 1},
                {"name": "High Value Creature", "type_line": "Creature - Giant", "cmc": 7},
                {"name": "Medium Value Creature", "type_line": "Creature - Soldier", "cmc": 3},
            ],
        )
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {
            "name": "Organ Hoarder",
            "type_line": "Creature - Zombie",
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_library_look_count": 3,
            "etb_library_pick_count": 1,
            "etb_library_pick_target": "any_card",
            "etb_library_rest_destination": "graveyard",
        }

        self.battle.resolve_generic_permanent_etb(
            active,
            [opponent],
            permanent,
            permanent,
            turn=5,
            rng=random.Random(5),
        )

        self.assertEqual(len(active.hand), 1)
        self.assertEqual(len(active.graveyard), 2)
        self.assertEqual(len(active.library), 0)
        moved_names = {card["name"] for card in active.hand + active.graveyard}
        self.assertEqual(
            moved_names,
            {"Low Value Creature", "High Value Creature", "Medium Value Creature"},
        )
        self.assertTrue(
            any(
                event == "dig_to_hand_resolved"
                and data.get("card") == "Organ Hoarder"
                and data.get("looked_count") == 3
                and data.get("picked_count") == 1
                for event, data in self.events
            )
        )

    def test_library_tutor_to_battlefield_respects_tapped_flag(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Forest", "type_line": "Basic Land - Forest", "cmc": 0},
                {"name": "Mountain", "type_line": "Basic Land - Mountain", "cmc": 0},
            ],
        )
        opponent = self.battle.Player("Opponent", None, [])
        effect = {
            "effect": "tutor",
            "battle_model_scope": "xmage_library_search_to_battlefield_spell_v1",
            "target": "plains_island_swamp_or_mountain_to_battlefield",
            "count": 1,
            "tutor_enters_tapped": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Farseek", "type_line": "Sorcery"},
            turn=2,
            rng=random.Random(2),
            effect_data_override=effect,
        )

        self.assertEqual(len(active.battlefield), 1)
        tutored = active.battlefield[0]
        self.assertEqual(tutored["name"], "Mountain")
        self.assertTrue(tutored.get("tapped"))
        self.assertTrue(
            any(
                event == "tutor_resolved"
                and data.get("card") == "Fixture Farseek"
                and data.get("destination") == "battlefield"
                and data.get("found") == "Mountain"
                for event, data in self.events
            )
        )

    def test_library_tutor_to_top_moves_selected_card_to_library_top(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Fixture Creature", "type_line": "Creature - Human", "cmc": 1},
                {"name": "Fixture Sorcery", "type_line": "Sorcery", "cmc": 3},
            ],
        )
        opponent = self.battle.Player("Opponent", None, [])
        effect = {
            "effect": "tutor",
            "battle_model_scope": "xmage_library_search_to_library_top_spell_v1",
            "target": "sorcery_to_top",
            "count": 1,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Personal Tutor", "type_line": "Sorcery"},
            turn=2,
            rng=random.Random(2),
            effect_data_override=effect,
        )

        self.assertEqual(active.library[0]["name"], "Fixture Sorcery")
        self.assertEqual(len(active.hand), 0)
        self.assertTrue(
            any(
                event == "tutor_resolved"
                and data.get("card") == "Fixture Personal Tutor"
                and data.get("destination") == "library_top"
                and data.get("found") == "Fixture Sorcery"
                for event, data in self.events
            )
        )

    def test_graveyard_to_library_top_recursion_moves_card_from_graveyard(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Existing Top", "type_line": "Creature - Human", "cmc": 1}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Graveyard Answer", "type_line": "Instant", "cmc": 2}
        active.graveyard.append(target)
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_put_target_graveyard_card_on_library_spell_v1",
            "target": "any_card",
            "target_constraints": {"zone": "graveyard", "controller": "self", "scope": "any_card"},
            "count": 1,
            "destination": "library_top",
            "target_controller": "self",
            "target_graveyard_controller": "self",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Reclaim", "type_line": "Instant"},
            turn=2,
            rng=random.Random(2),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.library[:2]], ["Graveyard Answer", "Existing Top"])
        self.assertEqual(active.hand, [])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Reclaim"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Fixture Reclaim"
                and data.get("destination") == "library_top"
                and data.get("recovered") == ["Graveyard Answer"]
                for event, data in self.events
            )
        )

    def test_graveyard_to_library_bottom_recursion_moves_card_from_graveyard(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Existing Top", "type_line": "Creature - Human", "cmc": 1}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Graveyard Memory", "type_line": "Sorcery", "cmc": 2}
        active.graveyard.append(target)
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_put_target_graveyard_card_on_library_spell_v1",
            "target": "any_card",
            "target_constraints": {"zone": "graveyard", "controller": "self", "scope": "any_card"},
            "count": 1,
            "destination": "library_bottom",
            "target_controller": "self",
            "target_graveyard_controller": "self",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Bottom", "type_line": "Sorcery"},
            turn=2,
            rng=random.Random(2),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.library], ["Existing Top", "Graveyard Memory"])
        self.assertEqual(active.hand, [])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Bottom"])

    def test_graveyard_to_library_shuffle_targets_single_players_graveyard(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [{"name": "Library Card", "type_line": "Land"}])
        active.graveyard.append({"name": "Low Value", "type_line": "Land", "cmc": 0})
        opponent.graveyard.extend(
            [
                {"name": "Opponent Bomb", "type_line": "Creature", "cmc": 7},
                {"name": "Opponent Answer", "type_line": "Instant", "cmc": 2},
                {"name": "Opponent Filler", "type_line": "Land", "cmc": 0},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_put_target_graveyard_card_on_library_spell_v1",
            "target": "any_card",
            "target_constraints": {"zone": "graveyard", "controller": "target_player", "scope": "any_card"},
            "count": 2,
            "destination": "library_shuffle",
            "up_to_count": True,
            "target_controller": "target_player",
            "target_graveyard_controller": "target_player",
            "library_controller": "target_player",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Reclamation", "type_line": "Instant"},
            turn=2,
            rng=random.Random(2),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.graveyard], ["Low Value", "Fixture Reclamation"])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Opponent Filler"])
        self.assertEqual(
            sorted(card["name"] for card in opponent.library),
            ["Library Card", "Opponent Answer", "Opponent Bomb"],
        )
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Fixture Reclamation"
                and data.get("destination") == "library_shuffle"
                and data.get("target_graveyard_controller") == "target_player"
                and set(data.get("recovered") or []) == {"Opponent Bomb", "Opponent Answer"}
                for event, data in self.events
            )
        )

    def test_recursion_battlefield_from_opponent_graveyard_enters_under_controller(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        enemy = {
            "name": "Enemy Bear",
            "type_line": "Creature - Bear",
            "cmc": 2,
            "power": 2,
            "toughness": 2,
        }
        opponent.graveyard.append(enemy)
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_battlefield_spell_v1",
            "target": "creature",
            "target_controller": "opponent",
            "target_graveyard_controller": "opponent",
            "battlefield_controller": "self",
            "target_constraints": {"zone": "graveyard", "controller": "opponent", "card_types": ["creature"]},
            "count": 1,
            "destination": "battlefield",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Ashen Powder", "type_line": "Sorcery"},
            turn=3,
            rng=random.Random(3),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.graveyard, [])
        self.assertEqual([card["name"] for card in active.battlefield], ["Enemy Bear"])
        self.assertEqual(opponent.battlefield, [])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("recovered") == ["Enemy Bear"]
                and data.get("target_graveyard_controller") == "opponent"
                and data.get("battlefield_controller") == "self"
                for event, data in self.events
            )
        )

    def test_recursion_battlefield_from_any_graveyard_can_use_opponent_card_under_controller(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        enemy = {
            "name": "Opponent Angel",
            "type_line": "Creature - Angel",
            "cmc": 5,
            "power": 4,
            "toughness": 4,
        }
        opponent.graveyard.append(enemy)
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_battlefield_spell_v1",
            "target": "creature",
            "target_controller": "any_player",
            "target_graveyard_controller": "any_player",
            "battlefield_controller": "self",
            "target_constraints": {"zone": "graveyard", "controller": "any_player", "card_types": ["creature"]},
            "count": 1,
            "destination": "battlefield",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Hymn of Rebirth", "type_line": "Sorcery"},
            turn=4,
            rng=random.Random(4),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.graveyard, [])
        self.assertEqual([card["name"] for card in active.battlefield], ["Opponent Angel"])
        self.assertEqual(opponent.battlefield, [])

    def test_recursion_battlefield_mana_value_limit_enters_tapped(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        large = {
            "name": "Large Bear",
            "type_line": "Creature - Bear",
            "cmc": 4,
            "power": 4,
            "toughness": 4,
        }
        small = {
            "name": "Small Bear",
            "type_line": "Creature - Bear",
            "cmc": 3,
            "power": 3,
            "toughness": 3,
        }
        active.graveyard.extend([large, small])
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_battlefield_spell_v1",
            "target": "creature",
            "target_controller": "self",
            "target_graveyard_controller": "self",
            "battlefield_controller": "self",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "mana_value_max": 3,
            },
            "count": 1,
            "destination": "battlefield",
            "recursion_mana_value_max": 3,
            "enters_tapped": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Helping Hand", "type_line": "Sorcery"},
            turn=5,
            rng=random.Random(5),
            effect_data_override=effect,
        )

        self.assertIn("Large Bear", [card["name"] for card in active.graveyard])
        self.assertNotIn("Small Bear", [card["name"] for card in active.graveyard])
        self.assertEqual([card["name"] for card in active.battlefield], ["Small Bear"])
        self.assertTrue(active.battlefield[0].get("tapped"))
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("recovered") == ["Small Bear"]
                and data.get("mana_value_max") == 3
                and data.get("enters_tapped") is True
                for event, data in self.events
            )
        )

    def test_recursion_battlefield_total_mana_value_limit_selects_subset(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Too Large", "type_line": "Creature - Giant", "cmc": 4, "power": 4, "toughness": 4},
                {"name": "Two Drop", "type_line": "Creature - Human", "cmc": 2, "power": 2, "toughness": 2},
                {"name": "One Drop", "type_line": "Creature - Human", "cmc": 1, "power": 1, "toughness": 1},
                {"name": "Extra Two", "type_line": "Creature - Human", "cmc": 2, "power": 2, "toughness": 2},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_battlefield_spell_v1",
            "target": "creature",
            "target_controller": "self",
            "target_graveyard_controller": "self",
            "battlefield_controller": "self",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "total_mana_value_max": 3,
            },
            "count": 3,
            "up_to_count": True,
            "destination": "battlefield",
            "recursion_total_mana_value_max": 3,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Patch Up", "type_line": "Sorcery"},
            turn=5,
            rng=random.Random(5),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Two Drop", "One Drop"])
        self.assertEqual(
            [card["name"] for card in active.graveyard],
            ["Too Large", "Extra Two", "Patch Up"],
        )
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("recovered") == ["Two Drop", "One Drop"]
                and data.get("total_mana_value_max") == 3
                for event, data in self.events
            )
        )

    def test_recursion_battlefield_requires_different_names(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Clone Bear", "type_line": "Creature - Bear", "cmc": 2, "power": 2, "toughness": 2},
                {"name": "Clone Bear", "type_line": "Creature - Bear", "cmc": 2, "power": 2, "toughness": 2},
                {"name": "Unique Angel", "type_line": "Creature - Angel", "cmc": 5, "power": 4, "toughness": 4},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_battlefield_spell_v1",
            "target": "creature",
            "target_controller": "self",
            "target_graveyard_controller": "self",
            "battlefield_controller": "self",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "requires_different_names": True,
            },
            "count": 6,
            "up_to_count": True,
            "destination": "battlefield",
            "requires_different_names": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Behold the Sinister Six!", "type_line": "Sorcery"},
            turn=5,
            rng=random.Random(5),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Clone Bear", "Unique Angel"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Clone Bear", "Behold the Sinister Six!"])

    def test_recursion_battlefield_this_turn_only_uses_battlefield_graveyard_entries(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        fresh = {"name": "Fresh Creature", "type_line": "Creature - Human", "cmc": 2, "power": 2, "toughness": 2}
        stale = {
            "name": "Stale Creature",
            "type_line": "Creature - Human",
            "cmc": 2,
            "power": 2,
            "toughness": 2,
            "_put_into_graveyard_from_battlefield_turn": 4,
        }
        active.battlefield.append(fresh)
        active.graveyard.append(stale)
        self.battle.CURRENT_REPLAY_TURN = 5
        self.battle.move_creature_from_battlefield(
            active,
            fresh,
            reason="test_destroy",
            all_players=[active, opponent],
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_battlefield_spell_v1",
            "target": "creature",
            "target_controller": "self",
            "target_graveyard_controller": "self",
            "battlefield_controller": "self",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "graveyard_from_battlefield_this_turn": True,
            },
            "count": 4,
            "up_to_count": True,
            "destination": "battlefield",
            "graveyard_from_battlefield_this_turn": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Continue?", "type_line": "Instant"},
            turn=5,
            rng=random.Random(5),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Fresh Creature"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Stale Creature", "Continue?"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("recovered") == ["Fresh Creature"]
                and data.get("graveyard_from_battlefield_this_turn") is True
                for event, data in self.events
            )
        )

    def test_recursion_battlefield_with_plus_one_counters_applies_to_returned_creature(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        bear = {
            "name": "Target Bear",
            "type_line": "Creature - Bear",
            "cmc": 2,
            "power": 2,
            "toughness": 2,
        }
        active.graveyard.append(bear)
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_creature_to_battlefield_with_counter_spell_v1",
            "target": "creature",
            "target_controller": "self",
            "target_graveyard_controller": "self",
            "battlefield_controller": "self",
            "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
            "count": 1,
            "destination": "battlefield",
            "counter_type": "+1/+1",
            "counter_amount": 2,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Evil Reawakened", "type_line": "Sorcery"},
            turn=6,
            rng=random.Random(6),
            effect_data_override=effect,
        )

        self.assertEqual(active.graveyard, [{"name": "Evil Reawakened", "type_line": "Sorcery"}])
        self.assertEqual([card["name"] for card in active.battlefield], ["Target Bear"])
        returned = active.battlefield[0]
        self.assertEqual(returned["plus_one_counters"], 2)
        self.assertEqual(returned["power"], 4)
        self.assertEqual(returned["toughness"], 4)
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("counter_type") == "+1/+1"
                and data.get("counter_amount") == 2
                for event, data in self.events
            )
        )

    def test_recursion_battlefield_with_lifelink_counter_grants_keyword(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        cleric = {
            "name": "Target Cleric",
            "type_line": "Creature - Human Cleric",
            "cmc": 3,
            "power": 2,
            "toughness": 3,
        }
        active.graveyard.append(cleric)
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_creature_to_battlefield_with_counter_spell_v1",
            "target": "creature",
            "target_controller": "self",
            "target_graveyard_controller": "self",
            "battlefield_controller": "self",
            "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
            "count": 1,
            "destination": "battlefield",
            "counter_type": "lifelink",
            "counter_amount": 1,
            "counter_grants_keywords": ["lifelink"],
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Unbreakable Bond", "type_line": "Sorcery"},
            turn=7,
            rng=random.Random(7),
            effect_data_override=effect,
        )

        returned = active.battlefield[0]
        self.assertEqual(returned["lifelink_counters"], 1)
        self.assertTrue(returned["lifelink"])

    def test_recursion_battlefield_with_minus_one_counter_can_kill_returned_creature(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        enemy = {
            "name": "Opponent Skeleton",
            "type_line": "Creature - Skeleton",
            "cmc": 1,
            "power": 1,
            "toughness": 1,
        }
        opponent.graveyard.append(enemy)
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_creature_to_battlefield_with_counter_spell_v1",
            "target": "creature",
            "target_controller": "any_player",
            "target_graveyard_controller": "any_player",
            "battlefield_controller": "self",
            "target_constraints": {"zone": "graveyard", "controller": "any_player", "card_types": ["creature"]},
            "count": 3,
            "destination": "battlefield",
            "counter_type": "-1/-1",
            "counter_amount": 1,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Aberrant Return", "type_line": "Sorcery"},
            turn=8,
            rng=random.Random(8),
            effect_data_override=effect,
        )

        self.assertEqual(active.battlefield, [])
        self.assertEqual(opponent.graveyard, [])
        self.assertEqual([card["name"] for card in active.graveyard], ["Opponent Skeleton", "Aberrant Return"])

    def test_creature_dies_recursion_returns_artifact_card_to_hand_excluding_self(self) -> None:
        active = self.battle.Player("Active", None, [])
        retriever = {
            "name": "Myr Retriever",
            "type_line": "Artifact Creature - Myr",
            "power": 1,
            "toughness": 1,
            "effect": "creature",
            "battle_model_scope": "xmage_creature_dies_return_graveyard_card_to_hand_v1",
            "dies_recursion_target": "artifact",
            "dies_recursion_count": 1,
            "dies_recursion_destination": "hand",
            "dies_recursion_exclude_self": True,
        }
        bauble = {"name": "Mishra's Bauble", "type_line": "Artifact", "cmc": 0}
        active.battlefield.append(retriever)
        active.graveyard.append(bauble)

        destination = self.battle.move_creature_from_battlefield(
            active,
            retriever,
            reason="test_destroy",
        )

        self.assertEqual(destination, "graveyard")
        self.assertEqual([card["name"] for card in active.hand], ["Mishra's Bauble"])
        self.assertIn(retriever, active.graveyard)
        self.assertNotIn(bauble, active.graveyard)
        self.assertTrue(
            any(
                event == "dies_recursion_resolved"
                and data.get("card") == "Myr Retriever"
                and data.get("recovered") == ["Mishra's Bauble"]
                and data.get("exclude_self") is True
                for event, data in self.events
            )
        )

    def test_simple_activated_draw_permanent_pays_mana_taps_and_draws(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Card A"}, {"name": "Card B"}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(3)
        active.mana_pool.add("blue", 1)
        permanent = {
            "name": "Fixture Herald",
            "type_line": "Creature - Human Wizard",
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_v1",
            "activated_draw": True,
            "activated_draw_count": 1,
            "activation_cost_mana": "{3}{U}",
            "activation_cost_generic": 3,
            "activation_cost_colors": ["U"],
            "activation_requires_tap": True,
            "summoning_sick": False,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=3,
            rng=random.Random(3),
            phase="postcombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(len(active.hand), 1)
        self.assertEqual(len(active.library), 1)
        self.assertTrue(permanent.get("tapped"))
        self.assertEqual(active.available_mana(), 0)
        self.assertTrue(
            any(
                event == "utility_artifact_activated"
                and data.get("activation_kind") == "simple_activated_draw"
                and data.get("card") == "Fixture Herald"
                and data.get("cards_drawn") == 1
                and data.get("activation_cost") == "{3}{U}"
                for event, data in self.events
            )
        )

    def test_simple_activated_draw_self_sacrifice_permanent_moves_to_graveyard(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Card A"}, {"name": "Card B"}, {"name": "Card C"}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(1)
        active.mana_pool.add("blue", 1)
        permanent = {
            "name": "Fixture Capsule",
            "type_line": "Artifact",
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_v1",
            "activated_draw": True,
            "activated_draw_count": 2,
            "activated_self_sacrifice_draw": True,
            "activated_draw_on_self_sacrifice": True,
            "draw_on_self_sacrifice": 2,
            "activation_cost_mana": "{1}{U}",
            "activation_cost_generic": 1,
            "activation_cost_colors": ["U"],
            "activation_requires_tap": True,
            "activation_requires_sacrifice": True,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            rng=random.Random(4),
            phase="postcombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertNotIn(permanent, active.battlefield)
        self.assertIn(permanent, active.graveyard)
        self.assertEqual(len(active.hand), 2)
        self.assertEqual(len(active.library), 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertTrue(
            any(
                event == "utility_artifact_activated"
                and data.get("activation_kind") == "self_sacrifice_draw"
                and data.get("card") == "Fixture Capsule"
                and data.get("cards_drawn") == 2
                and data.get("activation_cost") == "{1}{U}"
                for event, data in self.events
            )
        )

    def test_simple_activated_draw_sacrifices_target_permanent_cost(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Card A"}, {"name": "Card B"}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(1)
        active.mana_pool.add("black", 1)
        source = {
            "name": "Fixture Chef",
            "type_line": "Creature - Vampire",
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_v1",
            "activated_draw": True,
            "activated_draw_count": 1,
            "activation_cost_mana": "{1}{B}",
            "activation_cost_generic": 1,
            "activation_cost_colors": ["B"],
            "activation_sacrifice_target": "artifact_or_creature",
            "activation_requires_sacrifice_target": True,
            "summoning_sick": False,
        }
        servo = {
            "name": "Servo Token",
            "type_line": "Artifact Creature - Servo",
            "power": 1,
            "toughness": 1,
            "token": True,
        }
        active.battlefield.extend([source, servo])

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=5,
            rng=random.Random(5),
            phase="postcombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertIn(source, active.battlefield)
        self.assertNotIn(servo, active.battlefield)
        self.assertNotIn(servo, active.graveyard)
        self.assertEqual(len(active.hand), 1)
        self.assertEqual(len(active.library), 1)
        self.assertTrue(
            any(
                event == "utility_artifact_activated"
                and data.get("activation_kind") == "simple_activated_draw"
                and data.get("card") == "Fixture Chef"
                and data.get("cards_drawn") == 1
                and data.get("sacrifice_target") == "artifact_or_creature"
                and data.get("sacrificed") == "Servo Token"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "token_ceased_to_exist"
                and data.get("token") == "Servo Token"
                for event, data in self.events
            )
        )

    def test_simple_activated_draw_pays_life_cost(self) -> None:
        active = self.battle.Player("Active", None, [{"name": "Card A"}])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("black", 1)
        permanent = {
            "name": "Fixture Greed",
            "type_line": "Enchantment",
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_v1",
            "activated_draw": True,
            "activated_draw_count": 1,
            "activation_cost_mana": "{B}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["B"],
            "activation_life_cost": 2,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=6,
            rng=random.Random(6),
            phase="postcombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.life, 38)
        self.assertEqual(len(active.hand), 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertTrue(
            any(
                event == "utility_artifact_activated"
                and data.get("activation_kind") == "simple_activated_draw"
                and data.get("card") == "Fixture Greed"
                and data.get("life_paid") == 2
                and data.get("life_before") == 40
                and data.get("life_after") == 38
                for event, data in self.events
            )
        )

    def test_simple_activated_draw_discard_permanent_draws_then_discards(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Fresh Card", "cmc": 2}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.hand.append({"name": "Expensive Spell", "cmc": 7, "type_line": "Sorcery"})
        active.mana_pool.add("blue", 1)
        permanent = {
            "name": "Fixture Looter",
            "type_line": "Creature - Merfolk Rogue",
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_discard_v1",
            "activated_draw_discard": True,
            "activated_draw_count": 1,
            "activated_discard_count": 1,
            "activation_cost_mana": "{U}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["U"],
            "activation_requires_tap": True,
            "summoning_sick": False,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=7,
            rng=random.Random(7),
            phase="postcombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertTrue(permanent.get("tapped"))
        self.assertEqual(len(active.hand), 1)
        self.assertEqual(len(active.library), 0)
        self.assertEqual(len(active.graveyard), 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertTrue(
            any(
                event == "utility_artifact_activated"
                and data.get("activation_kind") == "simple_activated_draw_discard"
                and data.get("card") == "Fixture Looter"
                and data.get("cards_drawn") == 1
                and data.get("cards_discarded") == 1
                and data.get("activation_cost") == "{U}"
                for event, data in self.events
            )
        )

    def test_draw_discard_spell_draws_then_discards(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Fresh Card A", "cmc": 2},
                {"name": "Fresh Card B", "cmc": 3},
            ],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.hand = [
            {"name": "Low Value Land", "type_line": "Land", "cmc": 0},
            {"name": "Keep Spell", "type_line": "Sorcery", "cmc": 5},
        ]
        spell = {"name": "Fixture Study", "type_line": "Sorcery", "cmc": 3}
        effect_data = {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_draw_discard_spell_v1",
            "draw_discard_spell": True,
            "count": 2,
            "draw_count": 2,
            "discard_count": 1,
            "draw_discard_order": "draw_then_discard",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            spell,
            turn=4,
            rng=random.Random(4),
            effect_data_override=effect_data,
            phase="resolution",
        )

        self.assertEqual(len(active.hand), 3)
        self.assertEqual(len(active.library), 0)
        self.assertTrue(any(card.get("name") == "Low Value Land" for card in active.graveyard))
        self.assertTrue(
            any(
                event == "draw_discard_spell_resolved"
                and data.get("card") == "Fixture Study"
                and data.get("order") == "draw_then_discard"
                and data.get("cards_drawn") == 2
                and data.get("cards_discarded") == 1
                for event, data in self.events
            )
        )

    def test_draw_discard_spell_discards_then_draws(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Fresh Card A", "cmc": 2},
                {"name": "Fresh Card B", "cmc": 3},
            ],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.hand = [{"name": "Low Value Land", "type_line": "Land", "cmc": 0}]
        spell = {"name": "Fixture Rendezvous", "type_line": "Sorcery", "cmc": 2}
        effect_data = {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_draw_discard_spell_v1",
            "draw_discard_spell": True,
            "count": 2,
            "draw_count": 2,
            "discard_count": 1,
            "draw_discard_order": "discard_then_draw",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            spell,
            turn=5,
            rng=random.Random(5),
            effect_data_override=effect_data,
            phase="resolution",
        )

        self.assertEqual(len(active.hand), 2)
        self.assertEqual(len(active.library), 0)
        self.assertTrue(any(card.get("name") == "Low Value Land" for card in active.graveyard))
        self.assertTrue(
            any(
                event == "draw_discard_spell_resolved"
                and data.get("card") == "Fixture Rendezvous"
                and data.get("order") == "discard_then_draw"
                and data.get("cards_drawn") == 2
                and data.get("cards_discarded") == 1
                for event, data in self.events
            )
        )

    def test_draw_lose_life_spell_draws_then_loses_life(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Fresh Card A", "cmc": 2},
                {"name": "Fresh Card B", "cmc": 3},
            ],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.life = 20
        spell = {"name": "Fixture Ambition", "type_line": "Sorcery", "cmc": 4}
        effect_data = {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_controller_draw_lose_life_spell_v1",
            "draw_lose_life_spell": True,
            "count": 2,
            "draw_count": 2,
            "life_loss": 3,
            "target_controller": "self",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            spell,
            turn=6,
            rng=random.Random(6),
            effect_data_override=effect_data,
            phase="resolution",
        )

        self.assertEqual(len(active.hand), 2)
        self.assertEqual(active.life, 17)
        self.assertTrue(
            any(
                event == "draw_lose_life_spell_resolved"
                and data.get("card") == "Fixture Ambition"
                and data.get("target_player") == "Active"
                and data.get("cards_drawn") == 2
                and data.get("life_lost") == 3
                and data.get("life_after") == 17
                for event, data in self.events
            )
        )

    def test_target_player_draw_lose_life_spell_targets_lethal_opponent(self) -> None:
        active = self.battle.Player("Active", None, [{"name": "Active Card"}])
        opponent = self.battle.Player(
            "Opponent",
            None,
            [
                {"name": "Opponent Card A", "cmc": 1},
                {"name": "Opponent Card B", "cmc": 2},
            ],
        )
        active.life = 20
        opponent.life = 2
        spell = {"name": "Fixture Sign", "type_line": "Sorcery", "cmc": 2}
        effect_data = {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_target_player_draw_lose_life_spell_v1",
            "draw_lose_life_spell": True,
            "count": 2,
            "draw_count": 2,
            "life_loss": 2,
            "target_controller": "target_player",
            "target": "player",
            "target_preference": "self",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            spell,
            turn=7,
            rng=random.Random(7),
            effect_data_override=effect_data,
            phase="resolution",
        )

        self.assertEqual(len(active.hand), 0)
        self.assertEqual(len(opponent.hand), 2)
        self.assertEqual(opponent.life, 0)
        self.assertTrue(
            any(
                event == "draw_lose_life_spell_resolved"
                and data.get("card") == "Fixture Sign"
                and data.get("target_player") == "Opponent"
                and data.get("target_reason") == "lethal_opponent"
                and data.get("cards_drawn") == 2
                and data.get("life_after") == 0
                for event, data in self.events
            )
        )

    def test_simple_activated_draw_discard_can_discard_drawn_card_with_empty_hand(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Fresh Card", "cmc": 2}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("blue", 1)
        permanent = {
            "name": "Fixture Looter",
            "type_line": "Creature - Merfolk Rogue",
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_discard_v1",
            "activated_draw_discard": True,
            "activated_draw_count": 1,
            "activated_discard_count": 1,
            "activation_cost_mana": "{U}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["U"],
            "activation_requires_tap": True,
            "summoning_sick": False,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=7,
            rng=random.Random(17),
            phase="postcombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(len(active.hand), 0)
        self.assertEqual(len(active.library), 0)
        self.assertEqual([card.get("name") for card in active.graveyard], ["Fresh Card"])
        self.assertTrue(permanent.get("tapped"))
        self.assertTrue(
            any(
                event == "utility_artifact_activated"
                and data.get("activation_kind") == "simple_activated_draw_discard"
                and data.get("cards_drawn") == 1
                and data.get("cards_discarded") == 1
                and data.get("discarded") == ["Fresh Card"]
                for event, data in self.events
            )
        )

    def test_simple_activated_draw_discard_self_sacrifice_moves_source_to_graveyard(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Fresh Card", "cmc": 2}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.hand.append({"name": "Spare Land", "type_line": "Land"})
        permanent = {
            "name": "Fixture Researcher",
            "type_line": "Creature - Human Wizard",
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_discard_v1",
            "activated_draw_discard": True,
            "activated_draw_count": 1,
            "activated_discard_count": 1,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": False,
            "activation_requires_sacrifice": True,
            "summoning_sick": False,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=8,
            rng=random.Random(8),
            phase="postcombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertNotIn(permanent, active.battlefield)
        self.assertIn(permanent, active.graveyard)
        self.assertEqual(len(active.hand), 1)
        self.assertEqual(len(active.library), 0)
        self.assertEqual(len(active.graveyard), 2)
        self.assertTrue(
            any(
                event == "utility_artifact_activated"
                and data.get("activation_kind") == "simple_activated_draw_discard"
                and data.get("card") == "Fixture Researcher"
                and data.get("source_sacrificed") is True
                and data.get("cards_drawn") == 1
                and data.get("cards_discarded") == 1
                for event, data in self.events
            )
        )

    def test_spell_cast_draw_engine_draws_for_matching_creature_spell(self) -> None:
        active = self.battle.Player("Active", None, [{"name": "Drawn Card"}])
        opponent = self.battle.Player("Opponent", None, [])
        engine = {
            "name": "Beast Whisperer",
            "type_line": "Creature - Elf Druid",
            "effect": "creature",
            "battle_model_scope": "xmage_spell_cast_draw_engine_v1",
            "trigger": "spell_cast",
            "trigger_effect": "draw_cards",
            "spell_cast_draw_count": 1,
            "spell_cast_draw_card_types": ["creature"],
            "_rule_logical_key": "battle_rule_v1:beast-whisperer-test",
            "_rule_oracle_hash": "beast-whisperer-test-hash",
        }
        active.battlefield.append(engine)

        self.battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            {"name": "Llanowar Elves", "type_line": "Creature - Elf", "cmc": 1},
            turn=2,
            phase="precombat_main",
        )
        self.battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            {"name": "Sol Ring", "type_line": "Artifact", "cmc": 1},
            turn=2,
            phase="precombat_main",
        )

        self.assertEqual([card["name"] for card in active.hand], ["Drawn Card"])
        draw_events = [
            data
            for event, data in self.events
            if event == "trigger_resolved" and data.get("card") == "Beast Whisperer"
        ]
        self.assertEqual(len(draw_events), 1)
        self.assertEqual(draw_events[0]["trigger_spell"], "Llanowar Elves")
        self.assertEqual(draw_events[0]["cards_drawn"], 1)
        self.assertEqual(draw_events[0]["rule_logical_key"], "battle_rule_v1:beast-whisperer-test")

    def test_spell_cast_draw_engine_respects_subtype_mana_value_and_graveyard_source(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Card A"}, {"name": "Card B"}, {"name": "Card C"}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.battlefield.extend(
            [
                {
                    "name": "Emrakul's Influence",
                    "type_line": "Enchantment",
                    "effect": "draw_engine",
                    "battle_model_scope": "xmage_spell_cast_draw_engine_v1",
                    "trigger": "spell_cast",
                    "trigger_effect": "draw_cards",
                    "spell_cast_draw_count": 2,
                    "spell_cast_draw_card_types": ["creature"],
                    "spell_cast_draw_required_subtypes": ["eldrazi"],
                    "spell_cast_draw_mana_value_min": 7,
                },
                {
                    "name": "Secrets of the Dead",
                    "type_line": "Enchantment",
                    "effect": "draw_engine",
                    "battle_model_scope": "xmage_spell_cast_draw_engine_v1",
                    "trigger": "spell_cast",
                    "trigger_effect": "draw_cards",
                    "spell_cast_draw_count": 1,
                    "spell_cast_draw_source_zone": "graveyard",
                },
            ]
        )

        self.battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            {"name": "Small Eldrazi", "type_line": "Creature - Eldrazi", "cmc": 6},
            turn=3,
            phase="precombat_main",
        )
        self.battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            {"name": "Large Eldrazi", "type_line": "Creature - Eldrazi", "cmc": 7},
            turn=3,
            phase="precombat_main",
        )
        self.battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            {
                "name": "Flashback Spell",
                "type_line": "Sorcery",
                "cmc": 2,
                "_cast_context": {"source_zone": "graveyard"},
            },
            turn=3,
            phase="precombat_main",
        )

        self.assertEqual([card["name"] for card in active.hand], ["Card A", "Card B", "Card C"])
        self.assertTrue(
            any(
                event == "trigger_resolved"
                and data.get("card") == "Emrakul's Influence"
                and data.get("trigger_spell") == "Large Eldrazi"
                and data.get("cards_drawn") == 2
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "trigger_resolved"
                and data.get("card") == "Secrets of the Dead"
                and data.get("trigger_spell") == "Flashback Spell"
                and data.get("trigger_spell_source_zone") == "graveyard"
                for event, data in self.events
            )
        )

    def test_simple_activated_life_gain_permanent_pays_mana_taps_and_gains_life(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.life = 35
        active.mana_pool.add_generic(2)
        permanent = {
            "name": "Fountain of Youth",
            "type_line": "Artifact",
            "effect": "artifact",
            "battle_model_scope": "xmage_permanent_simple_activated_life_gain_v1",
            "activated_effect": "controller_gain_life",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_life_gain_v1",
            "life_gain_amount": 1,
            "activated_life_gain_amount": 1,
            "activation_cost_mana": "{2}",
            "activation_cost_generic": 2,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "activation_requires_sacrifice": False,
            "_rule_logical_key": "battle_rule_v1:fixture_fountain_of_youth",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=5,
            rng=random.Random(5),
            phase="postcombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.life, 36)
        self.assertTrue(permanent.get("tapped"))
        self.assertIn(permanent, active.battlefield)
        self.assertEqual(active.available_mana(), 0)
        self.assertTrue(
            any(
                event == "life_gain_activated"
                and data.get("activation_kind") == "simple_activated_life_gain"
                and data.get("card") == "Fountain of Youth"
                and data.get("activation_cost") == "{2}"
                and data.get("life_gain_requested") == 1
                and data.get("life_gained") == 1
                and data.get("controller_life_before") == 35
                and data.get("controller_life_after") == 36
                and data.get("tapped") is True
                and data.get("sacrificed_self") is False
                for event, data in self.events
            )
        )

    def test_simple_activated_life_gain_self_sacrifice_moves_source_to_graveyard(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.life = 33
        permanent = {
            "name": "Bottle Gnomes",
            "type_line": "Artifact Creature - Gnome",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_life_gain_v1",
            "activated_effect": "controller_gain_life",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_life_gain_v1",
            "life_gain_amount": 3,
            "activated_life_gain_amount": 3,
            "activated_self_sacrifice_life_gain": True,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": False,
            "activation_requires_sacrifice": True,
            "summoning_sick": True,
            "_rule_logical_key": "battle_rule_v1:fixture_bottle_gnomes",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=6,
            rng=random.Random(6),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.life, 36)
        self.assertNotIn(permanent, active.battlefield)
        self.assertIn(permanent, active.graveyard)
        self.assertTrue(
            any(
                event == "life_gain_activated"
                and data.get("card") == "Bottle Gnomes"
                and data.get("activation_cost") == "{0}"
                and data.get("life_gain_requested") == 3
                and data.get("life_gained") == 3
                and data.get("sacrificed_self") is True
                for event, data in self.events
            )
        )

    def test_fixed_create_creature_tokens_spell_creates_modeled_tokens(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        effect = {
            "effect": "token_maker",
            "battle_model_scope": "xmage_fixed_create_creature_tokens_spell_v1",
            "ability_kind": "one_shot",
            "token_count": 2,
            "token_name": "Goblin Token",
            "token_subtype": "Goblin",
            "token_power": 1,
            "token_toughness": 1,
            "token_colors": ["R"],
            "_rule_logical_key": "battle_rule_v1:fixture_token_spell",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Fodder",
                "type_line": "Sorcery",
                "oracle_text": "Create two 1/1 red Goblin creature tokens.",
            },
            turn=2,
            rng=random.Random(2),
            effect_data_override=effect,
        )

        tokens = [card for card in active.battlefield if card.get("name") == "Goblin Token"]
        self.assertEqual(len(tokens), 2)
        self.assertTrue(all(token.get("power") == 1 and token.get("toughness") == 1 for token in tokens))
        self.assertTrue(all(token.get("type_line") == "Creature Token — Goblin" for token in tokens))
        self.assertTrue(all(token.get("colors") == ["R"] for token in tokens))
        self.assertTrue(
            any(
                event == "tokens_created"
                and data.get("card") == "Fixture Fodder"
                and data.get("tokens_created") == 2
                and data.get("token_name") == "Goblin Token"
                and data.get("rule_logical_key") == "battle_rule_v1:fixture_token_spell"
                for event, data in self.events
            )
        )

    def test_fixed_create_creature_tokens_spell_preserves_static_token_keywords(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        effect = {
            "effect": "token_maker",
            "battle_model_scope": "xmage_fixed_create_creature_tokens_spell_v1",
            "ability_kind": "one_shot",
            "token_count": 1,
            "token_name": "Wurm Token",
            "token_subtype": "Wurm",
            "token_power": 5,
            "token_toughness": 5,
            "token_colors": ["G"],
            "token_keywords": ["trample"],
            "_rule_logical_key": "battle_rule_v1:fixture_token_trample",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Wurm",
                "type_line": "Instant",
                "oracle_text": "Create a 5/5 green Wurm creature token with trample.",
            },
            turn=2,
            rng=random.Random(2),
            effect_data_override=effect,
        )

        tokens = [card for card in active.battlefield if card.get("name") == "Wurm Token"]
        self.assertEqual(len(tokens), 1)
        token = tokens[0]
        self.assertTrue(token.get("trample"))
        self.assertIn("trample", token.get("keywords", []))
        self.assertTrue(self.battle.card_has_keyword(token, "trample"))

    def test_creature_etb_create_tokens_preserves_token_model(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {"name": "Fixture Pioneer", "type_line": "Creature - Human Artificer"}
        active.battlefield.append(permanent)
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_create_tokens_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_token_count": 1,
            "etb_token_name": "Thopter Token",
            "etb_token_subtype": "Thopter",
            "etb_token_power": 1,
            "etb_token_toughness": 1,
            "etb_token_colors": [],
            "etb_token_keywords": ["flying"],
            "etb_token_flying": True,
            "etb_artifact_tokens": True,
            "_rule_logical_key": "battle_rule_v1:fixture_etb_token",
        }

        self.battle.resolve_generic_permanent_etb(
            active,
            [opponent],
            permanent,
            effect,
            turn=3,
            rng=random.Random(3),
        )

        tokens = [card for card in active.battlefield if card.get("name") == "Thopter Token"]
        self.assertEqual(len(tokens), 1)
        token = tokens[0]
        self.assertEqual(token.get("type_line"), "Artifact Creature Token — Thopter")
        self.assertEqual(token.get("power"), 1)
        self.assertEqual(token.get("toughness"), 1)
        self.assertTrue(token.get("flying"))
        self.assertIn("flying", token.get("keywords", []))

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

    def test_fixed_damage_spell_pays_creature_sacrifice_cost_before_damage(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        sacrifice = {
            "name": "Spare Goblin",
            "type_line": "Creature - Goblin",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
        }
        target = {
            "name": "Target Beast",
            "type_line": "Creature - Beast",
            "effect": "creature",
            "power": 4,
            "toughness": 4,
        }
        active.battlefield.append(sacrifice)
        opponent.battlefield.append(target)
        effect = {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
            "amount": 5,
            "damage": 5,
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "requires_sacrifice_creature": True,
            "additional_cost": "sacrifice_creature",
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Conclusion",
                "type_line": "Instant",
                "oracle_text": "As an additional cost to cast this spell, sacrifice a creature. Fixture Conclusion deals 5 damage to target creature.",
            },
            turn=4,
            rng=random.Random(31),
            effect_data_override=effect,
        )

        self.assertNotIn(sacrifice, active.battlefield)
        self.assertIn(sacrifice, active.graveyard)
        self.assertNotIn(target, opponent.battlefield)
        self.assertIn(target, opponent.graveyard)
        self.assertTrue(
            any(
                event == "additional_cost_paid"
                and data.get("card") == "Fixture Conclusion"
                and data.get("cost") == "sacrifice_creature"
                and data.get("sacrificed") == "Spare Goblin"
                for event, data in self.events
            )
        )

    def test_fixed_damage_spell_pays_artifact_or_creature_sacrifice_cost(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        artifact = {
            "name": "Spare Bauble",
            "type_line": "Artifact",
            "effect": "artifact",
            "cmc": 0,
        }
        creature = {
            "name": "Larger Creature",
            "type_line": "Creature - Beast",
            "effect": "creature",
            "power": 4,
            "toughness": 4,
        }
        active.battlefield.extend([creature, artifact])
        opponent.life = 8
        effect = {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
            "amount": 5,
            "damage": 5,
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "requires_sacrifice_artifact_or_creature": True,
            "additional_cost": "sacrifice_artifact_or_creature",
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Club",
                "type_line": "Instant",
                "oracle_text": (
                    "As an additional cost to cast this spell, sacrifice an artifact or creature. "
                    "Fixture Club deals 5 damage to any target."
                ),
            },
            turn=4,
            rng=random.Random(33),
            effect_data_override=effect,
        )

        self.assertNotIn(artifact, active.battlefield)
        self.assertIn(artifact, active.graveyard)
        self.assertIn(creature, active.battlefield)
        self.assertEqual(opponent.life, 3)
        self.assertTrue(
            any(
                event == "additional_cost_paid"
                and data.get("card") == "Fixture Club"
                and data.get("cost") == "sacrifice_artifact_or_creature"
                and data.get("sacrificed") == "Spare Bauble"
                for event, data in self.events
            )
        )

    def test_destroy_target_spell_pays_creature_sacrifice_cost_before_removal(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        sacrifice = {
            "name": "Spare Cultist",
            "type_line": "Creature - Human",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
        }
        target = {
            "name": "Target Knight",
            "type_line": "Creature - Knight",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
        }
        active.battlefield.append(sacrifice)
        opponent.battlefield.append(target)
        effect = {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "destination": "graveyard",
            "requires_sacrifice_creature": True,
            "additional_cost": "sacrifice_creature",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Splinters",
                "type_line": "Sorcery",
                "oracle_text": "As an additional cost to cast this spell, sacrifice a creature. Destroy target creature.",
            },
            turn=4,
            rng=random.Random(32),
            effect_data_override=effect,
        )

        self.assertNotIn(sacrifice, active.battlefield)
        self.assertIn(sacrifice, active.graveyard)
        self.assertNotIn(target, opponent.battlefield)
        self.assertIn(target, opponent.graveyard)
        self.assertTrue(
            any(
                event == "additional_cost_paid"
                and data.get("card") == "Fixture Splinters"
                and data.get("cost") == "sacrifice_creature"
                and data.get("sacrificed") == "Spare Cultist"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "removal_resolved"
                and data.get("card") == "Fixture Splinters"
                and data.get("target") == "Target Knight"
                and data.get("destination") == "graveyard"
                for event, data in self.events
            )
        )

    def test_fixed_damage_spell_without_required_sacrifice_land_does_not_damage(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        opponent.life = 8
        effect = {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
            "amount": 3,
            "damage": 3,
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "requires_sacrifice_land": True,
            "additional_cost": "sacrifice_land",
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Volley",
                "type_line": "Instant",
                "oracle_text": "As an additional cost to cast this spell, sacrifice a land. Fixture Volley deals 3 damage to any target.",
            },
            turn=4,
            rng=random.Random(32),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.life, 8)
        self.assertTrue(
            any(
                event == "additional_cost_failed"
                and data.get("card") == "Fixture Volley"
                and data.get("cost") == "sacrifice_land"
                for event, data in self.events
            )
        )
        self.assertFalse(
            any(
                event == "damage_resolved"
                and data.get("card") == "Fixture Volley"
                for event, data in self.events
            )
        )

    def test_fixed_damage_gain_life_spell_damages_target_and_gains_life(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.life = 10
        target = {"name": "Target Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        opponent.battlefield.append(target)
        effect = {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_and_controller_gain_life_spell_v1",
            "amount": 3,
            "damage": 3,
            "gain_life": 2,
            "controller_gain_life": 2,
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Drain",
                "type_line": "Instant",
                "oracle_text": "Fixture Drain deals 3 damage to target creature and you gain 2 life.",
            },
            turn=2,
            rng=random.Random(24),
            effect_data_override=effect,
        )

        self.assertEqual(active.life, 12)
        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Target Bear"])
        self.assertTrue(
            any(
                event == "damage_resolved"
                and data.get("card") == "Fixture Drain"
                and data.get("target") == "Target Bear"
                and data.get("result") == "creature_destroyed"
                and data.get("life_gain_requested") == 2
                and data.get("life_gained") == 2
                and data.get("controller_life_before") == 10
                and data.get("controller_life_after") == 12
                for event, data in self.events
            )
        )

    def test_target_constraints_keep_creature_enchantment_planeswalker_scope(self) -> None:
        effect = {"target_constraints": {"card_types": ["creature", "enchantment", "planeswalker"]}}

        self.assertEqual(
            self.battle._target_type_from_constraints(effect),
            "creature_enchantment_or_planeswalker",
        )

    def test_restricted_damage_targets_only_attacking_or_blocking_creature(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        idle = {"name": "Idle Bear", "type_line": "Creature - Bear", "power": 5, "toughness": 5}
        attacker = {
            "name": "Attacking Bear",
            "type_line": "Creature - Bear",
            "power": 2,
            "toughness": 2,
            "attacking": True,
        }
        opponent.battlefield.extend([idle, attacker])
        effect = {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
            "amount": 4,
            "damage": 4,
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "combat_state": "attacking_or_blocking"},
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Arrows",
                "type_line": "Instant",
                "oracle_text": "Fixture Arrows deals 4 damage to target attacking or blocking creature.",
            },
            turn=3,
            rng=random.Random(32),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in opponent.battlefield], ["Idle Bear"])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Attacking Bear"])

    def test_destroy_target_spell_respects_untapped_constraint(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        tapped = {"name": "Tapped Bear", "type_line": "Creature - Bear", "power": 5, "toughness": 5, "tapped": True}
        untapped = {"name": "Untapped Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        opponent.battlefield.extend([tapped, untapped])
        effect = {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "tapped_state": "untapped"},
            "destination": "graveyard",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Asphyxiate", "type_line": "Sorcery", "oracle_text": "Destroy target untapped creature."},
            turn=3,
            rng=random.Random(33),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in opponent.battlefield], ["Tapped Bear"])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Untapped Bear"])

    def test_destroy_target_spell_respects_color_type_and_supertype_constraints(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        black_bear = {
            "name": "Black Bear",
            "type_line": "Creature - Bear",
            "colors": ["B"],
            "power": 5,
            "toughness": 5,
        }
        artifact_bear = {
            "name": "Artifact Bear",
            "type_line": "Artifact Creature - Bear",
            "colors": ["G"],
            "power": 4,
            "toughness": 4,
        }
        legal_bear = {
            "name": "Legal Bear",
            "type_line": "Creature - Bear",
            "colors": ["G"],
            "power": 2,
            "toughness": 2,
        }
        opponent.battlefield.extend([black_bear, artifact_bear, legal_bear])
        effect = {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "exclude_card_types": ["artifact"], "exclude_colors": ["B"]},
            "destination": "graveyard",
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Terror",
                "type_line": "Instant",
                "oracle_text": "Destroy target nonartifact, nonblack creature.",
            },
            turn=3,
            rng=random.Random(36),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in opponent.battlefield], ["Black Bear", "Artifact Bear"])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Legal Bear"])

        opponent.battlefield = [
            {"name": "Big Nonlegend", "type_line": "Creature - Giant", "power": 8, "toughness": 8},
            {"name": "Small Legend", "type_line": "Legendary Creature - Human", "power": 1, "toughness": 1},
        ]
        opponent.graveyard = []
        legendary_effect = {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "required_supertypes": ["legendary"]},
            "destination": "graveyard",
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Demise", "type_line": "Instant", "oracle_text": "Destroy target legendary creature."},
            turn=4,
            rng=random.Random(37),
            effect_data_override=legendary_effect,
        )

        self.assertEqual([card["name"] for card in opponent.battlefield], ["Big Nonlegend"])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Small Legend"])

        opponent.battlefield = [
            {"name": "Colorless Construct", "type_line": "Artifact Creature - Construct", "power": 5, "toughness": 5},
            {"name": "Multicolor Bear", "type_line": "Creature - Bear", "colors": ["B", "G"], "power": 4, "toughness": 4},
            {"name": "Monocolor Bear", "type_line": "Creature - Bear", "colors": ["G"], "power": 2, "toughness": 2},
        ]
        opponent.graveyard = []
        monocolor_effect = {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "color_count_exact": 1},
            "destination": "graveyard",
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Price", "type_line": "Instant", "oracle_text": "Destroy target monocolored creature."},
            turn=5,
            rng=random.Random(38),
            effect_data_override=monocolor_effect,
        )

        self.assertEqual([card["name"] for card in opponent.battlefield], ["Colorless Construct", "Multicolor Bear"])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Monocolor Bear"])

    def test_exile_target_spell_respects_power_and_color_constraints(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        small_black = {
            "name": "Small Black Bear",
            "type_line": "Creature - Bear",
            "colors": ["B"],
            "power": 2,
            "toughness": 2,
        }
        large_green = {
            "name": "Large Green Bear",
            "type_line": "Creature - Bear",
            "colors": ["G"],
            "power": 4,
            "toughness": 4,
        }
        opponent.battlefield.extend([small_black, large_green])
        power_effect = {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_exile_target_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "power_min": 4},
            "destination": "exile",
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Blade",
                "type_line": "Instant",
                "oracle_text": "Exile target creature with power 4 or greater.",
            },
            turn=4,
            rng=random.Random(34),
            effect_data_override=power_effect,
        )

        self.assertEqual([card["name"] for card in opponent.battlefield], ["Small Black Bear"])
        self.assertEqual([card["name"] for card in opponent.exile], ["Large Green Bear"])

        color_effect = {
            "effect": "remove_permanent",
            "battle_model_scope": "xmage_exile_target_spell_v1",
            "target": "permanent",
            "target_constraints": {"card_types": ["permanent"], "target_colors": ["B", "R"]},
            "destination": "exile",
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Purge",
                "type_line": "Instant",
                "oracle_text": "Exile target black or red permanent.",
            },
            turn=5,
            rng=random.Random(35),
            effect_data_override=color_effect,
        )

        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.exile], ["Large Green Bear", "Small Black Bear"])

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

    def test_destroy_gain_life_spell_destroys_target_and_gains_life_for_controller(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.life = 10
        opponent.life = 20
        target = {"name": "Target Relic", "type_line": "Artifact", "cmc": 2}
        opponent.battlefield.append(target)
        effect = {
            "effect": "remove_permanent",
            "battle_model_scope": "xmage_destroy_target_and_controller_gain_life_spell_v1",
            "target": "artifact_or_enchantment",
            "target_constraints": {"card_types": ["artifact", "enchantment"]},
            "destination": "graveyard",
            "controller_gains_life": 4,
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Offering",
                "type_line": "Instant",
                "oracle_text": "Destroy target artifact or enchantment. You gain 4 life.",
            },
            turn=3,
            rng=random.Random(31),
            effect_data_override=effect,
        )

        self.assertEqual(active.life, 14)
        self.assertEqual(opponent.life, 20)
        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Target Relic"])
        self.assertTrue(
            any(
                event == "removal_resolved"
                and data.get("card") == "Fixture Offering"
                and data.get("target") == "Target Relic"
                and data.get("destination") == "graveyard"
                and data.get("controller_gains_life") == 4
                and data.get("life_gain_recipient") == "controller"
                and data.get("life_gain_requested") == 4
                and data.get("life_gained") == 4
                for event, data in self.events
            )
        )

    def test_fixed_life_gain_spell_uses_gain_life_runtime(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.life = 10
        effect = {
            "effect": "life_total_change",
            "battle_model_scope": "xmage_fixed_controller_gain_life_spell_v1",
            "life_gain_amount": 7,
            "target": "self",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Life", "type_line": "Sorcery", "oracle_text": "You gain 7 life."},
            turn=4,
            rng=random.Random(4),
            effect_data_override=effect,
        )

        self.assertEqual(active.life, 17)
        self.assertTrue(
            any(
                event == "life_total_changed"
                and data.get("card") == "Fixture Life"
                and data.get("mode") == "gain_life"
                and data.get("requested_delta") == 7
                and data.get("life_after") == 17
                and data.get("changed") is True
                for event, data in self.events
            )
        )

    def test_fixed_life_gain_spell_respects_cant_gain_life(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.life = 10
        active.cant_gain_life = True
        active.cant_gain_life_source = "Fixture Static"
        effect = {
            "effect": "life_total_change",
            "battle_model_scope": "xmage_fixed_controller_gain_life_spell_v1",
            "life_gain_amount": 7,
            "target": "self",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Life", "type_line": "Sorcery", "oracle_text": "You gain 7 life."},
            turn=4,
            rng=random.Random(44),
            effect_data_override=effect,
        )

        self.assertEqual(active.life, 10)
        self.assertTrue(
            any(
                event == "life_gain_prevented"
                and data.get("player") == "Active"
                and data.get("amount") == 7
                and data.get("source") == "Fixture Static"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "life_total_changed"
                and data.get("card") == "Fixture Life"
                and data.get("changed") is False
                and data.get("life_after") == 10
                for event, data in self.events
            )
        )

    def test_composite_life_gain_draw_spell_resolves_both_components_once(self) -> None:
        active = self.battle.Player("Active", None, [{"name": "Drawn Card"}])
        opponent = self.battle.Player("Opponent", None, [])
        active.life = 12
        effect = {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_fixed_controller_gain_life_draw_card_spell_v1",
            "_composite_rule_components": [
                {
                    "effect": "life_total_change",
                    "battle_model_scope": "xmage_fixed_controller_gain_life_spell_v1",
                    "life_gain_amount": 3,
                    "target": "self",
                    "compose_on_resolution": True,
                },
                {
                    "effect": "draw_cards",
                    "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                    "count": 1,
                    "compose_on_resolution": True,
                },
            ],
        }
        card = {
            "name": "Fixture Revitalize",
            "type_line": "Instant",
            "oracle_text": "You gain 3 life. Draw a card.",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            card,
            turn=4,
            rng=random.Random(47),
            effect_data_override=effect,
        )

        self.assertEqual(active.life, 15)
        self.assertEqual([card["name"] for card in active.hand], ["Drawn Card"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Revitalize"])
        self.assertTrue(
            any(
                event == "life_total_changed"
                and data.get("card") == "Fixture Revitalize"
                and data.get("component_index") == 0
                and data.get("requested_delta") == 3
                and data.get("life_after") == 15
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "composite_rule_resolved"
                and data.get("card") == "Fixture Revitalize"
                and data.get("components_applied") == 2
                and data.get("components_skipped") == 0
                for event, data in self.events
            )
        )

    def test_composite_boost_draw_spell_resolves_both_components_once(self) -> None:
        active = self.battle.Player("Active", None, [{"name": "Drawn Card"}])
        opponent = self.battle.Player("Opponent", None, [])
        active.battlefield = [
            {"name": "Active Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        ]
        effect = {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1",
            "_composite_rule_components": [
                {
                    "effect": "stat_modifier_until_eot",
                    "battle_model_scope": "xmage_fixed_boost_target_creature_until_eot_spell_v1",
                    "target": "creature",
                    "target_constraints": {"card_types": ["creature"]},
                    "target_controller": "any",
                    "power_delta": 1,
                    "toughness_delta": 0,
                    "compose_on_resolution": True,
                },
                {
                    "effect": "draw_cards",
                    "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                    "count": 1,
                    "compose_on_resolution": True,
                },
            ],
        }
        card = {
            "name": "Fixture Defiant Strike",
            "type_line": "Instant",
            "oracle_text": "Target creature gets +1/+0 until end of turn. Draw a card.",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            card,
            turn=5,
            rng=random.Random(48),
            effect_data_override=effect,
        )

        self.assertEqual(active.battlefield[0]["power"], 3)
        self.assertEqual(active.battlefield[0]["toughness"], 2)
        self.assertEqual([card["name"] for card in active.hand], ["Drawn Card"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Defiant Strike"])
        self.assertTrue(
            any(
                event == "stat_modifier_until_eot_resolved"
                and data.get("card") == "Fixture Defiant Strike"
                and data.get("target") == "Active Bear"
                and data.get("target_power_after") == 3
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "composite_rule_resolved"
                and data.get("card") == "Fixture Defiant Strike"
                and data.get("components_applied") == 2
                and data.get("components_skipped") == 0
                for event, data in self.events
            )
        )

    def test_composite_destroy_draw_spell_resolves_both_components_once(self) -> None:
        active = self.battle.Player("Active", None, [{"name": "Drawn Card"}])
        opponent = self.battle.Player("Opponent", None, [])
        opponent.battlefield = [
            {"name": "Target Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        ]
        effect = {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_destroy_target_and_draw_card_spell_v1",
            "_composite_rule_components": [
                {
                    "effect": "remove_creature",
                    "battle_model_scope": "xmage_destroy_target_spell_v1",
                    "target": "creature",
                    "target_constraints": {"card_types": ["creature"]},
                    "destination": "graveyard",
                    "compose_on_resolution": True,
                },
                {
                    "effect": "draw_cards",
                    "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                    "count": 1,
                    "compose_on_resolution": True,
                },
            ],
        }
        card = {
            "name": "Fixture Annihilate",
            "type_line": "Sorcery",
            "oracle_text": "Destroy target creature. Draw a card.",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            card,
            turn=5,
            rng=random.Random(49),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Target Bear"])
        self.assertEqual([card["name"] for card in active.hand], ["Drawn Card"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Annihilate"])
        self.assertTrue(
            any(
                event == "removal_resolved"
                and data.get("card") == "Fixture Annihilate"
                and data.get("target") == "Target Bear"
                and data.get("destination") == "graveyard"
                and data.get("component_index") == 0
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "composite_rule_resolved"
                and data.get("card") == "Fixture Annihilate"
                and data.get("components_applied") == 2
                and data.get("components_skipped") == 0
                for event, data in self.events
            )
        )

    def test_composite_bounce_draw_spell_moves_target_to_hand_and_draws_once(self) -> None:
        active = self.battle.Player("Active", None, [{"name": "Drawn Card"}])
        opponent = self.battle.Player("Opponent", None, [])
        opponent.battlefield = [
            {
                "name": "Target Bear",
                "type_line": "Creature - Bear",
                "power": 2,
                "toughness": 2,
                "tapped": True,
            }
        ]
        effect = {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_return_target_to_hand_and_draw_card_spell_v1",
            "_composite_rule_components": [
                {
                    "effect": "remove_creature",
                    "battle_model_scope": "xmage_return_target_to_hand_spell_v1",
                    "target": "creature",
                    "target_constraints": {"card_types": ["creature"], "tapped_state": "tapped"},
                    "destination": "hand",
                    "compose_on_resolution": True,
                },
                {
                    "effect": "draw_cards",
                    "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                    "count": 1,
                    "compose_on_resolution": True,
                },
            ],
        }
        card = {
            "name": "Fixture Galestrike",
            "type_line": "Instant",
            "oracle_text": "Return target tapped creature to its owner's hand. Draw a card.",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            card,
            turn=5,
            rng=random.Random(50),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.hand], ["Target Bear"])
        self.assertEqual(opponent.graveyard, [])
        self.assertEqual([card["name"] for card in active.hand], ["Drawn Card"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Galestrike"])
        self.assertTrue(
            any(
                event == "removal_resolved"
                and data.get("card") == "Fixture Galestrike"
                and data.get("target") == "Target Bear"
                and data.get("destination") == "hand"
                and data.get("component_index") == 0
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "composite_rule_resolved"
                and data.get("card") == "Fixture Galestrike"
                and data.get("components_applied") == 2
                and data.get("components_skipped") == 0
                for event, data in self.events
            )
        )

    def test_composite_scry_draw_spell_reorders_library_then_draws_once(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Low Priority Land", "type_line": "Land", "cmc": 0},
                {"name": "Approach of the Second Sun", "type_line": "Sorcery", "cmc": 7},
                {"name": "Library Remainder", "type_line": "Instant", "cmc": 2},
            ],
        )
        opponent = self.battle.Player("Opponent", None, [])
        effect = {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_fixed_scry_and_draw_cards_spell_v1",
            "_composite_rule_components": [
                {
                    "effect": "scry",
                    "battle_model_scope": "xmage_fixed_scry_spell_v1",
                    "count": 2,
                    "compose_on_resolution": True,
                },
                {
                    "effect": "draw_cards",
                    "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                    "count": 1,
                    "compose_on_resolution": True,
                },
            ],
        }
        card = {
            "name": "Fixture Deliberate",
            "type_line": "Instant",
            "oracle_text": "Scry 2, then draw a card.",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            card,
            turn=5,
            rng=random.Random(51),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Approach of the Second Sun"])
        self.assertEqual([card["name"] for card in active.library], ["Low Priority Land", "Library Remainder"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Deliberate"])
        self.assertTrue(
            any(
                event == "scry_resolved"
                and data.get("card") == "Fixture Deliberate"
                and data.get("component_index") == 0
                and data.get("scry_count") == 2
                and "Approach of the Second Sun" in data.get("kept_on_top", [])
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "composite_rule_resolved"
                and data.get("card") == "Fixture Deliberate"
                and data.get("components_applied") == 2
                and data.get("components_skipped") == 0
                for event, data in self.events
            )
        )

    def test_composite_damage_draw_spell_damages_player_then_draws_once(self) -> None:
        active = self.battle.Player("Active", None, [{"name": "Fresh Draw"}])
        opponent = self.battle.Player("Opponent", None, [])
        opponent.life = 20
        effect = {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_fixed_damage_target_and_draw_card_spell_v1",
            "_composite_rule_components": [
                {
                    "effect": "direct_damage",
                    "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
                    "amount": 3,
                    "damage": 3,
                    "target": "any_target",
                    "target_constraints": {"card_types": ["any"]},
                    "compose_on_resolution": True,
                },
                {
                    "effect": "draw_cards",
                    "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                    "count": 1,
                    "compose_on_resolution": True,
                },
            ],
        }
        card = {
            "name": "Fixture Ember Shot",
            "type_line": "Instant",
            "oracle_text": "Fixture Ember Shot deals 3 damage to any target. Draw a card.",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            card,
            turn=5,
            rng=random.Random(52),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.life, 17)
        self.assertEqual([card["name"] for card in active.hand], ["Fresh Draw"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Ember Shot"])
        self.assertTrue(
            any(
                event == "damage_resolved"
                and data.get("card") == "Fixture Ember Shot"
                and data.get("amount") == 3
                and data.get("result") == "player_damage"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "composite_rule_resolved"
                and data.get("card") == "Fixture Ember Shot"
                and data.get("components_applied") == 2
                and data.get("components_skipped") == 0
                for event, data in self.events
            )
        )

    def test_composite_destroy_scry_spell_removes_target_then_scries(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Low Priority Land", "type_line": "Land", "cmc": 0},
                {"name": "Approach of the Second Sun", "type_line": "Sorcery", "cmc": 7},
                {"name": "Library Remainder", "type_line": "Instant", "cmc": 2},
            ],
        )
        opponent = self.battle.Player("Opponent", None, [])
        target = {
            "name": "Target Relic",
            "type_line": "Artifact",
            "effect": "artifact",
            "cmc": 2,
        }
        opponent.battlefield.append(target)
        effect = {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_destroy_target_and_scry_spell_v1",
            "_composite_rule_components": [
                {
                    "effect": "remove_permanent",
                    "battle_model_scope": "xmage_destroy_target_spell_v1",
                    "target": "artifact",
                    "target_constraints": {"card_types": ["artifact"]},
                    "destination": "graveyard",
                    "compose_on_resolution": True,
                },
                {
                    "effect": "scry",
                    "battle_model_scope": "xmage_fixed_scry_spell_v1",
                    "count": 2,
                    "scry_count": 2,
                    "compose_on_resolution": True,
                },
            ],
        }
        card = {
            "name": "Fixture Sorrow",
            "type_line": "Instant",
            "oracle_text": "Destroy target artifact. Scry 2.",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            card,
            turn=5,
            rng=random.Random(53),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Target Relic"])
        self.assertEqual(active.library[0]["name"], "Approach of the Second Sun")
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Sorrow"])
        self.assertTrue(
            any(
                event == "removal_resolved"
                and data.get("card") == "Fixture Sorrow"
                and data.get("target") == "Target Relic"
                and data.get("destination") == "graveyard"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "scry_resolved"
                and data.get("card") == "Fixture Sorrow"
                and data.get("component_index") == 1
                and data.get("scry_count") == 2
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "composite_rule_resolved"
                and data.get("card") == "Fixture Sorrow"
                and data.get("components_applied") == 2
                and data.get("components_skipped") == 0
                for event, data in self.events
            )
        )

    def test_creature_etb_gain_life_resolves_after_entering_battlefield(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.life = 20
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_gain_life_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_life_gain_amount": 3,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Cleric",
                "type_line": "Creature - Human Cleric",
                "oracle_text": "When Fixture Cleric enters, you gain 3 life.",
                "power": 2,
                "toughness": 2,
            },
            turn=4,
            rng=random.Random(45),
            effect_data_override=effect,
        )

        self.assertEqual(active.life, 23)
        self.assertEqual([card["name"] for card in active.battlefield], ["Fixture Cleric"])
        self.assertTrue(
            any(
                event == "trigger_resolved"
                and data.get("card") == "Fixture Cleric"
                and data.get("trigger") == "enters_battlefield"
                and data.get("effect") == "gain_life"
                and data.get("life_gain_requested") == 3
                and data.get("life_gained") == 3
                and data.get("controller_life_after") == 23
                for event, data in self.events
            )
        )

    def test_creature_etb_draw_resolves_after_entering_battlefield(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Drawn A"}, {"name": "Drawn B"}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_draw_cards_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_draw_count": 1,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Visionary",
                "type_line": "Creature - Elf Shaman",
                "oracle_text": "When Fixture Visionary enters, draw a card.",
                "power": 1,
                "toughness": 1,
            },
            turn=4,
            rng=random.Random(46),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Fixture Visionary"])
        self.assertEqual([card["name"] for card in active.hand], ["Drawn A"])
        self.assertEqual([card["name"] for card in active.library], ["Drawn B"])
        self.assertTrue(
            any(
                event == "trigger_resolved"
                and data.get("card") == "Fixture Visionary"
                and data.get("trigger") == "enters_battlefield"
                and data.get("effect") == "draw_cards"
                and data.get("cards_requested") == 1
                and data.get("cards_drawn") == 1
                and data.get("hand_after") == 1
                for event, data in self.events
            )
        )

    def test_creature_etb_destroy_resolves_after_entering_battlefield(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Target Relic", "type_line": "Artifact", "cmc": 2}
        opponent.battlefield.append(target)
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_destroy_target_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_remove_effect": "remove_permanent",
            "etb_remove_target": "artifact",
            "target_constraints": {"card_types": ["artifact"]},
            "destination": "graveyard",
            "_rule_logical_key": "battle_rule_v1:fixture_etb_destroy",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Vandal",
                "type_line": "Creature - Human Warrior",
                "oracle_text": "When this creature enters, destroy target artifact.",
                "power": 2,
                "toughness": 2,
            },
            turn=4,
            rng=random.Random(47),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Fixture Vandal"])
        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Target Relic"])
        self.assertTrue(
            any(
                event == "etb_removal_resolved"
                and data.get("card") == "Fixture Vandal"
                and data.get("trigger") == "enters_battlefield"
                and data.get("rule_logical_key") == "battle_rule_v1:fixture_etb_destroy"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "removal_resolved"
                and data.get("card") == "Fixture Vandal"
                and data.get("target") == "Target Relic"
                and data.get("destination") == "graveyard"
                for event, data in self.events
            )
        )

    def test_creature_etb_damage_resolves_after_entering_battlefield(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {
            "name": "Target Piker",
            "type_line": "Creature - Goblin Warrior",
            "power": 2,
            "toughness": 1,
        }
        opponent.battlefield.append(target)
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_fixed_damage_target_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_damage_amount": 1,
            "etb_damage_target": "creature",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "_rule_logical_key": "battle_rule_v1:fixture_etb_damage",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Sparkmage",
                "type_line": "Creature - Human Wizard",
                "oracle_text": "When this creature enters, it deals 1 damage to target creature.",
                "power": 1,
                "toughness": 1,
            },
            turn=4,
            rng=random.Random(49),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Fixture Sparkmage"])
        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Target Piker"])
        self.assertTrue(
            any(
                event == "damage_resolved"
                and data.get("card") == "Fixture Sparkmage"
                and data.get("target") == "Target Piker"
                and data.get("amount") == 1
                and data.get("result") == "creature_destroyed"
                and data.get("rule_logical_key") == "battle_rule_v1:fixture_etb_damage"
                for event, data in self.events
            )
        )

    def test_creature_tap_damage_enters_without_damage_then_activates(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        opponent.life = 5
        activated_effect = {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_tap_fixed_damage_target_activated_ability_v1",
            "ability_kind": "activated",
            "activation_requires_tap": True,
            "amount": 2,
            "damage": 2,
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "_rule_source": "curated",
            "_rule_review_status": "verified",
            "_rule_execution_status": "auto",
            "_rule_logical_key": "battle_rule_v1:fixture_tap_damage",
        }
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_tap_fixed_damage_target_activated_v1",
            "ability_kind": "static_and_activated",
            "activated_effect": "direct_damage",
            "activated_battle_model_scope": "xmage_tap_fixed_damage_target_activated_ability_v1",
            "activated_damage_amount": 2,
            "activation_requires_tap": True,
            "_activated_rule_effects": [activated_effect],
            "_rule_source": "curated",
            "_rule_review_status": "verified",
            "_rule_execution_status": "auto",
            "_rule_logical_key": "battle_rule_v1:fixture_tap_damage",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Archer",
                "type_line": "Creature - Human Archer",
                "oracle_text": "{T}: Fixture Archer deals 2 damage to any target.",
                "power": 1,
                "toughness": 1,
            },
            turn=5,
            rng=random.Random(47),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.life, 5)
        self.assertFalse(any(event == "damage_resolved" for event, _ in self.events))
        permanent = active.battlefield[0]
        permanent["summoning_sick"] = False

        activated = self.battle.activate_generic_tap_damage_permanent(
            active,
            [opponent],
            permanent,
            turn=6,
            rng=random.Random(48),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertTrue(permanent["tapped"])
        self.assertEqual(opponent.life, 3)
        self.assertTrue(
            any(
                event == "activated_ability"
                and data.get("card") == "Fixture Archer"
                and data.get("activation_kind") == "tap_damage"
                and data.get("rule_logical_key") == "battle_rule_v1:fixture_tap_damage"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "damage_resolved"
                and data.get("card") == "Fixture Archer"
                and data.get("amount") == 2
                and data.get("result") == "player_damage"
                and data.get("phase") == "precombat_main"
                for event, data in self.events
            )
        )

    def test_simple_activated_damage_artifact_pays_taps_sacrifices_and_damages_player(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        opponent.life = 5
        active.mana_pool.add_generic(1)
        permanent = {
            "name": "Fixture Aeolipile",
            "type_line": "Artifact",
            "effect": "artifact",
            "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_effect": "direct_damage",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_damage_amount": 2,
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "activation_cost_mana": "{1}",
            "activation_cost_generic": 1,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "activation_requires_sacrifice": True,
            "_rule_logical_key": "battle_rule_v1:fixture_aeolipile",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_generic_tap_damage_permanent(
            active,
            [opponent],
            permanent,
            turn=7,
            rng=random.Random(52),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertNotIn(permanent, active.battlefield)
        self.assertIn(permanent, active.graveyard)
        self.assertTrue(permanent.get("tapped"))
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual(opponent.life, 3)
        self.assertTrue(
            any(
                event == "activated_ability"
                and data.get("card") == "Fixture Aeolipile"
                and data.get("activation_kind") == "simple_activated_damage"
                and data.get("activation_cost") == "{1}"
                and data.get("sacrificed_source") is True
                and data.get("mana_paid") == 1
                and data.get("rule_logical_key") == "battle_rule_v1:fixture_aeolipile"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "damage_resolved"
                and data.get("card") == "Fixture Aeolipile"
                and data.get("amount") == 2
                and data.get("result") == "player_damage"
                for event, data in self.events
            )
        )

    def test_simple_activated_damage_creature_pays_colored_sacrifices_and_hits_creature(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(2)
        active.mana_pool.add("red", 1)
        target = {"name": "Target Piker", "type_line": "Creature - Goblin", "power": 2, "toughness": 2}
        opponent.battlefield.append(target)
        permanent = {
            "name": "Fixture Lunatic",
            "type_line": "Creature - Barbarian",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_effect": "direct_damage",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_damage_amount": 2,
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "activation_cost_mana": "{2}{R}",
            "activation_cost_generic": 2,
            "activation_cost_colors": ["R"],
            "activation_requires_tap": False,
            "activation_requires_sacrifice": True,
            "summoning_sick": True,
            "_rule_logical_key": "battle_rule_v1:fixture_lunatic",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_generic_tap_damage_permanent(
            active,
            [opponent],
            permanent,
            turn=7,
            rng=random.Random(53),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertNotIn(permanent, active.battlefield)
        self.assertIn(permanent, active.graveyard)
        self.assertFalse(permanent.get("tapped", False))
        self.assertEqual(active.available_mana(), 0)
        self.assertNotIn(target, opponent.battlefield)
        self.assertIn(target, opponent.graveyard)
        self.assertTrue(
            any(
                event == "activated_ability"
                and data.get("card") == "Fixture Lunatic"
                and data.get("activation_kind") == "simple_activated_damage"
                and data.get("activation_cost") == "{2}{R}"
                and data.get("mana_paid") == 3
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "damage_resolved"
                and data.get("card") == "Fixture Lunatic"
                and data.get("target") == "Target Piker"
                and data.get("result") == "creature_destroyed"
                for event, data in self.events
            )
        )

    def test_simple_activated_damage_respects_flying_creature_target_constraint(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        ground = {"name": "Ground Piker", "type_line": "Creature - Goblin", "power": 2, "toughness": 1}
        flyer = {
            "name": "Flying Drake",
            "type_line": "Creature - Drake",
            "power": 2,
            "toughness": 1,
            "keywords": ["flying"],
        }
        opponent.battlefield.extend([ground, flyer])
        permanent = {
            "name": "Centaur Archer",
            "type_line": "Creature - Centaur Archer",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_effect": "direct_damage",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_damage_amount": 1,
            "target": "flying_creature",
            "target_constraints": {"card_types": ["creature"], "required_keywords": ["flying"]},
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "activation_requires_sacrifice": False,
            "_rule_logical_key": "battle_rule_v1:fixture_centaur_archer",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_generic_tap_damage_permanent(
            active,
            [opponent],
            permanent,
            turn=7,
            rng=random.Random(55),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertIn(ground, opponent.battlefield)
        self.assertNotIn(flyer, opponent.battlefield)
        self.assertIn(flyer, opponent.graveyard)
        self.assertTrue(permanent.get("tapped"))
        self.assertTrue(
            any(
                event == "damage_resolved"
                and data.get("card") == "Centaur Archer"
                and data.get("target") == "Flying Drake"
                and data.get("result") == "creature_destroyed"
                for event, data in self.events
            )
        )

    def test_simple_activated_damage_respects_blocking_creature_target_constraint(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        non_blocker = {"name": "Loose Goblin", "type_line": "Creature - Goblin", "power": 2, "toughness": 1}
        blocker = {
            "name": "Blocking Soldier",
            "type_line": "Creature - Soldier",
            "power": 2,
            "toughness": 2,
            "blocking": True,
        }
        opponent.battlefield.extend([non_blocker, blocker])
        permanent = {
            "name": "War-Torch Goblin",
            "type_line": "Creature - Goblin Warrior",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_effect": "direct_damage",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_damage_amount": 2,
            "target": "blocking_creature",
            "target_constraints": {"card_types": ["creature"], "combat_state": "blocking"},
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": False,
            "activation_requires_sacrifice": True,
            "_rule_logical_key": "battle_rule_v1:fixture_war_torch_goblin",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_generic_tap_damage_permanent(
            active,
            [opponent],
            permanent,
            turn=7,
            rng=random.Random(56),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertIn(non_blocker, opponent.battlefield)
        self.assertNotIn(blocker, opponent.battlefield)
        self.assertIn(blocker, opponent.graveyard)
        self.assertNotIn(permanent, active.battlefield)
        self.assertIn(permanent, active.graveyard)
        self.assertTrue(
            any(
                event == "damage_resolved"
                and data.get("card") == "War-Torch Goblin"
                and data.get("target") == "Blocking Soldier"
                and data.get("result") == "creature_destroyed"
                for event, data in self.events
            )
        )

    def test_simple_activated_damage_blocks_when_mana_is_missing(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        opponent.life = 5
        permanent = {
            "name": "Fixture Aeolipile",
            "type_line": "Artifact",
            "effect": "artifact",
            "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_effect": "direct_damage",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_damage_amount": 2,
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "activation_cost_mana": "{1}",
            "activation_cost_generic": 1,
            "activation_requires_tap": True,
            "activation_requires_sacrifice": True,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_generic_tap_damage_permanent(
            active,
            [opponent],
            permanent,
            turn=7,
            rng=random.Random(54),
            phase="precombat_main",
        )

        self.assertFalse(activated)
        self.assertIn(permanent, active.battlefield)
        self.assertNotIn(permanent, active.graveyard)
        self.assertFalse(permanent.get("tapped", False))
        self.assertEqual(opponent.life, 5)
        self.assertFalse(any(event == "activated_ability" for event, _ in self.events))

    def test_simple_activated_destroy_taps_and_destroys_tapped_creature(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {
            "name": "Tapped Piker",
            "type_line": "Creature - Goblin",
            "power": 2,
            "toughness": 2,
            "tapped": True,
        }
        opponent.battlefield.append(target)
        permanent = {
            "name": "Fixture Assassin",
            "type_line": "Creature - Human Assassin",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_effect": "destroy_target",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_remove_effect": "remove_creature",
            "activated_remove_target": "tapped_creature",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "tapped_state": "tapped"},
            "destination": "graveyard",
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "activation_requires_sacrifice": False,
            "summoning_sick": False,
            "_rule_logical_key": "battle_rule_v1:fixture_assassin",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_generic_destroy_permanent(
            active,
            [opponent],
            [active, opponent],
            permanent,
            turn=15,
            rng=random.Random(15),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertTrue(permanent.get("tapped"))
        self.assertIn(permanent, active.battlefield)
        self.assertNotIn(target, opponent.battlefield)
        self.assertIn(target, opponent.graveyard)
        self.assertTrue(
            any(
                event == "activated_ability"
                and data.get("card") == "Fixture Assassin"
                and data.get("activation_kind") == "simple_activated_destroy"
                and data.get("target") == "Tapped Piker"
                and data.get("rule_logical_key") == "battle_rule_v1:fixture_assassin"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "removal_resolved"
                and data.get("card") == "Fixture Assassin"
                and data.get("target") == "Tapped Piker"
                and data.get("destination") == "graveyard"
                for event, data in self.events
            )
        )

    def test_simple_activated_destroy_self_sacrifices_and_destroys_artifact(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("red", 1)
        target = {"name": "Target Relic", "type_line": "Artifact", "cmc": 2}
        opponent.battlefield.append(target)
        permanent = {
            "name": "Fixture Reveler",
            "type_line": "Creature - Devil",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_effect": "destroy_target",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_remove_effect": "remove_permanent",
            "activated_remove_target": "artifact",
            "target": "artifact",
            "target_constraints": {"card_types": ["artifact"]},
            "destination": "graveyard",
            "activation_cost_mana": "{R}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["R"],
            "activation_requires_tap": False,
            "activation_requires_sacrifice": True,
            "summoning_sick": True,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_generic_destroy_permanent(
            active,
            [opponent],
            [active, opponent],
            permanent,
            turn=16,
            rng=random.Random(16),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertNotIn(permanent, active.battlefield)
        self.assertIn(permanent, active.graveyard)
        self.assertNotIn(target, opponent.battlefield)
        self.assertIn(target, opponent.graveyard)
        self.assertEqual(active.available_mana(), 0)
        self.assertTrue(
            any(
                event == "activated_ability"
                and data.get("card") == "Fixture Reveler"
                and data.get("activation_kind") == "simple_activated_destroy"
                and data.get("sacrificed_source") is True
                and data.get("mana_paid") == 1
                for event, data in self.events
            )
        )

    def test_simple_activated_destroy_respects_color_and_noncreature_artifact_constraints(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("white", 1)
        active.mana_pool.add("colorless", 1)
        green_threat = {
            "name": "Green Giant",
            "type_line": "Creature - Giant",
            "colors": ["G"],
            "power": 8,
            "toughness": 8,
        }
        black_target = {
            "name": "Black Piker",
            "type_line": "Creature - Zombie",
            "colors": ["B"],
            "power": 2,
            "toughness": 2,
        }
        opponent.battlefield.extend([green_threat, black_target])
        permanent = {
            "name": "Fixture Exorcist",
            "type_line": "Creature - Cleric",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_effect": "destroy_target",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_remove_effect": "remove_creature",
            "activated_remove_target": "black_creature",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "target_colors": ["B"]},
            "destination": "graveyard",
            "activation_cost_mana": "{1}{W}",
            "activation_cost_generic": 1,
            "activation_cost_colors": ["W"],
            "activation_requires_tap": True,
            "activation_requires_sacrifice": False,
            "summoning_sick": False,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_generic_destroy_permanent(
            active,
            [opponent],
            [active, opponent],
            permanent,
            turn=17,
            rng=random.Random(117),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertIn(green_threat, opponent.battlefield)
        self.assertNotIn(black_target, opponent.battlefield)
        self.assertIn(black_target, opponent.graveyard)
        self.assertTrue(permanent.get("tapped"))

        active.mana_pool.add("red", 3)
        opponent.battlefield = [
            {"name": "Artifact Golem", "type_line": "Artifact Creature - Golem", "power": 7, "toughness": 7},
            {"name": "Plain Relic", "type_line": "Artifact", "cmc": 1},
        ]
        opponent.graveyard = []
        joven = {
            "name": "Fixture Joven",
            "type_line": "Creature - Human Rogue",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_effect": "destroy_target",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_remove_effect": "remove_permanent",
            "activated_remove_target": "noncreature_artifact",
            "target": "artifact",
            "target_constraints": {"card_types": ["artifact"], "exclude_card_types": ["creature"]},
            "destination": "graveyard",
            "activation_cost_mana": "{R}{R}{R}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["R", "R", "R"],
            "activation_requires_tap": True,
            "activation_requires_sacrifice": False,
            "summoning_sick": False,
        }
        active.battlefield.append(joven)

        activated = self.battle.activate_generic_destroy_permanent(
            active,
            [opponent],
            [active, opponent],
            joven,
            turn=18,
            rng=random.Random(118),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertEqual([card["name"] for card in opponent.battlefield], ["Artifact Golem"])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Plain Relic"])
        self.assertTrue(joven.get("tapped"))

    def test_simple_activated_destroy_blocks_summoning_sick_tap_creature(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Tapped Piker", "type_line": "Creature - Goblin", "tapped": True}
        opponent.battlefield.append(target)
        permanent = {
            "name": "Fixture Assassin",
            "type_line": "Creature - Human Assassin",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_effect": "destroy_target",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_remove_effect": "remove_creature",
            "activated_remove_target": "tapped_creature",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "tapped_state": "tapped"},
            "destination": "graveyard",
            "activation_cost_mana": "{0}",
            "activation_requires_tap": True,
            "activation_requires_sacrifice": False,
            "summoning_sick": True,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_generic_destroy_permanent(
            active,
            [opponent],
            [active, opponent],
            permanent,
            turn=17,
            rng=random.Random(17),
            phase="precombat_main",
        )

        self.assertFalse(activated)
        self.assertFalse(permanent.get("tapped", False))
        self.assertIn(target, opponent.battlefield)
        self.assertEqual(opponent.graveyard, [])
        self.assertFalse(any(event == "removal_resolved" for event, _ in self.events))

    def test_simple_activated_self_boost_pays_mana_and_cleans_up(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("red", 1)
        permanent = {
            "name": "Fixture Hellhound",
            "type_line": "Creature - Elemental Dog",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "activated_effect": "self_stat_modifier_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "target": "self",
            "target_controller": "self",
            "power": 2,
            "toughness": 2,
            "power_delta": 1,
            "toughness_delta": 0,
            "power_boost": 1,
            "toughness_boost": 0,
            "activation_cost_mana": "{R}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["R"],
            "activation_requires_tap": False,
            "summoning_sick": True,
            "_rule_logical_key": "battle_rule_v1:fixture_hellhound",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_generic_self_boost_permanent(
            active,
            [active, opponent],
            permanent,
            turn=18,
            rng=random.Random(18),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual(permanent["power"], 3)
        self.assertEqual(permanent["toughness"], 2)
        self.assertFalse(permanent.get("tapped", False))
        self.assertTrue(
            any(
                event == "activated_ability"
                and data.get("card") == "Fixture Hellhound"
                and data.get("activation_kind") == "simple_activated_self_boost"
                and data.get("activation_cost") == "{R}"
                and data.get("mana_paid") == 1
                and data.get("rule_logical_key") == "battle_rule_v1:fixture_hellhound"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "stat_modifier_until_eot_resolved"
                and data.get("target") == "Fixture Hellhound"
                and data.get("power_delta") == 1
                and data.get("result") == "stat_modifier_until_eot_applied"
                for event, data in self.events
            )
        )

        self.battle.clear_until_eot(active)
        self.assertEqual(permanent["power"], 2)
        self.assertEqual(permanent["toughness"], 2)

    def test_simple_activated_self_boost_blocks_summoning_sick_tap_creature(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {
            "name": "Fixture Matron",
            "type_line": "Creature - Human Cleric",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "activated_effect": "self_stat_modifier_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "power": 1,
            "toughness": 3,
            "power_delta": 0,
            "toughness_delta": 3,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "summoning_sick": True,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_generic_self_boost_permanent(
            active,
            [active, opponent],
            permanent,
            turn=19,
            rng=random.Random(19),
            phase="precombat_main",
        )

        self.assertFalse(activated)
        self.assertEqual(permanent["power"], 1)
        self.assertEqual(permanent["toughness"], 3)
        self.assertFalse(permanent.get("tapped", False))
        self.assertFalse(any(event == "activated_ability" for event, _ in self.events))

    def test_best_simple_activated_self_boost_auto_uses_profitable_nontap_only(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("red", 1)
        tap_only = {
            "name": "Fixture Vanguard",
            "type_line": "Creature - Elf",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "activated_effect": "self_stat_modifier_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "power": 1,
            "toughness": 1,
            "power_delta": 0,
            "toughness_delta": 4,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "summoning_sick": False,
        }
        pump = {
            "name": "Fixture Firebreather",
            "type_line": "Creature - Elemental",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "activated_effect": "self_stat_modifier_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "power": 2,
            "toughness": 2,
            "power_delta": 1,
            "toughness_delta": 0,
            "activation_cost_mana": "{R}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["R"],
            "activation_requires_tap": False,
            "summoning_sick": True,
        }
        active.battlefield.extend([tap_only, pump])

        activated = self.battle.activate_best_generic_self_boost_permanent(
            active,
            [active, opponent],
            turn=20,
            rng=random.Random(20),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertEqual(pump["power"], 3)
        self.assertEqual(tap_only["toughness"], 1)
        self.assertFalse(tap_only.get("tapped", False))

    def test_simple_activated_target_boost_pays_taps_and_cleans_up(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("white", 1)
        source = {
            "name": "Fixture Warden",
            "type_line": "Creature - Spirit",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_target_boost_until_eot_v1",
            "activated_effect": "target_stat_modifier_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_target_boost_until_eot_v1",
            "target": "creature",
            "target_controller": "any",
            "target_constraints": {"card_types": ["creature"]},
            "power_delta": 1,
            "toughness_delta": 1,
            "power_boost": 1,
            "toughness_boost": 1,
            "activation_cost_mana": "{W}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["W"],
            "activation_requires_tap": True,
            "summoning_sick": False,
            "_rule_logical_key": "battle_rule_v1:fixture_warden",
        }
        small = {"name": "Small Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        best = {"name": "Best Bear", "type_line": "Creature - Bear", "power": 4, "toughness": 4}
        enemy = {"name": "Enemy Bear", "type_line": "Creature - Bear", "power": 5, "toughness": 5}
        active.battlefield.extend([source, small, best])
        opponent.battlefield.append(enemy)

        activated = self.battle.activate_generic_target_boost_permanent(
            active,
            [opponent],
            [active, opponent],
            source,
            turn=21,
            rng=random.Random(21),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertTrue(source["tapped"])
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual(best["power"], 5)
        self.assertEqual(best["toughness"], 5)
        self.assertEqual(small["power"], 2)
        self.assertEqual(enemy["power"], 5)
        self.assertTrue(
            any(
                event == "activated_ability"
                and data.get("activation_kind") == "simple_activated_target_boost"
                and data.get("target") == "Best Bear"
                and data.get("power_delta") == 1
                and data.get("rule_logical_key") == "battle_rule_v1:fixture_warden"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "stat_modifier_until_eot_resolved"
                and data.get("card") == "Fixture Warden"
                and data.get("target") == "Best Bear"
                and data.get("result") == "stat_modifier_until_eot_applied"
                for event, data in self.events
            )
        )

        self.battle.clear_until_eot(active)
        self.assertEqual(best["power"], 4)
        self.assertEqual(best["toughness"], 4)

    def test_simple_activated_target_boost_can_kill_opponent_creature(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        source = {
            "name": "Fixture Defiler",
            "type_line": "Creature - Horror",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_target_boost_until_eot_v1",
            "activated_effect": "target_stat_modifier_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_target_boost_until_eot_v1",
            "target": "creature",
            "target_controller": "any",
            "target_constraints": {"card_types": ["creature"]},
            "power_delta": -2,
            "toughness_delta": -2,
            "power_boost": -2,
            "toughness_boost": -2,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": False,
            "summoning_sick": False,
        }
        own = {"name": "Own Bear", "type_line": "Creature - Bear", "power": 3, "toughness": 3}
        enemy = {"name": "Enemy Cub", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        active.battlefield.extend([source, own])
        opponent.battlefield.append(enemy)

        activated = self.battle.activate_generic_target_boost_permanent(
            active,
            [opponent],
            [active, opponent],
            source,
            turn=22,
            rng=random.Random(22),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Enemy Cub"])
        self.assertEqual(active.battlefield, [source, own])
        self.assertTrue(
            any(
                event == "stat_modifier_until_eot_resolved"
                and data.get("card") == "Fixture Defiler"
                and data.get("target") == "Enemy Cub"
                and data.get("result") == "creature_put_into_graveyard_zero_toughness"
                and data.get("destination") == "graveyard"
                for event, data in self.events
            )
        )

    def test_simple_activated_target_boost_sacrifices_source_and_excludes_self_target(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        source = {
            "name": "Fixture Child",
            "type_line": "Creature - Spirit",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_target_boost_until_eot_v1",
            "activated_effect": "target_stat_modifier_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_target_boost_until_eot_v1",
            "target": "creature",
            "target_controller": "any",
            "target_constraints": {"card_types": ["creature"], "exclude_source": True},
            "power_delta": 1,
            "toughness_delta": 1,
            "power_boost": 1,
            "toughness_boost": 1,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": False,
            "activation_requires_sacrifice": True,
            "summoning_sick": False,
        }
        ally = {"name": "Ally Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        active.battlefield.extend([source, ally])

        activated = self.battle.activate_generic_target_boost_permanent(
            active,
            [opponent],
            [active, opponent],
            source,
            turn=23,
            rng=random.Random(23),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertEqual(active.battlefield, [ally])
        self.assertEqual(active.graveyard, [source])
        self.assertEqual(ally["power"], 3)
        self.assertEqual(ally["toughness"], 3)
        self.assertTrue(
            any(
                event == "activated_ability"
                and data.get("card") == "Fixture Child"
                and data.get("sacrificed_source") is True
                and data.get("target") == "Ally Bear"
                for event, data in self.events
            )
        )

    def test_simple_activated_target_boost_blocks_summoning_sick_tap_source(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        source = {
            "name": "Fixture Steed",
            "type_line": "Creature - Beast",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_target_boost_until_eot_v1",
            "activated_effect": "target_stat_modifier_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_target_boost_until_eot_v1",
            "target": "creature",
            "target_controller": "any",
            "target_constraints": {"card_types": ["creature"]},
            "power_delta": -2,
            "toughness_delta": 0,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "summoning_sick": True,
        }
        enemy = {"name": "Enemy Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        active.battlefield.append(source)
        opponent.battlefield.append(enemy)

        activated = self.battle.activate_generic_target_boost_permanent(
            active,
            [opponent],
            [active, opponent],
            source,
            turn=23,
            rng=random.Random(23),
            phase="precombat_main",
        )

        self.assertFalse(activated)
        self.assertFalse(source.get("tapped", False))
        self.assertEqual(enemy["power"], 2)

    def test_simple_activated_target_keyword_pays_taps_and_cleans_up(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("blue", 1)
        active.mana_pool.add("colorless", 1)
        source = {
            "name": "Fixture Glidemaster",
            "type_line": "Creature - Human Wizard",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "activated_effect": "target_keyword_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "target": "creature",
            "target_controller": "self",
            "target_constraints": {"card_types": ["creature"]},
            "granted_keywords_until_eot": ["flying"],
            "activation_cost_mana": "{1}{U}",
            "activation_cost_generic": 1,
            "activation_cost_colors": ["U"],
            "activation_requires_tap": True,
            "summoning_sick": False,
            "_rule_logical_key": "battle_rule_v1:fixture_glidemaster",
        }
        target = {"name": "Ground Bear", "type_line": "Creature - Bear", "power": 3, "toughness": 3}
        active.battlefield.extend([source, target])

        activated = self.battle.activate_generic_target_keyword_permanent(
            active,
            [opponent],
            [active, opponent],
            source,
            turn=21,
            rng=random.Random(21),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertTrue(source["tapped"])
        self.assertEqual(active.available_mana(), 0)
        self.assertTrue(target["flying"])
        self.assertEqual(target["keywords"], ["flying"])
        self.assertTrue(
            any(
                event == "activated_ability"
                and data.get("activation_kind") == "simple_activated_target_keyword"
                and data.get("target") == "Ground Bear"
                and data.get("granted_keywords_until_eot") == ["flying"]
                and data.get("rule_logical_key") == "battle_rule_v1:fixture_glidemaster"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "stat_modifier_until_eot_resolved"
                and data.get("card") == "Fixture Glidemaster"
                and data.get("target") == "Ground Bear"
                and data.get("granted_keywords_until_eot") == ["flying"]
                for event, data in self.events
            )
        )

        self.battle.clear_until_eot(active)
        self.assertNotIn("flying", target)
        self.assertNotIn("keywords", target)

    def test_simple_activated_target_keyword_preserves_source_static_keyword(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        source = {
            "name": "Fixture Efreet",
            "type_line": "Creature - Efreet",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "activated_effect": "target_keyword_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "target": "creature",
            "target_controller": "self",
            "target_constraints": {"card_types": ["creature"]},
            "granted_keywords_until_eot": ["flying"],
            "keywords": ["flying"],
            "_keywords_are_self": True,
            "flying": True,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": False,
            "summoning_sick": False,
        }
        target = {"name": "Ground Bear", "type_line": "Creature - Bear", "power": 3, "toughness": 3}
        active.battlefield.extend([source, target])

        activated = self.battle.activate_generic_target_keyword_permanent(
            active,
            [opponent],
            [active, opponent],
            source,
            turn=22,
            rng=random.Random(22),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertTrue(source["flying"])
        self.assertEqual(source["keywords"], ["flying"])
        self.assertTrue(target["flying"])
        self.assertEqual(target["keywords"], ["flying"])

        self.battle.clear_until_eot(active)
        self.assertTrue(source["flying"])
        self.assertEqual(source["keywords"], ["flying"])
        self.assertNotIn("flying", target)
        self.assertNotIn("keywords", target)

    def test_simple_activated_target_keyword_blocks_summoning_sick_tap_source(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        source = {
            "name": "Fixture Drillmaster",
            "type_line": "Creature - Goblin Shaman",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "activated_effect": "target_keyword_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "target": "creature",
            "target_controller": "any",
            "target_constraints": {"card_types": ["creature"]},
            "granted_keywords_until_eot": ["haste"],
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "summoning_sick": True,
        }
        target = {"name": "Fresh Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        active.battlefield.extend([source, target])

        activated = self.battle.activate_generic_target_keyword_permanent(
            active,
            [opponent],
            [active, opponent],
            source,
            turn=22,
            rng=random.Random(22),
            phase="precombat_main",
        )

        self.assertFalse(activated)
        self.assertFalse(source.get("tapped", False))
        self.assertNotIn("haste", target)

    def test_simple_activated_target_keyword_respects_permanent_subtype_target(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        source = {
            "name": "Fixture Marshal",
            "type_line": "Creature - Human Wizard",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "activated_effect": "target_keyword_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "target": "permanent",
            "target_controller": "self",
            "target_constraints": {"card_types": ["permanent"], "target_subtypes": ["soldier"]},
            "granted_keywords_until_eot": ["flying"],
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": False,
            "summoning_sick": False,
        }
        wrong = {"name": "Large Bear", "type_line": "Creature - Bear", "power": 9, "toughness": 9}
        target = {"name": "Soldier Banner", "type_line": "Kindred Enchantment - Soldier"}
        active.battlefield.extend([source, wrong, target])

        activated = self.battle.activate_generic_target_keyword_permanent(
            active,
            [opponent],
            [active, opponent],
            source,
            turn=23,
            rng=random.Random(23),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertNotIn("flying", wrong)
        self.assertTrue(target["flying"])
        self.assertEqual(target["keywords"], ["flying"])

    def test_simple_activated_target_keyword_respects_combat_subtype_target(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        source = {
            "name": "Fixture Horde",
            "type_line": "Creature - Zombie",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "activated_effect": "target_keyword_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "target": "creature",
            "target_controller": "self",
            "target_constraints": {
                "card_types": ["creature"],
                "combat_state": "attacking",
                "target_subtypes": ["zombie"],
            },
            "granted_keywords_until_eot": ["indestructible"],
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": False,
            "summoning_sick": False,
        }
        wrong_subtype = {
            "name": "Attacking Bear",
            "type_line": "Creature - Bear",
            "power": 9,
            "toughness": 9,
            "attacking": True,
        }
        wrong_state = {
            "name": "Idle Zombie",
            "type_line": "Creature - Zombie",
            "power": 8,
            "toughness": 8,
            "attacking": False,
        }
        target = {
            "name": "Attacking Zombie",
            "type_line": "Creature - Zombie",
            "power": 2,
            "toughness": 2,
            "attacking": True,
        }
        active.battlefield.extend([source, wrong_subtype, wrong_state, target])

        activated = self.battle.activate_generic_target_keyword_permanent(
            active,
            [opponent],
            [active, opponent],
            source,
            turn=24,
            rng=random.Random(24),
            phase="combat",
        )

        self.assertTrue(activated)
        self.assertNotIn("indestructible", wrong_subtype)
        self.assertNotIn("indestructible", wrong_state)
        self.assertTrue(target["indestructible"])

    def test_simple_activated_target_keyword_respects_power_max_target(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        source = {
            "name": "Fixture Glider",
            "type_line": "Artifact",
            "effect": "artifact",
            "battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "activated_effect": "target_keyword_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "target": "creature",
            "target_controller": "self",
            "target_constraints": {"card_types": ["creature"], "power_max": 3},
            "granted_keywords_until_eot": ["flying"],
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": False,
        }
        wrong = {"name": "Huge Beast", "type_line": "Creature - Beast", "power": 9, "toughness": 9}
        target = {"name": "Small Scout", "type_line": "Creature - Scout", "power": 2, "toughness": 2}
        active.battlefield.extend([source, wrong, target])

        activated = self.battle.activate_generic_target_keyword_permanent(
            active,
            [opponent],
            [active, opponent],
            source,
            turn=25,
            rng=random.Random(25),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertNotIn("flying", wrong)
        self.assertTrue(target["flying"])

    def test_creature_tap_damage_blocks_summoning_sick_activation(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        opponent.life = 5
        permanent = {
            "name": "Fixture Archer",
            "type_line": "Creature - Human Archer",
            "effect": "creature",
            "summoning_sick": True,
            "tapped": False,
            "_activated_rule_effects": [
                {
                    "effect": "direct_damage",
                    "battle_model_scope": "xmage_tap_fixed_damage_target_activated_ability_v1",
                    "ability_kind": "activated",
                    "activation_requires_tap": True,
                    "amount": 1,
                    "damage": 1,
                    "target": "any_target",
                    "target_constraints": {"scope": "any_target"},
                }
            ],
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_generic_tap_damage_permanent(
            active,
            [opponent],
            permanent,
            turn=5,
            rng=random.Random(49),
            phase="precombat_main",
        )

        self.assertFalse(activated)
        self.assertFalse(permanent["tapped"])
        self.assertEqual(opponent.life, 5)
        self.assertFalse(any(event == "activated_ability" for event, _ in self.events))

    def test_priority_round_uses_ready_creature_tap_damage(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        opponent.life = 5
        permanent = {
            "name": "Fixture Archer",
            "type_line": "Creature - Human Archer",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
            "summoning_sick": False,
            "tapped": False,
            "_activated_rule_effects": [
                {
                    "effect": "direct_damage",
                    "battle_model_scope": "xmage_tap_fixed_damage_target_activated_ability_v1",
                    "ability_kind": "activated",
                    "activation_requires_tap": True,
                    "amount": 1,
                    "damage": 1,
                    "target": "any_target",
                    "target_constraints": {"scope": "any_target"},
                }
            ],
        }
        active.battlefield.append(permanent)
        stack = self.battle.Stack()

        acted = self.battle.priority_round(
            active,
            [active, opponent],
            stack,
            turn=6,
            rng=random.Random(50),
            phase="precombat_main",
        )

        self.assertTrue(acted)
        self.assertTrue(permanent["tapped"])
        self.assertEqual(opponent.life, 4)

    def test_best_creature_tap_damage_handles_tied_options(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        opponent.life = 5

        def tap_damage_permanent(name: str) -> dict:
            return {
                "name": name,
                "type_line": "Creature - Human Wizard",
                "effect": "creature",
                "power": 1,
                "toughness": 1,
                "summoning_sick": False,
                "tapped": False,
                "_activated_rule_effects": [
                    {
                        "effect": "direct_damage",
                        "battle_model_scope": "xmage_tap_fixed_damage_target_activated_ability_v1",
                        "ability_kind": "activated",
                        "activation_requires_tap": True,
                        "amount": 1,
                        "damage": 1,
                        "target": "any_target",
                        "target_constraints": {"scope": "any_target"},
                    }
                ],
            }

        active.battlefield.extend(
            [
                tap_damage_permanent("Fixture Acolyte"),
                tap_damage_permanent("Fixture Battlemage"),
            ]
        )

        activated = self.battle.activate_best_generic_tap_damage_permanent(
            active,
            [opponent],
            [active, opponent],
            turn=6,
            rng=random.Random(51),
            phase="precombat_main",
        )

        self.assertTrue(activated)
        self.assertEqual(opponent.life, 4)
        tapped = [card["name"] for card in active.battlefield if card.get("tapped")]
        self.assertEqual(tapped, ["Fixture Battlemage"])

    def test_exile_target_spell_moves_permanent_to_exile(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Target Relic", "type_line": "Artifact", "cmc": 2}
        opponent.battlefield.append(target)
        effect = {
            "effect": "remove_permanent",
            "battle_model_scope": "xmage_exile_target_spell_v1",
            "target": "artifact",
            "target_constraints": {"card_types": ["artifact"]},
            "destination": "exile",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Exile", "type_line": "Sorcery", "oracle_text": "Exile target artifact."},
            turn=5,
            rng=random.Random(5),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.exile], ["Target Relic"])
        self.assertEqual(opponent.graveyard, [])
        self.assertTrue(
            any(
                event == "removal_resolved"
                and data.get("card") == "Fixture Exile"
                and data.get("target") == "Target Relic"
                and data.get("destination") == "exile"
                for event, data in self.events
            )
        )

    def test_simple_mana_source_permanent_refreshes_mana(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        effect = {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "C",
            "activation_requires_tap": True,
            "mana_activation_requires_tap": True,
            "permanent_type": "artifact",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Rock", "type_line": "Artifact", "oracle_text": "{T}: Add {C}."},
            turn=6,
            rng=random.Random(6),
            effect_data_override=effect,
        )
        active.refresh_mana_sources(turn=7)

        self.assertEqual(active.available_mana(), 1)
        self.assertEqual(active.mana_pool.colorless, 1)
        self.assertEqual(active.battlefield[0]["name"], "Fixture Rock")
        self.assertTrue(active.battlefield[0]["tapped"])
        self.assertTrue(
            any(
                event == "mana_refreshed"
                and data.get("player") == "Active"
                and data.get("sources") == 1
                for event, data in self.events
            )
        )

    def test_simple_mana_source_permanent_refreshes_fixed_distinct_symbols(self) -> None:
        active = self.battle.Player("Active", None, [])
        engineer = {
            "name": "Gyre Engineer",
            "type_line": "Creature - Vedalken Artificer",
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 2,
            "produces": "GU",
            "produced_mana_symbols": ["G", "U"],
            "activation_requires_tap": True,
            "mana_activation_requires_tap": True,
            "permanent_type": "creature",
        }
        active.battlefield.append(engineer)

        active.refresh_mana_sources(turn=7)

        self.assertEqual(active.available_mana(), 2)
        self.assertEqual(active.mana_pool.green, 1)
        self.assertEqual(active.mana_pool.blue, 1)
        self.assertEqual(active.mana_pool.generic, 0)
        self.assertTrue(engineer["tapped"])

    def test_mana_source_activation_mana_cost_is_paid_before_fixed_symbols_added(self) -> None:
        active = self.battle.Player("Active", None, [])
        blue_source = {
            "name": "Fixture Blue Rock",
            "type_line": "Artifact",
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "U",
            "produced_mana_symbols": ["U"],
            "activation_requires_tap": True,
            "mana_activation_requires_tap": True,
            "permanent_type": "artifact",
        }
        apprentice = {
            "name": "Apprentice Wizard",
            "type_line": "Creature - Human Wizard",
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 3,
            "produces": "C",
            "produced_mana_symbols": ["C", "C", "C"],
            "activation_mana_cost": "{U}",
            "activation_requires_tap": True,
            "mana_activation_requires_tap": True,
            "permanent_type": "creature",
        }
        active.battlefield.extend([blue_source, apprentice])

        active.refresh_mana_sources(turn=8)

        self.assertEqual(active.available_mana(), 3)
        self.assertEqual(active.mana_pool.blue, 0)
        self.assertEqual(active.mana_pool.colorless, 3)
        self.assertTrue(blue_source["tapped"])
        self.assertTrue(apprentice["tapped"])
        self.assertTrue(
            any(
                event == "mana_source_activation_cost_paid"
                and data.get("card") == "Apprentice Wizard"
                and data.get("activation_mana_cost") == "{U}"
                for event, data in self.events
            )
        )

    def test_mana_source_activation_mana_cost_blocks_without_required_mana(self) -> None:
        active = self.battle.Player("Active", None, [])
        apprentice = {
            "name": "Apprentice Wizard",
            "type_line": "Creature - Human Wizard",
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 3,
            "produces": "C",
            "produced_mana_symbols": ["C", "C", "C"],
            "activation_mana_cost": "{U}",
            "activation_requires_tap": True,
            "mana_activation_requires_tap": True,
            "permanent_type": "creature",
        }
        active.battlefield.append(apprentice)

        active.refresh_mana_sources(turn=8)

        self.assertEqual(active.available_mana(), 0)
        self.assertFalse(apprentice.get("tapped", False))
        self.assertTrue(
            any(
                event == "mana_source_activation_skipped"
                and data.get("card") == "Apprentice Wizard"
                and data.get("reason") == "insufficient_mana_for_activation_cost"
                for event, data in self.events
            )
        )

    def test_counter_target_creature_spell_filters_stack_target_type(self) -> None:
        opponent = self.battle.Player("Opponent", None, [])
        counter_effect = {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_v1",
            "target": "creature_spell",
            "target_constraints": {"zone": "stack", "stack_object": "spell", "card_types": ["creature"]},
            "instant": True,
        }
        counter = {
            "name": "Fixture Essence Scatter",
            "type_line": "Instant",
            "mana_cost": "{1}{U}",
            "cmc": 2,
            **counter_effect,
        }
        creature_spell = {"name": "Target Bear", "type_line": "Creature - Bear", "cmc": 2}
        sorcery_spell = {"name": "Target Draw", "type_line": "Sorcery", "cmc": 2}

        self.assertTrue(
            self.battle.counter_can_target(
                counter,
                counter_effect,
                creature_spell,
                stack_item=self.battle.StackItem(creature_spell, opponent, {"effect": "creature"}),
            )
        )
        self.assertFalse(
            self.battle.counter_can_target(
                counter,
                counter_effect,
                sorcery_spell,
                stack_item=self.battle.StackItem(sorcery_spell, opponent, {"effect": "draw_cards"}),
            )
        )

    def test_counter_target_blue_spell_filters_by_target_color(self) -> None:
        opponent = self.battle.Player("Opponent", None, [])
        counter_effect = {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_v1",
            "target": "blue_spell",
            "requires_blue_target": True,
            "target_constraints": {"zone": "stack", "stack_object": "spell", "spell_colors": ["U"]},
            "instant": True,
        }
        blue_spell = {
            "name": "Target Blue",
            "type_line": "Instant",
            "mana_cost": "{1}{U}",
            "colors": ["U"],
            "cmc": 2,
        }
        red_spell = {
            "name": "Target Red",
            "type_line": "Instant",
            "mana_cost": "{1}{R}",
            "colors": ["R"],
            "cmc": 2,
        }

        self.assertTrue(
            self.battle.counter_can_target(
                {},
                counter_effect,
                blue_spell,
                stack_item=self.battle.StackItem(blue_spell, opponent, {"effect": "draw_cards"}),
            )
        )
        self.assertFalse(
            self.battle.counter_can_target(
                {},
                counter_effect,
                red_spell,
                stack_item=self.battle.StackItem(red_spell, opponent, {"effect": "direct_damage"}),
            )
        )

    def test_counterspell_cards_uses_exact_stack_target_constraints(self) -> None:
        opponent = self.battle.Player("Opponent", None, [])
        opponent.mana_pool.add_generic(1)
        opponent.mana_pool.add("blue", 1)
        counter = {
            "name": "Fixture Dispel",
            "type_line": "Instant",
            "mana_cost": "{U}",
            "cmc": 1,
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_v1",
            "target": "instant_spell",
            "target_constraints": {"zone": "stack", "stack_object": "spell", "spell_types": ["instant"]},
            "instant": True,
        }
        opponent.hand.append(counter)
        instant_spell = {"name": "Target Instant", "type_line": "Instant", "cmc": 2}
        sorcery_spell = {"name": "Target Sorcery", "type_line": "Sorcery", "cmc": 2}

        self.assertEqual(
            opponent.counterspell_cards(
                castable_only=True,
                target_card=instant_spell,
                stack_item=self.battle.StackItem(instant_spell, opponent, {"effect": "direct_damage"}),
            ),
            [counter],
        )
        self.assertEqual(
            opponent.counterspell_cards(
                castable_only=True,
                target_card=sorcery_spell,
                stack_item=self.battle.StackItem(sorcery_spell, opponent, {"effect": "draw_cards"}),
            ),
            [],
        )

    def test_counter_draw_scope_is_stack_response_and_draws_on_counter(self) -> None:
        active = self.battle.Player("Active", None, [])
        responder = self.battle.Player(
            "Responder",
            None,
            [{"name": "Fresh Draw", "type_line": "Instant", "cmc": 1}],
        )
        responder.mana_pool.add_generic(2)
        responder.mana_pool.add("blue", 1)
        counter = {
            "name": "Fixture Exclude",
            "type_line": "Instant",
            "mana_cost": "{2}{U}",
            "cmc": 3,
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_and_draw_card_spell_v1",
            "target": "creature_spell",
            "target_constraints": {"zone": "stack", "stack_object": "spell", "card_types": ["creature"]},
            "draw_on_counter": 1,
            "_composite_rule_components": [
                {
                    "effect": "counter",
                    "battle_model_scope": "xmage_counter_target_spell_v1",
                    "target": "creature_spell",
                    "target_constraints": {
                        "zone": "stack",
                        "stack_object": "spell",
                        "card_types": ["creature"],
                    },
                },
                {
                    "effect": "draw_cards",
                    "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                    "count": 1,
                    "compose_on_resolution": True,
                },
            ],
            "instant": True,
        }
        responder.hand.append(counter)
        target_spell = {
            "name": "Target Finisher",
            "type_line": "Creature - Dragon",
            "cmc": 7,
            "effect": "finisher",
        }
        stack = self.battle.Stack()
        stack.push(target_spell, active, {"effect": "finisher"})

        self.assertTrue(
            self.battle.priority_round(
                active,
                [active, responder],
                stack,
                turn=8,
                rng=random.Random(8),
                phase="precombat_main",
            )
        )

        self.assertTrue(stack.items[-1].countered)
        self.assertEqual([card["name"] for card in responder.hand], ["Fresh Draw"])
        self.assertEqual([card["name"] for card in responder.graveyard], ["Fixture Exclude"])
        self.assertTrue(
            any(
                event == "spell_countered"
                and data.get("counter") == "Fixture Exclude"
                and data.get("target") == "Target Finisher"
                and data.get("cards_drawn") == 1
                for event, data in self.events
            )
        )

    def test_return_target_creature_to_owner_hand_moves_from_battlefield_to_hand(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {
            "name": "Target Bear",
            "type_line": "Creature - Bear",
            "power": 2,
            "toughness": 2,
            "tapped": True,
        }
        opponent.battlefield.append(target)
        effect = {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_return_target_to_hand_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "destination": "hand",
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Bounce",
                "type_line": "Instant",
                "oracle_text": "Return target creature to its owner's hand.",
            },
            turn=7,
            rng=random.Random(7),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.hand], ["Target Bear"])
        self.assertEqual(opponent.graveyard, [])
        self.assertNotIn("tapped", opponent.hand[0])
        self.assertTrue(
            any(
                event == "removal_resolved"
                and data.get("card") == "Fixture Bounce"
                and data.get("target") == "Target Bear"
                and data.get("destination") == "hand"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "permanent_moved_from_battlefield"
                and data.get("card") == "Target Bear"
                and data.get("destination") == "hand"
                for event, data in self.events
            )
        )

    def test_graveyard_to_hand_recursion_returns_matching_card_only(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Target Bolt", "type_line": "Instant", "cmc": 1}
        non_target = {"name": "Target Bear", "type_line": "Creature - Bear", "cmc": 2}
        active.graveyard.extend([non_target, target])
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_hand_spell_v1",
            "target": "instant_or_sorcery",
            "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["instant", "sorcery"]},
            "count": 1,
            "destination": "hand",
            "target_controller": "self",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Relearn",
                "type_line": "Sorcery",
                "oracle_text": "Return target instant or sorcery card from your graveyard to your hand.",
            },
            turn=8,
            rng=random.Random(8),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Bolt"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Target Bear", "Fixture Relearn"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Fixture Relearn"
                and data.get("recovered") == ["Target Bolt"]
                and data.get("target_type") == "instant_or_sorcery"
                and data.get("destination") == "hand"
                for event, data in self.events
            )
        )

    def test_graveyard_to_hand_recursion_uses_x_count(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Target Bear A", "type_line": "Creature - Bear", "cmc": 2},
                {"name": "Wrong Bolt", "type_line": "Instant", "cmc": 1},
                {"name": "Target Bear B", "type_line": "Creature - Bear", "cmc": 3},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_hand_spell_v1",
            "target": "creature",
            "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
            "count": 0,
            "count_from_x": True,
            "destination": "hand",
            "target_controller": "self",
            "_cast_context": {"x_value": 2},
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Death Denied",
                "type_line": "Instant",
                "oracle_text": "Return X target creature cards from your graveyard to your hand.",
            },
            turn=8,
            rng=random.Random(108),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Bear A", "Target Bear B"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Wrong Bolt", "Death Denied"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Death Denied"
                and data.get("recovered_count") == 2
                and data.get("x_value") == 2
                for event, data in self.events
            )
        )

    def test_mill_then_return_recursion_can_return_freshly_milled_creature(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Fresh Bear", "type_line": "Creature - Bear", "cmc": 2},
                {"name": "Fresh Mountain", "type_line": "Basic Land - Mountain", "cmc": 0},
                {"name": "Fresh Bolt", "type_line": "Instant", "cmc": 1},
                {"name": "Library Tail", "type_line": "Sorcery", "cmc": 4},
            ],
        )
        opponent = self.battle.Player("Opponent", None, [])
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_mill_then_return_graveyard_card_to_hand_spell_v1",
            "pre_recursion_mill_count": 3,
            "target": "creature",
            "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
            "count": 1,
            "destination": "hand",
            "target_controller": "self",
            "up_to_count": True,
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Corpse Churn",
                "type_line": "Instant",
                "oracle_text": (
                    "Put the top three cards of your library into your graveyard, "
                    "then you may return a creature card from your graveyard to your hand."
                ),
            },
            turn=8,
            rng=random.Random(8),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Fresh Bear"])
        self.assertEqual([card["name"] for card in active.library], ["Library Tail"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fresh Mountain", "Fresh Bolt", "Corpse Churn"])
        self.assertTrue(
            any(
                event == "mill_resolved"
                and data.get("card") == "Corpse Churn"
                and data.get("cards_milled") == 3
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Corpse Churn"
                and data.get("recovered") == ["Fresh Bear"]
                and data.get("pre_recursion_cards_milled") == 3
                for event, data in self.events
            )
        )

    def test_mill_then_return_recursion_matches_creature_or_land(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Fresh Land", "type_line": "Land", "cmc": 0},
                {"name": "Fresh Spell", "type_line": "Instant", "cmc": 1},
                {"name": "Fresh Bear", "type_line": "Creature - Bear", "cmc": 2},
            ],
        )
        opponent = self.battle.Player("Opponent", None, [])
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_mill_then_return_graveyard_card_to_hand_spell_v1",
            "pre_recursion_mill_count": 3,
            "target": "creature_or_land",
            "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature", "land"]},
            "count": 1,
            "destination": "hand",
            "target_controller": "self",
            "up_to_count": True,
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Grapple with the Past", "type_line": "Instant"},
            turn=8,
            rng=random.Random(8),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Fresh Land"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fresh Spell", "Fresh Bear", "Grapple with the Past"])

    def test_graveyard_to_hand_recursion_exiles_self_after_recovery(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        first_target = {"name": "Target Bolt", "type_line": "Instant", "cmc": 1}
        second_target = {"name": "Target Bear", "type_line": "Creature - Bear", "cmc": 2}
        active.graveyard.extend([first_target, second_target])
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_hand_spell_v1",
            "target": "any_card",
            "target_constraints": {"zone": "graveyard", "controller": "self", "scope": "any_card"},
            "count": 2,
            "destination": "hand",
            "target_controller": "self",
            "exiles_self": True,
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Restock",
                "type_line": "Sorcery",
                "oracle_text": "Return two target cards from your graveyard to your hand. Exile Fixture Restock.",
            },
            turn=8,
            rng=random.Random(8),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Bolt", "Target Bear"])
        self.assertEqual(active.graveyard, [])
        self.assertEqual([card["name"] for card in active.exile], ["Fixture Restock"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Fixture Restock"
                and data.get("recovered_count") == 2
                and data.get("destination") == "hand"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "spell_resolved"
                and data.get("card") == "Fixture Restock"
                and data.get("destination") == "exile"
                and data.get("zone_after") == "exile"
                for event, data in self.events
            )
        )

    def test_graveyard_to_hand_x_recursion_exiles_self_and_filters_target(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Target Bolt", "type_line": "Instant", "cmc": 1},
                {"name": "Wrong Bear", "type_line": "Creature - Bear", "cmc": 2},
                {"name": "Target Ritual", "type_line": "Sorcery", "cmc": 2},
                {"name": "Target Charm", "type_line": "Instant", "cmc": 3},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_hand_spell_v1",
            "target": "instant_or_sorcery",
            "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["instant", "sorcery"]},
            "count": 0,
            "count_from_x": True,
            "up_to_count": True,
            "destination": "hand",
            "target_controller": "self",
            "exiles_self": True,
            "_cast_context": {"x_value": 2},
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Divergent Equation",
                "type_line": "Instant",
                "oracle_text": (
                    "Return up to X target instant and/or sorcery cards from your graveyard to your hand. "
                    "Exile Divergent Equation."
                ),
            },
            turn=8,
            rng=random.Random(208),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Bolt", "Target Ritual"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Wrong Bear", "Target Charm"])
        self.assertEqual([card["name"] for card in active.exile], ["Divergent Equation"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Divergent Equation"
                and data.get("recovered") == ["Target Bolt", "Target Ritual"]
                and data.get("recovered_count") == 2
                and data.get("x_value") == 2
                and data.get("target_type") == "instant_or_sorcery"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "spell_resolved"
                and data.get("card") == "Divergent Equation"
                and data.get("destination") == "exile"
                for event, data in self.events
            )
        )

    def test_graveyard_to_hand_recursion_matches_color_and_subtype_targets(self) -> None:
        cases = [
            (
                "Fixture Revive",
                "green_card",
                {"zone": "graveyard", "controller": "self", "colors": ["G"]},
                [
                    {"name": "Colorless Rock", "type_line": "Artifact", "mana_cost": "{2}", "colors": []},
                    {"name": "Green Bear", "type_line": "Creature - Bear", "mana_cost": "{1}{G}", "colors": ["G"]},
                ],
                ["Green Bear"],
            ),
            (
                "Fixture Reborn Hope",
                "multicolored_card",
                {"zone": "graveyard", "controller": "self", "min_colors": 2},
                [
                    {"name": "Mono Green Bear", "type_line": "Creature - Bear", "colors": ["G"]},
                    {"name": "Gold Bear", "type_line": "Creature - Bear", "colors": ["G", "W"]},
                ],
                ["Gold Bear"],
            ),
            (
                "Fixture Boggart Birth Rite",
                "goblin_card",
                {"zone": "graveyard", "controller": "self", "subtypes": ["goblin"]},
                [
                    {"name": "Target Zombie", "type_line": "Creature - Zombie"},
                    {"name": "Target Goblin", "type_line": "Creature - Goblin Warrior"},
                ],
                ["Target Goblin"],
            ),
        ]
        for spell_name, target, constraints, graveyard, expected_names in cases:
            with self.subTest(target=target):
                active = self.battle.Player("Active", None, [])
                opponent = self.battle.Player("Opponent", None, [])
                active.graveyard.extend(graveyard)
                effect = {
                    "effect": "recursion",
                    "battle_model_scope": "xmage_return_target_graveyard_card_to_hand_spell_v1",
                    "target": target,
                    "target_constraints": constraints,
                    "count": 1,
                    "destination": "hand",
                    "target_controller": "self",
                    "sorcery": True,
                }

                self.battle.apply_effect_immediate(
                    active,
                    [opponent],
                    {"name": spell_name, "type_line": "Sorcery"},
                    turn=8,
                    rng=random.Random(8),
                    effect_data_override=effect,
                )

                self.assertEqual([card["name"] for card in active.hand], expected_names)

    def test_graveyard_to_hand_choose_one_or_both_components_resolve(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Target Human", "type_line": "Creature - Human Soldier"},
                {"name": "Target Construct", "type_line": "Artifact Creature - Construct"},
                {"name": "Target Land", "type_line": "Land"},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1",
            "mode_selection": "one_or_both",
            "recursion_components": [
                {
                    "target": "creature",
                    "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
                    "count": 1,
                    "destination": "hand",
                    "target_controller": "self",
                },
                {
                    "target": "land",
                    "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["land"]},
                    "count": 1,
                    "destination": "hand",
                    "target_controller": "self",
                },
            ],
            "destination": "hand",
            "target_controller": "self",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Grim Discovery", "type_line": "Sorcery"},
            turn=8,
            rng=random.Random(8),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Human", "Target Land"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Target Construct", "Fixture Grim Discovery"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("mode_selection") == "one_or_both"
                and data.get("recovered_count") == 2
                and [item["target_type"] for item in data.get("recovered_by_component", [])] == ["creature", "land"]
                for event, data in self.events
            )
        )

    def test_graveyard_to_hand_choose_one_picks_best_component(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Target Zombie A", "type_line": "Creature - Zombie"},
                {"name": "Target Zombie B", "type_line": "Creature - Zombie Wizard"},
                {"name": "Target Human", "type_line": "Creature - Human"},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_choose_one_graveyard_cards_to_hand_spell_v1",
            "mode_selection": "choose_one",
            "recursion_components": [
                {
                    "target": "creature",
                    "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
                    "count": 1,
                    "destination": "hand",
                    "target_controller": "self",
                },
                {
                    "target": "zombie_card",
                    "target_constraints": {"zone": "graveyard", "controller": "self", "subtypes": ["zombie"]},
                    "count": 2,
                    "destination": "hand",
                    "target_controller": "self",
                },
            ],
            "destination": "hand",
            "target_controller": "self",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Ghoulcaller's Chant", "type_line": "Sorcery"},
            turn=8,
            rng=random.Random(8),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Zombie A", "Target Zombie B"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Target Human", "Fixture Ghoulcaller's Chant"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("mode_selection") == "choose_one"
                and data.get("recovered_by_component", [{}])[0].get("index") == 1
                for event, data in self.events
            )
        )

    def test_graveyard_to_hand_choose_one_shared_type_component(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Target Wizard A", "type_line": "Creature - Human Wizard"},
                {"name": "Target Wizard B", "type_line": "Creature - Vedalken Wizard"},
                {"name": "Target Soldier", "type_line": "Creature - Soldier"},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_choose_one_graveyard_cards_to_hand_spell_v1",
            "mode_selection": "choose_one",
            "recursion_components": [
                {
                    "target": "creature",
                    "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
                    "count": 1,
                    "destination": "hand",
                    "target_controller": "self",
                },
                {
                    "target": "shared_creature_type",
                    "target_constraints": {
                        "zone": "graveyard",
                        "controller": "self",
                        "card_types": ["creature"],
                        "shared_subtype_group": "creature_type",
                    },
                    "shared_subtype_group": "creature_type",
                    "count": 2,
                    "destination": "hand",
                    "target_controller": "self",
                },
            ],
            "destination": "hand",
            "target_controller": "self",
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Unbury", "type_line": "Instant"},
            turn=8,
            rng=random.Random(8),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Wizard A", "Target Wizard B"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Target Soldier", "Fixture Unbury"])

    def test_graveyard_to_hand_shared_type_up_to_count_returns_partial_group(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Target Wizard A", "type_line": "Creature - Human Wizard"},
                {"name": "Target Wizard B", "type_line": "Creature - Vedalken Wizard"},
                {"name": "Target Soldier", "type_line": "Creature - Soldier"},
                {"name": "Target Relic", "type_line": "Artifact"},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_hand_spell_v1",
            "target": "shared_creature_type",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "shared_subtype_group": "creature_type",
            },
            "shared_subtype_group": "creature_type",
            "count": 3,
            "up_to_count": True,
            "destination": "hand",
            "target_controller": "self",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Aphetto Dredging", "type_line": "Sorcery"},
            turn=8,
            rng=random.Random(8),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Wizard A", "Target Wizard B"])
        self.assertEqual(
            [card["name"] for card in active.graveyard],
            ["Target Soldier", "Target Relic", "Fixture Aphetto Dredging"],
        )
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("target_type") == "shared_creature_type"
                and data.get("recovered") == ["Target Wizard A", "Target Wizard B"]
                for event, data in self.events
            )
        )

    def test_graveyard_to_hand_exile_self_components_return_noncreature_permanent(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Target Bear", "type_line": "Creature - Bear", "cmc": 2},
                {"name": "Target Relic", "type_line": "Artifact", "cmc": 3},
                {"name": "Wrong Bolt", "type_line": "Instant", "cmc": 1},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1",
            "mode_selection": "all_components",
            "recursion_components": [
                {
                    "target": "creature",
                    "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
                    "count": 1,
                    "up_to_count": True,
                    "destination": "hand",
                    "target_controller": "self",
                },
                {
                    "target": "noncreature_permanent",
                    "target_constraints": {
                        "zone": "graveyard",
                        "controller": "self",
                        "card_types": ["artifact", "enchantment", "planeswalker", "battle", "land"],
                        "exclude_card_types": ["creature"],
                    },
                    "count": 1,
                    "up_to_count": True,
                    "destination": "hand",
                    "target_controller": "self",
                },
            ],
            "destination": "hand",
            "target_controller": "self",
            "exiles_self": True,
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Retrieve",
                "type_line": "Sorcery",
                "oracle_text": (
                    "Return up to one target creature card and up to one target noncreature permanent card "
                    "from your graveyard to your hand. Exile Fixture Retrieve."
                ),
            },
            turn=8,
            rng=random.Random(8),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Bear", "Target Relic"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Wrong Bolt"])
        self.assertEqual([card["name"] for card in active.exile], ["Fixture Retrieve"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("mode_selection") == "all_components"
                and data.get("recovered_count") == 2
                and [item["target_type"] for item in data.get("recovered_by_component", [])]
                == ["creature", "noncreature_permanent"]
                for event, data in self.events
            )
        )

    def test_graveyard_to_hand_for_each_color_returns_one_creature_per_color(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "White Soldier", "type_line": "Creature - Human Soldier", "colors": ["W"]},
                {"name": "Blue Drake", "type_line": "Creature - Drake", "colors": ["U"]},
                {"name": "Black Rogue", "type_line": "Creature - Rogue", "colors": ["B"]},
                {"name": "Red Warrior", "type_line": "Creature - Warrior", "colors": ["R"]},
                {"name": "Green Beast", "type_line": "Creature - Beast", "colors": ["G"]},
                {"name": "Wrong Bolt", "type_line": "Instant", "colors": ["R"]},
                {"name": "Colorless Golem", "type_line": "Artifact Creature - Golem", "colors": []},
            ]
        )
        components = []
        for target, color in [
            ("white_creature", "W"),
            ("blue_creature", "U"),
            ("black_creature", "B"),
            ("red_creature", "R"),
            ("green_creature", "G"),
        ]:
            components.append(
                {
                    "target": target,
                    "target_constraints": {
                        "zone": "graveyard",
                        "controller": "self",
                        "card_types": ["creature"],
                        "colors": [color],
                    },
                    "count": 1,
                    "up_to_count": True,
                    "destination": "hand",
                    "target_controller": "self",
                }
            )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_one_graveyard_creature_per_color_to_hand_spell_v1",
            "mode_selection": "all_components",
            "recursion_components": components,
            "destination": "hand",
            "target_controller": "self",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Rogues' Gallery",
                "type_line": "Sorcery",
                "oracle_text": (
                    "For each color, return up to one target creature card of that color "
                    "from your graveyard to your hand."
                ),
            },
            turn=8,
            rng=random.Random(8),
            effect_data_override=effect,
        )

        self.assertEqual(
            [card["name"] for card in active.hand],
            ["White Soldier", "Blue Drake", "Black Rogue", "Red Warrior", "Green Beast"],
        )
        self.assertEqual(
            [card["name"] for card in active.graveyard],
            ["Wrong Bolt", "Colorless Golem", "Fixture Rogues' Gallery"],
        )
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("mode_selection") == "all_components"
                and data.get("recovered_count") == 5
                and [item["target_type"] for item in data.get("recovered_by_component", [])]
                == ["white_creature", "blue_creature", "black_creature", "red_creature", "green_creature"]
                for event, data in self.events
            )
        )

    def test_graveyard_to_hand_multi_target_respects_mount_vehicle_and_no_abilities(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Target Bear", "type_line": "Creature - Bear", "oracle_text": "Trample"},
                {"name": "Saddle Mount", "type_line": "Creature - Horse Mount", "oracle_text": "Saddle 1"},
                {"name": "Crew Vehicle", "type_line": "Artifact - Vehicle", "oracle_text": "Crew 2"},
                {"name": "Vanilla Wolf", "type_line": "Creature - Wolf", "oracle_text": ""},
                {"name": "Ability Elf", "type_line": "Creature - Elf", "oracle_text": "Tap: Add G."},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_multiple_graveyard_cards_to_hand_spell_v1",
            "mode_selection": "all_components",
            "recursion_components": [
                {
                    "target": "creature",
                    "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
                    "count": 1,
                    "up_to_count": True,
                    "destination": "hand",
                    "target_controller": "self",
                },
                {
                    "target": "mount_card",
                    "target_constraints": {"zone": "graveyard", "controller": "self", "subtypes": ["mount"]},
                    "count": 1,
                    "up_to_count": True,
                    "destination": "hand",
                    "target_controller": "self",
                },
                {
                    "target": "vehicle_card",
                    "target_constraints": {"zone": "graveyard", "controller": "self", "subtypes": ["vehicle"]},
                    "count": 1,
                    "up_to_count": True,
                    "destination": "hand",
                    "target_controller": "self",
                },
                {
                    "target": "creature_no_abilities",
                    "target_constraints": {
                        "zone": "graveyard",
                        "controller": "self",
                        "card_types": ["creature"],
                        "requires_no_abilities": True,
                    },
                    "count": 1,
                    "up_to_count": True,
                    "destination": "hand",
                    "target_controller": "self",
                },
            ],
            "destination": "hand",
            "target_controller": "self",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Rise from the Wreck",
                "type_line": "Sorcery",
                "oracle_text": (
                    "Return up to one target creature card, up to one target Mount card, "
                    "up to one target Vehicle card, and up to one target creature card with no abilities "
                    "from your graveyard to your hand."
                ),
            },
            turn=8,
            rng=random.Random(8),
            effect_data_override=effect,
        )

        self.assertEqual(
            [card["name"] for card in active.hand],
            ["Target Bear", "Saddle Mount", "Crew Vehicle", "Vanilla Wolf"],
        )
        self.assertEqual([card["name"] for card in active.graveyard], ["Ability Elf", "Fixture Rise from the Wreck"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("recovered_count") == 4
                and [item["target_type"] for item in data.get("recovered_by_component", [])]
                == ["creature", "mount_card", "vehicle_card", "creature_no_abilities"]
                for event, data in self.events
            )
        )

    def test_graveyard_to_battlefield_recursion_returns_matching_permanent_only(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Target Bear", "type_line": "Creature - Bear", "cmc": 2}
        non_target = {"name": "Target Bolt", "type_line": "Instant", "cmc": 1}
        active.graveyard.extend([non_target, target])
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_battlefield_spell_v1",
            "target": "creature",
            "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
            "count": 1,
            "destination": "battlefield",
            "target_controller": "self",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Resurrection",
                "type_line": "Sorcery",
                "oracle_text": "Return target creature card from your graveyard to the battlefield.",
            },
            turn=8,
            rng=random.Random(8),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Target Bear"])
        self.assertEqual([card["name"] for card in active.hand], [])
        self.assertEqual([card["name"] for card in active.graveyard], ["Target Bolt", "Fixture Resurrection"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Fixture Resurrection"
                and data.get("recovered") == ["Target Bear"]
                and data.get("target_type") == "creature"
                and data.get("destination") == "battlefield"
                for event, data in self.events
            )
        )

    def test_return_all_matching_graveyard_cards_to_battlefield_respects_filters(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Legal Bear", "type_line": "Creature - Bear", "cmc": 2, "power": 2, "toughness": 2},
                {"name": "Too Large Giant", "type_line": "Creature - Giant", "cmc": 4, "power": 4, "toughness": 4},
                {"name": "Legal Elf", "type_line": "Creature - Elf", "cmc": 1, "power": 1, "toughness": 1},
                {"name": "Wrong Aura", "type_line": "Enchantment - Aura", "cmc": 1},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_all_matching_graveyard_cards_to_battlefield_spell_v1",
            "target": "creature",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "mana_value_max": 2,
            },
            "return_all_matching": True,
            "recursion_mana_value_max": 2,
            "destination": "battlefield",
            "target_controller": "self",
            "target_graveyard_controller": "self",
            "battlefield_controller": "self",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Raise the Past",
                "type_line": "Sorcery",
                "oracle_text": "Return all creature cards with mana value 2 or less from your graveyard to the battlefield.",
            },
            turn=8,
            rng=random.Random(208),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Legal Bear", "Legal Elf"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Too Large Giant", "Wrong Aura", "Raise the Past"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Raise the Past"
                and data.get("recovered") == ["Legal Bear", "Legal Elf"]
                and data.get("return_all_matching") is True
                and data.get("mana_value_max") == 2
                and data.get("destination") == "battlefield"
                for event, data in self.events
            )
        )

    def test_graveyard_to_battlefield_recursion_uses_x_mana_value_limit(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Too Large", "type_line": "Creature - Giant", "cmc": 4, "power": 4, "toughness": 4},
                {"name": "Legal Bear", "type_line": "Creature - Bear", "cmc": 3, "power": 3, "toughness": 3},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_battlefield_spell_v1",
            "target": "creature",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "mana_value_max_source": "x_value",
            },
            "count": 1,
            "destination": "battlefield",
            "target_controller": "self",
            "target_graveyard_controller": "self",
            "battlefield_controller": "self",
            "target_mana_value_max_from_x": True,
            "_cast_context": {"x_value": 3},
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Stir the Grave",
                "type_line": "Sorcery",
                "oracle_text": "Return target creature card with mana value X or less from your graveyard to the battlefield.",
            },
            turn=9,
            rng=random.Random(109),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Legal Bear"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Too Large", "Stir the Grave"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Stir the Grave"
                and data.get("mana_value_max") == 3
                and data.get("x_value") == 3
                for event, data in self.events
            )
        )

    def test_graveyard_to_battlefield_recursion_uses_x_outlaw_count(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Target Rogue", "type_line": "Creature - Human Rogue", "cmc": 2, "power": 2, "toughness": 2},
                {"name": "Wrong Soldier", "type_line": "Creature - Human Soldier", "cmc": 2, "power": 2, "toughness": 2},
                {"name": "Target Pirate", "type_line": "Creature - Goblin Pirate", "cmc": 3, "power": 3, "toughness": 2},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_battlefield_spell_v1",
            "target": "outlaw_creature",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["creature"],
                "subtype_group": "outlaw",
                "subtypes": ["assassin", "mercenary", "pirate", "rogue", "warlock"],
            },
            "count": 0,
            "count_from_x": True,
            "destination": "battlefield",
            "target_controller": "self",
            "target_graveyard_controller": "self",
            "battlefield_controller": "self",
            "_cast_context": {"x_value": 2},
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Back in Town",
                "type_line": "Sorcery",
                "oracle_text": "Return X target outlaw creature cards from your graveyard to the battlefield.",
            },
            turn=9,
            rng=random.Random(110),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Target Rogue", "Target Pirate"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Wrong Soldier", "Back in Town"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Back in Town"
                and data.get("recovered") == ["Target Rogue", "Target Pirate"]
                and data.get("x_value") == 2
                for event, data in self.events
            )
        )

    def test_graveyard_to_battlefield_uses_graveyard_permanent_count_mana_value_limit(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Too Large Relic", "type_line": "Artifact", "cmc": 4},
                {"name": "Legal Relic", "type_line": "Artifact", "cmc": 2},
                {"name": "Wrong Land", "type_line": "Land", "cmc": 0},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_battlefield_spell_v1",
            "target": "nonland_permanent",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["artifact", "creature", "enchantment", "planeswalker", "battle"],
                "exclude_card_types": ["land"],
                "mana_value_max_source": "graveyard_permanent_count",
            },
            "count": 1,
            "destination": "battlefield",
            "target_controller": "self",
            "target_graveyard_controller": "self",
            "battlefield_controller": "self",
            "target_mana_value_max_from_graveyard_permanent_count": True,
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Squirming Emergence",
                "type_line": "Sorcery",
                "oracle_text": (
                    "Fathomless descent — Return to the battlefield target nonland permanent card "
                    "in your graveyard with mana value less than or equal to the number of permanent cards in your graveyard."
                ),
            },
            turn=9,
            rng=random.Random(111),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Legal Relic"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Too Large Relic", "Wrong Land", "Fixture Squirming Emergence"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Fixture Squirming Emergence"
                and data.get("mana_value_max") == 3
                and data.get("recovered") == ["Legal Relic"]
                for event, data in self.events
            )
        )

    def test_graveyard_to_battlefield_choose_one_or_both_components_resolve(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.extend(
            [
                {"name": "Target Bear", "type_line": "Creature - Bear", "cmc": 2, "power": 2, "toughness": 2},
                {"name": "Target Aura", "type_line": "Enchantment - Aura", "cmc": 1},
                {"name": "Wrong Relic", "type_line": "Artifact", "cmc": 1},
            ]
        )
        effect = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_one_or_both_graveyard_cards_to_battlefield_spell_v1",
            "mode_selection": "one_or_both",
            "recursion_components": [
                {
                    "target": "creature",
                    "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
                    "count": 1,
                    "destination": "battlefield",
                    "target_controller": "self",
                    "target_graveyard_controller": "self",
                    "battlefield_controller": "self",
                },
                {
                    "target": "aura_card",
                    "target_constraints": {"zone": "graveyard", "controller": "self", "subtypes": ["aura"]},
                    "count": 1,
                    "destination": "battlefield",
                    "target_controller": "self",
                    "target_graveyard_controller": "self",
                    "battlefield_controller": "self",
                },
            ],
            "destination": "battlefield",
            "target_controller": "self",
            "target_graveyard_controller": "self",
            "battlefield_controller": "self",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Rise to Glory",
                "type_line": "Sorcery",
                "oracle_text": (
                    "Choose one or both — Return target creature card from your graveyard to the battlefield. "
                    "Return target Aura card from your graveyard to the battlefield."
                ),
            },
            turn=9,
            rng=random.Random(112),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Target Bear", "Target Aura"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Wrong Relic", "Fixture Rise to Glory"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("mode_selection") == "one_or_both"
                and [item["target_type"] for item in data.get("recovered_by_component", [])]
                == ["creature", "aura_card"]
                for event, data in self.events
            )
        )

    def test_simple_activated_recursion_to_battlefield_respects_this_turn_and_enters_tapped(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("colorless", 2)
        wrong_old = {
            "name": "Old Bear",
            "type_line": "Creature - Bear",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "cmc": 2,
        }
        target = {
            "name": "Fresh Bear",
            "type_line": "Creature - Bear",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "cmc": 2,
            "_put_into_graveyard_from_battlefield_turn": 16,
        }
        active.graveyard.extend([wrong_old, target])
        permanent = {
            "name": "Fixture Othelm",
            "type_line": "Creature - Human",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_battlefield_v1",
            "activated_effect": "recursion",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_battlefield_v1",
            "graveyard_to_hand_target": "creature",
            "graveyard_to_hand_target_count": 1,
            "graveyard_to_hand_destination": "battlefield",
            "graveyard_to_hand_activation_cost_mana": "{2}",
            "graveyard_to_hand_activation_cost_generic": 2,
            "graveyard_to_hand_activation_cost_colors": [],
            "graveyard_to_hand_activation_requires_tap": True,
            "graveyard_to_hand_activation_requires_sacrifice": False,
            "graveyard_from_battlefield_this_turn": True,
            "enters_tapped": True,
            "summoning_sick": False,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=16,
            rng=random.Random(16),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual([card["name"] for card in active.graveyard], ["Old Bear"])
        self.assertEqual([card["name"] for card in active.battlefield], ["Fixture Othelm", "Fresh Bear"])
        self.assertTrue(active.battlefield[1].get("tapped"))
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Fixture Othelm"
                and data.get("recovered") == ["Fresh Bear"]
                and data.get("activation_kind") == "simple_activated_graveyard_to_battlefield"
                for event, data in self.events
            )
        )

    def test_creature_dies_draw_trigger_draws_when_moved_to_graveyard(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Draw A"}, {"name": "Draw B"}, {"name": "Draw C"}],
        )
        permanent = {
            "name": "Fixture Scholar",
            "type_line": "Creature - Human Wizard",
            "battle_model_scope": "xmage_creature_dies_draw_cards_v1",
            "draw_cards_when_this_dies": 2,
        }
        active.battlefield.append(permanent)

        destination = self.battle.move_creature_from_battlefield(
            active,
            permanent,
            reason="test_destroy",
            source={"name": "Fixture Removal"},
        )

        self.assertEqual(destination, "graveyard")
        self.assertEqual([card["name"] for card in active.hand], ["Draw A", "Draw B"])
        self.assertEqual([card["name"] for card in active.library], ["Draw C"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Scholar"])
        self.assertTrue(
            any(
                event == "dies_draw_resolved"
                and data.get("card") == "Fixture Scholar"
                and data.get("draw_count") == 2
                and data.get("cards_drawn") == ["Draw A", "Draw B"]
                and data.get("source") == "Fixture Removal"
                for event, data in self.events
            )
        )

    def test_creature_etb_graveyard_recursion_returns_matching_card_only(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {"name": "Fixture Elementalist", "type_line": "Creature - Human Shaman"}
        active.battlefield.append(permanent)
        target = {"name": "Target Bolt", "type_line": "Instant", "cmc": 1}
        non_target = {"name": "Target Bear", "type_line": "Creature - Bear", "cmc": 2}
        active.graveyard.extend([non_target, target])
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_return_graveyard_card_to_hand_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_target": "instant_or_sorcery",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "hand",
            "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["instant", "sorcery"]},
        }

        self.battle.resolve_generic_permanent_etb(
            active,
            [opponent],
            permanent,
            effect,
            turn=9,
            rng=random.Random(9),
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Bolt"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Target Bear"])
        self.assertEqual([card["name"] for card in active.battlefield], ["Fixture Elementalist"])
        self.assertTrue(
            any(
                event == "etb_recursion_resolved"
                and data.get("card") == "Fixture Elementalist"
                and data.get("recovered") == ["Target Bolt"]
                and data.get("target_type") == "instant_or_sorcery"
                and data.get("destination") == "hand"
                for event, data in self.events
            )
        )

    def test_creature_etb_graveyard_recursion_returns_spirit_instant_or_sorcery(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {"name": "Returned Pastcaller", "type_line": "Creature - Spirit Cleric"}
        active.battlefield.append(permanent)
        non_target = {"name": "Target Relic", "type_line": "Artifact", "cmc": 2}
        target = {"name": "Target Spirit", "type_line": "Creature - Spirit", "cmc": 3}
        active.graveyard.extend([non_target, target])
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_return_graveyard_card_to_hand_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_target": "spirit_instant_or_sorcery",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "hand",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "any_of": [
                    {"subtypes": ["spirit"]},
                    {"card_types": ["instant"]},
                    {"card_types": ["sorcery"]},
                ],
            },
        }

        self.battle.resolve_generic_permanent_etb(
            active,
            [opponent],
            permanent,
            effect,
            turn=9,
            rng=random.Random(9),
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Spirit"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Target Relic"])
        self.assertTrue(
            any(
                event == "etb_recursion_resolved"
                and data.get("card") == "Returned Pastcaller"
                and data.get("recovered") == ["Target Spirit"]
                and data.get("target_type") == "spirit_instant_or_sorcery"
                and data.get("destination") == "hand"
                for event, data in self.events
            )
        )

    def test_creature_etb_graveyard_recursion_returns_lands(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {"name": "Fixture Treefolk", "type_line": "Creature - Treefolk Druid"}
        active.battlefield.append(permanent)
        active.graveyard.extend(
            [
                {"name": "Target Plains", "type_line": "Basic Land - Plains", "cmc": 0},
                {"name": "Target Mountain", "type_line": "Basic Land - Mountain", "cmc": 0},
                {"name": "Target Bear", "type_line": "Creature - Bear", "cmc": 2},
            ]
        )
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_return_graveyard_card_to_hand_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_target": "land",
            "etb_recursion_count": 2,
            "etb_recursion_destination": "hand",
            "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["land"]},
        }

        self.battle.resolve_generic_permanent_etb(
            active,
            [opponent],
            permanent,
            effect,
            turn=10,
            rng=random.Random(10),
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Plains", "Target Mountain"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Target Bear"])
        self.assertTrue(
            any(
                event == "etb_recursion_resolved"
                and data.get("card") == "Fixture Treefolk"
                and data.get("recovered") == ["Target Plains", "Target Mountain"]
                and data.get("target_type") == "land"
                for event, data in self.events
            )
        )

    def test_creature_etb_mill_then_return_can_return_freshly_milled_land(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Fresh Plains", "type_line": "Basic Land - Plains", "cmc": 0},
                {"name": "Fresh Bear", "type_line": "Creature - Bear", "cmc": 2},
                {"name": "Fresh Spell", "type_line": "Sorcery", "cmc": 3},
            ],
        )
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {"name": "Eccentric Farmer", "type_line": "Creature - Human Peasant"}
        active.battlefield.append(permanent)
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_mill_count": 3,
            "etb_recursion_target": "land",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "hand",
            "etb_recursion_up_to_count": True,
            "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["land"]},
        }

        self.battle.resolve_generic_permanent_etb(
            active,
            [opponent],
            permanent,
            effect,
            turn=10,
            rng=random.Random(10),
        )

        self.assertEqual([card["name"] for card in active.hand], ["Fresh Plains"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fresh Bear", "Fresh Spell"])
        self.assertEqual([card["name"] for card in active.battlefield], ["Eccentric Farmer"])
        self.assertTrue(
            any(
                event == "etb_recursion_resolved"
                and data.get("card") == "Eccentric Farmer"
                and data.get("cards_milled") == 3
                and data.get("recovered") == ["Fresh Plains"]
                for event, data in self.events
            )
        )

    def test_creature_etb_mill_then_return_can_return_freshly_milled_permanent(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [
                {"name": "Fresh Relic", "type_line": "Artifact", "cmc": 2},
                {"name": "Fresh Bolt", "type_line": "Instant", "cmc": 1},
            ],
        )
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {"name": "Acolyte of Affliction", "type_line": "Creature - Human Cleric"}
        active.battlefield.append(permanent)
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_mill_count": 2,
            "etb_recursion_target": "permanent",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "hand",
            "etb_recursion_up_to_count": True,
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["artifact", "creature", "enchantment", "planeswalker", "battle", "land"],
            },
        }

        self.battle.resolve_generic_permanent_etb(
            active,
            [opponent],
            permanent,
            effect,
            turn=10,
            rng=random.Random(10),
        )

        self.assertEqual([card["name"] for card in active.hand], ["Fresh Relic"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fresh Bolt"])
        self.assertEqual([card["name"] for card in active.battlefield], ["Acolyte of Affliction"])

    def test_creature_etb_graveyard_recursion_returns_subtype_card(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {"name": "Barrow Witches", "type_line": "Creature - Human Warlock"}
        active.battlefield.append(permanent)
        active.graveyard.extend(
            [
                {"name": "Target Soldier", "type_line": "Creature - Human Soldier", "cmc": 2},
                {"name": "Target Knight", "type_line": "Creature - Human Knight", "cmc": 3},
            ]
        )
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_return_graveyard_card_to_hand_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_target": "knight_card",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "hand",
            "target_constraints": {"zone": "graveyard", "controller": "self", "subtypes": ["knight"]},
        }

        self.battle.resolve_generic_permanent_etb(
            active,
            [opponent],
            permanent,
            effect,
            turn=11,
            rng=random.Random(11),
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Knight"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Target Soldier"])

    def test_creature_etb_graveyard_recursion_respects_artifact_mana_value_limit(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {"name": "Leonin Squire", "type_line": "Creature - Cat Soldier"}
        active.battlefield.append(permanent)
        active.graveyard.extend(
            [
                {"name": "Large Relic", "type_line": "Artifact", "cmc": 2},
                {"name": "Small Relic", "type_line": "Artifact", "cmc": 1},
            ]
        )
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_return_graveyard_card_to_hand_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_target": "artifact",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "hand",
            "etb_recursion_mana_value_max": 1,
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["artifact"],
                "mana_value_max": 1,
            },
        }

        self.battle.resolve_generic_permanent_etb(
            active,
            [opponent],
            permanent,
            effect,
            turn=12,
            rng=random.Random(12),
        )

        self.assertEqual([card["name"] for card in active.hand], ["Small Relic"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Large Relic"])

    def test_creature_etb_graveyard_recursion_returns_food_or_creature(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {"name": "Ragamuffin Raptor", "type_line": "Creature - Dinosaur"}
        active.battlefield.append(permanent)
        active.graveyard.extend(
            [
                {"name": "Target Food", "type_line": "Artifact - Food", "cmc": 1},
                {"name": "Target Spell", "type_line": "Instant", "cmc": 1},
            ]
        )
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_return_graveyard_card_to_hand_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_target": "creature_or_food",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "hand",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "any_of": [{"card_types": ["creature"]}, {"subtypes": ["food"]}],
            },
        }

        self.battle.resolve_generic_permanent_etb(
            active,
            [opponent],
            permanent,
            effect,
            turn=13,
            rng=random.Random(13),
        )

        self.assertEqual([card["name"] for card in active.hand], ["Target Food"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Target Spell"])

    def test_creature_etb_graveyard_to_library_puts_matching_card_on_top(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {"name": "Dukhara Scavenger", "type_line": "Creature - Crocodile"}
        active.battlefield.append(permanent)
        active.library = [{"name": "Existing Top", "type_line": "Sorcery", "cmc": 2}]
        active.graveyard.extend(
            [
                {"name": "Target Spark", "type_line": "Instant", "cmc": 1},
                {"name": "Target Relic", "type_line": "Artifact", "cmc": 2},
            ]
        )
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_put_graveyard_card_on_library_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_target": "artifact_or_creature",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "library_top",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["artifact", "creature"],
            },
        }

        self.battle.resolve_generic_permanent_etb(
            active,
            [opponent],
            permanent,
            effect,
            turn=14,
            rng=random.Random(14),
        )

        self.assertEqual([card["name"] for card in active.library], ["Target Relic", "Existing Top"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Target Spark"])
        self.assertEqual(active.hand, [])
        self.assertTrue(
            any(
                event == "etb_recursion_resolved"
                and data.get("card") == "Dukhara Scavenger"
                and data.get("recovered") == ["Target Relic"]
                and data.get("target_type") == "artifact_or_creature"
                and data.get("destination") == "library_top"
                for event, data in self.events
            )
        )

    def test_creature_etb_graveyard_to_library_can_put_card_on_bottom(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {"name": "Fixture Archivist", "type_line": "Creature - Wizard"}
        active.battlefield.append(permanent)
        active.library = [{"name": "Existing Top", "type_line": "Sorcery", "cmc": 2}]
        active.graveyard.append({"name": "Bottom Target", "type_line": "Instant", "cmc": 1})
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_put_graveyard_card_on_library_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_target": "instant_or_sorcery",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "library_bottom",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "self",
                "card_types": ["instant", "sorcery"],
            },
        }

        self.battle.resolve_generic_permanent_etb(
            active,
            [opponent],
            permanent,
            effect,
            turn=15,
            rng=random.Random(15),
        )

        self.assertEqual([card["name"] for card in active.library], ["Existing Top", "Bottom Target"])
        self.assertEqual(active.graveyard, [])
        self.assertEqual(active.hand, [])

    def test_creature_etb_graveyard_to_library_owner_library_can_target_opponent_graveyard(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        permanent = {"name": "Nantuko Tracer", "type_line": "Creature - Insect Druid"}
        active.battlefield.append(permanent)
        opponent.library = [{"name": "Opponent Existing Top", "type_line": "Land"}]
        opponent.graveyard.append({"name": "Opponent Bomb", "type_line": "Creature - Dragon", "cmc": 7})
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_put_graveyard_card_on_library_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "etb_recursion_target": "any_card",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "library_bottom",
            "target_graveyard_controller": "any",
            "target_controller": "any",
            "library_controller": "owner",
            "target_constraints": {
                "zone": "graveyard",
                "controller": "any",
                "scope": "any_card",
            },
        }

        self.battle.resolve_generic_permanent_etb(
            active,
            [opponent],
            permanent,
            effect,
            turn=16,
            rng=random.Random(16),
        )

        self.assertEqual(opponent.graveyard, [])
        self.assertEqual([card["name"] for card in opponent.library], ["Opponent Existing Top", "Opponent Bomb"])
        self.assertEqual(active.graveyard, [])
        self.assertEqual(active.library, [])
        self.assertTrue(
            any(
                event == "etb_recursion_resolved"
                and data.get("card") == "Nantuko Tracer"
                and data.get("recovered") == ["Opponent Bomb"]
                and data.get("target_graveyard_controller") == "any"
                and data.get("library_controller") == "owner"
                and data.get("target_owners") == ["Opponent"]
                and data.get("library_owners") == ["Opponent"]
                for event, data in self.events
            )
        )

    def test_add_plus_one_counter_spell_buffs_own_best_creature(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        small = {"name": "Small Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        best = {"name": "Best Bear", "type_line": "Creature - Bear", "power": 4, "toughness": 4}
        enemy = {"name": "Enemy Bear", "type_line": "Creature - Bear", "power": 5, "toughness": 5}
        active.battlefield.extend([small, best])
        opponent.battlefield.append(enemy)
        effect = {
            "effect": "add_counters",
            "battle_model_scope": "xmage_fixed_add_counters_target_creature_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_controller": "any",
            "counter_type": "+1/+1",
            "counter_count": 1,
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Battlegrowth",
                "type_line": "Instant",
                "oracle_text": "Put a +1/+1 counter on target creature.",
            },
            turn=9,
            rng=random.Random(9),
            effect_data_override=effect,
        )

        self.assertEqual(best["plus_one_counters"], 1)
        self.assertEqual(best["power"], 5)
        self.assertEqual(best["toughness"], 5)
        self.assertNotIn("plus_one_counters", small)
        self.assertNotIn("plus_one_counters", enemy)
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Battlegrowth"])
        self.assertTrue(
            any(
                event == "add_counters_resolved"
                and data.get("card") == "Fixture Battlegrowth"
                and data.get("target") == "Best Bear"
                and data.get("counter_type") == "+1/+1"
                and data.get("counters_added") == 1
                and data.get("result") == "counters_added"
                for event, data in self.events
            )
        )

    def test_add_minus_one_counters_spell_can_put_zero_toughness_creature_in_graveyard(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Enemy Bear", "type_line": "Creature - Bear", "power": 3, "toughness": 3}
        own = {"name": "Own Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        active.battlefield.append(own)
        opponent.battlefield.append(target)
        effect = {
            "effect": "add_counters",
            "battle_model_scope": "xmage_fixed_add_counters_target_creature_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_controller": "any",
            "counter_type": "-1/-1",
            "counter_count": 4,
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Blight Rot",
                "type_line": "Instant",
                "oracle_text": "Put four -1/-1 counters on target creature.",
            },
            turn=10,
            rng=random.Random(10),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Enemy Bear"])
        self.assertEqual(active.battlefield, [own])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Blight Rot"])
        self.assertTrue(
            any(
                event == "add_counters_resolved"
                and data.get("card") == "Fixture Blight Rot"
                and data.get("target") == "Enemy Bear"
                and data.get("counter_type") == "-1/-1"
                and data.get("counters_added") == 4
                and data.get("result") == "creature_put_into_graveyard_zero_toughness"
                and data.get("destination") == "graveyard"
                for event, data in self.events
            )
        )

    def test_creature_etb_add_plus_one_counter_buffs_own_best_creature_without_graveyarding_source(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        best = {"name": "Best Bear", "type_line": "Creature - Bear", "power": 4, "toughness": 4}
        enemy = {"name": "Enemy Bear", "type_line": "Creature - Bear", "power": 5, "toughness": 5}
        active.battlefield.append(best)
        opponent.battlefield.append(enemy)
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_add_counters_target_creature_v1",
            "etb_add_counters_target": "creature",
            "etb_add_counters_counter_type": "+1/+1",
            "etb_add_counters_count": 1,
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_controller": "any",
            "counter_type": "+1/+1",
            "counter_count": 1,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Bond Beetle",
                "type_line": "Creature - Insect",
                "oracle_text": (
                    "When Fixture Bond Beetle enters the battlefield, put a +1/+1 counter on target creature."
                ),
                "power": 0,
                "toughness": 1,
            },
            turn=11,
            rng=random.Random(11),
            effect_data_override=effect,
        )

        self.assertEqual(best["plus_one_counters"], 1)
        self.assertEqual(best["power"], 5)
        self.assertEqual(best["toughness"], 5)
        self.assertNotIn("plus_one_counters", enemy)
        self.assertEqual([card["name"] for card in active.graveyard], [])
        self.assertIn("Fixture Bond Beetle", [card["name"] for card in active.battlefield])
        self.assertTrue(
            any(
                event == "trigger_resolved"
                and data.get("card") == "Fixture Bond Beetle"
                and data.get("trigger") == "enters_battlefield"
                and data.get("effect") == "add_counters"
                and data.get("target") == "Best Bear"
                and data.get("counter_type") == "+1/+1"
                and data.get("counters_added") == 1
                for event, data in self.events
            )
        )

    def test_creature_etb_minus_one_counter_can_kill_opponent_creature_without_graveyarding_source(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Enemy Cub", "type_line": "Creature - Bear", "power": 1, "toughness": 1}
        own = {"name": "Own Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        active.battlefield.append(own)
        opponent.battlefield.append(target)
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_add_counters_target_creature_v1",
            "etb_add_counters_target": "creature",
            "etb_add_counters_counter_type": "-1/-1",
            "etb_add_counters_count": 1,
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_controller": "any",
            "counter_type": "-1/-1",
            "counter_count": 1,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Pith Driller",
                "type_line": "Artifact Creature - Phyrexian Horror",
                "oracle_text": (
                    "When Fixture Pith Driller enters the battlefield, put a -1/-1 counter on target creature."
                ),
                "power": 2,
                "toughness": 4,
            },
            turn=12,
            rng=random.Random(12),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Enemy Cub"])
        self.assertIn("Fixture Pith Driller", [card["name"] for card in active.battlefield])
        self.assertEqual([card["name"] for card in active.graveyard], [])
        self.assertTrue(
            any(
                event == "trigger_resolved"
                and data.get("card") == "Fixture Pith Driller"
                and data.get("trigger") == "enters_battlefield"
                and data.get("effect") == "add_counters"
                and data.get("target") == "Enemy Cub"
                and data.get("counter_type") == "-1/-1"
                and data.get("result") == "creature_put_into_graveyard_zero_toughness"
                and data.get("destination") == "graveyard"
                for event, data in self.events
            )
        )

    def test_stat_modifier_until_eot_spell_buffs_own_best_creature_and_cleans_up(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        small = {"name": "Small Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        best = {"name": "Best Bear", "type_line": "Creature - Bear", "power": 4, "toughness": 4}
        enemy = {"name": "Enemy Bear", "type_line": "Creature - Bear", "power": 5, "toughness": 5}
        active.battlefield.extend([small, best])
        opponent.battlefield.append(enemy)
        effect = {
            "effect": "stat_modifier_until_eot",
            "battle_model_scope": "xmage_fixed_boost_target_creature_until_eot_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_controller": "any",
            "power_delta": 3,
            "toughness_delta": 3,
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Giant Growth",
                "type_line": "Instant",
                "oracle_text": "Target creature gets +3/+3 until end of turn.",
            },
            turn=11,
            rng=random.Random(11),
            effect_data_override=effect,
        )

        self.assertEqual(best["power"], 7)
        self.assertEqual(best["toughness"], 7)
        self.assertEqual(small["power"], 2)
        self.assertEqual(enemy["power"], 5)
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Giant Growth"])
        self.assertTrue(
            any(
                event == "stat_modifier_until_eot_resolved"
                and data.get("card") == "Fixture Giant Growth"
                and data.get("target") == "Best Bear"
                and data.get("power_delta") == 3
                and data.get("toughness_delta") == 3
                and data.get("result") == "stat_modifier_until_eot_applied"
                for event, data in self.events
            )
        )

        self.battle.clear_until_eot(active)
        self.assertEqual(best["power"], 4)
        self.assertEqual(best["toughness"], 4)

    def test_stat_modifier_until_eot_spell_grants_keyword_and_cleans_up(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {
            "name": "Ground Bear",
            "type_line": "Creature - Bear",
            "power": 2,
            "toughness": 2,
            "keywords": ["vigilance"],
            "vigilance": True,
        }
        active.battlefield.append(target)
        effect = {
            "effect": "stat_modifier_until_eot",
            "battle_model_scope": "xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_controller": "self",
            "power_delta": 2,
            "toughness_delta": 2,
            "granted_keywords_until_eot": ["flying"],
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Wings",
                "type_line": "Instant",
                "oracle_text": "Target creature you control gets +2/+2 and gains flying until end of turn.",
            },
            turn=12,
            rng=random.Random(12),
            effect_data_override=effect,
        )

        self.assertEqual(target["power"], 4)
        self.assertEqual(target["toughness"], 4)
        self.assertTrue(target["flying"])
        self.assertEqual(target["keywords"], ["vigilance", "flying"])
        self.assertTrue(
            any(
                event == "stat_modifier_until_eot_resolved"
                and data.get("card") == "Fixture Wings"
                and data.get("target") == "Ground Bear"
                and data.get("granted_keywords_until_eot") == ["flying"]
                and data.get("result") == "stat_modifier_until_eot_applied"
                for event, data in self.events
            )
        )

        self.battle.clear_until_eot(active)
        self.assertEqual(target["power"], 2)
        self.assertEqual(target["toughness"], 2)
        self.assertEqual(target["keywords"], ["vigilance"])
        self.assertNotIn("flying", target)

    def test_stat_modifier_until_eot_spell_can_kill_opponent_creature(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Enemy Bear", "type_line": "Creature - Bear", "power": 3, "toughness": 3}
        own = {"name": "Own Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        active.battlefield.append(own)
        opponent.battlefield.append(target)
        effect = {
            "effect": "stat_modifier_until_eot",
            "battle_model_scope": "xmage_fixed_boost_target_creature_until_eot_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_controller": "any",
            "power_delta": -4,
            "toughness_delta": -4,
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Grasp of Darkness",
                "type_line": "Instant",
                "oracle_text": "Target creature gets -4/-4 until end of turn.",
            },
            turn=12,
            rng=random.Random(12),
            effect_data_override=effect,
        )

        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Enemy Bear"])
        self.assertEqual(active.battlefield, [own])
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Grasp of Darkness"])
        self.assertTrue(
            any(
                event == "stat_modifier_until_eot_resolved"
                and data.get("card") == "Fixture Grasp of Darkness"
                and data.get("target") == "Enemy Bear"
                and data.get("power_delta") == -4
                and data.get("toughness_delta") == -4
                and data.get("result") == "creature_put_into_graveyard_zero_toughness"
                and data.get("destination") == "graveyard"
                for event, data in self.events
            )
        )

    def test_controlled_stat_modifier_until_eot_spell_buffs_only_own_creatures_and_cleans_up(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        small = {"name": "Small Bear", "type_line": "Creature - Bear", "power": 2, "toughness": 2}
        best = {"name": "Best Bear", "type_line": "Creature - Bear", "power": 4, "toughness": 4}
        enemy = {"name": "Enemy Bear", "type_line": "Creature - Bear", "power": 5, "toughness": 5}
        active.battlefield.extend([small, best])
        opponent.battlefield.append(enemy)
        effect = {
            "effect": "controlled_stat_modifier_until_eot",
            "battle_model_scope": "xmage_fixed_boost_controlled_creatures_until_eot_spell_v1",
            "target": "controlled_creatures",
            "target_controller": "self",
            "target_constraints": {"controller": "self", "card_types": ["creature"]},
            "power_delta": 2,
            "toughness_delta": 0,
            "instant": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Burn Bright",
                "type_line": "Instant",
                "oracle_text": "Creatures you control get +2/+0 until end of turn.",
            },
            turn=13,
            rng=random.Random(13),
            effect_data_override=effect,
        )

        self.assertEqual(small["power"], 4)
        self.assertEqual(small["toughness"], 2)
        self.assertEqual(best["power"], 6)
        self.assertEqual(best["toughness"], 4)
        self.assertEqual(enemy["power"], 5)
        self.assertEqual(enemy["toughness"], 5)
        self.assertEqual([card["name"] for card in active.graveyard], ["Fixture Burn Bright"])
        self.assertTrue(
            any(
                event == "controlled_stat_modifier_until_eot_resolved"
                and data.get("card") == "Fixture Burn Bright"
                and data.get("affected_count") == 2
                and data.get("power_delta") == 2
                and data.get("result") == "stat_modifier_until_eot_applied"
                for event, data in self.events
            )
        )

        self.battle.clear_until_eot(active)
        self.assertEqual(small["power"], 2)
        self.assertEqual(small["toughness"], 2)
        self.assertEqual(best["power"], 4)
        self.assertEqual(best["toughness"], 4)

    def test_static_combat_keyword_creature_effect_enriches_permanent_keywords(self) -> None:
        card = {
            "name": "Fixture Keyword Creature",
            "type_line": "Creature - Bird",
            "oracle_text": "Flying, vigilance, haste",
            "power": 2,
            "toughness": 2,
        }
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_static_self_combat_keyword_creature_v1",
            "keywords": ["flying", "vigilance", "haste"],
            "_keywords_are_self": True,
            "flying": True,
            "vigilance": True,
            "haste": True,
        }

        permanent = self.battle.enrich_card({**card, **effect})
        permanent["effect"] = "creature"
        permanent["haste"] = self.battle.has_haste(permanent)
        permanent["summoning_sick"] = not permanent["haste"]

        self.assertTrue(permanent["flying"])
        self.assertTrue(self.battle.has_vigilance(permanent))
        self.assertTrue(permanent["haste"])
        self.assertFalse(permanent["summoning_sick"])

    def test_static_self_keyword_creature_runtime_enforces_hexproof_shroud_indestructible(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        card = {
            "name": "Fixture Protected Creature",
            "type_line": "Artifact Creature - Construct",
            "oracle_text": "Hexproof\nShroud\nIndestructible",
            "controller": "Active",
            "power": 2,
            "toughness": 2,
        }
        effect = {
            "effect": "creature",
            "battle_model_scope": "xmage_static_self_combat_keyword_creature_v1",
            "keywords": ["hexproof", "shroud", "indestructible"],
            "_keywords_are_self": True,
        }

        permanent = self.battle.enrich_card({**card, **effect})

        self.assertTrue(permanent["hexproof"])
        self.assertTrue(permanent["shroud"])
        self.assertTrue(permanent["indestructible"])
        self.assertFalse(self.battle.is_legal_target({"name": "Enemy Spell"}, permanent, opponent))
        self.assertFalse(self.battle.is_legal_target({"name": "Own Spell"}, permanent, active))

        permanent_without_shroud = dict(permanent)
        permanent_without_shroud["shroud"] = False
        self.assertFalse(self.battle.is_legal_target({"name": "Enemy Spell"}, permanent_without_shroud, opponent))
        self.assertTrue(self.battle.is_legal_target({"name": "Own Spell"}, permanent_without_shroud, active))

    def test_destroy_all_enchantments_board_wipe_resolves_by_type(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.battlefield.append({"name": "Own Aura", "type_line": "Enchantment"})
        opponent.battlefield.extend(
            [
                {"name": "Target Oath", "type_line": "Enchantment"},
                {"name": "Target Bear", "type_line": "Creature - Bear", "toughness": 2},
            ]
        )
        effect = {
            "effect": "board_wipe",
            "battle_model_scope": "xmage_destroy_all_matching_permanents_spell_v1",
            "destroy_card_types": ["enchantment"],
            "destination": "graveyard",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Tranquility", "type_line": "Sorcery", "oracle_text": "Destroy all enchantments."},
            turn=9,
            rng=random.Random(9),
            effect_data_override=effect,
        )

        self.assertEqual(active.battlefield, [])
        self.assertEqual([card["name"] for card in active.graveyard], ["Own Aura", "Fixture Tranquility"])
        self.assertEqual([card["name"] for card in opponent.battlefield], ["Target Bear"])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Target Oath"])
        self.assertTrue(
            any(
                event == "board_wipe_resolved"
                and data.get("card") == "Fixture Tranquility"
                and data.get("destroy_card_types") == ["enchantment"]
                and data.get("enchantments_destroyed") == 2
                for event, data in self.events
            )
        )

    def test_fixed_damage_wipe_opponent_creatures_scope(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        own_creature = {"name": "Own Bear", "type_line": "Creature - Bear", "toughness": 1}
        target_creature = {"name": "Target Goblin", "type_line": "Creature - Goblin", "toughness": 1}
        active.battlefield.append(own_creature)
        opponent.battlefield.append(target_creature)
        effect = {
            "effect": "damage_wipe",
            "battle_model_scope": "xmage_fixed_damage_all_matching_permanents_spell_v1",
            "amount": 1,
            "damage": 1,
            "damage_scope": "each_creature_opponents_control",
            "sorcery": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {
                "name": "Fixture Volley",
                "type_line": "Sorcery",
                "oracle_text": "Fixture Volley deals 1 damage to each creature your opponents control.",
            },
            turn=10,
            rng=random.Random(10),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Own Bear"])
        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Target Goblin"])
        self.assertTrue(
            any(
                event == "damage_wipe_resolved"
                and data.get("card") == "Fixture Volley"
                and data.get("damage") == 1
                and data.get("damage_scope") == "each_creature_opponents_control"
                and data.get("opponent_creatures_destroyed") == 1
                for event, data in self.events
            )
        )

    def test_simple_activated_recursion_permanent_pays_colored_taps_and_returns_matching_card(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("black", 1)
        active.mana_pool.add("red", 1)
        active.mana_pool.add("green", 1)
        target = {"name": "Target Bear", "type_line": "Creature - Bear", "cmc": 2}
        non_target = {"name": "Target Bolt", "type_line": "Instant", "cmc": 1}
        active.graveyard.extend([non_target, target])
        permanent = {
            "name": "Adun Oakenshield",
            "type_line": "Legendary Creature - Human Knight",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_hand_v1",
            "activated_effect": "recursion",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_hand_v1",
            "graveyard_to_hand_target": "creature",
            "graveyard_to_hand_target_count": 1,
            "graveyard_to_hand_destination": "hand",
            "graveyard_to_hand_activation_cost_mana": "{B}{R}{G}",
            "graveyard_to_hand_activation_cost_generic": 0,
            "graveyard_to_hand_activation_cost_colors": ["B", "R", "G"],
            "graveyard_to_hand_activation_requires_tap": True,
            "graveyard_to_hand_activation_requires_sacrifice": False,
            "summoning_sick": False,
            "_rule_logical_key": "battle_rule_v1:fixture_adun",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=11,
            rng=random.Random(11),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertTrue(permanent.get("tapped"))
        self.assertIn(permanent, active.battlefield)
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual([card["name"] for card in active.hand], ["Target Bear"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Target Bolt"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Adun Oakenshield"
                and data.get("activation_kind") == "simple_activated_graveyard_to_hand"
                and data.get("activation_cost") == "{B}{R}{G}"
                and data.get("mana_paid") == 3
                and data.get("recovered") == ["Target Bear"]
                for event, data in self.events
            )
        )

    def test_simple_activated_recursion_permanent_pays_discard_creature_cost(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("black", 1)
        target = {"name": "Returned Bear", "type_line": "Creature - Bear", "cmc": 2}
        active.graveyard.append(target)
        keep_spell = {"name": "Valuable Spell", "type_line": "Sorcery", "cmc": 4}
        discard_creature = {"name": "Spare Zombie", "type_line": "Creature - Zombie", "cmc": 1}
        active.hand.extend([keep_spell, discard_creature])
        permanent = {
            "name": "Tortured Existence",
            "type_line": "Enchantment",
            "effect": "enchantment",
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_hand_v1",
            "activated_effect": "recursion",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_hand_v1",
            "graveyard_to_hand_target": "creature",
            "graveyard_to_hand_target_count": 1,
            "graveyard_to_hand_destination": "hand",
            "graveyard_to_hand_activation_cost_mana": "{B}",
            "graveyard_to_hand_activation_cost_generic": 0,
            "graveyard_to_hand_activation_cost_colors": ["B"],
            "graveyard_to_hand_activation_requires_tap": False,
            "graveyard_to_hand_activation_requires_sacrifice": False,
            "graveyard_to_hand_activation_discard_count": 1,
            "graveyard_to_hand_activation_discard_target": "creature_card",
            "activation_discard_count": 1,
            "activation_discard_target": "creature_card",
            "_rule_logical_key": "battle_rule_v1:fixture_tortured_existence",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=12,
            rng=random.Random(12),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertIn(permanent, active.battlefield)
        self.assertEqual([card["name"] for card in active.hand], ["Valuable Spell", "Returned Bear"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Spare Zombie"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Tortured Existence"
                and data.get("activation_kind") == "simple_activated_graveyard_to_hand"
                and data.get("activation_cost") == "{B}"
                and data.get("recovered") == ["Returned Bear"]
                and data.get("discarded") == ["Spare Zombie"]
                and data.get("discarded_count") == 1
                and data.get("discard_target") == "creature_card"
                and data.get("mana_paid") == 1
                for event, data in self.events
            )
        )

    def test_simple_activated_recursion_permanent_does_not_pay_when_discard_creature_cost_unavailable(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("black", 1)
        target = {"name": "Returned Bear", "type_line": "Creature - Bear", "cmc": 2}
        active.graveyard.append(target)
        only_spell = {"name": "Only Spell", "type_line": "Instant", "cmc": 1}
        active.hand.append(only_spell)
        permanent = {
            "name": "Tortured Existence",
            "type_line": "Enchantment",
            "effect": "enchantment",
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_hand_v1",
            "graveyard_to_hand_target": "creature",
            "graveyard_to_hand_target_count": 1,
            "graveyard_to_hand_destination": "hand",
            "graveyard_to_hand_activation_cost_mana": "{B}",
            "graveyard_to_hand_activation_cost_generic": 0,
            "graveyard_to_hand_activation_cost_colors": ["B"],
            "graveyard_to_hand_activation_requires_tap": False,
            "graveyard_to_hand_activation_requires_sacrifice": False,
            "graveyard_to_hand_activation_discard_count": 1,
            "graveyard_to_hand_activation_discard_target": "creature_card",
            "activation_discard_count": 1,
            "activation_discard_target": "creature_card",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=13,
            rng=random.Random(13),
            phase="precombat_main",
        )

        self.assertEqual(activated, 0)
        self.assertEqual(active.available_mana(), 1)
        self.assertEqual(active.hand, [only_spell])
        self.assertEqual(active.graveyard, [target])
        self.assertFalse(any(event == "recursion_resolved" for event, _ in self.events))

    def test_simple_activated_recursion_permanent_pays_life_cost(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(1)
        active.mana_pool.add("black", 1)
        active.life = 20
        target = {"name": "Returned Bear", "type_line": "Creature - Bear", "cmc": 2}
        active.graveyard.append(target)
        permanent = {
            "name": "Phyrexian Reclamation",
            "type_line": "Enchantment",
            "effect": "enchantment",
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_hand_v1",
            "activated_effect": "recursion",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_hand_v1",
            "graveyard_to_hand_target": "creature",
            "graveyard_to_hand_target_count": 1,
            "graveyard_to_hand_destination": "hand",
            "graveyard_to_hand_activation_cost_mana": "{1}{B}",
            "graveyard_to_hand_activation_cost_generic": 1,
            "graveyard_to_hand_activation_cost_colors": ["B"],
            "graveyard_to_hand_activation_requires_tap": False,
            "graveyard_to_hand_activation_requires_sacrifice": False,
            "graveyard_to_hand_activation_life_cost": 2,
            "activation_life_cost": 2,
            "_rule_logical_key": "battle_rule_v1:fixture_phyrexian_reclamation",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=14,
            rng=random.Random(14),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual(active.life, 18)
        self.assertIn(permanent, active.battlefield)
        self.assertEqual([card["name"] for card in active.hand], ["Returned Bear"])
        self.assertEqual(active.graveyard, [])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Phyrexian Reclamation"
                and data.get("life_paid") == 2
                and data.get("life_before") == 20
                and data.get("life_after") == 18
                for event, data in self.events
            )
        )

    def test_simple_activated_recursion_to_battlefield_sacrifices_target_permanent(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("red", 1)
        active.mana_pool.add("white", 1)
        active.mana_pool.add("black", 1)
        target = {
            "name": "Seal of Cleansing",
            "type_line": "Enchantment",
            "effect": "enchantment",
            "cmc": 2,
        }
        active.graveyard.append(target)
        sacrificed = {"name": "Omen of the Sun", "type_line": "Enchantment", "cmc": 3}
        permanent = {
            "name": "Ghen, Arcanum Weaver",
            "type_line": "Legendary Creature - Human Wizard",
            "effect": "creature",
            "power": 2,
            "toughness": 3,
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_battlefield_v1",
            "activated_effect": "recursion",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_battlefield_v1",
            "graveyard_to_hand_target": "enchantment",
            "graveyard_to_hand_target_count": 1,
            "graveyard_to_hand_destination": "battlefield",
            "graveyard_to_hand_activation_cost_mana": "{R}{W}{B}",
            "graveyard_to_hand_activation_cost_generic": 0,
            "graveyard_to_hand_activation_cost_colors": ["R", "W", "B"],
            "graveyard_to_hand_activation_requires_tap": True,
            "graveyard_to_hand_activation_requires_sacrifice": False,
            "graveyard_to_hand_activation_sacrifice_target": "enchantment",
            "graveyard_to_hand_activation_requires_sacrifice_target": True,
            "activation_sacrifice_target": "enchantment",
            "activation_requires_sacrifice_target": True,
            "summoning_sick": False,
            "_rule_logical_key": "battle_rule_v1:fixture_ghen_arcanum_weaver",
        }
        active.battlefield.extend([permanent, sacrificed])

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=17,
            rng=random.Random(17),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertIn(permanent, active.battlefield)
        self.assertNotIn(sacrificed, active.battlefield)
        self.assertIn(sacrificed, active.graveyard)
        self.assertEqual([card["name"] for card in active.battlefield], ["Ghen, Arcanum Weaver", "Seal of Cleansing"])
        self.assertTrue(permanent.get("tapped"))
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Ghen, Arcanum Weaver"
                and data.get("destination") == "battlefield"
                and data.get("sacrifice_target") == "enchantment"
                and data.get("sacrificed_target") == "Omen of the Sun"
                and data.get("returned_to_battlefield") == ["Seal of Cleansing"]
                for event, data in self.events
            )
        )

    def test_simple_activated_recursion_self_sacrifice_selects_target_before_sacrificing_source(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(2)
        active.mana_pool.add("black", 1)
        target = {"name": "Old Bear", "type_line": "Creature - Bear", "cmc": 2}
        active.graveyard.append(target)
        permanent = {
            "name": "Corpse Hauler",
            "type_line": "Creature - Human Rogue",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_hand_v1",
            "activated_effect": "recursion",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_hand_v1",
            "graveyard_to_hand_target": "creature",
            "graveyard_to_hand_target_count": 1,
            "graveyard_to_hand_destination": "hand",
            "graveyard_to_hand_activation_cost_mana": "{2}{B}",
            "graveyard_to_hand_activation_cost_generic": 2,
            "graveyard_to_hand_activation_cost_colors": ["B"],
            "graveyard_to_hand_activation_requires_tap": False,
            "graveyard_to_hand_activation_requires_sacrifice": True,
            "summoning_sick": True,
            "_rule_logical_key": "battle_rule_v1:fixture_corpse_hauler",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=12,
            rng=random.Random(12),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertNotIn(permanent, active.battlefield)
        self.assertIn(permanent, active.graveyard)
        self.assertEqual([card["name"] for card in active.hand], ["Old Bear"])
        self.assertNotIn("Corpse Hauler", [card["name"] for card in active.hand])
        self.assertTrue(
            any(
                event == "utility_artifact_activated"
                and data.get("card") == "Corpse Hauler"
                and data.get("activation_kind") == "simple_activated_graveyard_to_hand"
                and data.get("sacrificed_self") is True
                and data.get("mana_paid") == 3
                for event, data in self.events
            )
        )

    def test_simple_activated_recursion_to_battlefield_sacrifices_source_and_returns_target(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("black", 1)
        non_target = {"name": "Discarded Bolt", "type_line": "Instant", "cmc": 1}
        target = {
            "name": "Old Bear",
            "type_line": "Creature - Bear",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "cmc": 2,
        }
        active.graveyard.extend([non_target, target])
        permanent = {
            "name": "Doomed Necromancer",
            "type_line": "Creature - Human Cleric Mercenary",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_battlefield_v1",
            "activated_effect": "recursion",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_battlefield_v1",
            "graveyard_to_hand_target": "creature",
            "graveyard_to_hand_target_count": 1,
            "graveyard_to_hand_destination": "battlefield",
            "graveyard_to_hand_activation_cost_mana": "{B}",
            "graveyard_to_hand_activation_cost_generic": 0,
            "graveyard_to_hand_activation_cost_colors": ["B"],
            "graveyard_to_hand_activation_requires_tap": True,
            "graveyard_to_hand_activation_requires_sacrifice": True,
            "summoning_sick": False,
            "_rule_logical_key": "battle_rule_v1:fixture_doomed_necromancer",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=16,
            rng=random.Random(16),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertNotIn(permanent, active.battlefield)
        self.assertIn(permanent, active.graveyard)
        self.assertEqual(active.hand, [])
        self.assertEqual([card["name"] for card in active.graveyard], ["Discarded Bolt", "Doomed Necromancer"])
        self.assertEqual([card["name"] for card in active.battlefield], ["Old Bear"])
        self.assertTrue(active.battlefield[0].get("summoning_sick"))
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Doomed Necromancer"
                and data.get("activation_kind") == "simple_activated_graveyard_to_battlefield"
                and data.get("destination") == "battlefield"
                and data.get("recovered") == ["Old Bear"]
                and data.get("returned_to_battlefield") == ["Old Bear"]
                and data.get("sacrificed_self") is True
                and data.get("mana_paid") == 1
                for event, data in self.events
            )
        )

    def test_simple_activated_recursion_to_battlefield_activate_as_sorcery_self_sacrifice(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(3)
        active.mana_pool.add("black", 1)
        target = {
            "name": "Old Bear",
            "type_line": "Creature - Bear",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "cmc": 2,
        }
        active.graveyard.append(target)
        permanent = {
            "name": "Bonecaller Cleric",
            "type_line": "Creature - Human Cleric",
            "effect": "creature",
            "power": 2,
            "toughness": 1,
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_battlefield_v1",
            "activated_effect": "recursion",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_battlefield_v1",
            "activation_timing": "sorcery",
            "graveyard_to_hand_target": "creature",
            "graveyard_to_hand_target_count": 1,
            "graveyard_to_hand_destination": "battlefield",
            "graveyard_to_hand_activation_cost_mana": "{3}{B}",
            "graveyard_to_hand_activation_cost_generic": 3,
            "graveyard_to_hand_activation_cost_colors": ["B"],
            "graveyard_to_hand_activation_requires_tap": False,
            "graveyard_to_hand_activation_requires_sacrifice": True,
            "summoning_sick": True,
            "_rule_logical_key": "battle_rule_v1:fixture_bonecaller_cleric",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=17,
            rng=random.Random(17),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertNotIn(permanent, active.battlefield)
        self.assertIn(permanent, active.graveyard)
        self.assertEqual([card["name"] for card in active.graveyard], ["Bonecaller Cleric"])
        self.assertEqual([card["name"] for card in active.battlefield], ["Old Bear"])
        self.assertEqual(active.available_mana(), 0)
        self.assertTrue(
            any(
                event == "utility_artifact_activated"
                and data.get("card") == "Bonecaller Cleric"
                and data.get("activation_kind") == "simple_activated_graveyard_to_battlefield"
                and data.get("sacrificed_self") is True
                and data.get("mana_paid") == 4
                and data.get("returned_to_battlefield") == ["Old Bear"]
                for event, data in self.events
            )
        )

    def test_simple_activated_recursion_blocks_summoning_sick_tap_creature(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("black", 1)
        active.mana_pool.add("red", 1)
        active.mana_pool.add("green", 1)
        target = {"name": "Target Bear", "type_line": "Creature - Bear", "cmc": 2}
        active.graveyard.append(target)
        permanent = {
            "name": "Adun Oakenshield",
            "type_line": "Legendary Creature - Human Knight",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_hand_v1",
            "graveyard_to_hand_target": "creature",
            "graveyard_to_hand_target_count": 1,
            "graveyard_to_hand_destination": "hand",
            "graveyard_to_hand_activation_cost_mana": "{B}{R}{G}",
            "graveyard_to_hand_activation_cost_generic": 0,
            "graveyard_to_hand_activation_cost_colors": ["B", "R", "G"],
            "graveyard_to_hand_activation_requires_tap": True,
            "graveyard_to_hand_activation_requires_sacrifice": False,
            "summoning_sick": True,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=13,
            rng=random.Random(13),
            phase="precombat_main",
        )

        self.assertEqual(activated, 0)
        self.assertFalse(permanent.get("tapped", False))
        self.assertEqual(active.available_mana(), 3)
        self.assertEqual(active.hand, [])
        self.assertEqual([card["name"] for card in active.graveyard], ["Target Bear"])
        self.assertFalse(any(event == "recursion_resolved" for event, _ in self.events))

    def test_simple_activated_recursion_basic_land_target(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(1)
        active.mana_pool.add("green", 1)
        basic = {"name": "Forest", "type_line": "Basic Land - Forest", "cmc": 0, "effect": "land"}
        nonbasic = {"name": "Command Tower", "type_line": "Land", "cmc": 0, "effect": "land"}
        active.graveyard.extend([nonbasic, basic])
        permanent = {
            "name": "Groundskeeper",
            "type_line": "Creature - Human Druid",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_hand_v1",
            "graveyard_to_hand_target": "basic_land",
            "graveyard_to_hand_target_count": 1,
            "graveyard_to_hand_destination": "hand",
            "graveyard_to_hand_activation_cost_mana": "{1}{G}",
            "graveyard_to_hand_activation_cost_generic": 1,
            "graveyard_to_hand_activation_cost_colors": ["G"],
            "graveyard_to_hand_activation_requires_tap": False,
            "graveyard_to_hand_activation_requires_sacrifice": False,
            "summoning_sick": True,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=14,
            rng=random.Random(14),
            phase="postcombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertFalse(permanent.get("tapped", False))
        self.assertIn(permanent, active.battlefield)
        self.assertEqual([card["name"] for card in active.hand], ["Forest"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Command Tower"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("target_type") == "basic_land"
                and data.get("recovered") == ["Forest"]
                for event, data in self.events
            )
        )

    def test_graveyard_self_return_pays_mana_and_moves_source_to_hand(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(2)
        active.mana_pool.add("black", 1)
        source = {
            "name": "Sanitarium Skeleton",
            "type_line": "Creature - Skeleton",
            "cmc": 1,
            "effect": "creature",
            "battle_model_scope": "xmage_graveyard_simple_activated_self_return_to_hand_v1",
            "graveyard_self_return_to_hand": True,
            "graveyard_self_return_destination": "hand",
            "graveyard_self_return_activation_cost_mana": "{2}{B}",
            "graveyard_self_return_activation_cost_generic": 2,
            "graveyard_self_return_activation_cost_colors": ["B"],
            "_rule_logical_key": "battle_rule_v1:fixture_skeleton",
        }
        other = {"name": "Other Graveyard Card", "type_line": "Sorcery", "cmc": 1}
        active.graveyard.extend([other, source])

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=15,
            rng=random.Random(15),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual([card["name"] for card in active.hand], ["Sanitarium Skeleton"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Other Graveyard Card"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Sanitarium Skeleton"
                and data.get("activation_kind") == "graveyard_self_return_to_hand"
                and data.get("activation_cost") == "{2}{B}"
                and data.get("source_zone") == "graveyard"
                and data.get("destination") == "hand"
                and data.get("returned") == ["Sanitarium Skeleton"]
                and data.get("mana_paid") == 3
                for event, data in self.events
            )
        )

    def test_graveyard_self_return_to_hand_pays_discard_creature_cost(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(2)
        active.mana_pool.add("black", 1)
        discard_creature = {"name": "Spare Zombie", "type_line": "Creature - Zombie", "cmc": 2}
        keep_spell = {"name": "Important Spell", "type_line": "Sorcery", "cmc": 4}
        active.hand.extend([keep_spell, discard_creature])
        source = {
            "name": "Kraul Swarm",
            "type_line": "Creature - Insect Warrior",
            "cmc": 5,
            "effect": "creature",
            "battle_model_scope": "xmage_graveyard_simple_activated_self_return_to_hand_v1",
            "graveyard_self_return_to_hand": True,
            "graveyard_self_return_destination": "hand",
            "graveyard_self_return_activation_cost_mana": "{2}{B}",
            "graveyard_self_return_activation_cost_generic": 2,
            "graveyard_self_return_activation_cost_colors": ["B"],
            "graveyard_self_return_activation_discard_count": 1,
            "graveyard_self_return_activation_discard_target": "creature_card",
            "activation_discard_count": 1,
            "activation_discard_target": "creature_card",
            "_rule_logical_key": "battle_rule_v1:fixture_kraul_swarm",
        }
        active.graveyard.append(source)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=16,
            rng=random.Random(16),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual([card["name"] for card in active.hand], ["Important Spell", "Kraul Swarm"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Spare Zombie"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Kraul Swarm"
                and data.get("activation_kind") == "graveyard_self_return_to_hand"
                and data.get("discarded") == ["Spare Zombie"]
                and data.get("discarded_count") == 1
                and data.get("discard_target") == "creature_card"
                and data.get("returned") == ["Kraul Swarm"]
                and data.get("mana_paid") == 3
                for event, data in self.events
            )
        )

    def test_graveyard_self_return_to_hand_does_not_pay_when_discard_creature_cost_unavailable(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(2)
        active.mana_pool.add("black", 1)
        noncreature = {"name": "Only Spell", "type_line": "Instant", "cmc": 1}
        active.hand.append(noncreature)
        source = {
            "name": "Kraul Swarm",
            "type_line": "Creature - Insect Warrior",
            "cmc": 5,
            "effect": "creature",
            "battle_model_scope": "xmage_graveyard_simple_activated_self_return_to_hand_v1",
            "graveyard_self_return_to_hand": True,
            "graveyard_self_return_destination": "hand",
            "graveyard_self_return_activation_cost_mana": "{2}{B}",
            "graveyard_self_return_activation_cost_generic": 2,
            "graveyard_self_return_activation_cost_colors": ["B"],
            "graveyard_self_return_activation_discard_count": 1,
            "graveyard_self_return_activation_discard_target": "creature_card",
            "activation_discard_count": 1,
            "activation_discard_target": "creature_card",
        }
        active.graveyard.append(source)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=17,
            rng=random.Random(17),
            phase="precombat_main",
        )

        self.assertEqual(activated, 0)
        self.assertEqual(active.available_mana(), 3)
        self.assertEqual(active.hand, [noncreature])
        self.assertEqual(active.graveyard, [source])
        self.assertFalse(any(event == "recursion_resolved" for event, _ in self.events))

    def test_simple_activated_graveyard_exile_pays_mana_and_exiles_opponent_card(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(1)
        own_card = {"name": "Own Flashback", "type_line": "Sorcery", "cmc": 2}
        target = {"name": "Opponent Reanimate", "type_line": "Sorcery", "cmc": 1}
        active.graveyard.append(own_card)
        opponent.graveyard.append(target)
        permanent = {
            "name": "Withered Wretch",
            "type_line": "Creature - Zombie Cleric",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_exile_graveyard_card_v1",
            "activated_effect": "graveyard_exile",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_exile_graveyard_card_v1",
            "graveyard_exile_target": "any_card",
            "graveyard_exile_target_count": 1,
            "graveyard_exile_destination": "exile",
            "graveyard_exile_activation_cost_mana": "{1}",
            "graveyard_exile_activation_cost_generic": 1,
            "graveyard_exile_activation_cost_colors": [],
            "graveyard_exile_activation_requires_tap": False,
            "graveyard_exile_activation_requires_sacrifice": False,
            "summoning_sick": True,
            "_rule_logical_key": "battle_rule_v1:fixture_withered_wretch",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=16,
            rng=random.Random(16),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual([card["name"] for card in active.graveyard], ["Own Flashback"])
        self.assertEqual(opponent.graveyard, [])
        self.assertEqual([card["name"] for card in opponent.exile], ["Opponent Reanimate"])
        self.assertTrue(
            any(
                event == "graveyard_exile_activated"
                and data.get("card") == "Withered Wretch"
                and data.get("activation_kind") == "simple_activated_graveyard_exile"
                and data.get("activation_cost") == "{1}"
                and data.get("exiled") == ["Opponent Reanimate"]
                and data.get("target_owners") == ["Opponent"]
                and data.get("mana_paid") == 1
                for event, data in self.events
            )
        )

    def test_graveyard_exile_spell_exiles_multiple_cards_from_single_graveyard(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.graveyard.append({"name": "Own Flashback", "type_line": "Sorcery", "cmc": 5})
        opponent.graveyard.extend(
            [
                {"name": "Opponent Reanimate", "type_line": "Sorcery", "cmc": 4},
                {"name": "Opponent Escape", "type_line": "Creature - Horror", "cmc": 2},
                {"name": "Opponent Small", "type_line": "Creature - Rat", "cmc": 1},
            ]
        )
        effect = {
            "effect": "graveyard_exile",
            "battle_model_scope": "xmage_exile_target_graveyard_card_spell_v1",
            "target": "any_card",
            "target_constraints": {"zone": "graveyard", "controller": "any", "scope": "any_card"},
            "count": 2,
            "destination": "exile",
            "target_controller": "any",
            "graveyard_exile_target": "any_card",
            "graveyard_exile_target_count": 2,
            "graveyard_exile_destination": "exile",
            "graveyard_exile_single_graveyard": True,
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Fixture Graveyard Hate", "type_line": "Instant"},
            turn=17,
            rng=random.Random(17),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.graveyard], ["Own Flashback", "Fixture Graveyard Hate"])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Opponent Small"])
        self.assertEqual([card["name"] for card in opponent.exile], ["Opponent Reanimate", "Opponent Escape"])
        self.assertTrue(
            any(
                event == "graveyard_exile_resolved"
                and data.get("card") == "Fixture Graveyard Hate"
                and data.get("exiled") == ["Opponent Reanimate", "Opponent Escape"]
                and data.get("target_owners") == ["Opponent", "Opponent"]
                and data.get("single_graveyard") is True
                for event, data in self.events
            )
        )

    def test_graveyard_self_return_to_battlefield_pays_mana_and_enters_tapped(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(1)
        active.mana_pool.add("black", 1)
        source = {
            "name": "Reassembling Skeleton",
            "type_line": "Creature - Skeleton Warrior",
            "cmc": 2,
            "effect": "creature",
            "battle_model_scope": "xmage_graveyard_simple_activated_self_return_to_battlefield_v1",
            "graveyard_self_return_to_battlefield": True,
            "graveyard_self_return_destination": "battlefield",
            "graveyard_self_return_activation_cost_mana": "{1}{B}",
            "graveyard_self_return_activation_cost_generic": 1,
            "graveyard_self_return_activation_cost_colors": ["B"],
            "enters_tapped": True,
            "_rule_logical_key": "battle_rule_v1:fixture_reassembling_skeleton",
        }
        active.graveyard.append(source)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=16,
            rng=random.Random(16),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual(active.graveyard, [])
        self.assertEqual([card["name"] for card in active.battlefield], ["Reassembling Skeleton"])
        self.assertTrue(active.battlefield[0].get("tapped"))
        self.assertTrue(active.battlefield[0].get("summoning_sick"))
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Reassembling Skeleton"
                and data.get("activation_kind") == "graveyard_self_return_to_battlefield"
                and data.get("activation_cost") == "{1}{B}"
                and data.get("source_zone") == "graveyard"
                and data.get("destination") == "battlefield"
                and data.get("enters_tapped") is True
                and data.get("returned") == ["Reassembling Skeleton"]
                and data.get("mana_paid") == 2
                for event, data in self.events
            )
        )

    def test_graveyard_self_return_to_battlefield_pays_mana_discards_two_and_enters_tapped(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(2)
        active.mana_pool.add("blue", 1)
        discard_one = {"name": "Spare Plains", "type_line": "Basic Land - Plains", "cmc": 0}
        discard_two = {"name": "Minor Artifact", "type_line": "Artifact", "cmc": 1}
        keep_card = {"name": "Valuable Instant", "type_line": "Instant", "cmc": 3, "effect": "draw_cards"}
        active.hand.extend([keep_card, discard_two, discard_one])
        source = {
            "name": "Advanced Stitchwing",
            "type_line": "Creature - Zombie Horror",
            "cmc": 5,
            "effect": "creature",
            "battle_model_scope": "xmage_graveyard_simple_activated_self_return_to_battlefield_v1",
            "graveyard_self_return_to_battlefield": True,
            "graveyard_self_return_destination": "battlefield",
            "graveyard_self_return_activation_cost_mana": "{2}{U}",
            "graveyard_self_return_activation_cost_generic": 2,
            "graveyard_self_return_activation_cost_colors": ["U"],
            "graveyard_self_return_activation_discard_count": 2,
            "activation_discard_count": 2,
            "activation_discard_target": "any_card",
            "enters_tapped": True,
            "keywords": ["flying"],
            "_rule_logical_key": "battle_rule_v1:fixture_advanced_stitchwing",
        }
        active.graveyard.append(source)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=17,
            rng=random.Random(17),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual([card["name"] for card in active.hand], ["Valuable Instant"])
        self.assertCountEqual(
            [card["name"] for card in active.graveyard],
            ["Spare Plains", "Minor Artifact"],
        )
        self.assertEqual([card["name"] for card in active.battlefield], ["Advanced Stitchwing"])
        self.assertTrue(active.battlefield[0].get("tapped"))
        self.assertTrue(active.battlefield[0].get("summoning_sick"))
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Advanced Stitchwing"
                and data.get("activation_kind") == "graveyard_self_return_to_battlefield"
                and data.get("activation_cost") == "{2}{U}"
                and data.get("destination") == "battlefield"
                and data.get("returned") == ["Advanced Stitchwing"]
                and data.get("discarded_count") == 2
                and set(data.get("discarded") or []) == {"Spare Plains", "Minor Artifact"}
                and set(data.get("discard_to_graveyard") or []) == {"Spare Plains", "Minor Artifact"}
                and data.get("mana_paid") == 3
                for event, data in self.events
            )
        )

    def test_graveyard_self_return_to_battlefield_does_not_pay_when_discard_cost_unavailable(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(2)
        active.mana_pool.add("blue", 1)
        only_card = {"name": "Only Hand Card", "type_line": "Sorcery", "cmc": 2}
        active.hand.append(only_card)
        source = {
            "name": "Stitchwing Skaab",
            "type_line": "Creature - Zombie Horror",
            "cmc": 4,
            "effect": "creature",
            "battle_model_scope": "xmage_graveyard_simple_activated_self_return_to_battlefield_v1",
            "graveyard_self_return_to_battlefield": True,
            "graveyard_self_return_destination": "battlefield",
            "graveyard_self_return_activation_cost_mana": "{1}{U}",
            "graveyard_self_return_activation_cost_generic": 1,
            "graveyard_self_return_activation_cost_colors": ["U"],
            "graveyard_self_return_activation_discard_count": 2,
            "activation_discard_count": 2,
            "activation_discard_target": "any_card",
            "enters_tapped": True,
        }
        active.graveyard.append(source)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=18,
            rng=random.Random(18),
            phase="precombat_main",
        )

        self.assertEqual(activated, 0)
        self.assertEqual(active.available_mana(), 3)
        self.assertEqual(active.hand, [only_card])
        self.assertEqual(active.battlefield, [])
        self.assertEqual(active.graveyard, [source])
        self.assertFalse(any(event == "recursion_resolved" for event, _ in self.events))

    def test_graveyard_self_return_to_battlefield_pays_exile_creature_cost(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(1)
        active.mana_pool.add("black", 1)
        exile_creature = {"name": "Spent Servo", "type_line": "Artifact Creature - Servo", "cmc": 1}
        stay_spell = {"name": "Past Spell", "type_line": "Sorcery", "cmc": 3}
        source = {
            "name": "Scrapheap Scrounger",
            "type_line": "Artifact Creature - Construct",
            "cmc": 2,
            "effect": "creature",
            "battle_model_scope": "xmage_graveyard_simple_activated_self_return_to_battlefield_v1",
            "graveyard_self_return_to_battlefield": True,
            "graveyard_self_return_destination": "battlefield",
            "graveyard_self_return_activation_cost_mana": "{1}{B}",
            "graveyard_self_return_activation_cost_generic": 1,
            "graveyard_self_return_activation_cost_colors": ["B"],
            "graveyard_self_return_activation_exile_from_graveyard_count": 1,
            "graveyard_self_return_activation_exile_from_graveyard_target": "creature_card",
            "graveyard_self_return_activation_exile_from_graveyard_other": True,
            "activation_exile_from_graveyard_count": 1,
            "activation_exile_from_graveyard_target": "creature_card",
            "activation_exile_from_graveyard_other": True,
            "enters_tapped": False,
            "cant_block": True,
            "static_cant_block": True,
            "_rule_logical_key": "battle_rule_v1:fixture_scrapheap_scrounger",
        }
        active.graveyard.extend([stay_spell, exile_creature, source])

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=19,
            rng=random.Random(19),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual([card["name"] for card in active.graveyard], ["Past Spell"])
        self.assertEqual([card["name"] for card in active.exile], ["Spent Servo"])
        self.assertEqual(active.exile[0].get("_exile_reason"), "graveyard_self_return_exile_cost")
        self.assertEqual([card["name"] for card in active.battlefield], ["Scrapheap Scrounger"])
        self.assertFalse(active.battlefield[0].get("tapped"))
        self.assertTrue(active.battlefield[0].get("cant_block"))
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Scrapheap Scrounger"
                and data.get("activation_kind") == "graveyard_self_return_to_battlefield"
                and data.get("activation_cost") == "{1}{B}"
                and data.get("destination") == "battlefield"
                and data.get("enters_tapped") is False
                and data.get("exiled_cost") == ["Spent Servo"]
                and data.get("exiled_cost_count") == 1
                and data.get("exile_cost_target") == "creature_card"
                and data.get("mana_paid") == 2
                for event, data in self.events
            )
        )

    def test_graveyard_self_return_to_battlefield_does_not_pay_when_exile_cost_unavailable(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("black", 2)
        only_creature = {"name": "Only Creature", "type_line": "Creature - Skeleton", "cmc": 2}
        noncreature = {"name": "Spent Spell", "type_line": "Instant", "cmc": 1}
        source = {
            "name": "Despoiler of Souls",
            "type_line": "Creature - Horror",
            "cmc": 2,
            "effect": "creature",
            "battle_model_scope": "xmage_graveyard_simple_activated_self_return_to_battlefield_v1",
            "graveyard_self_return_to_battlefield": True,
            "graveyard_self_return_destination": "battlefield",
            "graveyard_self_return_activation_cost_mana": "{B}{B}",
            "graveyard_self_return_activation_cost_generic": 0,
            "graveyard_self_return_activation_cost_colors": ["B", "B"],
            "graveyard_self_return_activation_exile_from_graveyard_count": 2,
            "graveyard_self_return_activation_exile_from_graveyard_target": "creature_card",
            "graveyard_self_return_activation_exile_from_graveyard_other": True,
            "activation_exile_from_graveyard_count": 2,
            "activation_exile_from_graveyard_target": "creature_card",
            "activation_exile_from_graveyard_other": True,
            "enters_tapped": False,
        }
        active.graveyard.extend([noncreature, only_creature, source])

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=20,
            rng=random.Random(20),
            phase="precombat_main",
        )

        self.assertEqual(activated, 0)
        self.assertEqual(active.available_mana(), 2)
        self.assertEqual(active.exile, [])
        self.assertEqual(active.battlefield, [])
        self.assertEqual(active.graveyard, [noncreature, only_creature, source])
        self.assertFalse(any(event == "recursion_resolved" for event, _ in self.events))

    def test_simple_activated_graveyard_exile_single_graveyard_exiles_multiple_and_sacrifices_source(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(1)
        active.mana_pool.add("black", 1)
        opponent.graveyard.extend(
            [
                {"name": "Opponent Escape", "type_line": "Creature - Zombie", "cmc": 4},
                {"name": "Opponent Flashback", "type_line": "Instant", "cmc": 2},
            ]
        )
        active.graveyard.append({"name": "Own Spell", "type_line": "Sorcery", "cmc": 5})
        permanent = {
            "name": "Famished Ghoul",
            "type_line": "Creature - Zombie",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_exile_graveyard_card_v1",
            "activated_effect": "graveyard_exile",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_exile_graveyard_card_v1",
            "graveyard_exile_target": "any_card",
            "graveyard_exile_target_count": 2,
            "graveyard_exile_destination": "exile",
            "graveyard_exile_single_graveyard": True,
            "graveyard_exile_up_to_count": True,
            "graveyard_exile_activation_cost_mana": "{1}{B}",
            "graveyard_exile_activation_cost_generic": 1,
            "graveyard_exile_activation_cost_colors": ["B"],
            "graveyard_exile_activation_requires_tap": False,
            "graveyard_exile_activation_requires_sacrifice": True,
            "summoning_sick": True,
            "_rule_logical_key": "battle_rule_v1:fixture_famished_ghoul",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=17,
            rng=random.Random(17),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertNotIn(permanent, active.battlefield)
        self.assertIn(permanent, active.graveyard)
        self.assertEqual([card["name"] for card in active.graveyard], ["Own Spell", "Famished Ghoul"])
        self.assertEqual(opponent.graveyard, [])
        self.assertCountEqual(
            [card["name"] for card in opponent.exile],
            ["Opponent Escape", "Opponent Flashback"],
        )
        self.assertTrue(
            any(
                event == "graveyard_exile_activated"
                and data.get("card") == "Famished Ghoul"
                and data.get("sacrificed_self") is True
                and data.get("exiled_count") == 2
                and data.get("target_owners") == ["Opponent", "Opponent"]
                for event, data in self.events
            )
        )

    def test_simple_activated_graveyard_exile_blocks_summoning_sick_tap_creature(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Opponent Bear", "type_line": "Creature - Bear", "cmc": 2}
        opponent.graveyard.append(target)
        permanent = {
            "name": "Thraben Heretic",
            "type_line": "Creature - Human Wizard",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_exile_graveyard_card_v1",
            "activated_effect": "graveyard_exile",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_exile_graveyard_card_v1",
            "graveyard_exile_target": "creature",
            "graveyard_exile_target_count": 1,
            "graveyard_exile_destination": "exile",
            "graveyard_exile_activation_cost_mana": "{0}",
            "graveyard_exile_activation_cost_generic": 0,
            "graveyard_exile_activation_cost_colors": [],
            "graveyard_exile_activation_requires_tap": True,
            "graveyard_exile_activation_requires_sacrifice": False,
            "summoning_sick": True,
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=18,
            rng=random.Random(18),
            phase="precombat_main",
        )

        self.assertEqual(activated, 0)
        self.assertFalse(permanent.get("tapped", False))
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Opponent Bear"])
        self.assertEqual(opponent.exile, [])
        self.assertFalse(any(event == "graveyard_exile_activated" for event, _ in self.events))

    def test_graveyard_self_return_does_not_move_without_mana(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        source = {
            "name": "Durable Coilbug",
            "type_line": "Creature - Insect",
            "cmc": 5,
            "effect": "creature",
            "battle_model_scope": "xmage_graveyard_simple_activated_self_return_to_hand_v1",
            "graveyard_self_return_to_hand": True,
            "graveyard_self_return_activation_cost_mana": "{4}{B}",
            "graveyard_self_return_activation_cost_generic": 4,
            "graveyard_self_return_activation_cost_colors": ["B"],
        }
        active.graveyard.append(source)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=16,
            rng=random.Random(16),
            phase="precombat_main",
        )

        self.assertEqual(activated, 0)
        self.assertEqual(active.hand, [])
        self.assertEqual(active.graveyard, [source])

    def test_graveyard_self_return_to_battlefield_does_not_move_without_mana(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        source = {
            "name": "Persistent Specimen",
            "type_line": "Creature - Skeleton",
            "cmc": 3,
            "effect": "creature",
            "battle_model_scope": "xmage_graveyard_simple_activated_self_return_to_battlefield_v1",
            "graveyard_self_return_to_battlefield": True,
            "graveyard_self_return_destination": "battlefield",
            "graveyard_self_return_activation_cost_mana": "{2}{B}",
            "graveyard_self_return_activation_cost_generic": 2,
            "graveyard_self_return_activation_cost_colors": ["B"],
            "enters_tapped": True,
        }
        active.graveyard.append(source)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=19,
            rng=random.Random(19),
            phase="precombat_main",
        )

        self.assertEqual(activated, 0)
        self.assertEqual(active.hand, [])
        self.assertEqual(active.battlefield, [])
        self.assertEqual(active.graveyard, [source])
        self.assertFalse(any(event == "recursion_resolved" for event, _ in self.events))

    def test_simple_activated_graveyard_to_library_bottom_pays_mana_and_moves_card(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Existing Top", "type_line": "Creature - Human", "cmc": 1}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(2)
        target = {"name": "Graveyard Memory", "type_line": "Sorcery", "cmc": 2}
        active.graveyard.append(target)
        permanent = {
            "name": "Epitaph Golem",
            "type_line": "Artifact Creature - Golem",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_library_v1",
            "activated_effect": "graveyard_to_library",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_library_v1",
            "graveyard_to_library_target": "any_card",
            "graveyard_to_library_target_count": 1,
            "graveyard_to_library_destination": "library_bottom",
            "graveyard_to_library_activation_cost_mana": "{2}",
            "graveyard_to_library_activation_cost_generic": 2,
            "graveyard_to_library_activation_cost_colors": [],
            "graveyard_to_library_activation_requires_tap": False,
            "graveyard_to_library_activation_requires_sacrifice": False,
            "summoning_sick": True,
            "_rule_logical_key": "battle_rule_v1:fixture_epitaph_golem",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=20,
            rng=random.Random(20),
            phase="postcombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual(active.graveyard, [])
        self.assertEqual([card["name"] for card in active.library], ["Existing Top", "Graveyard Memory"])
        self.assertIn(permanent, active.battlefield)
        self.assertTrue(
            any(
                event == "graveyard_to_library_activated"
                and data.get("card") == "Epitaph Golem"
                and data.get("activation_kind") == "simple_activated_graveyard_to_library"
                and data.get("destination") == "library_bottom"
                and data.get("moved") == ["Graveyard Memory"]
                and data.get("mana_paid") == 2
                for event, data in self.events
            )
        )

    def test_simple_activated_graveyard_to_owner_library_can_target_opponent_graveyard(self) -> None:
        active = self.battle.Player("Active", None, [{"name": "Active Top", "type_line": "Land", "cmc": 0}])
        opponent = self.battle.Player(
            "Opponent",
            None,
            [{"name": "Opponent Top", "type_line": "Creature - Human", "cmc": 1}],
        )
        active.mana_pool.add_generic(2)
        target = {"name": "Opponent Flashback Spell", "type_line": "Sorcery", "cmc": 4}
        opponent.graveyard.append(target)
        permanent = {
            "name": "Cogwork Archivist",
            "type_line": "Artifact Creature - Construct",
            "effect": "creature",
            "reach": True,
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_library_v1",
            "activated_effect": "graveyard_to_library",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_library_v1",
            "graveyard_to_library_target": "any_card",
            "graveyard_to_library_target_count": 1,
            "graveyard_to_library_destination": "library_bottom",
            "target_controller": "any",
            "target_graveyard_controller": "any",
            "library_controller": "owner",
            "graveyard_to_library_activation_cost_mana": "{2}",
            "graveyard_to_library_activation_cost_generic": 2,
            "graveyard_to_library_activation_cost_colors": [],
            "graveyard_to_library_activation_requires_tap": True,
            "graveyard_to_library_activation_requires_sacrifice": False,
            "_rule_logical_key": "battle_rule_v1:fixture_cogwork_archivist",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=21,
            rng=random.Random(21),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual(opponent.graveyard, [])
        self.assertEqual([card["name"] for card in opponent.library], ["Opponent Top", "Opponent Flashback Spell"])
        self.assertEqual([card["name"] for card in active.library], ["Active Top"])
        self.assertTrue(permanent["tapped"])
        self.assertTrue(
            any(
                event == "graveyard_to_library_activated"
                and data.get("card") == "Cogwork Archivist"
                and data.get("destination") == "library_bottom"
                and data.get("target_graveyard_controller") == "any"
                and data.get("library_controller") == "owner"
                and data.get("target_owners") == ["Opponent"]
                and data.get("library_owners") == ["Opponent"]
                and data.get("moved") == ["Opponent Flashback Spell"]
                and data.get("mana_paid") == 2
                for event, data in self.events
            )
        )

    def test_simple_activated_graveyard_to_owner_library_supports_zero_mana_tap_cost(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Opponent Escape Card", "type_line": "Instant", "cmc": 3}
        opponent.graveyard.append(target)
        permanent = {
            "name": "Junktroller",
            "type_line": "Artifact Creature - Golem",
            "effect": "creature",
            "defender": True,
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_library_v1",
            "activated_effect": "graveyard_to_library",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_library_v1",
            "graveyard_to_library_target": "any_card",
            "graveyard_to_library_target_count": 1,
            "graveyard_to_library_destination": "library_bottom",
            "target_controller": "any",
            "target_graveyard_controller": "any",
            "library_controller": "owner",
            "graveyard_to_library_activation_cost_mana": "{0}",
            "graveyard_to_library_activation_cost_generic": 0,
            "graveyard_to_library_activation_cost_colors": [],
            "graveyard_to_library_activation_requires_tap": True,
            "_rule_logical_key": "battle_rule_v1:fixture_junktroller",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=22,
            rng=random.Random(22),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual(active.available_mana(), 0)
        self.assertEqual(opponent.graveyard, [])
        self.assertEqual([card["name"] for card in opponent.library], ["Opponent Escape Card"])
        self.assertTrue(permanent["tapped"])
        self.assertTrue(
            any(
                event == "graveyard_to_library_activated"
                and data.get("card") == "Junktroller"
                and data.get("activation_cost") == "{0}"
                and data.get("target_owners") == ["Opponent"]
                and data.get("library_owners") == ["Opponent"]
                for event, data in self.events
            )
        )

    def test_simple_activated_graveyard_to_library_top_filters_creature(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Existing Top", "type_line": "Creature - Human", "cmc": 1}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add("black", 1)
        non_target = {"name": "Graveyard Bolt", "type_line": "Instant", "cmc": 1}
        target = {"name": "Graveyard Bear", "type_line": "Creature - Bear", "cmc": 2}
        active.graveyard.extend([non_target, target])
        permanent = {
            "name": "Haunted Crossroads",
            "type_line": "Enchantment",
            "effect": "enchantment",
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_library_v1",
            "activated_effect": "graveyard_to_library",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_library_v1",
            "graveyard_to_library_target": "creature",
            "graveyard_to_library_target_count": 1,
            "graveyard_to_library_destination": "library_top",
            "graveyard_to_library_activation_cost_mana": "{B}",
            "graveyard_to_library_activation_cost_generic": 0,
            "graveyard_to_library_activation_cost_colors": ["B"],
            "graveyard_to_library_activation_requires_tap": False,
            "graveyard_to_library_activation_requires_sacrifice": False,
            "_rule_logical_key": "battle_rule_v1:fixture_haunted_crossroads",
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=21,
            rng=random.Random(21),
            phase="precombat_main",
        )

        self.assertEqual(activated, 1)
        self.assertEqual([card["name"] for card in active.library[:2]], ["Graveyard Bear", "Existing Top"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Graveyard Bolt"])
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Haunted Crossroads"
                and data.get("destination") == "library_top"
                and data.get("target_type") == "creature"
                and data.get("recovered") == ["Graveyard Bear"]
                for event, data in self.events
            )
        )

    def test_simple_activated_graveyard_to_library_does_not_move_without_mana(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        target = {"name": "Graveyard Memory", "type_line": "Sorcery", "cmc": 2}
        active.graveyard.append(target)
        permanent = {
            "name": "Tomb Trawler",
            "type_line": "Artifact Creature - Golem",
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_library_v1",
            "activated_effect": "graveyard_to_library",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_library_v1",
            "graveyard_to_library_target": "any_card",
            "graveyard_to_library_target_count": 1,
            "graveyard_to_library_destination": "library_bottom",
            "graveyard_to_library_activation_cost_mana": "{2}",
            "graveyard_to_library_activation_cost_generic": 2,
            "graveyard_to_library_activation_cost_colors": [],
        }
        active.battlefield.append(permanent)

        activated = self.battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=22,
            rng=random.Random(22),
            phase="precombat_main",
        )

        self.assertEqual(activated, 0)
        self.assertEqual(active.library, [])
        self.assertEqual(active.graveyard, [target])
        self.assertFalse(any(event == "graveyard_to_library_activated" for event, _ in self.events))

    def test_enchantment_effect_enters_battlefield_with_activated_rule_effects(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        effect = {
            "effect": "enchantment",
            "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_library_v1",
            "activated_effect": "graveyard_to_library",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_library_v1",
            "graveyard_to_library_target": "creature",
            "graveyard_to_library_target_count": 1,
            "graveyard_to_library_destination": "library_top",
            "_activated_rule_effects": [
                {
                    "effect": "recursion",
                    "battle_model_scope": "xmage_permanent_simple_activated_graveyard_to_library_v1",
                    "ability_kind": "activated",
                    "activated_effect": "graveyard_to_library",
                    "graveyard_to_library_target": "creature",
                    "graveyard_to_library_target_count": 1,
                    "graveyard_to_library_destination": "library_top",
                    "activation_cost_mana": "{B}",
                    "activation_cost_generic": 0,
                    "activation_cost_colors": ["B"],
                }
            ],
            "_rule_logical_key": "battle_rule_v1:fixture_haunted_crossroads",
        }

        self.battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Haunted Crossroads", "type_line": "Enchantment", "cmc": 3},
            turn=23,
            rng=random.Random(23),
            effect_data_override=effect,
        )

        self.assertEqual([card["name"] for card in active.battlefield], ["Haunted Crossroads"])
        permanent = active.battlefield[0]
        self.assertEqual(permanent["effect"], "enchantment")
        self.assertEqual(
            permanent["_activated_rule_effects"][0]["battle_model_scope"],
            "xmage_permanent_simple_activated_graveyard_to_library_v1",
        )
        self.assertTrue(
            any(
                event == "permanent_to_battlefield"
                and data.get("card") == "Haunted Crossroads"
                and data.get("effect") == "enchantment"
                for event, data in self.events
            )
        )

    def test_flashback_recursion_spell_resolves_from_graveyard_and_exiles(self) -> None:
        active = self.battle.Player("Active", None, [])
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(4)
        active.mana_pool.add("black", 1)
        target = {"name": "Graveyard Bear", "type_line": "Creature - Bear", "cmc": 2}
        source = {
            "name": "Morgue Theft",
            "type_line": "Sorcery",
            "cmc": 2,
            "flashback_cost": "{4}{B}",
        }
        self.battle.HANDCRAFTED_KNOWN_CARD_RULES["Morgue Theft"] = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_hand_spell_v1",
            "target": "creature",
            "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
            "count": 1,
            "destination": "hand",
            "target_controller": "self",
            "flashback_cost": "{4}{B}",
            "flashback_status": "runtime_executor_v1",
            "_rule_logical_key": "battle_rule_v1:fixture_morgue_theft",
        }
        self.battle.HANDCRAFTED_KNOWN_CARDS.add("Morgue Theft")
        active.graveyard.extend([target, source])
        stack = self.battle.Stack()

        cast = self.battle.cast_flashback_spell_from_graveyard(
            active,
            source,
            [opponent],
            [active, opponent],
            turn=24,
            phase="precombat_main",
            stack=stack,
            rng=random.Random(24),
        )

        self.assertTrue(cast)
        self.assertNotIn(source, active.graveyard)
        self.assertEqual(len(stack.items), 1)

        self.battle.priority_round(
            active,
            [active, opponent],
            stack,
            turn=24,
            rng=random.Random(25),
            phase="precombat_main",
        )

        self.assertTrue(stack.empty())
        self.assertEqual([card["name"] for card in active.hand], ["Graveyard Bear"])
        self.assertEqual(active.graveyard, [])
        self.assertEqual([card["name"] for card in active.exile], ["Morgue Theft"])
        self.assertTrue(
            any(
                event == "flashback_cast"
                and data.get("card") == "Morgue Theft"
                and data.get("flashback_cost") == "{4}{B}"
                for event, data in self.events
            )
        )
        self.assertTrue(
            any(
                event == "recursion_resolved"
                and data.get("card") == "Morgue Theft"
                and data.get("destination") == "hand"
                and data.get("recovered") == ["Graveyard Bear"]
                for event, data in self.events
            )
        )

    def test_cycling_recursion_spell_pays_cost_draws_and_moves_to_graveyard(self) -> None:
        active = self.battle.Player(
            "Active",
            None,
            [{"name": "Fresh Card", "type_line": "Instant", "cmc": 1}],
        )
        opponent = self.battle.Player("Opponent", None, [])
        active.mana_pool.add_generic(2)
        source = {
            "name": "Wander in Death",
            "type_line": "Sorcery",
            "cmc": 3,
        }
        self.battle.HANDCRAFTED_KNOWN_CARD_RULES["Wander in Death"] = {
            "effect": "recursion",
            "battle_model_scope": "xmage_return_target_graveyard_card_to_hand_spell_v1",
            "target": "creature",
            "target_constraints": {"zone": "graveyard", "controller": "self", "card_types": ["creature"]},
            "count": 2,
            "up_to_count": True,
            "destination": "hand",
            "target_controller": "self",
            "cycling_cost": "{2}",
            "cycling_status": "runtime_executor_v1",
            "_rule_logical_key": "battle_rule_v1:fixture_wander_in_death",
        }
        self.battle.HANDCRAFTED_KNOWN_CARDS.add("Wander in Death")
        active.hand.append(source)

        activated = self.battle.activate_hand_cycling(
            active,
            [opponent],
            [active, opponent],
            turn=25,
            rng=random.Random(26),
            phase="precombat_main",
            stack=self.battle.Stack(),
        )

        self.assertEqual(activated, 1)
        self.assertEqual([card["name"] for card in active.hand], ["Fresh Card"])
        self.assertEqual([card["name"] for card in active.graveyard], ["Wander in Death"])
        self.assertEqual(active.available_mana(), 0)
        self.assertTrue(
            any(
                event == "cycling_activated"
                and data.get("card") == "Wander in Death"
                and data.get("cycling_cost") == "{2}"
                and data.get("drawn") == ["Fresh Card"]
                for event, data in self.events
            )
        )


if __name__ == "__main__":
    unittest.main()
