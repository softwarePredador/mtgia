#!/usr/bin/env python3
"""Group XMage-backed ManaLoom candidates by semantic effect family.

This is a read-only batching layer. It turns card-level XMage validity output
into family-level work units so ManaLoom can implement runtime behavior once per
family and promote metadata in batches after review, tests, and PG approval.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DEFAULT_REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"


FAMILY_DEFINITIONS: dict[str, dict[str, Any]] = {
    "static_cost_reducer": {
        "effects": {"static_cost_reduction"},
        "support_status": "runtime_supported_family",
        "implementation_unit": "battle cost-locking / affordability / payment reducer",
        "family_tests": [
            "test_pearl_medallion_reduces_white_spell_generic_cost_without_mana_source",
            "test_scarlet_witch_reduces_mv4_instant_or_sorcery_by_source_power",
            "test_scarlet_witch_does_not_reduce_mv3_or_non_instant_sorcery_spell",
        ],
        "batch_strategy": "metadata_batch_after_pg_precheck",
    },
    "other_turn_mana_rock": {
        "effects": {
            "other_turn_untapping_any_color_mana_rock",
            "other_turn_untapping_target_player_colorless_mana_rock",
        },
        "support_status": "runtime_supported_by_local_artifact",
        "implementation_unit": "mana source refresh and target-player mana-pool routing",
        "family_tests": ["pg109_benders_waterskin_victory_chimes_focused_runtime"],
        "batch_strategy": "metadata_batch_after_pg_precheck",
    },
    "modal_mana_rock": {
        "effects": {"mana_rock_with_sacrifice_draw", "mana_rock_with_harnessed_blink"},
        "support_status": "runtime_family_required",
        "implementation_unit": "activated artifact mana plus secondary activated/non-mana mode",
        "family_tests": [],
        "batch_strategy": "implement_family_before_metadata_batch",
    },
    "token_maker": {
        "effects": {"token_maker"},
        "support_status": "runtime_family_required",
        "implementation_unit": "token creation with stats, abilities, duration, and zone cleanup",
        "family_tests": [],
        "batch_strategy": "implement_family_before_metadata_batch",
    },
    "board_wipe_choice": {
        "effects": {
            "vow_counter_each_player_sacrifice_rest",
            "gift_destroy_all_creatures_return_own_destroyed_creature",
            "selective_nonland_sacrifice",
            "board_wipe",
            "sweeper_damage",
        },
        "support_status": "runtime_family_required",
        "implementation_unit": "multi-player choice/wipe/sacrifice resolution",
        "family_tests": [],
        "batch_strategy": "implement_family_before_metadata_batch",
    },
    "discard_modal_trigger": {
        "effects": {"discard_trigger_modal_draw_treasure_opponent_life_loss"},
        "support_status": "runtime_family_required",
        "implementation_unit": "triggered modal once-each-turn resolution",
        "family_tests": [],
        "batch_strategy": "implement_family_before_metadata_batch",
    },
    "graveyard_spell_copy_cast": {
        "effects": {"exile_instant_sorcery_boost_combat_damage_copy_cast"},
        "support_status": "runtime_family_required",
        "implementation_unit": "graveyard target, temporary team boost, delayed combat-damage copy/cast",
        "family_tests": [],
        "batch_strategy": "implement_family_before_metadata_batch",
    },
    "targeted_interaction": {
        "effects": {
            "removal_destroy",
            "removal_exile",
            "remove_permanent",
            "bounce",
            "direct_damage",
            "counter_spell",
            "add_counters",
            "recursion",
            "draw_cards",
        },
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "target legality, resolution, zone transition, and event provenance",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "manual_model": {
        "effects": {"external_reference_required_manual_model"},
        "support_status": "manual_model_required",
        "implementation_unit": "manual Oracle/reference review",
        "family_tests": [],
        "batch_strategy": "not_batch_safe",
    },
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def normalize_name(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip()).lower()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def primary_effect(card: dict[str, Any]) -> dict[str, Any]:
    return (card.get("xmage") or {}).get("primary_effect") or {}


def xmage_types(card: dict[str, Any]) -> set[str]:
    return {str(value or "").upper() for value in ((card.get("xmage") or {}).get("types") or []) if value}


def xmage_ability_classes(card: dict[str, Any]) -> set[str]:
    return {str(value or "") for value in ((card.get("xmage") or {}).get("ability_classes") or []) if value}


def xmage_effect_classes(card: dict[str, Any]) -> set[str]:
    return {str(value or "") for value in ((card.get("xmage") or {}).get("effect_classes") or []) if value}


def xmage_cost_classes(card: dict[str, Any]) -> set[str]:
    return {str(value or "") for value in ((card.get("xmage") or {}).get("cost_classes") or []) if value}


def family_for_effect(effect: str | None) -> str:
    effect = str(effect or "external_reference_required_manual_model")
    for family_id, definition in FAMILY_DEFINITIONS.items():
        if effect in definition["effects"]:
            return family_id
    return "manual_model"


def static_cost_reducer_batch_safe(card: dict[str, Any]) -> bool:
    effect_json = primary_effect(card)
    scope = str(effect_json.get("battle_model_scope") or "")
    applies_to = str(effect_json.get("cost_reduction_applies_to") or "")
    cost_classes = xmage_cost_classes(card)
    types = xmage_types(card)
    if scope == "static_activated_ability_cost_reduction_variant_v1":
        return (
            applies_to in {
                "activated_abilities_of_creatures_you_control",
                "activated_abilities_of_artifacts_you_control",
                "activated_abilities_you_activate",
            }
            and int(effect_json.get("cost_reduction_generic") or 0) > 0
            and int(effect_json.get("cost_reduction_minimum_total_mana") or 0) == 1
            and "cost_reduction_condition" not in effect_json
        )
    if scope == "static_variable_self_spell_cost_reduction_variant_v1":
        return (
            applies_to == "this_spell"
            and types == {"CREATURE"}
            and "SacrificeXTargetCost" in cost_classes
            and effect_json.get("cost_reduction_amount_source")
            == "sacrificed_artifact_or_creature_count_this_turn"
            and bool(effect_json.get("cost_reduction_counts_additional_sacrifices_paid_while_casting"))
        )
    if scope not in {
        "static_cost_reduction_for_matching_spells_v1",
        "static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1",
    }:
        return False
    if applies_to not in {"spells_you_cast", "instant_sorcery_spells_you_cast"}:
        return False
    return "cost_reduction_condition" not in effect_json


GENERIC_BATCH_SAFE_SCOPES = {
    ("counter_spell", "counter_target_stack_object_variant_v1"),
    ("draw_cards", "source_controller_draw_variant_v1"),
    ("bounce", "targeted_return_to_hand_variant_v1"),
    ("removal_exile", "targeted_exile_variant_v1"),
    ("removal_destroy", "targeted_destroy_variant_v1"),
    ("direct_damage", "targeted_damage_variant_v1"),
    ("recursion", "graveyard_to_battlefield_variant_v1"),
    ("sweeper_damage", "damage_all_variant_v1"),
}
MANA_ROCK_BATCH_SAFE_SCOPE = (
    "mana_rock_with_sacrifice_draw",
    "mana_rock_self_sacrifice_draw_v1",
)
GENERIC_BATCH_SAFE_EFFECT_CLASSES = {
    "counter_spell": {"CounterTargetEffect"},
    "draw_cards": {"DrawCardSourceControllerEffect"},
    "bounce": {"ReturnToHandTargetEffect"},
    "removal_exile": {"ExileTargetEffect"},
    "removal_destroy": {"DestroyTargetEffect"},
    "direct_damage": {"DamageTargetEffect"},
    "sweeper_damage": {"DamageAllEffect"},
}
GENERIC_BATCH_SAFE_ABILITY_CLASSES = {
    "counter_spell": {"AlternativeCostSourceAbility"},
    "draw_cards": {"FlashbackAbility"},
    "bounce": {"AlternativeCostSourceAbility"},
    "removal_exile": {"AlternativeCostSourceAbility"},
    "removal_destroy": {"AlternativeCostSourceAbility", "CantBeCounteredSourceAbility"},
    "direct_damage": set(),
    "sweeper_damage": {"ConvokeAbility"},
    "recursion": {"FlashbackAbility"},
}


def specialized_targeted_interaction_batch_safe(card: dict[str, Any]) -> bool:
    effect_json = primary_effect(card)
    effect = str(effect_json.get("effect") or "")
    scope = str(effect_json.get("battle_model_scope") or "")
    target = str(effect_json.get("target") or "")
    types = xmage_types(card)
    ability_classes = xmage_ability_classes(card)
    effect_classes = xmage_effect_classes(card)
    cost_classes = xmage_cost_classes(card)
    if effect != "remove_permanent" or target != "artifact_or_enchantment":
        return False
    if scope == "artifact_or_enchantment_removal_lifegain_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"DestroyTargetEffect", "GainLifeTargetControllerEffect"}
            and not ability_classes
            and int(effect_json.get("target_controller_gains_life") or 0) == 4
        )
    if scope == "activated_sacrifice_self_destroy_artifact_or_enchantment_v1":
        return (
            types == {"ENCHANTMENT"}
            and effect_classes == {"DestroyTargetEffect"}
            and ability_classes == {"SimpleActivatedAbility"}
            and "SacrificeSourceCost" in cost_classes
            and effect_json.get("activation_cost") == "sacrifice_self"
        )
    if scope == "aura_of_silence_tax_and_sacrifice_removal_waiver_v1":
        return (
            types == {"ENCHANTMENT"}
            and effect_classes == {"DestroyTargetEffect", "SpellsCostIncreasingAllEffect"}
            and ability_classes == {"SimpleActivatedAbility", "SimpleStaticAbility"}
            and "SacrificeSourceCost" in cost_classes
            and effect_json.get("activation_cost") == "sacrifice_self"
            and int(effect_json.get("taxes_opponent_artifact_enchantment_spells") or 0) == 2
        )
    return False


def generic_runtime_batch_safe(card: dict[str, Any]) -> bool:
    effect_json = primary_effect(card)
    effect = str(effect_json.get("effect") or "")
    scope = str(effect_json.get("battle_model_scope") or "")
    types = xmage_types(card)
    ability_classes = xmage_ability_classes(card)
    effect_classes = xmage_effect_classes(card)
    if (effect, scope) == MANA_ROCK_BATCH_SAFE_SCOPE:
        return False
    if (effect, scope) not in GENERIC_BATCH_SAFE_SCOPES:
        return False
    if not types or not types.issubset({"INSTANT", "SORCERY"}):
        return False
    if effect == "recursion":
        if "ReturnFromGraveyardToBattlefieldTargetEffect" not in effect_classes:
            return False
    else:
        allowed_effects = GENERIC_BATCH_SAFE_EFFECT_CLASSES.get(effect)
        if allowed_effects is None or not effect_classes.issubset(allowed_effects):
            return False
    allowed_abilities = GENERIC_BATCH_SAFE_ABILITY_CLASSES.get(effect, set())
    if not ability_classes.issubset(allowed_abilities):
        return False
    return True


def modal_mana_rock_batch_safe(card: dict[str, Any]) -> bool:
    effect_json = primary_effect(card)
    effect = str(effect_json.get("effect") or "")
    scope = str(effect_json.get("battle_model_scope") or "")
    types = xmage_types(card)
    ability_classes = xmage_ability_classes(card)
    effect_classes = xmage_effect_classes(card)
    cost_classes = xmage_cost_classes(card)
    if effect != "mana_rock_with_sacrifice_draw":
        return False
    if scope not in {
        "mana_rock_self_sacrifice_draw_v1",
        "two_mana_rock_graveyard_hate_cantrip_v1",
        "two_mana_rock_self_sacrifice_draw_two_v1",
    }:
        return False
    if types != {"ARTIFACT"}:
        return False
    if "DrawCardSourceControllerEffect" not in effect_classes:
        return False
    if not any("Mana" in cls for cls in ability_classes):
        return False
    if not {"TapSourceCost", "SacrificeSourceCost"}.issubset(cost_classes):
        return False
    if not effect_json.get("activated_self_sacrifice_draw"):
        return False
    if effect_json.get("produces") != "C":
        return False
    if int(effect_json.get("mana_produced") or 0) < 1:
        return False
    if scope == "two_mana_rock_self_sacrifice_draw_two_v1":
        return int(effect_json.get("draw_on_self_sacrifice") or 1) == 2
    return True


def exact_scope_batch_safe(card: dict[str, Any]) -> bool:
    effect_json = primary_effect(card)
    effect = str(effect_json.get("effect") or "")
    scope = str(effect_json.get("battle_model_scope") or "")
    types = xmage_types(card)
    ability_classes = xmage_ability_classes(card)
    effect_classes = xmage_effect_classes(card)

    if effect == "draw_cards" and scope == "veil_of_summer_draw_and_protection_waiver_v1":
        return (
            types == {"INSTANT"}
            and {
                "ConditionalOneShotEffect",
                "DrawCardSourceControllerEffect",
                "CantBeCounteredControlledEffect",
            }.issubset(effect_classes)
            and int(effect_json.get("count") or 0) == 1
            and bool(effect_json.get("conditional_draw_if_opponent_cast_blue_or_black_spell_this_turn"))
            and bool(effect_json.get("spells_you_control_cant_be_countered_this_turn"))
            and effect_json.get("controller_and_permanents_hexproof_from_colors_until_eot") == ["U", "B"]
            and {"HexproofFromBlueAbility", "HexproofFromBlackAbility"}.issubset(ability_classes)
        )

    if effect == "creature" and scope == "rishkar_counter_mana_creature_waiver_v1":
        return (
            types == {"CREATURE"}
            and {"EntersBattlefieldTriggeredAbility", "SimpleStaticAbility"}.issubset(ability_classes)
            and {"AddCountersTargetEffect", "GainAbilityControlledEffect"}.issubset(effect_classes)
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 2
            and int(effect_json.get("etb_plus_one_counter_targets") or 0) == 2
            and bool(effect_json.get("countered_creatures_tap_for_mana"))
            and effect_json.get("produces") == "G"
        )

    if effect == "counter_spell" and scope == "pact_of_negation_delayed_upkeep_counter_v1":
        return (
            types == {"INSTANT"}
            and {"CounterTargetEffect", "CreateDelayedTriggeredAbilityEffect"}.issubset(effect_classes)
            and "PactDelayedTriggeredAbility" in ability_classes
            and effect_json.get("target") == "spell"
            and bool(effect_json.get("instant"))
            and effect_json.get("delayed_upkeep_mana_payment") == "{3}{U}{U}"
            and bool(effect_json.get("lose_game_if_unpaid"))
        )

    if effect == "counter_spell" and scope == "counter_noncreature_spell_target_controller_treasure_two_v1":
        return (
            types == {"INSTANT"}
            and {"CounterTargetEffect", "CreateTokenControllerTargetEffect"}.issubset(effect_classes)
            and effect_json.get("target") == "noncreature_spell"
            and bool(effect_json.get("instant"))
            and int(effect_json.get("target_controller_creates_treasure") or 0) == 2
        )

    if effect == "counter_spell" and scope == "counter_enchantment_instant_sorcery_spell_target_controller_bird_v1":
        token = effect_json.get("target_controller_creates_token") or {}
        return (
            types == {"INSTANT"}
            and {"CounterTargetEffect", "CreateTokenControllerTargetEffect"}.issubset(effect_classes)
            and effect_json.get("target") == "enchantment_instant_or_sorcery_spell"
            and bool(effect_json.get("instant"))
            and token.get("name") == "Bird"
            and int(token.get("count") or 0) == 1
            and int(token.get("power") or 0) == 2
            and int(token.get("toughness") or 0) == 2
            and token.get("colors") == ["U"]
            and token.get("keywords") == ["flying"]
        )

    if effect == "counter_spell" and scope == "counter_spell_draw_then_discard_v1":
        return (
            types == {"INSTANT"}
            and {"CounterTargetEffect", "DrawDiscardControllerEffect"}.issubset(effect_classes)
            and effect_json.get("target") == "spell"
            and bool(effect_json.get("instant"))
            and int(effect_json.get("draw_then_discard") or 0) == 1
        )

    if effect == "counter_spell" and scope == "counter_spell_costs_one_less_if_control_wizard_v1":
        return (
            types == {"INSTANT"}
            and {"CounterTargetEffect", "SpellCostReductionSourceEffect"}.issubset(effect_classes)
            and "SimpleStaticAbility" in ability_classes
            and effect_json.get("target") == "spell"
            and bool(effect_json.get("instant"))
            and int(effect_json.get("cost_reduction_generic_if_control_wizard") or 0) == 1
        )

    if effect == "creature" and scope == "sacrifice_creature_put_plus_one_counter_on_self_cant_block_v1":
        return (
            types == {"CREATURE"}
            and "AddCountersSourceEffect" in effect_classes
            and {"CantBlockAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
            and "SacrificeTargetCost" in xmage_cost_classes(card)
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("cant_block"))
            and effect_json.get("activation_cost") == "sacrifice_creature"
            and int(effect_json.get("self_add_plus_one_counter") or 0) == 1
        )

    if effect == "creature" and scope == "credit_counter_upkeep_growth_sacrifice_for_life_v1":
        return (
            types == {"CREATURE"}
            and "AddCountersSourceEffect" in effect_classes
            and {"EntersBattlefieldAbility", "EntersBattlefieldTriggeredAbility", "BeginningOfUpkeepTriggeredAbility", "ActivateIfConditionActivatedAbility"}.issubset(ability_classes)
            and "SacrificeSourceCost" in xmage_cost_classes(card)
            and int(effect_json.get("power") or 0) == 0
            and int(effect_json.get("toughness") or 0) == 2
            and int(effect_json.get("enters_with_credit_counters") or 0) == 3
            and int(effect_json.get("etb_damage_controller") or 0) == 3
            and int(effect_json.get("upkeep_add_credit_counter") or 0) == 1
            and effect_json.get("activation_cost") == "sacrifice_self"
            and bool(effect_json.get("gain_life_per_credit_counter"))
            and bool(effect_json.get("activation_only_your_upkeep"))
        )

    if effect == "creature" and scope == "end_step_plus_one_counter_and_other_nontoken_creature_endures_x_v1":
        return (
            types == {"CREATURE"}
            and "AddCountersSourceEffect" in effect_classes
            and {"BeginningOfEndStepTriggeredAbility", "EntersBattlefieldAllTriggeredAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 2
            and int(effect_json.get("end_step_add_plus_one_counter") or 0) == 1
            and bool(effect_json.get("other_nontoken_creature_endures_equal_to_source_counters"))
        )

    if effect == "creature" and scope == "flash_reach_nonhuman_etb_pay_x_put_x_plus_one_counters_on_self_v1":
        return (
            types == {"CREATURE"}
            and "AddCountersSourceEffect" in effect_classes
            and {"FlashAbility", "ReachAbility", "EntersBattlefieldControlledTriggeredAbility", "ReflexiveTriggeredAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 2
            and bool(effect_json.get("flash"))
            and bool(effect_json.get("reach"))
            and bool(effect_json.get("another_nonhuman_etb_optional_pay_x_for_x_plus_one_counters_on_self"))
        )

    if effect == "creature" and scope == "flying_ward_channel_regrowth_or_bounce_creature_v1":
        return (
            types == {"CREATURE", "ENCHANTMENT"}
            and {"ReturnFromGraveyardToHandTargetEffect", "ReturnToHandTargetEffect"}.issubset(effect_classes)
            and {"ChannelAbility", "FlyingAbility", "WardAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 6
            and int(effect_json.get("toughness") or 0) == 5
            and bool(effect_json.get("flying"))
            and effect_json.get("ward_cost") == "{2}"
            and effect_json.get("channel_return_graveyard_card_to_hand") == "{2}{G}"
            and effect_json.get("channel_return_target_creature_to_hand") == "{1}{U}"
        )

    if effect == "creature" and scope == "etb_strip_other_creature_abilities_and_grant_keyword_counters_v1":
        return (
            types == {"CREATURE"}
            and {"LoseAllAbilitiesTargetEffect", "AddCountersTargetEffect"}.issubset(effect_classes)
            and {
                "EntersBattlefieldTriggeredAbility",
                "FlyingAbility",
                "FirstStrikeAbility",
                "LifelinkAbility",
            }.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("flying"))
            and bool(effect_json.get("first_strike"))
            and bool(effect_json.get("lifelink"))
            and bool(effect_json.get("etb_other_target_creature_loses_all_abilities"))
            and effect_json.get("etb_grants_keyword_counters") == ["flying", "first_strike", "lifelink"]
        )

    if effect == "creature" and scope == "flying_persist_sacrifice_self_counter_noncreature_spell_v1":
        return (
            types == {"CREATURE"}
            and "CounterTargetEffect" in effect_classes
            and {"SimpleActivatedAbility", "FlyingAbility", "PersistAbility"}.issubset(ability_classes)
            and "SacrificeSourceCost" in xmage_cost_classes(card)
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 2
            and bool(effect_json.get("flying"))
            and bool(effect_json.get("persist"))
            and effect_json.get("activated_counter_noncreature_spell_cost") == "{U}"
            and effect_json.get("activation_cost") == "sacrifice_self"
        )

    if effect == "creature" and scope == "flying_may_draw_two_when_opponent_draws_card_v1":
        return (
            types == {"CREATURE"}
            and effect_classes == {"DrawCardSourceControllerEffect"}
            and {"FlyingAbility", "ConsecratedSphinxTriggeredAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 4
            and int(effect_json.get("toughness") or 0) == 6
            and bool(effect_json.get("flying"))
            and int(effect_json.get("opponent_draws_card_may_draw") or 0) == 2
        )

    if effect == "creature" and scope == "flash_flying_second_opponent_draw_draw_one_and_activated_each_player_draw_v1":
        return (
            types == {"CREATURE"}
            and {"DrawCardSourceControllerEffect", "DrawCardAllEffect"}.issubset(effect_classes)
            and {"DrawNthCardTriggeredAbility", "FlashAbility", "FlyingAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("flash"))
            and bool(effect_json.get("flying"))
            and int(effect_json.get("opponent_second_card_each_turn_draw") or 0) == 1
            and effect_json.get("activated_each_player_draw_cost") == "{3}{U}"
            and int(effect_json.get("activated_each_player_draw_count") or 0) == 1
        )

    if effect == "creature" and scope == "cant_be_countered_no_max_hand_opponent_noncreature_cast_draw_exile_blink_v1":
        return (
            types == {"CREATURE"}
            and {"DrawCardSourceControllerEffect", "ExileReturnBattlefieldOwnerNextEndStepSourceEffect", "MaximumHandSizeControllerEffect"}.issubset(effect_classes)
            and {"CantBeCounteredSourceAbility", "SimpleActivatedAbility", "SimpleStaticAbility", "SpellCastOpponentTriggeredAbility"}.issubset(ability_classes)
            and "DiscardTargetCost" in xmage_cost_classes(card)
            and int(effect_json.get("power") or 0) == 7
            and int(effect_json.get("toughness") or 0) == 7
            and bool(effect_json.get("cant_be_countered"))
            and bool(effect_json.get("no_maximum_hand_size"))
            and int(effect_json.get("opponent_casts_noncreature_draw") or 0) == 1
            and int(effect_json.get("activated_discard_cards_to_exile_and_return_tapped_count") or 0) == 3
        )

    if effect == "draw_cards" and scope == "draw_one_and_source_controller_spells_gain_flash_until_eot_v1":
        return (
            types == {"INSTANT"}
            and {"CastAsThoughItHadFlashAllEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
            and int(effect_json.get("count") or 0) == 1
            and bool(effect_json.get("instant"))
            and bool(effect_json.get("source_controller_spells_have_flash_until_eot"))
        )

    if effect == "direct_damage" and scope == "activated_sacrifice_creature_deal_one_any_target_v1":
        return (
            types == {"ENCHANTMENT"}
            and effect_classes == {"DamageTargetEffect"}
            and ability_classes == {"SimpleActivatedAbility"}
            and "SacrificeTargetCost" in xmage_cost_classes(card)
            and effect_json.get("activation_cost") == "sacrifice_creature"
            and int(effect_json.get("damage") or 0) == 1
            and effect_json.get("target") == "any_target"
        )

    if effect == "artifact" and scope == "etb_exile_graveyard_card_or_sacrifice_for_mass_graveyard_exile_or_draw_v1":
        return (
            types == {"ARTIFACT"}
            and {"ExileTargetEffect", "DrawCardSourceControllerEffect", "OneShotEffect"}.issubset(effect_classes)
            and {"EntersBattlefieldTriggeredAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
            and {"TapSourceCost", "SacrificeSourceCost", "GenericManaCost"}.issubset(xmage_cost_classes(card))
            and bool(effect_json.get("etb_exile_target_card_from_graveyard"))
            and bool(effect_json.get("activated_tap_sacrifice_exile_each_opponents_graveyard"))
            and int(effect_json.get("activated_generic_one_tap_sacrifice_draw") or 0) == 1
        )

    if effect == "artifact" and scope == "counter_no_mana_spent_spells_and_cantrip_sacrifice_v1":
        return (
            types == {"ARTIFACT"}
            and {"CounterTargetEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
            and {"SpellCastAllTriggeredAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
            and {"GenericManaCost", "TapSourceCost", "SacrificeSourceCost"}.issubset(xmage_cost_classes(card))
            and bool(effect_json.get("trigger_counter_spell_if_no_mana_was_spent"))
            and int(effect_json.get("activated_generic_one_tap_sacrifice_draw") or 0) == 1
        )

    if effect == "bounce" and scope == "return_target_nonland_permanent_you_dont_control_or_overload_all_opponents_nonlands_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"ReturnToHandTargetEffect"}
            and ability_classes == {"OverloadAbility"}
            and bool(effect_json.get("instant"))
            and effect_json.get("target") == "nonland_permanent_you_dont_control"
            and effect_json.get("overload_cost") == "{6}{U}"
            and bool(effect_json.get("overload_bounces_each_nonland_permanent_you_dont_control"))
        )

    if effect == "modal_spell" and scope == "counter_target_blue_spell_or_destroy_target_blue_permanent_v1":
        return (
            types == {"INSTANT"}
            and {"CounterTargetEffect", "DestroyTargetEffect"}.issubset(effect_classes)
            and not ability_classes
            and bool(effect_json.get("counter_target_blue_spell"))
            and bool(effect_json.get("destroy_target_blue_permanent"))
            and bool(effect_json.get("instant"))
        )

    return False


def promotion_lane(card: dict[str, Any], family: dict[str, Any]) -> str:
    if card.get("status") == "blocked_missing_xmage_class":
        return "blocked_missing_xmage_source"
    if not card.get("ready_for_structured_pull"):
        return "mapper_metadata_or_test_scenario_required"
    if exact_scope_batch_safe(card):
        return "batch_metadata_candidate_requires_pg_precheck"
    if generic_runtime_batch_safe(card):
        return "batch_metadata_candidate_requires_pg_precheck"
    if specialized_targeted_interaction_batch_safe(card):
        return "batch_metadata_candidate_requires_pg_precheck"
    if modal_mana_rock_batch_safe(card):
        return "batch_metadata_candidate_requires_pg_precheck"
    support_status = str(family.get("support_status") or "")
    if family.get("effects") == {"static_cost_reduction"} and not static_cost_reducer_batch_safe(card):
        return "split_family_scope_review_required"
    if support_status in {"runtime_supported_family", "runtime_supported_by_local_artifact"}:
        return "batch_metadata_candidate_requires_pg_precheck"
    if support_status == "runtime_family_required":
        return "runtime_family_implementation_required"
    if support_status == "runtime_family_partially_supported_review_required":
        return "split_family_scope_review_required"
    return "manual_model_required"


def classify_card(card: dict[str, Any]) -> dict[str, Any]:
    effect_json = primary_effect(card)
    family_id = family_for_effect(effect_json.get("effect"))
    family = FAMILY_DEFINITIONS[family_id]
    lane = promotion_lane(card, family)
    return {
        "card_name": card.get("card_name"),
        "normalized_name": normalize_name(str(card.get("card_name") or "")),
        "severity": card.get("severity"),
        "status": card.get("status"),
        "coherence_findings": card.get("coherence_findings") or [],
        "oracle_hash": card.get("oracle_hash"),
        "family_id": family_id,
        "effect": effect_json.get("effect"),
        "battle_model_scope": effect_json.get("battle_model_scope"),
        "family_support_status": family.get("support_status"),
        "implementation_unit": family.get("implementation_unit"),
        "batch_strategy": family.get("batch_strategy"),
        "promotion_lane": lane,
        "ready_for_structured_pull": bool(card.get("ready_for_structured_pull")),
        "valid_xmage_source": bool(card.get("valid_xmage_source")),
        "xmage_class": (card.get("xmage") or {}).get("class_name"),
        "xmage_path": (card.get("xmage") or {}).get("path"),
        "xmage_types": sorted(xmage_types(card)),
        "xmage_ability_classes": sorted(xmage_ability_classes(card)),
        "xmage_effect_classes": sorted(xmage_effect_classes(card)),
        "focused_test_scenario_count": (card.get("checks") or {}).get("focused_test_scenario_count") or 0,
        "effect_json": effect_json,
    }


def build_family_report(batch_audit: dict[str, Any]) -> dict[str, Any]:
    cards = [classify_card(card) for card in batch_audit.get("cards", []) if isinstance(card, dict)]
    by_family: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for card in cards:
        by_family[card["family_id"]].append(card)

    families: list[dict[str, Any]] = []
    for family_id, family_cards in sorted(by_family.items()):
        definition = FAMILY_DEFINITIONS[family_id]
        lane_counts = Counter(card["promotion_lane"] for card in family_cards)
        families.append(
            {
                "family_id": family_id,
                "support_status": definition.get("support_status"),
                "implementation_unit": definition.get("implementation_unit"),
                "batch_strategy": definition.get("batch_strategy"),
                "family_tests": definition.get("family_tests") or [],
                "card_count": len(family_cards),
                "lane_counts": dict(sorted(lane_counts.items())),
                "sample_cards": [card["card_name"] for card in family_cards[:8]],
                "cards": family_cards,
            }
        )

    lane_counts = Counter(card["promotion_lane"] for card in cards)
    family_counts = Counter(card["family_id"] for card in cards)
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "mutations_performed": [],
        "source": {
            "batch_audit_generated_at": batch_audit.get("generated_at"),
            "batch_audit_summary": batch_audit.get("summary"),
            "deck_id": (batch_audit.get("source") or {}).get("deck_id"),
        },
        "summary": {
            "card_count": len(cards),
            "family_count": len(families),
            "family_counts": dict(sorted(family_counts.items())),
            "promotion_lane_counts": dict(sorted(lane_counts.items())),
            "batch_metadata_candidate_count": lane_counts.get("batch_metadata_candidate_requires_pg_precheck", 0),
            "runtime_family_required_count": lane_counts.get("runtime_family_implementation_required", 0),
            "manual_or_blocked_count": (
                lane_counts.get("manual_model_required", 0)
                + lane_counts.get("blocked_missing_xmage_source", 0)
                + lane_counts.get("mapper_metadata_or_test_scenario_required", 0)
                + lane_counts.get("split_family_scope_review_required", 0)
            ),
        },
        "families": families,
        "cards": cards,
    }


def markdown_report(report: dict[str, Any]) -> str:
    lines = [
        "# XMage Semantic Family Classification",
        "",
        f"Generated at: `{report['generated_at']}`",
        "",
        "Read-only artifact. `mutations_performed=[]`.",
        "",
        f"- Summary: `{json.dumps(report.get('summary'), sort_keys=True)}`",
        "",
        "| Family | Cards | Support | Lane counts | Implementation unit |",
        "| --- | ---: | --- | --- | --- |",
    ]
    for family in report.get("families", []):
        lines.append(
            "| "
            + " | ".join(
                [
                    f"`{family.get('family_id')}`",
                    str(family.get("card_count")),
                    f"`{family.get('support_status')}`",
                    f"`{json.dumps(family.get('lane_counts'), sort_keys=True)}`",
                    str(family.get("implementation_unit") or ""),
                ]
            )
            + " |"
        )
    lines.extend(["", "## Work Units", ""])
    for family in report.get("families", []):
        lines.extend(
            [
                f"### {family.get('family_id')}",
                "",
                f"- Support: `{family.get('support_status')}`",
                f"- Batch strategy: `{family.get('batch_strategy')}`",
                f"- Family tests: `{json.dumps(family.get('family_tests'), sort_keys=True)}`",
                f"- Cards: `{json.dumps(family.get('sample_cards'), sort_keys=True)}`",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def write_report(report: dict[str, Any], output_json: Path, output_md: Path) -> None:
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    output_md.write_text(markdown_report(report), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xmage-batch-audit", required=True)
    parser.add_argument("--output-prefix")
    parser.add_argument("--output-json")
    parser.add_argument("--output-md")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    batch_audit = load_json(Path(args.xmage_batch_audit))
    report = build_family_report(batch_audit)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    if args.output_prefix:
        output_json = Path(f"{args.output_prefix}.json")
        output_md = Path(f"{args.output_prefix}.md")
    else:
        stem = f"xmage_semantic_family_classification_{timestamp}"
        output_json = Path(args.output_json or DEFAULT_REPORT_DIR / f"{stem}.json")
        output_md = Path(args.output_md or DEFAULT_REPORT_DIR / f"{stem}.md")
    if args.output_json:
        output_json = Path(args.output_json)
    if args.output_md:
        output_md = Path(args.output_md)
    write_report(report, output_json, output_md)
    print(f"json_report={output_json}")
    print(f"md_report={output_md}")
    print(f"summary={json.dumps(report['summary'], sort_keys=True)}")
    print("mutations_performed=[]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
