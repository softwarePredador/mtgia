#!/usr/bin/env python3
"""Focused runtime tests for Alhammarret's Archive replacement effects."""

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
    spec = importlib.util.spec_from_file_location("battle_alhammarret_archive_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def archive_effect():
    return {
        "effect": "draw_engine",
        "ability_kind": "static",
        "permanent_type": "artifact",
        "legendary": True,
        "draw_on_enter": False,
        "battle_model_scope": "static_double_life_gain_and_draw_except_first_draw_step_v1",
        "life_gain_replacement_double": True,
        "life_gain_multiplier": 2,
        "draw_replacement_double_except_first_draw_step": True,
        "draw_replacement_amount_multiplier": 2,
        "draw_replacement_controller_only": True,
        "draw_replacement_first_draw_step_exception": True,
    }


def library_cards(count=8):
    return [
        {"name": f"Audit Card {index}", "type_line": "Sorcery", "cmc": 1}
        for index in range(count)
    ]


def put_archive_on_battlefield(battle, active, opponent, events):
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    card = {"name": "Alhammarret's Archive", "type_line": "Legendary Artifact", "cmc": 5, "mana_cost": "{5}"}
    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=9,
        rng=random.Random(611),
        effect_data_override=archive_effect(),
        stack=battle.Stack(),
        phase="precombat_main",
    )
    return active.battlefield[0]


def test_alhammarrets_archive_enters_without_drawing_and_doubles_life_gain():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.library = library_cards()
        active.life = 30

        permanent = put_archive_on_battlefield(battle, active, opponent, events)
        gained = battle.gain_life(active, 3, cap=40)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert permanent["effect"] == "draw_engine"
    assert permanent["draw_on_enter"] is False
    assert len(active.hand) == 0
    assert gained is True
    assert active.life == 36
    assert any(
        event == "life_gain_replacement_applied"
        and data.get("card") == "Alhammarret's Archive"
        and data.get("original_amount") == 3
        and data.get("final_amount") == 6
        for event, data in events
    )


def test_alhammarrets_archive_draw_replacement_respects_draw_step_exception():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.library = library_cards(10)
        put_archive_on_battlefield(battle, active, opponent, events)

        battle.CURRENT_REPLAY_TURN = 10
        first_draw_step = active.draw(1, random.Random(10), phase="draw_step")
        second_draw_step = active.draw(1, random.Random(10), phase="draw_step")
        main_phase_draw = active.draw(1, random.Random(10), phase="precombat_main")
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert len(first_draw_step) == 1
    assert len(second_draw_step) == 2
    assert len(main_phase_draw) == 2
    assert len(active.hand) == 5
    draw_replacements = [
        data for event, data in events if event == "draw_replacement_applied"
    ]
    assert len(draw_replacements) == 2
    assert all(data.get("final_draw_count") == 2 for data in draw_replacements)
    assert draw_replacements[0]["phase"] == "draw_step"
    assert draw_replacements[1]["phase"] == "precombat_main"


if __name__ == "__main__":
    test_alhammarrets_archive_enters_without_drawing_and_doubles_life_gain()
    test_alhammarrets_archive_draw_replacement_respects_draw_step_exception()
    print("PASS test_alhammarrets_archive_runtime")
