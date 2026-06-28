#!/usr/bin/env python3
"""Focused runtime tests for Slickshot Show-Off noncreature spell pump."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_slickshot_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def slickshot_card():
    return {
        "name": "Slickshot Show-Off",
        "type_line": "Creature - Bird Wizard",
        "mana_cost": "{1}{R}",
        "cmc": 2,
        "power": 1,
        "toughness": 2,
    }


def test_slickshot_showoff_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(slickshot_card())

    assert effect["effect"] == "creature"
    assert effect["battle_model_scope"] == "noncreature_spell_cast_boost_source_plus_2_0_until_eot_plot_v1"
    assert effect["flying"] is True
    assert effect["haste"] is True
    assert effect["trigger"] == "noncreature_spell_cast"
    assert effect["trigger_effect"] == "boost_source_until_eot"
    assert effect["trigger_power_bonus_until_eot"] == 2
    assert effect["plot"] is True
    assert effect["plot_cost"] == "{1}{R}"
    assert effect["_rule_logical_key"] == "battle_rule_v1:9fd2ff72170533330fc8ba9165bd99b4"
    assert effect["_rule_oracle_hash"] == "24ce626e7e7957d8e01f615ea00d9d08"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Slickshot Show-Off" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_slickshot_showoff_enters_as_hasty_flying_creature():
    battle = load_battle()
    controller = player(battle, "Lorehold")

    battle.apply_effect_immediate(
        controller,
        [],
        slickshot_card(),
        turn=3,
        rng=random.Random(616),
        effect_data_override=battle.get_card_effect(slickshot_card()),
    )

    permanent = next(card for card in controller.battlefield if card.get("name") == "Slickshot Show-Off")
    assert battle.is_battlefield_creature(permanent) is True
    assert permanent["flying"] is True
    assert permanent["haste"] is True
    assert permanent["summoning_sick"] is False
    assert permanent["power"] == 1
    assert permanent["toughness"] == 2


def test_slickshot_showoff_noncreature_spell_boosts_until_end_of_turn():
    battle = load_battle()
    controller = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    permanent = {**slickshot_card(), **battle.get_card_effect(slickshot_card())}
    controller.battlefield = [permanent]
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        battle.trigger_spell_cast_engines(
            controller,
            [controller, opponent],
            {"name": "Lightning Bolt", "type_line": "Instant", "cmc": 1},
            turn=4,
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert permanent["power"] == 3
    assert permanent["toughness"] == 2
    assert any(
        event == "trigger_resolved"
        and data.get("card") == "Slickshot Show-Off"
        and data.get("trigger") == "noncreature_spell_cast"
        and data.get("trigger_spell") == "Lightning Bolt"
        and data.get("effect") == "boost_source_until_eot"
        and data.get("power_bonus") == 2
        and data.get("power_before") == 1
        and data.get("power_after") == 3
        for event, data in events
    )

    battle.clear_until_eot(controller)
    assert permanent["power"] == 1
    assert permanent["toughness"] == 2


def test_slickshot_showoff_ignores_creature_spells():
    battle = load_battle()
    controller = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    permanent = {**slickshot_card(), **battle.get_card_effect(slickshot_card())}
    controller.battlefield = [permanent]

    battle.trigger_spell_cast_engines(
        controller,
        [controller, opponent],
        {"name": "Runeclaw Bear", "type_line": "Creature - Bear", "cmc": 2},
        turn=4,
        phase="precombat_main",
    )

    assert permanent["power"] == 1
    assert permanent["toughness"] == 2


if __name__ == "__main__":
    test_slickshot_showoff_get_card_effect_is_runtime_source()
    test_slickshot_showoff_enters_as_hasty_flying_creature()
    test_slickshot_showoff_noncreature_spell_boosts_until_end_of_turn()
    test_slickshot_showoff_ignores_creature_spells()
    print("PASS test_slickshot_showoff_runtime")
