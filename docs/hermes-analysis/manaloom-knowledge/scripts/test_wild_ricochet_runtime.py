#!/usr/bin/env python3
"""Focused runtime tests for Wild Ricochet stack-copy semantics."""

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
    spec = importlib.util.spec_from_file_location("battle_wild_ricochet_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def wild_ricochet_card():
    return {
        "name": "Wild Ricochet",
        "type_line": "Instant",
        "mana_cost": "{2}{R}{R}",
        "cmc": 4,
    }


def test_wild_ricochet_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(wild_ricochet_card())

    assert effect["effect"] == "copy_spell"
    assert effect["instant"] is True
    assert effect["target"] == "instant_or_sorcery_on_stack"
    assert effect["target_spell_card_types"] == ["instant", "sorcery"]
    assert effect["copy_target_stack_object"] is True
    assert effect["copy_is_not_cast"] is True
    assert effect["may_choose_new_targets"] is True
    assert effect["choose_new_targets_status"] == "annotation_only"
    assert effect["may_choose_new_targets_for_target_spell"] is True
    assert effect["choose_new_targets_for_target_spell_status"] == "annotation_only"
    assert (
        effect["battle_model_scope"]
        == "copy_target_instant_or_sorcery_stack_spell_change_original_and_copy_targets_annotation_v1"
    )
    assert effect["_rule_logical_key"] == "battle_rule_v1:bb9ee6595d8b30aa87f1a15879e2703a"
    assert effect["_rule_oracle_hash"] == "c7d62b1c3e0178970919cd0fc3b6b995"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Wild Ricochet" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_wild_ricochet_copies_target_instant_or_sorcery_on_stack():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Active")
        responder = player(battle, "Responder")
        wild_ricochet = wild_ricochet_card()
        responder.hand = [wild_ricochet]
        responder.mana_pool.add("red", 2)
        responder.mana_pool.add_generic(2)
        target_spell = {
            "name": "Targeted Insight",
            "cmc": 3,
            "mana_cost": "{2}{U}",
            "type_line": "Sorcery",
        }
        target_effect = {"effect": "draw_cards", "count": 1}
        stack = battle.Stack()
        stack.push(target_spell, active, target_effect)

        assert battle.priority_round(
            active,
            [active, responder],
            stack,
            7,
            random.Random(612),
            phase="precombat_main",
        ) is True
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert wild_ricochet not in responder.hand
    assert wild_ricochet in responder.graveyard
    assert stack.items[-1].card.get("is_copy") is True
    assert stack.items[-1].controller is responder
    cast_event = next(
        data
        for event, data in events
        if event == "spell_cast" and data.get("card") == "Wild Ricochet"
    )
    copied_event = next(
        data
        for event, data in events
        if event == "spell_copied" and data.get("card") == "Wild Ricochet"
    )
    assert cast_event["response_to"] == "Targeted Insight"
    assert cast_event["may_choose_new_targets_for_target_spell"] is True
    assert cast_event["choose_new_targets_for_target_spell_status"] == "annotation_only"
    assert copied_event["copied_spell"] == "Targeted Insight"
    assert copied_event["copy_is_cast"] is False
    assert copied_event["may_choose_new_targets"] is True
    assert copied_event["choose_new_targets_status"] == "annotation_only"
    assert copied_event["may_choose_new_targets_for_target_spell"] is True
    assert copied_event["choose_new_targets_for_target_spell_status"] == "annotation_only"
    assert copied_event["rule_logical_key"] == "battle_rule_v1:bb9ee6595d8b30aa87f1a15879e2703a"


def test_wild_ricochet_without_stack_target_does_not_become_permanent():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        card = wild_ricochet_card()
        effect = battle.get_card_effect(card)
        battle.apply_effect_immediate(
            active,
            [],
            card,
            turn=5,
            rng=random.Random(613),
            effect_data_override=effect,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert any(card.get("name") == "Wild Ricochet" for card in active.graveyard)
    assert not any(
        permanent.get("name") == "Wild Ricochet"
        for permanent in active.battlefield
        if isinstance(permanent, dict)
    )
    assert any(
        event == "copy_spell_no_stack_target"
        and data.get("card") == "Wild Ricochet"
        and data.get("rule_logical_key") == "battle_rule_v1:bb9ee6595d8b30aa87f1a15879e2703a"
        for event, data in events
    )


if __name__ == "__main__":
    test_wild_ricochet_get_card_effect_is_runtime_source()
    test_wild_ricochet_copies_target_instant_or_sorcery_on_stack()
    test_wild_ricochet_without_stack_target_does_not_become_permanent()
    print("PASS test_wild_ricochet_runtime")
