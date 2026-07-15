#!/usr/bin/env python3
"""Focused runtime coverage for prepared faces and conjured cards."""

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
    spec = importlib.util.spec_from_file_location("battle_digital_prepare_conjure_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def ursine_rule():
    payload = json.loads(REVIEWED_RULES_PATH.read_text(encoding="utf-8"))
    return payload["Ursine Guide // Ranger's Merit"]


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def ursine_permanent(controller_name):
    return {
        "name": "Ursine Guide // Ranger's Merit",
        "owner": controller_name,
        "controller": controller_name,
        **ursine_rule()["effect_json"],
    }


def test_ursine_reviewed_rule_has_runtime_and_oracle_contract():
    rule = ursine_rule()
    effect = rule["effect_json"]
    face = effect["prepared_spell_face"]

    assert rule["review_status"] == "verified"
    assert rule["execution_status"] == "auto"
    assert rule["oracle_hash"] == "697fbc17f2c7bbe9e1b7a15782c98755"
    assert effect["enters_prepared"] is True
    assert effect["trigger_spell_not_from_starting_deck"] is True
    assert effect["conjure_card_template"]["name"] == "Bear Cub"
    assert face["pump_all_subtypes"] == ["Bear"]
    assert face["pump_all_counter_type"] == "+1/+1"
    assert face["keywords"] == ["trample"]


def test_enters_prepared_and_prepared_state_clears_when_leaving_battlefield():
    battle = load_battle()
    controller = player(battle, "Controller")
    opponent = player(battle, "Opponent")
    ursine = battle.prepare_entering_permanent(
        ursine_permanent(controller.name),
        controller=controller,
        all_players=[controller, opponent],
        turn=2,
    )
    controller.battlefield = [ursine]

    assert ursine["prepared"] is True
    assert ursine["_prepared_spell_copy"]["name"] == "Ranger's Merit"
    destination = battle.move_permanent_from_battlefield_to_hand(
        controller,
        ursine,
        reason="returned_by_test",
        turn=3,
    )

    assert destination == "hand"
    assert "prepared" not in ursine
    assert "prepared_turn" not in ursine
    assert "_prepared_spell_copy" not in ursine


def test_nonstarting_spell_conjures_real_card_and_prepares_source():
    battle = load_battle()
    controller = player(battle, "Controller")
    opponent = player(battle, "Opponent")
    ursine = ursine_permanent(controller.name)
    ursine["prepared"] = False
    controller.battlefield = [ursine]
    normal_spell = {
        "name": "Starting Deck Spell",
        "type_line": "Sorcery",
        "mana_cost": "{G}",
        "effect": "draw_cards",
    }

    battle.trigger_spell_cast_engines(
        controller,
        [controller, opponent],
        normal_spell,
        turn=3,
        phase="main1",
    )
    assert [card.get("name") for card in controller.battlefield] == [
        "Ursine Guide // Ranger's Merit"
    ]
    assert ursine["prepared"] is False

    conjured_spell = {
        **normal_spell,
        "name": "Conjured Spell",
        "_conjured": True,
        "_not_from_starting_deck": True,
    }
    battle.trigger_spell_cast_engines(
        controller,
        [controller, opponent],
        conjured_spell,
        turn=4,
        phase="main1",
    )

    bear = next(card for card in controller.battlefield if card.get("name") == "Bear Cub")
    assert bear["_conjured"] is True
    assert bear["_not_from_starting_deck"] is True
    assert bear["card_origin"] == "conjured"
    assert not bear.get("is_token")
    assert ursine["prepared"] is True
    assert ursine["_prepared_spell_copy"]["name"] == "Ranger's Merit"


def test_rangers_merit_retriggers_ursine_then_buffs_each_bear():
    battle = load_battle()
    controller = player(battle, "Controller")
    opponent = player(battle, "Opponent")
    ursine = battle.prepare_entering_permanent(
        ursine_permanent(controller.name),
        controller=controller,
        all_players=[controller, opponent],
        turn=5,
    )
    existing_bear = {
        "name": "Existing Bear",
        "type_line": "Creature - Bear",
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "owner": controller.name,
        "controller": controller.name,
    }
    controller.battlefield = [ursine, existing_bear]
    controller.mana_pool.add_generic(3)
    controller.mana_pool.add("green", 2)

    cast = battle.cast_prepared_spell_faces(
        controller,
        [opponent],
        [controller, opponent],
        turn=5,
        phase="precombat_main",
        stack=battle.Stack(),
        rng=random.Random(5),
    )

    assert cast is True
    bears = [
        permanent
        for permanent in controller.battlefield
        if battle.permanent_has_subtype(permanent, "Bear")
    ]
    assert len(bears) == 3
    assert {permanent.get("power") for permanent in bears} == {3, 4}
    assert ursine["power"] == 4
    assert existing_bear["power"] == 3
    assert all(permanent.get("trample") is True for permanent in bears)
    assert all(int(permanent.get("plus_one_counters") or 0) == 1 for permanent in bears)
    assert ursine["prepared"] is True
    assert ursine["_prepared_spell_copy"]["name"] == "Ranger's Merit"
    assert not any(card.get("name") == "Ranger's Merit" for card in controller.graveyard)


if __name__ == "__main__":
    test_ursine_reviewed_rule_has_runtime_and_oracle_contract()
    test_enters_prepared_and_prepared_state_clears_when_leaving_battlefield()
    test_nonstarting_spell_conjures_real_card_and_prepares_source()
    test_rangers_merit_retriggers_ursine_then_buffs_each_bear()
    print("PASS test_digital_prepare_conjure_runtime")
