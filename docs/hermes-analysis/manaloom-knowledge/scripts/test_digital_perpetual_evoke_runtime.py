#!/usr/bin/env python3
"""Focused runtime coverage for Aquatic Subtlety and perpetual Evoke."""

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
        "battle_digital_perpetual_evoke_under_test",
        BATTLE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def aquatic_rule():
    payload = json.loads(REVIEWED_RULES_PATH.read_text(encoding="utf-8"))
    return payload["Aquatic Subtlety"]


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def test_aquatic_rule_uses_current_oracle_and_executable_family():
    rule = aquatic_rule()
    effect = rule["effect_json"]

    assert rule["review_status"] == "verified"
    assert rule["execution_status"] == "auto"
    assert rule["oracle_hash"] == "0b3135c67536802f25423c4b0cc758ae"
    assert effect["effect"] == "draw_bottom_perpetual_evoke"
    assert effect["draw_count"] == 2
    assert effect["bottom_from_hand_count"] == 2
    assert effect["perpetual_evoke_creature_color"] == "U"
    assert effect["perpetual_evoke_exile_card_color"] == "U"


def test_aquatic_draws_bottoms_then_grants_only_remaining_blue_creatures():
    battle = load_battle()
    controller = player(battle, "Controller")
    opponent = player(battle, "Opponent")
    blue_creature = {
        "name": "Blue Creature",
        "mana_cost": "{U}",
        "cmc": 1,
        "colors": ["U"],
        "type_line": "Creature - Test",
        "effect": "creature",
        "power": 1,
        "toughness": 1,
    }
    red_creature = {
        "name": "Red Creature",
        "mana_cost": "{R}",
        "cmc": 1,
        "colors": ["R"],
        "type_line": "Creature - Test",
        "effect": "creature",
        "power": 1,
        "toughness": 1,
    }
    high_cost_one = {
        "name": "High Cost One",
        "mana_cost": "{10}",
        "cmc": 10,
        "type_line": "Artifact",
        "effect": "artifact",
    }
    high_cost_two = {
        "name": "High Cost Two",
        "mana_cost": "{9}",
        "cmc": 9,
        "type_line": "Artifact",
        "effect": "artifact",
    }
    controller.hand = [blue_creature, red_creature]
    controller.library = [high_cost_one, high_cost_two, {"name": "Library Tail"}]
    source = {"name": "Aquatic Subtlety", "type_line": "Sorcery"}

    result = battle.resolve_draw_bottom_perpetual_evoke_spell(
        controller,
        [opponent],
        source,
        aquatic_rule()["effect_json"],
        turn=4,
        rng=random.Random(4),
        phase="resolution",
    )

    assert [card["name"] for card in result["drawn"]] == ["High Cost One", "High Cost Two"]
    assert {card["name"] for card in result["bottomed"]} == {"High Cost One", "High Cost Two"}
    assert [card["name"] for card in controller.hand] == ["Blue Creature", "Red Creature"]
    assert [card["name"] for card in controller.library[-2:]] == [
        card["name"] for card in result["bottomed"]
    ]
    assert battle.perpetual_evoke_ability(blue_creature)["exile_card_color"] == "U"
    assert battle.perpetual_evoke_ability(red_creature) is None
    assert source in controller.graveyard


def test_perpetual_evoke_cast_exiles_blue_card_runs_etb_then_sacrifices():
    battle = load_battle()
    controller = player(battle, "Controller")
    opponent = player(battle, "Opponent")
    creature = {
        "name": "Expensive Blue ETB Creature",
        "mana_cost": "{6}{U}{U}",
        "cmc": 8,
        "colors": ["U"],
        "type_line": "Creature - Test",
        "effect": "creature",
        "power": 6,
        "toughness": 6,
    }
    fodder = {
        "name": "Blue Fodder",
        "mana_cost": "{U}",
        "cmc": 1,
        "colors": ["U"],
        "type_line": "Instant",
        "effect": "draw_cards",
    }
    drawn_on_etb = {"name": "ETB Draw"}
    controller.hand = [creature, fodder]
    controller.library = [drawn_on_etb]
    assert battle.grant_perpetual_evoke_to_card(
        creature,
        exile_card_color="U",
        source="Aquatic Subtlety",
    ) is True

    effect = {
        "effect": "creature",
        "etb_draw_count": 1,
        "battle_model_scope": "unit_test_etb_creature_v1",
    }
    plan = battle.runtime_cast_plan_for_card(controller, creature, effect)
    assert plan is not None
    assert plan["alternative_cost"] == "{0}"
    assert plan["alternative_cost_kind"] == battle.PERPETUAL_EVOKE_EXILE_CARD_KIND
    assert plan["cost_context"]["perpetual_evoke"]["exile_card"] is fodder

    cast_context = battle.begin_cast_context(
        controller,
        creature,
        "precombat_main",
        effect_data=effect,
        role="creature",
        modes=plan["modes"],
        alternative_cost=plan["alternative_cost"],
        alternative_cost_kind=plan["alternative_cost_kind"],
        additional_costs=plan["additional_costs"],
        locked_cost_override=plan["locked_cost"],
    )
    assert battle.commit_cast_payment(cast_context) is True
    controller.hand.remove(creature)
    assert battle.pay_additional_card_costs(
        controller,
        creature,
        effect,
        turn=5,
        cost_context=plan["cost_context"],
    ) is True
    assert fodder in controller.exile
    assert creature["_evoke_cost_paid"] is True

    battle.apply_effect_immediate(
        controller,
        [opponent],
        creature,
        turn=5,
        rng=random.Random(5),
        effect_data_override=effect,
        phase="resolution",
    )

    assert drawn_on_etb in controller.hand
    assert not controller.battlefield
    assert [card["name"] for card in controller.graveyard] == [
        "Expensive Blue ETB Creature"
    ]
    graveyard_card = controller.graveyard[0]
    assert graveyard_card["_evoke_cost_paid"] is True
    assert battle.perpetual_evoke_ability(graveyard_card)["source"] == "Aquatic Subtlety"


if __name__ == "__main__":
    test_aquatic_rule_uses_current_oracle_and_executable_family()
    test_aquatic_draws_bottoms_then_grants_only_remaining_blue_creatures()
    test_perpetual_evoke_cast_exiles_blue_card_runs_etb_then_sacrifices()
    print("PASS test_digital_perpetual_evoke_runtime")
