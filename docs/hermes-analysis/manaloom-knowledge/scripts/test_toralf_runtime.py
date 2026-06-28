#!/usr/bin/env python3
"""Focused runtime tests for Toralf excess noncombat damage semantics."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_toralf_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name, life=40):
    participant = battle.Player(name, None, [], strategy="midrange")
    participant.life = life
    return participant


def creature(name, power=2, toughness=2, **extra):
    card = {
        "name": name,
        "effect": "creature",
        "type_line": "Creature",
        "power": power,
        "toughness": toughness,
    }
    card.update(extra)
    return card


def toralf_card():
    return {
        "name": "Toralf, God of Fury // Toralf's Hammer",
        "type_line": "Legendary Creature - God",
        "cmc": 4,
        "mana_cost": "{2}{R}{R}",
    }


def cast_toralf(battle, active, opponents, turn=4):
    card = toralf_card()
    battle.apply_effect_immediate(
        active,
        opponents,
        card,
        turn=turn,
        rng=random.Random(612),
        effect_data_override=battle.get_card_effect(card),
    )
    return next(
        permanent
        for permanent in active.battlefield
        if permanent["name"] == "Toralf, God of Fury // Toralf's Hammer"
    )


def test_toralf_uses_xmage_backed_manual_runtime_waiver():
    battle = load_battle()
    effect = battle.get_card_effect(toralf_card())

    assert "Toralf, God of Fury // Toralf's Hammer" in battle.MANUAL_RULE_RUNTIME_WAIVERS
    assert effect["effect"] == "creature"
    assert effect["power"] == 5
    assert effect["toughness"] == 4
    assert effect["trample"] is True
    assert effect["trigger"] == "opponent_permanent_excess_noncombat_damage"
    assert effect["trigger_effect"] == "damage_any_target"
    assert effect["damage_amount_source"] == "excess_noncombat_damage"
    assert effect["excess_noncombat_damage_to_opponent_permanent_reflect_any_target"] is True
    assert effect["back_face_name"] == "Toralf's Hammer"
    assert effect["hammer_activation_damage"] == 3
    assert effect["battle_model_scope"] == "opponent_creature_excess_noncombat_damage_reflect_any_target_equipment_metadata_v1"
    assert effect["_rule_oracle_hash"] == "900c199972617df82c6ddf796e2cf04f"
    assert effect["_rule_logical_key"] == "battle_rule_v1:733e913423b3c4471520195c8a814097"
    waiver = next(
        row
        for row in battle.manual_runtime_waiver_inventory()
        if row["card"] == "Toralf, God of Fury // Toralf's Hammer"
    )
    assert waiver["effect"] == "creature"
    assert waiver["promotion_target"] == "card_battle_rules"
    assert "ToralfGodOfFury.java" in waiver["source_runs"]


def test_toralf_cast_enters_as_trampling_creature():
    battle = load_battle()
    active = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")

    permanent = cast_toralf(battle, active, [opponent])

    assert battle.is_battlefield_creature(permanent)
    assert permanent["power"] == 5
    assert permanent["toughness"] == 4
    assert permanent["trample"] is True


def test_toralf_excess_noncombat_damage_hits_opponent_player():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        toralf = cast_toralf(battle, active, [opponent])
        target = creature("Opponent Bear", power=2, toughness=2)
        opponent.battlefield.append(target)

        triggers = battle.trigger_creature_damage_controller_reflect(
            [active, opponent],
            active,
            opponent,
            {"name": "Volcanic Fallout", "type_line": "Instant"},
            target,
            5,
            turn=5,
            phase="resolution",
            damage_event="direct_damage",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert triggers == 1
    assert opponent.life == 37
    assert toralf in active.battlefield
    assert any(
        event == "trigger_resolved"
        and data["card"] == "Toralf, God of Fury // Toralf's Hammer"
        and data["trigger"] == "opponent_permanent_excess_noncombat_damage"
        and data["damaged_creature"] == "Opponent Bear"
        and data["excess_damage"] == 3
        and data["target_player"] == "Opponent"
        for event, data in events
    )


def test_toralf_does_not_trigger_from_combat_damage():
    battle = load_battle()
    active = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    cast_toralf(battle, active, [opponent])
    target = creature("Opponent Bear", power=2, toughness=2)
    opponent.battlefield.append(target)

    triggers = battle.trigger_creature_damage_controller_reflect(
        [active, opponent],
        active,
        opponent,
        {"name": "Attacker", "type_line": "Creature"},
        target,
        5,
        turn=5,
        phase="combat_damage",
        damage_event="combat_damage",
    )

    assert triggers == 0
    assert opponent.life == 40


def test_toralf_does_not_trigger_for_controller_own_creature():
    battle = load_battle()
    active = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    cast_toralf(battle, active, [opponent])
    own_target = creature("Lorehold Bear", power=2, toughness=2)
    active.battlefield.append(own_target)

    triggers = battle.trigger_creature_damage_controller_reflect(
        [active, opponent],
        opponent,
        active,
        {"name": "Opponent Burn", "type_line": "Instant"},
        own_target,
        5,
        turn=5,
        phase="resolution",
        damage_event="direct_damage",
    )

    assert triggers == 0
    assert opponent.life == 40


if __name__ == "__main__":
    tests = [
        test_toralf_uses_xmage_backed_manual_runtime_waiver,
        test_toralf_cast_enters_as_trampling_creature,
        test_toralf_excess_noncombat_damage_hits_opponent_player,
        test_toralf_does_not_trigger_from_combat_damage,
        test_toralf_does_not_trigger_for_controller_own_creature,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
