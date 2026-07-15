#!/usr/bin/env python3
"""Focused runtime coverage for Storm, conjure pools, and free exile casts."""

from __future__ import annotations

import importlib.util
import json
import random
import sqlite3
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
REVIEWED_RULES_PATH = SCRIPT_DIR / "reviewed_battle_card_rules.json"
KNOWLEDGE_DB = SCRIPT_DIR / "knowledge.db"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


def load_battle():
    spec = importlib.util.spec_from_file_location(
        "battle_digital_storm_conjure_under_test",
        BATTLE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def limitless_rule():
    payload = json.loads(REVIEWED_RULES_PATH.read_text(encoding="utf-8"))
    return payload["Limitless Rekindling"]


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def test_limitless_reviewed_rule_has_complete_pool_and_oracle_contract():
    rule = limitless_rule()
    effect = rule["effect_json"]
    pool = effect["conjure_random_named_card_pool"]

    assert rule["review_status"] == "verified"
    assert rule["execution_status"] == "auto"
    assert rule["oracle_hash"] == "1dbb46e25887ccd93fc2b013c75f7710"
    assert effect["storm"] is True
    assert effect["conjure_pool_set_code"] == "ECL"
    assert effect["conjured_card_free_cast_until_eot"] is True
    assert len(pool) == 56
    assert len(set(pool)) == 56

    connection = sqlite3.connect(KNOWLEDGE_DB)
    try:
        rows = connection.execute(
            f"""
            SELECT normalized_name, type_line, oracle_text
            FROM card_oracle_cache
            WHERE normalized_name IN ({','.join('?' for _ in pool)})
            """,
            [name.lower() for name in pool],
        ).fetchall()
    finally:
        connection.close()
    assert len(rows) == 56
    assert all(
        "instant" in (type_line or "").lower()
        or "sorcery" in (type_line or "").lower()
        for _name, type_line, _oracle in rows
    )
    assert all(oracle_text for _name, _type_line, oracle_text in rows)


def test_conjured_card_is_not_a_token_and_permission_expires_by_turn():
    battle = load_battle()
    controller = player(battle, "Controller")
    opponent = player(battle, "Opponent")
    opponent.battlefield = [
        {
            "name": "Damage Target",
            "owner": opponent.name,
            "controller": opponent.name,
            "type_line": "Creature - Test",
            "effect": "creature",
            "power": 5,
            "toughness": 5,
        }
    ]
    source = {"name": "Limitless Rekindling", "type_line": "Sorcery"}
    effect = {
        "effect": "conjure_random_card_to_exile",
        "conjure_random_named_card_pool": ["Sear"],
        "conjured_card_free_cast_until_eot": True,
    }
    conjured = battle.conjure_random_named_pool_card_to_exile(
        controller,
        source,
        effect,
        turn=5,
        rng=random.Random(5),
        phase="resolution",
    )

    assert conjured.get("name") == "Sear"
    assert conjured["_conjured"] is True
    assert conjured["_not_from_starting_deck"] is True
    assert conjured["card_origin"] == "conjured"
    assert not conjured.get("is_token")
    assert conjured in controller.exile
    assert conjured["_free_cast_from_exile_until_turn"] == 5

    stack = battle.Stack()
    assert battle.cast_turn_limited_free_exile_card(
        controller,
        conjured,
        [opponent],
        [controller, opponent],
        turn=6,
        phase="precombat_main",
        stack=stack,
        rng=random.Random(6),
    ) is False
    assert conjured in controller.exile

    conjured["_free_cast_from_exile_until_turn"] = 5
    assert battle.cast_turn_limited_free_exile_card(
        controller,
        conjured,
        [opponent],
        [controller, opponent],
        turn=5,
        phase="precombat_main",
        stack=stack,
        rng=random.Random(5),
    ) is True
    assert conjured not in controller.exile
    assert len(stack.items) == 1
    assert stack.items[0].card is conjured
    assert stack.items[0].card["_mana_spent_to_cast"] == 0


def test_storm_copies_resolve_even_when_original_is_countered():
    battle = load_battle()
    controller = player(battle, "Controller")
    opponent = player(battle, "Opponent")
    battle.CURRENT_REPLAY_TURN = 7
    try:
        controller.record_spell_cast(7, card={"name": "First", "type_line": "Instant", "cmc": 1})
        controller.record_spell_cast(7, card={"name": "Second", "type_line": "Sorcery", "cmc": 1})
        source = {
            "name": "Limitless Rekindling",
            "type_line": "Kindred Sorcery - Elemental",
            "storm": True,
        }
        effect = {
            "effect": "conjure_random_card_to_exile",
            "storm": True,
            "conjure_random_named_card_pool": ["Sear"],
            "conjured_card_free_cast_until_eot": True,
        }
        controller.record_spell_cast(7, card=source)
        stack = battle.Stack()
        assert battle.register_storm_copies_for_cast(
            controller,
            source,
            effect_data=effect,
        ) == 2
        stack.push(source, controller, effect)

        assert len(stack.items) == 3
        assert stack.items[0].card is source
        assert all(item.card.get("is_copy") for item in stack.items[1:])
        assert [item.card.get("_storm_copy_index") for item in stack.items[1:]] == [1, 2]

        stack.items[0].countered = True
        for _ in range(2):
            item = stack.resolve_top()
            assert item is not None
            battle.apply_effect_immediate(
                controller,
                [opponent],
                item.card,
                turn=7,
                rng=random.Random(7),
                effect_data_override=item.effect_data,
                stack=stack,
                phase="resolution",
            )
        assert stack.resolve_top() is None
    finally:
        battle.CURRENT_REPLAY_TURN = None

    assert [card.get("name") for card in controller.exile] == ["Sear", "Sear"]
    assert source in controller.graveyard
    assert not any(card.get("is_copy") for card in controller.graveyard)


if __name__ == "__main__":
    test_limitless_reviewed_rule_has_complete_pool_and_oracle_contract()
    test_conjured_card_is_not_a_token_and_permission_expires_by_turn()
    test_storm_copies_resolve_even_when_original_is_countered()
    print("PASS test_digital_storm_conjure_runtime")
