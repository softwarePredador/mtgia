#!/usr/bin/env python3
"""Focused runtime tests for Lorehold Agent 3 finisher/draw/recursion scopes."""

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
    spec = importlib.util.spec_from_file_location("battle_lorehold_agent3_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def creature(name, power, toughness):
    return {
        "name": name,
        "effect": "creature",
        "type_line": "Creature",
        "is_creature_permanent": True,
        "power": power,
        "toughness": toughness,
    }


def card(name, type_line, cmc=0):
    return {"name": name, "type_line": type_line, "cmc": cmc}


def test_agent3_get_card_effect_exact_scopes_and_hashes():
    battle = load_battle()

    expected = {
        "Ancient Gold Dragon": (
            "token_maker",
            "source_combat_damage_player_roll_d20_create_faerie_dragon_tokens_equal_result_v1",
            "4ee7da13b4db1902895c7523fb04fdd2",
        ),
        "Chandra's Ignition": (
            "sweeper_damage",
            "controlled_creature_power_damage_each_other_creature_each_opponent_v1",
            "92b36154e7e9f9a2fd8abd64d5f9c032",
        ),
        "Charmbreaker Devils": (
            "creature",
            "upkeep_return_random_instant_sorcery_graveyard_to_hand_spell_cast_plus_4_0_v1",
            "84e84ddacde81b208e8b5cd06b87e10e",
        ),
        "Naktamun Lorespinner // Wheel of Fortune": (
            "creature",
            "upkeep_prepare_if_player_hand_size_lte_one_prepared_wheel_discard_draw_seven_v1",
            "17a8d82c246b858c8e7b5b3866515485",
        ),
    }
    for name, (effect_name, scope, oracle_hash) in expected.items():
        effect = battle.get_card_effect({"name": name})
        assert effect["effect"] == effect_name
        assert effect["battle_model_scope"] == scope
        assert effect["_rule_oracle_hash"] == oracle_hash
        assert effect["_rule_review_status"] == "verified"
        assert effect["_rule_execution_status"] == "auto"
        assert name in battle.MANUAL_RULE_RUNTIME_WAIVERS

    naktamun = battle.get_card_effect({"name": "Naktamun Lorespinner // Wheel of Fortune"})
    assert naktamun["prepare"]["name"] == "Wheel of Fortune"
    assert naktamun["prepare"]["effect"] == "draw_cards"
    assert naktamun["prepare"]["count"] == 7
    assert naktamun["prepare"]["wheel_like"] is True


def test_ancient_gold_dragon_rolls_d20_for_faerie_dragon_tokens():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")

        battle.apply_effect_immediate(
            active,
            [opponent],
            card("Ancient Gold Dragon", "Creature - Elder Dragon", 7),
            turn=7,
            rng=random.Random(700),
        )
        dragon = next(permanent for permanent in active.battlefield if permanent.get("name") == "Ancient Gold Dragon")
        dragon["summoning_sick"] = False
        expected_roll = random.Random(717).randint(1, 20)

        battle.combat_damage_steps(
            active,
            [opponent],
            opponent,
            [dragon],
            [(dragon, [])],
            turn=8,
            rng=random.Random(717),
            all_players=[active, opponent],
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert opponent.life == 33
    faeries = [
        permanent
        for permanent in active.battlefield
        if permanent.get("name") == "Faerie Dragon Token" and permanent.get("tag") == "token"
    ]
    assert len(faeries) == expected_roll
    assert all(permanent.get("power") == 1 and permanent.get("toughness") == 1 for permanent in faeries)
    assert all(permanent.get("flying") is True for permanent in faeries)
    trigger_event = next(
        data
        for event, data in events
        if event == "trigger_resolved"
        and data.get("card") == "Ancient Gold Dragon"
        and data.get("trigger") == "combat_damage_to_player"
    )
    assert trigger_event["effect"] == "token_maker"
    assert trigger_event["token_count_source"] == "d20_result"
    assert trigger_event["die_sides"] == 20
    assert trigger_event["die_roll"] == expected_roll
    assert trigger_event["tokens_created"] == expected_roll


def test_chandras_ignition_uses_target_power_for_each_other_creature_and_each_opponent():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent_a = player(battle, "Opponent A")
        opponent_b = player(battle, "Opponent B")
        target = creature("Chosen Giant", 5, 5)
        active_small = creature("Own Recruit", 2, 2)
        opponent_small = creature("Small Blocker", 3, 3)
        opponent_large = creature("Large Blocker", 6, 6)
        active.battlefield = [target, active_small]
        opponent_a.battlefield = [opponent_small]
        opponent_b.battlefield = [opponent_large]

        battle.apply_effect_immediate(
            active,
            [opponent_a, opponent_b],
            card("Chandra's Ignition", "Sorcery", 5),
            turn=5,
            rng=random.Random(5),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert opponent_a.life == 35
    assert opponent_b.life == 35
    assert target in active.battlefield
    assert active_small in active.graveyard
    assert opponent_small in opponent_a.graveyard
    assert opponent_large in opponent_b.battlefield
    event = next(
        data
        for event, data in events
        if event == "damage_resolved"
        and data.get("card") == "Chandra's Ignition"
    )
    assert event["effect"] == "sweeper_damage"
    assert event["target_creature"] == "Chosen Giant"
    assert event["damage_source"] == "Chosen Giant"
    assert event["amount"] == 5
    assert event["damaged_opponent_count"] == 2
    assert event["creatures_destroyed"] == 2


def test_charmbreaker_devils_upkeep_returns_random_instant_or_sorcery_and_boosts():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        battle.apply_effect_immediate(
            active,
            [opponent],
            card("Charmbreaker Devils", "Creature - Devil", 6),
            turn=6,
            rng=random.Random(6),
        )
        devils = next(permanent for permanent in active.battlefield if permanent.get("name") == "Charmbreaker Devils")
        bolt = card("Lightning Bolt", "Instant", 1)
        mountain = card("Mountain", "Basic Land - Mountain", 0)
        charm = card("Boros Charm", "Instant", 2)
        active.graveyard = [bolt, mountain, charm]
        expected = random.Random(42).choice([bolt, charm])

        returned = battle.process_upkeep_random_instant_sorcery_recursion(active, turn=7, rng=random.Random(42))
        battle.trigger_spell_cast_engines(
            active,
            [active, opponent],
            card("Lightning Helix", "Instant", 2),
            turn=7,
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert returned == 1
    assert expected in active.hand
    assert expected not in active.graveyard
    assert mountain in active.graveyard
    assert devils["power"] == 8
    recursion_event = next(
        data
        for event, data in events
        if event == "trigger_resolved"
        and data.get("card") == "Charmbreaker Devils"
        and data.get("effect") == "upkeep_random_graveyard_recursion"
    )
    assert recursion_event["selection"] == "random"
    assert recursion_event["destination"] == "hand"
    assert recursion_event["returned_card"] == expected["name"]
    boost_event = next(
        data
        for event, data in events
        if event == "trigger_resolved"
        and data.get("card") == "Charmbreaker Devils"
        and data.get("effect") == "boost_source_until_eot"
    )
    assert boost_event["trigger"] == "instant_sorcery_cast"
    assert boost_event["power_before"] == 4
    assert boost_event["power_after"] == 8


def test_naktamun_prepare_creates_wheel_copy_without_generic_draw_collapse():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        battle.apply_effect_immediate(
            active,
            [opponent],
            card("Naktamun Lorespinner // Wheel of Fortune", "Creature - Jackal Wizard", 3),
            turn=3,
            rng=random.Random(3),
        )
        naktamun = next(
            permanent
            for permanent in active.battlefield
            if permanent.get("name") == "Naktamun Lorespinner // Wheel of Fortune"
        )
        active.hand = [card("Plains", "Basic Land - Plains", 0), card("Mountain", "Basic Land - Mountain", 0)]
        opponent.hand = [card("Island", "Basic Land - Island", 0)]

        prepared = battle.process_upkeep_prepare_triggers(active, [active, opponent], turn=4)
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert prepared == 1
    assert naktamun["prepared"] is True
    prepared_copy = next(card for card in active.exile if card.get("_prepared_copy"))
    assert prepared_copy["name"] == "Wheel of Fortune"
    assert prepared_copy["effect"] == "draw_cards"
    assert prepared_copy["count"] == 7
    assert prepared_copy["wheel_like"] is True
    assert prepared_copy["battle_model_scope"] == "prepared_each_player_discard_hand_draw_seven_v1"
    event = next(
        data
        for event, data in events
        if event == "trigger_resolved"
        and data.get("card") == "Naktamun Lorespinner // Wheel of Fortune"
        and data.get("effect") == "prepare_spell_copy"
    )
    assert event["result"] == "prepared"
    assert event["prepared_spell"] == "Wheel of Fortune"
    assert event["prepared_spell_effect"] == "draw_cards"
    assert event["prepared_spell_count"] == 7
    assert event["prepared_spell_wheel_like"] is True
