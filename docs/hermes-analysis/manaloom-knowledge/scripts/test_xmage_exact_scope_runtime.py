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


if __name__ == "__main__":
    unittest.main()
