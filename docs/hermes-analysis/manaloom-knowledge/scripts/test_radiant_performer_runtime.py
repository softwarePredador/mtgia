#!/usr/bin/env python3
"""Focused runtime tests for Radiant Performer partial stack-copy semantics."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_radiant_performer_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name, life=40):
    participant = battle.Player(name, None, [], strategy="midrange")
    participant.life = life
    return participant


def radiant_card():
    return {
        "name": "Radiant Performer",
        "type_line": "Creature - Human Wizard",
        "cmc": 5,
        "mana_cost": "{3}{R}{R}",
    }


def cast_radiant(battle, active, opponents, turn=5, stack=None):
    card = radiant_card()
    battle.apply_effect_immediate(
        active,
        opponents,
        card,
        turn=turn,
        rng=random.Random(616),
        effect_data_override=battle.get_card_effect(card),
        stack=stack,
    )
    return next(
        permanent
        for permanent in active.battlefield
        if permanent["name"] == "Radiant Performer"
    )


def test_radiant_performer_uses_xmage_backed_partial_runtime_waiver():
    battle = load_battle()
    effect = battle.get_card_effect(radiant_card())

    assert "Radiant Performer" in battle.MANUAL_RULE_RUNTIME_WAIVERS
    assert effect["effect"] == "copy_spell"
    assert effect["power"] == 2
    assert effect["toughness"] == 2
    assert effect["flash"] is True
    assert effect["etb_if_cast_from_hand"] is True
    assert effect["etb_copy_spell"] is True
    assert effect["copy_target_stack_object"] is True
    assert effect["copy_target_stack_object_single_permanent_or_player_target_only"] is True
    assert effect["copy_for_each_other_legal_permanent_or_player_target"] is True
    assert effect["supports_stack_spell_copy"] is True
    assert effect["supports_stack_ability_copy"] is False
    assert effect["supports_copy_for_each_other_target"] is False
    assert effect["_runtime_partial"] is True
    assert effect["battle_model_scope"] == "flash_creature_etb_copy_stack_spell_partial_metadata_v1"
    assert effect["_rule_oracle_hash"] == "893b8d4958e842209180034ee424d134"
    assert effect["_rule_logical_key"] == "battle_rule_v1:fa12ce53b0a0c4b963f4071b4fde2c9b"
    waiver = next(
        row
        for row in battle.manual_runtime_waiver_inventory()
        if row["card"] == "Radiant Performer"
    )
    assert waiver["effect"] == "copy_spell"
    assert waiver["promotion_target"] == "card_battle_rules"
    assert "RadiantPerformer.java" in waiver["source_runs"]


def test_radiant_performer_enters_battlefield_and_reports_no_stack_target():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")

        permanent = cast_radiant(battle, active, [opponent], stack=None)
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert battle.is_battlefield_creature(permanent)
    assert permanent["effect"] == "creature"
    assert permanent["power"] == 2
    assert permanent["toughness"] == 2
    assert permanent["summoning_sick"] is True
    assert any(
        event == "creature_to_battlefield"
        and data["card"] == "Radiant Performer"
        and data["rule_source"] == "manual_runtime_waiver"
        for event, data in events
    )
    assert any(
        event == "copy_spell_no_stack_target"
        and data["card"] == "Radiant Performer"
        and data["trigger"] == "enters_battlefield"
        for event, data in events
    )


if __name__ == "__main__":
    tests = [
        test_radiant_performer_uses_xmage_backed_partial_runtime_waiver,
        test_radiant_performer_enters_battlefield_and_reports_no_stack_target,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
