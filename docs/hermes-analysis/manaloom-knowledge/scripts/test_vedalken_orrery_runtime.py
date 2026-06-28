#!/usr/bin/env python3
"""Focused runtime tests for Vedalken Orrery flash timing permission."""

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
    spec = importlib.util.spec_from_file_location("battle_orrery_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def orrery_card():
    return {
        "name": "Vedalken Orrery",
        "type_line": "Artifact",
        "mana_cost": "{4}",
        "cmc": 4,
    }


def test_vedalken_orrery_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(orrery_card())

    assert effect["effect"] == "flash_permission"
    assert effect["battle_model_scope"] == "nonland_spells_as_though_flash_static_v1"
    assert effect["artifact"] is True
    assert effect["mana_cost"] == "{4}"
    assert effect["cast_nonland_spells_as_flash"] is True
    assert effect["flash_permission_filter"] == "nonland_spells"
    assert effect["_rule_logical_key"] == "battle_rule_v1:9e2c7c96d5b2a117731924d511bb0e2a"
    assert effect["_rule_oracle_hash"] == "1fa2fc4b26db2e2d0691f8170d03b4db"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Vedalken Orrery" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_vedalken_orrery_allows_nonland_spells_outside_main_phase():
    battle = load_battle()
    active = player(battle, "Lorehold")
    creature = {
        "name": "Flashless Creature",
        "type_line": "Creature - Soldier",
        "cmc": 2,
    }
    sorcery = {
        "name": "Flashless Sorcery",
        "type_line": "Sorcery",
        "cmc": 3,
    }
    land = {
        "name": "Plains",
        "type_line": "Basic Land - Plains",
    }

    assert battle.can_cast_in_phase(creature, {"effect": "creature"}, "combat", controller=active) is False
    assert battle.can_cast_in_phase(sorcery, {"effect": "draw_cards"}, "combat", controller=active) is False
    assert battle.can_cast_in_phase(land, {"effect": "land"}, "combat", controller=active) is False

    active.battlefield = [{**orrery_card(), **battle.get_card_effect(orrery_card())}]

    assert battle.controller_casts_nonland_as_flash(active, creature) is True
    assert battle.can_cast_in_phase(creature, {"effect": "creature"}, "combat", controller=active) is True
    assert battle.can_cast_in_phase(sorcery, {"effect": "draw_cards"}, "combat", controller=active) is True
    assert battle.can_cast_in_phase(land, {"effect": "land"}, "combat", controller=active) is False


def test_vedalken_orrery_resolves_as_static_permission_permanent():
    battle = load_battle()
    active = player(battle, "Lorehold")
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        battle.apply_effect_immediate(
            active,
            [],
            orrery_card(),
            turn=4,
            rng=random.Random(613),
            effect_data_override=battle.get_card_effect(orrery_card()),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    permanent = next(
        card
        for card in active.battlefield
        if isinstance(card, dict) and card.get("name") == "Vedalken Orrery"
    )
    assert permanent["effect"] == "flash_permission"
    assert permanent["cast_nonland_spells_as_flash"] is True
    entered = next(
        data
        for event, data in events
        if event == "static_permission_entered" and data.get("card") == "Vedalken Orrery"
    )
    assert entered["permission"] == "cast_nonland_spells_as_flash"
    assert entered["rule_logical_key"] == "battle_rule_v1:9e2c7c96d5b2a117731924d511bb0e2a"


if __name__ == "__main__":
    test_vedalken_orrery_get_card_effect_is_runtime_source()
    test_vedalken_orrery_allows_nonland_spells_outside_main_phase()
    test_vedalken_orrery_resolves_as_static_permission_permanent()
    print("PASS test_vedalken_orrery_runtime")
