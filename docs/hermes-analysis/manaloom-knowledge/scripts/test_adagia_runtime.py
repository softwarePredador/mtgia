#!/usr/bin/env python3
"""Focused runtime tests for Adagia Station 12 copy-token behavior."""

from __future__ import annotations

import importlib.util
import sqlite3
import tempfile
from contextlib import closing
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_adagia_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def adagia_effect() -> dict:
    return {
        "effect": "copy_creature_token",
        "ability_kind": "activated",
        "battle_model_scope": "station_12_copy_artifact_or_enchantment_you_control_legendary_token_v1",
        "copy_target_types": ["artifact", "enchantment"],
        "target_controller": "own",
        "token_legendary": True,
        "activate_only_as_sorcery": True,
        "activation_cost_mana": "{3}{W}",
        "activation_requires_tap": True,
        "station_level_required": 12,
    }


def adagia_card(battle) -> dict:
    return battle.prepare_entering_permanent(
        {
            "name": "Adagia, Windswept Bastion",
            "type_line": "Land — Planet",
            **adagia_effect(),
        }
    )


def test_adagia_get_card_effect_preserves_land_and_exposes_station_copy_activation() -> None:
    battle = load_battle()
    with tempfile.TemporaryDirectory() as tmpdir:
        sqlite_db = Path(tmpdir) / "knowledge.db"
        with closing(sqlite3.connect(sqlite_db)) as conn:
            battle.battle_rule_registry.ensure_battle_card_rules(conn)
            battle.battle_rule_registry.upsert_battle_card_rule(
                conn,
                "Adagia, Windswept Bastion",
                {"effect": "land"},
                source="curated",
                confidence=0.99,
                review_status="verified",
                logical_rule_key_value="battle_rule_v1:001-land",
            )
            battle.battle_rule_registry.upsert_battle_card_rule(
                conn,
                "Adagia, Windswept Bastion",
                adagia_effect(),
                source="curated",
                confidence=0.99,
                review_status="verified",
                logical_rule_key_value="battle_rule_v1:999-station-copy",
            )
            conn.commit()
        old_db = battle.DB
        try:
            battle.DB = str(sqlite_db)
            resolved = battle.get_card_effect(
                {
                    "name": "Adagia, Windswept Bastion",
                    "type_line": "Land — Planet",
                    "oracle_text": "",
                }
            )
        finally:
            battle.DB = old_db

    assert resolved["effect"] == "land"
    assert resolved["activated_effect"] == "copy_creature_token"
    assert resolved["station_level_required"] == 12
    assert resolved["activation_cost_mana"] == "{3}{W}"
    assert resolved["_rule_runtime_selection"]["selection_mode"] == (
        "primary_with_executable_activated_abilities"
    )
    assert len(resolved["_activated_rule_effects"]) == 1
    assert resolved["_activated_rule_effects"][0]["battle_model_scope"] == (
        "station_12_copy_artifact_or_enchantment_you_control_legendary_token_v1"
    )


def test_adagia_station_gate_blocks_copy_before_level_12() -> None:
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Lorehold", None, [])
        opponent = battle.Player("Opponent", None, [])
        source = adagia_card(battle)
        target = {"name": "Sol Ring", "type_line": "Artifact", "effect": "mana_rock"}
        active.battlefield = [source, target]

        result = battle.resolve_copy_creature_token(
            active,
            source,
            adagia_effect(),
            turn=6,
            opponents=[opponent],
            finish_spell=False,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert result is None
    assert len(active.battlefield) == 2
    assert any(
        event == "copy_creature_token_failed"
        and data.get("card") == "Adagia, Windswept Bastion"
        and data.get("reason") == "station_level_required"
        and data.get("station_level_required") == 12
        for event, data in events
    )


def test_adagia_precombat_engine_activates_station_copy_after_level_12() -> None:
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Lorehold", None, [])
        opponent = battle.Player("Opponent", None, [])
        source = battle.prepare_entering_permanent(
            {
                "name": "Adagia, Windswept Bastion",
                "type_line": "Land — Planet",
                "effect": "land",
                "activated_effect": "copy_creature_token",
                "station_level_required": 12,
                "activation_cost_mana": "{3}{W}",
                "activation_requires_tap": True,
                "_activated_rule_effects": [adagia_effect()],
            }
        )
        source["charge_counters"] = 12
        source["station_online"] = True
        target = {"name": "Sol Ring", "type_line": "Artifact", "effect": "mana_rock"}
        active.battlefield = [source, target]
        active.mana_pool.add_generic(3)
        active.mana_pool.add("white", 1)

        activated = battle.activate_secondary_copy_creature_token_abilities(
            active,
            [opponent],
            turn=8,
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert activated == 1
    assert source["tapped"] is True
    assert any(card.get("copy_of") == "Sol Ring" for card in active.battlefield)
    assert any(
        event == "activated_ability_resolved"
        and data.get("card") == "Adagia, Windswept Bastion"
        and data.get("activation_cost") == "{3}{W}"
        and data.get("tokens_created") == 1
        for event, data in events
    )


def test_adagia_station_12_creates_legendary_artifact_or_enchantment_copy() -> None:
    battle = load_battle()
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Lorehold", None, [])
        opponent = battle.Player("Opponent", None, [])
        source = adagia_card(battle)
        source["charge_counters"] = 12
        source["station_online"] = True
        target = {"name": "Sol Ring", "type_line": "Artifact", "effect": "mana_rock"}
        active.battlefield = [source, target]

        created = battle.resolve_copy_creature_token(
            active,
            source,
            adagia_effect(),
            turn=7,
            opponents=[opponent],
            finish_spell=False,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert created is not None
    assert len(created) == 1
    token = created[0]
    assert token["copy_of"] == "Sol Ring"
    assert token["legendary"] is True
    assert "Legendary" in token["type_line"]
    assert any(
        event == "copy_creature_token_created"
        and data.get("card") == "Adagia, Windswept Bastion"
        and data.get("target") == "Sol Ring"
        and data.get("token_legendary") is True
        for event, data in events
    )
