#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import random
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_MODULE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def _load_battle_module():
    spec = importlib.util.spec_from_file_location(
        "battle_priority_lorehold_card_runtime_test",
        BATTLE_MODULE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = _load_battle_module()


def card(name, type_line, **extra):
    payload = {"name": name, "type_line": type_line}
    payload.update(extra)
    return payload


class PriorityLoreholdCardRuntimeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.events = []
        self.decisions = []
        self.old_event_handler = battle.REPLAY_EVENT_HANDLER
        self.old_decision_handler = battle.DECISION_TRACE_HANDLER
        battle.REPLAY_EVENT_HANDLER = lambda event, data: self.events.append((event, data))
        battle.DECISION_TRACE_HANDLER = lambda data: self.decisions.append(data)

    def tearDown(self) -> None:
        battle.REPLAY_EVENT_HANDLER = self.old_event_handler
        battle.DECISION_TRACE_HANDLER = self.old_decision_handler

    def test_mana_family_sources_produce_expected_runtime_mana(self) -> None:
        commander = card(
            "Lorehold, the Historian",
            "Legendary Creature — Elder Dragon",
            color_identity=["R", "W"],
        )
        player = battle.Player("Lorehold", commander, [], is_human=True)
        player.battlefield = [
            card(
                "Command Tower",
                "Land",
                effect="land",
                mana_produced=1,
                produces="WUBRGC",
                commander_identity_mana_source=True,
                battle_model_scope="commander_identity_land_mana_source_v1",
            ),
            card(
                "Sol Ring",
                "Artifact",
                effect="ramp_permanent",
                mana_produced=2,
                produces="C",
                battle_model_scope="two_colorless_mana_rock_v1",
            ),
            card(
                "Fellwar Stone",
                "Artifact",
                effect="ramp_permanent",
                mana_produced=1,
                produces="WUBRGC",
                battle_model_scope="conditional_opponent_color_mana_rock_v1",
                conditionally_produces_opponent_land_colors=True,
            ),
            card(
                "Talisman of Conviction",
                "Artifact",
                effect="ramp_permanent",
                mana_produced=1,
                produces="CRW",
                life_for_colored_mana=1,
                battle_model_scope="pain_talisman_color_pair_partial_v1",
            ),
        ]

        player.refresh_mana_sources(turn=1)

        self.assertEqual(player.available_mana(), 5)
        self.assertEqual(player.mana_pool.snapshot().get("colorless"), 2)
        conditional_sources = {source["source"]: source for source in player.conditional_mana_sources}
        self.assertEqual(
            sorted(mode["color"] for mode in conditional_sources["Command Tower"]["modes"]),
            ["red", "white"],
        )
        self.assertEqual(
            sorted(mode["color"] for mode in conditional_sources["Talisman of Conviction"]["modes"]),
            ["colorless", "red", "white"],
        )
        self.assertIn("Fellwar Stone", conditional_sources)
        talisman_modes = {
            mode["color"]: mode
            for mode in conditional_sources["Talisman of Conviction"]["modes"]
        }
        self.assertEqual(talisman_modes["colorless"]["life_loss_on_spend"], 0)
        self.assertEqual(talisman_modes["red"]["life_loss_on_spend"], 1)
        self.assertEqual(talisman_modes["white"]["life_loss_on_spend"], 1)

    def test_turbulent_steppe_enters_untapped_only_when_opponents_control_eight_lands(self) -> None:
        def basic_lands(prefix: str, count: int):
            return [
                card(f"{prefix} Land {index}", "Basic Land — Mountain", effect="land")
                for index in range(count)
            ]

        def play_with_opponent_land_count(opponent_land_count: int):
            player = battle.Player("Lorehold", None, [], is_human=True)
            opponent = battle.Player("Opponent", None, [])
            opponent.battlefield = basic_lands("Opponent", opponent_land_count)
            steppe = card("Turbulent Steppe", "Land — Mountain Plains", cmc=0)
            player.hand = [steppe]

            played = battle.play_land_candidate(
                player,
                [opponent],
                [player, opponent],
                turn=4,
                stack=battle.Stack(),
                candidate={"card": steppe, "source_zone": "hand"},
            )

            self.assertTrue(played)
            return player.battlefield[-1], player

        tapped_steppe, tapped_player = play_with_opponent_land_count(7)
        self.assertTrue(tapped_steppe["tapped"])
        self.assertTrue(tapped_steppe["enters_tapped"])
        self.assertEqual(
            tapped_steppe["conditional_enters_tapped_reason"],
            "opponents_below_required_land_count",
        )
        self.assertEqual(tapped_player.available_mana(), 0)

        untapped_steppe, untapped_player = play_with_opponent_land_count(8)
        self.assertFalse(untapped_steppe.get("tapped", False))
        self.assertFalse(untapped_steppe.get("enters_tapped", False))
        self.assertEqual(
            untapped_steppe["conditional_enters_tapped_reason"],
            "opponents_control_required_land_count",
        )
        self.assertEqual(untapped_steppe["conditional_enters_tapped_land_count"], 8)
        self.assertEqual(untapped_player.available_mana(), 1)
        self.assertEqual(untapped_player.mana_pool.snapshot().get("wildcard"), 1)

    def test_farewell_modal_exile_wipe_exiles_selected_types_and_graveyards(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        player.battlefield = [
            card("Sol Ring", "Artifact", effect="ramp_permanent"),
            card("Lorehold Apprentice", "Creature — Human Cleric", effect="creature", power=2, toughness=2),
            card("Ghostly Prison", "Enchantment", effect="passive"),
            card("Plains", "Basic Land — Plains", effect="land"),
        ]
        opponent.battlefield = [
            card("Darksteel Myr", "Artifact Creature — Myr", effect="creature", indestructible=True),
            card("Command Tower", "Land", effect="land"),
        ]
        player.graveyard = [card("Faithless Looting", "Sorcery")]
        opponent.graveyard = [card("Counterspell", "Instant")]
        effect = {
            "effect": "board_wipe",
            "exile_modes": ["artifacts", "creatures", "enchantments", "graveyards"],
            "battle_model_scope": "modal_exile_wipe_creature_runtime_baseline_v1",
        }

        battle.apply_effect_immediate(
            player,
            [opponent],
            card("Farewell", "Sorcery", cmc=6),
            turn=3,
            rng=random.Random(3),
            effect_data_override=effect,
        )

        self.assertEqual([permanent["name"] for permanent in player.battlefield], ["Plains"])
        self.assertEqual([permanent["name"] for permanent in opponent.battlefield], ["Command Tower"])
        exile_names = {exiled["name"] for exiled in player.exile + opponent.exile}
        self.assertTrue({"Sol Ring", "Lorehold Apprentice", "Ghostly Prison", "Darksteel Myr"} <= exile_names)
        self.assertEqual([grave_card["name"] for grave_card in player.graveyard], ["Farewell"])
        self.assertFalse(opponent.graveyard)
        event_payloads = [
            data for event, data in self.events if event == "modal_exile_board_wipe_resolved"
        ]
        self.assertEqual(event_payloads[0]["battlefield_exiled"], 4)
        self.assertEqual(event_payloads[0]["graveyard_exiled"], 2)

    def test_swords_to_plowshares_exiles_creature_and_grants_life_equal_power(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        opponent.life = 10
        target = card("Questing Beast", "Creature — Beast", effect="creature", power=4, toughness=4)
        opponent.battlefield = [target]
        effect = {
            "effect": "remove_creature",
            "target": "creature",
            "destination": "exile",
            "exile_target": True,
            "target_controller_life_gain_equal_target_power": True,
            "battle_model_scope": "swords_to_plowshares_creature_exile_life_equal_power_v1",
        }

        battle.apply_effect_immediate(
            player,
            [opponent],
            card("Swords to Plowshares", "Instant", cmc=1),
            turn=2,
            rng=random.Random(2),
            effect_data_override=effect,
        )

        self.assertFalse(opponent.battlefield)
        self.assertEqual([exiled["name"] for exiled in opponent.exile], ["Questing Beast"])
        self.assertEqual(opponent.life, 14)

    def test_teferis_protection_phases_all_permanents_and_locks_life(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        player.battlefield = [
            card("Lorehold, the Historian", "Legendary Creature — Elder Dragon", effect="creature"),
            card("Plains", "Basic Land — Plains", effect="land"),
        ]
        effect = {
            "effect": "phase_out",
            "duration": "until_your_next_turn",
            "exiles_self": True,
            "life_total_cant_change": True,
            "protection_from_everything": True,
            "phase_out_all_permanents_you_control": True,
            "phase_out_includes_lands": True,
            "battle_model_scope": "teferis_protection_life_lock_protection_all_permanents_phase_out_self_exile_v1",
        }

        battle.apply_effect_immediate(
            player,
            [],
            card("Teferi's Protection", "Instant", cmc=3),
            turn=4,
            rng=random.Random(4),
            effect_data_override=effect,
        )

        self.assertFalse(player.battlefield)
        self.assertEqual({permanent["name"] for permanent in player.phased_out}, {"Lorehold, the Historian", "Plains"})
        self.assertTrue(player.life_cant_change)
        self.assertTrue(player.protection_from_everything)

    def test_flawless_maneuver_grants_controlled_creatures_indestructible(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        player.battlefield = [
            card("Lorehold, the Historian", "Legendary Creature — Elder Dragon", effect="creature"),
            card("Storm-Kiln Artist", "Creature — Dwarf Shaman", effect="creature"),
            card("Sol Ring", "Artifact", effect="ramp_permanent"),
        ]
        effect = {
            "effect": "indestructible",
            "target_scope": "creatures_you_control",
            "free_if_control_commander": True,
            "battle_model_scope": "flawless_maneuver_control_commander_free_creatures_indestructible_until_eot_v1",
        }

        battle.apply_effect_immediate(
            player,
            [],
            card("Flawless Maneuver", "Instant", cmc=3),
            turn=4,
            rng=random.Random(4),
            effect_data_override=effect,
        )

        self.assertTrue(player.battlefield[0]["indestructible"])
        self.assertTrue(player.battlefield[1]["indestructible"])
        self.assertFalse(player.battlefield[2].get("indestructible", False))

    def test_land_tax_tutors_three_basic_lands_when_opponent_has_more_lands(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        land_tax = card(
            "Land Tax",
            "Enchantment",
            effect="land_tax",
            max_count=3,
            tutor_target="basic_land",
            reveals=True,
            shuffle_after=True,
            battle_model_scope="land_tax_upkeep_opponent_more_lands_basic_land_tutor_to_hand_v1",
        )
        player.battlefield = [
            land_tax,
            card("Plains", "Basic Land — Plains", effect="land", basic=True),
        ]
        opponent.battlefield = [
            card("Island", "Basic Land — Island", effect="land", basic=True),
            card("Mountain", "Basic Land — Mountain", effect="land", basic=True),
        ]
        player.library = [
            card("Plains", "Basic Land — Plains", basic=True),
            card("Mountain", "Basic Land — Mountain", basic=True),
            card("Sacred Foundry", "Land — Mountain Plains"),
            card("Island", "Basic Land — Island", basic=True),
        ]

        moved = battle.resolve_land_tax_upkeep_trigger(
            player,
            land_tax,
            turn=1,
            all_players=[player, opponent],
        )

        self.assertEqual(moved, 3)
        self.assertEqual({hand_card["name"] for hand_card in player.hand}, {"Plains", "Mountain", "Island"})
        self.assertEqual([library_card["name"] for library_card in player.library], ["Sacred Foundry"])

    def test_library_of_leng_replaces_discard_to_top_for_lorehold_draw(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        discarded = card("Comet Storm", "Instant", cmc=3)
        player.battlefield = [
            card(
                "Library of Leng",
                "Artifact",
                effect="passive",
                no_max_hand_size=True,
                discard_effect_to_top_replacement=True,
                battle_model_scope="discard_replacement_to_top_v1",
            )
        ]
        player.hand = [discarded]

        result = battle.resolve_effect_discard_cards(
            player,
            [discarded],
            top_limit=1,
            opponents=[],
            turn=1,
            phase="opponent_upkeep",
        )

        self.assertTrue(result["used_replacement"])
        self.assertEqual([card_["name"] for card_ in result["to_top"]], ["Comet Storm"])
        self.assertEqual(player.library[0]["name"], "Comet Storm")
        self.assertFalse(player.graveyard)

    def test_thor_noncreature_spell_trigger_deals_spell_mana_value_damage(self) -> None:
        player = battle.Player("Thor Player", None, [])
        opponent = battle.Player("Opponent", None, [])
        opponent.life = 4
        thor_effect = {
            "effect": "creature",
            "is_creature_permanent": True,
            "power": 5,
            "toughness": 5,
            "flying": True,
            "trigger": "noncreature_spell_cast",
            "trigger_effect": "damage_any_target",
            "trigger_damage_amount_source": "trigger_spell_mana_value",
            "battle_model_scope": "etb_graveyard_impulse_recast_noncreature_spell_damage_any_target_v1",
        }

        battle.apply_effect_immediate(
            player,
            [opponent],
            card("Thor, God of Thunder", "Legendary Creature — God Warrior Hero", cmc=5),
            turn=3,
            rng=random.Random(17),
            effect_data_override=thor_effect,
        )
        battle.trigger_spell_cast_engines(
            player,
            [player, opponent],
            card("Big Score", "Instant", cmc=4),
            turn=3,
            phase="precombat_main",
            active_player=player,
        )
        battle.trigger_spell_cast_engines(
            player,
            [player, opponent],
            card("Creature Followup", "Creature", cmc=4),
            turn=3,
            phase="precombat_main",
            active_player=player,
        )

        thor_triggers = [
            data
            for event, data in self.events
            if event == "trigger_resolved"
            and data.get("card") == "Thor, God of Thunder"
            and data.get("effect") == "damage_any_target"
        ]
        self.assertEqual(len(thor_triggers), 1)
        self.assertEqual(thor_triggers[0]["amount"], 4)
        self.assertEqual(thor_triggers[0]["result"], "player_damage")
        self.assertEqual(opponent.life, 0)

    def test_hit_the_mother_lode_discovers_and_creates_treasure_difference(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        player.library = [
            card("Mountain", "Basic Land — Mountain", effect="land", cmc=0),
            card("Expensive Miss", "Sorcery", effect="draw_cards", count=0, cmc=11),
            card("Free Hit", "Sorcery", effect="draw_cards", count=0, cmc=4),
        ]
        effect = {
            "effect": "draw_cards",
            "count": 1,
            "discover_value": 10,
            "discover_treasure_difference": True,
            "battle_model_scope": "discover_10_as_one_card_value_component_v1",
        }

        battle.apply_effect_immediate(
            player,
            [opponent],
            card("Hit the Mother Lode", "Sorcery", cmc=7),
            turn=5,
            rng=random.Random(5),
            effect_data_override=effect,
        )

        self.assertEqual(player.treasures, 6)
        self.assertEqual([grave_card["name"] for grave_card in player.graveyard], ["Free Hit", "Hit the Mother Lode"])
        self.assertEqual({library_card["name"] for library_card in player.library}, {"Mountain", "Expensive Miss"})
        events = [data for event, data in self.events if event == "discover_resolved"]
        self.assertEqual(events[0]["hit"], "Free Hit")
        self.assertEqual(events[0]["hit_mana_value"], 4)
        self.assertEqual(events[0]["treasures_created"], 6)
        self.assertTrue(events[0]["cast_success"])

    def test_improvisation_capstone_exiles_until_total_mana_value_and_free_casts(self) -> None:
        player = battle.Player("Lorehold", None, [], is_human=True)
        opponent = battle.Player("Opponent", None, [])
        player.library = [
            card("Plains", "Basic Land — Plains", effect="land", cmc=0),
            card("Small Spell", "Instant", effect="draw_cards", count=0, cmc=2),
            card("Second Spell", "Sorcery", effect="draw_cards", count=0, cmc=3),
        ]
        effect = {
            "effect": "exile_value",
            "exile_until_total_mana_value_at_least": 4,
            "may_cast_exiled_spells_without_paying": True,
            "paradigm": True,
            "battle_model_scope": "exile_value_free_casts_paradigm_annotation_v1",
        }

        battle.apply_effect_immediate(
            player,
            [opponent],
            card("Improvisation Capstone", "Sorcery", cmc=7),
            turn=6,
            rng=random.Random(6),
            effect_data_override=effect,
        )

        self.assertEqual(
            [grave_card["name"] for grave_card in player.graveyard],
            ["Small Spell", "Second Spell", "Improvisation Capstone"],
        )
        self.assertEqual([exiled["name"] for exiled in player.exile], ["Plains"])
        events = [data for event, data in self.events if event == "exile_value_free_casts_resolved"]
        self.assertEqual(events[0]["exiled_total_mana_value"], 5)
        self.assertEqual(events[0]["free_cast_count"], 2)
        self.assertTrue(events[0]["paradigm"])

    def test_tibalts_trickery_counters_then_resolves_random_replacement(self) -> None:
        counter_player = battle.Player("Lorehold", None, [], is_human=True)
        spell_player = battle.Player("Opponent", None, [])
        tibalt = card(
            "Tibalt's Trickery",
            "Instant",
            effect="counter",
            target="spell",
            instant=True,
            cmc=2,
            random_mill_then_free_replacement_spell=True,
            battle_model_scope="counterspell_with_random_replacement_annotation_v1",
        )
        target_spell = card("Original Bomb", "Sorcery", effect="draw_cards", count=0, cmc=7)
        counter_player.hand = [tibalt]
        counter_player.mana_pool.add_generic(2)
        spell_player.library = [
            card("Island", "Basic Land — Island", effect="land", cmc=0),
            card("Mountain", "Basic Land — Mountain", effect="land", cmc=0),
            card("Forest", "Basic Land — Forest", effect="land", cmc=0),
            card("Replacement Spell", "Sorcery", effect="draw_cards", count=0, cmc=5),
        ]
        stack_item = battle.StackItem(target_spell, spell_player, {"effect": "draw_cards", "count": 0})

        used_counter = counter_player.use_counterspell(
            turn=7,
            target_card=target_spell,
            stack_item=stack_item,
            phase="stack_response",
            all_players=[counter_player, spell_player],
        )

        self.assertIs(used_counter, tibalt)
        self.assertTrue(tibalt["_countered_target"])
        self.assertIn(tibalt, counter_player.graveyard)
        self.assertIn("Replacement Spell", [grave_card["name"] for grave_card in spell_player.graveyard])
        events = [data for event, data in self.events if event == "tibalts_trickery_replacement_resolved"]
        self.assertEqual(events[0]["replacement_hit"], "Replacement Spell")
        self.assertTrue(events[0]["replacement_cast_success"])
        self.assertGreaterEqual(events[0]["cards_milled"], 1)


if __name__ == "__main__":
    unittest.main()
