#!/usr/bin/env python3
"""Focused runtime tests for The Warring Triad graveyard threshold and mana ability."""

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
    spec = importlib.util.spec_from_file_location("battle_warring_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def warring_card():
    return {
        "name": "The Warring Triad",
        "type_line": "Legendary Artifact Creature - God",
        "mana_cost": "{3}",
        "cmc": 3,
        "power": 5,
        "toughness": 5,
    }


def graveyard_cards(count):
    return [
        {"name": f"Graveyard Card {index}", "type_line": "Creature"}
        for index in range(count)
    ]


def test_the_warring_triad_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(warring_card())

    assert effect["effect"] == "ramp_permanent"
    assert effect["battle_model_scope"] == "legendary_artifact_creature_graveyard_threshold_self_mill_any_color_mana_v1"
    assert effect["is_mana_source"] is True
    assert effect["mana_produced"] == 1
    assert effect["produces"] == "WUBRG"
    assert effect["mana_activation_requires_tap"] is True
    assert effect["mana_activation_mill_count"] == 1
    assert effect["creature_if_graveyard_count_at_least"] == 8
    assert effect["_rule_logical_key"] == "battle_rule_v1:1b92340f98d8dd60da33dbd03e915d23"
    assert effect["_rule_oracle_hash"] == "4b71a0484cf31247d62e92ca0bf27efd"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "The Warring Triad" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_the_warring_triad_is_not_creature_before_graveyard_threshold():
    battle = load_battle()
    active = player(battle, "Lorehold")
    active.graveyard = graveyard_cards(7)

    battle.apply_effect_immediate(
        active,
        [],
        warring_card(),
        turn=4,
        rng=random.Random(610),
        effect_data_override=battle.get_card_effect(warring_card()),
    )

    permanent = next(card for card in active.battlefield if card.get("name") == "The Warring Triad")
    assert permanent["graveyard_count_creature_active"] is False
    assert permanent["creature_type_suppressed"] is True
    assert permanent["is_creature_permanent"] is False
    assert battle.is_battlefield_creature(permanent) is False
    assert permanent["is_mana_source"] is True


def test_the_warring_triad_becomes_creature_at_graveyard_threshold():
    battle = load_battle()
    active = player(battle, "Lorehold")
    active.graveyard = graveyard_cards(8)

    battle.apply_effect_immediate(
        active,
        [],
        warring_card(),
        turn=4,
        rng=random.Random(611),
        effect_data_override=battle.get_card_effect(warring_card()),
    )

    permanent = next(card for card in active.battlefield if card.get("name") == "The Warring Triad")
    assert permanent["graveyard_count_creature_active"] is True
    assert permanent.get("creature_type_suppressed") is None
    assert permanent["is_creature_permanent"] is True
    assert battle.is_battlefield_creature(permanent) is True
    assert permanent["power"] == 5
    assert permanent["toughness"] == 5
    assert permanent["flying"] is True
    assert permanent["trample"] is True
    assert permanent["haste"] is True
    assert permanent["summoning_sick"] is False


def test_the_warring_triad_mills_for_mana_and_updates_creature_static():
    battle = load_battle()
    active = player(battle, "Lorehold")
    active.graveyard = graveyard_cards(7)
    active.library = [
        {"name": "Milled Threshold Card", "type_line": "Sorcery"},
        {"name": "Next Library Card", "type_line": "Instant"},
    ]
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        battle.apply_effect_immediate(
            active,
            [],
            warring_card(),
            turn=4,
            rng=random.Random(612),
            effect_data_override=battle.get_card_effect(warring_card()),
        )
        permanent = next(card for card in active.battlefield if card.get("name") == "The Warring Triad")
        assert battle.is_battlefield_creature(permanent) is False

        active.refresh_mana_sources(turn=5)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    permanent = next(card for card in active.battlefield if card.get("name") == "The Warring Triad")
    assert active.available_mana() == 1
    assert permanent["tapped"] is True
    assert active.graveyard[-1]["name"] == "Milled Threshold Card"
    assert len(active.library) == 1
    assert permanent["graveyard_count_creature_active"] is True
    assert battle.is_battlefield_creature(permanent) is True

    assert any(
        event == "mana_source_mill_cost_paid"
        and data.get("card") == "The Warring Triad"
        and data.get("mill_count") == 1
        for event, data in events
    )
    assert any(
        event == "static_graveyard_count_creature_state_changed"
        and data.get("card") == "The Warring Triad"
        and data.get("active") is True
        for event, data in events
    )


if __name__ == "__main__":
    test_the_warring_triad_get_card_effect_is_runtime_source()
    test_the_warring_triad_is_not_creature_before_graveyard_threshold()
    test_the_warring_triad_becomes_creature_at_graveyard_threshold()
    test_the_warring_triad_mills_for_mana_and_updates_creature_static()
    print("PASS test_the_warring_triad_runtime")
