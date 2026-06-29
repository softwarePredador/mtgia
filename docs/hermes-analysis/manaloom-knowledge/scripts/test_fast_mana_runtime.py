#!/usr/bin/env python3
"""Focused runtime tests for exact fast-mana artifact rules."""

from __future__ import annotations

import importlib.util
import random
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_fast_mana_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_pg255_fast_mana_rules_resolve_from_curated_sqlite():
    battle = load_battle()

    expected = {
        "Ashnod's Altar": (
            "passive",
            "activated_sacrifice_creature_add_two_colorless_mana_v1",
            "battle_rule_v1:5fd05007191c6e481e8371724035031c",
            "dd3e1f004f2b178f31b638fad9cad591",
        ),
        "Chrome Mox": (
            "ramp_permanent",
            "zero_mana_artifact_imprint_nonartifact_nonland_tap_add_imprinted_color_v1",
            "battle_rule_v1:4b4ae6ec37e017046c6671e1a5985f17",
            "44481be7f5347792ede1a9b679a424b3",
        ),
        "Mox Diamond": (
            "ramp_permanent",
            "zero_mana_artifact_discard_land_etb_tap_add_any_color_v1",
            "battle_rule_v1:0a78dec9b9b2b0b5218b7d0a64a9afb3",
            "517f664e6c81ce9c204c09a20e14be2d",
        ),
    }

    for name, (effect, scope, key, oracle_hash) in expected.items():
        rule = battle.get_card_effect({"name": name, "type_line": "Artifact"})
        assert rule["effect"] == effect
        assert rule["battle_model_scope"] == scope
        assert rule["_rule_logical_key"] == key
        assert rule["_rule_oracle_hash"] == oracle_hash
        assert rule["_rule_source"] == "curated"
        assert rule["_rule_review_status"] == "verified"
        assert rule["_rule_execution_status"] == "auto"


def test_chrome_mox_imprints_colored_nonartifact_nonland_card():
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Active", None, [])
        opponent = battle.Player("Opponent", None, [])
        mox = {"name": "Chrome Mox", "cmc": 0, "type_line": "Artifact"}
        imprint_card = {
            "name": "Red Filler",
            "cmc": 5,
            "type_line": "Sorcery",
            "effect": "draw_cards",
            "color_identity": ["R"],
        }
        active.hand = [mox, imprint_card]
        active.command_zone = [
            {
                "name": "Cheap Commander",
                "cmc": 1,
                "type_line": "Legendary Creature",
                "effect": "creature",
                "is_commander": True,
            }
        ]

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(42),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert acted is True
    assert imprint_card not in active.hand
    assert any(card.get("name") == "Red Filler" for card in active.exile)
    assert any(
        permanent.get("name") == "Chrome Mox"
        and permanent.get("imprinted_card") == "Red Filler"
        and permanent.get("mana_produced") == 1
        for permanent in active.battlefield
        if isinstance(permanent, dict)
    )
    assert any(
        event == "imprint_resolved"
        and data.get("card") == "Chrome Mox"
        and data.get("imprinted") == "Red Filler"
        for event, data in events
    )


def test_mox_diamond_discards_land_only_when_it_unlocks_commander():
    battle = load_battle()
    events = []
    decisions = []
    previous_event_handler = battle.REPLAY_EVENT_HANDLER
    previous_trace_handler = battle.DECISION_TRACE_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.DECISION_TRACE_HANDLER = decisions.append
    try:
        active = battle.Player("Active", None, [])
        opponent = battle.Player("Opponent", None, [])
        mox = {"name": "Mox Diamond", "cmc": 0, "type_line": "Artifact"}
        land = {"name": "Savannah", "effect": "land", "type_line": "Land"}
        active.hand = [mox, land]
        active.command_zone = [
            {
                "name": "Cheap Commander",
                "cmc": 1,
                "type_line": "Legendary Creature",
                "effect": "creature",
                "is_commander": True,
            }
        ]

        acted = battle.cast_spells_v8(
            active,
            [opponent],
            [active, opponent],
            turn=1,
            phase="precombat_main",
            stack=battle.Stack(),
            rng=random.Random(39),
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_event_handler
        battle.DECISION_TRACE_HANDLER = previous_trace_handler

    assert acted is True
    assert land not in active.hand
    assert any(card.get("name") == "Savannah" for card in active.graveyard)
    assert any(
        permanent.get("name") == "Mox Diamond"
        for permanent in active.battlefield
        if isinstance(permanent, dict)
    )
    assert any(
        event == "additional_cost_paid"
        and data.get("card") == "Mox Diamond"
        and data.get("cost") == "discard_land"
        and data.get("unlock_card") == "Cheap Commander"
        for event, data in events
    )
    assert any(
        trace["decision_type"] == "cast_spell"
        and trace["chosen_option"].get("card") == "Mox Diamond"
        and trace["expected_payoff_reason"] == "same_turn_commander_cast"
        for trace in decisions
    )


def test_ashnods_altar_sacrifices_token_for_contextual_mana_unlock():
    battle = load_battle()
    events = []
    decisions = []
    previous_event_handler = battle.REPLAY_EVENT_HANDLER
    previous_trace_handler = battle.DECISION_TRACE_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.DECISION_TRACE_HANDLER = decisions.append
    try:
        active = battle.Player("Active", None, [])
        opponent = battle.Player("Opponent", None, [])
        token = battle.create_creature_token(
            active,
            name="Servo Token",
            power=1,
            toughness=1,
        )
        altar_rule = battle.get_card_effect({"name": "Ashnod's Altar", "type_line": "Artifact"})
        altar = {"name": "Ashnod's Altar", "cmc": 3, "type_line": "Artifact", **altar_rule}
        active.battlefield.extend(
            [
                altar,
                {
                    "name": "Wastes",
                    "effect": "land",
                    "type_line": "Basic Land",
                    "produces": "C",
                    "mana_produced": 1,
                },
            ]
        )
        active.hand = [
            {
                "name": "Approach of the Second Sun",
                "cmc": 7,
                "mana_cost": "{3}",
                "type_line": "Sorcery",
            }
        ]
        active.refresh_mana_sources(turn=4)

        activations = battle.activate_sacrifice_mana_artifacts(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_event_handler
        battle.DECISION_TRACE_HANDLER = previous_trace_handler

    assert activations == 1
    assert active.available_mana() == 3
    assert token not in active.battlefield
    assert altar in active.battlefield
    assert any(
        event == "utility_artifact_activated"
        and data.get("card") == "Ashnod's Altar"
        and data.get("activation_kind") == "sacrifice_creature_for_mana_unlock"
        and data.get("sacrificed") == "Servo Token"
        and data.get("unlock_target") == "Approach of the Second Sun"
        and data.get("mana_added") == 2
        for event, data in events
    )
    assert any(
        decision.get("decision_type") == "utility_artifact_activation"
        and decision.get("chosen_option", {}).get("action") == "activate_sacrifice_mana_artifact"
        and "sacrifice_creature" in decision.get("risk_flags", [])
        for decision in decisions
    )
