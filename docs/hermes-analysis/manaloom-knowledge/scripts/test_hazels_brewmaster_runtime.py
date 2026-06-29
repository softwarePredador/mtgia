#!/usr/bin/env python3
"""Focused runtime tests for Hazel's Brewmaster."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_hazels_brewmaster_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def hazel_effect() -> dict:
    return {
        "effect": "creature",
        "ability_kind": "triggered_static",
        "battle_model_scope": (
            "etb_or_attack_exile_graveyard_card_create_food_share_exiled_creature_activated_abilities_v1"
        ),
        "power": 3,
        "toughness": 4,
        "keywords": ["menace"],
        "menace": True,
        "trigger": "enters_battlefield_or_attacks",
        "trigger_effect": "exile_graveyard_card_create_food",
        "hazel_brewmaster_etb_or_attack_exile_graveyard_card_create_food": True,
        "target_zone": "graveyard",
        "target_count_max": 1,
        "target_optional": True,
        "create_food_token": True,
        "foods_gain_activated_abilities_from_exiled_creatures": True,
    }


def hazel_card() -> dict:
    return {
        "name": "Hazel's Brewmaster",
        "type_line": "Creature — Squirrel Warlock",
        "cmc": 4,
        **hazel_effect(),
    }


def devoted_druid() -> dict:
    return {
        "name": "Devoted Druid",
        "type_line": "Creature — Elf Druid",
        "effect": "creature",
        "power": 0,
        "toughness": 2,
        "activated_add_mana": True,
        "activated_add_mana_color": "G",
        "is_mana_source": True,
        "mana_produced": 1,
        "mana_colors": ["G"],
    }


def test_hazel_etb_exiles_graveyard_creature_and_food_gains_activated_ability() -> None:
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Lorehold", None, [])
        opponent = battle.Player("Opponent", None, [])
        active.graveyard = [devoted_druid()]

        battle.apply_effect_immediate(
            active,
            [opponent],
            hazel_card(),
            turn=4,
            rng=random.Random(607),
            effect_data_override=hazel_effect(),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    hazel = next(card for card in active.battlefield if card.get("name") == "Hazel's Brewmaster")
    food = next(card for card in active.battlefield if card.get("name") == "Food Token")
    assert active.graveyard == []
    assert any(card.get("name") == "Devoted Druid" for card in active.exile)
    assert food["type_line"] == "Artifact Token — Food"
    assert food["activated_add_mana"] is True
    assert food["activated_add_mana_color"] == "G"
    assert "activated_add_mana" in food["hazel_brewmaster_activated_abilities_copied"]
    assert hazel["hazel_shared_activated_ability_fields"]["activated_add_mana"] is True
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Hazel's Brewmaster"
        and data.get("source_event") == "enters_battlefield"
        and data.get("exiled_card") == "Devoted Druid"
        and data.get("food_token") == "Food Token"
        for event, data in events
    )


def test_hazel_attack_trigger_creates_food_even_without_graveyard_target() -> None:
    battle = load_battle()
    active = battle.Player("Lorehold", None, [])
    opponent = battle.Player("Opponent", None, [])
    hazel = battle.prepare_entering_permanent(hazel_card(), controller=active, all_players=[active, opponent], turn=5)
    active.battlefield = [hazel]

    resolved = battle.resolve_hazels_brewmaster_attack_triggers(
        active,
        [hazel],
        [opponent],
        turn=5,
    )

    assert resolved == 1
    assert any(card.get("name") == "Food Token" for card in active.battlefield)
