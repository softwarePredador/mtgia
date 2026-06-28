#!/usr/bin/env python3
"""Focused runtime tests for Whispersilk Cloak equipment semantics."""

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
    spec = importlib.util.spec_from_file_location("battle_whispersilk_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def whispersilk_cloak_card():
    return {
        "name": "Whispersilk Cloak",
        "type_line": "Artifact - Equipment",
        "mana_cost": "{3}",
        "cmc": 3,
    }


def test_whispersilk_cloak_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(whispersilk_cloak_card())

    assert effect["effect"] == "equipment_static_attachment"
    assert effect["battle_model_scope"] == "equipment_auto_attach_unblockable_shroud_v1"
    assert effect["artifact"] is True
    assert effect["equipment"] is True
    assert effect["equip_cost"] == "{2}"
    assert effect["grants_shroud"] is True
    assert effect["grants_unblockable"] is True
    assert effect["attached_creature_cant_be_blocked"] is True
    assert effect["_rule_logical_key"] == "battle_rule_v1:776e69f786c18a8398012554b8e22907"
    assert effect["_rule_oracle_hash"] == "5384a7231f4c91ab45b4007b0ac7f8dc"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Whispersilk Cloak" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_whispersilk_cloak_grants_shroud_and_cant_be_blocked():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        target = {
            "name": "Equipped Threat",
            "effect": "creature",
            "type_line": "Creature",
            "power": 4,
            "toughness": 4,
            "summoning_sick": False,
        }
        active.battlefield = [target]
        effect = battle.get_card_effect(whispersilk_cloak_card())

        battle.apply_effect_immediate(
            active,
            [],
            whispersilk_cloak_card(),
            turn=4,
            rng=random.Random(616),
            effect_data_override=effect,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert target["shroud"] is True
    assert target["unblockable"] is True
    assert target["cant_be_blocked"] is True
    equipment = next(
        permanent
        for permanent in active.battlefield
        if isinstance(permanent, dict) and permanent.get("name") == "Whispersilk Cloak"
    )
    assert equipment["effect"] == "equipment_static_attachment"
    assert equipment["attached_to"] == "Equipped Threat"
    attached_event = next(
        data
        for event, data in events
        if event == "equipment_attached" and data.get("card") == "Whispersilk Cloak"
    )
    assert attached_event["target"] == "Equipped Threat"
    assert attached_event["grants"] == ["shroud", "unblockable"]
    assert attached_event["rule_logical_key"] == "battle_rule_v1:776e69f786c18a8398012554b8e22907"


def test_whispersilk_cloak_blocks_targeting_and_blockers():
    battle = load_battle()
    active = player(battle, "Lorehold")
    defender = player(battle, "Defender")
    attacker = {
        "name": "Equipped Threat",
        "effect": "creature",
        "type_line": "Creature",
        "power": 4,
        "toughness": 4,
        "summoning_sick": False,
    }
    blocker = {
        "name": "Large Blocker",
        "effect": "creature",
        "type_line": "Creature",
        "power": 6,
        "toughness": 6,
        "summoning_sick": False,
    }
    active.battlefield = [attacker]
    defender.battlefield = [blocker]

    battle.apply_effect_immediate(
        active,
        [],
        whispersilk_cloak_card(),
        turn=5,
        rng=random.Random(617),
        effect_data_override=battle.get_card_effect(whispersilk_cloak_card()),
    )

    assert (
        battle.is_legal_target(
            {"name": "Removal", "effect": "remove_creature", "target": "creature"},
            attacker,
            defender,
            target_type="creature",
            target_controller=active,
        )
        is False
    )
    block_assignments = battle.declare_blockers_step(
        defender,
        [attacker],
        turn=5,
        rng=random.Random(618),
    )
    assert block_assignments == [(attacker, [])]


if __name__ == "__main__":
    test_whispersilk_cloak_get_card_effect_is_runtime_source()
    test_whispersilk_cloak_grants_shroud_and_cant_be_blocked()
    test_whispersilk_cloak_blocks_targeting_and_blockers()
    print("PASS test_whispersilk_cloak_runtime")
