#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "battle_package_end_to_end_validation.py"


def load_module():
    spec = importlib.util.spec_from_file_location("battle_package_end_to_end_validation_mod", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validator = load_module()


def manifest_with_expected_rule() -> dict:
    return {
        "expected_rules": [
            {
                "normalized_name": "verge rangers",
                "card_name": "Verge Rangers",
                "logical_rule_key": "battle_rule_v1:abc",
                "oracle_hash": "hash123",
                "review_status": "verified",
                "execution_status": "auto",
                "min_rule_version": 2,
                "required_effect_fields": {
                    "effect": "topdeck_play",
                    "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
                },
                "forbid_annotation_only": True,
            }
        ]
    }


def test_validate_snapshot_derives_checks_from_expected_rules(tmp_path) -> None:
    snapshot_path = tmp_path / "known_cards_canonical_snapshot.json"
    snapshot_path.write_text(
        json.dumps(
            {
                "Verge Rangers": {
                    "battle_rule_logical_key": "battle_rule_v1:abc",
                    "battle_rule_oracle_hash": "hash123",
                    "battle_rule_review_status": "verified",
                    "battle_rule_execution_status": "auto",
                    "battle_rule_version": 2,
                    "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
                }
            }
        ),
        encoding="utf-8",
    )
    manifest = manifest_with_expected_rule()

    results = validator.validate_snapshot(
        snapshot_path,
        manifest,
        validator.expected_rules_by_key(manifest),
    )

    assert len(results) == 1
    assert results[0]["card_name"] == "Verge Rangers"
    assert results[0]["battle_model_scope"] == "look_top_library_play_lands_from_top_if_opponent_more_lands_v1"


def test_validate_runtime_lookup_derives_checks_from_expected_rules() -> None:
    class FakeBattle:
        @staticmethod
        def get_card_effect(card):
            assert card == {"name": "Verge Rangers"}
            return {
                "effect": "topdeck_play",
                "_rule_logical_key": "battle_rule_v1:abc",
                "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
            }

    results = validator.validate_runtime_lookup(FakeBattle, manifest_with_expected_rule())

    assert len(results) == 1
    assert results[0]["card_name"] == "Verge Rangers"
    assert results[0]["effect"] == "topdeck_play"


def test_simple_activated_damage_runner_executes_random_discard_cost() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "enchantment",
        "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
        "activated_effect": "direct_damage",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
        "activated_damage_amount": 2,
        "target": "any_target",
        "target_constraints": {"scope": "any_target"},
        "activation_cost_mana": "{2}",
        "activation_cost_generic": 2,
        "activation_cost_colors": [],
        "activation_requires_tap": False,
        "activation_requires_sacrifice": False,
        "activation_discard_count": 1,
        "activation_discard_target": "any_card",
        "activation_requires_discard_card": True,
        "activation_discard_random": True,
        "_rule_logical_key": "battle_rule_v1:stormbind",
    }
    try:
        result = validator.run_simple_activated_damage(
            battle,
            {
                "name": "Stormbind activates damage ability",
                "type": "simple_activated_damage",
                "card": {"name": "Stormbind"},
                "opponent_life": 7,
                "controller_mana": {"generic": 2},
                "controller_hand": [
                    {"name": "E2E Spare Card A", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
                    {"name": "E2E Spare Card B", "type_line": "Instant", "effect": "direct_damage", "cmc": 1},
                ],
                "expected_damage": 2,
                "expected_discard_count": 1,
                "expected_discard_target": "any_card",
                "expected_discard_random": True,
                "logical_rule_key": "battle_rule_v1:stormbind",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Stormbind"
    assert result["damage"] == 2
    assert result["discarded_count"] == 1
    assert result["opponent_life"] == 5


def test_simple_mana_source_refresh_runner_executes_partial_mana_rule() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "ramp_permanent",
        "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "WUBRG",
        "mana_activation_requires_tap": True,
        "modeled_ability_subset": "mana_source_only",
        "_runtime_partial": True,
        "_rule_logical_key": "battle_rule_v1:caravan",
    }
    try:
        result = validator.run_simple_mana_source_refresh(
            battle,
            {
                "name": "Cultivator's Caravan refreshes modeled mana source",
                "type": "simple_mana_source_refresh",
                "card": {"name": "Cultivator's Caravan"},
                "expected_available_mana_after_refresh": 1,
                "expected_tapped": True,
                "expected_sources": 1,
                "expected_conditional_mana": 1,
                "logical_rule_key": "battle_rule_v1:caravan",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Cultivator's Caravan"
    assert result["available_mana"] == 1
    assert result["conditional_mana"] == 1
    assert result["tapped"] is True


def test_creature_dies_create_treasure_runner_executes_trigger() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_creature_dies_create_treasure_v1",
        "ability_kind": "triggered",
        "trigger": "dies",
        "dies_trigger_effect": "treasure_maker",
        "dies_or_graveyard_from_battlefield_treasure": True,
        "dies_treasure_count": 1,
        "treasure_count": 1,
        "keywords": ["defender"],
        "defender": True,
        "_rule_logical_key": "battle_rule_v1:gleaming-barrier",
    }
    try:
        result = validator.run_creature_dies_create_treasure(
            battle,
            {
                "name": "Gleaming Barrier dies and creates Treasure",
                "type": "creature_dies_create_treasure",
                "card": {"name": "Gleaming Barrier", "type_line": "Creature", "effect": "creature"},
                "expected_treasure_count": 1,
                "expected_keywords": ["defender"],
                "logical_rule_key": "battle_rule_v1:gleaming-barrier",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Gleaming Barrier"
    assert result["treasures_created"] == 1
    assert result["controller_treasures_after"] == 1
    assert result["validated_keywords"] == ["defender"]


def test_simple_mana_source_refresh_runner_pays_activation_cost_from_support_source() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "ramp_permanent",
        "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "WUBRG",
        "mana_activation_requires_tap": True,
        "activation_mana_cost": "{G}",
        "_rule_logical_key": "battle_rule_v1:ceta",
    }
    try:
        result = validator.run_simple_mana_source_refresh(
            battle,
            {
                "name": "Ceta Disciple refreshes modeled mana source",
                "type": "simple_mana_source_refresh",
                "card": {"name": "Ceta Disciple"},
                "controller_mana": {
                    "generic": 0,
                    "white": 0,
                    "blue": 0,
                    "black": 0,
                    "red": 0,
                    "green": 1,
                },
                "expected_available_mana_after_refresh": 1,
                "expected_tapped": True,
                "expected_sources": 2,
                "expected_conditional_mana": 1,
                "logical_rule_key": "battle_rule_v1:ceta",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Ceta Disciple"
    assert result["available_mana"] == 1
    assert result["conditional_mana"] == 1
    assert result["sources"] == 2
