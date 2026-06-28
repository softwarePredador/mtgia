#!/usr/bin/env python3
"""Focused runtime tests for Rem Karolus static spell-damage replacements."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_rem_karolus_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def creature(name, toughness=3):
    return {
        "name": name,
        "effect": "creature",
        "type_line": "Creature",
        "power": toughness,
        "toughness": toughness,
    }


def rem_card():
    return {
        "name": "Rem Karolus, Stalwart Slayer",
        "type_line": "Legendary Creature - Human Knight",
        "cmc": 3,
        "mana_cost": "{1}{R}{W}",
    }


def rem_permanent(battle):
    card = rem_card()
    return {**card, **battle.get_card_effect(card)}


def test_rem_karolus_uses_xmage_backed_manual_runtime_waiver():
    battle = load_battle()
    effect = battle.get_card_effect(rem_card())

    assert "Rem Karolus, Stalwart Slayer" in battle.MANUAL_RULE_RUNTIME_WAIVERS
    assert effect["effect"] == "creature"
    assert effect["power"] == 2
    assert effect["toughness"] == 3
    assert effect["flying"] is True
    assert effect["haste"] is True
    assert effect["prevent_spell_damage_to_you_and_permanents_you_control"] is True
    assert effect["spell_damage_to_opponents_and_permanents_they_control_bonus"] == 1
    assert effect["battle_model_scope"] == "spell_damage_to_opponents_plus_one_prevent_own_nonself_v1"
    assert effect["_rule_oracle_hash"] == "7d58da0feedf10778e5f0a84b724e08c"
    assert effect["_rule_logical_key"] == "battle_rule_v1:1a987670b594e446e4b1a122214e549e"
    waiver = next(
        row
        for row in battle.manual_runtime_waiver_inventory()
        if row["card"] == "Rem Karolus, Stalwart Slayer"
    )
    assert waiver["effect"] == "creature"
    assert "RemKarolusStalwartSlayer.java" in waiver["source_runs"]


def test_rem_karolus_cast_enters_as_hasty_flying_creature():
    battle = load_battle()
    active = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    card = rem_card()

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=3,
        rng=random.Random(612),
        effect_data_override=battle.get_card_effect(card),
    )

    permanent = next(card for card in active.battlefield if card["name"] == "Rem Karolus, Stalwart Slayer")
    assert battle.is_battlefield_creature(permanent)
    assert permanent["power"] == 2
    assert permanent["toughness"] == 3
    assert permanent["haste"] is True
    assert permanent["summoning_sick"] is False
    assert permanent["flying"] is True


def test_rem_karolus_adds_one_to_spell_damage_to_opponents():
    battle = load_battle()
    active = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    active.battlefield = [rem_permanent(battle)]
    spell = {"name": "Lightning Bolt", "type_line": "Instant", "controller": "Lorehold"}

    damage_dealt, target_amount, dealt = battle.deal_damage_to_player_with_static_replacements(
        active,
        opponent,
        spell,
        3,
        turn=4,
        phase="resolution",
    )

    assert dealt is True
    assert target_amount == 4
    assert damage_dealt == 4
    assert opponent.life == 36


def test_rem_karolus_prevents_spell_damage_to_self_and_controlled_permanents():
    battle = load_battle()
    active = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    rem = rem_permanent(battle)
    ally = creature("Lorehold Ally", toughness=4)
    active.battlefield = [rem, ally]
    spell = {"name": "Shock", "type_line": "Instant", "controller": "Opponent"}

    damage_dealt, target_amount, _ = battle.deal_damage_to_player_with_static_replacements(
        opponent,
        active,
        spell,
        2,
        turn=5,
        phase="resolution",
    )
    ally_amount = battle.apply_static_damage_replacements(
        opponent,
        active,
        ally,
        spell,
        3,
        damage_event_type="permanent",
        turn=5,
        phase="resolution",
    )
    rem_self_amount = battle.apply_static_damage_replacements(
        opponent,
        active,
        rem,
        spell,
        3,
        damage_event_type="permanent",
        turn=5,
        phase="resolution",
    )

    assert target_amount == 0
    assert damage_dealt == 0
    assert active.life == 40
    assert ally_amount == 0
    assert rem_self_amount == 3


def test_rem_karolus_ignores_nonspell_damage_sources():
    battle = load_battle()
    active = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    active.battlefield = [rem_permanent(battle)]
    creature_source = {"name": "Goblin Piker", "type_line": "Creature", "controller": "Opponent"}

    damage_to_lorehold = battle.apply_static_damage_replacements(
        opponent,
        active,
        active,
        creature_source,
        3,
        damage_event_type="player",
        turn=6,
        phase="combat_damage",
    )
    damage_to_opponent = battle.apply_static_damage_replacements(
        active,
        opponent,
        opponent,
        creature_source,
        3,
        damage_event_type="player",
        turn=6,
        phase="combat_damage",
    )

    assert damage_to_lorehold == 3
    assert damage_to_opponent == 3


def test_static_damage_modifier_effect_enters_battlefield_and_applies():
    battle = load_battle()
    active = player(battle, "Lorehold")
    opponent = player(battle, "Opponent")
    card = {
        "name": "Twinflame Tyrant",
        "type_line": "Creature - Dragon",
        "cmc": 5,
        "mana_cost": "{3}{R}{R}",
    }
    effect = battle.get_card_effect(card)
    assert effect["effect"] == "damage_modifier"

    battle.apply_effect_immediate(
        active,
        [opponent],
        card,
        turn=5,
        rng=random.Random(607),
        effect_data_override=effect,
    )
    permanent = next(card for card in active.battlefield if card["name"] == "Twinflame Tyrant")
    assert battle.is_battlefield_creature(permanent)
    assert permanent["effect"] == "creature"

    spell = {"name": "Lightning Helix", "type_line": "Instant", "controller": "Lorehold"}
    damage_dealt, target_amount, dealt = battle.deal_damage_to_player_with_static_replacements(
        active,
        opponent,
        spell,
        3,
        turn=6,
        phase="resolution",
    )
    assert dealt is True
    assert target_amount == 6
    assert damage_dealt == 6
    assert opponent.life == 34


if __name__ == "__main__":
    tests = [
        test_rem_karolus_uses_xmage_backed_manual_runtime_waiver,
        test_rem_karolus_cast_enters_as_hasty_flying_creature,
        test_rem_karolus_adds_one_to_spell_damage_to_opponents,
        test_rem_karolus_prevents_spell_damage_to_self_and_controlled_permanents,
        test_rem_karolus_ignores_nonspell_damage_sources,
        test_static_damage_modifier_effect_enters_battlefield_and_applies,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
