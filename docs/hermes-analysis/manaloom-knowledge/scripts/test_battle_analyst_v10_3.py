#!/usr/bin/env python3
"""Focused regression checks for the v10.3 battle/replay fixes.

Run from this directory with:
    python3 test_battle_analyst_v10_3.py
"""

import importlib.util
import os
import random
from pathlib import Path


MODULE_PATH = Path(
    os.environ.get(
        "BATTLE_ANALYST_PATH",
        Path(__file__).with_name("battle_analyst_v8.py"),
    )
)
spec = importlib.util.spec_from_file_location("battle_under_test", MODULE_PATH)
battle = importlib.util.module_from_spec(spec)
spec.loader.exec_module(battle)


def card(name, cmc=99, effect="unknown", power=0):
    return {
        "name": name,
        "cmc": cmc,
        "tag": effect,
        "effect": effect,
        "type_line": "Creature" if effect == "creature" else "Sorcery",
        "power": power,
    }


def player(name, deck=None):
    return battle.Player(name, None, deck or [], strategy="midrange")


def test_sba_only_reports_new_elimination():
    dead = player("Dead")
    alive = player("Alive", [card("Library card")])
    dead.life = 0

    assert battle.check_sbas([alive, dead]) is True
    assert dead.eliminated is True
    assert battle.check_sbas([alive, dead]) is False


def test_cleanup_runs_with_previously_eliminated_player():
    active = player("Active", [card("Draw") for _ in range(5)])
    active.hand = [card(f"Expensive {index}") for index in range(10)]
    dead = player("Dead")
    dead.life = 0
    dead.eliminated = True

    battle.play_turn_v8(
        active,
        [dead],
        [active, dead],
        turn=3,
        rng=random.Random(1),
        stack=battle.Stack(),
    )

    assert len(active.hand) == 7


def test_draw_step_runs_once_with_multiple_permanents():
    active = player("Active", [card("Draw") for _ in range(5)])
    active.battlefield = [
        {"name": "Permanent A", "effect": "unknown"},
        {"name": "Permanent B", "effect": "unknown"},
    ]
    opponent = player("Opponent", [card("Opp Draw") for _ in range(5)])

    battle.play_turn_v8(
        active,
        [opponent],
        [active, opponent],
        turn=1,
        rng=random.Random(2),
        stack=battle.Stack(),
    )

    assert len(active.hand) == 1


def test_approach_sets_explicit_win_state():
    active = player("Active")
    opponent = player("Opponent")
    approach = {
        "name": "Approach of the Second Sun",
        "cmc": 7,
        "type_line": "Sorcery",
    }

    battle.apply_effect_immediate(active, [opponent], approach, 5, random.Random(3))
    assert active.has_won() is False
    battle.apply_effect_immediate(active, [opponent], approach, 6, random.Random(3))

    assert active.has_won() is True
    assert active.win_reason == "approach"


def test_combat_emits_structured_event():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    attacker = player("Attacker")
    defender = player("Defender")
    attacker.battlefield = [
        {
            "name": "Attacker Creature",
            "effect": "creature",
            "power": 3,
            "summoning_sick": False,
            "tapped": False,
        }
    ]

    battle.combat_phase_v8(
        attacker,
        [defender],
        [attacker, defender],
        turn=2,
        rng=random.Random(4),
        stack=battle.Stack(),
    )

    combat_events = [data for event, data in events if event == "combat"]
    assert len(combat_events) == 1
    assert combat_events[0]["attacker"] == "Attacker"
    assert combat_events[0]["target"] == "Defender"
    assert combat_events[0]["attackers"] == 1


def test_turn_stops_immediately_after_approach_win():
    active = player("Active", [card("Library card") for _ in range(10)])
    opponent = player("Opponent", [card("Opp Library") for _ in range(10)])
    active.approach_count = 1
    active.hand = [
        {
            "name": "Approach of the Second Sun",
            "cmc": 7,
            "type_line": "Sorcery",
        },
        {
            "name": "Must Stay In Hand",
            "cmc": 1,
            "tag": "draw",
            "type_line": "Sorcery",
        },
    ]
    active.battlefield = ["land" for _ in range(10)]

    battle.play_turn_v8(
        active,
        [opponent],
        [active, opponent],
        turn=5,
        rng=random.Random(5),
        stack=battle.Stack(),
    )

    assert active.has_won() is True
    assert any(card["name"] == "Must Stay In Hand" for card in active.hand)


if __name__ == "__main__":
    tests = [
        test_sba_only_reports_new_elimination,
        test_cleanup_runs_with_previously_eliminated_player,
        test_draw_step_runs_once_with_multiple_permanents,
        test_approach_sets_explicit_win_state,
        test_combat_emits_structured_event,
        test_turn_stops_immediately_after_approach_win,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
