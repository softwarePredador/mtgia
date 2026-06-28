#!/usr/bin/env python3
"""Focused runtime tests for Semblance Anvil imprint cost reduction."""

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
    spec = importlib.util.spec_from_file_location("battle_semblance_anvil_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name):
    return battle.Player(name, None, [], strategy="midrange")


def test_semblance_anvil_get_card_effect_is_runtime_source():
    battle = load_battle()

    effect = battle.get_card_effect(
        {"name": "Semblance Anvil", "type_line": "Artifact", "cmc": 3, "mana_cost": "{3}"}
    )

    assert effect["effect"] == "static_cost_reduction"
    assert effect["requires_imprint_nonland_card"] is True
    assert effect["cost_reduction_applies_to"] == "spells_you_cast_sharing_imprinted_card_type"
    assert effect["cost_reduction_generic"] == 2
    assert effect["battle_model_scope"] == "imprint_nonland_card_reduce_spells_sharing_card_type_v1"
    assert effect["_rule_logical_key"] == "battle_rule_v1:ac1ab7b07d9e4a4cb5ce455bc50ccb7e"
    assert effect["_rule_oracle_hash"] == "32a67417a2ff0e86b36986f3d0973d8c"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"


def test_semblance_anvil_imprints_nonland_and_reduces_shared_type_spells_only():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        imprint_card = {
            "name": "Thrill of Possibility",
            "type_line": "Instant",
            "cmc": 2,
            "mana_cost": "{1}{R}",
            "effect": "draw_cards",
        }
        future_instant = {
            "name": "Big Score",
            "type_line": "Instant",
            "cmc": 4,
            "mana_cost": "{3}{R}",
            "effect": "draw_cards",
        }
        unrelated_creature = {
            "name": "Sun Titan",
            "type_line": "Creature - Giant",
            "cmc": 6,
            "mana_cost": "{4}{W}{W}",
            "effect": "creature",
        }
        active.hand = [imprint_card, future_instant, unrelated_creature]
        card = {"name": "Semblance Anvil", "type_line": "Artifact", "cmc": 3, "mana_cost": "{3}"}
        effect = battle.get_card_effect(card)

        battle.apply_effect_immediate(
            active,
            [opponent],
            card,
            turn=4,
            rng=random.Random(612),
            effect_data_override=effect,
            stack=battle.Stack(),
            phase="precombat_main",
        )

        permanent = active.battlefield[0]
        shared_cost = battle.card_cost_for_player_state(active, future_instant)
        unrelated_cost = battle.card_cost_for_player_state(active, unrelated_creature)
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert imprint_card in active.exile
    assert imprint_card not in active.hand
    assert permanent["imprinted_card"] == "Thrill of Possibility"
    assert permanent["imprinted_card_types"] == ["instant"]
    assert shared_cost["generic"] == 1
    assert shared_cost["static_cost_reduction_total"] == 2
    assert shared_cost["static_cost_reductions"][0]["source"] == "Semblance Anvil"
    assert shared_cost["static_cost_reductions"][0]["shared_card_types"] == ["instant"]
    assert unrelated_cost["generic"] == 4
    assert "static_cost_reduction_total" not in unrelated_cost
    assert any(
        event == "imprint_resolved"
        and data.get("card") == "Semblance Anvil"
        and data.get("imprinted") == "Thrill of Possibility"
        and data.get("imprinted_card_types") == ["instant"]
        for event, data in events
    )


def test_semblance_anvil_without_nonland_imprint_does_not_reduce_costs():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(battle, "Lorehold")
        opponent = player(battle, "Opponent")
        active.hand = [
            {"name": "Mountain", "type_line": "Basic Land - Mountain", "effect": "land", "cmc": 0}
        ]
        card = {"name": "Semblance Anvil", "type_line": "Artifact", "cmc": 3, "mana_cost": "{3}"}
        effect = battle.get_card_effect(card)

        battle.apply_effect_immediate(
            active,
            [opponent],
            card,
            turn=5,
            rng=random.Random(616),
            effect_data_override=effect,
            stack=battle.Stack(),
            phase="precombat_main",
        )

        target_spell = {
            "name": "Big Score",
            "type_line": "Instant",
            "cmc": 4,
            "mana_cost": "{3}{R}",
            "effect": "draw_cards",
        }
        cost = battle.card_cost_for_player_state(active, target_spell)
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert cost["generic"] == 3
    assert "static_cost_reduction_total" not in cost
    assert active.battlefield[0].get("imprinted_card_types") in (None, [])
    assert any(
        event == "imprint_failed"
        and data.get("card") == "Semblance Anvil"
        and data.get("cost") == "imprint_nonland_card"
        for event, data in events
    )


if __name__ == "__main__":
    test_semblance_anvil_get_card_effect_is_runtime_source()
    test_semblance_anvil_imprints_nonland_and_reduces_shared_type_spells_only()
    test_semblance_anvil_without_nonland_imprint_does_not_reduce_costs()
    print("PASS test_semblance_anvil_runtime")
