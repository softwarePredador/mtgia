#!/usr/bin/env python3
"""Focused runtime tests for Planetarium of Wan Shi Tong."""

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
    spec = importlib.util.spec_from_file_location("battle_planetarium_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def lorehold_engine():
    return {
        "name": "Lorehold, the Historian",
        "type_line": "Legendary Creature",
        "effect": "creature",
        "opponent_upkeep_rummage": True,
    }


def planetarium_permanent(battle):
    effect = battle.get_card_effect(
        {
            "name": "Planetarium of Wan Shi Tong",
            "type_line": "Legendary Artifact",
            "cmc": 6,
            "mana_cost": "{6}",
        }
    )
    return {"name": "Planetarium of Wan Shi Tong", "type_line": "Legendary Artifact", **effect}


def ponder():
    return {"name": "Ponder", "type_line": "Sorcery", "cmc": 1, "mana_cost": "{U}"}


def mountain():
    return {"name": "Mountain", "type_line": "Basic Land - Mountain", "effect": "land", "cmc": 0}


def test_planetarium_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(
        {
            "name": "Planetarium of Wan Shi Tong",
            "type_line": "Legendary Artifact",
            "cmc": 6,
            "mana_cost": "{6}",
        }
    )

    assert effect["effect"] == "topdeck_manipulation"
    assert effect["activation_cost_generic"] == 1
    assert effect["activation_requires_tap"] is True
    assert effect["activated_scry_count"] == 2
    assert effect["scry_or_surveil_top_library_free_cast_once_each_turn"] is True
    assert effect["battle_model_scope"] == "scry_or_surveil_once_turn_top_library_free_cast_v1"
    assert effect["_rule_logical_key"] == "battle_rule_v1:a2082ebdf6e7e169b97eccecbb22b36a"
    assert effect["_rule_oracle_hash"] == "67433ff9a3bb75652404373a2949a53a"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"


def test_planetarium_activates_scry_then_free_casts_top_card_once():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        planetarium = planetarium_permanent(battle)
        active.battlefield = [lorehold_engine(), planetarium]
        active.library = [
            mountain(),
            ponder(),
            {"name": "Drawn Card", "type_line": "Sorcery", "cmc": 1, "effect": "draw_cards"},
        ]
        active.mana_pool.add_generic(1)

        activated = battle.activate_lorehold_topdeck_artifacts(
            active,
            turn=7,
            rng=random.Random(611),
            phase="upkeep",
            all_players=[active, opponent],
            stack=battle.Stack(),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert activated == 1
    assert planetarium["tapped"] is True
    assert planetarium["utility_artifact_used_this_turn"] is True
    assert planetarium["planetarium_top_free_cast_last_turn"] == 7
    assert active.available_mana() == 0
    assert any(card.get("name") == "Ponder" for card in active.graveyard)
    assert all(card.get("name") != "Ponder" for card in active.library)
    assert any(
        event == "topdeck_manipulation_activated"
        and data.get("card") == "Planetarium of Wan Shi Tong"
        and data.get("activation_kind") == "planetarium_scry_then_top_free_cast"
        and data.get("scry_top_after", [None])[0] == "Ponder"
        for event, data in events
    )
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Planetarium of Wan Shi Tong"
        and data.get("trigger") == "scry"
        and data.get("looked_card") == "Ponder"
        and data.get("result") == "cast_without_paying_mana"
        and data.get("cast_without_paying_mana_cost") is True
        for event, data in events
    )
    assert any(
        event == "spell_cast"
        and data.get("card") == "Ponder"
        and data.get("source_zone") == "library"
        and data.get("locked_cost", {}).get("spend_tags") == ["cast_without_paying_mana_cost"]
        for event, data in events
    )


def test_planetarium_trigger_is_once_each_turn():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        planetarium = planetarium_permanent(battle)
        active.battlefield = [lorehold_engine(), planetarium]
        active.library = [ponder(), mountain()]

        first = battle.resolve_planetarium_scry_or_surveil_trigger(
            active,
            planetarium,
            opponents=[opponent],
            all_players=[active, opponent],
            turn=8,
            rng=random.Random(613),
            phase="upkeep",
            stack=battle.Stack(),
            trigger_event="scry",
        )
        active.library = [ponder(), mountain()]
        second = battle.resolve_planetarium_scry_or_surveil_trigger(
            active,
            planetarium,
            opponents=[opponent],
            all_players=[active, opponent],
            turn=8,
            rng=random.Random(614),
            phase="upkeep",
            stack=battle.Stack(),
            trigger_event="surveil",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert first is True
    assert second is False
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Planetarium of Wan Shi Tong"
        and data.get("trigger") == "surveil"
        and data.get("result") == "once_each_turn_already_used"
        for event, data in events
    )


if __name__ == "__main__":
    test_planetarium_get_card_effect_is_runtime_source()
    test_planetarium_activates_scry_then_free_casts_top_card_once()
    test_planetarium_trigger_is_once_each_turn()
    print("PASS test_planetarium_runtime")
