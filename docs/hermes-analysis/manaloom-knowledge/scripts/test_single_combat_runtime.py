#!/usr/bin/env python3
"""Focused runtime tests for Single Combat sacrifice and spell-type lock."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_single_combat_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def single_combat_card():
    return {
        "name": "Single Combat",
        "type_line": "Sorcery",
        "mana_cost": "{3}{W}{W}",
        "cmc": 5,
    }


def creature(name, power=2, toughness=None):
    return {
        "name": name,
        "effect": "creature",
        "type_line": "Creature",
        "power": power,
        "toughness": toughness if toughness is not None else power,
    }


def planeswalker(name, loyalty=4):
    return {
        "name": name,
        "effect": "planeswalker",
        "type_line": "Planeswalker",
        "loyalty": loyalty,
    }


def test_single_combat_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(single_combat_card())

    assert effect["effect"] == "single_combat"
    assert effect["battle_model_scope"] == (
        "each_player_keep_one_creature_or_planeswalker_sacrifice_rest_then_creature_planeswalker_cast_lock_v1"
    )
    assert effect["each_player_chooses_one_creature_or_planeswalker_sacrifices_rest"] is True
    assert effect["spell_type_cast_lock_card_types"] == ["creature", "planeswalker"]
    assert effect["spell_type_cast_lock_applies_to"] == "all_players"
    assert effect["_rule_logical_key"] == "battle_rule_v1:45c2a4f6d6d4930fb4cb54b8fa886bc2"
    assert effect["_rule_oracle_hash"] == "be6bde23599b29cf800eefe5f11416f6"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Single Combat" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_single_combat_keeps_one_creature_or_planeswalker_per_player_and_locks_casting():
    battle = load_battle()
    controller = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    own_best = creature("Own Titan", power=6, toughness=6)
    own_small = creature("Own Token", power=1, toughness=1)
    own_walker = planeswalker("Own Walker", loyalty=2)
    opp_best = creature("Opp Titan", power=5, toughness=5)
    opp_small = creature("Opp Token", power=1, toughness=1)
    opp_walker = planeswalker("Opp Walker", loyalty=1)
    controller.battlefield = [own_small, own_best, own_walker]
    opponent.battlefield = [opp_small, opp_best, opp_walker]
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        battle.apply_effect_immediate(
            controller,
            [opponent],
            single_combat_card(),
            turn=3,
            rng=random.Random(615),
            effect_data_override=battle.get_card_effect(single_combat_card()),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert own_best in controller.battlefield
    assert opp_best in opponent.battlefield
    assert own_small in controller.graveyard
    assert own_walker in controller.graveyard
    assert opp_small in opponent.graveyard
    assert opp_walker in opponent.graveyard
    assert battle.spell_type_cast_lock_for_card(
        controller,
        {"name": "Bear", "type_line": "Creature", "cmc": 2},
        {"effect": "creature"},
    )
    assert battle.can_cast_in_phase(
        {"name": "Bear", "type_line": "Creature", "cmc": 2},
        {"effect": "creature"},
        "precombat_main",
        controller=controller,
    ) is False
    assert battle.can_cast_in_phase(
        {"name": "Jace", "type_line": "Planeswalker", "cmc": 4},
        {"effect": "planeswalker"},
        "precombat_main",
        controller=opponent,
    ) is False
    assert battle.can_cast_in_phase(
        {"name": "Lightning Bolt", "type_line": "Instant", "cmc": 1},
        {"effect": "direct_damage"},
        "precombat_main",
        controller=opponent,
    ) is True
    assert any(
        event == "single_combat_resolved"
        and data.get("sacrificed") == 4
        and data.get("locked_players") == ["Lorehold", "Opponent"]
        for event, data in events
    )


def test_single_combat_lock_expires_after_source_next_turn_cleanup():
    battle = load_battle()
    controller = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    for participant in (controller, opponent):
        battle.add_spell_type_cast_lock(
            participant,
            source="Single Combat",
            source_player="Lorehold",
            started_turn=3,
            card_types=["creature", "planeswalker"],
            duration="until_end_of_your_next_turn",
        )

    creature_card = {"name": "Bear", "type_line": "Creature", "cmc": 2}
    assert battle.can_cast_in_phase(creature_card, {"effect": "creature"}, "precombat_main", controller=opponent) is False

    battle.clear_expired_spell_type_cast_locks_after_turn(controller, [controller, opponent], 3)
    assert battle.can_cast_in_phase(creature_card, {"effect": "creature"}, "precombat_main", controller=opponent) is False

    battle.clear_expired_spell_type_cast_locks_after_turn(controller, [controller, opponent], 4)
    assert battle.can_cast_in_phase(creature_card, {"effect": "creature"}, "precombat_main", controller=opponent) is True


if __name__ == "__main__":
    test_single_combat_get_card_effect_is_runtime_source()
    test_single_combat_keeps_one_creature_or_planeswalker_per_player_and_locks_casting()
    test_single_combat_lock_expires_after_source_next_turn_cleanup()
