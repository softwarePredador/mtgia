#!/usr/bin/env python3
"""Focused runtime tests for Rune-Tail flip and prevention semantics."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_rune_tail_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name, life=40):
    participant = battle.Player(name, None, [], strategy="midrange")
    participant.life = life
    return participant


def creature(name, toughness=3):
    return {
        "name": name,
        "effect": "creature",
        "type_line": "Creature",
        "power": toughness,
        "toughness": toughness,
    }


def rune_tail_card():
    return {
        "name": "Rune-Tail, Kitsune Ascendant // Rune-Tail's Essence",
        "type_line": "Legendary Creature - Fox Monk",
        "cmc": 3,
        "mana_cost": "{2}{W}",
    }


def cast_rune_tail(battle, active, opponent, turn=3):
    card = rune_tail_card()
    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=turn,
        rng=random.Random(616),
        effect_data_override=battle.get_card_effect(card),
    )
    return next(
        permanent
        for permanent in active.battlefield
        if permanent["name"] == "Rune-Tail, Kitsune Ascendant // Rune-Tail's Essence"
    )


def test_rune_tail_uses_xmage_backed_manual_runtime_waiver():
    battle = load_battle()
    effect = battle.get_card_effect(rune_tail_card())

    assert "Rune-Tail, Kitsune Ascendant // Rune-Tail's Essence" in battle.MANUAL_RULE_RUNTIME_WAIVERS
    assert effect["effect"] == "creature"
    assert effect["power"] == 2
    assert effect["toughness"] == 2
    assert effect["life_total_threshold"] == 30
    assert effect["flips_at_life_total_threshold"] is True
    assert effect["flipped_name"] == "Rune-Tail's Essence"
    assert effect["prevent_all_damage_to_controlled_creatures"] is True
    assert effect["battle_model_scope"] == "life_30_flip_prevent_all_damage_to_controlled_creatures_v1"
    assert effect["_rule_oracle_hash"] == "41538153d9a8b81b8233170efee5f9da"
    assert effect["_rule_logical_key"] == "battle_rule_v1:ac1ab7b07d9e4a4cb5ce455bc50ccb7e"


def test_rune_tail_flips_on_enter_at_life_threshold():
    battle = load_battle()
    active = player(battle, "Lorehold", life=40)
    opponent = player(battle, "Opponent", life=40)

    rune_tail = cast_rune_tail(battle, active, opponent)

    assert rune_tail["_life_total_threshold_flipped"] is True
    assert rune_tail["flipped_to"] == "Rune-Tail's Essence"
    assert rune_tail["type_line"] == "Legendary Enchantment"
    assert rune_tail["effect"] == "passive"
    assert rune_tail["creature_type_suppressed"] is True
    assert battle.is_battlefield_creature(rune_tail) is False


def test_rune_tail_prevents_damage_to_controlled_creatures_after_flip():
    battle = load_battle()
    active = player(battle, "Lorehold", life=40)
    opponent = player(battle, "Opponent", life=40)
    rune_tail = cast_rune_tail(battle, active, opponent)
    ally = creature("Lorehold Ally", toughness=4)
    active.battlefield.append(ally)
    source = {"name": "Blasphemous Act", "type_line": "Sorcery", "controller": "Opponent"}

    ally_amount = battle.apply_static_damage_replacements(
        opponent,
        active,
        ally,
        source,
        13,
        damage_event_type="permanent",
        turn=4,
        phase="resolution",
    )
    rune_tail_amount = battle.apply_static_damage_replacements(
        opponent,
        active,
        rune_tail,
        source,
        13,
        damage_event_type="permanent",
        turn=4,
        phase="resolution",
    )
    opponent_creature_amount = battle.apply_static_damage_replacements(
        opponent,
        opponent,
        creature("Opponent Creature", toughness=4),
        source,
        13,
        damage_event_type="permanent",
        turn=4,
        phase="resolution",
    )

    assert ally_amount == 0
    assert rune_tail_amount == 13
    assert opponent_creature_amount == 13


def test_rune_tail_flip_persists_after_life_drops():
    battle = load_battle()
    active = player(battle, "Lorehold", life=40)
    opponent = player(battle, "Opponent", life=40)
    cast_rune_tail(battle, active, opponent)
    ally = creature("Lorehold Ally", toughness=4)
    active.battlefield.append(ally)
    active.life = 20

    amount = battle.apply_static_damage_replacements(
        opponent,
        active,
        ally,
        {"name": "Combat Damage", "type_line": "Creature", "controller": "Opponent"},
        3,
        damage_event_type="permanent",
        turn=5,
        phase="combat_damage",
    )

    assert amount == 0


def test_rune_tail_does_not_prevent_before_flip_then_flips_after_life_gain():
    battle = load_battle()
    active = player(battle, "Lorehold", life=29)
    opponent = player(battle, "Opponent", life=40)
    rune_tail = cast_rune_tail(battle, active, opponent)
    ally = creature("Lorehold Ally", toughness=4)
    active.battlefield.append(ally)
    source = {"name": "Shock", "type_line": "Instant", "controller": "Opponent"}

    before = battle.apply_static_damage_replacements(
        opponent,
        active,
        ally,
        source,
        2,
        damage_event_type="permanent",
        turn=4,
        phase="resolution",
    )
    active.life = 30
    battle.refresh_life_total_threshold_statics_for_player(
        active,
        turn=5,
        phase="life_gain",
        emit_events=True,
    )
    after = battle.apply_static_damage_replacements(
        opponent,
        active,
        ally,
        source,
        2,
        damage_event_type="permanent",
        turn=5,
        phase="resolution",
    )

    assert before == 2
    assert rune_tail["_life_total_threshold_flipped"] is True
    assert after == 0


if __name__ == "__main__":
    tests = [
        test_rune_tail_uses_xmage_backed_manual_runtime_waiver,
        test_rune_tail_flips_on_enter_at_life_threshold,
        test_rune_tail_prevents_damage_to_controlled_creatures_after_flip,
        test_rune_tail_flip_persists_after_life_drops,
        test_rune_tail_does_not_prevent_before_flip_then_flips_after_life_gain,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
