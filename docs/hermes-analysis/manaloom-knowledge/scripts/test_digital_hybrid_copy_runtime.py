#!/usr/bin/env python3
"""Focused runtime coverage for protection and hybrid-spell copying."""

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
    spec = importlib.util.spec_from_file_location("battle_digital_hybrid_copy_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def providence_rule():
    payload = json.loads(REVIEWED_RULES_PATH.read_text(encoding="utf-8"))
    return payload["Providence of Night"]


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def providence_permanent(controller_name):
    return {
        "name": "Providence of Night",
        "owner": controller_name,
        "controller": controller_name,
        **providence_rule()["effect_json"],
    }


def test_providence_reviewed_rule_has_runtime_and_oracle_contract():
    rule = providence_rule()
    effect = rule["effect_json"]

    assert rule["review_status"] == "verified"
    assert rule["execution_status"] == "auto"
    assert rule["oracle_hash"] == "9081285c9c3934caeecd10f5fb4cd476"
    assert effect["protection_from_color_profile"] == "monocolored"
    assert effect["trigger_spell_requires_hybrid_mana"] is True
    assert effect["copy_any_spell_on_stack"] is True
    assert effect["choose_new_targets_status"] == "runtime_executor_v1"


def test_protection_from_monocolored_covers_targeting_damage_and_blocking():
    battle = load_battle()
    controller = player(battle, "Controller")
    opponent = player(battle, "Opponent")
    providence = providence_permanent(controller.name)
    controller.battlefield = [providence]
    red_source = {
        "name": "Red Source",
        "controller": opponent.name,
        "type_line": "Creature - Elemental",
        "colors": ["R"],
        "power": 3,
        "toughness": 3,
    }
    multicolor_source = {
        "name": "Multicolor Source",
        "controller": opponent.name,
        "type_line": "Creature - Elemental",
        "colors": ["R", "U"],
        "power": 3,
        "toughness": 3,
    }

    assert battle.is_legal_target(
        red_source,
        providence,
        opponent,
        all_players=[controller, opponent],
        target_type="creature",
        target_controller=controller,
    ) is False
    assert battle.is_legal_target(
        multicolor_source,
        providence,
        opponent,
        all_players=[controller, opponent],
        target_type="creature",
        target_controller=controller,
    ) is True
    assert battle.apply_static_damage_replacements(
        opponent,
        controller,
        providence,
        red_source,
        3,
        damage_event_type="permanent",
        emit=False,
    ) == 0
    assert battle.apply_static_damage_replacements(
        opponent,
        controller,
        providence,
        multicolor_source,
        3,
        damage_event_type="permanent",
        emit=False,
    ) == 3
    assert battle.blocker_can_block_attacker(red_source, providence) is False
    assert battle.blocker_can_block_attacker(multicolor_source, providence) is True


def test_hybrid_spell_copy_ignores_nonhybrid_and_copies_permanent_as_token():
    battle = load_battle()
    controller = player(battle, "Controller")
    opponent = player(battle, "Opponent")
    controller.battlefield = [providence_permanent(controller.name)]

    nonhybrid = {
        "name": "Plain Spell",
        "mana_cost": "{1}{U}",
        "cmc": 2,
        "type_line": "Instant",
        "effect": "draw_cards",
        "draw_count": 1,
    }
    stack = battle.Stack()
    stack.push(nonhybrid, controller, dict(nonhybrid))
    battle.trigger_spell_cast_engines(
        controller,
        [controller, opponent],
        nonhybrid,
        turn=3,
        phase="main1",
        stack=stack,
    )
    assert len(stack.items) == 1

    hybrid_creature = {
        "name": "Hybrid Creature",
        "mana_cost": "{G/W}",
        "cmc": 1,
        "type_line": "Creature - Elf",
        "effect": "creature",
        "power": 2,
        "toughness": 2,
    }
    stack = battle.Stack()
    stack.push(hybrid_creature, controller, dict(hybrid_creature))
    battle.trigger_spell_cast_engines(
        controller,
        [controller, opponent],
        hybrid_creature,
        turn=4,
        phase="main1",
        stack=stack,
    )

    assert len(stack.items) == 2
    copied_item = stack.resolve_top()
    assert copied_item.card["is_copy"] is True
    assert copied_item.was_cast is False
    battle.apply_effect_immediate(
        controller,
        [opponent],
        copied_item.card,
        turn=4,
        rng=random.Random(4),
        effect_data_override=copied_item.effect_data,
        stack=stack,
        phase="main1",
    )

    copied_permanent = next(
        permanent
        for permanent in controller.battlefield
        if permanent.get("name") == "Hybrid Creature"
    )
    assert copied_permanent["is_token"] is True
    assert copied_permanent["token"] is True
    assert copied_permanent["_resolved_from_spell_copy"] is True
    assert "is_copy" not in copied_permanent


if __name__ == "__main__":
    test_providence_reviewed_rule_has_runtime_and_oracle_contract()
    test_protection_from_monocolored_covers_targeting_damage_and_blocking()
    test_hybrid_spell_copy_ignores_nonhybrid_and_copies_permanent_as_token()
    print("PASS test_digital_hybrid_copy_runtime")
