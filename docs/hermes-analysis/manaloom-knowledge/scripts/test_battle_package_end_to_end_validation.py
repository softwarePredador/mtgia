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
