#!/usr/bin/env python3
"""Focused runtime tests for Sawhorn Nemesis chosen-player damage doubling."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_sawhorn_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name, life=40):
    participant = battle.Player(name, None, [], strategy="midrange")
    participant.life = life
    return participant


def sawhorn_card():
    return {
        "name": "Sawhorn Nemesis",
        "type_line": "Creature - Dinosaur",
        "mana_cost": "{3}{R}",
        "cmc": 4,
        "power": 2,
        "toughness": 4,
    }


def creature(name, toughness=4):
    return {
        "name": name,
        "effect": "creature",
        "type_line": "Creature",
        "power": toughness,
        "toughness": toughness,
    }


def resolve_sawhorn(battle, controller, opponents, turn=4):
    battle.apply_effect_immediate(
        controller,
        opponents,
        sawhorn_card(),
        turn=turn,
        rng=random.Random(616),
        effect_data_override=battle.get_card_effect(sawhorn_card()),
    )
    return next(card for card in controller.battlefield if card.get("name") == "Sawhorn Nemesis")


def test_sawhorn_nemesis_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(sawhorn_card())

    assert effect["effect"] == "creature"
    assert effect["battle_model_scope"] == "chosen_player_or_permanents_they_control_damage_doubled_v1"
    assert effect["as_enters_choose_player"] is True
    assert effect["damage_modifier_applies_to"] == "chosen_player_or_permanents_they_control"
    assert effect["damage_modifier_targets"] == ["chosen_player", "chosen_player_permanents"]
    assert effect["damage_multiplier"] == 2
    assert effect["_rule_logical_key"] == "battle_rule_v1:93e3f5684069bf77d7219e17f3e04a6c:sawhorn_nemesis_runtime_v1"
    assert effect["_rule_oracle_hash"] == "93e3f5684069bf77d7219e17f3e04a6c"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Sawhorn Nemesis" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_sawhorn_enters_and_chooses_lowest_life_opponent():
    battle = load_battle()
    controller = player(battle, "Lorehold", life=40)
    low = player(battle, "Low Opponent", life=21)
    high = player(battle, "High Opponent", life=35)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        permanent = resolve_sawhorn(battle, controller, [high, low])
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert permanent["power"] == 2
    assert permanent["toughness"] == 4
    assert permanent["chosen_player_name"] == "Low Opponent"
    assert permanent["chosen_player_role"] == "opponent"
    assert any(
        event == "as_enters_choose_player"
        and data.get("card") == "Sawhorn Nemesis"
        and data.get("chosen_player") == "Low Opponent"
        for event, data in events
    )


def test_sawhorn_doubles_damage_to_chosen_player_only():
    battle = load_battle()
    controller = player(battle, "Lorehold", life=40)
    chosen = player(battle, "Chosen Opponent", life=40)
    other = player(battle, "Other Opponent", life=40)
    resolve_sawhorn(battle, controller, [other, chosen])
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        dealt_chosen, final_chosen, ok_chosen = battle.deal_damage_to_player_with_static_replacements(
            controller,
            chosen,
            {"name": "Lightning Strike", "type_line": "Instant", "controller": "Lorehold"},
            3,
            turn=5,
            phase="resolution",
        )
        dealt_other, final_other, ok_other = battle.deal_damage_to_player_with_static_replacements(
            controller,
            other,
            {"name": "Lightning Strike", "type_line": "Instant", "controller": "Lorehold"},
            3,
            turn=5,
            phase="resolution",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert (dealt_chosen, final_chosen, ok_chosen) == (6, 6, True)
    assert chosen.life == 34
    assert (dealt_other, final_other, ok_other) == (3, 3, True)
    assert other.life == 37
    assert any(
        event == "static_damage_replacement_applied"
        and data.get("source") == "Lightning Strike"
        and data.get("target_controller") == "Chosen Opponent"
        and data.get("original_amount") == 3
        and data.get("final_amount") == 6
        and data.get("modifiers", [{}])[0].get("source") == "Sawhorn Nemesis"
        for event, data in events
    )


def test_sawhorn_doubles_damage_to_chosen_players_permanent():
    battle = load_battle()
    controller = player(battle, "Lorehold", life=40)
    chosen = player(battle, "Chosen Opponent", life=40)
    other = player(battle, "Other Opponent", life=40)
    chosen_creature = creature("Chosen Four Toughness", toughness=4)
    other_creature = creature("Other Four Toughness", toughness=4)
    chosen.battlefield = [chosen_creature]
    other.battlefield = [other_creature]
    resolve_sawhorn(battle, controller, [other, chosen])
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        battle.apply_damage_wipe(
            controller,
            [chosen, other],
            {"name": "Three Damage Wipe", "type_line": "Sorcery", "controller": "Lorehold"},
            {"effect": "damage_wipe", "damage": 3, "damage_scope": "each_creature"},
            turn=6,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert chosen_creature not in chosen.battlefield
    assert other_creature in other.battlefield
    assert any(
        event == "static_damage_replacement_applied"
        and data.get("target_controller") == "Chosen Opponent"
        and data.get("target") == "Chosen Four Toughness"
        and data.get("final_amount") == 6
        for event, data in events
    )


def test_sawhorn_doubles_external_source_damage_to_chosen_player():
    battle = load_battle()
    controller = player(battle, "Lorehold", life=40)
    chosen = player(battle, "Chosen Opponent", life=35)
    caster = player(battle, "Caster Opponent", life=40)
    resolve_sawhorn(battle, controller, [caster, chosen])
    caster._current_opponents = [controller, chosen]

    dealt, final_amount, ok = battle.deal_damage_to_player_with_static_replacements(
        caster,
        chosen,
        {"name": "Caster Shock", "type_line": "Instant", "controller": "Caster Opponent"},
        2,
        turn=7,
        phase="resolution",
    )

    assert (dealt, final_amount, ok) == (4, 4, True)
    assert chosen.life == 31


if __name__ == "__main__":
    test_sawhorn_nemesis_get_card_effect_is_runtime_source()
    test_sawhorn_enters_and_chooses_lowest_life_opponent()
    test_sawhorn_doubles_damage_to_chosen_player_only()
    test_sawhorn_doubles_damage_to_chosen_players_permanent()
    test_sawhorn_doubles_external_source_damage_to_chosen_player()
