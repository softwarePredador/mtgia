#!/usr/bin/env python3
"""Focused runtime tests for XMage-backed life-total change effects."""

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
    spec = importlib.util.spec_from_file_location("battle_life_total_change_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def spell(name, type_line, cmc, mana_cost):
    return {
        "name": name,
        "type_line": type_line,
        "cmc": cmc,
        "mana_cost": mana_cost,
    }


def filler(index):
    return {"name": f"Library Card {index}", "type_line": "Sorcery", "cmc": 1}


def test_life_total_change_rules_are_xmage_backed_runtime_waivers():
    battle = load_battle()

    expected = {
        "Invincible Hymn": {
            "oracle_hash": "1ef3fc195072cd1c0c2f7dd03fa875f6",
            "logical_key": "battle_rule_v1:de6504fa068c924a1bad5f1ada35a026",
            "scope": "controller_life_total_becomes_library_size_v1",
        },
        "Heroes Remembered": {
            "oracle_hash": "0a349cd92e9d1e5f0f4887e6f12c75b7",
            "logical_key": "battle_rule_v1:4978416393dc912bc2d6d090afde8dc8",
            "scope": "controller_gain_20_life_suspend_10_w_v1",
        },
        "Beacon of Immortality": {
            "oracle_hash": "642c17cb019f4299d5af9954f812f8a6",
            "logical_key": "battle_rule_v1:655c7da1b9d381d24b94b64487226598",
            "scope": "double_target_player_life_total_shuffle_self_v1",
        },
    }

    for card_name, fields in expected.items():
        effect = battle.get_card_effect({"name": card_name, "type_line": "Sorcery", "cmc": 8})
        assert effect["effect"] == "life_total_change"
        assert effect["battle_model_scope"] == fields["scope"]
        assert effect["_rule_oracle_hash"] == fields["oracle_hash"]
        assert effect["_rule_logical_key"] == fields["logical_key"]
        assert effect["_rule_review_status"] == "verified"
        assert effect["_rule_execution_status"] == "auto"
        assert card_name in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_invincible_hymn_sets_life_to_library_size_without_cap():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        active.life = 12
        active.library = [filler(index) for index in range(55)]
        card = spell("Invincible Hymn", "Sorcery", 8, "{6}{W}{W}")

        battle.apply_effect_immediate(
            active,
            opponents=[],
            card=card,
            turn=9,
            rng=random.Random(610),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert active.life == 55
    assert any(grave_card.get("name") == "Invincible Hymn" for grave_card in active.graveyard)
    assert any(
        event == "life_total_changed"
        and data.get("card") == "Invincible Hymn"
        and data.get("mode") == "life_total_becomes_library_size"
        and data.get("requested_delta") == 43
        and data.get("life_after") == 55
        for event, data in events
    )


def test_heroes_remembered_gains_20_life_without_cap():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        active.life = 39
        card = spell("Heroes Remembered", "Sorcery", 9, "{6}{W}{W}{W}")

        battle.apply_effect_immediate(
            active,
            opponents=[],
            card=card,
            turn=10,
            rng=random.Random(614),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert active.life == 59
    assert any(grave_card.get("name") == "Heroes Remembered" for grave_card in active.graveyard)
    assert any(
        event == "life_total_changed"
        and data.get("card") == "Heroes Remembered"
        and data.get("mode") == "gain_life"
        and data.get("requested_delta") == 20
        and data.get("life_after") == 59
        for event, data in events
    )


def test_beacon_doubles_life_and_shuffles_self():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        active.life = 23
        active.library = [filler(index) for index in range(7)]
        card = spell("Beacon of Immortality", "Instant", 6, "{5}{W}")

        battle.apply_effect_immediate(
            active,
            opponents=[],
            card=card,
            turn=8,
            rng=random.Random(615),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert active.life == 46
    assert any(library_card.get("name") == "Beacon of Immortality" for library_card in active.library)
    assert all(grave_card.get("name") != "Beacon of Immortality" for grave_card in active.graveyard)
    assert any(
        event == "life_total_changed"
        and data.get("card") == "Beacon of Immortality"
        and data.get("mode") == "double_target_player_life_total"
        and data.get("requested_delta") == 23
        and data.get("life_after") == 46
        for event, data in events
    )
    assert any(
        event == "spell_shuffled_into_library_on_resolution"
        and data.get("card") == "Beacon of Immortality"
        for event, data in events
    )


if __name__ == "__main__":
    test_life_total_change_rules_are_xmage_backed_runtime_waivers()
    test_invincible_hymn_sets_life_to_library_size_without_cap()
    test_heroes_remembered_gains_20_life_without_cap()
    test_beacon_doubles_life_and_shuffles_self()
    print("PASS test_life_total_change_runtime")
