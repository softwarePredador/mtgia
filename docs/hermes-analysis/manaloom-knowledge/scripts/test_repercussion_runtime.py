#!/usr/bin/env python3
"""Focused runtime tests for Repercussion-style creature damage reflection."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_repercussion_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def creature(name, toughness=4):
    return {
        "name": name,
        "effect": "creature",
        "type_line": "Creature",
        "power": toughness,
        "toughness": toughness,
    }


def repercussion_card():
    return {
        "name": "Repercussion",
        "type_line": "Enchantment",
        "cmc": 3,
        "mana_cost": "{1}{R}{R}",
    }


def repercussion(battle):
    card = repercussion_card()
    effect = battle.get_card_effect(card)
    return {**card, **effect}


def test_repercussion_uses_xmage_backed_manual_runtime_waiver():
    battle = load_battle()
    effect = battle.get_card_effect(repercussion_card())

    assert "Repercussion" in battle.MANUAL_RULE_RUNTIME_WAIVERS
    assert effect["effect"] == "passive"
    assert effect["global_creature_damage_reflect_to_controller"] is True
    assert effect["trigger"] == "creature_dealt_damage"
    assert effect["trigger_effect"] == "damage_creature_controller"
    assert effect["damage_amount_source"] == "damage_dealt_to_creature"
    assert effect["battle_model_scope"] == "creature_damage_controller_reflect_global_v1"
    assert effect["_rule_oracle_hash"] == "8e1ed4f8063ab89dd8906878a6232862"
    assert effect["_rule_logical_key"] == "battle_rule_v1:d1a0c5cc0035945ec8bfd795da52d017"
    waiver = next(
        row
        for row in battle.manual_runtime_waiver_inventory()
        if row["card"] == "Repercussion"
    )
    assert waiver["effect"] == "passive"
    assert waiver["promotion_target"] == "card_battle_rules"
    assert "Repercussion.java" in waiver["source_runs"]


def test_repercussion_cast_enters_battlefield_and_triggers():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        opponent.battlefield = [creature("Four Toughness Creature", toughness=4)]
        card = repercussion_card()

        battle.apply_effect_immediate(
            active,
            [opponent],
            card,
            turn=3,
            rng=random.Random(607),
            effect_data_override=battle.get_card_effect(card),
        )
        assert any(permanent.get("name") == "Repercussion" for permanent in active.battlefield)

        battle.apply_damage_wipe(
            active,
            [opponent],
            {"name": "Three Damage Wipe", "type_line": "Sorcery", "cmc": 4},
            {"effect": "damage_wipe", "damage": 3, "damage_scope": "each_creature"},
            turn=4,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert opponent.life == 37
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Repercussion"
        and data.get("target_player") == "Opponent"
        and data.get("original_damage_to_creature") == 3
        for event, data in events
    )


def test_repercussion_damages_creature_controller_after_survived_creature_damage():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        opponent.battlefield = [creature("Four Toughness Creature", toughness=4)]
        active.battlefield = [repercussion(battle)]

        battle.apply_damage_wipe(
            active,
            [opponent],
            {"name": "Three Damage Wipe", "type_line": "Sorcery", "cmc": 4},
            {"effect": "damage_wipe", "damage": 3, "damage_scope": "each_creature"},
            turn=4,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert opponent.life == 37
    assert opponent.battlefield[0]["name"] == "Four Toughness Creature"
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Repercussion"
        and data.get("trigger") == "creature_dealt_damage"
        and data.get("effect") == "damage_creature_controller"
        and data.get("damaged_creature") == "Four Toughness Creature"
        and data.get("target_player") == "Opponent"
        and data.get("original_damage_to_creature") == 3
        and data.get("amount") == 3
        and data.get("damage_dealt") == 3
        for event, data in events
    )


def test_repercussion_stacks_with_blasphemous_act_board_damage():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.battlefield = [
            repercussion(battle),
            creature("Own Token", toughness=1),
        ]
        opponent.battlefield = [
            creature("Opponent Creature A", toughness=2),
            creature("Opponent Creature B", toughness=3),
        ]

        battle.apply_damage_wipe(
            active,
            [opponent],
            {"name": "Blasphemous Act", "type_line": "Sorcery", "cmc": 9},
            {"effect": "damage_wipe", "damage": 13, "damage_scope": "each_creature"},
            turn=7,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert active.life == 27
    assert opponent.life == 14
    assert all(card.get("name") != "Own Token" for card in active.battlefield)
    assert opponent.battlefield == []
    trigger_events = [
        data
        for event, data in events
        if event == "trigger_resolved" and data.get("card") == "Repercussion"
    ]
    assert len(trigger_events) == 3
    assert [data["target_player"] for data in trigger_events].count("Opponent") == 2
    assert [data["target_player"] for data in trigger_events].count("Lorehold") == 1
    assert all(data.get("amount") == 13 for data in trigger_events)


if __name__ == "__main__":
    tests = [
        test_repercussion_uses_xmage_backed_manual_runtime_waiver,
        test_repercussion_cast_enters_battlefield_and_triggers,
        test_repercussion_damages_creature_controller_after_survived_creature_damage,
        test_repercussion_stacks_with_blasphemous_act_board_damage,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
