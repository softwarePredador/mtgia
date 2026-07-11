#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "xmage_batch_pg_package_builder.py"


def load_module():
    spec = importlib.util.spec_from_file_location("xmage_batch_pg_package_builder_mod", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


builder = load_module()


def test_package_deck_role_derives_role_for_exact_effect_with_manual_placeholder() -> None:
    proposal = {
        "effect_json": {
            "effect": "ramp_permanent",
            "mana_produced": 1,
            "battle_model_scope": "land_type_mana_dork_plus_counter_triples_adapt_v1",
        },
        "deck_role_json": {
            "category": "manual_review",
            "effect": "external_reference_required_manual_model",
        },
    }

    assert builder.package_deck_role(proposal) == {
        "category": "ramp",
        "effect": "ramp_permanent",
    }


def test_package_deck_role_derives_role_for_unknown_activated_untap_target() -> None:
    proposal = {
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_untap_target_v1",
            "activated_effect": "untap_target",
            "activated_untap_target": "land",
            "target": "land",
        },
        "deck_role_json": {
            "category": "unknown",
            "effect": "creature",
            "target": "land",
        },
    }

    assert builder.package_deck_role(proposal) == {
        "category": "ramp",
        "effect": "creature",
        "subtype": "land_untap",
        "target": "land",
    }


def test_package_deck_role_preserves_true_external_reference_placeholder() -> None:
    proposal = {
        "effect_json": {"effect": "external_reference_required_manual_model"},
        "deck_role_json": {
            "category": "manual_review",
            "effect": "external_reference_required_manual_model",
        },
    }

    assert builder.package_deck_role(proposal) == proposal["deck_role_json"]


def test_counter_unless_pays_dynamic_fields_and_execution_scenario_are_manifested() -> None:
    proposal = {
        "normalized_name": "spell stutter",
        "card_name": "Spell Stutter",
        "oracle_hash": "hash-counter",
        "logical_rule_key": "battle_rule_v1:counter",
        "effect_json": {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_unless_controller_pays_generic_v1",
            "target": "spell",
            "counter_unless_pays_generic": 0,
            "counter_unless_pays_amount_source": "controlled_subtype_count",
            "counter_unless_pays_subtype": "faerie",
            "counter_unless_pays_base": 2,
            "counter_unless_pays_per": 1,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert expected["required_effect_fields"]["counter_unless_pays_amount_source"] == "controlled_subtype_count"
    assert expected["required_effect_fields"]["counter_unless_pays_subtype"] == "faerie"
    assert scenario["type"] == "counter_unless_pays_response"
    assert scenario["expected_counter_unless_pays_generic"] == 4
    assert scenario["expected_counter_unless_pays_count"] == 2


def test_counter_unless_pays_draw_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "runeboggle",
        "card_name": "Runeboggle",
        "oracle_hash": "hash-runeboggle",
        "logical_rule_key": "battle_rule_v1:runeboggle",
        "effect_json": {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_unless_controller_pays_generic_draw_card_v1",
            "target": "spell",
            "counter_unless_pays_generic": 1,
            "draw_on_counter": 1,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert expected["required_effect_fields"]["draw_on_counter"] == 1
    assert scenario["type"] == "counter_unless_pays_response"
    assert scenario["expected_counter_unless_pays_generic"] == 1
    assert scenario["expected_cards_drawn"] == 1


def test_battlefield_to_library_removal_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "excommunicate",
        "card_name": "Excommunicate",
        "oracle_hash": "hash-excommunicate",
        "logical_rule_key": "battle_rule_v1:excommunicate",
        "effect_json": {
            "effect": "remove_permanent",
            "battle_model_scope": "xmage_put_target_permanent_on_library_spell_v1",
            "zone_move": "battlefield_to_library",
            "from_zone": "battlefield",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_controller": "opponent",
            "library_controller": "owner",
            "destination": "library_top",
            "target_count": 1,
            "target_count_min": 1,
            "target_count_max": 1,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert expected["required_effect_fields"]["zone_move"] == "battlefield_to_library"
    assert expected["required_effect_fields"]["from_zone"] == "battlefield"
    assert scenario["type"] == "single_target_removal"
    assert scenario["expected_destination"] == "library_top"
    assert scenario["expected_target_constraints"] == {"card_types": ["creature"]}


def test_graveyard_to_library_draw_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "footbottom feast",
        "card_name": "Footbottom Feast",
        "oracle_hash": "hash-feast",
        "logical_rule_key": "battle_rule_v1:feast",
        "effect_json": {
            "effect": "recursion",
            "battle_model_scope": "xmage_put_graveyard_cards_on_library_then_draw_spell_v1",
            "target": "creature",
            "count": 99,
            "destination": "library_top",
            "draw_after_graveyard_to_library": True,
            "draw_after_graveyard_to_library_count": 1,
            "instant": True,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "graveyard_to_library_draw_spell"
    assert scenario["expected_drawn"] == "E2E High Value Creature"
    assert scenario["expected_library_top_after"] == "E2E Low Value Creature"
    assert scenario["expected_recovered_count"] == 2


def test_put_from_hand_to_battlefield_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "elvish piper",
        "card_name": "Elvish Piper",
        "oracle_hash": "hash-piper",
        "logical_rule_key": "battle_rule_v1:piper",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_put_hand_card_onto_battlefield_v1",
            "ability_kind": "static_and_activated",
            "activated_effect": "put_from_hand_onto_battlefield",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_put_hand_card_onto_battlefield_v1",
            "put_from_hand_target": "creature_card",
            "target": "creature_card",
            "destination": "battlefield",
            "count": 1,
            "optional": True,
            "activation_cost_mana": "{G}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["G"],
            "activation_requires_tap": True,
            "activation_requires_sacrifice": False,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert expected["required_effect_fields"]["put_from_hand_target"] == "creature_card"
    assert scenario["type"] == "simple_activated_put_from_hand_to_battlefield"
    assert scenario["expected_moved"] == "E2E High Value Creature"
    assert scenario["expected_target_type"] == "creature_card"
    assert scenario["controller_mana"]["green"] == 1
    assert scenario["expected_tapped_source"] is True


def test_static_filtered_protection_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "enemy of the guildpact",
        "card_name": "Enemy of the Guildpact",
        "oracle_hash": "hash-protection",
        "logical_rule_key": "battle_rule_v1:filtered-protection",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_static_self_protection_from_filtered_creature_v1",
            "static_effect": "self_protection_from_filtered",
            "protection_filter": "multicolored",
            "protection_from_color_profile": "multicolored",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert expected["required_effect_fields"]["protection_from_color_profile"] == "multicolored"
    assert scenario["type"] == "static_filtered_protection"
    assert scenario["matching_source"]["colors"] == ["R", "G"]
    assert scenario["nonmatching_source"]["colors"] == ["R"]


def test_static_subtype_protection_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "warren-scourge elf",
        "card_name": "Warren-Scourge Elf",
        "oracle_hash": "hash-protection-subtype",
        "logical_rule_key": "battle_rule_v1:subtype-protection",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_static_self_protection_from_subtypes_creature_v1",
            "static_effect": "self_protection_from_subtypes",
            "protection_from_subtypes": ["goblin"],
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert expected["required_effect_fields"]["protection_from_subtypes"] == ["goblin"]
    assert scenario["type"] == "static_subtype_protection"
    assert scenario["matching_source"]["type_line"] == "Creature - Goblin"
    assert scenario["nonmatching_source"]["type_line"] == "Creature - Elf"


def test_counter_unless_pays_draw_execution_scenario_uses_instant_fixture_for_instant_or_sorcery_target() -> None:
    proposal = {
        "normalized_name": "disrupt",
        "card_name": "Disrupt",
        "oracle_hash": "hash-disrupt",
        "logical_rule_key": "battle_rule_v1:disrupt",
        "effect_json": {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_unless_controller_pays_generic_draw_card_v1",
            "target": "instant_or_sorcery_spell",
            "target_constraints": {
                "zone": "stack",
                "stack_object": "spell",
                "spell_types": ["instant", "sorcery"],
            },
            "counter_unless_pays_generic": 1,
            "draw_on_counter": 1,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "counter_unless_pays_response"
    assert scenario["target_spell"]["type_line"] == "Instant"


def test_counter_target_stack_object_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "disallow",
        "card_name": "Disallow",
        "oracle_hash": "hash-disallow",
        "logical_rule_key": "battle_rule_v1:disallow",
        "effect_json": {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_v1",
            "target": "spell_or_activated_or_triggered_ability",
            "target_constraints": {
                "zone": "stack",
                "any_of": [
                    {"stack_object": "spell"},
                    {"stack_object": "activated_ability"},
                    {"stack_object": "triggered_ability"},
                ],
            },
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "counter_target_response"
    assert scenario["target_stack_object"]["type_line"] == "Instant"
    assert scenario["target_stack_effect"]["effect"] == "finisher"
    assert scenario["nonmatching_stack_object"]["type_line"] == "Mana Ability"
    assert scenario["nonmatching_stack_effect"]["effect"] == "mana_ability"


def test_counter_target_excluded_spell_subtype_execution_scenario_uses_illegal_subtype_fixture() -> None:
    proposal = {
        "normalized_name": "faerie trickery",
        "card_name": "Faerie Trickery",
        "oracle_hash": "hash-faerie-trickery",
        "logical_rule_key": "battle_rule_v1:faerie trickery",
        "effect_json": {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_v1",
            "target": "nonfaerie_spell",
            "target_constraints": {
                "zone": "stack",
                "stack_object": "spell",
                "exclude_spell_subtypes": ["faerie"],
            },
            "countered_spell_to_exile": True,
            "countered_spell_to_exile_reason": "counter_target_exile_replacement",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "counter_target_response"
    assert "Faerie" not in scenario["target_stack_object"]["type_line"]
    assert "Faerie" in scenario["nonmatching_stack_object"]["type_line"]
    assert scenario["card"]["countered_spell_to_exile"] is True
    assert scenario["expected_countered_spell_to_exile"] is True


def test_counter_target_top_library_execution_scenario_preserves_expected_destination() -> None:
    proposal = {
        "normalized_name": "memory lapse",
        "card_name": "Memory Lapse",
        "oracle_hash": "hash-memory-lapse",
        "logical_rule_key": "battle_rule_v1:memory-lapse",
        "effect_json": {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_v1",
            "target": "spell",
            "target_constraints": {"zone": "stack", "stack_object": "spell"},
            "countered_spell_to_top_library": True,
            "countered_spell_to_top_library_reason": "counter_target_top_library_replacement",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "counter_target_response"
    assert scenario["card"]["countered_spell_to_top_library"] is True
    assert scenario["expected_countered_spell_to_top_library"] is True
    assert scenario["expected_countered_spell_to_exile"] is False


def test_counter_target_x_mana_value_execution_scenario_uses_cast_context() -> None:
    proposal = {
        "normalized_name": "spell blast",
        "card_name": "Spell Blast",
        "oracle_hash": "hash-spell-blast",
        "logical_rule_key": "battle_rule_v1:spell-blast",
        "effect_json": {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_v1",
            "target": "spell_mana_value_x",
            "target_constraints": {
                "zone": "stack",
                "stack_object": "spell",
                "counter_target_mana_value_source": "x_value",
            },
            "counter_target_mana_value_source": "x_value",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "counter_target_response"
    assert scenario["card"]["mana_cost"] == "{X}{U}"
    assert scenario["card"]["_cast_context"] == {"x_value": 3}
    assert scenario["target_stack_object"]["cmc"] == 3
    assert scenario["nonmatching_stack_object"]["cmc"] == 4


def test_modal_counter_target_mana_value_execution_scenario_uses_any_of_option() -> None:
    proposal = {
        "normalized_name": "change the equation",
        "card_name": "Change the Equation",
        "oracle_hash": "hash-change-equation",
        "logical_rule_key": "battle_rule_v1:change-equation",
        "effect_json": {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_v1",
            "target": "spell_mana_value_2_or_less_or_red_green_spell_mana_value_6_or_less",
            "target_constraints": {
                "zone": "stack",
                "stack_object": "spell",
                "any_of": [
                    {"stack_object": "spell", "counter_target_mana_value_max": 2},
                    {
                        "stack_object": "spell",
                        "spell_colors": ["R", "G"],
                        "counter_target_mana_value_max": 6,
                    },
                ],
            },
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "counter_target_response"
    assert scenario["target_stack_object"]["cmc"] == 2
    assert scenario["nonmatching_stack_object"]["type_line"] == "Mana Ability"


def test_counter_draw_special_target_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "keep safe",
        "card_name": "Keep Safe",
        "oracle_hash": "hash-keep-safe",
        "logical_rule_key": "battle_rule_v1:keep-safe",
        "effect_json": {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_and_draw_card_spell_v1",
            "target": "spell_targeting_permanent_you_control",
            "target_constraints": {
                "zone": "stack",
                "stack_object": "spell",
                "spell_targets": "permanent_you_control",
            },
            "draw_on_counter": 1,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "counter_target_response"
    assert scenario["expected_cards_drawn"] == 1
    assert scenario["target_stack_effect"]["targets"][0]["target_controller"] == "Responder"
    assert scenario["nonmatching_stack_effect"]["targets"][0]["target_controller"] == "Active"


def test_counter_target_player_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "outwit",
        "card_name": "Outwit",
        "oracle_hash": "hash-outwit",
        "logical_rule_key": "battle_rule_v1:outwit",
        "effect_json": {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_v1",
            "target": "spell_targeting_player",
            "target_constraints": {
                "zone": "stack",
                "stack_object": "spell",
                "spell_targets": "player",
            },
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "counter_target_response"
    assert scenario["target_stack_effect"]["targets"][0]["target_type"] == "player"
    assert scenario["nonmatching_stack_effect"]["targets"][0]["target_type"] == "permanent"


def test_counter_second_spell_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "second guess",
        "card_name": "Second Guess",
        "oracle_hash": "hash-second-guess",
        "logical_rule_key": "battle_rule_v1:second-guess",
        "effect_json": {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_v1",
            "target": "spell_second_spell_this_turn",
            "target_constraints": {
                "zone": "stack",
                "stack_object": "spell",
                "spell_order_this_turn": 2,
            },
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "counter_target_response"
    assert scenario["target_stack_effect"]["spell_order_this_turn"] == 2
    assert scenario["nonmatching_stack_effect"]["spell_order_this_turn"] == 1


def test_counter_target_creature_power_or_toughness_fixture_is_manifested() -> None:
    proposal = {
        "normalized_name": "stern scolding",
        "card_name": "Stern Scolding",
        "oracle_hash": "hash-stern",
        "logical_rule_key": "battle_rule_v1:stern",
        "effect_json": {
            "effect": "counter",
            "battle_model_scope": "xmage_counter_target_spell_v1",
            "target": "creature_spell_power_or_toughness_2_or_less",
            "target_constraints": {
                "zone": "stack",
                "stack_object": "spell",
                "card_types": ["creature"],
                "power_or_toughness_max": 2,
            },
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "counter_target_response"
    assert scenario["target_stack_object"]["power"] == 2
    assert scenario["target_stack_object"]["toughness"] == 5
    assert scenario["nonmatching_stack_object"]["power"] == 4
    assert scenario["nonmatching_stack_object"]["toughness"] == 4


def test_static_cost_increase_colored_tax_fields_and_execution_scenario_are_manifested() -> None:
    proposal = {
        "normalized_name": "derelor",
        "card_name": "Derelor",
        "oracle_hash": "hash-derelor",
        "logical_rule_key": "battle_rule_v1:derelor",
        "effect_json": {
            "effect": "static_cost_increase",
            "battle_model_scope": "xmage_static_generic_cost_increase_for_matching_spells_v1",
            "static_effect": "generic_cost_increase_for_matching_spells",
            "cost_increase_applies_to": "spells_you_cast",
            "cost_increase_amount_source": "fixed",
            "cost_increase_generic": 0,
            "cost_increase_color_symbols": ["B"],
            "cost_increase_filters": [{"applies_to_spell_colors": ["B"]}],
            "permanent_type": "creature",
            "xmage_ability_class": "SimpleStaticAbility",
            "xmage_effect_class": "SpellsCostIncreasingAllEffect",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    required = expected["required_effect_fields"]
    assert required["cost_increase_color_symbols"] == ["B"]
    assert required["cost_increase_filters"] == [{"applies_to_spell_colors": ["B"]}]
    assert scenario["type"] == "static_cost_increase_spell_cost"
    assert scenario["target_spell"]["colors"] == ["B"]
    assert scenario["expected_colored"] == {"black": 2}
    assert scenario["expected_static_cost_increase_total"] == 1
    assert scenario["expected_static_cost_increase_color_symbols"] == ["B"]


def test_static_cost_reduction_colored_symbols_fields_and_execution_scenario_are_manifested() -> None:
    proposal = {
        "normalized_name": "edgewalker",
        "card_name": "Edgewalker",
        "oracle_hash": "hash-edgewalker",
        "logical_rule_key": "battle_rule_v1:edgewalker",
        "effect_json": {
            "effect": "static_cost_reduction",
            "battle_model_scope": "xmage_static_generic_cost_reduction_for_matching_spells_v1",
            "static_effect": "generic_cost_reduction_for_matching_spells",
            "cost_reduction_applies_to": "spells_you_cast",
            "cost_reduction_amount_source": "fixed",
            "cost_reduction_generic": 0,
            "cost_reduction_color_symbols": ["W", "B"],
            "cost_reduction_filters": [{"applies_to_subtypes": ["cleric"]}],
            "applies_to_subtypes": ["cleric"],
            "permanent_type": "creature",
            "xmage_ability_class": "SimpleStaticAbility",
            "xmage_effect_class": "SpellsCostReductionControllerEffect",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    required = expected["required_effect_fields"]
    assert required["cost_reduction_color_symbols"] == ["W", "B"]
    assert required["cost_reduction_filters"] == [{"applies_to_subtypes": ["cleric"]}]
    assert scenario["type"] == "static_cost_reduction_spell_cost"
    assert scenario["target_spell"]["type_line"] == "Creature - Cleric"
    assert scenario["target_spell"]["mana_cost"] == "{1}{W}{B}"
    assert scenario["expected_generic"] == 1
    assert scenario["expected_colored"] == {"white": 0, "black": 0}
    assert scenario["expected_static_cost_reduction_total"] == 2
    assert scenario["expected_static_cost_reduction_color_symbols"] == ["W", "B"]


def test_static_graveyard_threshold_distinct_card_types_fields_and_execution_scenario_are_manifested() -> None:
    proposal = {
        "normalized_name": "gnarlwood dryad",
        "card_name": "Gnarlwood Dryad",
        "oracle_hash": "hash-gnarlwood-dryad",
        "logical_rule_key": "battle_rule_v1:gnarlwood-dryad",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_static_source_boost_if_graveyard_threshold_v1",
            "static_effect": "source_power_toughness_boost_if_graveyard_count",
            "graveyard_count_scope": "controller_graveyard",
            "graveyard_count_card_types": ["card_type"],
            "graveyard_count_mode": "distinct_card_types",
            "graveyard_count_threshold": 4,
            "static_power_bonus": 2,
            "static_toughness_bonus": 2,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    required = expected["required_effect_fields"]
    assert required["graveyard_count_mode"] == "distinct_card_types"
    assert required["graveyard_count_card_types"] == ["card_type"]
    assert scenario["type"] == "static_graveyard_threshold_source_boost"
    assert scenario["expected_count"] == 4
    assert scenario["expected_power"] == 3
    assert scenario["expected_toughness"] == 3
    assert {card["type_line"] for card in scenario["controller_graveyard"]} == {
        "Creature",
        "Enchantment",
        "Instant",
        "Land",
    }


def test_creature_etb_draw_discard_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "bazaar trademage",
        "card_name": "Bazaar Trademage",
        "oracle_hash": "hash-bazaar-trademage",
        "logical_rule_key": "battle_rule_v1:bazaar-trademage",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_draw_discard_cards_v1",
            "etb_draw_discard": True,
            "etb_draw_count": 2,
            "etb_discard_count": 3,
            "draw_count": 2,
            "discard_count": 3,
            "draw_discard_order": "draw_then_discard",
            "keywords": ["flying"],
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "creature_etb_draw_discard"
    assert scenario["expected_draw_count"] == 2
    assert scenario["expected_discard_count"] == 3
    assert scenario["expected_hand_after"] == 2
    assert scenario["expected_graveyard_after"] == 3
    assert scenario["expected_keywords"] == ["flying"]


def test_creature_etb_conditional_draw_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "scholar of stars",
        "card_name": "Scholar of Stars",
        "oracle_hash": "hash-scholar-of-stars",
        "logical_rule_key": "battle_rule_v1:scholar-of-stars",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_draw_cards_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "trigger_effect": "draw_cards",
            "etb_draw_count": 1,
            "etb_draw_condition_status": "runtime_executor_v1",
            "etb_draw_condition": "controller_controls_matching_permanent",
            "etb_draw_condition_min_count": 1,
            "etb_draw_condition_card_types": ["artifact"],
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert required["etb_draw_condition_status"] == "runtime_executor_v1"
    assert required["etb_draw_condition"] == "controller_controls_matching_permanent"
    assert required["etb_draw_condition_card_types"] == ["artifact"]
    assert scenario["type"] == "creature_etb_draw"
    assert scenario["expected_draw_count"] == 1
    assert scenario["expected_condition"] == "controller_controls_matching_permanent"
    assert scenario["controller_battlefield"][0]["type_line"] == "Artifact"


def test_creature_etb_dynamic_draw_execution_scenario_counts_turn_deaths() -> None:
    proposal = {
        "normalized_name": "lilianas standard bearer",
        "card_name": "Liliana's Standard Bearer",
        "oracle_hash": "hash-lilianas-standard-bearer",
        "logical_rule_key": "battle_rule_v1:lilianas-standard-bearer",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_dynamic_draw_cards_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "trigger_effect": "dynamic_draw_cards",
            "etb_dynamic_draw": True,
            "etb_draw_count_source": "creatures_you_control_died_this_turn",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert required["etb_dynamic_draw"] is True
    assert required["etb_draw_count_source"] == "creatures_you_control_died_this_turn"
    assert scenario["type"] == "creature_etb_draw"
    assert scenario["expected_draw_count"] == 3
    assert scenario["creatures_you_control_died_this_turn_count"] == 3
    assert len(scenario["controller_library"]) == 3


def test_creature_etb_each_player_sacrifice_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "fleshbag marauder",
        "card_name": "Fleshbag Marauder",
        "oracle_hash": "hash-fleshbag-marauder",
        "logical_rule_key": "battle_rule_v1:fleshbag-marauder",
        "effect_json": {
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
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert expected["required_effect_fields"]["etb_each_player_sacrifice"] is True
    assert scenario["type"] == "each_player_sacrifice"
    assert scenario["card"]["type_line"] == "Creature"
    assert scenario["sacrifice_count"] == 1
    assert scenario["sacrifice_card_types"] == ["creature"]


def test_creature_dies_each_player_sacrifice_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "akki blizzard-herder",
        "card_name": "Akki Blizzard-Herder",
        "oracle_hash": "hash-akki-blizzard-herder",
        "logical_rule_key": "battle_rule_v1:akki-blizzard-herder",
        "effect_json": {
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
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert expected["required_effect_fields"]["dies_each_player_sacrifice"] is True
    assert scenario["type"] == "creature_dies_each_player_sacrifice"
    assert scenario["card"]["type_line"] == "Creature"
    assert scenario["sacrifice_count"] == 1
    assert scenario["sacrifice_card_types"] == ["land"]


def test_creature_etb_target_stat_modifier_execution_scenario_is_manifested() -> None:
    proposal = {
        "normalized_name": "blister beetle",
        "card_name": "Blister Beetle",
        "oracle_hash": "hash-blister-beetle",
        "logical_rule_key": "battle_rule_v1:blister-beetle",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_fixed_boost_target_until_eot_v1",
            "etb_target_stat_modifier": True,
            "target": "creature",
            "target_controller": "any",
            "power_delta": -1,
            "toughness_delta": -1,
            "power_boost": -1,
            "toughness_boost": -1,
            "duration": "until_end_of_turn",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert expected["required_effect_fields"]["etb_target_stat_modifier"] is True
    assert scenario["type"] == "creature_etb_target_stat_modifier"
    assert scenario["expected_power_delta"] == -1
    assert scenario["expected_toughness_delta"] == -1


def test_manifest_expected_rule_from_proposal_contains_e2e_fields() -> None:
    proposal = {
        "normalized_name": "verge rangers",
        "card_name": "Verge Rangers",
        "oracle_hash": "hash123",
        "logical_rule_key": "battle_rule_v1:abc",
        "effect_json": {
            "effect": "topdeck_play",
            "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
            "target": "land",
            "target_graveyard_controller": "opponent",
            "battlefield_controller": "self",
            "count": 1,
            "count_from_x": True,
            "target_count_from_x": True,
            "destination": "play",
            "enters_tapped": True,
            "exiles_self": False,
            "mode_selection": "one_or_both",
            "recursion_mana_value_max": 3,
            "recursion_mana_value_max_from_x": True,
            "target_mana_value_max_from_x": True,
            "pre_recursion_mill_count": 3,
            "etb_draw_count": 2,
            "etb_life_loss": 2,
            "etb_life_gain_amount": 3,
            "etb_damage_amount": 4,
            "etb_damage_target": "creature",
            "etb_remove_effect": "remove_permanent",
            "etb_remove_target": "artifact",
            "etb_token_count": 2,
            "etb_token_name": "Zombie",
            "etb_token_power": 2,
            "etb_token_toughness": 2,
            "etb_add_counters_target": "creature",
            "etb_add_counters_count": 1,
            "etb_add_counters_counter_type": "+1/+1",
            "etb_recursion_target": "artifact",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "hand",
            "etb_recursion_up_to_count": False,
            "etb_recursion_mana_value_max": 1,
            "etb_recursion_mill_count": 2,
            "etb_tutor_target": "basic_land_to_battlefield",
            "etb_tutor_count": 1,
            "tutor_enters_tapped": True,
            "dies_recursion_target": "artifact",
            "dies_recursion_count": 1,
            "dies_recursion_destination": "hand",
            "dies_recursion_exclude_self": True,
            "dies_damage_amount": 2,
            "dies_damage_target": "any_target",
            "dies_damage_optional": True,
            "graveyard_exile_target": "any_card",
            "graveyard_exile_target_count": 3,
            "graveyard_exile_destination": "exile",
            "graveyard_exile_up_to_count": True,
            "graveyard_exile_single_graveyard": True,
            "graveyard_to_library_target": "creature",
            "graveyard_to_library_target_count": 1,
            "graveyard_to_library_destination": "library_top",
            "graveyard_to_library_up_to_count": False,
            "graveyard_to_library_activation_cost_mana": "{B}",
            "graveyard_to_library_activation_cost_generic": 0,
            "graveyard_to_library_activation_cost_colors": ["B"],
            "exile_if_dies_from_damage": True,
            "exile_if_dies_target": "creature",
            "keywords": ["haste"],
            "_keywords_are_self": True,
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WBG",
            "produced_mana_symbols": ["W", "B", "G"],
            "mana_activation_requires_tap": True,
            "activation_mana_cost": "{0}",
            "cost_reduction_applies_to": "this_spell",
            "cost_reduction_amount_source": "fixed",
            "cost_reduction_generic": 3,
            "cost_reduction_condition": "opponent_graveyard_cards_at_least",
            "cost_reduction_opponent_graveyard_cards_min": 7,
            "ability_kind": "static_and_activated",
            "activated_effect": "direct_damage",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_add_counters": True,
            "activated_add_counters_target": "self",
            "activated_add_counters_counter_type": "+1/+1",
            "activated_add_counters_count": 1,
            "spell_cast_add_counters": True,
            "spell_cast_add_counters_target": "self",
            "spell_cast_add_counters_count": 1,
            "spell_cast_add_counters_counter_type": "+1/+1",
            "spell_cast_add_counters_card_types": ["instant", "sorcery"],
            "spell_cast_add_counters_required_colors": ["W", "U"],
            "spell_cast_add_counters_requires_multicolored": False,
            "spell_cast_add_counters_mana_value_min": 2,
            "activated_damage_amount": 1,
            "counter_type": "+1/+1",
            "counter_count": 1,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "activation_requires_sacrifice": False,
            "_activated_rule_effects": [
                {
                    "effect": "direct_damage",
                    "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
                    "amount": 1,
                    "damage": 1,
                    "target": "any_target",
                }
            ],
            "xmage_ability_class": "SimpleActivatedAbility",
            "xmage_ability_classes": ["HasteAbility", "SimpleActivatedAbility"],
            "xmage_effect_class": "DamageTargetEffect",
            "recursion_components": [
                {
                    "target": "creature",
                    "count": 1,
                    "destination": "hand",
                    "target_controller": "self",
                }
            ],
        },
        "review_status": "verified",
        "execution_status": "auto",
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["normalized_name"] == "verge rangers"
    assert expected["logical_rule_key"] == "battle_rule_v1:abc"
    assert expected["oracle_hash"] == "hash123"
    assert expected["min_rule_version"] == 2
    assert expected["required_effect_fields"] == {
            "effect": "topdeck_play",
            "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
            "target": "land",
            "target_graveyard_controller": "opponent",
            "battlefield_controller": "self",
            "count": 1,
            "count_from_x": True,
            "target_count_from_x": True,
            "destination": "play",
            "enters_tapped": True,
            "exiles_self": False,
            "mode_selection": "one_or_both",
            "recursion_mana_value_max": 3,
            "recursion_mana_value_max_from_x": True,
            "target_mana_value_max_from_x": True,
            "pre_recursion_mill_count": 3,
            "etb_draw_count": 2,
            "etb_life_loss": 2,
            "etb_life_gain_amount": 3,
            "etb_damage_amount": 4,
            "etb_damage_target": "creature",
            "etb_remove_effect": "remove_permanent",
            "etb_remove_target": "artifact",
            "etb_token_count": 2,
            "etb_token_name": "Zombie",
            "etb_token_power": 2,
            "etb_token_toughness": 2,
            "etb_add_counters_target": "creature",
            "etb_add_counters_count": 1,
            "etb_add_counters_counter_type": "+1/+1",
            "etb_recursion_target": "artifact",
            "etb_recursion_count": 1,
            "etb_recursion_destination": "hand",
            "etb_recursion_up_to_count": False,
            "etb_recursion_mana_value_max": 1,
            "etb_recursion_mill_count": 2,
            "etb_tutor_target": "basic_land_to_battlefield",
            "etb_tutor_count": 1,
            "tutor_enters_tapped": True,
            "dies_recursion_target": "artifact",
            "dies_recursion_count": 1,
            "dies_recursion_destination": "hand",
            "dies_recursion_exclude_self": True,
            "dies_damage_amount": 2,
            "dies_damage_target": "any_target",
            "dies_damage_optional": True,
            "graveyard_exile_target": "any_card",
            "graveyard_exile_target_count": 3,
            "graveyard_exile_destination": "exile",
            "graveyard_exile_up_to_count": True,
            "graveyard_exile_single_graveyard": True,
            "graveyard_to_library_target": "creature",
            "graveyard_to_library_target_count": 1,
            "graveyard_to_library_destination": "library_top",
            "graveyard_to_library_up_to_count": False,
            "graveyard_to_library_activation_cost_mana": "{B}",
            "graveyard_to_library_activation_cost_generic": 0,
            "graveyard_to_library_activation_cost_colors": ["B"],
            "exile_if_dies_from_damage": True,
            "exile_if_dies_target": "creature",
            "keywords": ["haste"],
            "_keywords_are_self": True,
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WBG",
            "produced_mana_symbols": ["W", "B", "G"],
            "mana_activation_requires_tap": True,
            "activation_mana_cost": "{0}",
            "cost_reduction_applies_to": "this_spell",
            "cost_reduction_amount_source": "fixed",
            "cost_reduction_generic": 3,
            "cost_reduction_condition": "opponent_graveyard_cards_at_least",
            "cost_reduction_opponent_graveyard_cards_min": 7,
            "ability_kind": "static_and_activated",
            "activated_effect": "direct_damage",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_add_counters": True,
            "activated_add_counters_target": "self",
            "activated_add_counters_counter_type": "+1/+1",
            "activated_add_counters_count": 1,
            "spell_cast_add_counters": True,
            "spell_cast_add_counters_target": "self",
            "spell_cast_add_counters_count": 1,
            "spell_cast_add_counters_counter_type": "+1/+1",
            "spell_cast_add_counters_card_types": ["instant", "sorcery"],
            "spell_cast_add_counters_required_colors": ["W", "U"],
            "spell_cast_add_counters_requires_multicolored": False,
            "spell_cast_add_counters_mana_value_min": 2,
            "activated_damage_amount": 1,
            "counter_type": "+1/+1",
            "counter_count": 1,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "activation_requires_sacrifice": False,
            "_activated_rule_effects": [
                {
                    "effect": "direct_damage",
                    "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
                    "amount": 1,
                    "damage": 1,
                    "target": "any_target",
                }
            ],
            "xmage_ability_class": "SimpleActivatedAbility",
            "xmage_ability_classes": ["HasteAbility", "SimpleActivatedAbility"],
            "xmage_effect_class": "DamageTargetEffect",
            "recursion_components": [
                {
                    "target": "creature",
                "count": 1,
                "destination": "hand",
                "target_controller": "self",
            }
        ],
    }


def test_manifest_expected_rule_preserves_target_player_draw_fields() -> None:
    proposal = {
        "normalized_name": "inspiration",
        "card_name": "Inspiration",
        "oracle_hash": "hash-target-draw",
        "logical_rule_key": "battle_rule_v1:hash-target-draw",
        "effect_json": {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_target_player_draw_spell_v1",
            "target": "player",
            "target_controller": "target_player",
            "target_preference": "self",
            "target_constraints": {"players": ["any"]},
            "count": 2,
            "draw_count": 2,
            "target_player_draw": True,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "draw_cards",
        "battle_model_scope": "xmage_fixed_target_player_draw_spell_v1",
        "target": "player",
        "target_controller": "target_player",
        "target_constraints": {"players": ["any"]},
        "target_preference": "self",
        "count": 2,
        "draw_count": 2,
        "target_player_draw": True,
    }


def test_manifest_builds_fixed_draw_additional_cost_scenario() -> None:
    rule = {
        "normalized_name": "merciless resolve",
        "card_name": "Merciless Resolve",
        "oracle_hash": "hash-merciless-resolve",
        "logical_rule_key": "battle_rule_v1:hash-merciless-resolve",
        "required_effect_fields": {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
            "count": 2,
            "draw_count": 2,
            "instant": True,
            "additional_cost": "sacrifice_creature_or_land",
            "requires_sacrifice_creature_or_land": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "fixed_draw_spell"
    assert scenario["expected_draw_count"] == 2
    assert scenario["expected_additional_cost"] == "sacrifice_creature_or_land"
    assert scenario["expected_sacrificed_names"] == ["E2E Sacrifice Cost Creature"]
    assert scenario["controller_battlefield"][0]["type_line"] == "Creature - Soldier"


def test_manifest_builds_fixed_draw_discard_random_scenario() -> None:
    rule = {
        "normalized_name": "goblin lore",
        "card_name": "Goblin Lore",
        "oracle_hash": "hash-goblin-lore",
        "logical_rule_key": "battle_rule_v1:hash-goblin-lore",
        "required_effect_fields": {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_draw_discard_spell_v1",
            "count": 4,
            "draw_count": 4,
            "discard_count": 3,
            "discard_random": True,
            "draw_discard_order": "draw_then_discard",
            "sorcery": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "fixed_draw_discard_spell"
    assert scenario["expected_draw_count"] == 4
    assert scenario["expected_discard_count"] == 3
    assert scenario["expected_discard_random"] is True
    assert scenario["expected_draw_discard_order"] == "draw_then_discard"
    assert len(scenario["controller_library"]) == 4
    assert len(scenario["controller_hand"]) == 3


def test_manifest_builds_beginning_end_step_draw_execution_scenario() -> None:
    rule = {
        "normalized_name": "the gaffer",
        "card_name": "The Gaffer",
        "oracle_hash": "hash-the-gaffer",
        "logical_rule_key": "battle_rule_v1:hash-the-gaffer",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_beginning_end_step_conditional_draw_v1",
            "trigger": "each_end_step",
            "trigger_effect": "draw_cards",
            "end_step_draw_count": 1,
            "end_step_draw_optional": False,
            "end_step_draw_condition_status": "runtime_executor_v1",
            "end_step_draw_condition": "controller_gained_life_gte",
            "end_step_draw_condition_threshold": 3,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "beginning_end_step_draw"
    assert scenario["expected_trigger"] == "each_end_step"
    assert scenario["expected_draw_count"] == 1
    assert scenario["expected_condition"] == "controller_gained_life_gte"
    assert scenario["expected_threshold"] == 3
    assert scenario["card"]["type_line"] == "Creature - E2E Fixture"


def test_manifest_builds_fixed_draw_discard_unless_scenario() -> None:
    rule = {
        "normalized_name": "thirst for knowledge",
        "card_name": "Thirst for Knowledge",
        "oracle_hash": "hash-thirst-for-knowledge",
        "logical_rule_key": "battle_rule_v1:hash-thirst-for-knowledge",
        "required_effect_fields": {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_draw_discard_spell_v1",
            "count": 3,
            "draw_count": 3,
            "discard_count": 2,
            "discard_random": False,
            "discard_unless_status": "runtime_executor_v1",
            "discard_unless_filter": "artifact_card",
            "discard_unless_count": 1,
            "discard_unless_card_types": ["artifact"],
            "draw_discard_order": "draw_then_discard",
            "instant": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "fixed_draw_discard_spell"
    assert scenario["expected_draw_count"] == 3
    assert scenario["expected_discard_count"] == 1
    assert scenario["expected_discard_random"] is False
    assert scenario["expected_draw_discard_order"] == "draw_then_discard"
    assert scenario["controller_hand"][0]["name"] == "E2E Draw Discard Artifact Card"
    assert scenario["controller_hand"][0]["type_line"] == "Artifact"


def test_manifest_expected_rule_preserves_damage_prevention_fields() -> None:
    proposal = {
        "normalized_name": "vine snare",
        "card_name": "Vine Snare",
        "oracle_hash": "hash-vine-snare",
        "logical_rule_key": "battle_rule_v1:hash-vine-snare",
        "effect_json": {
            "effect": "damage_prevention_shield",
            "battle_model_scope": "xmage_prevent_damage_from_creatures_spell_v1",
            "prevent_damage_from_creature_sources_this_turn": True,
            "prevent_damage_scope": "combat_damage_from_creatures",
            "prevent_damage_kind": "combat_damage",
            "prevent_damage_duration": "until_end_of_turn",
            "prevent_damage_amount": 999,
            "prevent_source_constraints": {
                "card_types": ["creature"],
                "power_lte": 4,
            },
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == proposal["effect_json"]


def test_manifest_expected_rule_preserves_partial_mana_source_fields() -> None:
    proposal = {
        "normalized_name": "cultivator's caravan",
        "card_name": "Cultivator's Caravan",
        "oracle_hash": "hash-caravan",
        "logical_rule_key": "battle_rule_v1:hash-caravan",
        "effect_json": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": True,
            "modeled_ability_subset": "mana_source_only",
            "_runtime_partial": True,
            "_runtime_partial_reason": "Only mana source is modeled.",
            "xmage_mana_ability_classes": ["AnyColorManaAbility"],
            "xmage_auxiliary_ability_classes": ["CrewAbility"],
            "xmage_unmodeled_auxiliary_ability_classes": ["CrewAbility"],
            "xmage_unmodeled_effect_classes": [],
            "xmage_effect_classes": [],
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["modeled_ability_subset"] == "mana_source_only"
    assert required["_runtime_partial"] is True
    assert required["xmage_mana_ability_classes"] == ["AnyColorManaAbility"]
    assert required["xmage_unmodeled_auxiliary_ability_classes"] == ["CrewAbility"]


def test_simple_mana_source_execution_scenario_pays_activation_cost() -> None:
    rule = {
        "card_name": "Ceta Disciple",
        "logical_rule_key": "battle_rule_v1:ceta",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": True,
            "activation_mana_cost": "{G}",
        },
    }

    scenario = builder.simple_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["controller_mana"] == {
        "generic": 0,
        "white": 0,
        "blue": 0,
        "black": 0,
        "red": 0,
        "green": 1,
    }
    assert scenario["support_mana_sources"] == [
        {
            "name": "E2E Green Support Source 1",
            "type_line": "Artifact",
            "effect": "ramp_permanent",
            "battle_model_scope": "e2e_support_mana_source_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "G",
            "produced_mana_symbols": ["G"],
            "mana_activation_requires_tap": True,
        }
    ]
    assert scenario["expected_available_mana_after_refresh"] == 1
    assert scenario["expected_conditional_mana"] == 1
    assert scenario["expected_sources"] == 2


def test_simple_mana_source_execution_scenario_seeds_tap_support_cost() -> None:
    rule = {
        "card_name": "Citanul Stalwart",
        "logical_rule_key": "battle_rule_v1:citanul-stalwart",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": True,
            "mana_source_requires_untapped_artifact_or_creature": True,
            "mana_activation_tap_support_count": 1,
            "mana_activation_tap_support_type": "artifact_or_creature",
            "mana_source_support_can_include_source": False,
        },
    }

    scenario = builder.simple_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["controller_battlefield"] == [
        {
            "name": "E2E Untapped Support Artifact 1",
            "type_line": "Artifact",
            "tapped": False,
        }
    ]
    assert scenario["expected_support_tapped_count"] == 1
    assert scenario["expected_support_tapped_names"] == ["E2E Untapped Support Artifact 1"]
    assert scenario["expected_sources"] == 1
    assert scenario["expected_conditional_mana"] == 1


def test_simple_mana_source_execution_scenario_pays_life_cost() -> None:
    rule = {
        "card_name": "Phyrexian Lens",
        "logical_rule_key": "battle_rule_v1:phyrexian_lens",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": True,
            "activation_life_cost": 1,
        },
    }

    scenario = builder.simple_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["starting_life"] == 40
    assert scenario["expected_life_paid"] == 1
    assert scenario["expected_life_after_refresh"] == 39
    assert scenario["expected_conditional_mana"] == 1


def test_simple_mana_source_execution_scenario_pays_discard_cost() -> None:
    rule = {
        "card_name": "Skirge Familiar",
        "logical_rule_key": "battle_rule_v1:skirge_familiar",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "B",
            "produced_mana_symbols": ["B"],
            "mana_activation_requires_tap": False,
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
        },
    }

    scenario = builder.simple_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["controller_hand"] == [
        {
            "name": "E2E Spare Discard Card 1",
            "type_line": "Sorcery",
            "effect": "draw_cards",
            "cmc": 2,
        }
    ]
    assert scenario["expected_discard_count"] == 1
    assert scenario["expected_discard_target"] == "any_card"
    assert scenario["expected_available_mana_after_refresh"] == 1
    assert scenario["expected_sources"] == 1


def test_simple_mana_source_execution_scenario_preserves_activation_limit() -> None:
    rule = {
        "card_name": "Abzan Devotee",
        "logical_rule_key": "battle_rule_v1:abzan",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WBG",
            "mana_activation_requires_tap": False,
            "activation_mana_cost": "{1}",
            "activation_limit_per_turn": 1,
        },
    }

    scenario = builder.simple_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["expected_activation_limit_per_turn"] == 1
    assert scenario["expected_conditional_mana"] == 1
    assert scenario["expected_sources"] == 2


def test_simple_mana_source_execution_scenario_preserves_enters_tapped_state() -> None:
    rule = {
        "card_name": "Arc Reactor",
        "logical_rule_key": "battle_rule_v1:arc",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 3,
            "produces": "C",
            "produced_mana_symbols": ["C", "C", "C"],
            "mana_activation_requires_tap": True,
            "enters_tapped": True,
        },
    }

    scenario = builder.simple_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["expected_available_mana_after_refresh"] == 0
    assert scenario["expected_sources"] == 0
    assert scenario["expected_tapped"] is True
    assert scenario["source_overrides"] == {"tapped": True}


def test_simple_mana_source_execution_scenario_tracks_two_color_choices_as_conditional() -> None:
    rule = {
        "card_name": "Atarka Monument",
        "logical_rule_key": "battle_rule_v1:atarka",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "RG",
            "mana_activation_requires_tap": True,
        },
    }

    scenario = builder.simple_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["expected_available_mana_after_refresh"] == 1
    assert scenario["expected_conditional_mana"] == 1
    assert scenario["expected_sources"] == 1
    assert scenario["expected_tapped"] is True


def test_self_sacrifice_mana_source_execution_scenario_unlocks_spell() -> None:
    rule = {
        "card_name": "Chromatic Sphere",
        "logical_rule_key": "battle_rule_v1:chromatic",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_self_sacrifice_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_source_contextual_only": True,
            "mana_activation_requires_sacrifice": True,
            "activation_requires_sacrifice": True,
            "mana_produced": 1,
            "produces": "WUBRG",
            "activation_mana_cost": "{1}",
            "mana_activation_requires_tap": True,
            "activation_requires_tap": True,
        },
    }

    scenario = builder.sacrifice_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "sacrifice_mana_source_activation"
    assert scenario["expected_event"] == "self_sacrifice_mana_source_activated"
    assert scenario["controller_mana"]["generic"] == 1
    assert scenario["unlock_card"]["mana_cost"] == "{G}"
    assert scenario["expected_available_mana_after_activation"] == 1
    assert scenario["expected_conditional_mana"] == 1
    assert scenario["expect_source_sacrificed"] is True
    assert scenario["expect_target_sacrificed"] is False


def test_target_sacrifice_mana_source_execution_scenario_seeds_target() -> None:
    rule = {
        "card_name": "Phyrexian Altar",
        "logical_rule_key": "battle_rule_v1:altar",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_target_sacrifice_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_source_contextual_only": True,
            "mana_activation_requires_sacrifice_target": True,
            "activation_requires_sacrifice_target": True,
            "activation_sacrifice_target": "creature",
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": False,
            "activation_requires_tap": False,
        },
    }

    scenario = builder.sacrifice_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "sacrifice_mana_source_activation"
    assert scenario["expected_event"] == "target_sacrifice_mana_source_activated"
    assert scenario["sacrifice_target"]["type_line"] == "Creature - Fixture"
    assert scenario["unlock_card"]["mana_cost"] == "{G}"
    assert scenario["expected_conditional_mana"] == 1
    assert scenario["expect_source_sacrificed"] is False
    assert scenario["expect_target_sacrificed"] is True


def test_target_sacrifice_mana_source_execution_scenario_uses_manifest_aliases() -> None:
    rule = {
        "card_name": "Phyrexian Altar",
        "logical_rule_key": "battle_rule_v1:altar",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_target_sacrifice_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_source_contextual_only": True,
            "activation_requires_sacrifice_target": True,
            "activation_sacrifice_target": "creature",
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": False,
            "activation_requires_tap": False,
        },
    }

    scenario = builder.sacrifice_mana_source_execution_scenario_from_expected_rule(rule)

    assert scenario["expected_event"] == "target_sacrifice_mana_source_activated"
    assert scenario["expect_source_sacrificed"] is False
    assert scenario["expect_target_sacrificed"] is True
    assert scenario["sacrifice_target"]["type_line"] == "Creature - Fixture"


def test_manifest_expected_rule_preserves_library_bottom_pick_fields() -> None:
    proposal = {
        "normalized_name": "shimmer of possibility",
        "card_name": "Shimmer of Possibility",
        "oracle_hash": "hash-shimmer",
        "logical_rule_key": "battle_rule_v1:hash-shimmer",
        "effect_json": {
            "effect": "dig_to_hand",
            "battle_model_scope": "xmage_look_library_pick_to_hand_rest_bottom_spell_v1",
            "look_count": 4,
            "pick_count": 1,
            "count": 1,
            "pick_target": "any_card",
            "target": "any_card",
            "destination": "hand",
            "rest_destination": "library_bottom",
            "library_bottom_order": "random",
            "pick_up_to_count": False,
            "pick_all_matching": False,
            "reveal": False,
            "xmage_effect_class": "LookLibraryAndPickControllerEffect",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["effect"] == "dig_to_hand"
    assert required["battle_model_scope"] == "xmage_look_library_pick_to_hand_rest_bottom_spell_v1"
    assert required["look_count"] == 4
    assert required["pick_count"] == 1
    assert required["rest_destination"] == "library_bottom"
    assert required["library_bottom_order"] == "random"
    assert required["xmage_effect_class"] == "LookLibraryAndPickControllerEffect"


def test_manifest_expected_rule_preserves_combat_damage_draw_fields() -> None:
    proposal = {
        "normalized_name": "scroll thief",
        "card_name": "Scroll Thief",
        "oracle_hash": "hash-scroll-thief",
        "logical_rule_key": "battle_rule_v1:hash-scroll-thief",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_combat_damage_draw_cards_v1",
            "ability_kind": "triggered",
            "trigger": "combat_damage_to_player",
            "trigger_effect": "draw_cards",
            "combat_damage_player_draw": True,
            "combat_damage_draw_count": 1,
            "combat_damage_draw_optional": True,
            "combat_damage_draw_optional_cost": "discard_card",
            "combat_damage_draw_optional_cost_count": 1,
            "draw_count": 1,
            "xmage_effect_class": "DrawCardSourceControllerEffect",
            "xmage_ability_class": "DealsCombatDamageToAPlayerTriggeredAbility",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["effect"] == "creature"
    assert required["battle_model_scope"] == "xmage_creature_combat_damage_draw_cards_v1"
    assert required["trigger"] == "combat_damage_to_player"
    assert required["trigger_effect"] == "draw_cards"
    assert required["combat_damage_player_draw"] is True
    assert required["combat_damage_draw_count"] == 1
    assert required["combat_damage_draw_optional"] is True
    assert required["combat_damage_draw_optional_cost"] == "discard_card"
    assert required["combat_damage_draw_optional_cost_count"] == 1
    assert required["draw_count"] == 1
    assert required["xmage_effect_class"] == "DrawCardSourceControllerEffect"
    assert required["xmage_ability_class"] == "DealsCombatDamageToAPlayerTriggeredAbility"


def test_manifest_expected_rule_preserves_etb_optional_and_dynamic_draw_fields() -> None:
    proposal = {
        "normalized_name": "fissure wizard",
        "card_name": "Fissure Wizard",
        "oracle_hash": "hash-fissure-wizard",
        "logical_rule_key": "battle_rule_v1:hash-fissure-wizard",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_optional_discard_draw_cards_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "trigger_effect": "optional_discard_draw",
            "etb_optional_discard_draw": True,
            "etb_optional_discard_count": 1,
            "etb_optional_discard_draw_count": 1,
            "draw_count": 1,
            "xmage_effect_class": "DrawCardSourceControllerEffect",
            "xmage_ability_class": "EntersBattlefieldTriggeredAbility",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["etb_optional_discard_draw"] is True
    assert required["etb_optional_discard_count"] == 1
    assert required["etb_optional_discard_draw_count"] == 1
    assert required["draw_count"] == 1

    proposal["effect_json"] = {
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
        "xmage_effect_class": "DrawDiscardControllerEffect",
        "xmage_ability_class": "EntersBattlefieldTriggeredAbility",
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]
    assert required["battle_model_scope"] == "xmage_creature_etb_draw_discard_cards_v1"
    assert required["etb_draw_discard"] is True
    assert required["etb_draw_count"] == 2
    assert required["etb_discard_count"] == 1
    assert required["draw_count"] == 2
    assert required["discard_count"] == 1
    assert required["draw_discard_order"] == "draw_then_discard"

    proposal["effect_json"] = {
        "effect": "creature",
        "battle_model_scope": "xmage_creature_etb_dynamic_draw_cards_v1",
        "ability_kind": "triggered",
        "trigger": "enters_battlefield",
        "trigger_effect": "dynamic_draw_cards",
        "etb_dynamic_draw": True,
        "draw_count_source": "controlled_creatures_with_color",
        "etb_draw_count_source": "controlled_creatures_with_color",
        "draw_count_color": "green",
        "etb_draw_count_color": "green",
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]
    assert required["etb_dynamic_draw"] is True
    assert required["draw_count_source"] == "controlled_creatures_with_color"
    assert required["etb_draw_count_source"] == "controlled_creatures_with_color"
    assert required["draw_count_color"] == "green"
    assert required["etb_draw_count_color"] == "green"


def test_manifest_expected_rule_preserves_activation_discard_cost_fields() -> None:
    proposal = {
        "normalized_name": "goblin picker",
        "card_name": "Goblin Picker",
        "oracle_hash": "hash-activated-discard-draw",
        "logical_rule_key": "battle_rule_v1:hash-activated-discard-draw",
        "effect_json": {
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_v1",
            "activated_draw": True,
            "activated_draw_count": 1,
            "activation_cost_mana": "{R}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["R"],
            "activation_requires_tap": True,
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
            "activation_requires_discard_card": True,
            "activation_discard_random": True,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"]["activation_discard_count"] == 1
    assert expected["required_effect_fields"]["activation_discard_target"] == "any_card"
    assert expected["required_effect_fields"]["activation_requires_discard_card"] is True
    assert expected["required_effect_fields"]["activation_discard_random"] is True


def test_manifest_builds_simple_activated_draw_execution_scenario_with_sacrifice_target() -> None:
    rule = {
        "normalized_name": "thraxodemon",
        "card_name": "Thraxodemon",
        "oracle_hash": "hash-thraxodemon",
        "logical_rule_key": "battle_rule_v1:thraxodemon",
        "required_effect_fields": {
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_v1",
            "activated_draw": True,
            "activated_draw_count": 1,
            "activation_cost_mana": "{3}",
            "activation_cost_generic": 3,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "activation_requires_sacrifice_target": True,
            "activation_sacrifice_target": "artifact_or_creature",
        },
    }

    scenario = builder.simple_activated_draw_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_draw"
    assert scenario["controller_mana"]["generic"] == 3
    assert scenario["expected_draw_count"] == 1
    assert scenario["expected_tapped_source"] is True
    assert scenario["expect_target_sacrificed"] is True
    assert scenario["sacrifice_target"]["type_line"] == "Artifact"


def test_manifest_builds_simple_activated_draw_execution_scenario_with_tap_cost_target() -> None:
    rule = {
        "normalized_name": "azami-lady-of-scrolls",
        "card_name": "Azami, Lady of Scrolls",
        "oracle_hash": "hash-azami",
        "logical_rule_key": "battle_rule_v1:azami",
        "required_effect_fields": {
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_v1",
            "activated_draw": True,
            "activated_draw_count": 1,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": False,
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
        },
    }

    scenario = builder.simple_activated_draw_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_draw"
    assert scenario["expected_tap_cost_count"] == 1
    assert scenario["tap_cost_targets"][0]["type_line"].startswith("Creature")
    assert "Wizard" in scenario["tap_cost_targets"][0]["type_line"]


def test_manifest_builds_simple_activated_draw_execution_scenario_with_remove_counter_cost() -> None:
    rule = {
        "normalized_name": "soul-diviner",
        "card_name": "Soul Diviner",
        "oracle_hash": "hash-soul-diviner",
        "logical_rule_key": "battle_rule_v1:soul-diviner",
        "required_effect_fields": {
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_v1",
            "activated_draw": True,
            "activated_draw_count": 1,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "activation_remove_counter_cost": {
                "count": 1,
                "target_controller": "self",
                "counter_types": ["any"],
                "constraints": {"card_types": ["artifact", "creature", "land", "planeswalker"]},
            },
        },
    }

    scenario = builder.simple_activated_draw_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_draw"
    assert scenario["expected_remove_counter_cost_count"] == 1
    assert scenario["expected_remove_counter_type"] == "+1/+1"
    assert scenario["counter_cost_targets"][0]["plus_one_counters"] == 1


def test_manifest_builds_simple_activated_draw_graveyard_self_exile_scenario() -> None:
    rule = {
        "normalized_name": "cobbled-lancer",
        "card_name": "Cobbled Lancer",
        "oracle_hash": "hash-cobbled-lancer",
        "logical_rule_key": "battle_rule_v1:cobbled-lancer",
        "required_effect_fields": {
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_v1",
            "activated_draw": True,
            "activated_draw_count": 1,
            "activation_cost_mana": "{3}{U}",
            "activation_cost_generic": 3,
            "activation_cost_colors": ["U"],
            "activation_requires_tap": False,
            "activation_zone": "graveyard",
            "activation_requires_exile_source_from_graveyard": True,
        },
    }

    scenario = builder.simple_activated_draw_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_draw"
    assert scenario["source_zone"] == "graveyard"
    assert scenario["expected_exiled_source_from_graveyard"] is True
    assert scenario["controller_mana"]["generic"] == 3
    assert scenario["controller_mana"]["blue"] == 1


def test_manifest_builds_simple_activated_draw_discard_graveyard_self_exile_scenario() -> None:
    rule = {
        "normalized_name": "maestros-initiate",
        "card_name": "Maestros Initiate",
        "oracle_hash": "hash-maestros-initiate",
        "logical_rule_key": "battle_rule_v1:maestros-initiate",
        "required_effect_fields": {
            "effect": "draw_engine",
            "battle_model_scope": "xmage_permanent_simple_activated_draw_discard_v1",
            "activated_draw_discard": True,
            "activated_draw_count": 2,
            "activated_discard_count": 1,
            "draw_count": 2,
            "discard_count": 1,
            "activation_cost_mana": "{4}{U/R}",
            "activation_cost_generic": 4,
            "activation_cost_colors": ["U/R"],
            "activation_requires_tap": False,
            "activation_zone": "graveyard",
            "activation_requires_exile_source_from_graveyard": True,
        },
    }

    scenario = builder.simple_activated_draw_discard_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_draw_discard"
    assert scenario["source_zone"] == "graveyard"
    assert scenario["expected_exiled_source_from_graveyard"] is True
    assert scenario["expected_draw_count"] == 2
    assert scenario["expected_discard_count"] == 1
    assert scenario["controller_mana"]["generic"] == 4


def test_manifest_builds_target_player_x_draw_execution_scenario() -> None:
    rule = {
        "normalized_name": "braingeyser",
        "card_name": "Braingeyser",
        "oracle_hash": "hash-braingeyser",
        "logical_rule_key": "battle_rule_v1:hash-braingeyser",
        "required_effect_fields": {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_target_player_draw_spell_v1",
            "target": "player",
            "target_controller": "target_player",
            "target_preference": "self",
            "count": 0,
            "draw_count": 0,
            "draw_count_source": "x_value",
            "target_player_draw": True,
            "sorcery": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "target_player_draw_spell"
    assert scenario["card"]["name"] == "Braingeyser"
    assert scenario["card"]["type_line"] == "Sorcery"
    assert scenario["x_value"] == 3
    assert scenario["expected_draw_count"] == 3
    assert len(scenario["controller_library"]) == 3
    assert scenario["expected_target_player"] == "Spell Controller"


def test_manifest_builds_target_player_x_draw_shuffle_self_execution_scenario() -> None:
    rule = {
        "normalized_name": "blue sun's zenith",
        "card_name": "Blue Sun's Zenith",
        "oracle_hash": "hash-blue-sun",
        "logical_rule_key": "battle_rule_v1:hash-blue-sun",
        "required_effect_fields": {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_target_player_draw_spell_v1",
            "target": "player",
            "target_controller": "target_player",
            "target_preference": "self",
            "count": 0,
            "draw_count": 0,
            "draw_count_source": "x_value",
            "target_player_draw": True,
            "instant": True,
            "shuffle_self_into_library_on_resolution": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "target_player_draw_spell"
    assert scenario["card"]["name"] == "Blue Sun's Zenith"
    assert scenario["card"]["type_line"] == "Instant"
    assert scenario["x_value"] == 3
    assert scenario["expected_draw_count"] == 3
    assert scenario["expect_shuffle_self"] is True
    assert scenario["expected_spell_destination"] == "library"


def test_manifest_builds_simple_activated_damage_execution_scenario() -> None:
    rule = {
        "normalized_name": "stormbind",
        "card_name": "Stormbind",
        "oracle_hash": "hash-stormbind",
        "logical_rule_key": "battle_rule_v1:hash-stormbind",
        "required_effect_fields": {
            "effect": "enchantment",
            "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_damage_amount": 2,
            "target": "any_target",
            "activation_cost_mana": "{2}",
            "activation_cost_generic": 2,
            "activation_cost_colors": [],
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
            "activation_requires_discard_card": True,
            "activation_discard_random": True,
        },
    }

    scenario = builder.simple_activated_damage_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_damage"
    assert scenario["expected_damage"] == 2
    assert scenario["expected_discard_count"] == 1
    assert scenario["expected_discard_target"] == "any_card"
    assert scenario["expected_discard_random"] is True
    assert scenario["expected_life_paid"] == 0
    assert scenario["controller_mana"]["generic"] == 2
    assert len(scenario["controller_hand"]) == 2


def test_manifest_builds_simple_activated_damage_life_cost_execution_scenario() -> None:
    rule = {
        "normalized_name": "reckless_assault",
        "card_name": "Reckless Assault",
        "oracle_hash": "hash-reckless-assault",
        "logical_rule_key": "battle_rule_v1:hash-reckless-assault",
        "required_effect_fields": {
            "effect": "enchantment",
            "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_damage_amount": 1,
            "target": "any_target",
            "activation_cost_mana": "{1}",
            "activation_cost_generic": 1,
            "activation_cost_colors": [],
            "activation_life_cost": 2,
        },
    }

    scenario = builder.simple_activated_damage_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_damage"
    assert scenario["expected_damage"] == 1
    assert scenario["expected_life_paid"] == 2
    assert scenario["starting_life"] == 40
    assert scenario["controller_mana"]["generic"] == 1


def test_manifest_builds_simple_activated_damage_exile_top_library_cost_scenario() -> None:
    rule = {
        "normalized_name": "arc-slogger",
        "card_name": "Arc-Slogger",
        "oracle_hash": "hash-arc-slogger",
        "logical_rule_key": "battle_rule_v1:hash-arc-slogger",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_damage_amount": 2,
            "target": "any_target",
            "activation_cost_mana": "{R}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["R"],
            "activation_exile_top_library_count": 10,
        },
    }

    scenario = builder.simple_activated_damage_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_damage"
    assert scenario["expected_exiled_top_library_count"] == 10
    assert len(scenario["controller_library"]) == 10
    assert scenario["controller_mana"]["red"] == 1


def test_manifest_builds_simple_activated_damage_remove_counter_cost_scenario() -> None:
    rule = {
        "normalized_name": "ion-storm",
        "card_name": "Ion Storm",
        "oracle_hash": "hash-ion-storm",
        "logical_rule_key": "battle_rule_v1:hash-ion-storm",
        "required_effect_fields": {
            "effect": "enchantment",
            "battle_model_scope": "xmage_permanent_simple_activated_damage_v1",
            "activated_damage_amount": 2,
            "target": "any_target",
            "activation_cost_mana": "{1}{R}",
            "activation_cost_generic": 1,
            "activation_cost_colors": ["R"],
            "activation_remove_counter_cost": {
                "count": 1,
                "target_controller": "self",
                "counter_types": ["+1/+1", "charge"],
                "constraints": {"card_types": ["permanent"]},
            },
        },
    }

    scenario = builder.simple_activated_damage_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_damage"
    assert scenario["expected_remove_counter_cost_count"] == 1
    assert scenario["expected_remove_counter_type"] == "+1/+1"
    assert len(scenario["counter_cost_targets"]) == 1
    assert scenario["counter_cost_targets"][0]["plus_one_counters"] == 1
    assert scenario["controller_mana"]["generic"] == 1
    assert scenario["controller_mana"]["red"] == 1


def test_manifest_builds_damage_each_opponent_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "sizzle",
        "card_name": "Sizzle",
        "oracle_hash": "hash-sizzle",
        "logical_rule_key": "battle_rule_v1:hash-sizzle",
        "required_effect_fields": {
            "effect": "damage_each_opponent",
            "battle_model_scope": "spell_damage_each_opponent_v1",
            "ability_kind": "one_shot",
            "amount": 3,
            "damage": 3,
            "target_controller": "opponents",
            "sorcery": True,
        },
    }

    scenario = builder.damage_each_opponent_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "damage_each_opponent_spell"
    assert scenario["card"]["name"] == "Sizzle"
    assert scenario["card"]["type_line"] == "Sorcery"
    assert scenario["expected_damage"] == 3
    assert scenario["opponent_life"] == 9
    assert scenario["second_opponent_life"] == 11


def test_manifest_builds_damage_each_opponent_and_their_permanents_execution_scenario() -> None:
    rule = {
        "normalized_name": "end_the_festivities",
        "card_name": "End the Festivities",
        "oracle_hash": "hash-end",
        "logical_rule_key": "battle_rule_v1:hash-end",
        "required_effect_fields": {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_damage_each_opponent_and_their_permanents_spell_v1",
            "ability_kind": "one_shot",
            "amount": 1,
            "damage": 1,
            "damage_scope": "each_creature_and_planeswalker_opponents_control",
            "target_controller": "opponents",
            "sorcery": True,
        },
    }

    scenario = builder.damage_each_opponent_and_their_permanents_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "damage_each_opponent_and_their_permanents_spell"
    assert scenario["card"]["name"] == "End the Festivities"
    assert scenario["card"]["type_line"] == "Sorcery"
    assert scenario["expected_damage"] == 1
    assert scenario["expected_damage_scope"] == "each_creature_and_planeswalker_opponents_control"
    assert scenario["expected_planeswalker_damage"] is True


def test_manifest_builds_damage_gain_life_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "kiss_of_death",
        "card_name": "Kiss of Death",
        "oracle_hash": "hash-kiss",
        "logical_rule_key": "battle_rule_v1:hash-kiss",
        "required_effect_fields": {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_and_controller_gain_life_spell_v1",
            "amount": 4,
            "damage": 4,
            "gain_life": 4,
            "controller_gain_life": 4,
            "target": "opponent_or_planeswalker",
            "target_constraints": {"scope": "opponent_or_planeswalker"},
        },
    }

    scenario = builder.damage_gain_life_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "damage_gain_life_spell"
    assert scenario["target"] is None
    assert scenario["expected_damage"] == 4
    assert scenario["expected_life_gain"] == 4
    assert scenario["expected_target_constraints"] == {"scope": "opponent_or_planeswalker"}


def test_manifest_builds_fixed_damage_target_spell_execution_scenario() -> None:
    proposal = {
        "normalized_name": "rending volley",
        "card_name": "Rending Volley",
        "oracle_hash": "hash-rending-volley",
        "logical_rule_key": "battle_rule_v1:hash-rending-volley",
        "effect_json": {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
            "amount": 4,
            "damage": 4,
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "target_colors": ["W", "U"]},
            "cant_be_countered": True,
        },
    }

    rule = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert rule["required_effect_fields"]["cant_be_countered"] is True
    assert scenario is not None
    assert scenario["type"] == "fixed_damage_target_spell"
    assert scenario["card"]["name"] == "Rending Volley"
    assert scenario["expected_damage"] == 4
    assert scenario["expected_life_gain"] == 0
    assert scenario["expected_cant_be_countered"] is True
    assert scenario["target"]["type_line"].startswith("Creature")
    assert scenario["target"]["colors"] == ["W"]
    assert scenario["nonmatching_target"]["type_line"].startswith("Creature")
    assert scenario["nonmatching_target"]["colors"] == ["B"]


def test_manifest_builds_fixed_damage_target_shuffle_self_execution_scenario() -> None:
    proposal = {
        "normalized_name": "beacon of destruction",
        "card_name": "Beacon of Destruction",
        "oracle_hash": "hash-beacon-destruction",
        "logical_rule_key": "battle_rule_v1:hash-beacon-destruction",
        "effect_json": {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
            "amount": 5,
            "damage": 5,
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "instant": True,
            "shuffle_self_into_library_on_resolution": True,
        },
    }

    rule = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert rule["required_effect_fields"]["shuffle_self_into_library_on_resolution"] is True
    assert scenario is not None
    assert scenario["type"] == "fixed_damage_target_spell"
    assert scenario["card"]["name"] == "Beacon of Destruction"
    assert scenario["expected_damage"] == 5
    assert scenario["expect_shuffle_self"] is True
    assert scenario["expected_spell_destination"] == "library"


def test_manifest_builds_fixed_damage_target_additional_cost_scenario() -> None:
    proposal = {
        "normalized_name": "devour in flames",
        "card_name": "Devour in Flames",
        "oracle_hash": "hash-devour-in-flames",
        "logical_rule_key": "battle_rule_v1:hash-devour-in-flames",
        "effect_json": {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
            "amount": 5,
            "damage": 5,
            "target": "creature_or_planeswalker",
            "target_constraints": {"scope": "creature_or_planeswalker"},
            "requires_return_land_to_hand": True,
            "additional_cost": "return_land_to_hand",
            "xmage_additional_cost_class": "ReturnToHandChosenControlledPermanentCost",
            "xmage_additional_cost_target": "land",
        },
    }

    rule = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert rule["required_effect_fields"]["requires_return_land_to_hand"] is True
    assert scenario is not None
    assert scenario["type"] == "fixed_damage_target_spell"
    assert scenario["expected_additional_cost"] == "return_land_to_hand"
    assert scenario["expected_returned_land_name"] == "E2E Return Cost Land"
    assert scenario["controller_battlefield"][0]["type_line"] == "Basic Land - Mountain"


def test_manifest_builds_single_target_removal_or_additional_cost_scenario() -> None:
    proposal = {
        "normalized_name": "bitter triumph",
        "card_name": "Bitter Triumph",
        "oracle_hash": "hash-bitter-triumph",
        "logical_rule_key": "battle_rule_v1:hash-bitter-triumph",
        "effect_json": {
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
            "xmage_additional_cost_class": "OrCost",
        },
    }

    rule = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert rule["required_effect_fields"]["requires_one_additional_cost_option"] is True
    assert scenario is not None
    assert scenario["type"] == "single_target_removal"
    assert scenario["expected_additional_cost"] == "discard_card"
    assert scenario["expected_discarded_name"] == "E2E Discard Cost Card"
    assert scenario["controller_hand"][0]["name"] == "E2E Discard Cost Card"


def test_manifest_builds_damage_target_create_treasure_execution_scenario() -> None:
    proposal = {
        "normalized_name": "improvised weaponry",
        "card_name": "Improvised Weaponry",
        "oracle_hash": "hash-improvised-weaponry",
        "logical_rule_key": "battle_rule_v1:hash-improvised-weaponry",
        "effect_json": {
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
        },
    }

    rule = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "damage_target_create_treasure"
    assert scenario["card"]["name"] == "Improvised Weaponry"
    assert scenario["expected_damage"] == 2
    assert scenario["expected_life_gain"] == 0
    assert scenario["expected_treasure_count"] == 1
    assert scenario["expected_target_constraints"] == {"scope": "any_target"}


def test_manifest_builds_tap_target_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "gridlock",
        "card_name": "Gridlock",
        "oracle_hash": "hash-gridlock",
        "logical_rule_key": "battle_rule_v1:hash-gridlock",
        "required_effect_fields": {
            "effect": "tap_target",
            "battle_model_scope": "xmage_tap_target_spell_v1",
            "target": "nonland_permanent",
            "target_constraints": {"card_types": ["permanent"], "exclude_card_types": ["land"]},
            "target_count_from_x": True,
            "target_count_source": "x_value",
        },
    }

    scenario = builder.tap_target_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "tap_target_spell"
    assert scenario["card"]["name"] == "Gridlock"
    assert scenario["expected_target_count"] == 2
    assert scenario["x_value"] == 2
    assert len(scenario["targets"]) == 2
    assert scenario["nonmatching_target"]["name"] == "E2E Illegal Tap Spell Target"


def test_manifest_builds_boost_untap_target_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "synchronized strike",
        "card_name": "Synchronized Strike",
        "oracle_hash": "hash-synchronized-strike",
        "logical_rule_key": "battle_rule_v1:hash-synchronized-strike",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.boost_untap_target_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "stat_modifier_until_eot_untap_target"
    assert scenario["expected_power_delta"] == 2
    assert scenario["expected_toughness_delta"] == 2
    assert scenario["expected_target_count"] == 2
    assert len(scenario["targets"]) == 2
    assert all(target["tapped"] is True for target in scenario["targets"])
    assert scenario["nonmatching_target"]["name"] == "E2E Illegal Boost Untap Target"


def test_manifest_builds_boost_keyword_untap_target_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "aim high",
        "card_name": "Aim High",
        "oracle_hash": "hash-aim-high",
        "logical_rule_key": "battle_rule_v1:hash-aim-high",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.boost_untap_target_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "stat_modifier_until_eot_untap_target"
    assert scenario["expected_power_delta"] == 2
    assert scenario["expected_toughness_delta"] == 2
    assert scenario["expected_keywords"] == ["reach"]
    assert scenario["expected_target_count"] == 1
    assert scenario["targets"][0]["tapped"] is True


def test_manifest_builds_add_counters_untap_target_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "dragonscale boon",
        "card_name": "Dragonscale Boon",
        "oracle_hash": "hash-dragonscale-boon",
        "logical_rule_key": "battle_rule_v1:hash-dragonscale-boon",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.add_counters_untap_target_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "add_counters_untap_target_spell"
    assert scenario["expected_counter_type"] == "+1/+1"
    assert scenario["expected_counter_count"] == 2
    assert scenario["target"]["tapped"] is True
    assert scenario["nonmatching_target"]["name"] == "E2E Illegal Counter Untap Target"


def test_manifest_builds_add_counters_multi_target_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "test counters",
        "card_name": "Test Counters",
        "oracle_hash": "hash-test-counters",
        "logical_rule_key": "battle_rule_v1:hash-test-counters",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.add_counters_target_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "add_counters_target_spell"
    assert scenario["expected_target_count"] == 2
    assert len(scenario["targets"]) == 2
    assert scenario["expected_counter_type"] == "+1/+1"


def test_manifest_builds_add_counters_untap_multi_target_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "leos guidance",
        "card_name": "Leo's Guidance",
        "oracle_hash": "hash-leos-guidance",
        "logical_rule_key": "battle_rule_v1:hash-leos-guidance",
        "required_effect_fields": {
            "effect": "add_counters",
            "battle_model_scope": "xmage_fixed_add_counters_and_untap_target_creatures_spell_v1",
            "target": "creature",
            "target_controller": "any",
            "target_constraints": {"card_types": ["creature"]},
            "counter_type": "+1/+1",
            "counter_count": 1,
            "count": 1,
            "untap_target": True,
            "target_count": 3,
            "target_count_min": 0,
            "target_count_max": 3,
            "up_to_count": True,
        },
    }

    scenario = builder.add_counters_untap_target_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "add_counters_untap_target_spell"
    assert scenario["expected_target_count"] == 3
    assert len(scenario["targets"]) == 3
    assert all(target["tapped"] is True for target in scenario["targets"])


def test_manifest_builds_gain_control_untap_haste_execution_scenario() -> None:
    rule = {
        "normalized_name": "act of treason",
        "card_name": "Act of Treason",
        "oracle_hash": "hash-act-of-treason",
        "logical_rule_key": "battle_rule_v1:hash-act-of-treason",
        "required_effect_fields": {
            "effect": "gain_control_untap_haste_until_eot",
            "battle_model_scope": "xmage_gain_control_untap_haste_until_eot_spell_v1",
            "target": "creature",
            "target_controller": "opponents",
            "target_constraints": {"card_types": ["creature"]},
            "control_duration": "until_end_of_turn",
            "untap_target": True,
            "granted_keywords_until_eot": ["haste"],
        },
    }

    scenario = builder.gain_control_untap_haste_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "gain_control_untap_haste_until_eot"
    assert scenario["card"]["name"] == "Act of Treason"
    assert scenario["target"]["tapped"] is True
    assert scenario["expected_target_constraints"] == {"card_types": ["creature"]}
    assert scenario["expected_granted_keywords"] == ["haste"]
    assert scenario["expected_control_duration"] == "until_end_of_turn"
    assert scenario["nonmatching_target"]["name"] == "E2E Illegal Temporary Control Target"


def test_manifest_builds_simple_activated_tap_target_execution_scenario() -> None:
    rule = {
        "normalized_name": "akroan jailer",
        "card_name": "Akroan Jailer",
        "oracle_hash": "hash-akroan-jailer",
        "logical_rule_key": "battle_rule_v1:hash-akroan-jailer",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_tap_target_v1",
            "activated_effect": "tap_target",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_tap_target_v1",
            "activated_tap_target": "creature",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "activation_cost_mana": "{2}{W}",
            "activation_cost_generic": 2,
            "activation_cost_colors": ["W"],
            "activation_requires_tap": True,
        },
    }

    scenario = builder.simple_activated_tap_target_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_tap_target"
    assert scenario["expected_target"] == "creature"
    assert scenario["expected_tapped_source"] is True
    assert scenario["controller_mana"]["generic"] == 2
    assert scenario["controller_mana"]["white"] == 1


def test_manifest_builds_simple_activated_untap_target_execution_scenario() -> None:
    rule = {
        "normalized_name": "argothian elder",
        "card_name": "Argothian Elder",
        "oracle_hash": "hash-argothian-elder",
        "logical_rule_key": "battle_rule_v1:hash-argothian-elder",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.simple_activated_untap_target_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_untap_target"
    assert scenario["expected_target"] == "land"
    assert scenario["expected_target_count"] == 2
    assert scenario["expected_tapped_source"] is True
    assert len(scenario["targets"]) == 2
    assert all(target["effect"] == "land" and target["tapped"] is True for target in scenario["targets"])
    assert scenario["nonmatching_target"]["tapped"] is True


def test_manifest_builds_simple_activated_tap_target_noncreature_fixture() -> None:
    rule = {
        "normalized_name": "icy manipulator",
        "card_name": "Icy Manipulator",
        "oracle_hash": "hash-icy-manipulator",
        "logical_rule_key": "battle_rule_v1:hash-icy-manipulator",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.simple_activated_tap_target_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["expected_target"] == "artifact_creature_or_land"
    assert scenario["target"]["type_line"] in {"Creature - Soldier", "Artifact", "Land"}
    assert scenario["controller_mana"]["generic"] == 1


def test_manifest_builds_simple_activated_tap_target_restricted_fixture() -> None:
    rule = {
        "normalized_name": "law-rune enforcer",
        "card_name": "Law-Rune Enforcer",
        "oracle_hash": "hash-law-rune-enforcer",
        "logical_rule_key": "battle_rule_v1:hash-law-rune-enforcer",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.simple_activated_tap_target_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["expected_target"] == "creature_mana_value_2_or_greater"
    assert scenario["target"]["type_line"] == "Creature - Soldier"
    assert scenario["target"]["cmc"] == 2
    assert scenario["controller_mana"]["generic"] == 1


def test_manifest_builds_simple_activated_add_counters_target_scenario() -> None:
    rule = {
        "normalized_name": "gnarled effigy",
        "card_name": "Gnarled Effigy",
        "oracle_hash": "hash-gnarled-effigy",
        "logical_rule_key": "battle_rule_v1:hash-gnarled-effigy",
        "required_effect_fields": {
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
            "counter_type": "-1/-1",
            "counter_count": 1,
            "activation_cost_mana": "{4}",
            "activation_cost_generic": 4,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "activation_requires_sacrifice": True,
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
            "activation_life_cost": 3,
            "activation_sacrifice_cost": {
                "count": 1,
                "target_controller": "self",
                "constraints": {"card_types": ["creature"], "target_subtypes": ["human"]},
            },
        },
    }

    scenario = builder.simple_activated_add_counters_target_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_add_counters_target"
    assert scenario["expected_target"] == "creature"
    assert scenario["expected_counter_type"] == "-1/-1"
    assert scenario["expected_counter_count"] == 1
    assert scenario["expected_tapped_source"] is True
    assert scenario["expected_sacrificed_source"] is True
    assert scenario["expected_discard_count"] == 1
    assert scenario["expected_life_paid"] == 3
    assert scenario["expected_sacrifice_count"] == 1
    assert scenario["target"]["type_line"] == "Creature - Soldier"
    assert scenario["controller_mana"]["generic"] == 4
    assert scenario["controller_hand"][0]["name"] == "E2E Counter Cost Discard 1"
    assert scenario["sacrifice_targets"][0]["type_line"] == "Creature - Human"


def test_manifest_builds_simple_activated_add_counters_self_scenario() -> None:
    rule = {
        "normalized_name": "markov dreadknight",
        "card_name": "Markov Dreadknight",
        "oracle_hash": "hash-markov-dreadknight",
        "logical_rule_key": "battle_rule_v1:hash-markov-dreadknight",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.simple_activated_add_counters_self_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_add_counters_self"
    assert scenario["expected_counter_type"] == "+1/+1"
    assert scenario["expected_counter_count"] == 2
    assert scenario["expected_tapped_source"] is False
    assert scenario["expected_discard_count"] == 1
    assert scenario["expected_life_paid"] == 3
    assert scenario["expected_sacrifice_count"] == 1
    assert scenario["controller_mana"]["generic"] == 2
    assert scenario["controller_mana"]["black"] == 1
    assert scenario["controller_hand"][0]["name"] == "E2E Self Counter Cost Discard 1"
    assert scenario["sacrifice_targets"][0]["type_line"] == "Creature - Soldier"


def test_manifest_builds_simple_activated_destroy_execution_scenario() -> None:
    rule = {
        "normalized_name": "caustic caterpillar",
        "card_name": "Caustic Caterpillar",
        "oracle_hash": "hash-caustic-caterpillar",
        "logical_rule_key": "battle_rule_v1:hash-caustic-caterpillar",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_effect": "destroy_target",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_remove_effect": "remove_permanent",
            "activated_remove_target": "artifact_or_enchantment",
            "target": "permanent",
            "target_constraints": {"card_types_any": ["artifact", "enchantment"]},
            "destination": "graveyard",
            "activation_cost_mana": "{1}{G}",
            "activation_cost_generic": 1,
            "activation_cost_colors": ["G"],
            "activation_requires_sacrifice": True,
            "activated_self_sacrifice_destroy": True,
        },
    }

    scenario = builder.simple_activated_destroy_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_destroy"
    assert scenario["expected_sacrificed_source"] is True
    assert scenario["expected_destination"] == "graveyard"
    assert scenario["controller_mana"]["generic"] == 1
    assert scenario["controller_mana"]["green"] == 1
    assert scenario["target"]["type_line"] == "Artifact"


def test_manifest_builds_simple_activated_destroy_token_target_scenario() -> None:
    rule = {
        "normalized_name": "dogged hunter",
        "card_name": "Dogged Hunter",
        "oracle_hash": "hash-dogged-hunter",
        "logical_rule_key": "battle_rule_v1:hash-dogged-hunter",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_effect": "destroy_target",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_remove_effect": "remove_creature",
            "activated_remove_target": "creature_token",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "token": True},
            "destination": "graveyard",
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
        },
    }

    scenario = builder.simple_activated_destroy_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_destroy"
    assert scenario["expected_target"] == "creature_token"
    assert scenario["expected_target_constraints"] == {"card_types": ["creature"], "token": True}
    assert scenario["expected_tapped_source"] is True
    assert scenario["target"]["type_line"] == "Creature - Soldier"
    assert scenario["target"]["token"] is True
    assert scenario["target"]["is_token"] is True


def test_manifest_builds_simple_activated_destroy_sacrifice_target_scenario() -> None:
    rule = {
        "normalized_name": "quagmire druid",
        "card_name": "Quagmire Druid",
        "oracle_hash": "hash-quagmire-druid",
        "logical_rule_key": "battle_rule_v1:hash-quagmire-druid",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_effect": "destroy_target",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_remove_effect": "remove_permanent",
            "activated_remove_target": "enchantment",
            "target": "enchantment",
            "target_constraints": {"card_types": ["enchantment"]},
            "destination": "graveyard",
            "activation_cost_mana": "{G}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["G"],
            "activation_requires_tap": True,
            "activation_requires_sacrifice_target": True,
            "activation_sacrifice_target": "creature",
        },
    }

    scenario = builder.simple_activated_destroy_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_destroy"
    assert scenario["controller_mana"]["green"] == 1
    assert scenario["expected_target"] == "enchantment"
    assert scenario["target"]["type_line"] == "Enchantment"
    assert scenario["expect_target_sacrificed"] is True
    assert scenario["sacrifice_target"]["type_line"] == "Creature - Soldier"


def test_manifest_builds_simple_activated_destroy_discard_cost_scenario() -> None:
    rule = {
        "normalized_name": "notorious assassin",
        "card_name": "Notorious Assassin",
        "oracle_hash": "hash-notorious-assassin",
        "logical_rule_key": "battle_rule_v1:hash-notorious-assassin",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_effect": "destroy_target",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_destroy_target_v1",
            "activated_remove_effect": "remove_creature",
            "activated_remove_target": "nonblack_creature",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "exclude_colors": ["B"]},
            "destination": "graveyard",
            "activation_cost_mana": "{2}{B}",
            "activation_cost_generic": 2,
            "activation_cost_colors": ["B"],
            "activation_requires_tap": True,
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
            "activation_requires_discard_card": True,
        },
    }

    scenario = builder.simple_activated_destroy_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_destroy"
    assert scenario["controller_mana"]["generic"] == 2
    assert scenario["controller_mana"]["black"] == 1
    assert scenario["expected_discard_count"] == 1
    assert scenario["expected_discard_target"] == "any_card"
    assert scenario["controller_hand"] == [
        {
            "name": "E2E Activated Destroy Discard 1",
            "type_line": "Instant",
            "effect": "draw_cards",
            "cmc": 2,
        }
    ]
    assert scenario["target"]["colors"] == ["W"]


def test_manifest_builds_simple_activated_bounce_self_discard_scenario() -> None:
    rule = {
        "normalized_name": "waterfront bouncer",
        "card_name": "Waterfront Bouncer",
        "oracle_hash": "hash-waterfront-bouncer",
        "logical_rule_key": "battle_rule_v1:hash-waterfront-bouncer",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_return_to_hand_v1",
            "activated_effect": "return_to_hand",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_return_to_hand_v1",
            "activated_remove_effect": "remove_creature",
            "activated_remove_target": "creature",
            "target": "creature",
            "target_controller": "self",
            "target_constraints": {
                "card_types": ["creature"],
                "controller_scope": "self",
                "exclude_source": True,
            },
            "destination": "hand",
            "activation_cost_mana": "{U}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["U"],
            "activation_requires_tap": True,
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
            "activation_requires_discard_card": True,
        },
    }

    scenario = builder.simple_activated_bounce_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_bounce"
    assert scenario["target_controller"] == "self"
    assert scenario["target_owner"] == "controller"
    assert scenario["expected_destination"] == "hand"
    assert scenario["expected_target_controller"] == "self"
    assert scenario["expected_tapped_source"] is True
    assert scenario["expected_discard_count"] == 1
    assert scenario["expected_discard_target"] == "any_card"
    assert scenario["controller_mana"]["blue"] == 1
    assert scenario["target"]["type_line"] == "Creature - Soldier"
    assert scenario["controller_hand"][0]["name"] == "E2E Activated Bounce Discard 1"


def test_manifest_builds_simple_activated_self_keyword_execution_scenario() -> None:
    rule = {
        "normalized_name": "cobalt golem",
        "card_name": "Cobalt Golem",
        "oracle_hash": "hash-cobalt-golem",
        "logical_rule_key": "battle_rule_v1:hash-cobalt-golem",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_self_keyword_until_eot_v1",
            "activated_effect": "self_keyword_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_self_keyword_until_eot_v1",
            "target": "self",
            "target_controller": "self",
            "granted_keywords_until_eot": ["flying"],
            "activation_cost_mana": "{2}{R/W}",
            "activation_cost_generic": 2,
            "activation_cost_colors": ["R/W"],
            "activation_requires_tap": False,
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
            "activation_requires_discard_card": True,
        },
    }

    scenario = builder.simple_activated_self_keyword_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_self_keyword"
    assert scenario["expected_keywords"] == ["flying"]
    assert scenario["expected_tapped_source"] is False
    assert scenario["controller_mana"]["generic"] == 2
    assert scenario["controller_mana"]["red"] == 1
    assert scenario["controller_mana"]["white"] == 0
    assert scenario["expected_discard_count"] == 1
    assert len(scenario["controller_hand"]) == 2


def test_manifest_builds_simple_activated_self_boost_execution_scenario() -> None:
    rule = {
        "normalized_name": "rootwalla",
        "card_name": "Rootwalla",
        "oracle_hash": "hash-rootwalla",
        "logical_rule_key": "battle_rule_v1:hash-rootwalla",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "activated_effect": "self_stat_modifier_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "target": "self",
            "target_controller": "self",
            "power_delta": 2,
            "toughness_delta": 2,
            "activation_cost_mana": "{1}{G}",
            "activation_cost_generic": 1,
            "activation_cost_colors": ["G"],
            "activation_limit_per_turn": 1,
        },
    }

    scenario = builder.simple_activated_self_boost_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_self_boost"
    assert scenario["card"]["name"] == "Rootwalla"
    assert scenario["controller_mana"]["generic"] == 1
    assert scenario["controller_mana"]["green"] == 1
    assert scenario["expected_power_delta"] == 2
    assert scenario["expected_toughness_delta"] == 2
    assert scenario["expected_activation_limit_per_turn"] == 1


def test_manifest_builds_simple_activated_self_boost_snow_cost_scenario() -> None:
    rule = {
        "normalized_name": "frostwalla",
        "card_name": "Frostwalla",
        "oracle_hash": "hash-frostwalla",
        "logical_rule_key": "battle_rule_v1:hash-frostwalla",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "activated_effect": "self_stat_modifier_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "target": "self",
            "target_controller": "self",
            "power_delta": 2,
            "toughness_delta": 2,
            "activation_cost_mana": "{S}",
            "activation_cost_generic": 1,
            "activation_cost_colors": [],
            "activation_limit_per_turn": 1,
        },
    }

    scenario = builder.simple_activated_self_boost_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_self_boost"
    assert scenario["controller_mana"]["generic"] == 1
    assert scenario["controller_mana"]["green"] == 0
    assert scenario["expected_activation_limit_per_turn"] == 1


def test_manifest_builds_simple_activated_self_boost_extra_cost_scenario() -> None:
    rule = {
        "normalized_name": "fleshgrafter",
        "card_name": "Fleshgrafter",
        "oracle_hash": "hash-fleshgrafter",
        "logical_rule_key": "battle_rule_v1:hash-fleshgrafter",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "activated_effect": "self_stat_modifier_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_self_boost_until_eot_v1",
            "target": "self",
            "target_controller": "self",
            "power_delta": 2,
            "toughness_delta": 2,
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_discard_count": 1,
            "activation_discard_target": "artifact_card",
            "activation_requires_discard_card": True,
            "activation_life_cost": 1,
        },
    }

    scenario = builder.simple_activated_self_boost_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_self_boost"
    assert scenario["expected_discard_count"] == 1
    assert scenario["expected_life_paid"] == 1
    assert scenario["controller_hand"][0]["type_line"] == "Artifact"


def test_manifest_builds_simple_activated_target_keyword_execution_scenario() -> None:
    rule = {
        "normalized_name": "selfless savior",
        "card_name": "Selfless Savior",
        "oracle_hash": "hash-selfless-savior",
        "logical_rule_key": "battle_rule_v1:hash-selfless-savior",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "activated_effect": "target_keyword_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "target": "creature",
            "target_controller": "self",
            "target_constraints": {"card_types": ["creature"], "exclude_source": True},
            "granted_keywords_until_eot": ["indestructible"],
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_sacrifice": True,
        },
    }

    scenario = builder.simple_activated_target_keyword_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_target_keyword"
    assert scenario["expected_keywords"] == ["indestructible"]
    assert scenario["expected_sacrificed_source"] is True
    assert scenario["target"]["type_line"].startswith("Creature")


def test_manifest_builds_simple_activated_target_keyword_sacrifice_target_scenario() -> None:
    rule = {
        "normalized_name": "slobad goblin tinkerer",
        "card_name": "Slobad, Goblin Tinkerer",
        "oracle_hash": "hash-slobad",
        "logical_rule_key": "battle_rule_v1:hash-slobad",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "activated_effect": "target_keyword_until_eot",
            "activated_battle_model_scope": "xmage_permanent_simple_activated_target_keyword_until_eot_v1",
            "target": "artifact",
            "target_controller": "self",
            "target_constraints": {"card_types": ["artifact"]},
            "granted_keywords_until_eot": ["indestructible"],
            "activation_cost_mana": "{0}",
            "activation_cost_generic": 0,
            "activation_cost_colors": [],
            "activation_requires_sacrifice_target": True,
            "activation_sacrifice_target": "artifact",
        },
    }

    scenario = builder.simple_activated_target_keyword_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "simple_activated_target_keyword"
    assert scenario["expected_keywords"] == ["indestructible"]
    assert scenario["target"]["type_line"] == "Artifact"
    assert scenario["expect_target_sacrificed"] is True
    assert scenario["sacrifice_target"]["type_line"] == "Artifact"


def test_manifest_builds_target_keyword_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "double cleave",
        "card_name": "Double Cleave",
        "oracle_hash": "hash-double-cleave",
        "logical_rule_key": "battle_rule_v1:hash-double-cleave",
        "required_effect_fields": {
            "effect": "stat_modifier_until_eot",
            "battle_model_scope": "xmage_fixed_keyword_target_creature_until_eot_spell_v1",
            "target": "creature",
            "target_controller": "any",
            "target_constraints": {"card_types": ["creature"]},
            "power_delta": 0,
            "toughness_delta": 0,
            "granted_keywords_until_eot": ["double_strike"],
        },
    }

    scenario = builder.target_keyword_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "stat_modifier_until_eot"
    assert scenario["expected_power_delta"] == 0
    assert scenario["expected_toughness_delta"] == 0
    assert scenario["expected_keywords"] == ["double_strike"]


def test_manifest_builds_boost_multiple_keywords_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "aerial maneuver",
        "card_name": "Aerial Maneuver",
        "oracle_hash": "hash-aerial-maneuver",
        "logical_rule_key": "battle_rule_v1:hash-aerial-maneuver",
        "required_effect_fields": {
            "effect": "stat_modifier_until_eot",
            "battle_model_scope": "xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1",
            "target": "creature",
            "target_controller": "any",
            "target_constraints": {"card_types": ["creature"]},
            "power_delta": 1,
            "toughness_delta": 1,
            "granted_keywords_until_eot": ["flying", "first_strike"],
        },
    }

    scenario = builder.target_keyword_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "stat_modifier_until_eot"
    assert scenario["expected_power_delta"] == 1
    assert scenario["expected_toughness_delta"] == 1
    assert scenario["expected_keywords"] == ["flying", "first_strike"]


def test_manifest_builds_multi_target_boost_keyword_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "coordinated assault",
        "card_name": "Coordinated Assault",
        "oracle_hash": "hash-coordinated-assault",
        "logical_rule_key": "battle_rule_v1:hash-coordinated-assault",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.target_keyword_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "stat_modifier_until_eot"
    assert scenario["expected_target_count"] == 2
    assert len(scenario["targets"]) == 2
    assert scenario["expected_power_delta"] == 1
    assert scenario["expected_toughness_delta"] == 0
    assert scenario["expected_keywords"] == ["first_strike"]


def test_manifest_builds_multi_target_boost_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "dauntless onslaught",
        "card_name": "Dauntless Onslaught",
        "oracle_hash": "hash-dauntless-onslaught",
        "logical_rule_key": "battle_rule_v1:hash-dauntless-onslaught",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.target_keyword_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "stat_modifier_until_eot"
    assert scenario["expected_target_count"] == 2
    assert len(scenario["targets"]) == 2
    assert scenario["expected_power_delta"] == 2
    assert scenario["expected_toughness_delta"] == 2
    assert scenario["expected_keywords"] == []


def test_manifest_builds_target_keyword_draw_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "poison the blade",
        "card_name": "Poison the Blade",
        "oracle_hash": "hash-poison-the-blade",
        "logical_rule_key": "battle_rule_v1:hash-poison-the-blade",
        "required_effect_fields": {
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
                    "target_constraints": {"card_types": ["creature"]},
                    "target_controller": "any",
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
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "target_keyword_draw_spell"
    assert scenario["expected_power_delta"] == 0
    assert scenario["expected_toughness_delta"] == 0
    assert scenario["expected_keywords"] == ["deathtouch"]
    assert scenario["expected_draw_count"] == 1
    assert len(scenario["library"]) == 2


def test_manifest_builds_multicolored_target_keyword_draw_fixture() -> None:
    rule = {
        "normalized_name": "psychotic fury",
        "card_name": "Psychotic Fury",
        "oracle_hash": "hash-psychotic-fury",
        "logical_rule_key": "battle_rule_v1:hash-psychotic-fury",
        "required_effect_fields": {
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
                    "target_constraints": {"card_types": ["creature"], "color_count_min": 2},
                    "target_controller": "any",
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
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "target_keyword_draw_spell"
    assert scenario["target"]["colors"] == ["W", "U"]
    assert scenario["nonmatching_target"]["colors"] == ["W"]
    assert scenario["expected_target_constraints"] == {"card_types": ["creature"], "color_count_min": 2}


def test_manifest_builds_boost_keyword_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "massive might",
        "card_name": "Massive Might",
        "oracle_hash": "hash-massive-might",
        "logical_rule_key": "battle_rule_v1:hash-massive-might",
        "required_effect_fields": {
            "effect": "stat_modifier_until_eot",
            "battle_model_scope": "xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1",
            "target": "creature",
            "target_controller": "any",
            "target_constraints": {"card_types": ["creature"]},
            "power_delta": 2,
            "toughness_delta": 2,
            "granted_keywords_until_eot": ["trample"],
        },
    }

    scenario = builder.target_keyword_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "stat_modifier_until_eot"
    assert scenario["expected_power_delta"] == 2
    assert scenario["expected_toughness_delta"] == 2
    assert scenario["expected_keywords"] == ["trample"]


def test_manifest_builds_boost_scry_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "battlewise valor",
        "card_name": "Battlewise Valor",
        "oracle_hash": "hash-battlewise-valor",
        "logical_rule_key": "battle_rule_v1:hash-battlewise-valor",
        "required_effect_fields": {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_fixed_boost_target_creature_until_eot_scry_spell_v1",
            "target": "creature",
            "target_controller": "any",
            "target_constraints": {"card_types": ["creature"]},
            "power_delta": 2,
            "toughness_delta": 2,
            "scry_count": 1,
            "_composite_rule_components": [
                {
                    "effect": "stat_modifier_until_eot",
                    "battle_model_scope": "xmage_fixed_boost_target_creature_until_eot_spell_v1",
                    "power_delta": 2,
                    "toughness_delta": 2,
                },
                {
                    "effect": "scry",
                    "battle_model_scope": "xmage_fixed_scry_spell_v1",
                    "count": 1,
                },
            ],
        },
    }

    scenario = builder.boost_scry_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "boost_scry_spell"
    assert scenario["expected_power_delta"] == 2
    assert scenario["expected_toughness_delta"] == 2
    assert scenario["expected_scry_count"] == 1


def test_manifest_builds_global_boost_draw_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "hydrolash",
        "card_name": "Hydrolash",
        "oracle_hash": "hash-hydrolash",
        "logical_rule_key": "battle_rule_v1:hash-hydrolash",
        "required_effect_fields": {
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
                    "target_controller": "all",
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
        },
    }

    scenario = builder.global_stat_modifier_draw_spell_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "global_stat_modifier_draw_spell"
    assert scenario["expected_power_delta"] == -2
    assert scenario["expected_toughness_delta"] == 0
    assert scenario["expected_draw_count"] == 1
    assert scenario["expected_affected_count"] == 2
    assert scenario["expected_creature_filter"] == {"combat_state": "attacking"}


def test_manifest_builds_target_boost_draw_spell_execution_scenario() -> None:
    rule = {
        "normalized_name": "aangs defense",
        "card_name": "Aang's Defense",
        "oracle_hash": "hash-aangs-defense",
        "logical_rule_key": "battle_rule_v1:hash-aangs-defense",
        "required_effect_fields": {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "controller_scope": "self", "combat_state": "blocking"},
            "target_controller": "self",
            "power_delta": 2,
            "toughness_delta": 2,
            "draw_count": 1,
            "_composite_rule_components": [
                {
                    "effect": "stat_modifier_until_eot",
                    "battle_model_scope": "xmage_fixed_boost_target_creature_until_eot_spell_v1",
                    "target": "creature",
                    "target_constraints": {
                        "card_types": ["creature"],
                        "controller_scope": "self",
                        "combat_state": "blocking",
                    },
                    "target_controller": "self",
                    "power_delta": 2,
                    "toughness_delta": 2,
                    "duration": "until_end_of_turn",
                },
                {
                    "effect": "draw_cards",
                    "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
                    "count": 1,
                },
            ],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "target_keyword_draw_spell"
    assert scenario["target"]["blocking"] is True
    assert scenario["nonmatching_target"].get("blocking") is not True
    assert scenario["expected_keywords"] == []
    assert scenario["expected_power_delta"] == 2
    assert scenario["expected_toughness_delta"] == 2
    assert scenario["expected_draw_count"] == 1


def test_manifest_builds_controlled_stat_modifier_filtered_execution_scenario() -> None:
    rule = {
        "normalized_name": "guardians' pledge",
        "card_name": "Guardians' Pledge",
        "oracle_hash": "hash-guardians-pledge",
        "logical_rule_key": "battle_rule_v1:hash-guardians-pledge",
        "required_effect_fields": {
            "effect": "controlled_stat_modifier_until_eot",
            "battle_model_scope": "xmage_fixed_boost_controlled_creatures_until_eot_spell_v1",
            "target": "controlled_w_creatures",
            "target_controller": "self",
            "target_constraints": {
                "controller": "self",
                "card_types": ["creature"],
                "creature_filter": {"colors": ["W"]},
            },
            "creature_filter": {"colors": ["W"]},
            "power_delta": 2,
            "toughness_delta": 2,
        },
    }

    scenario = builder.controlled_stat_modifier_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "controlled_stat_modifier_until_eot"
    assert scenario["expected_power_delta"] == 2
    assert scenario["expected_toughness_delta"] == 2
    assert scenario["expected_creature_filter"] == {"colors": ["W"]}
    assert scenario["matching_target"]["colors"] == ["W"]
    assert scenario["nonmatching_target"]["colors"] == ["B"]
    assert scenario["opponent_target"]["colors"] == ["W"]


def test_manifest_builds_attack_self_boost_execution_scenario() -> None:
    rule = {
        "normalized_name": "benalish veteran",
        "card_name": "Benalish Veteran",
        "oracle_hash": "hash-benalish-veteran",
        "logical_rule_key": "battle_rule_v1:hash-benalish-veteran",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_attack_self_boost_until_eot_v1",
            "trigger": "attack",
            "trigger_effect": "self_stat_modifier_until_eot",
            "power_delta": 1,
            "toughness_delta": 1,
        },
    }

    scenario = builder.attack_self_boost_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "attack_self_boost"
    assert scenario["card"]["name"] == "Benalish Veteran"
    assert scenario["expected_power_delta"] == 1
    assert scenario["expected_toughness_delta"] == 1


def test_manifest_builds_becomes_blocked_self_boost_execution_scenario() -> None:
    rule = {
        "normalized_name": "gang of elk",
        "card_name": "Gang of Elk",
        "oracle_hash": "hash-gang-of-elk",
        "logical_rule_key": "battle_rule_v1:hash-gang-of-elk",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_becomes_blocked_self_boost_until_eot_v1",
            "trigger": "becomes_blocked",
            "trigger_effect": "self_stat_modifier_until_eot",
            "power_delta": 2,
            "toughness_delta": 2,
            "blocker_count_mode": "per_blocker",
        },
    }

    scenario = builder.becomes_blocked_self_boost_execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "becomes_blocked_self_boost"
    assert scenario["card"]["name"] == "Gang of Elk"
    assert scenario["expected_base_power_delta"] == 2
    assert scenario["expected_base_toughness_delta"] == 2
    assert scenario["expected_blocker_count_mode"] == "per_blocker"
    assert scenario["blocker_count"] == 3


def test_manifest_builds_single_target_exile_execution_scenario() -> None:
    rule = {
        "normalized_name": "radiant purge",
        "card_name": "Radiant Purge",
        "oracle_hash": "hash-radiant-purge",
        "logical_rule_key": "battle_rule_v1:hash-radiant-purge",
        "required_effect_fields": {
            "effect": "remove_permanent",
            "battle_model_scope": "xmage_exile_target_spell_v1",
            "target": "permanent",
            "target_constraints": {"card_types": ["creature", "enchantment"], "color_count_min": 2},
            "destination": "exile",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal"
    assert scenario["expected_effect"] == "remove_permanent"
    assert scenario["expected_destination"] == "exile"
    assert scenario["target"]["colors"] == ["W", "U"]
    assert scenario["nonmatching_target"]["colors"] == ["W"]


def test_single_target_removal_scenario_uses_illegal_fixture_for_simple_creature_target() -> None:
    rule = {
        "normalized_name": "oblivion strike",
        "card_name": "Oblivion Strike",
        "oracle_hash": "hash-oblivion-strike",
        "logical_rule_key": "battle_rule_v1:hash-oblivion-strike",
        "required_effect_fields": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_exile_target_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "destination": "exile",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["target"]["type_line"].startswith("Creature")
    assert scenario["nonmatching_target"]["type_line"] == "Land"


def test_manifest_builds_single_target_exile_draw_execution_scenario() -> None:
    rule = {
        "normalized_name": "second thoughts",
        "card_name": "Second Thoughts",
        "oracle_hash": "hash-second-thoughts",
        "logical_rule_key": "battle_rule_v1:hash-second-thoughts",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal_and_draw"
    assert scenario["expected_destination"] == "exile"
    assert scenario["expected_draw_count"] == 1
    assert scenario["target"]["attacking"] is True
    assert scenario["nonmatching_target"].get("attacking") is not True


def test_manifest_builds_graveyard_exile_draw_execution_scenario() -> None:
    rule = {
        "normalized_name": "cremate",
        "card_name": "Cremate",
        "oracle_hash": "hash-cremate",
        "logical_rule_key": "battle_rule_v1:hash-cremate",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal_and_draw"
    assert scenario["target_zone"] == "graveyard"
    assert scenario["expected_effect"] == "graveyard_exile"
    assert scenario["expected_destination"] == "exile"
    assert scenario["expected_draw_count"] == 1
    assert scenario["target"]["type_line"] == "Instant"


def test_single_target_bounce_scenario_moves_target_to_hand() -> None:
    rule = {
        "normalized_name": "cut the earthly bond",
        "card_name": "Cut the Earthly Bond",
        "oracle_hash": "hash-cut-the-earthly-bond",
        "logical_rule_key": "battle_rule_v1:hash-cut-the-earthly-bond",
        "required_effect_fields": {
            "effect": "remove_permanent",
            "battle_model_scope": "xmage_return_target_to_hand_spell_v1",
            "target": "enchanted_permanent",
            "target_constraints": {"card_types": ["permanent"], "enchanted": True},
            "destination": "hand",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal"
    assert scenario["expected_destination"] == "hand"
    assert scenario["target"]["enchanted"] is True
    assert scenario["nonmatching_target"].get("enchanted") is False


def test_damage_prevention_scenario_uses_matching_and_nonmatching_sources() -> None:
    rule = {
        "normalized_name": "hunter's ambush",
        "card_name": "Hunter's Ambush",
        "oracle_hash": "hash-hunters-ambush",
        "logical_rule_key": "battle_rule_v1:hash-hunters-ambush",
        "required_effect_fields": {
            "effect": "damage_prevention_shield",
            "battle_model_scope": "xmage_prevent_damage_from_creatures_spell_v1",
            "prevent_damage_from_creature_sources_this_turn": True,
            "prevent_damage_scope": "combat_damage_from_creatures",
            "prevent_damage_kind": "combat_damage",
            "prevent_damage_duration": "until_end_of_turn",
            "prevent_source_constraints": {
                "card_types": ["creature"],
                "exclude_colors": ["G"],
            },
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "damage_prevention"
    assert scenario["matching_source"]["type_line"].startswith("Creature")
    assert scenario["matching_source"]["colors"] == ["R"]
    assert scenario["nonmatching_source"]["colors"] == ["G"]
    assert scenario["expected_prevent_damage_kind"] == "combat_damage"


def test_single_target_removal_and_surveil_scenario_exercises_surveillance() -> None:
    rule = {
        "normalized_name": "deadly visit",
        "card_name": "Deadly Visit",
        "oracle_hash": "hash-deadly-visit",
        "logical_rule_key": "battle_rule_v1:hash-deadly-visit",
        "required_effect_fields": {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_destroy_target_and_surveil_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "destination": "graveyard",
            "surveil_count": 2,
            "_composite_rule_components": [
                {
                    "effect": "remove_creature",
                    "battle_model_scope": "xmage_destroy_target_spell_v1",
                    "target": "creature",
                    "target_constraints": {"card_types": ["creature"]},
                    "destination": "graveyard",
                },
                {
                    "effect": "surveil",
                    "battle_model_scope": "xmage_fixed_surveil_spell_v1",
                    "count": 2,
                    "surveil_count": 2,
                },
            ],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal_and_surveil"
    assert scenario["expected_effect"] == "remove_creature"
    assert scenario["expected_surveil_count"] == 2
    assert scenario["target"]["type_line"].startswith("Creature")
    assert scenario["nonmatching_target"]["type_line"] == "Land"
    assert len(scenario["library"]) == 3
    assert len(scenario["player_battlefield"]) == 4


def test_multi_target_removal_scenario_uses_declared_target_count() -> None:
    rule = {
        "normalized_name": "into the void",
        "card_name": "Into the Void",
        "oracle_hash": "hash-into-the-void",
        "logical_rule_key": "battle_rule_v1:hash-into-the-void",
        "required_effect_fields": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_return_target_to_hand_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "destination": "hand",
            "target_count_min": 0,
            "target_count_max": 2,
            "max_targets": 2,
            "up_to_count": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "multi_target_removal"
    assert scenario["expected_destination"] == "hand"
    assert scenario["expected_target_count"] == 2
    assert len(scenario["targets"]) == 2
    assert builder.single_target_removal_execution_scenario_from_expected_rule(rule) is None


def test_destroy_gain_life_scenario_carries_controller_life_gain() -> None:
    rule = {
        "normalized_name": "divine offering fixture",
        "card_name": "Divine Offering Fixture",
        "oracle_hash": "hash-divine-offering-fixture",
        "logical_rule_key": "battle_rule_v1:hash-divine-offering-fixture",
        "required_effect_fields": {
            "effect": "remove_permanent",
            "battle_model_scope": "xmage_destroy_target_and_controller_gain_life_spell_v1",
            "target": "artifact_or_enchantment",
            "target_constraints": {"card_types": ["artifact", "enchantment"]},
            "destination": "graveyard",
            "controller_gains_life": 4,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal"
    assert scenario["expected_effect"] == "remove_permanent"
    assert scenario["expected_controller_life_gain"] == 4
    assert scenario["controller_life"] == 10


def test_destroy_source_controller_life_loss_scenario_carries_loss() -> None:
    rule = {
        "normalized_name": "infernal grasp fixture",
        "card_name": "Infernal Grasp Fixture",
        "oracle_hash": "hash-infernal-grasp-fixture",
        "logical_rule_key": "battle_rule_v1:hash-infernal-grasp-fixture",
        "required_effect_fields": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_and_source_controller_loses_life_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "destination": "graveyard",
            "source_controller_life_loss_on_resolve": 2,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal"
    assert scenario["expected_source_controller_life_loss"] == 2
    assert scenario["controller_life"] == 20


def test_multi_target_destroy_source_controller_life_loss_scenario_carries_loss_once() -> None:
    rule = {
        "normalized_name": "reckless spite fixture",
        "card_name": "Reckless Spite Fixture",
        "oracle_hash": "hash-reckless-spite-fixture",
        "logical_rule_key": "battle_rule_v1:hash-reckless-spite-fixture",
        "required_effect_fields": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_and_source_controller_loses_life_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "exclude_colors": ["B"]},
            "destination": "graveyard",
            "target_count_min": 2,
            "target_count_max": 2,
            "max_targets": 2,
            "source_controller_life_loss_on_resolve": 5,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "multi_target_removal"
    assert scenario["expected_source_controller_life_loss"] == 5
    assert scenario["controller_life"] == 20
    assert len(scenario["targets"]) == 2


def test_destroy_source_controller_damage_scenario_carries_damage() -> None:
    rule = {
        "normalized_name": "aftershock fixture",
        "card_name": "Aftershock Fixture",
        "oracle_hash": "hash-aftershock-fixture",
        "logical_rule_key": "battle_rule_v1:hash-aftershock-fixture",
        "required_effect_fields": {
            "effect": "remove_permanent",
            "battle_model_scope": "xmage_destroy_target_and_source_controller_damage_spell_v1",
            "target": "artifact_creature_or_land",
            "target_constraints": {"card_types": ["artifact", "creature", "land"]},
            "destination": "graveyard",
            "source_controller_damage_on_resolve": 3,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal"
    assert scenario["expected_source_controller_damage"] == 3
    assert scenario["controller_life"] == 20


def test_destroy_target_controller_damage_scenario_carries_damage() -> None:
    rule = {
        "normalized_name": "peak eruption fixture",
        "card_name": "Peak Eruption Fixture",
        "oracle_hash": "hash-peak-eruption-fixture",
        "logical_rule_key": "battle_rule_v1:hash-peak-eruption-fixture",
        "required_effect_fields": {
            "effect": "remove_permanent",
            "battle_model_scope": "xmage_destroy_target_and_target_controller_damage_spell_v1",
            "target": "land",
            "target_constraints": {"card_types": ["land"], "required_subtypes": ["mountain"]},
            "destination": "graveyard",
            "target_controller_damage_on_resolve": 3,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal"
    assert scenario["expected_target_controller_damage"] == 3
    assert scenario["target_controller_life"] == 20
    assert scenario["target"]["subtypes"] == ["mountain"]
    assert "mountain" not in scenario["nonmatching_target"].get("subtypes", [])
    assert scenario["nonmatching_target"]["type_line"].startswith("Land")


def test_multi_target_damage_scenario_exercises_divided_damage() -> None:
    rule = {
        "normalized_name": "arc lightning",
        "card_name": "Arc Lightning",
        "oracle_hash": "hash-arc-lightning",
        "logical_rule_key": "battle_rule_v1:hash-arc-lightning",
        "required_effect_fields": {
            "effect": "multi_target_damage",
            "battle_model_scope": "xmage_fixed_multi_target_damage_spell_v1",
            "amount": 3,
            "damage": 3,
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "target_count_min": 1,
            "target_count_max": 3,
            "max_targets": 3,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "multi_target_damage"
    assert scenario["expected_total_damage"] == 3
    assert scenario["expected_target_count"] == 3
    assert len(scenario["targets"]) == 3


def test_multi_target_damage_scenario_exercises_each_target_damage() -> None:
    proposal = {
        "normalized_name": "swelter",
        "card_name": "Swelter",
        "oracle_hash": "hash-swelter",
        "logical_rule_key": "battle_rule_v1:hash-swelter",
        "effect_json": {
            "effect": "multi_target_damage",
            "battle_model_scope": "xmage_fixed_damage_each_target_spell_v1",
            "amount": 2,
            "damage": 2,
            "damage_per_target": 2,
            "damage_assignment_mode": "each_target",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_count_min": 2,
            "target_count_max": 2,
            "max_targets": 2,
            "divided_damage": False,
        },
    }

    rule = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert rule["required_effect_fields"]["damage_assignment_mode"] == "each_target"
    assert rule["required_effect_fields"]["damage_per_target"] == 2
    assert scenario is not None
    assert scenario["type"] == "multi_target_damage"
    assert scenario["name"] == "Swelter deals 2 damage to each target"
    assert scenario["expected_total_damage"] == 4
    assert scenario["expected_target_count"] == 2
    assert len(scenario["targets"]) == 2


def test_multi_target_damage_scenario_keeps_one_damage_each_target() -> None:
    proposal = {
        "normalized_name": "dual shot",
        "card_name": "Dual Shot",
        "oracle_hash": "hash-dual-shot",
        "logical_rule_key": "battle_rule_v1:hash-dual-shot",
        "effect_json": {
            "effect": "multi_target_damage",
            "battle_model_scope": "xmage_fixed_damage_each_target_spell_v1",
            "amount": 1,
            "damage": 1,
            "damage_per_target": 1,
            "damage_assignment_mode": "each_target",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "target_count_min": 0,
            "target_count_max": 2,
            "max_targets": 2,
            "up_to_count": True,
            "divided_damage": False,
        },
    }

    rule = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["name"] == "Dual Shot deals 1 damage to each target"
    assert scenario["expected_total_damage"] == 2
    assert scenario["expected_target_count"] == 2


def test_single_target_removal_scenario_models_excluded_color_and_combat_state() -> None:
    rule = {
        "normalized_name": "assassins blade",
        "card_name": "Assassin's Blade",
        "oracle_hash": "hash-assassins-blade",
        "logical_rule_key": "battle_rule_v1:hash-assassins-blade",
        "required_effect_fields": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {
                "card_types": ["creature"],
                "combat_state": "attacking",
                "exclude_colors": ["B"],
            },
            "destination": "graveyard",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal"
    assert scenario["target"]["attacking"] is True
    assert scenario["target"]["colors"] == ["W"]
    assert scenario["nonmatching_target"]["colors"] == ["B"]


def test_single_target_removal_scenario_models_blocked_creature_state() -> None:
    rule = {
        "normalized_name": "smite",
        "card_name": "Smite",
        "oracle_hash": "hash-smite",
        "logical_rule_key": "battle_rule_v1:hash-smite",
        "required_effect_fields": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "combat_state": "blocked"},
            "destination": "graveyard",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal"
    assert scenario["target"]["blocked"] is True
    assert not scenario["nonmatching_target"].get("blocked")


def test_single_target_removal_scenario_models_excluded_keyword() -> None:
    rule = {
        "normalized_name": "pitfall trap",
        "card_name": "Pitfall Trap",
        "oracle_hash": "hash-pitfall-trap",
        "logical_rule_key": "battle_rule_v1:hash-pitfall-trap",
        "required_effect_fields": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {
                "card_types": ["creature"],
                "combat_state": "attacking",
                "exclude_keywords": ["flying"],
            },
            "destination": "graveyard",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["type"] == "single_target_removal"
    assert scenario["target"]["attacking"] is True
    assert "keywords" not in scenario["target"]
    assert scenario["nonmatching_target"]["keywords"] == ["flying"]


def test_single_target_removal_scenario_models_excluded_card_type() -> None:
    rule = {
        "normalized_name": "expunge",
        "card_name": "Expunge",
        "oracle_hash": "hash-expunge",
        "logical_rule_key": "battle_rule_v1:hash-expunge",
        "required_effect_fields": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {
                "card_types": ["creature"],
                "exclude_card_types": ["artifact"],
                "exclude_colors": ["B"],
            },
            "destination": "graveyard",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario is not None
    assert scenario["target"]["type_line"].startswith("Creature")
    assert scenario["target"]["colors"] == ["W"]
    assert "Artifact Creature" in scenario["nonmatching_target"]["type_line"]
    assert scenario["nonmatching_target"]["colors"] == ["B"]


def test_manifest_expected_rule_preserves_spell_additional_sacrifice_cost_fields() -> None:
    proposal = {
        "normalized_name": "bone splinters",
        "card_name": "Bone Splinters",
        "oracle_hash": "hash-bone-splinters",
        "logical_rule_key": "battle_rule_v1:hash-bone-splinters",
        "effect_json": {
            "effect": "remove_creature",
            "battle_model_scope": "xmage_destroy_target_spell_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "destination": "graveyard",
            "additional_cost": "sacrifice_creature",
            "requires_sacrifice_creature": True,
            "xmage_additional_cost_class": "SacrificeTargetCost",
            "xmage_additional_cost_target": "creature",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"]["additional_cost"] == "sacrifice_creature"
    assert expected["required_effect_fields"]["requires_sacrifice_creature"] is True
    assert expected["required_effect_fields"]["xmage_additional_cost_class"] == "SacrificeTargetCost"
    assert expected["required_effect_fields"]["xmage_additional_cost_target"] == "creature"


def test_manifest_expected_rule_preserves_extended_board_wipe_fields() -> None:
    proposal = {
        "normalized_name": "planar cleansing",
        "card_name": "Planar Cleansing",
        "oracle_hash": "hash-planar-cleansing",
        "logical_rule_key": "battle_rule_v1:hash-planar-cleansing",
        "effect_json": {
            "effect": "board_wipe",
            "battle_model_scope": "xmage_destroy_all_matching_permanents_spell_v1",
            "destroy_card_types": ["permanent"],
            "destroy_controller": "opponents_control",
            "destroy_required_colors": ["W"],
            "destroy_excluded_colors": ["G"],
            "destroy_required_subtypes": ["plains"],
            "destroy_excluded_subtypes": ["aura"],
            "destroy_exclude_card_types": ["land"],
            "destroy_tapped_state": "tapped",
            "destroy_nonbasic_lands": True,
            "destroy_mana_value_lte": 3,
            "destroy_mana_value_lte_source": "x_value",
            "destroy_power_gte": 4,
            "destroy_toughness_gte": 4,
            "destroy_counter_state": "none",
            "destroy_combat_state": "blocking_or_blocked",
            "destroy_color_count_lt": 5,
            "destroy_dealt_damage_to_you_this_turn": True,
            "destroy_exclude_commanders": True,
            "destroy_enchanted_state": "not_enchanted",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["destroy_card_types"] == ["permanent"]
    assert required["destroy_controller"] == "opponents_control"
    assert required["destroy_required_colors"] == ["W"]
    assert required["destroy_excluded_colors"] == ["G"]
    assert required["destroy_required_subtypes"] == ["plains"]
    assert required["destroy_excluded_subtypes"] == ["aura"]
    assert required["destroy_exclude_card_types"] == ["land"]
    assert required["destroy_tapped_state"] == "tapped"
    assert required["destroy_nonbasic_lands"] is True
    assert required["destroy_mana_value_lte"] == 3
    assert required["destroy_mana_value_lte_source"] == "x_value"
    assert required["destroy_power_gte"] == 4
    assert required["destroy_toughness_gte"] == 4
    assert required["destroy_counter_state"] == "none"
    assert required["destroy_combat_state"] == "blocking_or_blocked"
    assert required["destroy_color_count_lt"] == 5
    assert required["destroy_dealt_damage_to_you_this_turn"] is True
    assert required["destroy_exclude_commanders"] is True
    assert required["destroy_enchanted_state"] == "not_enchanted"

    proposal["effect_json"] = {
        "effect": "damage_wipe",
        "battle_model_scope": "xmage_fixed_damage_all_matching_permanents_spell_v1",
        "amount": 2,
        "damage": 2,
        "damage_scope": "each_nonartifact_creature",
    }
    expected = builder.expected_rule_from_proposal(proposal)
    assert expected["required_effect_fields"]["damage_scope"] == "each_nonartifact_creature"


def test_board_wipe_execution_scenario_preserves_destroy_filters() -> None:
    proposal = {
        "normalized_name": "consume the meek",
        "card_name": "Consume the Meek",
        "oracle_hash": "hash-consume-the-meek",
        "logical_rule_key": "battle_rule_v1:consume-the-meek",
        "effect_json": {
            "effect": "board_wipe",
            "battle_model_scope": "xmage_destroy_all_matching_permanents_spell_v1",
            "destroy_card_types": ["creature"],
            "destroy_mana_value_lte": 3,
            "destroy_mana_value_lte_source": "x_value",
            "destroy_counter_state": "none",
            "destroy_exclude_commanders": True,
            "destination": "graveyard",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "board_wipe"
    assert scenario["destroy_card_types"] == ["creature"]
    assert scenario["destroy_mana_value_lte"] == 3
    assert scenario["destroy_mana_value_lte_source"] == "x_value"
    assert scenario["x_value"] == 3
    assert scenario["destroy_counter_state"] == "none"
    assert scenario["destroy_exclude_commanders"] is True


def test_damage_wipe_execution_scenario_preserves_damage_players() -> None:
    proposal = {
        "normalized_name": "rain of embers",
        "card_name": "Rain of Embers",
        "oracle_hash": "hash-rain-of-embers",
        "logical_rule_key": "battle_rule_v1:rain-of-embers",
        "effect_json": {
            "effect": "damage_wipe",
            "battle_model_scope": "xmage_fixed_damage_each_creature_each_player_spell_v1",
            "amount": 1,
            "damage": 1,
            "damage_scope": "each_creature",
            "damage_players": True,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert expected["required_effect_fields"]["damage_players"] is True
    assert scenario["type"] == "damage_wipe"
    assert scenario["expected_damage"] == 1
    assert scenario["expected_damage_scope"] == "each_creature"
    assert scenario["expected_damage_players"] is True


def test_mass_return_to_hand_fields_and_execution_scenario_are_manifested() -> None:
    proposal = {
        "normalized_name": "aetherize",
        "card_name": "Aetherize",
        "oracle_hash": "hash-aetherize",
        "logical_rule_key": "battle_rule_v1:aetherize",
        "effect_json": {
            "effect": "mass_return_to_hand",
            "battle_model_scope": "xmage_return_all_matching_permanents_to_hand_spell_v1",
            "return_card_types": ["creature"],
            "return_controller": "any",
            "return_combat_state": "attacking",
            "destination": "hand",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    required = expected["required_effect_fields"]
    assert required["return_card_types"] == ["creature"]
    assert required["return_controller"] == "any"
    assert required["return_combat_state"] == "attacking"
    assert scenario["type"] == "mass_return_to_hand"
    assert scenario["return_card_types"] == ["creature"]
    assert scenario["return_combat_state"] == "attacking"


def test_manifest_expected_rule_preserves_dynamic_graveyard_damage_fields() -> None:
    proposal = {
        "normalized_name": "kindle",
        "card_name": "Kindle",
        "oracle_hash": "hash-kindle",
        "logical_rule_key": "battle_rule_v1:hash-kindle",
        "effect_json": {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_dynamic_graveyard_count_damage_spell_v1",
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "damage": 0,
            "damage_amount_source": "graveyard_card_count",
            "damage_base_amount": 2,
            "damage_per_graveyard_count": 1,
            "graveyard_count_scope": "all_graveyards",
            "graveyard_count_card_names": ["Kindle"],
            "graveyard_count_subtypes": ["arcane"],
            "graveyard_count_card_types": ["instant"],
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["damage_amount_source"] == "graveyard_card_count"
    assert required["damage_base_amount"] == 2
    assert required["damage_per_graveyard_count"] == 1
    assert required["graveyard_count_scope"] == "all_graveyards"
    assert required["graveyard_count_card_names"] == ["Kindle"]
    assert required["graveyard_count_subtypes"] == ["arcane"]
    assert required["graveyard_count_card_types"] == ["instant"]


def test_manifest_expected_rule_preserves_composite_damage_draw_components() -> None:
    components = [
        {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_fixed_damage_target_spell_v1",
            "amount": 3,
            "damage": 3,
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "compose_on_resolution": True,
            "xmage_effect_class": "DamageTargetEffect",
        },
        {
            "effect": "draw_cards",
            "battle_model_scope": "xmage_fixed_source_controller_draw_spell_v1",
            "count": 1,
            "compose_on_resolution": True,
            "xmage_effect_class": "DrawCardSourceControllerEffect",
        },
    ]
    proposal = {
        "normalized_name": "ember shot",
        "card_name": "Ember Shot",
        "oracle_hash": "hash-ember-shot",
        "logical_rule_key": "battle_rule_v1:hash-ember-shot",
        "effect_json": {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_fixed_damage_target_and_draw_card_spell_v1",
            "amount": 3,
            "damage": 3,
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
            "draw_count": 1,
            "count": 1,
            "_composite_rule_components": components,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["effect"] == "composite_resolution"
    assert required["battle_model_scope"] == "xmage_fixed_damage_target_and_draw_card_spell_v1"
    assert required["_composite_rule_components"] == components


def test_manifest_expected_rule_preserves_zero_amount_for_x_damage() -> None:
    proposal = {
        "normalized_name": "blaze",
        "card_name": "Blaze",
        "oracle_hash": "hash-blaze",
        "logical_rule_key": "battle_rule_v1:hash-blaze",
        "effect_json": {
            "effect": "direct_damage",
            "battle_model_scope": "xmage_x_damage_target_spell_v1",
            "amount": 0,
            "damage": 0,
            "damage_amount_source": "x_value",
            "target": "any_target",
            "target_constraints": {"scope": "any_target"},
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["amount"] == 0
    assert required["damage"] == 0
    assert required["damage_amount_source"] == "x_value"


def test_apply_sql_preserves_existing_backup_table_for_idempotent_rerun() -> None:
    proposal = {
        "normalized_name": "quarry beetle",
        "card_name": "Quarry Beetle",
        "oracle_hash": "hash-quarry",
        "logical_rule_key": "battle_rule_v1:hash-quarry",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_return_graveyard_card_to_battlefield_v1",
            "etb_recursion_target": "land",
            "etb_recursion_destination": "battlefield",
        },
        "deck_role_json": {"category": "unknown", "effect": "creature"},
        "source": "curated",
        "confidence": 0.96,
        "review_status": "verified",
        "execution_status": "auto",
        "notes": "fixture",
    }

    sql = builder.build_apply_sql([proposal], "pg_fixture_backup")

    assert "CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg_fixture_backup AS" in sql
    assert "DROP TABLE" not in sql


def test_safe_ident_preserves_timestamp_suffix_when_truncated() -> None:
    ident = builder.safe_ident("PG485_activated_damage_discard_cost_new_server_20260705_055236")

    assert len(ident) <= 56
    assert ident.endswith("20260705_055236")


def test_existing_backup_table_from_manifest_ignores_truncated_timestamp(tmp_path) -> None:
    manifest = tmp_path / "manifest.json"
    manifest.write_text(
        '{"backup_table":"manaloom_deploy_audit.pg485_activated_damage_discard_cost_new_server_20260705_"}',
        encoding="utf-8",
    )

    assert builder.existing_backup_table_from_manifest(manifest) is None

    manifest.write_text(
        '{"backup_table":"manaloom_deploy_audit.pg485_activated_damage_20260705_055236"}',
        encoding="utf-8",
    )

    assert builder.existing_backup_table_from_manifest(manifest) == "pg485_activated_damage_20260705_055236"


def test_manifest_expected_rule_preserves_contextual_mana_source_field() -> None:
    proposal = {
        "normalized_name": "wild cantor",
        "card_name": "Wild Cantor",
        "oracle_hash": "hash-contextual-mana",
        "logical_rule_key": "battle_rule_v1:hash-contextual-mana",
        "effect_json": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_self_sacrifice_mana_source_permanent_v1",
            "ability_kind": "activated_mana",
            "is_mana_source": True,
            "mana_source_contextual_only": True,
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": False,
            "activation_requires_tap": False,
            "activation_requires_sacrifice": True,
            "permanent_type": "creature",
            "xmage_ability_class": "AnyColorManaAbility",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "ramp_permanent",
        "battle_model_scope": "xmage_self_sacrifice_mana_source_permanent_v1",
        "ability_kind": "activated_mana",
        "is_mana_source": True,
        "mana_source_contextual_only": True,
        "mana_produced": 1,
        "produces": "WUBRG",
        "mana_activation_requires_tap": False,
        "activation_requires_tap": False,
        "activation_requires_sacrifice": True,
        "permanent_type": "creature",
        "xmage_ability_class": "AnyColorManaAbility",
    }


def test_manifest_expected_rule_preserves_tap_and_sacrifice_mana_fields() -> None:
    proposal = {
        "normalized_name": "eye of ramos",
        "card_name": "Eye of Ramos",
        "oracle_hash": "hash-ramos",
        "logical_rule_key": "battle_rule_v1:hash-ramos",
        "effect_json": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_tap_and_self_sacrifice_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "U",
            "produced_mana_symbols": ["U"],
            "mana_activation_requires_tap": True,
            "sacrifice_mana_source_contextual_only": True,
            "sacrifice_mana_produced": 1,
            "sacrifice_produces": "U",
            "sacrifice_produced_mana_symbols": ["U"],
            "sacrifice_mana_activation_requires_tap": False,
            "sacrifice_activation_requires_tap": False,
            "sacrifice_mana_activation_requires_sacrifice": True,
            "sacrifice_activation_requires_sacrifice": True,
            "permanent_type": "artifact",
            "ability_kind": "mana_and_sacrifice_mana",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "ramp_permanent",
        "battle_model_scope": "xmage_tap_and_self_sacrifice_mana_source_permanent_v1",
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "U",
        "produced_mana_symbols": ["U"],
        "mana_activation_requires_tap": True,
        "sacrifice_mana_source_contextual_only": True,
        "sacrifice_mana_produced": 1,
        "sacrifice_produces": "U",
        "sacrifice_produced_mana_symbols": ["U"],
        "sacrifice_mana_activation_requires_tap": False,
        "sacrifice_activation_requires_tap": False,
        "sacrifice_mana_activation_requires_sacrifice": True,
        "sacrifice_activation_requires_sacrifice": True,
        "permanent_type": "artifact",
        "ability_kind": "mana_and_sacrifice_mana",
    }


def test_manifest_expected_rule_preserves_dies_mana_fields() -> None:
    proposal = {
        "normalized_name": "cathodion",
        "card_name": "Cathodion",
        "oracle_hash": "hash-cathodion",
        "logical_rule_key": "battle_rule_v1:hash-cathodion",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_dies_add_fixed_mana_v1",
            "ability_kind": "triggered",
            "trigger": "dies",
            "trigger_effect": "add_mana",
            "permanent_type": "artifact_creature",
            "dies_mana_produced": 3,
            "dies_produces": "C",
            "dies_produced_mana_symbols": ["C", "C", "C"],
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "creature",
        "battle_model_scope": "xmage_permanent_dies_add_fixed_mana_v1",
        "ability_kind": "triggered",
        "trigger": "dies",
        "trigger_effect": "add_mana",
        "permanent_type": "artifact_creature",
        "dies_mana_produced": 3,
        "dies_produces": "C",
        "dies_produced_mana_symbols": ["C", "C", "C"],
    }


def test_manifest_expected_rule_preserves_etb_mana_condition_fields() -> None:
    proposal = {
        "normalized_name": "coal stoker",
        "card_name": "Coal Stoker",
        "oracle_hash": "hash-coal-stoker",
        "logical_rule_key": "battle_rule_v1:coal-stoker",
        "effect_json": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_creature_etb_add_fixed_mana_v1",
            "ability_kind": "triggered",
            "trigger": "enters_battlefield",
            "trigger_effect": "add_mana",
            "permanent_type": "creature",
            "etb_mana_produced": 3,
            "etb_produces": "R",
            "etb_produced_mana_symbols": ["R", "R", "R"],
            "etb_mana_condition": "cast_from_hand",
            "mana_produced": 3,
            "produces": "R",
            "produced_mana_symbols": ["R", "R", "R"],
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "ramp_permanent",
        "battle_model_scope": "xmage_creature_etb_add_fixed_mana_v1",
        "ability_kind": "triggered",
        "permanent_type": "creature",
        "etb_mana_produced": 3,
        "etb_produces": "R",
        "etb_produced_mana_symbols": ["R", "R", "R"],
        "etb_mana_condition": "cast_from_hand",
        "mana_produced": 3,
        "produces": "R",
        "produced_mana_symbols": ["R", "R", "R"],
        "trigger": "enters_battlefield",
        "trigger_effect": "add_mana",
    }


def test_execution_scenario_includes_creature_etb_fixed_mana_condition() -> None:
    rule = {
        "normalized_name": "coal stoker",
        "card_name": "Coal Stoker",
        "logical_rule_key": "battle_rule_v1:coal-stoker",
        "required_effect_fields": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_creature_etb_add_fixed_mana_v1",
            "etb_mana_produced": 3,
            "etb_produces": "R",
            "etb_produced_mana_symbols": ["R", "R", "R"],
            "etb_mana_condition": "cast_from_hand",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario == {
        "name": "Coal Stoker ETB adds fixed mana",
        "type": "creature_etb_fixed_mana",
        "card": {
            "name": "Coal Stoker",
            "type_line": "Creature - Elemental",
            "effect": "ramp_permanent",
        },
        "was_cast": True,
        "cast_from_zone": "hand",
        "expected_mana_added": 3,
        "expected_produced_mana_symbols": ["R", "R", "R"],
        "expected_condition": "cast_from_hand",
        "logical_rule_key": "battle_rule_v1:coal-stoker",
    }


def test_manifest_expected_rule_preserves_aura_static_power_toughness_fields() -> None:
    proposal = {
        "normalized_name": "dead weight",
        "card_name": "Dead Weight",
        "oracle_hash": "hash-dead-weight",
        "logical_rule_key": "battle_rule_v1:dead-weight",
        "effect_json": {
            "effect": "aura_static_attachment",
            "battle_model_scope": "xmage_aura_static_power_toughness_attachment_v1",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"], "zone": "battlefield"},
            "enchant_target": "creature",
            "enchant_target_controller": "any",
            "power_boost": -2,
            "toughness_boost": -2,
            "static_power_bonus": -2,
            "static_toughness_bonus": -2,
            "aura": True,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "aura_static_attachment",
        "battle_model_scope": "xmage_aura_static_power_toughness_attachment_v1",
        "target": "creature",
        "target_constraints": {"card_types": ["creature"], "zone": "battlefield"},
        "enchant_target": "creature",
        "enchant_target_controller": "any",
        "static_power_bonus": -2,
        "static_toughness_bonus": -2,
        "power_boost": -2,
        "toughness_boost": -2,
    }


def test_equipment_static_attachment_execution_scenario_preserves_keywords() -> None:
    proposal = {
        "normalized_name": "maul of the skyclaves",
        "card_name": "Maul of the Skyclaves",
        "oracle_hash": "hash-maul",
        "logical_rule_key": "battle_rule_v1:maul-of-the-skyclaves",
        "effect_json": {
            "effect": "equipment_static_attachment",
            "battle_model_scope": "xmage_equipment_static_power_toughness_attachment_v1",
            "target": "creature_you_control",
            "target_constraints": {"card_types": ["creature"], "controller": "self", "zone": "battlefield"},
            "power_boost": 2,
            "toughness_boost": 2,
            "static_power_bonus": 2,
            "static_toughness_bonus": 2,
            "attached_keywords": ["first_strike", "flying"],
            "grants_first_strike": True,
            "grants_flying": True,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert expected["required_effect_fields"]["attached_keywords"] == ["first_strike", "flying"]
    assert expected["required_effect_fields"]["grants_first_strike"] is True
    assert expected["required_effect_fields"]["grants_flying"] is True
    assert scenario == {
        "name": "Maul of the Skyclaves equipment static P/T attaches",
        "type": "equipment_static_power_toughness_attachment",
        "card": {"name": "Maul of the Skyclaves", "type_line": "Artifact - Equipment"},
        "target": {
            "name": "E2E Equipment Target for Maul of the Skyclaves",
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
    }


def test_manifest_expected_rule_preserves_static_controlled_keyword_fields() -> None:
    proposal = {
        "normalized_name": "groundshaker sliver",
        "card_name": "Groundshaker Sliver",
        "oracle_hash": "hash-groundshaker",
        "logical_rule_key": "battle_rule_v1:groundshaker-sliver",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_static_controlled_keyword_grant_v1",
            "static_effect": "controlled_keyword_grant",
            "static_applies_to": "creatures_you_control",
            "static_granted_keywords": ["trample"],
            "static_required_subtypes": ["sliver"],
            "static_exclude_source": False,
            "target": "controlled_creatures",
            "target_controller": "self",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "creature",
        "battle_model_scope": "xmage_static_controlled_keyword_grant_v1",
        "target": "controlled_creatures",
        "target_controller": "self",
        "static_effect": "controlled_keyword_grant",
        "static_applies_to": "creatures_you_control",
        "static_exclude_source": False,
        "static_granted_keywords": ["trample"],
        "static_required_subtypes": ["sliver"],
    }


def test_manifest_expected_rule_preserves_static_controlled_pt_filtered_fields() -> None:
    proposal = {
        "normalized_name": "dire fleet neckbreaker",
        "card_name": "Dire Fleet Neckbreaker",
        "oracle_hash": "hash-neckbreaker",
        "logical_rule_key": "battle_rule_v1:dire-fleet-neckbreaker",
        "effect_json": {
            "effect": "creature",
            "battle_model_scope": "xmage_static_controlled_power_toughness_boost_v1",
            "static_effect": "controlled_power_toughness_boost",
            "static_applies_to": "creatures_you_control",
            "static_power_bonus": 2,
            "static_toughness_bonus": 0,
            "static_required_subtypes": ["pirate"],
            "static_required_combat_state": "attacking",
            "static_exclude_source": False,
            "target": "controlled_creatures",
            "target_controller": "self",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    assert expected["required_effect_fields"] == {
        "effect": "creature",
        "battle_model_scope": "xmage_static_controlled_power_toughness_boost_v1",
        "target": "controlled_creatures",
        "target_controller": "self",
        "static_effect": "controlled_power_toughness_boost",
        "static_applies_to": "creatures_you_control",
        "static_power_bonus": 2,
        "static_toughness_bonus": 0,
        "static_exclude_source": False,
        "static_required_subtypes": ["pirate"],
        "static_required_combat_state": "attacking",
    }


def test_static_controlled_pt_execution_scenario_uses_filter_negative_and_opponent() -> None:
    rule = {
        "normalized_name": "builder's blessing",
        "card_name": "Builder's Blessing",
        "logical_rule_key": "battle_rule_v1:builders-blessing",
        "required_effect_fields": {
            "effect": "passive",
            "battle_model_scope": "xmage_static_controlled_power_toughness_boost_v1",
            "static_effect": "controlled_power_toughness_boost",
            "static_power_bonus": 0,
            "static_toughness_bonus": 2,
            "static_required_tapped_state": "untapped",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "static_controlled_power_toughness_boost"
    assert scenario["expected_power"] == 2
    assert scenario["expected_toughness"] == 4
    assert scenario["matching_target"]["tapped"] is False
    assert scenario["nonmatching_target"]["tapped"] is True
    assert scenario["opponent_target"]["tapped"] is False


def test_static_controlled_keyword_execution_scenario_uses_filter_negative_and_opponent() -> None:
    rule = {
        "normalized_name": "roughshod mentor",
        "card_name": "Roughshod Mentor",
        "logical_rule_key": "battle_rule_v1:roughshod-mentor",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_static_controlled_keyword_grant_v1",
            "static_effect": "controlled_keyword_grant",
            "static_granted_keywords": ["trample"],
            "static_required_colors": ["G"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "static_controlled_keyword"
    assert scenario["expected_keyword"] == "trample"
    assert scenario["matching_target"]["colors"] == ["G"]
    assert scenario["nonmatching_target"]["colors"] == ["U"]
    assert scenario["opponent_target"]["colors"] == ["G"]


def test_aura_static_power_toughness_execution_scenario_targets_debuff_to_opponent() -> None:
    rule = {
        "normalized_name": "dead weight",
        "card_name": "Dead Weight",
        "logical_rule_key": "battle_rule_v1:dead-weight",
        "required_effect_fields": {
            "effect": "aura_static_attachment",
            "battle_model_scope": "xmage_aura_static_power_toughness_attachment_v1",
            "enchant_target_controller": "any",
            "power_boost": -2,
            "toughness_boost": -2,
            "static_power_bonus": -2,
            "static_toughness_bonus": -2,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario == {
        "name": "Dead Weight aura static P/T attaches",
        "type": "aura_static_power_toughness_attachment",
        "card": {"name": "Dead Weight"},
        "target": {
            "name": "E2E Aura Target for Dead Weight",
            "type_line": "Creature - Soldier",
            "base_power": 2,
            "base_toughness": 2,
            "power": 2,
            "toughness": 2,
        },
        "target_owner": "opponent",
        "expected_power": 0,
        "expected_toughness": 0,
        "expected_moved_to_graveyard": True,
        "expected_source": "Dead Weight",
        "logical_rule_key": "battle_rule_v1:dead-weight",
    }


def test_aura_static_power_toughness_execution_scenario_targets_boost_to_controller() -> None:
    rule = {
        "normalized_name": "giant strength",
        "card_name": "Giant Strength",
        "logical_rule_key": "battle_rule_v1:giant-strength",
        "required_effect_fields": {
            "effect": "aura_static_attachment",
            "battle_model_scope": "xmage_aura_static_power_toughness_attachment_v1",
            "enchant_target_controller": "any",
            "power_boost": 2,
            "toughness_boost": 2,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "aura_static_power_toughness_attachment"
    assert scenario["target_owner"] == "controller"
    assert scenario["expected_power"] == 4
    assert scenario["expected_toughness"] == 4
    assert scenario["expected_moved_to_graveyard"] is False


def test_creature_etb_create_treasure_execution_scenario() -> None:
    rule = {
        "normalized_name": "prosperous pirates",
        "card_name": "Prosperous Pirates",
        "logical_rule_key": "battle_rule_v1:prosperous-pirates",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_create_treasure_v1",
            "etb_treasure_count": 2,
            "treasure_count": 2,
            "keywords": ["defender"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario == {
        "name": "Prosperous Pirates ETB creates Treasure",
        "type": "creature_etb_create_treasure",
        "card": {
            "name": "Prosperous Pirates",
            "type_line": "Creature - Pirate",
            "effect": "creature",
        },
        "expected_treasure_count": 2,
        "expected_keywords": ["defender"],
        "logical_rule_key": "battle_rule_v1:prosperous-pirates",
    }


def test_conditional_creature_etb_create_treasure_execution_scenario_sets_lands() -> None:
    rule = {
        "normalized_name": "ticket tortoise",
        "card_name": "Ticket Tortoise",
        "logical_rule_key": "battle_rule_v1:ticket-tortoise",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_create_treasure_v1",
            "etb_treasure_count": 1,
            "treasure_count": 1,
            "etb_treasure_condition": "opponent_controls_more_lands",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_etb_create_treasure"
    assert scenario["expected_condition"] == "opponent_controls_more_lands"
    assert scenario["controller_land_count"] == 1
    assert scenario["opponent_land_count"] == 2


def test_creature_etb_scry_execution_scenario() -> None:
    rule = {
        "normalized_name": "omenspeaker",
        "card_name": "Omenspeaker",
        "logical_rule_key": "battle_rule_v1:omenspeaker",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_scry_v1",
            "trigger": "enters_battlefield",
            "etb_trigger_effect": "scry",
            "etb_scry_count": 2,
            "trigger_scry_count": 2,
            "keywords": ["flying"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_etb_scry"
    assert scenario["expected_scry_count"] == 2
    assert scenario["expected_keywords"] == ["flying"]
    assert scenario["card"]["name"] == "Omenspeaker"
    assert scenario["logical_rule_key"] == "battle_rule_v1:omenspeaker"


def test_creature_etb_library_pick_bottom_execution_scenario() -> None:
    rule = {
        "normalized_name": "augur of bolas",
        "card_name": "Augur of Bolas",
        "logical_rule_key": "battle_rule_v1:augur-of-bolas",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_look_library_pick_to_hand_rest_bottom_v1",
            "trigger": "enters_battlefield",
            "etb_library_look_count": 3,
            "etb_library_pick_count": 1,
            "etb_library_pick_target": "instant_or_sorcery",
            "etb_library_rest_destination": "library_bottom",
            "etb_library_pick_up_to_count": True,
            "etb_library_bottom_order": "any",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_etb_library_pick"
    assert scenario["expected_look_count"] == 3
    assert scenario["expected_pick_target"] == "instant_or_sorcery"
    assert scenario["expected_rest_destination"] == "library_bottom"
    assert scenario["expected_picked"] == ["E2E Preferred Match"]
    assert scenario["card"]["name"] == "Augur of Bolas"
    assert scenario["logical_rule_key"] == "battle_rule_v1:augur-of-bolas"


def test_creature_dies_create_tokens_execution_scenario() -> None:
    rule = {
        "normalized_name": "carrier thrall",
        "card_name": "Carrier Thrall",
        "logical_rule_key": "battle_rule_v1:carrier-thrall",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_dies_create_tokens_v1",
            "dies_trigger_effect": "token_maker",
            "dies_token_count": 1,
            "dies_token_name": "Eldrazi Scion Token",
            "dies_token_power": 1,
            "dies_token_toughness": 1,
            "dies_token_subtype": "Eldrazi Scion",
            "dies_token_colors": [],
            "dies_token_sacrifice_for_colorless_mana": True,
            "dies_token_mana_produced": 1,
            "dies_token_produces": "C",
            "dies_token_produced_mana_symbols": ["C"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario == {
        "name": "Carrier Thrall dies and creates modeled creature tokens",
        "type": "creature_dies_create_tokens",
        "card": {
            "name": "Carrier Thrall",
            "type_line": "Creature",
            "effect": "creature",
        },
        "expected_token": {
            "name": "Eldrazi Scion Token",
            "count": 1,
            "power": 1,
            "toughness": 1,
            "subtype": "Eldrazi Scion",
            "colors": [],
            "keywords": [],
            "artifact": False,
            "artifact_only": False,
            "tapped": False,
            "sacrifice_for_colorless_mana": True,
            "mana_produced": 1,
            "produces": "C",
            "produced_mana_symbols": ["C"],
        },
        "expected_keywords": [],
        "logical_rule_key": "battle_rule_v1:carrier-thrall",
    }


def test_creature_dies_create_tokens_execution_scenario_preserves_artifact_tapped_token() -> None:
    rule = {
        "normalized_name": "gravpack monoist",
        "card_name": "Gravpack Monoist",
        "logical_rule_key": "battle_rule_v1:gravpack-monoist",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_dies_create_tokens_v1",
            "dies_trigger_effect": "token_maker",
            "dies_token_count": 1,
            "dies_token_name": "Robot Token",
            "dies_token_power": 2,
            "dies_token_toughness": 2,
            "dies_token_subtype": "Robot",
            "dies_token_colors": [],
            "dies_token_tapped": True,
            "dies_artifact_tokens": True,
            "keywords": ["flying"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_dies_create_tokens"
    assert scenario["expected_token"]["artifact"] is True
    assert scenario["expected_token"]["tapped"] is True
    assert scenario["expected_keywords"] == ["flying"]


def test_creature_etb_create_tokens_execution_scenario_preserves_noncreature_artifact_token() -> None:
    rule = {
        "normalized_name": "cartographers companion",
        "card_name": "Cartographer's Companion",
        "logical_rule_key": "battle_rule_v1:cartographers-companion",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_create_tokens_v1",
            "trigger": "enters_battlefield",
            "etb_trigger_effect": "token_maker",
            "etb_token_count": 1,
            "etb_token_name": "Map Token",
            "etb_token_subtype": "Map",
            "etb_artifact_tokens": True,
            "etb_token_artifact_only": True,
            "etb_token_activated_ability": "explore_target_creature",
            "etb_token_activated_ability_status": "created_token_only",
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_etb_create_tokens"
    assert scenario["expected_token"]["name"] == "Map Token"
    assert scenario["expected_token"]["subtype"] == "Map"
    assert scenario["expected_token"]["artifact"] is True
    assert scenario["expected_token"]["artifact_only"] is True
    assert scenario["expected_token"]["power"] is None
    assert scenario["expected_token"]["toughness"] is None


def test_creature_etb_create_multi_tokens_execution_scenario() -> None:
    rule = {
        "normalized_name": "trostanis summoner",
        "card_name": "Trostani's Summoner",
        "logical_rule_key": "battle_rule_v1:trostanis-summoner",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_create_tokens_v1",
            "trigger": "enters_battlefield",
            "etb_trigger_effect": "token_maker",
            "token_component_count": 3,
            "token_total_count": 3,
            "_composite_rule_components": [
                {
                    "effect": "token_maker",
                    "token_count": 1,
                    "token_name": "Knight Token",
                    "token_power": 2,
                    "token_toughness": 2,
                    "token_subtype": "Knight",
                    "token_colors": ["W"],
                    "token_keywords": ["vigilance"],
                },
                {
                    "effect": "token_maker",
                    "token_count": 1,
                    "token_name": "Centaur Token",
                    "token_power": 3,
                    "token_toughness": 3,
                    "token_subtype": "Centaur",
                    "token_colors": ["G"],
                },
                {
                    "effect": "token_maker",
                    "token_count": 1,
                    "token_name": "Rhino Token",
                    "token_power": 4,
                    "token_toughness": 4,
                    "token_subtype": "Rhino",
                    "token_colors": ["G"],
                    "token_keywords": ["trample"],
                },
            ],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_etb_create_tokens"
    assert scenario["expected_component_count"] == 3
    assert scenario["expected_total_tokens"] == 3
    assert [token["name"] for token in scenario["expected_tokens"]] == [
        "Knight Token",
        "Centaur Token",
        "Rhino Token",
    ]


def test_creature_etb_create_tokens_execution_scenario_preserves_static_cant_block() -> None:
    rule = {
        "normalized_name": "edgewall pack",
        "card_name": "Edgewall Pack",
        "logical_rule_key": "battle_rule_v1:edgewall-pack",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_etb_create_tokens_v1",
            "trigger": "enters_battlefield",
            "etb_trigger_effect": "token_maker",
            "etb_token_count": 1,
            "etb_token_name": "Rat Token",
            "etb_token_power": 1,
            "etb_token_toughness": 1,
            "etb_token_subtype": "Rat",
            "etb_token_colors": ["B"],
            "etb_token_cant_block": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_etb_create_tokens"
    assert scenario["expected_token"]["name"] == "Rat Token"
    assert scenario["expected_token"]["cant_block"] is True


def test_creature_dies_create_multi_tokens_execution_scenario() -> None:
    rule = {
        "normalized_name": "wurmcoil engine",
        "card_name": "Wurmcoil Engine",
        "logical_rule_key": "battle_rule_v1:wurmcoil-engine",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_dies_create_tokens_v1",
            "dies_trigger_effect": "token_maker",
            "token_component_count": 2,
            "token_total_count": 2,
            "keywords": ["deathtouch", "lifelink"],
            "_composite_rule_components": [
                {
                    "effect": "token_maker",
                    "token_count": 1,
                    "token_name": "Phyrexian Wurm Token",
                    "token_power": 3,
                    "token_toughness": 3,
                    "token_subtype": "Phyrexian Wurm",
                    "token_colors": [],
                    "token_keywords": ["deathtouch"],
                    "artifact_tokens": True,
                },
                {
                    "effect": "token_maker",
                    "token_count": 1,
                    "token_name": "Phyrexian Wurm Token",
                    "token_power": 3,
                    "token_toughness": 3,
                    "token_subtype": "Phyrexian Wurm",
                    "token_colors": [],
                    "token_keywords": ["lifelink"],
                    "artifact_tokens": True,
                },
            ],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_dies_create_tokens"
    assert scenario["expected_component_count"] == 2
    assert scenario["expected_total_tokens"] == 2
    assert scenario["expected_keywords"] == ["deathtouch", "lifelink"]
    assert [token["keywords"] for token in scenario["expected_tokens"]] == [["deathtouch"], ["lifelink"]]


def test_creature_dies_create_treasure_execution_scenario() -> None:
    rule = {
        "normalized_name": "gleaming barrier",
        "card_name": "Gleaming Barrier",
        "logical_rule_key": "battle_rule_v1:gleaming-barrier",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_dies_create_treasure_v1",
            "dies_trigger_effect": "treasure_maker",
            "dies_or_graveyard_from_battlefield_treasure": True,
            "dies_treasure_count": 1,
            "treasure_count": 1,
            "keywords": ["defender"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario == {
        "name": "Gleaming Barrier dies and creates Treasure",
        "type": "creature_dies_create_treasure",
        "card": {
            "name": "Gleaming Barrier",
            "type_line": "Creature",
            "effect": "creature",
        },
        "expected_treasure_count": 1,
        "expected_keywords": ["defender"],
        "logical_rule_key": "battle_rule_v1:gleaming-barrier",
    }


def test_creature_dies_add_counters_execution_scenario() -> None:
    rule = {
        "normalized_name": "venerable knight",
        "card_name": "Venerable Knight",
        "logical_rule_key": "battle_rule_v1:venerable-knight",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_creature_dies_add_counters_target_creature_v1",
            "dies_add_counters": True,
            "dies_add_counters_target": "creature",
            "dies_add_counters_counter_type": "+1/+1",
            "dies_add_counters_count": 1,
            "target": "creature",
            "target_controller": "self",
            "target_constraints": {
                "card_types": ["creature"],
                "controller_scope": "self",
                "required_subtypes": ["knight"],
            },
            "counter_type": "+1/+1",
            "counter_count": 1,
            "keywords": ["first_strike"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_dies_add_counters"
    assert scenario["target_owner"] == "controller"
    assert scenario["expected_counter_type"] == "+1/+1"
    assert scenario["expected_counter_count"] == 1
    assert scenario["expected_target_controller"] == "self"
    assert scenario["expected_target_constraints"]["required_subtypes"] == ["knight"]
    assert "Knight" in scenario["target"]["type_line"]
    assert scenario["expected_keywords"] == ["first_strike"]


def test_manifest_checks_from_expected_rule_split_snapshot_and_runtime_fields() -> None:
    rule = {
        "normalized_name": "verge rangers",
        "card_name": "Verge Rangers",
        "oracle_hash": "hash123",
        "logical_rule_key": "battle_rule_v1:abc",
        "review_status": "verified",
        "execution_status": "auto",
        "min_rule_version": 2,
        "required_effect_fields": {
            "effect": "topdeck_play",
            "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
        },
    }

    snapshot_check = builder.snapshot_check_from_expected_rule(rule)
    runtime_check = builder.runtime_check_from_expected_rule(rule)

    assert snapshot_check["required_effect_fields"] == {
        "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
    }
    assert runtime_check["effect"] == "topdeck_play"
    assert runtime_check["required_effect_fields"] == rule["required_effect_fields"]


def test_simple_activated_create_token_execution_scenario_includes_discard_cost() -> None:
    rule = {
        "normalized_name": "icatian crier",
        "card_name": "Icatian Crier",
        "logical_rule_key": "battle_rule_v1:icatian-crier",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_create_token_v1",
            "activation_cost_mana": "{1}{W}",
            "activation_cost_generic": 1,
            "activation_cost_colors": ["W"],
            "activation_requires_tap": True,
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
            "activation_requires_discard_card": True,
            "token_count": 2,
            "token_name": "Citizen Token",
            "token_power": 1,
            "token_toughness": 1,
            "token_subtype": "Citizen",
            "token_colors": ["W"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_activated_create_token"
    assert scenario["controller_mana"] == {
        "generic": 1,
        "white": 1,
        "blue": 0,
        "black": 0,
        "red": 0,
        "green": 0,
    }
    assert len(scenario["controller_hand"]) == 2
    assert scenario["expected_discard_count"] == 1
    assert scenario["expected_discard_target"] == "any_card"
    assert scenario["expected_token"]["name"] == "Citizen Token"
    assert scenario["expected_token"]["count"] == 2


def test_controlled_subtype_token_spell_execution_scenario_seeds_support_permanents() -> None:
    rule = {
        "normalized_name": "elven ambush",
        "card_name": "Elven Ambush",
        "logical_rule_key": "battle_rule_v1:elven-ambush",
        "required_effect_fields": {
            "effect": "token_maker",
            "battle_model_scope": "xmage_controlled_subtype_create_creature_tokens_spell_v1",
            "token_count_source": "controlled_permanents_with_subtype",
            "token_count_subtype": "Elf",
            "token_name": "Elf Warrior Token",
            "token_power": 1,
            "token_toughness": 1,
            "token_subtype": "Elf Warrior",
            "token_colors": ["G"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "fixed_create_creature_tokens"
    assert scenario["controlled_permanent_subtype"] == "Elf"
    assert scenario["controlled_permanent_subtype_count"] == 3
    assert scenario["expected_token"]["count"] == 3
    assert scenario["expected_token"]["name"] == "Elf Warrior Token"


def test_fixed_create_tokens_execution_scenario_preserves_static_cant_block() -> None:
    rule = {
        "normalized_name": "fixture rat call",
        "card_name": "Fixture Rat Call",
        "logical_rule_key": "battle_rule_v1:fixture-rat-call",
        "required_effect_fields": {
            "effect": "token_maker",
            "battle_model_scope": "xmage_fixed_create_creature_tokens_spell_v1",
            "token_count": 1,
            "token_name": "Rat Token",
            "token_power": 1,
            "token_toughness": 1,
            "token_subtype": "Rat",
            "token_colors": ["B"],
            "token_cant_block": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "fixed_create_creature_tokens"
    assert scenario["expected_token"]["name"] == "Rat Token"
    assert scenario["expected_token"]["cant_block"] is True


def test_dynamic_count_token_spell_execution_scenarios_seed_support_state() -> None:
    fixtures = [
        (
            "Deploy to the Front",
            {"token_count_source": "all_creatures_on_battlefield"},
            {"expected_count": 4, "controlled_battlefield_creature_count": 2, "opponent_battlefield_creature_count": 2},
        ),
        (
            "Flurry of Wings",
            {"token_count_source": "attacking_creatures"},
            {"expected_count": 3, "attacking_creature_count": 3},
        ),
        (
            "Crash the Party",
            {"token_count_source": "controlled_tapped_creatures", "token_tapped": True},
            {"expected_count": 3, "controlled_tapped_creature_count": 3},
        ),
        (
            "Fungal Sprouting",
            {"token_count_source": "greatest_power_among_controlled_creatures"},
            {"expected_count": 4, "controlled_creature_powers": [1, 4, 2]},
        ),
        (
            "Spontaneous Generation",
            {"token_count_source": "controller_hand_count"},
            {"expected_count": 4, "controller_hand_card_count": 4},
        ),
        (
            "Ordered Migration",
            {"token_count_source": "domain_basic_land_types"},
            {"expected_count": 3, "domain_basic_land_subtypes": ["Plains", "Island", "Mountain"]},
        ),
        (
            "Fixture Graveborn",
            {"token_count_source": "controller_graveyard_creature_count"},
            {"expected_count": 3, "controller_graveyard_creature_count": 3},
        ),
        (
            "Rise from the Tides",
            {"token_count_source": "controller_graveyard_instant_sorcery_count"},
            {"expected_count": 3, "controller_graveyard_instant_sorcery_count": 3},
        ),
        (
            "Goblin Gathering",
            {
                "token_count_source": "named_cards_in_controller_graveyard_plus_base",
                "token_count_card_name": "Goblin Gathering",
                "token_count_base": 2,
            },
            {"expected_count": 4, "controller_graveyard_named_card_count": 2},
        ),
    ]
    for card_name, count_fields, expected in fixtures:
        rule = {
            "normalized_name": card_name.lower(),
            "card_name": card_name,
            "logical_rule_key": f"battle_rule_v1:{card_name.lower().replace(' ', '-')}",
            "required_effect_fields": {
                "effect": "token_maker",
                "battle_model_scope": "xmage_dynamic_count_create_creature_tokens_spell_v1",
                "token_name": "Soldier Token",
                "token_power": 1,
                "token_toughness": 1,
                "token_subtype": "Soldier",
                "token_colors": ["W"],
                **count_fields,
            },
        }

        scenario = builder.execution_scenario_from_expected_rule(rule)

        assert scenario["type"] == "fixed_create_creature_tokens"
        assert scenario["expected_token"]["count"] == expected["expected_count"]
        for key, value in expected.items():
            if key != "expected_count":
                assert scenario[key] == value


def test_expected_rule_preserves_named_graveyard_token_count_fields() -> None:
    proposal = {
        "normalized_name": "goblin gathering",
        "card_name": "Goblin Gathering",
        "oracle_hash": "hash-goblin-gathering",
        "logical_rule_key": "battle_rule_v1:goblin-gathering",
        "effect_json": {
            "effect": "token_maker",
            "battle_model_scope": "xmage_dynamic_count_create_creature_tokens_spell_v1",
            "token_count_source": "named_cards_in_controller_graveyard_plus_base",
            "token_count_card_name": "Goblin Gathering",
            "token_count_base": 2,
            "token_name": "Goblin Token",
            "token_power": 1,
            "token_toughness": 1,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)

    required = expected["required_effect_fields"]
    assert required["token_count_source"] == "named_cards_in_controller_graveyard_plus_base"
    assert required["token_count_card_name"] == "Goblin Gathering"
    assert required["token_count_base"] == 2


def test_graveyard_self_exile_activated_create_token_execution_scenario_marks_source_zone() -> None:
    rule = {
        "normalized_name": "eternal student",
        "card_name": "Eternal Student",
        "logical_rule_key": "battle_rule_v1:eternal-student",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_graveyard_self_exile_activated_create_token_v1",
            "activation_cost_mana": "{1}{B}",
            "activation_cost_generic": 1,
            "activation_cost_colors": ["B"],
            "activation_zone": "graveyard",
            "activation_requires_exile_source_from_graveyard": True,
            "token_count": 2,
            "token_name": "Inkling Token",
            "token_power": 1,
            "token_toughness": 1,
            "token_subtype": "Inkling",
            "token_colors": ["W", "B"],
            "token_keywords": ["flying"],
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_activated_create_token"
    assert scenario["source_zone"] == "graveyard"
    assert scenario["expected_exiled_source_from_graveyard"] is True
    assert scenario["controller_mana"] == {
        "generic": 1,
        "white": 0,
        "blue": 0,
        "black": 1,
        "red": 0,
        "green": 0,
    }
    assert scenario["expected_token"]["name"] == "Inkling Token"
    assert scenario["expected_token"]["keywords"] == ["flying"]


def test_spell_cast_gain_life_execution_scenario_uses_matching_and_nonmatching_spells() -> None:
    rule = {
        "normalized_name": "student of ojutai",
        "card_name": "Student of Ojutai",
        "logical_rule_key": "battle_rule_v1:student-of-ojutai",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_spell_cast_gain_life_v1",
            "trigger": "noncreature_spell_cast",
            "trigger_effect": "gain_life",
            "spell_cast_gain_life": True,
            "spell_cast_gain_life_amount": 2,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "spell_cast_gain_life"
    assert scenario["expected_life_gain"] == 2
    assert scenario["expected_trigger"] == "noncreature_spell_cast"
    assert scenario["matching_spell"]["type_line"] == "Instant"
    assert "Creature" in scenario["nonmatching_spell"]["type_line"]


def test_spell_cast_gain_life_execution_scenario_uses_opponent_for_any_player_trigger() -> None:
    rule = {
        "normalized_name": "angels feather",
        "card_name": "Angel's Feather",
        "logical_rule_key": "battle_rule_v1:angels-feather",
        "required_effect_fields": {
            "effect": "life_gain_engine",
            "battle_model_scope": "xmage_spell_cast_gain_life_v1",
            "trigger": "spell_cast",
            "trigger_effect": "gain_life",
            "spell_cast_gain_life": True,
            "spell_cast_gain_life_amount": 1,
            "spell_cast_gain_life_required_colors": ["W"],
            "spell_cast_gain_life_any_player": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "spell_cast_gain_life"
    assert scenario["matching_spell_controller"] == "opponent"
    assert scenario["nonmatching_spell_controller"] == "opponent"
    assert scenario["matching_spell"]["colors"] == ["W"]
    assert scenario["card"]["type_line"] == "Artifact"


def test_spell_cast_gain_life_execution_scenario_picks_true_nonmatching_color() -> None:
    rule = {
        "normalized_name": "wurms tooth",
        "card_name": "Wurm's Tooth",
        "logical_rule_key": "battle_rule_v1:wurms-tooth",
        "required_effect_fields": {
            "effect": "life_gain_engine",
            "battle_model_scope": "xmage_spell_cast_gain_life_v1",
            "trigger": "spell_cast",
            "trigger_effect": "gain_life",
            "spell_cast_gain_life": True,
            "spell_cast_gain_life_amount": 1,
            "spell_cast_gain_life_required_colors": ["G"],
            "spell_cast_gain_life_any_player": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["matching_spell"]["colors"] == ["G"]
    assert scenario["nonmatching_spell"]["colors"] != ["G"]


def test_spell_cast_gain_life_execution_scenario_includes_matching_land_trigger() -> None:
    rule = {
        "normalized_name": "staff of the death magus",
        "card_name": "Staff of the Death Magus",
        "logical_rule_key": "battle_rule_v1:staff-of-the-death-magus",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "spell_cast_gain_life"
    assert scenario["matching_spell"]["colors"] == ["B"]
    assert scenario["matching_land"]["type_line"] == "Basic Land - Swamp"
    assert scenario["nonmatching_land"]["type_line"] != "Basic Land - Swamp"
    assert scenario["expected_land_life_after"] == 22


def test_spell_cast_token_maker_execution_scenario_uses_matching_and_nonmatching_spells() -> None:
    rule = {
        "normalized_name": "third path iconoclast",
        "card_name": "Third Path Iconoclast",
        "logical_rule_key": "battle_rule_v1:third-path-iconoclast",
        "required_effect_fields": {
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
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "spell_cast_token_maker"
    assert scenario["expected_trigger"] == "noncreature_spell_cast"
    assert scenario["matching_spell"]["type_line"] == "Instant"
    assert "Creature" in scenario["nonmatching_spell"]["type_line"]
    assert scenario["expected_token"]["name"] == "Soldier Token"
    assert scenario["expected_token"]["artifact"] is True


def test_creature_enters_draw_execution_scenario_uses_matching_entering_creature() -> None:
    rule = {
        "normalized_name": "elemental bond",
        "card_name": "Elemental Bond",
        "logical_rule_key": "battle_rule_v1:elemental-bond",
        "required_effect_fields": {
            "effect": "enchantment",
            "battle_model_scope": "xmage_creature_enters_draw_trigger_v1",
            "trigger": "creature_you_control_enters",
            "trigger_effect": "draw_cards",
            "trigger_controller_scope": "self",
            "trigger_draw_count": 1,
            "trigger_entering_card_types": ["creature"],
            "trigger_entering_power_min": 3,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "creature_enters_draw"
    assert scenario["expected_draw_count"] == 1
    assert scenario["expected_trigger"] == "creature_you_control_enters"
    assert scenario["entering_controller"] == "controller"
    assert scenario["entering_creature"]["power"] == 3


def test_each_player_sacrifice_fields_and_execution_scenario() -> None:
    proposal = {
        "normalized_name": "renounce the guilds",
        "card_name": "Renounce the Guilds",
        "oracle_hash": "hash-renounce-the-guilds",
        "logical_rule_key": "battle_rule_v1:hash-renounce-the-guilds",
        "effect_json": {
            "effect": "each_player_sacrifice",
            "battle_model_scope": "xmage_each_player_sacrifice_fixed_permanents_spell_v1",
            "sacrifice_count": 1,
            "sacrifice_card_types": ["permanent"],
            "sacrifice_scope": "each_player",
            "sacrifice_choice": "controller_choice_lowest_value",
            "sacrifice_requires_multicolored": True,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["sacrifice_count"] == 1
    assert required["sacrifice_card_types"] == ["permanent"]
    assert required["sacrifice_scope"] == "each_player"
    assert required["sacrifice_choice"] == "controller_choice_lowest_value"
    assert required["sacrifice_requires_multicolored"] is True

    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "each_player_sacrifice"
    assert scenario["sacrifice_count"] == 1
    assert scenario["sacrifice_card_types"] == ["permanent"]
    assert scenario["sacrifice_requires_multicolored"] is True
    assert scenario["expected_sacrificed_per_player"] == 1


def test_simple_activated_regenerate_source_execution_scenario_uses_activation_mana() -> None:
    rule = {
        "normalized_name": "cudgel troll",
        "card_name": "Cudgel Troll",
        "logical_rule_key": "battle_rule_v1:cudgel-troll",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_regenerate_source_v1",
            "activated_effect": "regenerate_source",
            "activation_cost_mana": "{G}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["G"],
            "activation_requires_tap": False,
            "regenerate_source": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_activated_regenerate_source"
    assert scenario["controller_mana"] == {
        "generic": 0,
        "white": 0,
        "blue": 0,
        "black": 0,
        "red": 0,
        "green": 1,
    }
    assert scenario["expected_regeneration_shields"] == 1


def test_simple_activated_regenerate_source_execution_scenario_supplies_extra_costs() -> None:
    rule = {
        "normalized_name": "centaur veteran",
        "card_name": "Centaur Veteran",
        "logical_rule_key": "battle_rule_v1:centaur-veteran",
        "required_effect_fields": {
            "effect": "creature",
            "battle_model_scope": "xmage_permanent_simple_activated_regenerate_source_v1",
            "activated_effect": "regenerate_source",
            "activation_cost_mana": "{G}",
            "activation_cost_generic": 0,
            "activation_cost_colors": ["G"],
            "activation_requires_tap": False,
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
            "activation_life_cost": 2,
            "regenerate_source": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_activated_regenerate_source"
    assert scenario["expected_discard_count"] == 1
    assert scenario["expected_discard_target"] == "any_card"
    assert scenario["expected_life_paid"] == 2
    assert len(scenario["controller_hand"]) >= 1


def test_simple_activated_regenerate_target_execution_scenario_supplies_target_and_costs() -> None:
    rule = {
        "normalized_name": "draconian cylix",
        "card_name": "Draconian Cylix",
        "logical_rule_key": "battle_rule_v1:draconian-cylix",
        "required_effect_fields": {
            "effect": "artifact",
            "battle_model_scope": "xmage_permanent_simple_activated_regenerate_target_v1",
            "activated_effect": "regenerate_target",
            "target": "creature",
            "target_constraints": {"card_types": ["creature"]},
            "activation_cost_mana": "{2}",
            "activation_cost_generic": 2,
            "activation_cost_colors": [],
            "activation_requires_tap": True,
            "activation_discard_count": 1,
            "activation_discard_target": "any_card",
            "activation_discard_random": True,
            "regenerate_target": True,
        },
    }

    scenario = builder.execution_scenario_from_expected_rule(rule)

    assert scenario["type"] == "simple_activated_regenerate_target"
    assert scenario["controller_mana"]["generic"] == 2
    assert scenario["expected_tapped_source"] is True
    assert scenario["expected_regeneration_shields"] == 1
    assert scenario["expected_discard_count"] == 1
    assert scenario["target"]["type_line"].startswith("Creature")
    assert len(scenario["controller_hand"]) >= 1


def test_modal_damage_or_destroy_fields_and_execution_scenario_are_manifested() -> None:
    proposal = {
        "normalized_name": "fiery intervention",
        "card_name": "Fiery Intervention",
        "oracle_hash": "hash-fiery-intervention",
        "logical_rule_key": "battle_rule_v1:fiery-intervention",
        "effect_json": {
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
            "damage_amount": 5,
            "damage_target": "creature",
            "destroy_target": "artifact",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["modal_modes"][0]["mode"] == "direct_damage"
    assert required["modal_modes"][1]["mode"] == "destroy_target"
    assert required["mode_selection_model"] == "best_available_mode"
    assert required["damage_amount"] == 5
    assert required["destroy_target"] == "artifact"

    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "modal_damage_or_destroy"
    assert scenario["expected_selected_mode"] == "destroy_target"
    assert scenario["destroy_target"]["name"] == "E2E Legal Modal Destroy Target"
    assert scenario["damage_target"]["name"] == "E2E Legal Modal Damage Target"


def test_proliferate_draw_fields_and_execution_scenario_are_manifested() -> None:
    proposal = {
        "normalized_name": "contentious plan",
        "card_name": "Contentious Plan",
        "oracle_hash": "hash-contentious-plan",
        "logical_rule_key": "battle_rule_v1:contentious-plan",
        "effect_json": {
            "effect": "composite_resolution",
            "battle_model_scope": "xmage_fixed_proliferate_and_draw_cards_spell_v1",
            "draw_count": 1,
            "count": 1,
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
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["battle_model_scope"] == "xmage_fixed_proliferate_and_draw_cards_spell_v1"
    assert required["draw_count"] == 1
    assert required["proliferate_count"] == 1

    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "proliferate_draw_spell"
    assert scenario["expected_draw_count"] == 1
    assert scenario["expected_controller_plus_one_counters"] == 2
    assert scenario["expected_opponent_charge_counters"] == 3
    assert scenario["expected_opponent_poison_counters"] == 2


def test_pain_talisman_manifest_preserves_colored_mana_life_loss_modes() -> None:
    proposal = {
        "normalized_name": "talisman of hierarchy",
        "card_name": "Talisman of Hierarchy",
        "oracle_hash": "hash-talisman-hierarchy",
        "logical_rule_key": "battle_rule_v1:talisman-hierarchy",
        "effect_json": {
            "effect": "ramp_permanent",
            "battle_model_scope": "pain_talisman_color_pair_partial_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "CWB",
            "life_for_colored_mana": 1,
            "mana_activation_requires_tap": True,
            "activation_requires_tap": True,
            "permanent_type": "artifact",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["life_for_colored_mana"] == 1

    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["expected_available_mana_after_refresh"] == 1
    assert scenario["expected_conditional_mana"] == 1
    assert scenario["expected_conditional_life_loss_by_color"] == {
        "colorless": 0,
        "white": 1,
        "black": 1,
    }


def test_mana_source_activation_life_gain_manifest_expects_life_gain() -> None:
    proposal = {
        "normalized_name": "pristine talisman",
        "card_name": "Pristine Talisman",
        "oracle_hash": "hash-pristine-talisman",
        "logical_rule_key": "battle_rule_v1:pristine-talisman",
        "effect_json": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_mana_source_with_gain_life_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "C",
            "produced_mana_symbols": ["C"],
            "mana_activation_life_gain": 1,
            "mana_activation_requires_tap": True,
            "activation_requires_tap": True,
            "permanent_type": "artifact",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["mana_activation_life_gain"] == 1

    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["expected_available_mana_after_refresh"] == 1
    assert scenario["starting_life"] == 40
    assert scenario["expected_mana_activation_life_gain"] == 1
    assert scenario["expected_life_after_refresh"] == 41


def test_restricted_mana_source_manifest_preserves_conditional_modes() -> None:
    proposal = {
        "normalized_name": "beastcaller savant",
        "card_name": "Beastcaller Savant",
        "oracle_hash": "hash-beastcaller-savant",
        "logical_rule_key": "battle_rule_v1:beastcaller-savant",
        "effect_json": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_restricted_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": True,
            "activation_requires_tap": True,
            "conditional_mana_modes_status": "runtime_executor_v1",
            "conditional_mana_modes": [
                {
                    "color": "W",
                    "restriction": "creature_spell",
                    "mode": "restricted_spell_mana",
                    "status": "runtime_executor_v1",
                },
                {
                    "color": "U",
                    "restriction": "creature_spell",
                    "mode": "restricted_spell_mana",
                    "status": "runtime_executor_v1",
                },
            ],
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["conditional_mana_modes_status"] == "runtime_executor_v1"
    assert required["conditional_mana_modes"][0]["restriction"] == "creature_spell"

    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["expected_conditional_mana"] == 1
    assert scenario["expected_conditional_restrictions"] == ["creature_spell"]
    assert scenario["expected_restricted_mana_payable_card"]["type_line"] == "Creature"
    assert scenario["expected_restricted_mana_blocked_card"]["type_line"] == "Sorcery"


def test_land_color_dependent_mana_source_manifest_builds_land_dependency_scenario() -> None:
    proposal = {
        "normalized_name": "naga vitalist",
        "card_name": "Naga Vitalist",
        "oracle_hash": "hash-naga-vitalist",
        "logical_rule_key": "battle_rule_v1:naga-vitalist",
        "effect_json": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_simple_tap_land_color_dependent_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WUBRGC",
            "mana_activation_requires_tap": True,
            "activation_requires_tap": True,
            "conditionally_produces_controller_land_colors": True,
            "land_mana_dependency_controller": "self",
            "land_mana_dependency_allows_colorless": True,
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["conditionally_produces_controller_land_colors"] is True
    assert required["land_mana_dependency_controller"] == "self"
    assert required["land_mana_dependency_allows_colorless"] is True

    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["expected_conditional_mana"] == 1
    assert scenario["expected_conditional_colors"] == ["green", "colorless"]
    assert scenario["controller_lands"][0]["produces"] == "G"
    assert scenario["controller_lands"][1]["produces"] == "C"
    assert "opponent_lands" not in scenario


def test_fixed_color_dynamic_mana_source_manifest_builds_count_scenario() -> None:
    proposal = {
        "normalized_name": "magus of the coffers",
        "card_name": "Magus of the Coffers",
        "oracle_hash": "hash-magus-of-the-coffers",
        "logical_rule_key": "battle_rule_v1:magus-of-the-coffers",
        "effect_json": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_fixed_color_dynamic_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "B",
            "mana_activation_requires_tap": True,
            "activation_requires_tap": True,
            "activation_mana_cost": "{2}",
            "dynamic_mana_amount_source": "battlefield_permanent_count",
            "dynamic_mana_battlefield_count_scope": "controller_battlefield",
            "dynamic_mana_battlefield_count_subtypes": ["swamp"],
            "source_type_line": "Creature - Human Wizard",
            "source_mana_cost": "{4}{B}",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["dynamic_mana_amount_source"] == "battlefield_permanent_count"
    assert required["dynamic_mana_battlefield_count_subtypes"] == ["swamp"]

    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["expected_available_mana_after_refresh"] == 3
    assert scenario["controller_mana"]["generic"] == 2
    assert len(scenario["controller_battlefield"]) == 3
    assert scenario["type_line"] == "Creature - Human Wizard"


def test_controlled_creature_condition_conditional_mana_source_manifest_builds_ferocious_scenario() -> None:
    proposal = {
        "normalized_name": "ilysian caryatid",
        "card_name": "Ilysian Caryatid",
        "oracle_hash": "hash-ilysian-caryatid",
        "logical_rule_key": "battle_rule_v1:ilysian-caryatid",
        "effect_json": {
            "effect": "ramp_permanent",
            "battle_model_scope": "xmage_controlled_creature_condition_conditional_mana_source_permanent_v1",
            "is_mana_source": True,
            "mana_produced": 1,
            "produces": "WUBRG",
            "mana_activation_requires_tap": True,
            "activation_requires_tap": True,
            "conditional_mana_controlled_creature_power_gte": 4,
            "conditional_mana_produced_when_condition_met": 2,
            "conditional_mana_same_color_choice": True,
            "conditional_mana_modes_status": "runtime_executor_v1",
            "conditional_mana_modes": [
                {
                    "color": symbol,
                    "restriction": "any_spell",
                    "mode": "controlled_creature_power_gte",
                    "status": "runtime_executor_v1",
                }
                for symbol in "WUBRG"
            ],
            "source_type_line": "Creature - Plant",
            "source_mana_cost": "{1}{G}",
        },
    }

    expected = builder.expected_rule_from_proposal(proposal)
    required = expected["required_effect_fields"]

    assert required["conditional_mana_controlled_creature_power_gte"] == 4
    assert required["conditional_mana_same_color_choice"] is True

    scenario = builder.execution_scenario_from_expected_rule(expected)

    assert scenario["type"] == "simple_mana_source_refresh"
    assert scenario["expected_available_mana_after_refresh"] == 2
    assert scenario["expected_conditional_mana"] == 2
    assert scenario["controller_battlefield"][0]["power"] == 4
    assert scenario["type_line"] == "Creature - Plant"
