#!/usr/bin/env python3
"""Focused runtime tests for Cloud Key chosen-card-type cost reduction."""

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
    spec = importlib.util.spec_from_file_location("battle_cloud_key_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def cloud_key_effect():
    return {
        "effect": "static_cost_reduction",
        "ability_kind": "static",
        "permanent_type": "artifact",
        "battle_model_scope": "chosen_card_type_cost_reduction_v1",
        "choose_card_type_on_enter": True,
        "chosen_card_type_options": ["artifact", "creature", "enchantment", "instant", "sorcery"],
        "preferred_card_type_order": ["instant", "sorcery", "artifact", "creature", "enchantment"],
        "cost_reduction_applies_to": "spells_you_cast_of_chosen_card_type",
        "cost_reduction_uses_chosen_card_type": True,
        "cost_reduction_generic": 1,
    }


def test_cloud_key_chooses_best_hand_type_and_reduces_only_that_type():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        big_score = {
            "name": "Big Score",
            "type_line": "Instant",
            "cmc": 4,
            "mana_cost": "{3}{R}",
            "colors": ["R"],
        }
        unexpected_windfall = {
            "name": "Unexpected Windfall",
            "type_line": "Instant",
            "cmc": 4,
            "mana_cost": "{2}{R}{R}",
            "colors": ["R"],
        }
        sun_titan = {
            "name": "Sun Titan",
            "type_line": "Creature - Giant",
            "cmc": 6,
            "mana_cost": "{4}{W}{W}",
            "colors": ["W"],
        }
        active.hand = [big_score, unexpected_windfall, sun_titan]
        card = {"name": "Cloud Key", "type_line": "Artifact", "cmc": 3, "mana_cost": "{3}"}

        battle.apply_effect_immediate(
            active,
            [opponent],
            card,
            turn=6,
            rng=random.Random(607),
            effect_data_override=cloud_key_effect(),
            stack=battle.Stack(),
            phase="precombat_main",
        )

        permanent = active.battlefield[0]
        instant_cost = battle.card_cost_for_player_state(active, big_score)
        creature_cost = battle.card_cost_for_player_state(active, sun_titan)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert permanent["chosen_card_type"] == "instant"
    assert instant_cost["generic"] == 2
    assert instant_cost["static_cost_reduction_total"] == 1
    assert instant_cost["static_cost_reductions"][0]["source"] == "Cloud Key"
    assert instant_cost["static_cost_reductions"][0]["chosen_card_type"] == "instant"
    assert creature_cost["generic"] == 4
    assert "static_cost_reduction_total" not in creature_cost
    assert any(
        event == "chosen_card_type_resolved"
        and data.get("card") == "Cloud Key"
        and data.get("chosen_card_type") == "instant"
        and data.get("reason") == "hand_maximize_reduction"
        for event, data in events
    )


def test_cloud_key_without_choice_does_not_reduce_every_spell_type():
    battle = load_battle()
    active = player(battle, "Lorehold")
    source = {
        "name": "Cloud Key",
        "type_line": "Artifact",
        "effect": "static_cost_reduction",
        "battle_model_scope": "chosen_card_type_cost_reduction_v1",
        "cost_reduction_applies_to": "spells_you_cast_of_chosen_card_type",
        "cost_reduction_uses_chosen_card_type": True,
        "cost_reduction_generic": 1,
        "chosen_card_type_options": ["artifact", "creature", "enchantment", "instant", "sorcery"],
    }
    active.battlefield = [source]
    spell = {
        "name": "Big Score",
        "type_line": "Instant",
        "cmc": 4,
        "mana_cost": "{3}{R}",
        "colors": ["R"],
    }

    cost = battle.card_cost_for_player_state(active, spell)

    assert cost["generic"] == 3
    assert "static_cost_reduction_total" not in cost


if __name__ == "__main__":
    test_cloud_key_chooses_best_hand_type_and_reduces_only_that_type()
    test_cloud_key_without_choice_does_not_reduce_every_spell_type()
    print("PASS test_cloud_key_runtime")
