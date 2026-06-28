#!/usr/bin/env python3
"""Focused runtime tests for Screaming Nemesis damage reflection."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_screaming_nemesis_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name, life=40):
    participant = battle.Player(name, None, [], strategy="midrange")
    participant.life = life
    return participant


def screaming_card():
    return {
        "name": "Screaming Nemesis",
        "type_line": "Creature - Spirit",
        "mana_cost": "{2}{R}",
        "cmc": 3,
        "power": 3,
        "toughness": 3,
    }


def damage_wipe(name, amount):
    return (
        {"name": name, "type_line": "Sorcery", "cmc": 2},
        {"effect": "damage_wipe", "damage": amount, "damage_scope": "each_creature"},
    )


def resolve_screaming(battle, controller, opponents, turn=4):
    battle.apply_effect_immediate(
        controller,
        opponents,
        screaming_card(),
        turn=turn,
        rng=random.Random(616),
        effect_data_override=battle.get_card_effect(screaming_card()),
    )
    return next(card for card in controller.battlefield if card.get("name") == "Screaming Nemesis")


def test_screaming_nemesis_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(screaming_card())

    assert effect["effect"] == "creature"
    assert effect["battle_model_scope"] == (
        "source_dealt_damage_reflect_to_any_other_target_player_hit_cant_gain_life_v1"
    )
    assert effect["haste"] is True
    assert effect["trigger"] == "source_dealt_damage"
    assert effect["trigger_effect"] == "damage_any_target"
    assert effect["damage_amount_source"] == "damage_dealt_to_source"
    assert effect["source_damage_reflect_to_any_target"] is True
    assert effect["player_hit_cant_gain_life_rest_of_game"] is True
    assert effect["_rule_logical_key"] == "battle_rule_v1:77190ec2e1e1dcb8b15429e5d53e68bd:screaming_nemesis_runtime_v1"
    assert effect["_rule_oracle_hash"] == "77190ec2e1e1dcb8b15429e5d53e68bd"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Screaming Nemesis" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_screaming_nemesis_enters_as_hasty_creature():
    battle = load_battle()
    controller = player(battle, "Lorehold")

    permanent = resolve_screaming(battle, controller, [])

    assert permanent["power"] == 3
    assert permanent["toughness"] == 3
    assert permanent["haste"] is True
    assert permanent["summoning_sick"] is False


def test_screaming_nemesis_reflects_damage_and_blocks_life_gain_rest_of_game():
    battle = load_battle()
    controller = player(battle, "Lorehold", life=40)
    opponent = player(battle, "Opponent", life=40)
    permanent = resolve_screaming(battle, controller, [opponent])
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        spell, effect = damage_wipe("Pyroclasm", 2)
        battle.apply_damage_wipe(opponent, [controller], spell, effect, turn=5)
        gained = battle.gain_life(opponent, 5, cap=999)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert permanent in controller.battlefield
    assert opponent.life == 38
    assert opponent.cant_gain_life is True
    assert opponent.cant_gain_life_source == "Screaming Nemesis"
    assert gained is False
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Screaming Nemesis"
        and data.get("target_player") == "Opponent"
        and data.get("original_damage_to_source") == 2
        and data.get("damage_dealt") == 2
        and data.get("cant_gain_life_applied") is True
        for event, data in events
    )
    assert any(
        event == "life_gain_prevented"
        and data.get("player") == "Opponent"
        and data.get("source") == "Screaming Nemesis"
        for event, data in events
    )


if __name__ == "__main__":
    test_screaming_nemesis_get_card_effect_is_runtime_source()
    test_screaming_nemesis_enters_as_hasty_creature()
    test_screaming_nemesis_reflects_damage_and_blocks_life_gain_rest_of_game()
