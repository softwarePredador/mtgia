#!/usr/bin/env python3
"""Focused runtime tests for session Agent 3 finisher/recursion scopes."""

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
    spec = importlib.util.spec_from_file_location("battle_agent3_runtime_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def ancient_gold_dragon_card():
    return {
        "name": "Ancient Gold Dragon",
        "type_line": "Creature - Elder Dragon",
        "mana_cost": "{5}{W}{W}",
        "cmc": 7,
    }


def leyline_dowser_card():
    return {
        "name": "Leyline Dowser",
        "type_line": "Artifact",
        "mana_cost": "{2}",
        "cmc": 2,
    }


def spell(name, type_line="Instant", cmc=2, effect="draw_cards"):
    return {"name": name, "type_line": type_line, "cmc": cmc, "effect": effect}


def test_ancient_gold_dragon_get_card_effect_is_xmage_backed_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(ancient_gold_dragon_card())

    assert effect["effect"] == "token_maker"
    assert effect["battle_model_scope"] == "source_combat_damage_player_roll_d20_create_faerie_dragon_tokens_equal_result_v1"
    assert effect["trigger"] == "combat_damage_to_player"
    assert effect["trigger_source_deals_combat_damage_to_player"] is True
    assert effect["token_count_source"] == "d20_result"
    assert effect["die_sides"] == 20
    assert effect["token_name"] == "Faerie Dragon Token"
    assert effect["token_power"] == 1
    assert effect["token_toughness"] == 1
    assert effect["token_colors"] == ["U"]
    assert effect["token_flying"] is True
    assert effect["power"] == 7
    assert effect["toughness"] == 10
    assert effect["flying"] is True
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Ancient Gold Dragon" in battle.MANUAL_RULE_RUNTIME_WAIVERS


def test_ancient_gold_dragon_rolls_d20_for_combat_damage_faerie_dragon_tokens():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")

        battle.apply_effect_immediate(
            active,
            [opponent],
            ancient_gold_dragon_card(),
            turn=7,
            rng=random.Random(612),
            stack=battle.Stack(),
            phase="precombat_main",
        )
        dragon = next(card for card in active.battlefield if card.get("name") == "Ancient Gold Dragon")
        dragon["summoning_sick"] = False
        expected_roll = random.Random(613).randint(1, 20)

        battle.combat_damage_steps(
            active,
            [opponent],
            opponent,
            [dragon],
            [(dragon, [])],
            turn=8,
            rng=random.Random(613),
            all_players=[active, opponent],
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert opponent.life == 33
    faerie_tokens = [
        card
        for card in active.battlefield
        if card.get("name") == "Faerie Dragon Token"
    ]
    assert len(faerie_tokens) == expected_roll
    assert all(card.get("power") == 1 and card.get("toughness") == 1 for card in faerie_tokens)
    assert all(card.get("flying") is True for card in faerie_tokens)
    trigger_event = next(
        data
        for event, data in events
        if event == "trigger_resolved"
        and data.get("card") == "Ancient Gold Dragon"
        and data.get("trigger") == "combat_damage_to_player"
    )
    assert trigger_event["trigger_creatures"] == ["Ancient Gold Dragon"]
    assert trigger_event["token_count_source"] == "d20_result"
    assert trigger_event["tokens_created"] == expected_roll
    assert trigger_event["die_sides"] == 20
    assert trigger_event["die_roll"] == expected_roll
    assert trigger_event["treasures_created"] == 0


def test_leyline_dowser_get_card_effect_and_mill_to_hand_runtime_source():
    battle = load_battle()
    effect = battle.get_card_effect(leyline_dowser_card())
    assert effect["effect"] == "recursion"
    assert effect["battle_model_scope"] == "pay_one_tap_mill_one_instant_sorcery_to_hand_tap_legendary_creature_to_untap_v1"
    assert effect["activated_self_mill_count"] == 1
    assert effect["milled_card_types_to_hand"] == ["instant", "sorcery"]
    assert effect["secondary_untap_source_by_tapping_legendary_creature"] is True
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    assert "Leyline Dowser" in battle.MANUAL_RULE_RUNTIME_WAIVERS

    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        dowser = {**leyline_dowser_card(), **effect, "tapped": True}
        legend = {
            "name": "Lorehold, the Historian",
            "type_line": "Legendary Creature - Avatar",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
        }
        milled_spell = spell("Thrill of Possibility")
        active.battlefield = [dowser, legend]
        active.library = [milled_spell]
        active.mana_pool.add_generic(1)

        activated = battle.activate_utility_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=3,
            rng=random.Random(610),
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert activated == 1
    assert legend["tapped"] is True
    assert dowser["tapped"] is True
    assert milled_spell in active.hand
    assert milled_spell not in active.graveyard
    assert any(
        event == "utility_artifact_activated"
        and data.get("card") == "Leyline Dowser"
        and data.get("activation_kind") == "leyline_dowser_mill_one_maybe_spell_to_hand"
        and data.get("destination") == "hand"
        for event, data in events
    )


if __name__ == "__main__":
    test_ancient_gold_dragon_get_card_effect_is_xmage_backed_runtime_source()
    test_ancient_gold_dragon_rolls_d20_for_combat_damage_faerie_dragon_tokens()
    test_leyline_dowser_get_card_effect_and_mill_to_hand_runtime_source()
    print("PASS test_session_agent3_finisher_draw_recursion_runtime")
