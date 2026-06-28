#!/usr/bin/env python3
"""Focused runtime tests for Goliath Daydreamer dream-counter free casts."""

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
    spec = importlib.util.spec_from_file_location("battle_goliath_daydreamer_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def player(battle, name, deck=None):
    return battle.Player(name, None, deck or [], strategy="midrange")


def goliath_daydreamer():
    return {
        "name": "Goliath Daydreamer",
        "effect": "creature",
        "battle_model_scope": "instant_sorcery_from_hand_exile_dream_counter_attack_free_cast_v1",
        "goliath_daydreamer_exile_resolved_instant_sorcery": True,
        "goliath_daydreamer_attack_cast_dream_counter": True,
        "type_line": "Creature - Giant Wizard",
        "power": 4,
        "toughness": 4,
        "_rule_logical_key": "battle_rule_v1:goliath-daydreamer-test",
        "_rule_oracle_hash": "goliath-daydreamer-test-hash",
        "_rule_review_status": "verified",
        "_rule_execution_status": "auto",
    }


def draw_spell(name="Dream Cantrip"):
    return {
        "name": name,
        "type_line": "Instant",
        "cmc": 2,
        "effect": "draw_cards",
        "count": 1,
    }


def test_goliath_daydreamer_exiles_hand_spell_then_attack_free_casts_it():
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = player(
            battle,
            "Lorehold",
            [
                {"name": "Drawn Card", "type_line": "Sorcery", "cmc": 1, "effect": "draw_cards"},
            ],
        )
        opponent = player(battle, "Opponent")
        goliath = goliath_daydreamer()
        active.battlefield = [goliath]
        cantrip = draw_spell()
        effect_data = {
            "effect": "draw_cards",
            "count": 1,
            "_cast_context": {
                "source_zone": "hand",
                "phase": "precombat_main",
                "alternative_cost_kind": None,
            },
        }

        battle.apply_effect_immediate(
            active,
            [opponent],
            cantrip,
            turn=3,
            rng=random.Random(613),
            effect_data_override=effect_data,
            stack=battle.Stack(),
            phase="precombat_main",
        )

        assert cantrip in active.exile
        assert cantrip.get("_goliath_daydreamer_dream_counter") is True
        assert cantrip not in active.graveyard

        cast_count = battle.resolve_goliath_daydreamer_dream_counter_attack_triggers(
            active,
            [goliath],
            [opponent],
            [active, opponent],
            turn=4,
            rng=random.Random(614),
            phase="combat",
            stack=battle.Stack(),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert cast_count == 1
    assert cantrip not in active.exile
    assert cantrip in active.graveyard
    assert any(card.get("name") == "Drawn Card" for card in active.hand)
    assert any(
        event == "goliath_daydreamer_dream_counter_replacement_marked"
        and data.get("card") == "Dream Cantrip"
        for event, data in events
    )
    assert any(
        event == "replacement_exiled_on_resolution"
        and data.get("card") == "Dream Cantrip"
        and data.get("replacement_reason") == "goliath_daydreamer_dream_counter"
        for event, data in events
    )
    assert any(
        event == "goliath_daydreamer_free_cast"
        and data.get("cast_card") == "Dream Cantrip"
        and data.get("cast_without_paying_mana_cost") is True
        and data.get("source_zone") == "exile"
        and data.get("locked_cost", {}).get("spend_tags") == ["cast_without_paying_mana_cost"]
        for event, data in events
    )
    assert any(
        event == "spell_resolved"
        and data.get("card") == "Dream Cantrip"
        and data.get("source_zone") == "exile"
        and data.get("locked_cost", {}).get("spend_tags") == ["cast_without_paying_mana_cost"]
        for event, data in events
    )


def test_goliath_daydreamer_does_not_exile_non_hand_recast_spell():
    battle = load_battle()
    active = player(battle, "Lorehold")
    active.battlefield = [goliath_daydreamer()]
    recast = draw_spell("Recast Cantrip")

    battle.finish_resolved_spell(
        active,
        recast,
        turn=5,
        effect_data={
            "effect": "draw_cards",
            "_cast_context": {"source_zone": "exile"},
        },
    )

    assert recast in active.graveyard
    assert recast not in active.exile
    assert not recast.get("_goliath_daydreamer_dream_counter")


if __name__ == "__main__":
    test_goliath_daydreamer_exiles_hand_spell_then_attack_free_casts_it()
    test_goliath_daydreamer_does_not_exile_non_hand_recast_spell()
    print("PASS test_goliath_daydreamer_runtime")
