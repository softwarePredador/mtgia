#!/usr/bin/env python3
"""Focused runtime tests for Unstable Glyphbridge selective ETB wipe semantics."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_glyphbridge_under_test", BATTLE_PATH)
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


def glyphbridge_card():
    return {
        "name": "Unstable Glyphbridge // Sandswirl Wanderglyph",
        "type_line": "Artifact",
        "cmc": 5,
        "mana_cost": "{3}{W}{W}",
    }


def cast_glyphbridge(battle, active, opponents, turn=5):
    card = glyphbridge_card()
    battle.apply_effect_immediate(
        active,
        opponents,
        card,
        turn=turn,
        rng=random.Random(616),
        effect_data_override=battle.get_card_effect(card),
    )
    return next(
        permanent
        for permanent in active.battlefield
        if permanent["name"] == "Unstable Glyphbridge // Sandswirl Wanderglyph"
    )


def names(zone):
    return [card.get("name") for card in zone]


def test_unstable_glyphbridge_uses_xmage_backed_manual_runtime_waiver():
    battle = load_battle()
    effect = battle.get_card_effect(glyphbridge_card())

    assert "Unstable Glyphbridge // Sandswirl Wanderglyph" in battle.MANUAL_RULE_RUNTIME_WAIVERS
    assert effect["effect"] == "glyphbridge_selective_creature_wipe"
    assert effect["etb_if_cast"] is True
    assert effect["choose_one_small_creature_each_player_power_max"] == 2
    assert effect["destroy_all_other_creatures"] is True
    assert effect["craft_with_artifact"] == "{3}{W}{W}"
    assert effect["back_face_name"] == "Sandswirl Wanderglyph"
    assert effect["back_face_type_line"] == "Artifact Creature - Golem"
    assert effect["back_face_power"] == 5
    assert effect["back_face_toughness"] == 3
    assert effect["back_face_flying"] is True
    assert effect["battle_model_scope"] == "etb_choose_small_creature_each_player_destroy_rest_craft_metadata_v1"
    assert effect["_rule_oracle_hash"] == "e56f55f81b1f72be8c4e3752f1916898"
    assert effect["_rule_logical_key"] == "battle_rule_v1:f4168e92445f0a9b9b2de0ef32f4b78d"
    waiver = next(
        row
        for row in battle.manual_runtime_waiver_inventory()
        if row["card"] == "Unstable Glyphbridge // Sandswirl Wanderglyph"
    )
    assert waiver["effect"] == "glyphbridge_selective_creature_wipe"
    assert waiver["promotion_target"] == "card_battle_rules"
    assert "UnstableGlyphbridge.java" in waiver["source_runs"]


def test_unstable_glyphbridge_etb_keeps_one_small_creature_each_player_and_destroys_rest():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.battlefield = [
            creature("Lorehold Apprentice", power=2, toughness=3),
            creature("Lorehold Giant", power=5, toughness=5),
        ]
        opponent.battlefield = [
            creature("Opponent Utility", power=1, toughness=1),
            creature("Opponent Dragon", power=6, toughness=6),
        ]

        permanent = cast_glyphbridge(battle, active, [opponent])
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert permanent["effect"] == "passive"
    assert permanent["type_line"] == "Artifact"
    assert names(active.battlefield) == [
        "Lorehold Apprentice",
        "Unstable Glyphbridge // Sandswirl Wanderglyph",
    ]
    assert names(opponent.battlefield) == ["Opponent Utility"]
    assert names(active.graveyard) == ["Lorehold Giant"]
    assert names(opponent.graveyard) == ["Opponent Dragon"]
    assert any(
        event == "glyphbridge_selective_creature_wipe_resolved"
        and data["chosen_count"] == 2
        and data["destroyed"] == 2
        and data["protected"] == 0
        and data["own_creatures_destroyed"] == 1
        and data["live_opponent_creatures_destroyed"] == 1
        for event, data in events
    )


def test_unstable_glyphbridge_respects_indestructible_nonchosen_creatures():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.battlefield = [
            creature("Small Keeper", power=2, toughness=2),
            creature("Indestructible Threat", power=7, toughness=7, indestructible=True),
        ]
        opponent.battlefield = [
            creature("Opponent Small Keeper", power=1, toughness=3),
            creature("Opponent Large", power=4, toughness=4),
        ]

        cast_glyphbridge(battle, active, [opponent])
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert "Small Keeper" in names(active.battlefield)
    assert "Indestructible Threat" in names(active.battlefield)
    assert "Opponent Small Keeper" in names(opponent.battlefield)
    assert "Opponent Large" not in names(opponent.battlefield)
    assert "Opponent Large" in names(opponent.graveyard)
    resolution = next(
        data
        for event, data in events
        if event == "glyphbridge_selective_creature_wipe_resolved"
    )
    assert resolution["destroyed"] == 1
    assert resolution["protected"] == 1
    assert resolution["protected_cards"][0]["name"] == "Indestructible Threat"


def test_unstable_glyphbridge_no_small_creature_player_loses_all_destroyable_creatures():
    battle = load_battle()
    active = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    active.battlefield = [
        creature("Lorehold Giant One", power=5, toughness=5),
        creature("Lorehold Giant Two", power=4, toughness=4),
    ]
    opponent.battlefield = [creature("Opponent Utility", power=1, toughness=1)]

    cast_glyphbridge(battle, active, [opponent])

    assert names(active.battlefield) == ["Unstable Glyphbridge // Sandswirl Wanderglyph"]
    assert names(active.graveyard) == ["Lorehold Giant One", "Lorehold Giant Two"]
    assert names(opponent.battlefield) == ["Opponent Utility"]


if __name__ == "__main__":
    tests = [
        test_unstable_glyphbridge_uses_xmage_backed_manual_runtime_waiver,
        test_unstable_glyphbridge_etb_keeps_one_small_creature_each_player_and_destroys_rest,
        test_unstable_glyphbridge_respects_indestructible_nonchosen_creatures,
        test_unstable_glyphbridge_no_small_creature_player_loses_all_destroyable_creatures,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
