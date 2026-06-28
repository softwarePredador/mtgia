#!/usr/bin/env python3
"""Focused runtime tests for Stuffy Doll chosen-player damage reflection."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_stuffy_doll_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name, life=40):
    participant = battle.Player(name, None, [], strategy="midrange")
    participant.life = life
    return participant


def stuffy_card():
    return {
        "name": "Stuffy Doll",
        "type_line": "Artifact Creature - Construct",
        "mana_cost": "{5}",
        "cmc": 5,
        "power": 0,
        "toughness": 1,
    }


def damage_wipe(name, amount):
    return (
        {"name": name, "type_line": "Sorcery", "cmc": 2},
        {"effect": "damage_wipe", "damage": amount, "damage_scope": "each_creature"},
    )


def resolve_stuffy(battle, controller, opponents, turn=5):
    battle.apply_effect_immediate(
        controller,
        opponents,
        stuffy_card(),
        turn=turn,
        rng=random.Random(616),
        effect_data_override=battle.get_card_effect(stuffy_card()),
    )
    return next(card for card in controller.battlefield if card.get("name") == "Stuffy Doll")


def test_stuffy_doll_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(stuffy_card())

    assert effect["effect"] == "creature"
    assert effect["battle_model_scope"] == "source_dealt_damage_reflect_to_chosen_player_self_damage_indestructible_v1"
    assert effect["artifact"] is True
    assert effect["indestructible"] is True
    assert effect["as_enters_choose_player"] is True
    assert effect["source_damage_reflect_to_chosen_player"] is True
    assert effect["activated_self_damage_to_source"] == 1
    assert effect["activation_requires_tap"] is True
    assert effect["_rule_logical_key"] == "battle_rule_v1:e7b60d9805dbf2701195f627c6ca1600"
    assert effect["_rule_oracle_hash"] == "b3404d9b844875e0e427a0eda8011c83"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Stuffy Doll" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_stuffy_doll_chooses_lowest_life_opponent_as_it_enters():
    battle = load_battle()
    controller = player(battle, "Lorehold", life=40)
    low = player(battle, "Low Opponent", life=31)
    high = player(battle, "High Opponent", life=37)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        permanent = resolve_stuffy(battle, controller, [high, low])
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert permanent["indestructible"] is True
    assert permanent["chosen_player_name"] == "Low Opponent"
    assert permanent["chosen_player_role"] == "opponent"
    assert permanent["summoning_sick"] is True
    assert any(
        event == "as_enters_choose_player"
        and data.get("card") == "Stuffy Doll"
        and data.get("chosen_player") == "Low Opponent"
        for event, data in events
    )


def test_stuffy_doll_reflects_external_damage_to_chosen_player_and_survives():
    battle = load_battle()
    controller = player(battle, "Lorehold", life=40)
    chosen = player(battle, "Chosen Opponent", life=35)
    caster = player(battle, "Caster Opponent", life=38)
    permanent = resolve_stuffy(battle, controller, [caster, chosen])
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        spell, effect = damage_wipe("Pyroclasm", 2)
        battle.apply_damage_wipe(caster, [controller, chosen], spell, effect, turn=6)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert chosen.life == 33
    assert permanent in controller.battlefield
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Stuffy Doll"
        and data.get("trigger") == "source_dealt_damage"
        and data.get("target_selection") == "chosen_player"
        and data.get("target_player") == "Chosen Opponent"
        and data.get("original_damage_to_source") == 2
        and data.get("damage_dealt") == 2
        for event, data in events
    )


def test_stuffy_doll_tap_self_damage_activation_reflects_one_damage():
    battle = load_battle()
    controller = player(battle, "Lorehold", life=40)
    chosen = player(battle, "Chosen Opponent", life=12)
    permanent = resolve_stuffy(battle, controller, [chosen], turn=4)
    permanent["summoning_sick"] = False
    all_players = [controller, chosen]
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        activated = battle.activate_self_damage_reflect_sources(
            controller,
            [chosen],
            all_players,
            turn=5,
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert activated == 1
    assert chosen.life == 11
    assert permanent["tapped"] is True
    assert permanent in controller.battlefield
    assert any(
        event == "activated_ability"
        and data.get("card") == "Stuffy Doll"
        and data.get("activation_kind") == "self_damage_reflect"
        and data.get("damage_to_self") == 1
        and data.get("reflected_triggers") == 1
        for event, data in events
    )
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Stuffy Doll"
        and data.get("target_player") == "Chosen Opponent"
        and data.get("damage_event") == "activated_self_damage"
        and data.get("damage_dealt") == 1
        for event, data in events
    )


if __name__ == "__main__":
    test_stuffy_doll_get_card_effect_is_runtime_source()
    test_stuffy_doll_chooses_lowest_life_opponent_as_it_enters()
    test_stuffy_doll_reflects_external_damage_to_chosen_player_and_survives()
    test_stuffy_doll_tap_self_damage_activation_reflects_one_damage()
    print("PASS test_stuffy_doll_runtime")
