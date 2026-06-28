#!/usr/bin/env python3
"""Focused runtime tests for Serra Ascendant life-total threshold static."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_serra_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def serra_card():
    return {
        "name": "Serra Ascendant",
        "type_line": "Creature - Human Monk",
        "mana_cost": "{W}",
        "cmc": 1,
        "power": 1,
        "toughness": 1,
    }


def put_serra(battle, controller, *, life):
    controller.life = life
    battle.apply_effect_immediate(
        controller,
        [],
        serra_card(),
        turn=2,
        rng=random.Random(616),
        effect_data_override=battle.get_card_effect(serra_card()),
    )
    return next(card for card in controller.battlefield if card.get("name") == "Serra Ascendant")


def test_serra_ascendant_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(serra_card())

    assert effect["effect"] == "creature"
    assert effect["battle_model_scope"] == "controller_life_total_30_plus_self_plus_5_5_flying_static_v1"
    assert effect["lifelink"] is True
    assert effect["life_total_threshold"] == 30
    assert effect["life_total_threshold_power_bonus"] == 5
    assert effect["life_total_threshold_toughness_bonus"] == 5
    assert effect["life_total_threshold_grants"] == ["flying"]
    assert effect["_rule_logical_key"] == "battle_rule_v1:c3124030acfa1668606aca59dbbb7e2e"
    assert effect["_rule_oracle_hash"] == "a08a773363e4484f37512d57594b56eb"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Serra Ascendant" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_serra_ascendant_enters_as_6_6_flying_at_30_or_more_life():
    battle = load_battle()
    controller = player(battle, "Lorehold")

    permanent = put_serra(battle, controller, life=40)

    assert battle.is_battlefield_creature(permanent) is True
    assert permanent["lifelink"] is True
    assert permanent["power"] == 6
    assert permanent["toughness"] == 6
    assert permanent["flying"] is True
    assert permanent["_life_total_threshold_active"] is True


def test_serra_ascendant_enters_as_1_1_without_flying_below_threshold():
    battle = load_battle()
    controller = player(battle, "Lorehold")

    permanent = put_serra(battle, controller, life=29)

    assert permanent["lifelink"] is True
    assert permanent["power"] == 1
    assert permanent["toughness"] == 1
    assert not permanent.get("flying")
    assert permanent["_life_total_threshold_active"] is False


def test_serra_ascendant_refreshes_when_life_crosses_threshold():
    battle = load_battle()
    controller = player(battle, "Lorehold")
    permanent = put_serra(battle, controller, life=29)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        battle.gain_life(controller, 1, cap=999)
        assert controller.life == 30
        assert permanent["power"] == 6
        assert permanent["toughness"] == 6
        assert permanent["flying"] is True
        assert permanent["_life_total_threshold_active"] is True

        battle.deal_damage(controller, 1, source={"name": "Shock"})
        assert controller.life == 29
        assert permanent["power"] == 1
        assert permanent["toughness"] == 1
        assert permanent["flying"] is False
        assert permanent["_life_total_threshold_active"] is False
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    threshold_events = [
        data
        for event, data in events
        if event == "static_life_total_threshold_state_changed"
        and data.get("card") == "Serra Ascendant"
    ]
    assert [event["active"] for event in threshold_events] == [True, False]
    assert threshold_events[0]["controller_life"] == 30
    assert threshold_events[0]["power_after"] == 6
    assert threshold_events[1]["controller_life"] == 29
    assert threshold_events[1]["power_after"] == 1


if __name__ == "__main__":
    test_serra_ascendant_get_card_effect_is_runtime_source()
    test_serra_ascendant_enters_as_6_6_flying_at_30_or_more_life()
    test_serra_ascendant_enters_as_1_1_without_flying_below_threshold()
    test_serra_ascendant_refreshes_when_life_crosses_threshold()
