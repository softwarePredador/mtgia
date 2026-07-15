#!/usr/bin/env python3
"""Focused runtime coverage for Covercast and intensity-based mana."""

from __future__ import annotations

import importlib.util
import json
import random
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
REVIEWED_RULES_PATH = SCRIPT_DIR / "reviewed_battle_card_rules.json"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_battle():
    spec = importlib.util.spec_from_file_location(
        "battle_digital_covercast_under_test",
        BATTLE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def summitfest_rule():
    payload = json.loads(REVIEWED_RULES_PATH.read_text(encoding="utf-8"))
    return payload["Summitfest Closing Ceremony"]


def player(battle, name, deck=None):
    return battle.Player(name, None, deck or [], strategy="midrange")


def test_summitfest_reviewed_rule_has_runtime_and_oracle_contract():
    rule = summitfest_rule()
    effect = rule["effect_json"]

    assert rule["review_status"] == "verified"
    assert rule["execution_status"] == "auto"
    assert rule["oracle_hash"] == "9e107e0def32cfdd7711d49a7166f6c2"
    assert effect["starting_intensity"] == 3
    assert effect[
        "covercast_intensify_on_other_instant_sorcery_mana_spent_at_least"
    ] == 5
    assert effect["components"][0]["mana_produced_from_source_intensity"] is True
    assert effect["components"][0]["produced_mana_symbols_each_from_intensity"] == [
        "U",
        "R",
    ]
    assert effect["components"][1] == {"effect": "draw_cards", "count": 1}


def test_commit_cast_payment_records_actual_mana_spent():
    battle = load_battle()
    controller = player(battle, "Controller")
    controller.mana_pool.add_generic(5)
    spell = {
        "name": "Five Mana Test Spell",
        "type_line": "Sorcery",
        "mana_cost": "{5}",
        "cmc": 5,
        "effect": "draw_cards",
    }

    context = battle.begin_cast_context(
        controller,
        spell,
        "precombat_main",
        effect_data={"effect": "draw_cards", "count": 1},
    )

    assert battle.commit_cast_payment(context) is True
    assert spell["_mana_spent_to_cast"] == 5
    assert spell["_cast_context"]["mana_spent_to_cast"] == 5
    assert context.effect_data["_mana_spent_to_cast"] == 5


def test_covercast_uses_mana_spent_and_intensifies_only_at_threshold():
    battle = load_battle()
    controller = player(battle, "Controller")
    opponent = player(battle, "Opponent")
    summitfest = {
        "name": "Summitfest Closing Ceremony",
        **summitfest_rule()["effect_json"],
    }
    controller.hand = [summitfest]
    events = []
    old_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        four_mana_spell = {
            "name": "Four Mana Spell",
            "type_line": "Instant",
            "_mana_spent_to_cast": 4,
        }
        assert battle.process_covercast_intensity_from_hand(
            controller,
            [controller, opponent],
            four_mana_spell,
            turn=2,
            phase="precombat_main",
        ) == 0
        assert "_intensity" not in summitfest

        for turn, amount in ((3, 5), (4, 6)):
            expensive_spell = {
                "name": f"Expensive Spell {turn}",
                "type_line": "Sorcery",
                "_mana_spent_to_cast": amount,
            }
            assert battle.process_covercast_intensity_from_hand(
                controller,
                [controller, opponent],
                expensive_spell,
                turn=turn,
                phase="precombat_main",
            ) == 1
    finally:
        battle.REPLAY_EVENT_HANDLER = old_handler

    assert summitfest["_intensity"] == 5
    intensity_events = [data for event, data in events if event == "covercast_intensified"]
    assert [event["intensity_after"] for event in intensity_events] == [4, 5]
    assert [event["mana_spent"] for event in intensity_events] == [5, 6]


def test_summitfest_resolution_adds_each_color_per_intensity_and_draws():
    battle = load_battle()
    controller = player(
        battle,
        "Controller",
        deck=[{"name": "Drawn Card", "type_line": "Creature"}],
    )
    opponent = player(battle, "Opponent")
    card = {
        "name": "Summitfest Closing Ceremony",
        "type_line": "Instant",
        "mana_cost": "{3}{U}{R}",
        "cmc": 5,
        "_intensity": 5,
    }

    battle.apply_effect_immediate(
        controller,
        [opponent],
        card,
        turn=7,
        rng=random.Random(7),
        effect_data_override=summitfest_rule()["effect_json"],
        phase="resolution",
    )

    assert controller.mana_pool.blue == 5
    assert controller.mana_pool.red == 5
    assert controller.mana_pool.total() == 10
    assert [drawn.get("name") for drawn in controller.hand] == ["Drawn Card"]
    assert card in controller.graveyard


if __name__ == "__main__":
    test_summitfest_reviewed_rule_has_runtime_and_oracle_contract()
    test_commit_cast_payment_records_actual_mana_spent()
    test_covercast_uses_mana_spent_and_intensifies_only_at_threshold()
    test_summitfest_resolution_adds_each_color_per_intensity_and_draws()
    print("PASS test_digital_covercast_intensity_runtime")
