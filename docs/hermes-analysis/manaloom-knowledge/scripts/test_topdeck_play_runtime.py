#!/usr/bin/env python3
"""Focused runtime tests for top-library land play permissions."""

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
    spec = importlib.util.spec_from_file_location("battle_topdeck_play_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def basic_land(name="Plains", produces="W"):
    return {
        "name": name,
        "type_line": f"Basic Land - {name}",
        "effect": "land",
        "mana_produced": 1,
        "produces": produces,
    }


def dead_spell(name="Huge Spell"):
    return {
        "name": name,
        "type_line": "Sorcery",
        "effect": "draw_cards",
        "cmc": 99,
        "mana_cost": "{99}",
    }


def verge_rangers():
    return {
        "name": "Verge Rangers",
        "effect": "topdeck_play",
        "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
        "look_top_library_any_time": True,
        "play_lands_from_top_library": True,
        "play_from_top_condition": "opponent_controls_more_lands",
        "type_line": "Creature - Human Scout",
        "power": 3,
        "toughness": 3,
    }


def lens_of_clarity():
    return {
        "name": "Lens of Clarity",
        "effect": "topdeck_play",
        "battle_model_scope": "look_top_library_any_time_and_opponent_face_down_creatures_v1",
        "look_top_library_any_time": True,
        "look_opponent_face_down_creatures_any_time": True,
        "play_lands_from_top_library": False,
        "alternate_zone_permission": False,
        "may_cast_without_paying_mana_cost": False,
        "type_line": "Artifact",
        "cmc": 1,
    }


def player(battle, name, deck=None):
    return battle.Player(name, None, deck or [], strategy="midrange")


def run_turn_with_events(battle, active, opponent):
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            rng=random.Random(11),
            stack=battle.Stack(),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None
    return events


def test_verge_rangers_plays_top_library_land_when_opponent_has_more_lands():
    battle = load_battle()
    top_land = basic_land()
    active = player(battle, "Lorehold", [dead_spell(), top_land])
    active.battlefield.append(verge_rangers())
    opponent = player(battle, "Opponent")
    opponent.battlefield.extend([basic_land(), basic_land("Mountain", "R")])

    events = run_turn_with_events(battle, active, opponent)

    assert any(card.get("name") == "Plains" for card in active.battlefield)
    assert top_land not in active.library
    land_events = [data for event, data in events if event == "land_played"]
    assert land_events
    assert land_events[0]["card"] == "Plains"
    assert land_events[0]["source_zone"] == "library"
    assert land_events[0]["played_from_top_library"] is True
    assert land_events[0]["topdeck_play_source"] == "Verge Rangers"
    assert (
        land_events[0]["topdeck_play_scope"]
        == "look_top_library_play_lands_from_top_if_opponent_more_lands_v1"
    )


def test_verge_rangers_does_not_play_top_library_land_without_land_deficit():
    battle = load_battle()
    top_land = basic_land()
    active = player(battle, "Lorehold", [dead_spell(), top_land])
    active.battlefield.append(verge_rangers())
    opponent = player(battle, "Opponent")

    events = run_turn_with_events(battle, active, opponent)

    assert top_land in active.library
    assert not any(
        event == "land_played" and data.get("source_zone") == "library"
        for event, data in events
    )


def test_lens_of_clarity_enters_as_visibility_only_topdeck_play_permanent():
    battle = load_battle()
    active = player(battle, "Lorehold", [dead_spell(), basic_land()])
    opponent = player(battle, "Opponent")
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        effect = lens_of_clarity()
        battle.apply_effect_immediate(
            active,
            [opponent],
            effect,
            turn=1,
            rng=random.Random(607),
            effect_data_override=effect,
            stack=battle.Stack(),
            phase="main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    permanent = next(card for card in active.battlefield if card.get("name") == "Lens of Clarity")
    assert permanent["effect"] == "topdeck_play"
    assert permanent["look_top_library_any_time"] is True
    assert permanent["look_opponent_face_down_creatures_any_time"] is True
    assert permanent["play_lands_from_top_library"] is False
    assert permanent["may_cast_without_paying_mana_cost"] is False

    permission_events = [
        data for event, data in events if event == "topdeck_play_static_permission_entered"
    ]
    assert permission_events
    assert permission_events[0]["card"] == "Lens of Clarity"
    assert permission_events[0]["look_top_library_any_time"] is True
    assert permission_events[0]["look_opponent_face_down_creatures_any_time"] is True
    assert permission_events[0]["play_lands_from_top_library"] is False
    assert permission_events[0]["may_cast_without_paying_mana_cost"] is False
