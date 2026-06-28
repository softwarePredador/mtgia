#!/usr/bin/env python3
"""Focused runtime tests for Ancient Copper Dragon's d20 Treasure trigger."""

from __future__ import annotations

import importlib.util
import random
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_ancient_copper_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def dragon_card():
    return {
        "name": "Ancient Copper Dragon",
        "type_line": "Creature - Elder Dragon",
        "mana_cost": "{4}{R}{R}",
        "cmc": 6,
    }


def test_ancient_copper_dragon_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(dragon_card())

    assert effect["effect"] == "ramp_engine"
    assert effect["battle_model_scope"] == "source_combat_damage_player_roll_d20_create_treasure_equal_result_v1"
    assert effect["trigger"] == "combat_damage_to_player"
    assert effect["trigger_source_deals_combat_damage_to_player"] is True
    assert effect["treasure_count_source"] == "d20_result"
    assert effect["die_sides"] == 20
    assert effect["power"] == 6
    assert effect["toughness"] == 5
    assert effect["flying"] is True
    assert effect["_rule_logical_key"] == "battle_rule_v1:e2ac43c9f6e03e11e9fab994a5c15258"
    assert effect["_rule_oracle_hash"] == "776a45094149ed3e1cc8c1a408fb6318"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Ancient Copper Dragon" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_ancient_copper_dragon_rolls_d20_for_combat_damage_treasures():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")

        battle.apply_effect_immediate(
            active,
            [opponent],
            dragon_card(),
            turn=6,
            rng=random.Random(608),
        )
        dragon = next(card for card in active.battlefield if card.get("name") == "Ancient Copper Dragon")
        dragon["summoning_sick"] = False
        expected_roll = random.Random(616).randint(1, 20)

        battle.combat_damage_steps(
            active,
            [opponent],
            opponent,
            [dragon],
            [(dragon, [])],
            turn=7,
            rng=random.Random(616),
            all_players=[active, opponent],
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert opponent.life == 34
    assert active.treasures == expected_roll
    trigger_event = next(
        data
        for event, data in events
        if event == "trigger_resolved"
        and data.get("card") == "Ancient Copper Dragon"
        and data.get("trigger") == "combat_damage_to_player"
    )
    assert trigger_event["trigger_creatures"] == ["Ancient Copper Dragon"]
    assert trigger_event["treasure_count_source"] == "d20_result"
    assert trigger_event["die_sides"] == 20
    assert trigger_event["die_roll"] == expected_roll
    assert trigger_event["treasures_created"] == expected_roll
    assert trigger_event["treasures_before"] == 0
    assert trigger_event["treasures_after"] == expected_roll


def test_generic_combat_damage_treasure_trigger_still_uses_fixed_count():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Active")
        opponent = player(battle, "Opponent")
        knuckles = {
            "name": "Knuckles the Echidna",
            "cmc": 4,
            "type_line": "Legendary Creature - Echidna Warrior",
        }
        effect_data = {
            "effect": "ramp_engine",
            "battle_model_scope": "one_or_more_creatures_you_control_combat_damage_player_create_treasure_v1",
            "is_creature_permanent": True,
            "power": 2,
            "toughness": 4,
            "double_strike": True,
            "trample": True,
            "haste": True,
            "trigger": "combat_damage_to_player",
            "trigger_creatures_you_control": True,
            "treasure_count": 1,
        }

        battle.apply_effect_immediate(
            active,
            [opponent],
            knuckles,
            turn=5,
            rng=random.Random(12021),
            effect_data_override=effect_data,
        )
        creature = next(card for card in active.battlefield if card.get("name") == "Knuckles the Echidna")
        creature["summoning_sick"] = False
        battle.combat_damage_steps(
            active,
            [opponent],
            opponent,
            [creature],
            [(creature, [])],
            turn=5,
            rng=random.Random(12022),
            all_players=[active, opponent],
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert active.treasures == 2
    trigger_events = [
        data
        for event, data in events
        if event == "trigger_resolved"
        and data.get("card") == "Knuckles the Echidna"
        and data.get("trigger") == "combat_damage_to_player"
    ]
    assert len(trigger_events) == 2
    assert all(data["treasures_created"] == 1 for data in trigger_events)
    assert all(data["die_roll"] is None for data in trigger_events)
    assert trigger_events[0]["phase"] == "first_strike_damage"
    assert trigger_events[1]["phase"] == "combat_damage"


if __name__ == "__main__":
    test_ancient_copper_dragon_get_card_effect_is_runtime_source()
    test_ancient_copper_dragon_rolls_d20_for_combat_damage_treasures()
    test_generic_combat_damage_treasure_trigger_still_uses_fixed_count()
    print("PASS test_ancient_copper_dragon_runtime")
