#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "battle_package_end_to_end_validation.py"
PACKAGE_BUILDER_PATH = SCRIPT_DIR / "xmage_batch_pg_package_builder.py"


def load_module():
    spec = importlib.util.spec_from_file_location("battle_package_end_to_end_validation_mod", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_package_builder():
    spec = importlib.util.spec_from_file_location("xmage_batch_pg_package_builder_mod", PACKAGE_BUILDER_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validator = load_module()
package_builder = load_package_builder()


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


def test_equipment_static_attachment_runner_executes_boost_and_keywords() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    effect = {
        "effect": "equipment_static_attachment",
        "battle_model_scope": "xmage_equipment_static_power_toughness_attachment_v1",
        "power_boost": 2,
        "toughness_boost": 2,
        "static_power_bonus": 2,
        "static_toughness_bonus": 2,
        "attached_keywords": ["first_strike", "flying"],
        "_rule_logical_key": "battle_rule_v1:maul-of-the-skyclaves",
    }
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: dict(effect)
    try:
        result = validator.run_equipment_static_power_toughness_attachment(
            battle,
            {
                "name": "Maul of the Skyclaves equipment static P/T attaches",
                "type": "equipment_static_power_toughness_attachment",
                "card": {"name": "Maul of the Skyclaves", "type_line": "Artifact - Equipment"},
                "target": {
                    "name": "E2E Equipment Target",
                    "type_line": "Creature - Soldier",
                    "base_power": 2,
                    "base_toughness": 2,
                    "power": 2,
                    "toughness": 2,
                },
                "expected_power": 4,
                "expected_toughness": 4,
                "expected_keywords": ["first_strike", "flying"],
                "expected_source": "Maul of the Skyclaves",
                "logical_rule_key": "battle_rule_v1:maul-of-the-skyclaves",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Maul of the Skyclaves"
    assert result["target_power"] == 4
    assert result["target_toughness"] == 4
    assert result["validated_keywords"] == ["first_strike", "flying"]
    assert result["attached_event"]["grants"] == ["flying", "first_strike"]


def test_fixed_damage_target_spell_runner_executes_damage_and_cant_be_countered() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "direct_damage",
        "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
        "amount": 4,
        "damage": 4,
        "target": "creature",
        "target_constraints": {"card_types": ["creature"], "target_colors": ["W", "U"]},
        "cant_be_countered": True,
    }
    try:
        result = validator.run_fixed_damage_target_spell(
            battle,
            {
                "name": "Rending Volley deals fixed target damage",
                "type": "fixed_damage_target_spell",
                "card": {"name": "Rending Volley", "type_line": "Instant"},
                "target": {
                    "name": "E2E Fixed Damage Legal Target",
                    "type_line": "Creature",
                    "effect": "creature",
                    "colors": ["W"],
                    "power": 2,
                    "toughness": 2,
                },
                "nonmatching_target": {
                    "name": "E2E Fixed Damage Illegal Target",
                    "type_line": "Creature",
                    "effect": "creature",
                    "colors": ["B"],
                    "power": 2,
                    "toughness": 2,
                },
                "expected_damage": 4,
                "expected_life_gain": 0,
                "expected_cant_be_countered": True,
                "expected_target_constraints": {"card_types": ["creature"], "target_colors": ["W", "U"]},
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["damage"] == 4
    assert result["life_gained"] == 0
    assert result["target"] == "E2E Fixed Damage Legal Target"
    assert result["cant_be_countered"] is True


def test_fixed_damage_target_spell_runner_pays_return_land_cost() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "direct_damage",
        "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
        "amount": 5,
        "damage": 5,
        "target": "creature_or_planeswalker",
        "target_constraints": {"scope": "creature_or_planeswalker"},
        "additional_cost": "return_land_to_hand",
        "requires_return_land_to_hand": True,
    }
    try:
        result = validator.run_fixed_damage_target_spell(
            battle,
            {
                "name": "Devour in Flames pays return-land cost",
                "type": "fixed_damage_target_spell",
                "card": {"name": "Devour in Flames", "type_line": "Sorcery"},
                "target": {
                    "name": "E2E Fixed Damage Legal Target",
                    "type_line": "Creature",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                },
                "expected_damage": 5,
                "expected_life_gain": 0,
                "expected_target_constraints": {"scope": "creature_or_planeswalker"},
                "controller_battlefield": [
                    {
                        "name": "E2E Return Cost Land",
                        "type_line": "Basic Land - Mountain",
                        "effect": "land",
                        "tapped": True,
                    }
                ],
                "expected_additional_cost": "return_land_to_hand",
                "expected_returned_land_name": "E2E Return Cost Land",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["damage"] == 5
    assert result["additional_cost"] == "return_land_to_hand"


def test_fixed_damage_target_spell_runner_pays_mixed_sacrifice_cost() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "direct_damage",
        "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
        "amount": 5,
        "damage": 5,
        "target": "creature",
        "target_constraints": {"card_types": ["creature"]},
        "additional_cost": "sacrifice_creature_or_enchantment",
        "requires_sacrifice_creature_or_enchantment": True,
    }
    try:
        result = validator.run_fixed_damage_target_spell(
            battle,
            {
                "name": "Final Flare pays mixed sacrifice cost",
                "type": "fixed_damage_target_spell",
                "card": {"name": "Final Flare", "type_line": "Instant"},
                "target": {
                    "name": "E2E Fixed Damage Legal Target",
                    "type_line": "Creature",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                },
                "expected_damage": 5,
                "expected_life_gain": 0,
                "expected_target_constraints": {"card_types": ["creature"]},
                "controller_battlefield": [
                    {
                        "name": "E2E Sacrifice Cost Enchantment",
                        "type_line": "Enchantment",
                        "effect": "enchantment",
                    }
                ],
                "expected_additional_cost": "sacrifice_creature_or_enchantment",
                "expected_sacrificed_name": "E2E Sacrifice Cost Enchantment",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["damage"] == 5
    assert result["additional_cost"] == "sacrifice_creature_or_enchantment"


def test_single_target_removal_runner_pays_or_discard_cost() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "remove_creature",
        "battle_model_scope": "xmage_destroy_target_spell_v1",
        "target": "creature_or_planeswalker",
        "target_constraints": {"scope": "creature_or_planeswalker"},
        "destination": "graveyard",
        "additional_cost": "choose_discard_card_or_pay_life",
        "requires_one_additional_cost_option": True,
        "additional_cost_options": [
            {"cost": "discard_card", "requires_discard_card": True},
            {"cost": "pay_life", "requires_pay_life": True, "pay_life_amount": 3},
        ],
    }
    try:
        result = validator.run_single_target_removal(
            battle,
            {
                "name": "Bitter Triumph pays discard option",
                "type": "single_target_removal",
                "card": {"name": "Bitter Triumph", "type_line": "Instant"},
                "target": {
                    "name": "E2E Legal Removal Target",
                    "type_line": "Creature",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                },
                "nonmatching_target": {
                    "name": "E2E Illegal Removal Target",
                    "type_line": "Land",
                    "effect": "land",
                },
                "controller_hand": [
                    {
                        "name": "E2E Discard Cost Card",
                        "type_line": "Sorcery",
                        "effect": "draw_cards",
                    }
                ],
                "expected_destination": "graveyard",
                "expected_effect": "remove_creature",
                "expected_target_constraints": {"scope": "creature_or_planeswalker"},
                "expected_additional_cost": "discard_card",
                "expected_discarded_name": "E2E Discard Cost Card",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["target"] == "E2E Legal Removal Target"
    assert result["additional_cost"] == "discard_card"


def test_single_target_removal_runner_pays_life_cost() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "remove_creature",
        "battle_model_scope": "xmage_destroy_target_spell_v1",
        "target": "creature",
        "target_constraints": {"card_types": ["creature"]},
        "destination": "graveyard",
        "additional_cost": "pay_life",
        "requires_pay_life": True,
        "pay_life_amount": 3,
    }
    try:
        result = validator.run_single_target_removal(
            battle,
            {
                "name": "Fumarole pays life cost",
                "type": "single_target_removal",
                "card": {"name": "Fumarole", "type_line": "Sorcery"},
                "target": {
                    "name": "E2E Legal Removal Target",
                    "type_line": "Creature",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                },
                "controller_life": 20,
                "expected_destination": "graveyard",
                "expected_effect": "remove_creature",
                "expected_target_constraints": {"card_types": ["creature"]},
                "expected_additional_cost": "pay_life",
                "expected_pay_life_amount": 3,
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["target"] == "E2E Legal Removal Target"
    assert result["additional_cost"] == "pay_life"
    assert result["pay_life_amount"] == 3


def test_fixed_damage_target_spell_runner_validates_shuffle_self() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "direct_damage",
        "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
        "amount": 5,
        "damage": 5,
        "target": "any_target",
        "target_constraints": {"scope": "any_target"},
        "shuffle_self_into_library_on_resolution": True,
    }
    try:
        result = validator.run_fixed_damage_target_spell(
            battle,
            {
                "name": "Beacon of Destruction deals fixed target damage",
                "type": "fixed_damage_target_spell",
                "card": {"name": "Beacon of Destruction", "type_line": "Instant"},
                "expected_damage": 5,
                "expected_life_gain": 0,
                "expected_target_constraints": {"scope": "any_target"},
                "expect_shuffle_self": True,
                "expected_spell_destination": "library",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["damage"] == 5
    assert result["shuffled_self_into_library"] is True
    assert any(
        event == "spell_shuffled_into_library_on_resolution"
        and data.get("card") == "Beacon of Destruction"
        and data.get("to_zone") == "library"
        for event, data in events
    )


def test_creature_etb_create_tokens_runner_preserves_noncreature_artifact_token() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_creature_etb_create_tokens_v1",
        "ability_kind": "triggered",
        "trigger": "enters_battlefield",
        "etb_trigger_effect": "token_maker",
        "etb_token_count": 1,
        "etb_token_name": "Map Token",
        "etb_token_subtype": "Map",
        "etb_artifact_tokens": True,
        "etb_token_artifact_only": True,
        "etb_token_activated_ability": "explore_target_creature",
        "etb_token_activated_ability_status": "created_token_only",
    }
    try:
        result = validator.run_creature_etb_create_tokens(
            battle,
            {
                "name": "Cartographer's Companion enters and creates a Map token",
                "type": "creature_etb_create_tokens",
                "card": {
                    "name": "Cartographer's Companion",
                    "type_line": "Creature",
                    "effect": "creature",
                },
                "expected_token": {
                    "name": "Map Token",
                    "count": 1,
                    "power": None,
                    "toughness": None,
                    "subtype": "Map",
                    "colors": [],
                    "keywords": [],
                    "artifact": True,
                    "artifact_only": True,
                    "tapped": False,
                },
                "expected_total_tokens": 1,
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["tokens_created"] == 1


def test_counter_unless_pays_draw_runner_draws_when_tax_unpaid() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "counter",
        "battle_model_scope": "xmage_counter_target_spell_unless_controller_pays_generic_draw_card_v1",
        "target": "spell",
        "target_constraints": {"zone": "stack", "stack_object": "spell"},
        "counter_unless_pays_generic": 1,
        "draw_on_counter": 1,
        "instant": True,
    }
    try:
        result = validator.run_counter_unless_pays_response(
            battle,
            {
                "name": "Runeboggle counters unless tax is paid and draws",
                "type": "counter_unless_pays_response",
                "card": {
                    "name": "Runeboggle",
                    "type_line": "Instant",
                    "mana_cost": "{U}",
                    "cmc": 1,
                    "instant": True,
                },
                "target_spell": {
                    "name": "Counter Target Fixture",
                    "cmc": 7,
                    "mana_cost": "{5}{R}{R}",
                    "type_line": "Creature - Dragon",
                    "effect": "finisher",
                },
                "responder_mana": {"blue": 1},
                "active_mana": {"generic": 0},
                "expected_countered": True,
                "expected_counter_tax_paid": False,
                "expected_counter_unless_pays_generic": 1,
                "expected_cards_drawn": 1,
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Runeboggle"
    assert result["countered"] is True
    assert result["cards_drawn"] == 1


def test_counter_target_runner_validates_exile_replacement() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "counter",
        "battle_model_scope": "xmage_counter_target_spell_v1",
        "target": "spell",
        "target_constraints": {"zone": "stack", "stack_object": "spell"},
        "countered_spell_to_exile": True,
        "countered_spell_to_exile_reason": "counter_target_exile_replacement",
        "instant": True,
    }
    try:
        result = validator.run_counter_target_response(
            battle,
            {
                "name": "Dissipate counters and exiles",
                "type": "counter_target_response",
                "card": {
                    "name": "Dissipate",
                    "type_line": "Instant",
                    "mana_cost": "{1}{U}{U}",
                    "cmc": 3,
                    "instant": True,
                    "effect": "counter",
                    "battle_model_scope": "xmage_counter_target_spell_v1",
                    "target": "spell",
                    "target_constraints": {"zone": "stack", "stack_object": "spell"},
                    "countered_spell_to_exile": True,
                    "countered_spell_to_exile_reason": "counter_target_exile_replacement",
                },
                "target_stack_object": {
                    "name": "E2E Legal Counter Target",
                    "type_line": "Creature - Dragon",
                    "cmc": 7,
                    "effect": "finisher",
                },
                "target_stack_effect": {"effect": "finisher"},
                "nonmatching_stack_object": {
                    "name": "E2E Illegal Counter Target",
                    "type_line": "Activated Ability",
                    "effect": "activated_ability",
                    "cmc": 0,
                },
                "nonmatching_stack_effect": {"effect": "activated_ability"},
                "expected_countered_spell_to_exile": True,
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Dissipate"
    assert result["countered"] is True
    assert result["countered_spell_to_exile"] is True


def test_counter_target_runner_validates_top_library_replacement() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "counter",
        "battle_model_scope": "xmage_counter_target_spell_v1",
        "target": "spell",
        "target_constraints": {"zone": "stack", "stack_object": "spell"},
        "countered_spell_to_top_library": True,
        "countered_spell_to_top_library_reason": "counter_target_top_library_replacement",
        "instant": True,
    }
    try:
        result = validator.run_counter_target_response(
            battle,
            {
                "name": "Memory Lapse counters to library top",
                "type": "counter_target_response",
                "card": {
                    "name": "Memory Lapse",
                    "type_line": "Instant",
                    "mana_cost": "{1}{U}",
                    "cmc": 2,
                    "instant": True,
                    "effect": "counter",
                    "battle_model_scope": "xmage_counter_target_spell_v1",
                    "target": "spell",
                    "target_constraints": {"zone": "stack", "stack_object": "spell"},
                    "countered_spell_to_top_library": True,
                    "countered_spell_to_top_library_reason": (
                        "counter_target_top_library_replacement"
                    ),
                },
                "target_stack_object": {
                    "name": "E2E Legal Counter Target",
                    "type_line": "Creature - Dragon",
                    "cmc": 7,
                    "effect": "finisher",
                },
                "target_stack_effect": {"effect": "finisher"},
                "nonmatching_stack_object": {
                    "name": "E2E Illegal Counter Target",
                    "type_line": "Activated Ability",
                    "effect": "activated_ability",
                    "cmc": 0,
                },
                "nonmatching_stack_effect": {"effect": "activated_ability"},
                "expected_countered_spell_to_top_library": True,
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Memory Lapse"
    assert result["countered"] is True
    assert result["countered_spell_to_top_library"] is True
    assert any(
        event == "countered_spell_moved_to_library_top"
        and data.get("card") == "E2E Legal Counter Target"
        for event, data in events
    )


def test_board_wipe_runner_validates_destroy_filters() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "board_wipe",
        "battle_model_scope": "xmage_destroy_all_matching_permanents_spell_v1",
        "destroy_card_types": ["creature"],
        "destroy_mana_value_lte": 3,
        "destination": "graveyard",
    }
    try:
        result = validator.run_board_wipe(
            battle,
            {
                "name": "Consume the Meek destroys only low-value creatures",
                "type": "board_wipe",
                "card": {
                    "name": "Consume the Meek",
                    "type_line": "Instant",
                    "effect": "board_wipe",
                },
                "destroy_card_types": ["creature"],
                "destroy_mana_value_lte": 3,
                "logical_rule_key": "battle_rule_v1:consume-the-meek",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Consume the Meek"
    assert result["destroyed"] == 2
    assert result["expected_destroyed"] == 2


def test_board_wipe_runner_validates_extended_destroy_predicates() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    effect = {
        "effect": "board_wipe",
        "battle_model_scope": "xmage_destroy_all_matching_permanents_spell_v1",
        "destroy_card_types": ["creature"],
        "destroy_mana_value_lte": 0,
        "destroy_mana_value_lte_source": "x_value",
        "destroy_counter_state": "none",
        "destroy_combat_state": "blocking_or_blocked",
        "destroy_color_count_lt": 5,
        "destroy_dealt_damage_to_you_this_turn": True,
        "destroy_exclude_commanders": True,
        "destroy_enchanted_state": "not_enchanted",
        "destination": "graveyard",
    }
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: effect
    try:
        result = validator.run_board_wipe(
            battle,
            {
                "name": "Fixture selective wipe destroys only matching extended predicates",
                "type": "board_wipe",
                "card": {"name": "Fixture Selective Verdict", "type_line": "Sorcery"},
                **effect,
                "x_value": 3,
                "logical_rule_key": "battle_rule_v1:fixture-selective-verdict",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Fixture Selective Verdict"
    assert result["destroyed"] == 2
    assert result["expected_destroyed"] == 2


def test_mass_return_to_hand_runner_validates_return_filters() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    effect = {
        "effect": "mass_return_to_hand",
        "battle_model_scope": "xmage_return_all_matching_permanents_to_hand_spell_v1",
        "return_card_types": ["creature"],
        "return_controller": "any",
        "return_combat_state": "attacking",
        "destination": "hand",
    }
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: effect
    try:
        result = validator.run_mass_return_to_hand(
            battle,
            {
                "name": "Aetherize returns only attacking creatures",
                "type": "mass_return_to_hand",
                "card": {"name": "Aetherize", "type_line": "Instant"},
                **effect,
                "logical_rule_key": "battle_rule_v1:aetherize",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Aetherize"
    assert result["returned"] == 2
    assert result["expected_returned"] == 2


def test_global_stat_modifier_draw_spell_runner_executes_boost_and_draw() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "composite_resolution",
        "battle_model_scope": "xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1",
        "target": "attacking_creatures",
        "target_controller": "all",
        "target_constraints": {
            "card_types": ["creature"],
            "creature_filter": {"combat_state": "attacking"},
        },
        "creature_filter": {"combat_state": "attacking"},
        "power_delta": -2,
        "toughness_delta": 0,
        "draw_count": 1,
        "_composite_rule_components": [
            {
                "effect": "global_stat_modifier_until_eot",
                "battle_model_scope": "xmage_fixed_boost_filtered_creatures_until_eot_spell_v1",
                "target": "attacking_creatures",
                "target_controller": "all",
                "target_constraints": {
                    "card_types": ["creature"],
                    "creature_filter": {"combat_state": "attacking"},
                },
                "creature_filter": {"combat_state": "attacking"},
                "power_delta": -2,
                "toughness_delta": 0,
            },
            {
                "effect": "draw_cards",
                "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                "count": 1,
            },
        ],
    }
    try:
        result = validator.run_global_stat_modifier_draw_spell(
            battle,
            {
                "name": "Hydrolash globally modifies attacking creatures and draws 1",
                "type": "global_stat_modifier_draw_spell",
                "card": {"name": "Hydrolash", "type_line": "Instant"},
                "controller_battlefield": [
                    {
                        "name": "E2E Controller Matching Creature",
                        "type_line": "Creature - Soldier",
                        "power": 2,
                        "toughness": 2,
                        "attacking": True,
                    },
                    {"name": "E2E Controller Nonmatching Permanent", "type_line": "Artifact", "power": 2, "toughness": 2},
                ],
                "opponent_battlefield": [
                    {
                        "name": "E2E Opponent Matching Creature",
                        "type_line": "Creature - Soldier",
                        "power": 2,
                        "toughness": 2,
                        "attacking": True,
                    },
                    {"name": "E2E Opponent Nonmatching Permanent", "type_line": "Artifact", "power": 2, "toughness": 2},
                ],
                "library": [{"name": "E2E Draw Card 1", "type_line": "Instant"}],
                "expected_affected_names": [
                    "E2E Controller Matching Creature",
                    "E2E Opponent Matching Creature",
                ],
                "expected_affected_count": 2,
                "expected_power_delta": -2,
                "expected_toughness_delta": 0,
                "expected_draw_count": 1,
                "expected_target_controller": "all",
                "expected_creature_filter": {"combat_state": "attacking"},
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["affected_count"] == 2
    assert result["draw_count"] == 1
    assert result["creature_filter"] == {"combat_state": "attacking"}


def test_damage_target_create_treasure_runner_executes_damage_and_treasure() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "direct_damage",
        "battle_model_scope": "xmage_fixed_damage_target_create_treasure_spell_v1",
        "amount": 2,
        "damage": 2,
        "target": "any_target",
        "target_constraints": {"scope": "any_target"},
        "treasure_count": 1,
        "controller_treasure_tokens": 1,
        "treasure_recipient": "controller",
        "treasure_trigger": "on_resolution_after_damage",
    }
    try:
        result = validator.run_damage_target_create_treasure(
            battle,
            {
                "name": "Improvised Weaponry deals fixed target damage and creates Treasure",
                "type": "damage_target_create_treasure",
                "card": {"name": "Improvised Weaponry", "type_line": "Sorcery"},
                "target": {
                    "name": "E2E Damage Treasure Legal Target",
                    "type_line": "Creature",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                },
                "expected_damage": 2,
                "expected_life_gain": 0,
                "expected_treasure_count": 1,
                "expected_target_constraints": {"scope": "any_target"},
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["damage"] == 2
    assert result["treasures_created"] == 1
    assert result["controller_treasures"] == 1
    assert result["target"] == "E2E Damage Treasure Legal Target"


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


def test_static_cost_increase_runner_executes_colored_tax() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    previous_get_card_effect = battle.get_card_effect
    battle.get_card_effect = lambda card: {
        "effect": "static_cost_increase",
        "battle_model_scope": "xmage_static_generic_cost_increase_for_matching_spells_v1",
        "cost_increase_applies_to": "spells_you_cast",
        "cost_increase_generic": 0,
        "cost_increase_color_symbols": ["B"],
        "cost_increase_filters": [{"applies_to_spell_colors": ["B"]}],
        "_rule_logical_key": "battle_rule_v1:derelor",
    }
    try:
        result = validator.run_static_cost_increase_spell_cost(
            battle,
            {
                "name": "Derelor increases black spell cost",
                "type": "static_cost_increase_spell_cost",
                "card": {"name": "Derelor"},
                "target_spell": {
                    "name": "E2E Matching Taxed Spell",
                    "type_line": "Sorcery",
                    "colors": ["B"],
                    "mana_cost": "{1}{B}",
                    "cmc": 2,
                },
                "expected_generic": 1,
                "expected_colored": {"black": 2},
                "expected_static_cost_increase_total": 1,
                "expected_static_cost_increase_color_symbols": ["B"],
            },
            [],
        )
    finally:
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Derelor"
    assert result["generic"] == 1
    assert result["colored"]["black"] == 2
    assert result["static_cost_increase_color_symbols"] == ["B"]


def test_static_cost_reduction_runner_executes_colored_reduction() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    previous_get_card_effect = battle.get_card_effect
    battle.get_card_effect = lambda card: {
        "effect": "static_cost_reduction",
        "battle_model_scope": "xmage_static_generic_cost_reduction_for_matching_spells_v1",
        "cost_reduction_applies_to": "spells_you_cast",
        "cost_reduction_generic": 0,
        "cost_reduction_color_symbols": ["W", "B"],
        "cost_reduction_filters": [{"applies_to_subtypes": ["cleric"]}],
        "applies_to_subtypes": ["cleric"],
        "_rule_logical_key": "battle_rule_v1:edgewalker",
    }
    try:
        result = validator.run_static_cost_reduction_spell_cost(
            battle,
            {
                "name": "Edgewalker reduces cleric spell cost",
                "type": "static_cost_reduction_spell_cost",
                "card": {"name": "Edgewalker"},
                "target_spell": {
                    "name": "E2E Matching Cleric Spell",
                    "type_line": "Creature - Cleric",
                    "colors": ["W", "B"],
                    "mana_cost": "{1}{W}{B}",
                    "cmc": 3,
                },
                "expected_generic": 1,
                "expected_colored": {"white": 0, "black": 0},
                "expected_static_cost_reduction_total": 2,
                "expected_static_cost_reduction_color_symbols": ["W", "B"],
            },
            [],
        )
    finally:
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Edgewalker"
    assert result["generic"] == 1
    assert result["colored"]["white"] == 0
    assert result["colored"]["black"] == 0
    assert result["static_cost_reduction_total"] == 2
    assert result["static_cost_reduction_color_symbols"] == ["W", "B"]


def test_static_graveyard_threshold_runner_executes_distinct_card_type_delirium() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_static_source_boost_if_graveyard_threshold_v1",
        "static_effect": "source_power_toughness_boost_if_graveyard_count",
        "graveyard_count_scope": "controller_graveyard",
        "graveyard_count_card_types": ["card_type"],
        "graveyard_count_mode": "distinct_card_types",
        "graveyard_count_threshold": 4,
        "static_power_bonus": 2,
        "static_toughness_bonus": 2,
        "_rule_logical_key": "battle_rule_v1:gnarlwood-dryad",
    }
    try:
        result = validator.run_static_graveyard_threshold_source_boost(
            battle,
            {
                "name": "Gnarlwood Dryad graveyard threshold boost applies",
                "type": "static_graveyard_threshold_source_boost",
                "card": {
                    "name": "Gnarlwood Dryad",
                    "type_line": "Creature - Dryad Horror",
                    "power": 1,
                    "toughness": 1,
                },
                "controller_graveyard": [
                    {"name": "E2E Graveyard Creature", "type_line": "Creature"},
                    {"name": "E2E Graveyard Instant", "type_line": "Instant"},
                    {"name": "E2E Graveyard Land", "type_line": "Land"},
                    {"name": "E2E Graveyard Enchantment", "type_line": "Enchantment"},
                ],
                "expected_count": 4,
                "expected_active": True,
                "expected_power": 3,
                "expected_toughness": 3,
                "logical_rule_key": "battle_rule_v1:gnarlwood-dryad",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Gnarlwood Dryad"
    assert result["power"] == 3
    assert result["toughness"] == 3
    assert result["graveyard_count"] == 4
    assert result["active"] is True


def test_simple_activated_damage_runner_executes_life_cost() -> None:
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
        "activated_damage_amount": 1,
        "target": "any_target",
        "target_constraints": {"scope": "any_target"},
        "activation_cost_mana": "{1}",
        "activation_cost_generic": 1,
        "activation_cost_colors": [],
        "activation_requires_tap": False,
        "activation_requires_sacrifice": False,
        "activation_life_cost": 2,
        "_rule_logical_key": "battle_rule_v1:reckless_assault",
    }
    try:
        result = validator.run_simple_activated_damage(
            battle,
            {
                "name": "Reckless Assault activates damage ability",
                "type": "simple_activated_damage",
                "card": {"name": "Reckless Assault"},
                "opponent_life": 7,
                "starting_life": 10,
                "controller_mana": {"generic": 1},
                "expected_damage": 1,
                "expected_life_paid": 2,
                "logical_rule_key": "battle_rule_v1:reckless_assault",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Reckless Assault"
    assert result["damage"] == 1
    assert result["life_paid"] == 2
    assert result["controller_life"] == 8
    assert result["opponent_life"] == 6


def test_simple_activated_damage_runner_executes_exile_top_library_cost() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
        "activated_effect": "direct_damage",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
        "activated_damage_amount": 2,
        "target": "any_target",
        "target_constraints": {"scope": "any_target"},
        "activation_cost_mana": "{R}",
        "activation_cost_generic": 0,
        "activation_cost_colors": ["R"],
        "activation_requires_tap": False,
        "activation_requires_sacrifice": False,
        "activation_exile_top_library_count": 3,
        "_rule_logical_key": "battle_rule_v1:arc-slogger",
    }
    try:
        result = validator.run_simple_activated_damage(
            battle,
            {
                "name": "Arc-Slogger activates damage ability",
                "type": "simple_activated_damage",
                "card": {"name": "Arc-Slogger"},
                "opponent_life": 7,
                "controller_mana": {"red": 1},
                "controller_library": [
                    {"name": "E2E Library Card 1", "type_line": "Sorcery", "effect": "draw_cards"},
                    {"name": "E2E Library Card 2", "type_line": "Instant", "effect": "direct_damage"},
                    {"name": "E2E Library Card 3", "type_line": "Creature", "effect": "creature"},
                ],
                "expected_damage": 2,
                "expected_exiled_top_library_count": 3,
                "logical_rule_key": "battle_rule_v1:arc-slogger",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Arc-Slogger"
    assert result["damage"] == 2
    assert result["exiled_top_library_count"] == 3
    assert result["opponent_life"] == 5


def test_simple_activated_damage_runner_executes_remove_counter_cost() -> None:
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
        "activation_cost_mana": "{1}{R}",
        "activation_cost_generic": 1,
        "activation_cost_colors": ["R"],
        "activation_requires_tap": False,
        "activation_requires_sacrifice": False,
        "activation_remove_counter_cost": {
            "count": 1,
            "target_controller": "self",
            "counter_types": ["+1/+1", "charge"],
            "constraints": {"card_types": ["permanent"]},
        },
        "_rule_logical_key": "battle_rule_v1:ion-storm",
    }
    try:
        result = validator.run_simple_activated_damage(
            battle,
            {
                "name": "Ion Storm activates damage ability",
                "type": "simple_activated_damage",
                "card": {"name": "Ion Storm"},
                "opponent_life": 7,
                "controller_mana": {"generic": 1, "red": 1},
                "counter_cost_targets": [
                    {
                        "name": "E2E Counter Permanent",
                        "type_line": "Creature - Fixture",
                        "effect": "creature",
                        "power": 2,
                        "toughness": 2,
                        "plus_one_counters": 1,
                        "counters": {"+1/+1": 1},
                    }
                ],
                "expected_damage": 2,
                "expected_remove_counter_cost_count": 1,
                "expected_remove_counter_type": "+1/+1",
                "logical_rule_key": "battle_rule_v1:ion-storm",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Ion Storm"
    assert result["damage"] == 2
    assert result["removed_counter_cost_count"] == 1
    assert result["removed_counter_cost_type"] == "+1/+1"
    assert result["opponent_life"] == 5


def test_simple_activated_damage_runner_executes_tap_cost_targets() -> None:
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
        "activated_damage_amount": 1,
        "target": "any_target",
        "target_constraints": {"scope": "any_target"},
        "activation_cost_mana": "{0}",
        "activation_cost_generic": 0,
        "activation_cost_colors": [],
        "activation_requires_tap": False,
        "activation_requires_sacrifice": False,
        "activation_requires_tap_target": True,
        "activation_tap_cost": {
            "count": 2,
            "target_controller": "self",
            "constraints": {"card_types": ["artifact"], "tapped_state": "untapped"},
        },
        "_rule_logical_key": "battle_rule_v1:ghirapur-aether-grid",
    }
    try:
        result = validator.run_simple_activated_damage(
            battle,
            {
                "name": "Ghirapur Aether Grid taps artifacts for damage",
                "type": "simple_activated_damage",
                "card": {"name": "Ghirapur Aether Grid"},
                "opponent_life": 7,
                "expected_damage": 1,
                "tap_cost_targets": [
                    {"name": "E2E Tap Artifact 1", "type_line": "Artifact", "effect": "artifact"},
                    {"name": "E2E Tap Artifact 2", "type_line": "Artifact", "effect": "artifact"},
                ],
                "expected_tap_cost_count": 2,
                "logical_rule_key": "battle_rule_v1:ghirapur-aether-grid",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Ghirapur Aether Grid"
    assert result["opponent_life"] == 6
    assert result["tapped_cost_targets"] == ["E2E Tap Artifact 1", "E2E Tap Artifact 2"]
    assert any(
        event == "activated_ability"
        and data.get("card") == "Ghirapur Aether Grid"
        and data.get("tapped_cost_targets") == ["E2E Tap Artifact 1", "E2E Tap Artifact 2"]
        for event, data in events
    )


def test_simple_activated_damage_runner_executes_restricted_battlefield_target() -> None:
    effect = {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
        "activated_effect": "direct_damage",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
        "activated_damage_amount": 2,
        "amount": 2,
        "damage": 2,
        "target": "attacking_or_blocking_creature",
        "target_constraints": {"card_types": ["creature"], "combat_state": "attacking_or_blocking"},
        "activation_cost_mana": "{0}",
        "activation_cost_generic": 0,
        "activation_cost_colors": [],
        "activation_requires_tap": False,
        "activation_requires_sacrifice": False,
        "activation_requires_tap_target": True,
        "activation_tap_cost": {
            "count": 2,
            "target_controller": "self",
            "constraints": {
                "card_types": ["creature"],
                "required_subtypes": ["soldier"],
                "tapped_state": "untapped",
            },
        },
        "_rule_logical_key": "battle_rule_v1:catapult-squad",
    }
    scenario = package_builder.simple_activated_damage_execution_scenario_from_expected_rule(
        {
            "card_name": "Catapult Squad",
            "logical_rule_key": "battle_rule_v1:catapult-squad",
            "required_effect_fields": effect,
        }
    )

    assert scenario is not None
    assert scenario["expected_target"] == "attacking_or_blocking_creature"
    assert scenario["target"]["attacking"] is True
    assert "blocking" not in scenario["target"]

    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: dict(effect)
    try:
        result = validator.run_simple_activated_damage(battle, scenario, events)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Catapult Squad"
    assert result["target"] == "E2E Legal Activated Damage Target"
    assert result["target_result"] == "creature_destroyed"
    assert result["target_destination"] == "graveyard"
    assert result["opponent_life"] == 7
    assert result["tapped_cost_targets"] == [
        "E2E Activated Damage Tap Cost Target 1",
        "E2E Activated Damage Tap Cost Target 2",
    ]


def test_damage_each_opponent_and_their_permanents_runner_executes_composite_damage() -> None:
    effect = {
        "effect": "composite_resolution",
        "battle_model_scope": "xmage_damage_each_opponent_and_their_permanents_spell_v1",
        "ability_kind": "one_shot",
        "amount": 1,
        "damage": 1,
        "damage_scope": "each_creature_and_planeswalker_opponents_control",
        "target_controller": "opponents",
        "resolution_order": "damage_opponents_then_their_permanents",
        "_composite_rule_components": [
            {
                "effect": "damage_each_opponent",
                "battle_model_scope": "spell_damage_each_opponent_v1",
                "ability_kind": "one_shot",
                "amount": 1,
                "damage": 1,
                "target_controller": "opponents",
                "compose_on_resolution": True,
            },
            {
                "effect": "damage_wipe",
                "battle_model_scope": "xmage_fixed_damage_all_matching_permanents_spell_v1",
                "ability_kind": "one_shot",
                "amount": 1,
                "damage": 1,
                "damage_scope": "each_creature_and_planeswalker_opponents_control",
                "target_controller": "opponents",
                "compose_on_resolution": True,
            },
        ],
        "_rule_logical_key": "battle_rule_v1:end-the-festivities",
    }
    rule = {
        "card_name": "End the Festivities",
        "logical_rule_key": "battle_rule_v1:end-the-festivities",
        "required_effect_fields": effect,
    }
    scenario = package_builder.damage_each_opponent_and_their_permanents_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: dict(effect)
    try:
        result = validator.run_damage_each_opponent_and_their_permanents_spell(battle, scenario, events)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "End the Festivities"
    assert result["opponent_life"] == 8
    assert result["second_opponent_life"] == 10
    assert result["planeswalker_checked"] is True
    assert any(
        event == "composite_rule_resolved"
        and data.get("card") == "End the Festivities"
        and data.get("components_applied") == 2
        and data.get("components_skipped") == 0
        for event, data in events
    )


def test_target_player_x_draw_runner_uses_cast_x_value() -> None:
    effect = {
        "effect": "draw_cards",
        "battle_model_scope": "xmage_fixed_target_player_draw_spell_v1",
        "target": "player",
        "target_controller": "target_player",
        "target_preference": "self",
        "count": 0,
        "draw_count": 0,
        "draw_count_source": "x_value",
        "target_player_draw": True,
        "_rule_logical_key": "battle_rule_v1:braingeyser",
    }
    rule = {
        "card_name": "Braingeyser",
        "logical_rule_key": "battle_rule_v1:braingeyser",
        "required_effect_fields": effect,
    }
    scenario = package_builder.target_player_draw_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: dict(effect)
    try:
        result = validator.run_target_player_draw_spell(battle, scenario, events)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Braingeyser"
    assert result["target_player"] == "Spell Controller"
    assert result["cards_drawn"] == 3
    assert result["x_value"] == 3
    assert any(
        event == "draw_cards_resolved"
        and data.get("card") == "Braingeyser"
        and data.get("target_player_draw") is True
        and data.get("requested_draw_count") == 3
        and data.get("cards_drawn") == 3
        for event, data in events
    )


def test_target_player_x_draw_runner_validates_shuffle_self() -> None:
    effect = {
        "effect": "draw_cards",
        "battle_model_scope": "xmage_fixed_target_player_draw_spell_v1",
        "target": "player",
        "target_controller": "target_player",
        "target_preference": "self",
        "count": 0,
        "draw_count": 0,
        "draw_count_source": "x_value",
        "target_player_draw": True,
        "shuffle_self_into_library_on_resolution": True,
        "_rule_logical_key": "battle_rule_v1:blue-sun",
    }
    rule = {
        "card_name": "Blue Sun's Zenith",
        "logical_rule_key": "battle_rule_v1:blue-sun",
        "required_effect_fields": effect,
    }
    scenario = package_builder.target_player_draw_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["expect_shuffle_self"] is True
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: dict(effect)
    try:
        result = validator.run_target_player_draw_spell(battle, scenario, events)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Blue Sun's Zenith"
    assert result["cards_drawn"] == 3
    assert result["shuffled_self_into_library"] is True
    assert any(
        event == "spell_shuffled_into_library_on_resolution"
        and data.get("card") == "Blue Sun's Zenith"
        and data.get("to_zone") == "library"
        for event, data in events
    )


def test_simple_activated_draw_runner_executes_sacrifice_target_cost() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "draw_engine",
        "battle_model_scope": "xmage_permanent_simple_activated_draw_v1",
        "permanent_type": "creature",
        "activated_draw": True,
        "activated_draw_count": 1,
        "activation_cost_mana": "{0}",
        "activation_cost_generic": 0,
        "activation_cost_colors": [],
        "activation_requires_tap": True,
        "activation_requires_sacrifice": False,
        "activation_requires_sacrifice_target": True,
        "activation_sacrifice_target": "artifact",
        "_rule_logical_key": "battle_rule_v1:sage-of-lat-nam",
    }
    try:
        result = validator.run_simple_activated_draw(
            battle,
            {
                "name": "Sage of Lat-Nam activates draw ability",
                "type": "simple_activated_draw",
                "card": {"name": "Sage of Lat-Nam"},
                "controller_mana": {"generic": 0},
                "controller_library": [
                    {"name": "E2E Activated Draw Card", "type_line": "Sorcery", "effect": "draw_cards"}
                ],
                "sacrifice_target": {
                    "name": "E2E Artifact Sacrifice Target",
                    "type_line": "Artifact",
                    "effect": "artifact",
                    "cmc": 1,
                },
                "expect_target_sacrificed": True,
                "expected_draw_count": 1,
                "expected_tapped_source": True,
                "expected_discard_count": 0,
                "expected_life_paid": 0,
                "logical_rule_key": "battle_rule_v1:sage-of-lat-nam",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Sage of Lat-Nam"
    assert result["cards_drawn"] == 1
    assert result["source_tapped"] is True
    assert result["target_sacrificed"] is True


def test_simple_activated_draw_runner_executes_tap_cost_target() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "draw_engine",
        "battle_model_scope": "xmage_permanent_simple_activated_draw_v1",
        "permanent_type": "creature",
        "activated_draw": True,
        "activated_draw_count": 1,
        "activation_cost_mana": "{0}",
        "activation_cost_generic": 0,
        "activation_cost_colors": [],
        "activation_requires_tap": False,
        "activation_requires_sacrifice": False,
        "activation_requires_tap_target": True,
        "activation_tap_cost": {
            "count": 1,
            "target_controller": "self",
            "constraints": {
                "card_types": ["creature"],
                "required_subtypes": ["wizard"],
                "tapped_state": "untapped",
            },
        },
        "_rule_logical_key": "battle_rule_v1:azami",
    }
    try:
        result = validator.run_simple_activated_draw(
            battle,
            {
                "name": "Azami activates draw ability",
                "type": "simple_activated_draw",
                "card": {"name": "Azami, Lady of Scrolls"},
                "controller_mana": {},
                "controller_library": [
                    {"name": "E2E Activated Draw Card", "type_line": "Sorcery", "effect": "draw_cards"}
                ],
                "tap_cost_targets": [
                    {
                        "name": "E2E Untapped Wizard",
                        "type_line": "Creature - Human Wizard",
                        "effect": "creature",
                        "power": 1,
                        "toughness": 1,
                        "tapped": False,
                    }
                ],
                "expected_draw_count": 1,
                "expected_tapped_source": False,
                "expected_tap_cost_count": 1,
                "logical_rule_key": "battle_rule_v1:azami",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Azami, Lady of Scrolls"
    assert result["cards_drawn"] == 1
    assert result["source_tapped"] is False
    assert result["tapped_cost_targets"] == ["E2E Untapped Wizard"]


def test_simple_activated_draw_runner_executes_remove_counter_cost() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "draw_engine",
        "battle_model_scope": "xmage_permanent_simple_activated_draw_v1",
        "permanent_type": "creature",
        "activated_draw": True,
        "activated_draw_count": 1,
        "activation_cost_mana": "{0}",
        "activation_cost_generic": 0,
        "activation_cost_colors": [],
        "activation_requires_tap": True,
        "activation_requires_sacrifice": False,
        "activation_remove_counter_cost": {
            "count": 1,
            "target_controller": "self",
            "counter_types": ["any"],
            "constraints": {"card_types": ["permanent"], "exclude_card_types": ["land"]},
        },
        "_rule_logical_key": "battle_rule_v1:oaka",
    }
    try:
        result = validator.run_simple_activated_draw(
            battle,
            {
                "name": "O'aka activates draw ability",
                "type": "simple_activated_draw",
                "card": {"name": "O'aka, Traveling Merchant"},
                "controller_mana": {},
                "controller_library": [
                    {"name": "E2E Activated Draw Card", "type_line": "Sorcery", "effect": "draw_cards"}
                ],
                "counter_cost_targets": [
                    {
                        "name": "E2E Counter Permanent",
                        "type_line": "Creature - Fixture",
                        "effect": "creature",
                        "power": 2,
                        "toughness": 2,
                        "plus_one_counters": 1,
                        "counters": {"+1/+1": 1},
                    }
                ],
                "expected_draw_count": 1,
                "expected_tapped_source": True,
                "expected_remove_counter_cost_count": 1,
                "expected_remove_counter_type": "+1/+1",
                "logical_rule_key": "battle_rule_v1:oaka",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "O'aka, Traveling Merchant"
    assert result["cards_drawn"] == 1
    assert result["source_tapped"] is True
    assert result["removed_counter_cost_count"] == 1
    assert result["removed_counter_cost_type"] == "+1/+1"


def test_fixed_draw_spell_runner_pays_sacrifice_two_creatures_cost() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "draw_cards",
        "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
        "count": 3,
        "draw_count": 3,
        "additional_cost": "sacrifice_two_creatures",
        "requires_sacrifice_creature_count": 2,
    }
    try:
        result = validator.run_fixed_draw_spell(
            battle,
            {
                "name": "Bankrupt in Blood draws cards",
                "type": "fixed_draw_spell",
                "card": {"name": "Bankrupt in Blood", "type_line": "Sorcery"},
                "controller_library": [
                    {"name": f"E2E Draw Card {index + 1}", "type_line": "Sorcery", "effect": "draw_cards"}
                    for index in range(3)
                ],
                "controller_battlefield": [
                    {
                        "name": "E2E Sacrifice Cost Creature 1",
                        "type_line": "Creature - Soldier",
                        "effect": "creature",
                        "power": 1,
                        "toughness": 1,
                    },
                    {
                        "name": "E2E Sacrifice Cost Creature 2",
                        "type_line": "Creature - Soldier",
                        "effect": "creature",
                        "power": 1,
                        "toughness": 1,
                    },
                ],
                "expected_draw_count": 3,
                "expected_additional_cost": "sacrifice_two_creatures",
                "expected_sacrificed_names": [
                    "E2E Sacrifice Cost Creature 1",
                    "E2E Sacrifice Cost Creature 2",
                ],
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Bankrupt in Blood"
    assert result["cards_drawn"] == 3
    assert result["additional_cost"] == "sacrifice_two_creatures"
    assert result["sacrificed"] == [
        "E2E Sacrifice Cost Creature 1",
        "E2E Sacrifice Cost Creature 2",
    ]


def test_fixed_draw_discard_spell_runner_executes_random_discard() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "draw_cards",
        "battle_model_scope": "xmage_fixed_draw_discard_spell_v1",
        "count": 4,
        "draw_count": 4,
        "discard_count": 3,
        "discard_random": True,
        "draw_discard_order": "draw_then_discard",
        "draw_discard_spell": True,
    }
    try:
        result = validator.run_fixed_draw_discard_spell(
            battle,
            {
                "name": "Goblin Lore draws then discards",
                "type": "fixed_draw_discard_spell",
                "card": {"name": "Goblin Lore", "type_line": "Sorcery"},
                "controller_library": [
                    {"name": f"E2E Draw Discard Library Card {index + 1}", "type_line": "Sorcery", "effect": "draw_cards"}
                    for index in range(4)
                ],
                "controller_hand": [
                    {"name": f"E2E Draw Discard Spare Card {index + 1}", "type_line": "Instant", "effect": "draw_cards"}
                    for index in range(3)
                ],
                "expected_draw_count": 4,
                "expected_discard_count": 3,
                "expected_discard_random": True,
                "expected_draw_discard_order": "draw_then_discard",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Goblin Lore"
    assert result["cards_drawn"] == 4
    assert result["cards_discarded"] == 3
    assert result["discard_random"] is True
    assert result["order"] == "draw_then_discard"


def test_single_target_removal_runner_validates_controller_life_gain() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "remove_permanent",
        "battle_model_scope": "xmage_destroy_target_and_controller_gain_life_spell_v1",
        "target": "artifact_or_enchantment",
        "target_constraints": {"card_types": ["artifact", "enchantment"]},
        "destination": "graveyard",
        "controller_gains_life": 4,
        "_rule_logical_key": "battle_rule_v1:divine-offering-fixture",
    }
    try:
        result = validator.run_single_target_removal(
            battle,
            {
                "name": "Divine Offering Fixture removes one legal target",
                "type": "single_target_removal",
                "card": {"name": "Divine Offering Fixture", "type_line": "Instant"},
                "target": {
                    "name": "E2E Legal Removal Target",
                    "type_line": "Artifact",
                    "effect": "artifact",
                    "cmc": 3,
                },
                "nonmatching_target": {
                    "name": "E2E Illegal Removal Target",
                    "type_line": "Land",
                    "effect": "land",
                    "cmc": 0,
                },
                "expected_destination": "graveyard",
                "expected_effect": "remove_permanent",
                "expected_controller_life_gain": 4,
                "controller_life": 10,
                "logical_rule_key": "battle_rule_v1:divine-offering-fixture",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Divine Offering Fixture"
    assert result["controller_life_before"] == 10
    assert result["controller_life_after"] == 14
    assert result["controller_life_gained"] == 4


def test_single_target_removal_and_draw_runner_exiles_and_draws() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "composite_resolution",
        "battle_model_scope": "xmage_exile_target_and_draw_card_spell_v1",
        "target": "creature",
        "target_constraints": {"card_types": ["creature"], "combat_state": "attacking"},
        "destination": "exile",
        "draw_count": 1,
        "_composite_rule_components": [
            {
                "effect": "remove_creature",
                "battle_model_scope": "xmage_exile_target_spell_v1",
                "target": "creature",
                "target_constraints": {"card_types": ["creature"], "combat_state": "attacking"},
                "destination": "exile",
            },
            {
                "effect": "draw_cards",
                "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                "count": 1,
            },
        ],
        "_rule_logical_key": "battle_rule_v1:second-thoughts-fixture",
    }
    try:
        result = validator.run_single_target_removal_and_draw(
            battle,
            {
                "name": "Second Thoughts removes one legal target and draws 1",
                "type": "single_target_removal_and_draw",
                "card": {"name": "Second Thoughts", "type_line": "Instant"},
                "target": {
                    "name": "E2E Legal Removal Target",
                    "type_line": "Creature - Soldier",
                    "effect": "creature",
                    "attacking": True,
                    "power": 2,
                    "toughness": 2,
                },
                "nonmatching_target": {
                    "name": "E2E Illegal Removal Target",
                    "type_line": "Creature - Soldier",
                    "effect": "creature",
                    "attacking": False,
                    "power": 2,
                    "toughness": 2,
                },
                "expected_destination": "exile",
                "expected_draw_count": 1,
                "controller_library": [
                    {"name": "E2E Draw Card", "type_line": "Instant", "effect": "draw_cards"},
                    {"name": "E2E Remaining Card", "type_line": "Sorcery", "effect": "draw_cards"},
                ],
                "logical_rule_key": "battle_rule_v1:second-thoughts-fixture",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Second Thoughts"
    assert result["destination"] == "exile"
    assert result["cards_drawn"] == 1
    assert result["target"] == "E2E Legal Removal Target"
    assert result["nonmatching_target"] == "E2E Illegal Removal Target"


def test_single_target_removal_and_draw_runner_exiles_graveyard_card_and_draws() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "composite_resolution",
        "battle_model_scope": "xmage_exile_target_and_draw_card_spell_v1",
        "target": "any_card",
        "target_constraints": {"zone": "graveyard", "controller": "any", "card_types": ["card"]},
        "destination": "exile",
        "draw_count": 1,
        "_composite_rule_components": [
            {
                "effect": "graveyard_exile",
                "battle_model_scope": "xmage_exile_target_graveyard_card_spell_v1",
                "target": "any_card",
                "target_constraints": {"zone": "graveyard", "controller": "any", "card_types": ["card"]},
                "count": 1,
                "destination": "exile",
                "target_controller": "any",
                "graveyard_exile_target": "any_card",
                "graveyard_exile_target_count": 1,
                "graveyard_exile_destination": "exile",
                "graveyard_exile_single_graveyard": False,
            },
            {
                "effect": "draw_cards",
                "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                "count": 1,
            },
        ],
        "_rule_logical_key": "battle_rule_v1:cremate-fixture",
    }
    try:
        result = validator.run_single_target_removal_and_draw(
            battle,
            {
                "name": "Cremate exiles one graveyard card and draws 1",
                "type": "single_target_removal_and_draw",
                "card": {"name": "Cremate", "type_line": "Instant"},
                "target_zone": "graveyard",
                "target": {
                    "name": "E2E Legal Graveyard Target",
                    "type_line": "Instant",
                    "effect": "draw_cards",
                    "cmc": 2,
                },
                "nonmatching_target": {
                    "name": "E2E Battlefield Non-Target",
                    "type_line": "Creature - Soldier",
                    "effect": "creature",
                    "cmc": 2,
                    "power": 2,
                    "toughness": 2,
                },
                "expected_destination": "exile",
                "expected_draw_count": 1,
                "controller_library": [
                    {"name": "E2E Draw Card", "type_line": "Instant", "effect": "draw_cards"},
                    {"name": "E2E Remaining Card", "type_line": "Sorcery", "effect": "draw_cards"},
                ],
                "logical_rule_key": "battle_rule_v1:cremate-fixture",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Cremate"
    assert result["destination"] == "exile"
    assert result["cards_drawn"] == 1
    assert result["target"] == "E2E Legal Graveyard Target"
    assert result["nonmatching_target"] == "E2E Battlefield Non-Target"


def test_single_target_removal_runner_respects_self_controller_scope() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "remove_permanent",
        "battle_model_scope": "xmage_return_target_to_hand_spell_v1",
        "target": "permanent",
        "target_constraints": {"card_types": ["permanent"], "controller_scope": "self"},
        "target_controller": "self",
        "destination": "hand",
        "_rule_logical_key": "battle_rule_v1:rescue-fixture",
    }
    try:
        result = validator.run_single_target_removal(
            battle,
            {
                "name": "Rescue Fixture returns one controlled permanent",
                "type": "single_target_removal",
                "card": {"name": "Rescue Fixture", "type_line": "Instant"},
                "target": {
                    "name": "E2E Legal Removal Target",
                    "type_line": "Artifact",
                    "effect": "artifact",
                    "cmc": 2,
                },
                "nonmatching_target": {
                    "name": "E2E Illegal Removal Target",
                    "type_line": "Land",
                    "effect": "land",
                    "cmc": 0,
                },
                "expected_destination": "hand",
                "expected_effect": "remove_permanent",
                "logical_rule_key": "battle_rule_v1:rescue-fixture",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Rescue Fixture"
    assert result["target_player"] == "Active"
    assert result["moved_names"] == ["E2E Legal Removal Target"]
    assert result["battlefield_names"] == ["E2E Illegal Removal Target"]


def test_simple_activated_tap_target_runner_executes_tap_effect() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_tap_target_v1",
        "activated_effect": "tap_target",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_tap_target_v1",
        "activated_tap_target": "creature",
        "target": "creature",
        "target_constraints": {"card_types": ["creature"]},
        "activation_cost_mana": "{1}",
        "activation_cost_generic": 1,
        "activation_cost_colors": [],
        "activation_requires_tap": True,
        "activation_requires_sacrifice": False,
        "_rule_logical_key": "battle_rule_v1:akroan-jailer",
    }
    try:
        result = validator.run_simple_activated_tap_target(
            battle,
            {
                "name": "Akroan Jailer taps target creature",
                "type": "simple_activated_tap_target",
                "card": {"name": "Akroan Jailer"},
                "controller_mana": {"generic": 1},
                "expected_tapped_source": True,
                "logical_rule_key": "battle_rule_v1:akroan-jailer",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Akroan Jailer"
    assert result["target_tapped"] is True
    assert result["source_tapped"] is True


def test_tap_target_spell_runner_executes_multi_target_spell() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "tap_target",
        "battle_model_scope": "xmage_tap_target_spell_v1",
        "target": "creature",
        "target_constraints": {"card_types": ["creature"]},
        "target_count": 2,
        "target_count_max": 2,
        "up_to_count": True,
        "_rule_logical_key": "battle_rule_v1:lead-astray",
    }
    try:
        result = validator.run_tap_target_spell(
            battle,
            {
                "name": "Lead Astray taps two target creatures",
                "type": "tap_target_spell",
                "card": {"name": "Lead Astray", "type_line": "Instant"},
                "targets": [
                    {
                        "name": "E2E Legal Tap Target One",
                        "type_line": "Creature - Fixture",
                        "effect": "creature",
                        "power": 2,
                        "toughness": 2,
                    },
                    {
                        "name": "E2E Legal Tap Target Two",
                        "type_line": "Creature - Fixture",
                        "effect": "creature",
                        "power": 3,
                        "toughness": 3,
                    },
                ],
                "nonmatching_target": {
                    "name": "E2E Illegal Tap Target",
                    "type_line": "Land",
                    "effect": "land",
                },
                "expected_target_count": 2,
                "logical_rule_key": "battle_rule_v1:lead-astray",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Lead Astray"
    assert result["target_tapped_count"] == 2
    assert result["targets_tapped"] == [
        "E2E Legal Tap Target One",
        "E2E Legal Tap Target Two",
    ]


def test_boost_untap_target_runner_executes_multi_target_spell() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "stat_modifier_until_eot_untap_target",
        "battle_model_scope": "xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1",
        "target": "creature",
        "target_controller": "any",
        "target_constraints": {"card_types": ["creature"]},
        "power_delta": 2,
        "toughness_delta": 2,
        "untap_target": True,
        "target_count": 2,
        "target_count_min": 0,
        "target_count_max": 2,
        "up_to_count": True,
        "_rule_logical_key": "battle_rule_v1:synchronized-strike",
    }
    try:
        result = validator.run_stat_modifier_until_eot_untap_target(
            battle,
            {
                "name": "Synchronized Strike boosts and untaps two target creatures",
                "type": "stat_modifier_until_eot_untap_target",
                "card": {"name": "Synchronized Strike", "type_line": "Instant"},
                "targets": [
                    {
                        "name": "E2E Legal Boost Untap Target One",
                        "type_line": "Creature - Fixture",
                        "effect": "creature",
                        "power": 2,
                        "toughness": 2,
                        "tapped": True,
                    },
                    {
                        "name": "E2E Legal Boost Untap Target Two",
                        "type_line": "Creature - Fixture",
                        "effect": "creature",
                        "power": 3,
                        "toughness": 3,
                        "tapped": True,
                    },
                ],
                "nonmatching_target": {
                    "name": "E2E Illegal Boost Untap Target",
                    "type_line": "Land",
                    "effect": "land",
                    "tapped": True,
                },
                "expected_power_delta": 2,
                "expected_toughness_delta": 2,
                "expected_target_count": 2,
                "logical_rule_key": "battle_rule_v1:synchronized-strike",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Synchronized Strike"
    assert result["target_count"] == 2
    assert result["targets_untapped_count"] == 2


def test_boost_keyword_untap_target_runner_applies_keyword() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "stat_modifier_until_eot_untap_target",
        "battle_model_scope": "xmage_fixed_boost_keyword_and_untap_target_creature_until_eot_spell_v1",
        "target": "creature",
        "target_controller": "any",
        "target_constraints": {"card_types": ["creature"]},
        "power_delta": 2,
        "toughness_delta": 2,
        "untap_target": True,
        "granted_keywords_until_eot": ["reach"],
        "target_count": 1,
        "target_count_min": 1,
        "target_count_max": 1,
        "up_to_count": False,
        "_rule_logical_key": "battle_rule_v1:aim-high",
    }
    try:
        result = validator.run_stat_modifier_until_eot_untap_target(
            battle,
            {
                "name": "Aim High boosts, grants reach, and untaps target creature",
                "type": "stat_modifier_until_eot_untap_target",
                "card": {"name": "Aim High", "type_line": "Instant"},
                "targets": [
                    {
                        "name": "E2E Legal Boost Keyword Untap Target",
                        "type_line": "Creature - Fixture",
                        "effect": "creature",
                        "power": 2,
                        "toughness": 2,
                        "tapped": True,
                    },
                ],
                "nonmatching_target": {
                    "name": "E2E Illegal Boost Keyword Untap Target",
                    "type_line": "Land",
                    "effect": "land",
                    "tapped": True,
                },
                "expected_power_delta": 2,
                "expected_toughness_delta": 2,
                "expected_keywords": ["reach"],
                "expected_target_count": 1,
                "logical_rule_key": "battle_rule_v1:aim-high",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Aim High"
    assert result["target_count"] == 1
    assert result["targets_untapped_count"] == 1
    assert result["granted_keywords"] == ["reach"]


def test_add_counters_untap_target_runner_executes_spell() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "add_counters",
        "battle_model_scope": "xmage_fixed_add_counters_and_untap_target_creature_spell_v1",
        "target": "creature",
        "target_controller": "any",
        "target_constraints": {"card_types": ["creature"]},
        "counter_type": "+1/+1",
        "counter_count": 2,
        "count": 2,
        "untap_target": True,
        "target_count": 1,
        "target_count_min": 1,
        "target_count_max": 1,
        "up_to_count": False,
        "_rule_logical_key": "battle_rule_v1:dragonscale-boon",
    }
    try:
        result = validator.run_add_counters_untap_target_spell(
            battle,
            {
                "name": "Dragonscale Boon adds counters and untaps target creature",
                "type": "add_counters_untap_target_spell",
                "card": {"name": "Dragonscale Boon", "type_line": "Instant"},
                "target": {
                    "name": "E2E Counter Untap Target",
                    "type_line": "Creature - Fixture",
                    "effect": "creature",
                    "power": 3,
                    "toughness": 3,
                    "tapped": True,
                },
                "nonmatching_target": {
                    "name": "E2E Illegal Counter Untap Target",
                    "type_line": "Land",
                    "effect": "land",
                    "tapped": True,
                },
                "expected_counter_type": "+1/+1",
                "expected_counter_count": 2,
                "logical_rule_key": "battle_rule_v1:dragonscale-boon",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Dragonscale Boon"
    assert result["target_count"] == 1
    assert result["targets"] == ["E2E Counter Untap Target"]
    assert result["counters_added_each"] == 2
    assert result["targets_untapped_count"] == 1
    assert any(
        event == "add_counters_resolved"
        and data.get("card") == "Dragonscale Boon"
        and data.get("target_untapped") is True
        and data.get("counters_added") == 2
        for event, data in events
    )


def test_add_counters_multi_target_runner_executes_spell() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "add_counters",
        "battle_model_scope": "xmage_fixed_add_counters_target_creatures_spell_v1",
        "target": "creature",
        "target_controller": "any",
        "target_constraints": {"card_types": ["creature"]},
        "counter_type": "+1/+1",
        "counter_count": 1,
        "count": 1,
        "target_count": 2,
        "target_count_min": 0,
        "target_count_max": 2,
        "up_to_count": True,
        "_rule_logical_key": "battle_rule_v1:test-counters",
    }
    try:
        result = validator.run_add_counters_target_spell(
            battle,
            {
                "name": "Test Counters adds counters to targets",
                "type": "add_counters_target_spell",
                "card": {"name": "Test Counters", "type_line": "Instant"},
                "targets": [
                    {
                        "name": "E2E Counter Target A",
                        "type_line": "Creature - Fixture",
                        "effect": "creature",
                        "power": 3,
                        "toughness": 3,
                    },
                    {
                        "name": "E2E Counter Target B",
                        "type_line": "Creature - Fixture",
                        "effect": "creature",
                        "power": 2,
                        "toughness": 2,
                    },
                ],
                "nonmatching_target": {
                    "name": "E2E Illegal Counter Target",
                    "type_line": "Land",
                    "effect": "land",
                },
                "expected_target_count": 2,
                "expected_counter_type": "+1/+1",
                "expected_counter_count": 1,
                "logical_rule_key": "battle_rule_v1:test-counters",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Test Counters"
    assert result["target_count"] == 2
    assert result["counters_added_each"] == 1
    assert len(
        [
            data
            for event, data in events
            if event == "add_counters_resolved"
            and data.get("card") == "Test Counters"
            and data.get("counters_added") == 1
        ]
    ) == 2


def test_gain_control_untap_haste_runner_returns_control_at_cleanup() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "gain_control_untap_haste_until_eot",
        "battle_model_scope": "xmage_gain_control_untap_haste_until_eot_spell_v1",
        "target": "creature",
        "target_controller": "opponents",
        "target_constraints": {"card_types": ["creature"]},
        "control_duration": "until_end_of_turn",
        "untap_target": True,
        "granted_keywords_until_eot": ["haste"],
        "_rule_logical_key": "battle_rule_v1:act-of-treason",
    }
    try:
        result = validator.run_gain_control_untap_haste_until_eot(
            battle,
            {
                "name": "Act of Treason gains temporary control",
                "type": "gain_control_untap_haste_until_eot",
                "card": {"name": "Act of Treason", "type_line": "Sorcery"},
                "target": {
                    "name": "E2E Legal Temporary Control Target",
                    "type_line": "Creature - Soldier",
                    "effect": "creature",
                    "power": 3,
                    "toughness": 3,
                    "tapped": True,
                },
                "nonmatching_target": {
                    "name": "E2E Illegal Temporary Control Target",
                    "type_line": "Land",
                    "effect": "land",
                    "tapped": True,
                },
                "logical_rule_key": "battle_rule_v1:act-of-treason",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Act of Treason"
    assert result["target"] == "E2E Legal Temporary Control Target"
    assert result["control_returned"] is True


def test_simple_activated_tap_target_runner_executes_noncreature_target() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "artifact",
        "battle_model_scope": "xmage_permanent_simple_activated_tap_target_v1",
        "activated_effect": "tap_target",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_tap_target_v1",
        "activated_tap_target": "artifact_creature_or_land",
        "target": "artifact_creature_or_land",
        "target_constraints": {"card_types": ["artifact", "creature", "land"]},
        "activation_cost_mana": "{1}",
        "activation_cost_generic": 1,
        "activation_cost_colors": [],
        "activation_requires_tap": True,
        "activation_requires_sacrifice": False,
        "_rule_logical_key": "battle_rule_v1:icy-manipulator",
    }
    try:
        result = validator.run_simple_activated_tap_target(
            battle,
            {
                "name": "Icy Manipulator taps a land",
                "type": "simple_activated_tap_target",
                "card": {"name": "Icy Manipulator"},
                "target": {
                    "name": "E2E Land Target",
                    "type_line": "Land",
                    "effect": "land",
                    "cmc": 0,
                },
                "controller_mana": {"generic": 1},
                "expected_tapped_source": True,
                "logical_rule_key": "battle_rule_v1:icy-manipulator",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Icy Manipulator"
    assert result["target"] == "E2E Land Target"
    assert result["target_tapped"] is True
    assert result["source_tapped"] is True
    assert any(
        event == "tap_target_resolved"
        and data.get("card") == "Icy Manipulator"
        and data.get("target") == "E2E Land Target"
        and data.get("target_tapped") is True
        for event, data in events
    )


def test_simple_activated_tap_target_runner_executes_restricted_target() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_tap_target_v1",
        "activated_effect": "tap_target",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_tap_target_v1",
        "activated_tap_target": "creature_mana_value_2_or_greater",
        "target": "creature_mana_value_2_or_greater",
        "target_constraints": {"card_types": ["creature"], "mana_value_min": 2},
        "activation_cost_mana": "{1}",
        "activation_cost_generic": 1,
        "activation_cost_colors": [],
        "activation_requires_tap": True,
        "activation_requires_sacrifice": False,
        "_rule_logical_key": "battle_rule_v1:law-rune-enforcer",
    }
    try:
        result = validator.run_simple_activated_tap_target(
            battle,
            {
                "name": "Law-Rune Enforcer taps a mana value target",
                "type": "simple_activated_tap_target",
                "card": {"name": "Law-Rune Enforcer"},
                "target": {
                    "name": "E2E Mana Value Target",
                    "type_line": "Creature - Soldier",
                    "effect": "creature",
                    "cmc": 2,
                },
                "controller_mana": {"generic": 1},
                "expected_tapped_source": True,
                "logical_rule_key": "battle_rule_v1:law-rune-enforcer",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Law-Rune Enforcer"
    assert result["target"] == "E2E Mana Value Target"
    assert result["target_tapped"] is True
    assert result["source_tapped"] is True


def test_simple_activated_untap_target_runner_executes_multi_land_target() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_untap_target_v1",
        "activated_effect": "untap_target",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_untap_target_v1",
        "activated_untap_target": "land",
        "target": "land",
        "target_constraints": {"card_types": ["land"]},
        "target_count": 2,
        "target_count_min": 2,
        "target_count_max": 2,
        "activation_cost_mana": "{0}",
        "activation_cost_generic": 0,
        "activation_cost_colors": [],
        "activation_requires_tap": True,
        "activation_requires_sacrifice": False,
        "_rule_logical_key": "battle_rule_v1:argothian-elder",
    }
    try:
        result = validator.run_simple_activated_untap_target(
            battle,
            {
                "name": "Argothian Elder untaps two lands",
                "type": "simple_activated_untap_target",
                "card": {"name": "Argothian Elder"},
                "targets": [
                    {
                        "name": "E2E First Tapped Land",
                        "type_line": "Land",
                        "effect": "land",
                        "cmc": 0,
                        "tapped": True,
                    },
                    {
                        "name": "E2E Second Tapped Land",
                        "type_line": "Land",
                        "effect": "land",
                        "cmc": 0,
                        "tapped": True,
                    },
                ],
                "nonmatching_target": {
                    "name": "E2E Illegal Untap Creature",
                    "type_line": "Creature - Rogue",
                    "effect": "creature",
                    "cmc": 1,
                    "tapped": True,
                },
                "expected_target_count": 2,
                "expected_tapped_source": True,
                "logical_rule_key": "battle_rule_v1:argothian-elder",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Argothian Elder"
    assert result["targets_untapped"] == 2
    assert result["source_tapped"] is True
    assert any(
        event == "untap_target_resolved"
        and data.get("card") == "Argothian Elder"
        and data.get("target_untapped_count") == 2
        for event, data in events
    )


def test_simple_activated_add_counters_target_runner_executes_minus_counter() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "artifact",
        "battle_model_scope": "xmage_permanent_simple_activated_add_counters_target_creature_v1",
        "activated_effect": "add_counters",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_add_counters_target_creature_v1",
        "activated_add_counters": True,
        "activated_add_counters_target": "creature",
        "activated_add_counters_counter_type": "-1/-1",
        "activated_add_counters_count": 1,
        "target": "creature",
        "target_constraints": {"card_types": ["creature"]},
        "target_controller": "any",
        "counter_type": "-1/-1",
        "counter_count": 1,
        "count": 1,
        "activation_cost_mana": "{4}",
        "activation_cost_generic": 4,
        "activation_cost_colors": [],
        "activation_requires_tap": True,
        "activation_requires_sacrifice": False,
        "_rule_logical_key": "battle_rule_v1:gnarled-effigy",
    }
    try:
        result = validator.run_simple_activated_add_counters_target(
            battle,
            {
                "name": "Gnarled Effigy puts a counter on target creature",
                "type": "simple_activated_add_counters_target",
                "card": {"name": "Gnarled Effigy"},
                "target": {
                    "name": "E2E Counter Target",
                    "type_line": "Creature - Soldier",
                    "effect": "creature",
                    "power": 3,
                    "toughness": 3,
                },
                "controller_mana": {"generic": 4},
                "expected_tapped_source": True,
                "expected_counter_type": "-1/-1",
                "expected_counter_count": 1,
                "logical_rule_key": "battle_rule_v1:gnarled-effigy",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Gnarled Effigy"
    assert result["target"] == "E2E Counter Target"
    assert result["counter_type"] == "-1/-1"
    assert result["counters_added"] == 1
    assert result["source_tapped"] is True
    assert any(
        event == "activated_add_counters_target_resolved"
        and data.get("card") == "Gnarled Effigy"
        and data.get("target") == "E2E Counter Target"
        and data.get("counters_added") == 1
        for event, data in events
    )


def test_simple_activated_add_counters_target_runner_pays_extra_costs() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_add_counters_target_creature_v1",
        "activated_effect": "add_counters",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_add_counters_target_creature_v1",
        "activated_add_counters": True,
        "activated_add_counters_target": "creature",
        "activated_add_counters_counter_type": "+1/+1",
        "activated_add_counters_count": 1,
        "target": "creature",
        "target_constraints": {"card_types": ["creature"]},
        "target_controller": "any",
        "counter_type": "+1/+1",
        "counter_count": 1,
        "count": 1,
        "activation_cost_mana": "{1}",
        "activation_cost_generic": 1,
        "activation_cost_colors": [],
        "activation_requires_tap": False,
        "activation_requires_sacrifice": True,
        "activation_discard_count": 1,
        "activation_discard_target": "any_card",
        "activation_life_cost": 3,
        "activation_sacrifice_cost": {
            "count": 1,
            "target_controller": "self",
            "constraints": {"card_types": ["creature"], "exclude_source": True},
        },
        "_rule_logical_key": "battle_rule_v1:fixture-counter-costs",
    }
    try:
        result = validator.run_simple_activated_add_counters_target(
            battle,
            {
                "name": "Fixture Counter Costs pays extras",
                "type": "simple_activated_add_counters_target",
                "card": {
                    "name": "Fixture Counter Costs",
                    "type_line": "Creature - Human",
                    "power": 1,
                    "toughness": 1,
                },
                "target": {
                    "name": "E2E Counter Target",
                    "type_line": "Creature - Soldier",
                    "effect": "creature",
                    "power": 3,
                    "toughness": 3,
                },
                "controller_mana": {"generic": 1},
                "controller_hand": [
                    {"name": "E2E Discard Cost Card", "type_line": "Instant", "effect": "draw_cards", "cmc": 2}
                ],
                "sacrifice_targets": [
                    {"name": "E2E Sacrifice Cost Creature", "type_line": "Creature - Citizen", "effect": "creature"}
                ],
                "starting_life": 40,
                "expected_sacrificed_source": True,
                "expected_discard_count": 1,
                "expected_life_paid": 3,
                "expected_sacrifice_count": 1,
                "expected_counter_type": "+1/+1",
                "expected_counter_count": 1,
                "logical_rule_key": "battle_rule_v1:fixture-counter-costs",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["source_sacrificed"] is True
    assert result["discarded_count"] == 1
    assert result["life_paid"] == 3
    assert result["sacrifice_cost_count"] == 1
    assert any(
        event == "activated_ability"
        and data.get("card") == "Fixture Counter Costs"
        and data.get("sacrificed_source") is True
        and data.get("discarded_count") == 1
        and data.get("life_paid") == 3
        and data.get("sacrificed_cost_targets") == ["E2E Sacrifice Cost Creature"]
        for event, data in events
    )


def test_simple_activated_add_counters_self_runner_pays_extra_costs() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_self_add_counters_v1",
        "activated_effect": "add_counters",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_self_add_counters_v1",
        "activated_add_counters": True,
        "activated_add_counters_target": "self",
        "activated_add_counters_counter_type": "+1/+1",
        "activated_add_counters_count": 2,
        "target": "self",
        "counter_type": "+1/+1",
        "counter_count": 2,
        "count": 2,
        "activation_cost_mana": "{2}{B}",
        "activation_cost_generic": 2,
        "activation_cost_colors": ["B"],
        "activation_requires_tap": False,
        "activation_requires_sacrifice": False,
        "activation_discard_count": 1,
        "activation_discard_target": "any_card",
        "activation_life_cost": 3,
        "activation_sacrifice_cost": {
            "count": 1,
            "target_controller": "self",
            "constraints": {"card_types": ["creature"], "exclude_source": True},
        },
        "_rule_logical_key": "battle_rule_v1:fixture-self-counter-costs",
    }
    try:
        result = validator.run_simple_activated_add_counters_self(
            battle,
            {
                "name": "Fixture Self Counter Costs pays extras",
                "type": "simple_activated_add_counters_self",
                "card": {
                    "name": "Fixture Self Counter Costs",
                    "type_line": "Creature - Vampire",
                    "power": 2,
                    "toughness": 2,
                },
                "controller_mana": {"generic": 2, "black": 1},
                "controller_hand": [
                    {"name": "E2E Self Discard Cost Card", "type_line": "Instant", "effect": "draw_cards", "cmc": 2}
                ],
                "sacrifice_targets": [
                    {"name": "E2E Self Sacrifice Cost Creature", "type_line": "Creature - Citizen", "effect": "creature"}
                ],
                "starting_life": 40,
                "expected_discard_count": 1,
                "expected_life_paid": 3,
                "expected_sacrifice_count": 1,
                "expected_counter_type": "+1/+1",
                "expected_counter_count": 2,
                "logical_rule_key": "battle_rule_v1:fixture-self-counter-costs",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Fixture Self Counter Costs"
    assert result["counters_added"] == 2
    assert result["discarded_count"] == 1
    assert result["life_paid"] == 3
    assert result["sacrifice_cost_count"] == 1
    assert any(
        event == "activated_ability"
        and data.get("card") == "Fixture Self Counter Costs"
        and data.get("activation_kind") == "simple_activated_add_counters_self"
        and data.get("discarded_count") == 1
        and data.get("life_paid") == 3
        and data.get("sacrificed_cost_targets") == ["E2E Self Sacrifice Cost Creature"]
        for event, data in events
    )
    assert any(
        event == "self_add_counters_resolved"
        and data.get("card") == "Fixture Self Counter Costs"
        and data.get("counters_added") == 2
        for event, data in events
    )


def test_simple_activated_destroy_runner_executes_token_target_constraint() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
        "activated_effect": "destroy_target",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
        "activated_remove_effect": "remove_creature",
        "activated_remove_target": "creature_token",
        "target": "creature",
        "target_constraints": {"card_types": ["creature"], "token": True},
        "target_controller": "opponent",
        "destination": "graveyard",
        "activation_cost_mana": "{0}",
        "activation_cost_generic": 0,
        "activation_cost_colors": [],
        "activation_requires_tap": True,
        "activation_requires_sacrifice": False,
        "_rule_logical_key": "battle_rule_v1:dogged-hunter",
    }
    try:
        result = validator.run_simple_activated_destroy(
            battle,
            {
                "name": "Dogged Hunter destroys target creature token",
                "type": "simple_activated_destroy",
                "card": {"name": "Dogged Hunter"},
                "target": {
                    "name": "E2E Token Target",
                    "type_line": "Creature - Goblin",
                    "effect": "creature",
                    "token": True,
                    "is_token": True,
                    "power": 1,
                    "toughness": 1,
                },
                "controller_mana": {},
                "expected_tapped_source": True,
                "expected_destination": "graveyard",
                "logical_rule_key": "battle_rule_v1:dogged-hunter",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Dogged Hunter"
    assert result["target"] == "E2E Token Target"
    assert result["destination"] == "graveyard"
    assert result["source_tapped"] is True
    assert any(
        event == "activated_ability"
        and data.get("card") == "Dogged Hunter"
        and data.get("target") == "E2E Token Target"
        and data.get("activation_kind") == "simple_activated_destroy"
        for event, data in events
    )


def test_simple_activated_destroy_runner_executes_sacrifice_target_cost() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
        "activated_effect": "destroy_target",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
        "activated_remove_effect": "remove_permanent",
        "activated_remove_target": "enchantment",
        "target": "enchantment",
        "target_constraints": {"card_types": ["enchantment"]},
        "target_controller": "opponent",
        "destination": "graveyard",
        "activation_cost_mana": "{G}",
        "activation_cost_generic": 0,
        "activation_cost_colors": ["G"],
        "activation_requires_tap": True,
        "activation_requires_sacrifice": False,
        "activation_requires_sacrifice_target": True,
        "activation_sacrifice_target": "creature",
        "_rule_logical_key": "battle_rule_v1:quagmire-druid",
    }
    try:
        result = validator.run_simple_activated_destroy(
            battle,
            {
                "name": "Quagmire Druid destroys enchantment with sacrifice target cost",
                "type": "simple_activated_destroy",
                "card": {"name": "Quagmire Druid"},
                "target": {
                    "name": "E2E Enchantment Target",
                    "type_line": "Enchantment",
                    "effect": "enchantment",
                    "cmc": 3,
                },
                "sacrifice_target": {
                    "name": "E2E Sacrifice Creature",
                    "type_line": "Creature - Soldier",
                    "effect": "creature",
                    "power": 1,
                    "toughness": 1,
                },
                "controller_mana": {"green": 1},
                "expected_tapped_source": True,
                "expected_destination": "graveyard",
                "expect_target_sacrificed": True,
                "logical_rule_key": "battle_rule_v1:quagmire-druid",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Quagmire Druid"
    assert result["target"] == "E2E Enchantment Target"
    assert result["destination"] == "graveyard"
    assert result["source_tapped"] is True
    assert result["target_sacrificed"] is True
    assert any(
        event == "activated_ability"
        and data.get("card") == "Quagmire Druid"
        and data.get("sacrifice_target") == "creature"
        and data.get("sacrificed_target") == "E2E Sacrifice Creature"
        and data.get("mana_paid") == 1
        for event, data in events
    )


def test_simple_activated_destroy_runner_executes_structured_multi_sacrifice_cost() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
        "activated_effect": "destroy_target",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
        "activated_remove_effect": "remove_permanent",
        "activated_remove_target": "land",
        "target": "land",
        "target_constraints": {"card_types": ["land"]},
        "target_controller": "opponent",
        "destination": "graveyard",
        "activation_cost_mana": "{1}",
        "activation_cost_generic": 1,
        "activation_cost_colors": [],
        "activation_requires_tap": False,
        "activation_requires_sacrifice": False,
        "activation_requires_sacrifice_target": True,
        "activation_sacrifice_cost": {
            "count": 2,
            "target_controller": "self",
            "constraints": {"card_types": ["land"]},
        },
        "_rule_logical_key": "battle_rule_v1:keldon-arsonist",
    }
    try:
        result = validator.run_simple_activated_destroy(
            battle,
            {
                "name": "Keldon Arsonist destroys land with two sacrificed lands",
                "type": "simple_activated_destroy",
                "card": {"name": "Keldon Arsonist"},
                "target": {
                    "name": "E2E Land Target",
                    "type_line": "Land",
                    "effect": "land",
                    "cmc": 0,
                },
                "sacrifice_targets": [
                    {
                        "name": "E2E Sacrifice Land 1",
                        "type_line": "Land",
                        "effect": "land",
                        "cmc": 0,
                    },
                    {
                        "name": "E2E Sacrifice Land 2",
                        "type_line": "Land",
                        "effect": "land",
                        "cmc": 0,
                    },
                ],
                "controller_mana": {"generic": 1},
                "expected_destination": "graveyard",
                "expect_target_sacrificed": True,
                "expected_sacrifice_count": 2,
                "logical_rule_key": "battle_rule_v1:keldon-arsonist",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Keldon Arsonist"
    assert result["target"] == "E2E Land Target"
    assert result["destination"] == "graveyard"
    assert result["target_sacrificed"] is True
    assert result["sacrificed_targets"] == ["E2E Sacrifice Land 1", "E2E Sacrifice Land 2"]
    assert any(
        event == "activated_ability"
        and data.get("card") == "Keldon Arsonist"
        and data.get("sacrificed_targets") == ["E2E Sacrifice Land 1", "E2E Sacrifice Land 2"]
        and data.get("mana_paid") == 1
        for event, data in events
    )


def test_simple_activated_destroy_runner_executes_tap_cost_targets() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
        "activated_effect": "destroy_target",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
        "activated_remove_effect": "remove_creature",
        "activated_remove_target": "creature",
        "target": "creature",
        "target_constraints": {"card_types": ["creature"]},
        "target_controller": "opponent",
        "destination": "graveyard",
        "activation_cost_mana": "{0}",
        "activation_cost_generic": 0,
        "activation_cost_colors": [],
        "activation_requires_tap": True,
        "activation_requires_sacrifice": False,
        "activation_requires_tap_target": True,
        "activation_tap_cost": {
            "count": 3,
            "target_controller": "self",
            "constraints": {
                "card_types": ["creature"],
                "target_colors": ["W"],
                "tapped_state": "untapped",
            },
        },
        "_rule_logical_key": "battle_rule_v1:hand-of-justice",
    }
    try:
        result = validator.run_simple_activated_destroy(
            battle,
            {
                "name": "Hand of Justice destroys creature with white tap cost",
                "type": "simple_activated_destroy",
                "card": {"name": "Hand of Justice"},
                "source_overrides": {"colors": ["W"]},
                "target": {
                    "name": "E2E Creature Target",
                    "type_line": "Creature - Ogre",
                    "effect": "creature",
                    "power": 4,
                    "toughness": 4,
                },
                "tap_cost_targets": [
                    {
                        "name": f"E2E White Tap Creature {index}",
                        "type_line": "Creature - Soldier",
                        "effect": "creature",
                        "colors": ["W"],
                        "power": 1,
                        "toughness": 1,
                    }
                    for index in range(1, 4)
                ],
                "expected_tapped_source": True,
                "expected_destination": "graveyard",
                "expected_tap_cost_count": 3,
                "logical_rule_key": "battle_rule_v1:hand-of-justice",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Hand of Justice"
    assert result["target"] == "E2E Creature Target"
    assert result["source_tapped"] is True
    assert result["tapped_cost_targets"] == [
        "E2E White Tap Creature 1",
        "E2E White Tap Creature 2",
        "E2E White Tap Creature 3",
    ]
    assert any(
        event == "activated_ability"
        and data.get("card") == "Hand of Justice"
        and data.get("tapped_cost_targets")
        == ["E2E White Tap Creature 1", "E2E White Tap Creature 2", "E2E White Tap Creature 3"]
        for event, data in events
    )


def test_simple_activated_destroy_runner_executes_discard_cost() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
        "activated_effect": "destroy_target",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
        "activated_remove_effect": "remove_creature",
        "activated_remove_target": "nonblack_creature",
        "target": "creature",
        "target_constraints": {"card_types": ["creature"], "exclude_colors": ["B"]},
        "target_controller": "opponent",
        "destination": "graveyard",
        "activation_cost_mana": "{2}{B}",
        "activation_cost_generic": 2,
        "activation_cost_colors": ["B"],
        "activation_requires_tap": True,
        "activation_requires_sacrifice": False,
        "activation_discard_count": 1,
        "activation_discard_target": "any_card",
        "activation_requires_discard_card": True,
        "_rule_logical_key": "battle_rule_v1:notorious-assassin",
    }
    try:
        result = validator.run_simple_activated_destroy(
            battle,
            {
                "name": "Notorious Assassin destroys nonblack creature with discard cost",
                "type": "simple_activated_destroy",
                "card": {"name": "Notorious Assassin"},
                "target": {
                    "name": "E2E Nonblack Creature Target",
                    "type_line": "Creature - Giant",
                    "effect": "creature",
                    "colors": ["G"],
                    "power": 6,
                    "toughness": 6,
                },
                "controller_hand": [
                    {
                        "name": "E2E Activated Destroy Discard 1",
                        "type_line": "Instant",
                        "effect": "draw_cards",
                        "cmc": 2,
                    }
                ],
                "controller_mana": {"generic": 2, "black": 1},
                "expected_tapped_source": True,
                "expected_destination": "graveyard",
                "expected_discard_count": 1,
                "expected_discard_target": "any_card",
                "logical_rule_key": "battle_rule_v1:notorious-assassin",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Notorious Assassin"
    assert result["target"] == "E2E Nonblack Creature Target"
    assert result["discarded_count"] == 1
    assert result["source_tapped"] is True
    assert any(
        event == "activated_ability"
        and data.get("card") == "Notorious Assassin"
        and data.get("discarded") == ["E2E Activated Destroy Discard 1"]
        and data.get("discard_target") == "any_card"
        and data.get("mana_paid") == 3
        for event, data in events
    )


def test_simple_activated_self_keyword_runner_executes_keyword_effect() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_self_keyword_until_eot_v1",
        "activated_effect": "self_keyword_until_eot",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_self_keyword_until_eot_v1",
        "target": "self",
        "target_controller": "self",
        "target_constraints": {"source": "self", "card_types": ["creature"]},
        "granted_keywords_until_eot": ["flying"],
        "activation_cost_mana": "{2}{R/W}",
        "activation_cost_generic": 2,
        "activation_cost_colors": ["R/W"],
        "activation_requires_tap": False,
        "activation_discard_count": 1,
        "activation_discard_target": "any_card",
        "activation_requires_discard_card": True,
        "activation_life_cost": 2,
        "activation_requires_sacrifice": False,
        "_rule_logical_key": "battle_rule_v1:cobalt-golem",
    }
    try:
        result = validator.run_simple_activated_self_keyword(
            battle,
            {
                "name": "Cobalt Golem gains flying",
                "type": "simple_activated_self_keyword",
                "card": {"name": "Cobalt Golem"},
                "controller_mana": {"generic": 2, "red": 1},
                "controller_hand": [
                    {"name": "E2E Spare Card A", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
                    {"name": "E2E Spare Card B", "type_line": "Instant", "effect": "direct_damage", "cmc": 1},
                ],
                "expected_keywords": ["flying"],
                "expected_tapped_source": False,
                "expected_discard_count": 1,
                "expected_life_paid": 2,
                "logical_rule_key": "battle_rule_v1:cobalt-golem",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Cobalt Golem"
    assert result["granted_keywords"] == ["flying"]
    assert "flying" in result["source_keywords"]
    assert result["source_tapped"] is False
    assert result["discarded_count"] == 1
    assert result["life_paid"] == 2


def test_simple_activated_self_boost_runner_executes_extra_costs() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
        "activated_effect": "self_stat_modifier_until_eot",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
        "target": "self",
        "target_controller": "self",
        "target_constraints": {"source": "self", "card_types": ["creature"]},
        "power_delta": 2,
        "toughness_delta": 2,
        "power_boost": 2,
        "toughness_boost": 2,
        "activation_cost_mana": "{0}",
        "activation_cost_generic": 0,
        "activation_cost_colors": [],
        "activation_requires_tap": False,
        "activation_discard_count": 1,
        "activation_discard_target": "artifact_card",
        "activation_requires_discard_card": True,
        "activation_life_cost": 1,
        "_rule_logical_key": "battle_rule_v1:fleshgrafter",
    }
    try:
        result = validator.run_simple_activated_self_boost(
            battle,
            {
                "name": "Fleshgrafter pumps itself",
                "type": "simple_activated_self_boost",
                "card": {"name": "Fleshgrafter", "type_line": "Creature - Human Warrior"},
                "controller_hand": [
                    {"name": "E2E Spare Bauble", "type_line": "Artifact", "effect": "mana_source", "cmc": 1},
                    {"name": "E2E Nonartifact Spell", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2},
                ],
                "expected_power_delta": 2,
                "expected_toughness_delta": 2,
                "expected_discard_count": 1,
                "expected_life_paid": 1,
                "logical_rule_key": "battle_rule_v1:fleshgrafter",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Fleshgrafter"
    assert result["source_power"] == 4
    assert result["source_toughness"] == 4
    assert result["discarded_count"] == 1
    assert result["life_paid"] == 1


def test_simple_activated_regenerate_source_runner_consumes_shield_on_destroy() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_regenerate_source_v1",
        "activated_effect": "regenerate_source",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_regenerate_source_v1",
        "target": "self",
        "target_controller": "self",
        "target_constraints": {"source": "self", "card_types": ["creature"]},
        "regenerate_source": True,
        "activation_cost_mana": "{G}",
        "activation_cost_generic": 0,
        "activation_cost_colors": ["G"],
        "activation_requires_tap": False,
        "_rule_logical_key": "battle_rule_v1:cudgel-troll",
    }
    try:
        result = validator.run_simple_activated_regenerate_source(
            battle,
            {
                "name": "Cudgel Troll regenerates",
                "type": "simple_activated_regenerate_source",
                "card": {"name": "Cudgel Troll"},
                "controller_mana": {"green": 1},
                "expected_tapped_source": False,
                "expected_regeneration_shields": 1,
                "logical_rule_key": "battle_rule_v1:cudgel-troll",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Cudgel Troll"
    assert result["destination"] == "battlefield"
    assert result["source_tapped"] is True
    assert result["regeneration_shields_after"] == 0


def test_simple_activated_regenerate_source_runner_executes_extra_costs() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_simple_activated_regenerate_source_v1",
        "activated_effect": "regenerate_source",
        "activated_battle_model_scope": "xmage_permanent_simple_activated_regenerate_source_v1",
        "target": "self",
        "target_controller": "self",
        "target_constraints": {"source": "self", "card_types": ["creature"]},
        "regenerate_source": True,
        "activation_cost_mana": "{0}",
        "activation_cost_generic": 0,
        "activation_cost_colors": [],
        "activation_requires_tap": False,
        "activation_discard_count": 1,
        "activation_discard_target": "any_card",
        "activation_life_cost": 2,
        "_rule_logical_key": "battle_rule_v1:centaur-veteran",
    }
    try:
        result = validator.run_simple_activated_regenerate_source(
            battle,
            {
                "name": "Centaur Veteran regenerates with extra costs",
                "type": "simple_activated_regenerate_source",
                "card": {"name": "Centaur Veteran"},
                "controller_hand": [
                    {"name": "E2E Spare Card", "type_line": "Sorcery", "effect": "draw_cards"}
                ],
                "starting_life": 10,
                "expected_tapped_source": False,
                "expected_regeneration_shields": 1,
                "expected_discard_count": 1,
                "expected_discard_target": "any_card",
                "expected_life_paid": 2,
                "logical_rule_key": "battle_rule_v1:centaur-veteran",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Centaur Veteran"
    assert result["destination"] == "battlefield"
    assert result["discarded_count"] == 1
    assert result["life_paid"] == 2


def test_stat_modifier_until_eot_runner_executes_keyword_only_spell() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "stat_modifier_until_eot",
        "battle_model_scope": "xmage_fixed_keyword_target_creature_until_eot_spell_v1",
        "target": "creature",
        "target_controller": "any",
        "target_constraints": {"card_types": ["creature"]},
        "power_delta": 0,
        "toughness_delta": 0,
        "granted_keywords_until_eot": ["double_strike"],
        "_rule_logical_key": "battle_rule_v1:double-cleave",
    }
    try:
        result = validator.run_stat_modifier_until_eot(
            battle,
            {
                "name": "Double Cleave grants double strike",
                "type": "stat_modifier_until_eot",
                "card": {"name": "Double Cleave", "type_line": "Instant"},
                "expected_power_delta": 0,
                "expected_toughness_delta": 0,
                "expected_keywords": ["double_strike"],
                "logical_rule_key": "battle_rule_v1:double-cleave",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Double Cleave"
    assert result["target_power"] == 2
    assert result["target_toughness"] == 2
    assert result["granted_keywords"] == ["double_strike"]


def test_stat_modifier_until_eot_runner_executes_boost_with_multiple_keywords() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "stat_modifier_until_eot",
        "battle_model_scope": "xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1",
        "target": "creature",
        "target_controller": "any",
        "target_constraints": {"card_types": ["creature"]},
        "power_delta": 1,
        "toughness_delta": 1,
        "granted_keywords_until_eot": ["flying", "first_strike"],
        "_rule_logical_key": "battle_rule_v1:aerial-maneuver",
    }
    try:
        result = validator.run_stat_modifier_until_eot(
            battle,
            {
                "name": "Aerial Maneuver boosts and grants keywords",
                "type": "stat_modifier_until_eot",
                "card": {"name": "Aerial Maneuver", "type_line": "Instant"},
                "expected_power_delta": 1,
                "expected_toughness_delta": 1,
                "expected_keywords": ["flying", "first_strike"],
                "logical_rule_key": "battle_rule_v1:aerial-maneuver",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Aerial Maneuver"
    assert result["target_power"] == 3
    assert result["target_toughness"] == 3
    assert result["granted_keywords"] == ["flying", "first_strike"]


def test_stat_modifier_until_eot_runner_executes_multi_target_boost_keyword_spell() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "stat_modifier_until_eot",
        "battle_model_scope": "xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1",
        "target": "creature",
        "target_controller": "any",
        "target_constraints": {"card_types": ["creature"]},
        "power_delta": 1,
        "toughness_delta": 0,
        "granted_keywords_until_eot": ["first_strike"],
        "target_count": 2,
        "target_count_min": 0,
        "target_count_max": 2,
        "up_to_count": True,
        "_rule_logical_key": "battle_rule_v1:coordinated-assault",
    }
    try:
        result = validator.run_stat_modifier_until_eot(
            battle,
            {
                "name": "Coordinated Assault boosts two targets",
                "type": "stat_modifier_until_eot",
                "card": {"name": "Coordinated Assault", "type_line": "Instant"},
                "targets": [
                    {
                        "name": "E2E Target Creature 1",
                        "type_line": "Creature - Soldier",
                        "power": 2,
                        "toughness": 2,
                    },
                    {
                        "name": "E2E Target Creature 2",
                        "type_line": "Creature - Soldier",
                        "power": 2,
                        "toughness": 2,
                    },
                ],
                "expected_power_delta": 1,
                "expected_toughness_delta": 0,
                "expected_keywords": ["first_strike"],
                "expected_target_count": 2,
                "logical_rule_key": "battle_rule_v1:coordinated-assault",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Coordinated Assault"
    assert result["target_count"] == 2
    assert result["target_power"] == 3
    assert result["target_toughness"] == 2
    assert result["granted_keywords"] == ["first_strike"]
    assert any(
        event == "stat_modifier_until_eot_resolved"
        and data.get("card") == "Coordinated Assault"
        and data.get("target_count") == 2
        and data.get("granted_keywords_until_eot") == ["first_strike"]
        for event, data in events
    )


def test_stat_modifier_until_eot_runner_executes_multi_target_boost_spell() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "stat_modifier_until_eot",
        "battle_model_scope": "xmage_fixed_boost_target_creature_until_eot_spell_v1",
        "target": "creature",
        "target_controller": "any",
        "target_constraints": {"card_types": ["creature"]},
        "power_delta": 2,
        "toughness_delta": 2,
        "target_count": 2,
        "target_count_min": 0,
        "target_count_max": 2,
        "up_to_count": True,
        "_rule_logical_key": "battle_rule_v1:dauntless-onslaught",
    }
    try:
        result = validator.run_stat_modifier_until_eot(
            battle,
            {
                "name": "Dauntless Onslaught boosts two targets",
                "type": "stat_modifier_until_eot",
                "card": {"name": "Dauntless Onslaught", "type_line": "Instant"},
                "targets": [
                    {
                        "name": "E2E Target Creature 1",
                        "type_line": "Creature - Soldier",
                        "power": 2,
                        "toughness": 2,
                    },
                    {
                        "name": "E2E Target Creature 2",
                        "type_line": "Creature - Soldier",
                        "power": 2,
                        "toughness": 2,
                    },
                ],
                "expected_power_delta": 2,
                "expected_toughness_delta": 2,
                "expected_keywords": [],
                "expected_target_count": 2,
                "logical_rule_key": "battle_rule_v1:dauntless-onslaught",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Dauntless Onslaught"
    assert result["target_count"] == 2
    assert result["target_power"] == 4
    assert result["target_toughness"] == 4
    assert result["granted_keywords"] == []
    assert any(
        event == "stat_modifier_until_eot_resolved"
        and data.get("card") == "Dauntless Onslaught"
        and data.get("target_count") == 2
        and data.get("power_delta") == 2
        and data.get("toughness_delta") == 2
        for event, data in events
    )


def test_target_keyword_draw_spell_runner_executes_keyword_and_draw() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "composite_resolution",
        "battle_model_scope": "xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1",
        "target": "creature",
        "target_controller": "any",
        "target_constraints": {"card_types": ["creature"]},
        "power_delta": 0,
        "toughness_delta": 0,
        "granted_keywords_until_eot": ["deathtouch"],
        "draw_count": 1,
        "_composite_rule_components": [
            {
                "effect": "stat_modifier_until_eot",
                "battle_model_scope": "xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1",
                "target": "creature",
                "target_controller": "any",
                "target_constraints": {"card_types": ["creature"]},
                "power_delta": 0,
                "toughness_delta": 0,
                "granted_keywords_until_eot": ["deathtouch"],
            },
            {
                "effect": "draw_cards",
                "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                "count": 1,
            },
        ],
        "_rule_logical_key": "battle_rule_v1:poison-the-blade",
    }
    try:
        result = validator.run_target_keyword_draw_spell(
            battle,
            {
                "name": "Poison the Blade grants deathtouch and draws 1",
                "type": "target_keyword_draw_spell",
                "card": {"name": "Poison the Blade", "type_line": "Instant"},
                "expected_power_delta": 0,
                "expected_toughness_delta": 0,
                "expected_keywords": ["deathtouch"],
                "expected_draw_count": 1,
                "library": [
                    {"name": "E2E Draw Card", "type_line": "Instant", "effect": "draw_cards"},
                    {"name": "E2E Remaining Card", "type_line": "Sorcery", "effect": "draw_cards"},
                ],
                "logical_rule_key": "battle_rule_v1:poison-the-blade",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Poison the Blade"
    assert result["granted_keywords"] == ["deathtouch"]
    assert result["cards_drawn"] == 1
    assert result["hand"] == ["E2E Draw Card"]


def test_target_keyword_draw_spell_runner_respects_multicolored_target_constraint() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "composite_resolution",
        "battle_model_scope": "xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1",
        "target": "creature",
        "target_controller": "any",
        "target_constraints": {"card_types": ["creature"], "color_count_min": 2},
        "power_delta": 0,
        "toughness_delta": 0,
        "granted_keywords_until_eot": ["double_strike"],
        "draw_count": 1,
        "_composite_rule_components": [
            {
                "effect": "stat_modifier_until_eot",
                "battle_model_scope": "xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1",
                "target": "creature",
                "target_controller": "any",
                "target_constraints": {"card_types": ["creature"], "color_count_min": 2},
                "power_delta": 0,
                "toughness_delta": 0,
                "granted_keywords_until_eot": ["double_strike"],
            },
            {
                "effect": "draw_cards",
                "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                "count": 1,
            },
        ],
        "_rule_logical_key": "battle_rule_v1:psychotic-fury",
    }
    try:
        result = validator.run_target_keyword_draw_spell(
            battle,
            {
                "name": "Psychotic Fury grants double strike and draws 1",
                "type": "target_keyword_draw_spell",
                "card": {"name": "Psychotic Fury", "type_line": "Instant"},
                "target": {
                    "name": "E2E Multicolored Target Creature",
                    "type_line": "Creature - Soldier",
                    "power": 2,
                    "toughness": 2,
                    "colors": ["W", "U"],
                },
                "nonmatching_target": {
                    "name": "E2E Monocolored Illegal Creature",
                    "type_line": "Creature - Soldier",
                    "power": 2,
                    "toughness": 2,
                    "colors": ["W"],
                },
                "expected_power_delta": 0,
                "expected_toughness_delta": 0,
                "expected_keywords": ["double_strike"],
                "expected_draw_count": 1,
                "library": [
                    {"name": "E2E Draw Card", "type_line": "Instant", "effect": "draw_cards"},
                    {"name": "E2E Remaining Card", "type_line": "Sorcery", "effect": "draw_cards"},
                ],
                "logical_rule_key": "battle_rule_v1:psychotic-fury",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Psychotic Fury"
    assert result["target"] == "E2E Multicolored Target Creature"
    assert result["nonmatching_target"] == "E2E Monocolored Illegal Creature"
    assert result["granted_keywords"] == ["double_strike"]
    assert result["cards_drawn"] == 1


def test_target_keyword_draw_spell_runner_executes_boost_draw_without_keywords() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "composite_resolution",
        "battle_model_scope": "xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1",
        "target": "creature",
        "target_controller": "self",
        "target_constraints": {"card_types": ["creature"], "controller_scope": "self", "combat_state": "blocking"},
        "power_delta": 2,
        "toughness_delta": 2,
        "granted_keywords_until_eot": [],
        "draw_count": 1,
        "_composite_rule_components": [
            {
                "effect": "stat_modifier_until_eot",
                "battle_model_scope": "xmage_fixed_boost_target_creature_until_eot_spell_v1",
                "target": "creature",
                "target_controller": "self",
                "target_constraints": {
                    "card_types": ["creature"],
                    "controller_scope": "self",
                    "combat_state": "blocking",
                },
                "power_delta": 2,
                "toughness_delta": 2,
                "granted_keywords_until_eot": [],
            },
            {
                "effect": "draw_cards",
                "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                "count": 1,
            },
        ],
        "_rule_logical_key": "battle_rule_v1:aangs-defense",
    }
    try:
        result = validator.run_target_keyword_draw_spell(
            battle,
            {
                "name": "Aang's Defense boosts blocking target and draws 1",
                "type": "target_keyword_draw_spell",
                "card": {"name": "Aang's Defense", "type_line": "Instant"},
                "target": {
                    "name": "E2E Blocking Target Creature",
                    "type_line": "Creature - Soldier",
                    "power": 2,
                    "toughness": 2,
                    "blocking": True,
                },
                "nonmatching_target": {
                    "name": "E2E Nonblocking Illegal Creature",
                    "type_line": "Creature - Soldier",
                    "power": 2,
                    "toughness": 2,
                    "blocking": False,
                },
                "expected_target_constraints": {
                    "card_types": ["creature"],
                    "controller_scope": "self",
                    "combat_state": "blocking",
                },
                "expected_power_delta": 2,
                "expected_toughness_delta": 2,
                "expected_keywords": [],
                "expected_draw_count": 1,
                "library": [
                    {"name": "E2E Draw Card", "type_line": "Instant", "effect": "draw_cards"},
                    {"name": "E2E Remaining Card", "type_line": "Sorcery", "effect": "draw_cards"},
                ],
                "logical_rule_key": "battle_rule_v1:aangs-defense",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Aang's Defense"
    assert result["target"] == "E2E Blocking Target Creature"
    assert result["nonmatching_target"] == "E2E Nonblocking Illegal Creature"
    assert result["target_power"] == 4
    assert result["target_toughness"] == 4
    assert result["granted_keywords"] == []
    assert result["cards_drawn"] == 1
    assert result["hand"] == ["E2E Draw Card"]


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


def test_simple_mana_source_refresh_runner_pays_discard_cost() -> None:
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
        "produces": "B",
        "produced_mana_symbols": ["B"],
        "mana_activation_requires_tap": False,
        "activation_discard_count": 1,
        "activation_discard_target": "any_card",
        "_rule_logical_key": "battle_rule_v1:skirge",
    }
    try:
        result = validator.run_simple_mana_source_refresh(
            battle,
            {
                "name": "Skirge Familiar refreshes modeled mana source",
                "type": "simple_mana_source_refresh",
                "card": {"name": "Skirge Familiar"},
                "type_line": "Creature - Imp",
                "source_overrides": {"summoning_sick": False},
                "controller_hand": [
                    {"name": "E2E Spare Card", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 2}
                ],
                "expected_available_mana_after_refresh": 1,
                "expected_tapped": False,
                "expected_sources": 1,
                "expected_discard_count": 1,
                "expected_discard_target": "any_card",
                "logical_rule_key": "battle_rule_v1:skirge",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Skirge Familiar"
    assert result["available_mana"] == 1
    assert result["discarded_count"] == 1


def test_simple_mana_source_refresh_runner_validates_pain_talisman_modes() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "ramp_permanent",
        "battle_model_scope": "pain_talisman_color_pair_partial_v1",
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "CWB",
        "life_for_colored_mana": 1,
        "mana_activation_requires_tap": True,
        "_rule_logical_key": "battle_rule_v1:talisman-hierarchy",
    }
    try:
        result = validator.run_simple_mana_source_refresh(
            battle,
            {
                "name": "Talisman of Hierarchy refreshes pain mana",
                "type": "simple_mana_source_refresh",
                "card": {"name": "Talisman of Hierarchy"},
                "expected_available_mana_after_refresh": 1,
                "expected_tapped": True,
                "expected_sources": 1,
                "expected_conditional_mana": 1,
                "expected_conditional_life_loss_by_color": {
                    "colorless": 0,
                    "white": 1,
                    "black": 1,
                },
                "logical_rule_key": "battle_rule_v1:talisman-hierarchy",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Talisman of Hierarchy"
    assert result["conditional_mana"] == 1
    assert result["conditional_life_loss_by_color"] == {
        "colorless": 0,
        "white": 1,
        "black": 1,
    }


def test_simple_mana_source_refresh_runner_executes_activation_life_gain() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "ramp_permanent",
        "battle_model_scope": "xmage_simple_tap_mana_source_with_gain_life_v1",
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "C",
        "produced_mana_symbols": ["C"],
        "mana_activation_life_gain": 1,
        "mana_activation_requires_tap": True,
        "_rule_logical_key": "battle_rule_v1:pristine-talisman",
    }
    try:
        result = validator.run_simple_mana_source_refresh(
            battle,
            {
                "name": "Pristine Talisman refreshes mana and gains life",
                "type": "simple_mana_source_refresh",
                "card": {"name": "Pristine Talisman"},
                "starting_life": 40,
                "expected_available_mana_after_refresh": 1,
                "expected_tapped": True,
                "expected_sources": 1,
                "expected_mana_activation_life_gain": 1,
                "expected_life_after_refresh": 41,
                "logical_rule_key": "battle_rule_v1:pristine-talisman",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Pristine Talisman"
    assert result["available_mana"] == 1
    assert result["mana_activation_life_gain"] == 1
    assert result["life_after_refresh"] == 41


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


def test_creature_dies_add_counters_runner_executes_minus_counter_trigger() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_creature_dies_add_counters_target_creature_v1",
        "ability_kind": "triggered",
        "trigger": "dies",
        "trigger_effect": "add_counters",
        "dies_add_counters": True,
        "dies_add_counters_target": "creature",
        "dies_add_counters_counter_type": "-1/-1",
        "dies_add_counters_count": 1,
        "target": "creature",
        "target_constraints": {"card_types": ["creature"]},
        "target_controller": "any",
        "counter_type": "-1/-1",
        "counter_count": 1,
        "count": 1,
        "_rule_logical_key": "battle_rule_v1:bile-vial-boggart",
    }
    try:
        result = validator.run_creature_dies_add_counters(
            battle,
            {
                "name": "Bile-Vial Boggart dies and adds a -1/-1 counter",
                "type": "creature_dies_add_counters",
                "card": {"name": "Bile-Vial Boggart", "type_line": "Creature", "effect": "creature"},
                "target": {
                    "name": "E2E Dies Counter Target",
                    "type_line": "Creature - Soldier",
                    "effect": "creature",
                    "power": 3,
                    "toughness": 3,
                },
                "target_owner": "opponent",
                "expected_counter_type": "-1/-1",
                "expected_counter_count": 1,
                "logical_rule_key": "battle_rule_v1:bile-vial-boggart",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Bile-Vial Boggart"
    assert result["target"] == "E2E Dies Counter Target"
    assert result["counter_type"] == "-1/-1"
    assert result["counters_added"] == 1
    assert any(
        event == "dies_add_counters_resolved"
        and data.get("card") == "Bile-Vial Boggart"
        and data.get("target") == "E2E Dies Counter Target"
        and data.get("counters_added") == 1
        and data.get("trigger") == "dies"
        for event, data in events
    )


def test_creature_etb_scry_runner_executes_trigger() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_creature_etb_scry_v1",
        "ability_kind": "triggered",
        "trigger": "enters_battlefield",
        "trigger_effect": "scry",
        "etb_trigger_effect": "scry",
        "etb_scry_count": 2,
        "trigger_scry_count": 2,
        "keywords": ["flying"],
        "flying": True,
        "_rule_logical_key": "battle_rule_v1:omenspeaker",
    }
    try:
        result = validator.run_creature_etb_scry(
            battle,
            {
                "name": "Omenspeaker enters and scries 2",
                "type": "creature_etb_scry",
                "card": {"name": "Omenspeaker", "type_line": "Creature", "effect": "creature"},
                "expected_scry_count": 2,
                "expected_keywords": ["flying"],
                "library_top_names": ["E2E Land", "E2E Action", "E2E Reserve"],
                "logical_rule_key": "battle_rule_v1:omenspeaker",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Omenspeaker"
    assert result["scry_count"] == 2
    assert result["validated_keywords"] == ["flying"]
    assert result["looked_at"] == ["E2E Land", "E2E Action"]
    assert any(event == "etb_scry_resolved" for event, _ in events)


def test_creature_etb_draw_discard_runner_executes_trigger() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_creature_etb_draw_discard_cards_v1",
        "ability_kind": "triggered",
        "trigger": "enters_battlefield",
        "trigger_effect": "draw_discard",
        "etb_draw_discard": True,
        "etb_draw_count": 2,
        "etb_discard_count": 1,
        "draw_count": 2,
        "discard_count": 1,
        "draw_discard_order": "draw_then_discard",
        "keywords": ["flying"],
        "flying": True,
        "_rule_logical_key": "battle_rule_v1:bazaar-trademage",
    }
    try:
        result = validator.run_creature_etb_draw_discard(
            battle,
            {
                "name": "Bazaar Trademage enters and loots",
                "type": "creature_etb_draw_discard",
                "card": {"name": "Bazaar Trademage", "type_line": "Creature", "effect": "creature"},
                "controller_hand": [
                    {"name": "E2E Discard Candidate", "type_line": "Land", "effect": "land", "cmc": 0}
                ],
                "controller_library": [
                    {"name": "E2E Drawn Card A", "type_line": "Instant", "effect": "draw_cards", "cmc": 2},
                    {"name": "E2E Drawn Card B", "type_line": "Sorcery", "effect": "draw_cards", "cmc": 3},
                ],
                "expected_draw_count": 2,
                "expected_discard_count": 1,
                "expected_hand_after": 2,
                "expected_graveyard_after": 1,
                "expected_keywords": ["flying"],
                "logical_rule_key": "battle_rule_v1:bazaar-trademage",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Bazaar Trademage"
    assert result["cards_drawn"] == 2
    assert result["cards_discarded"] == 1
    assert result["hand_after"] == 2
    assert result["graveyard_after"] == 1
    assert result["validated_keywords"] == ["flying"]
    assert any(event == "etb_draw_discard_resolved" for event, _ in events)


def test_creature_etb_target_stat_modifier_runner_executes_trigger() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_creature_etb_fixed_boost_target_until_eot_v1",
        "ability_kind": "triggered",
        "trigger": "enters_battlefield",
        "trigger_effect": "stat_modifier_until_eot",
        "etb_target_stat_modifier": True,
        "target": "creature",
        "target_controller": "any",
        "target_constraints": {"card_types": ["creature"]},
        "power_delta": -1,
        "toughness_delta": -1,
        "power_boost": -1,
        "toughness_boost": -1,
        "duration": "until_end_of_turn",
        "_rule_logical_key": "battle_rule_v1:blister-beetle",
    }
    try:
        result = validator.run_creature_etb_target_stat_modifier(
            battle,
            {
                "name": "Blister Beetle weakens a target creature",
                "type": "creature_etb_target_stat_modifier",
                "card": {"name": "Blister Beetle", "type_line": "Creature - Insect", "power": 1, "toughness": 1},
                "expected_power_delta": -1,
                "expected_toughness_delta": -1,
                "logical_rule_key": "battle_rule_v1:blister-beetle",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Blister Beetle"
    assert result["target"] == "E2E Target Creature"
    assert result["target_power"] == 3
    assert result["target_toughness"] == 3
    assert result["power_delta"] == -1
    assert result["toughness_delta"] == -1
    assert any(
        event == "stat_modifier_until_eot_resolved" and data.get("card") == "Blister Beetle"
        for event, data in events
    )


def test_creature_etb_each_player_sacrifice_runner_executes_trigger() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_creature_etb_each_player_sacrifice_fixed_permanents_v1",
        "ability_kind": "triggered",
        "trigger": "enters_battlefield",
        "trigger_effect": "each_player_sacrifice",
        "etb_each_player_sacrifice": True,
        "sacrifice_count": 1,
        "sacrifice_card_types": ["creature"],
        "sacrifice_scope": "each_player",
        "sacrifice_choice": "controller_choice_lowest_value",
        "_rule_logical_key": "battle_rule_v1:fleshbag-marauder",
    }
    try:
        result = validator.run_each_player_sacrifice(
            battle,
            {
                "name": "Fleshbag Marauder enters and each player sacrifices a creature",
                "type": "each_player_sacrifice",
                "card": {
                    "name": "Fleshbag Marauder",
                    "type_line": "Creature - Zombie Warrior",
                    "effect": "creature",
                },
                "sacrifice_count": 1,
                "sacrifice_card_types": ["creature"],
                "expected_sacrificed_per_player": 1,
                "logical_rule_key": "battle_rule_v1:fleshbag-marauder",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Fleshbag Marauder"
    assert result["sacrificed"] == 2
    assert result["sacrifice_count"] == 1
    assert any(
        event == "each_player_sacrifice_resolved" and data.get("card") == "Fleshbag Marauder"
        for event, data in events
    )


def test_creature_dies_each_player_sacrifice_runner_executes_trigger() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_creature_dies_each_player_sacrifice_fixed_permanents_v1",
        "ability_kind": "triggered",
        "trigger": "dies",
        "trigger_effect": "each_player_sacrifice",
        "dies_each_player_sacrifice": True,
        "sacrifice_count": 1,
        "sacrifice_card_types": ["land"],
        "sacrifice_scope": "each_player",
        "sacrifice_choice": "controller_choice_lowest_value",
        "_rule_logical_key": "battle_rule_v1:akki-blizzard-herder",
    }
    try:
        result = validator.run_creature_dies_each_player_sacrifice(
            battle,
            {
                "name": "Akki Blizzard-Herder dies and each player sacrifices a land",
                "type": "creature_dies_each_player_sacrifice",
                "card": {
                    "name": "Akki Blizzard-Herder",
                    "type_line": "Creature - Goblin Shaman",
                    "effect": "creature",
                },
                "sacrifice_count": 1,
                "sacrifice_card_types": ["land"],
                "expected_sacrificed_per_player": 1,
                "logical_rule_key": "battle_rule_v1:akki-blizzard-herder",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Akki Blizzard-Herder"
    assert result["source_died"] is True
    assert result["sacrificed"] == 2
    assert result["sacrifice_count"] == 1
    assert any(
        event == "each_player_sacrifice_resolved"
        and data.get("card") == "Akki Blizzard-Herder"
        and data.get("trigger") == "dies"
        for event, data in events
    )


def test_fixed_create_tokens_runner_counts_controlled_subtype_support() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "token_maker",
        "battle_model_scope": "xmage_controlled_subtype_create_creature_tokens_spell_v1",
        "ability_kind": "one_shot",
        "token_count_source": "controlled_permanents_with_subtype",
        "token_count_subtype": "Elf",
        "token_name": "Elf Warrior Token",
        "token_power": 1,
        "token_toughness": 1,
        "token_subtype": "Elf Warrior",
        "token_colors": ["G"],
        "_rule_logical_key": "battle_rule_v1:elven-ambush",
    }
    try:
        result = validator.run_fixed_create_creature_tokens(
            battle,
            {
                "name": "Elven Ambush creates modeled creature tokens",
                "type": "fixed_create_creature_tokens",
                "card": {"name": "Elven Ambush"},
                "controlled_permanent_subtype": "Elf",
                "controlled_permanent_subtype_count": 3,
                "expected_token": {
                    "name": "Elf Warrior Token",
                    "count": 3,
                    "power": 1,
                    "toughness": 1,
                    "subtype": "Elf Warrior",
                    "colors": ["G"],
                },
                "logical_rule_key": "battle_rule_v1:elven-ambush",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Elven Ambush"
    assert result["tokens_created"] == 3
    assert result["token_name"] == "Elf Warrior Token"


def test_fixed_create_tokens_runner_validates_static_cant_block() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "token_maker",
        "battle_model_scope": "xmage_fixed_create_creature_tokens_spell_v1",
        "ability_kind": "one_shot",
        "token_count": 1,
        "token_name": "Rat Token",
        "token_power": 1,
        "token_toughness": 1,
        "token_subtype": "Rat",
        "token_colors": ["B"],
        "token_cant_block": True,
        "_rule_logical_key": "battle_rule_v1:fixture-rat-call",
    }
    try:
        result = validator.run_fixed_create_creature_tokens(
            battle,
            {
                "name": "Fixture Rat Call creates modeled creature tokens",
                "type": "fixed_create_creature_tokens",
                "card": {"name": "Fixture Rat Call"},
                "expected_token": {
                    "name": "Rat Token",
                    "count": 1,
                    "power": 1,
                    "toughness": 1,
                    "subtype": "Rat",
                    "colors": ["B"],
                    "cant_block": True,
                },
                "logical_rule_key": "battle_rule_v1:fixture-rat-call",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Fixture Rat Call"
    assert result["tokens_created"] == 1
    assert result["token_cant_block"] is True


def test_fixed_create_tokens_runner_counts_dynamic_support_state() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    cases = [
        (
            "Deploy to the Front",
            {"token_count_source": "all_creatures_on_battlefield"},
            {"controlled_battlefield_creature_count": 2, "opponent_battlefield_creature_count": 2},
            4,
        ),
        (
            "Flurry of Wings",
            {"token_count_source": "attacking_creatures"},
            {"attacking_creature_count": 3},
            3,
        ),
        (
            "Crash the Party",
            {"token_count_source": "controlled_tapped_creatures", "token_tapped": True},
            {"controlled_tapped_creature_count": 3},
            3,
        ),
        (
            "Fungal Sprouting",
            {"token_count_source": "greatest_power_among_controlled_creatures"},
            {"controlled_creature_powers": [1, 4, 2]},
            4,
        ),
        (
            "Spontaneous Generation",
            {"token_count_source": "controller_hand_count"},
            {"controller_hand_card_count": 4},
            4,
        ),
        (
            "Ordered Migration",
            {"token_count_source": "domain_basic_land_types"},
            {"domain_basic_land_subtypes": ["Plains", "Island", "Mountain"]},
            3,
        ),
        (
            "Fixture Graveborn",
            {"token_count_source": "controller_graveyard_creature_count"},
            {"controller_graveyard_creature_count": 3},
            3,
        ),
        (
            "Rise from the Tides",
            {"token_count_source": "controller_graveyard_instant_sorcery_count"},
            {"controller_graveyard_instant_sorcery_count": 3},
            3,
        ),
        (
            "Goblin Gathering",
            {
                "token_count_source": "named_cards_in_controller_graveyard_plus_base",
                "token_count_card_name": "Goblin Gathering",
                "token_count_base": 2,
            },
            {"controller_graveyard_named_card": "Goblin Gathering", "controller_graveyard_named_card_count": 2},
            4,
        ),
    ]
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    try:
        for card_name, count_fields, scenario_fields, expected_count in cases:
            events = []
            battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
            battle.get_card_effect = lambda card, fields=count_fields, name=card_name: {
                "effect": "token_maker",
                "battle_model_scope": "xmage_dynamic_count_create_creature_tokens_spell_v1",
                "ability_kind": "one_shot",
                "card_name": name,
                "token_name": "Soldier Token",
                "token_power": 1,
                "token_toughness": 1,
                "token_subtype": "Soldier",
                "token_colors": ["W"],
                "_rule_logical_key": f"battle_rule_v1:{name.lower().replace(' ', '-')}",
                **fields,
            }
            result = validator.run_fixed_create_creature_tokens(
                battle,
                {
                    "name": f"{card_name} creates modeled creature tokens",
                    "type": "fixed_create_creature_tokens",
                    "card": {"name": card_name},
                    "expected_token": {
                        "name": "Soldier Token",
                        "count": expected_count,
                        "power": 1,
                        "toughness": 1,
                        "subtype": "Soldier",
                        "colors": ["W"],
                        "tapped": bool(count_fields.get("token_tapped")),
                    },
                    "logical_rule_key": f"battle_rule_v1:{card_name.lower().replace(' ', '-')}",
                    **scenario_fields,
                },
                events,
            )
            assert result["card_name"] == card_name
            assert result["tokens_created"] == expected_count
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect


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


def test_spell_cast_gain_life_runner_blocks_nonmatching_and_resolves_matching_spell() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_spell_cast_gain_life_v1",
        "trigger": "noncreature_spell_cast",
        "trigger_effect": "gain_life",
        "spell_cast_gain_life": True,
        "spell_cast_gain_life_amount": 2,
        "_rule_logical_key": "battle_rule_v1:student-of-ojutai",
    }
    try:
        result = validator.run_spell_cast_gain_life(
            battle,
            {
                "name": "Student of Ojutai gains life when matching spell is cast",
                "type": "spell_cast_gain_life",
                "card": {
                    "name": "Student of Ojutai",
                    "type_line": "Creature - Human Monk",
                    "effect": "creature",
                },
                "starting_life": 20,
                "matching_spell": {"name": "Blue Instant", "type_line": "Instant", "cmc": 2},
                "nonmatching_spell": {
                    "name": "Creature Spell",
                    "type_line": "Creature - Soldier",
                    "cmc": 2,
                },
                "expected_trigger": "noncreature_spell_cast",
                "expected_life_gain": 2,
                "expected_life_after": 22,
                "logical_rule_key": "battle_rule_v1:student-of-ojutai",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Student of Ojutai"
    assert result["life_after"] == 22
    assert result["trigger"] == "noncreature_spell_cast"
    assert result["trigger_spell"] == "Blue Instant"


def test_spell_cast_gain_life_runner_resolves_any_player_opponent_spell() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "life_gain_engine",
        "battle_model_scope": "xmage_spell_cast_gain_life_v1",
        "trigger": "spell_cast",
        "trigger_effect": "gain_life",
        "spell_cast_gain_life": True,
        "spell_cast_gain_life_amount": 1,
        "spell_cast_gain_life_required_colors": ["W"],
        "spell_cast_gain_life_any_player": True,
        "_rule_logical_key": "battle_rule_v1:angels-feather",
    }
    try:
        result = validator.run_spell_cast_gain_life(
            battle,
            {
                "name": "Angel's Feather gains life when opponent casts white spell",
                "type": "spell_cast_gain_life",
                "card": {
                    "name": "Angel's Feather",
                    "type_line": "Artifact",
                    "effect": "life_gain_engine",
                },
                "starting_life": 20,
                "matching_spell": {
                    "name": "White Instant",
                    "type_line": "Instant",
                    "colors": ["W"],
                    "cmc": 2,
                },
                "matching_spell_controller": "opponent",
                "nonmatching_spell": {
                    "name": "Green Sorcery",
                    "type_line": "Sorcery",
                    "colors": ["G"],
                    "cmc": 2,
                },
                "nonmatching_spell_controller": "opponent",
                "expected_trigger": "spell_cast",
                "expected_life_gain": 1,
                "expected_life_after": 21,
                "logical_rule_key": "battle_rule_v1:angels-feather",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Angel's Feather"
    assert result["life_after"] == 21
    assert result["trigger"] == "spell_cast"
    assert result["trigger_spell"] == "White Instant"
    assert result["trigger_spell_controller"] == "Opponent"


def test_spell_cast_gain_life_runner_resolves_matching_land_enter_trigger() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: (
        {
            "effect": "life_gain_engine",
            "battle_model_scope": "xmage_spell_cast_gain_life_v1",
            "trigger": "spell_cast",
            "trigger_effect": "gain_life",
            "spell_cast_gain_life": True,
            "spell_cast_gain_life_amount": 1,
            "spell_cast_gain_life_required_colors": ["B"],
            "land_enter_gain_life": True,
            "land_enter_gain_life_amount": 1,
            "land_enter_gain_life_subtypes": ["Swamp"],
            "_rule_logical_key": "battle_rule_v1:staff-of-the-death-magus",
        }
        if card.get("name") == "Staff of the Death Magus"
        else {"effect": "land"} if "Land" in str(card.get("type_line") or "") else {}
    )
    try:
        result = validator.run_spell_cast_gain_life(
            battle,
            {
                "name": "Staff of the Death Magus gains life from spell and Swamp",
                "type": "spell_cast_gain_life",
                "card": {
                    "name": "Staff of the Death Magus",
                    "type_line": "Artifact",
                    "effect": "life_gain_engine",
                },
                "starting_life": 20,
                "matching_spell": {
                    "name": "Black Sorcery",
                    "type_line": "Sorcery",
                    "colors": ["B"],
                    "cmc": 2,
                },
                "nonmatching_spell": {
                    "name": "White Sorcery",
                    "type_line": "Sorcery",
                    "colors": ["W"],
                    "cmc": 2,
                },
                "matching_land": {
                    "name": "Swamp",
                    "type_line": "Basic Land - Swamp",
                    "effect": "land",
                },
                "nonmatching_land": {
                    "name": "Plains",
                    "type_line": "Basic Land - Plains",
                    "effect": "land",
                },
                "expected_trigger": "spell_cast",
                "expected_life_gain": 1,
                "expected_life_after": 21,
                "expected_land_life_after": 22,
                "logical_rule_key": "battle_rule_v1:staff-of-the-death-magus",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Staff of the Death Magus"
    assert result["life_after"] == 22
    assert result["land_trigger"] == "land_enter"
    assert result["trigger_land"] == "Swamp"


def test_spell_cast_token_maker_runner_blocks_nonmatching_and_resolves_matching_spell() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "creature",
        "battle_model_scope": "xmage_spell_cast_create_creature_token_v1",
        "trigger": "noncreature_spell_cast",
        "trigger_effect": "token_maker",
        "spell_cast_token_maker": True,
        "trigger_token_count": 1,
        "token_count": 1,
        "token_name": "Soldier Token",
        "token_power": 1,
        "token_toughness": 1,
        "token_subtype": "Soldier",
        "artifact_tokens": True,
        "_rule_logical_key": "battle_rule_v1:third-path-iconoclast",
    }
    try:
        result = validator.run_spell_cast_token_maker(
            battle,
            {
                "name": "Third Path Iconoclast creates token when matching spell is cast",
                "type": "spell_cast_token_maker",
                "card": {
                    "name": "Third Path Iconoclast",
                    "type_line": "Creature - Human Monk",
                    "effect": "creature",
                },
                "matching_spell": {"name": "Blue Instant", "type_line": "Instant", "cmc": 2},
                "nonmatching_spell": {
                    "name": "Creature Spell",
                    "type_line": "Creature - Soldier",
                    "cmc": 2,
                },
                "expected_trigger": "noncreature_spell_cast",
                "expected_tokens_created": 1,
                "expected_token": {
                    "name": "Soldier Token",
                    "count": 1,
                    "power": 1,
                    "toughness": 1,
                    "subtype": "Soldier",
                    "artifact": True,
                },
                "logical_rule_key": "battle_rule_v1:third-path-iconoclast",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Third Path Iconoclast"
    assert result["tokens_created"] == 1
    assert result["trigger"] == "noncreature_spell_cast"
    assert result["trigger_spell"] == "Blue Instant"
    assert result["token_names"] == ["Soldier Token"]


def test_modal_damage_or_destroy_runner_executes_chosen_destroy_mode() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "modal_spell",
        "battle_model_scope": "xmage_choose_one_damage_or_destroy_target_spell_v1",
        "mode_selection": "choose_one",
        "mode_selection_model": "best_available_mode",
        "mode_min": 1,
        "mode_max": 1,
        "modal_modes": [
            {
                "mode": "direct_damage",
                "effect": "direct_damage",
                "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
                "amount": 5,
                "damage": 5,
                "target": "creature",
                "target_constraints": {"card_types": ["creature"]},
            },
            {
                "mode": "destroy_target",
                "effect": "remove_permanent",
                "battle_model_scope": "xmage_destroy_target_spell_v1",
                "target": "artifact",
                "target_constraints": {"card_types": ["artifact"]},
                "destination": "graveyard",
            },
        ],
        "_rule_logical_key": "battle_rule_v1:fiery-intervention",
    }
    try:
        result = validator.run_modal_damage_or_destroy(
            battle,
            {
                "name": "Fiery Intervention chooses destroy mode over damage mode",
                "type": "modal_damage_or_destroy",
                "card": {"name": "Fiery Intervention", "type_line": "Sorcery"},
                "destroy_target": {
                    "name": "E2E Legal Modal Destroy Target",
                    "type_line": "Artifact",
                    "effect": "artifact",
                    "cmc": 3,
                },
                "damage_target": {
                    "name": "E2E Legal Modal Damage Target",
                    "type_line": "Creature - Goblin",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                    "cmc": 2,
                },
                "expected_selected_mode": "destroy_target",
                "expected_removed_target": "E2E Legal Modal Destroy Target",
                "expected_damage_target_survives": "E2E Legal Modal Damage Target",
                "expected_destination": "graveyard",
                "logical_rule_key": "battle_rule_v1:fiery-intervention",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Fiery Intervention"
    assert result["selected_mode"] == "destroy_target"
    assert result["removed_target"] == "E2E Legal Modal Destroy Target"


def test_proliferate_draw_runner_adds_counters_and_draws() -> None:
    battle = validator.load_battle(validator.DEFAULT_BATTLE)
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_get_card_effect = battle.get_card_effect
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.get_card_effect = lambda card: {
        "effect": "composite_resolution",
        "battle_model_scope": "xmage_fixed_proliferate_and_draw_cards_spell_v1",
        "draw_count": 1,
        "proliferate_count": 1,
        "resolution_order": "proliferate_then_draw",
        "_composite_rule_components": [
            {
                "effect": "proliferate",
                "battle_model_scope": "xmage_fixed_proliferate_spell_v1",
                "proliferate_count": 1,
            },
            {
                "effect": "draw_cards",
                "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                "count": 1,
            },
        ],
        "_rule_logical_key": "battle_rule_v1:contentious-plan",
    }
    try:
        result = validator.run_proliferate_draw_spell(
            battle,
            {
                "name": "Contentious Plan proliferates and draws 1",
                "type": "proliferate_draw_spell",
                "card": {"name": "Contentious Plan", "type_line": "Sorcery"},
                "controller_battlefield": [
                    {
                        "name": "E2E Controller Counter Creature",
                        "type_line": "Creature - Soldier",
                        "effect": "creature",
                        "power": 2,
                        "toughness": 2,
                        "plus_one_counters": 1,
                        "counters": {"+1/+1": 1},
                    }
                ],
                "opponent_battlefield": [
                    {
                        "name": "E2E Opponent Charge Artifact",
                        "type_line": "Artifact",
                        "effect": "artifact",
                        "charge_counters": 2,
                        "counters": {"charge": 2},
                    }
                ],
                "opponent_poison_counters": 1,
                "expected_controller_plus_one_counters": 2,
                "expected_controller_power": 3,
                "expected_controller_toughness": 3,
                "expected_opponent_charge_counters": 3,
                "expected_opponent_poison_counters": 2,
                "expected_draw_count": 1,
                "library": [{"name": "E2E Draw Card", "type_line": "Instant"}],
                "logical_rule_key": "battle_rule_v1:contentious-plan",
            },
            events,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.get_card_effect = previous_get_card_effect

    assert result["card_name"] == "Contentious Plan"
    assert result["draw_count"] == 1
    assert result["controller_plus_one_counters"] == 2
    assert result["opponent_charge_counters"] == 3
    assert result["opponent_poison_counters"] == 2
