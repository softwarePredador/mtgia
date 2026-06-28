#!/usr/bin/env python3
"""Focused runtime tests for Taunt from the Rampart combat semantics."""

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
    spec = importlib.util.spec_from_file_location("battle_taunt_from_the_rampart_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def creature(name, *, power=2, toughness=2):
    return {
        "name": name,
        "type_line": "Creature - Soldier",
        "effect": "creature",
        "power": power,
        "toughness": toughness,
        "tapped": False,
        "summoning_sick": False,
    }


def test_taunt_from_the_rampart_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(
        {"name": "Taunt from the Rampart", "type_line": "Sorcery", "cmc": 5}
    )

    assert effect["effect"] == "goad_opponents_creatures_cant_block"
    assert effect["battle_model_scope"] == (
        "goad_all_opponents_creatures_cant_block_until_your_next_turn_v1"
    )
    assert effect["goad_all_opponents_creatures"] is True
    assert effect["affected_creatures_cant_block_until_your_next_turn"] is True
    assert effect["_rule_logical_key"] == "battle_rule_v1:16e15ea414a18410acd151d43276651c"
    assert effect["_rule_oracle_hash"] == "8edc08d877978569fe4b5bc7120bb771"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"


def test_taunt_marks_opponents_creatures_then_clears_on_casters_next_turn():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active_creature = creature("Own Soldier")
        goaded_creature = creature("Opposing Wall", power=0, toughness=4)
        opponent_artifact = {"name": "Mana Rock", "type_line": "Artifact", "effect": "ramp_permanent"}
        active.battlefield = [active_creature]
        opponent.battlefield = [goaded_creature, opponent_artifact]
        card = {"name": "Taunt from the Rampart", "type_line": "Sorcery", "cmc": 5}
        effect = battle.get_card_effect(card)

        battle.apply_effect_immediate(
            active,
            [opponent],
            card,
            turn=3,
            rng=random.Random(7102),
            effect_data_override=effect,
            stack=battle.Stack(),
            phase="precombat_main",
        )

        assert goaded_creature["goaded"] is True
        assert goaded_creature["must_attack_each_combat_if_able"] is True
        assert battle.must_attack_if_able(goaded_creature) is True
        assert battle.should_attack_with_creature(goaded_creature) is True
        assert goaded_creature["cant_block"] is True
        assert battle.creature_cannot_block(goaded_creature) is True
        assert opponent.creatures_for_blocking() == []
        assert "goaded" not in active_creature
        assert opponent_artifact.get("cant_block") is None

        battle.clear_until_next_turn_effects(opponent, 4, all_players=[active, opponent])
        assert goaded_creature["goaded"] is True
        assert opponent.creatures_for_blocking() == []

        battle.clear_until_next_turn_effects(active, 5, all_players=[active, opponent])
        assert "goaded" not in goaded_creature
        assert "must_attack_each_combat_if_able" not in goaded_creature
        assert "cant_block" not in goaded_creature
        assert opponent.creatures_for_blocking() == [goaded_creature]
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert any(
        event == "goad_opponents_creatures_cant_block_resolved"
        and data.get("card") == "Taunt from the Rampart"
        and data.get("affected_count") == 1
        and data.get("duration") == "until_your_next_turn"
        for event, data in events
    )


def test_taunt_prevents_declared_blockers_from_affected_creatures():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        opponent.life = 2
        blocker = creature("Emergency Blocker", power=2, toughness=2)
        opponent.battlefield = [blocker]
        attacker = creature("Lethal Attacker", power=2, toughness=2)
        effect = battle.get_card_effect(
            {"name": "Taunt from the Rampart", "type_line": "Sorcery", "cmc": 5}
        )

        battle.apply_effect_immediate(
            active,
            [opponent],
            {"name": "Taunt from the Rampart", "type_line": "Sorcery", "cmc": 5},
            turn=6,
            rng=random.Random(7103),
            effect_data_override=effect,
            stack=battle.Stack(),
            phase="precombat_main",
        )

        assignments = battle.declare_blockers_step(
            opponent,
            [attacker],
            turn=6,
            rng=random.Random(7104),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert assignments == [(attacker, [])]
    assert any(
        event == "combat_step"
        and data.get("step") == "declare_blockers"
        and data.get("blockers") == 0
        for event, data in events
    )
