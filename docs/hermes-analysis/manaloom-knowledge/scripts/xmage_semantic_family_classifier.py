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
    "ramp_ritual": {
        "effects": {"ramp_ritual"},
        "support_status": "runtime_supported_by_local_artifact",
        "implementation_unit": "one-shot and activated ritual mana bursts already modeled by the battle runtime",
        "family_tests": [],
        "batch_strategy": "metadata_batch_after_pg_precheck",
    },
    "ramp_permanent": {
        "effects": {"ramp_permanent"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "battlefield mana artifacts and triggered resource permanents",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "land_ramp": {
        "effects": {"land_ramp"},
        "support_status": "runtime_supported_by_local_artifact",
        "implementation_unit": "search-based land tutoring and battlefield land entry with landfall-aware zone movement",
        "family_tests": [],
        "batch_strategy": "metadata_batch_after_pg_precheck",
    },
    "land": {
        "effects": {"land"},
        "support_status": "runtime_supported_by_local_artifact",
        "implementation_unit": "basic and simple land mana-source modeling already consumed by the battle runtime",
        "family_tests": [],
        "batch_strategy": "metadata_batch_after_pg_precheck",
    },
    "ramp_engine": {
        "effects": {"ramp_engine"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "triggered battlefield resource engines and resource-event bookkeeping",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "untap_land_engine": {
        "effects": {"untap_land_engine"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "activated land-untap engines that convert board resources into contextual extra mana",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "treasure_maker": {
        "effects": {"treasure_maker"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "treasure creation and discard-draw riders",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "copy_creature_token": {
        "effects": {"copy_creature_token"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "copy-target token creation with haste and end-step cleanup",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "copy_spell_engine": {
        "effects": {"copy_spell"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "stack spell copying from ETB, instant responses, and spell-cast battlefield triggers",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "free_cast": {
        "effects": {"free_cast", "exile_top_nonland_free_cast"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "cast-without-paying resolvers with source-zone, timing-bypass, and replacement-destination bookkeeping",
        "family_tests": [
            "test_pg102_creative_technique_demonstrates_top_nonland_free_casts",
            "test_pg191_invoke_calamity_casts_two_hand_or_graveyard_spells_and_exiles_them",
            "test_pg191_invoke_calamity_respects_total_mana_value_six_and_two_spell_limit",
        ],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "mill_spell": {
        "effects": {"brain_freeze", "mill_cards", "mill_engine"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "target-player library milling, storm copy counting, and activated mill engines",
        "family_tests": ["test_brain_freeze_mills_library_instead_of_dealing_life_damage"],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "life_drain_engine": {
        "effects": {"life_drain_engine"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "death/draw/discard trigger life-loss and controller-gain bookkeeping",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "copy_permanent_etb": {
        "effects": {"copy_permanent_etb"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "permanent enters-the-battlefield copy replacement with optional extra card types",
        "family_tests": [
            "test_phyrexian_metamorph_enters_as_copy_of_best_creature_and_keeps_artifact_type",
            "test_copy_enchantment_without_target_enters_as_self",
        ],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "token_maker": {
        "effects": {"token_maker", "composite_resolution"},
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
    "modal_spell": {
        "effects": {"modal_spell"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "exact-scope modal resolution with repeated mode selection when the card allows it",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "graveyard_spell_copy_cast": {
        "effects": {"exile_instant_sorcery_boost_combat_damage_copy_cast"},
        "support_status": "runtime_family_required",
        "implementation_unit": "graveyard target, temporary team boost, delayed combat-damage copy/cast",
        "family_tests": [],
        "batch_strategy": "implement_family_before_metadata_batch",
    },
    "extra_turn_spell": {
        "effects": {"extra_turn"},
        "support_status": "runtime_supported_family",
        "implementation_unit": "extra turn scheduling and delayed lose-the-game bookkeeping",
        "family_tests": ["test_final_fortune_extra_turn_causes_loss_after_taken_turn"],
        "batch_strategy": "metadata_batch_after_pg_precheck",
    },
    "dig_spell": {
        "effects": {"dig_to_hand"},
        "support_status": "runtime_supported_family",
        "implementation_unit": "top-of-library selection to hand with remainder-to-graveyard zone movement",
        "family_tests": ["test_scattered_thoughts_selects_two_from_top_four_and_bins_the_rest"],
        "batch_strategy": "metadata_batch_after_pg_precheck",
    },
    "pile_selection_spell": {
        "effects": {"pile_selection_draw"},
        "support_status": "runtime_supported_family",
        "implementation_unit": "top-of-library reveal, two-pile minimax partitioning, and hand-versus-graveyard zone movement",
        "family_tests": [
            "test_fact_or_fiction_minimizes_best_available_pile",
            "test_steam_augury_maximizes_worst_available_pile",
        ],
        "batch_strategy": "metadata_batch_after_pg_precheck",
    },
    "draw_engine": {
        "effects": {"draw_engine"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "static and activated draw-engine bookkeeping with delayed card movement",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "damage_prevention_reflect": {
        "effects": {"damage_prevention_reflect"},
        "support_status": "runtime_supported_family",
        "implementation_unit": "source-specific damage prevention shield plus reflected damage to the chosen source controller",
        "family_tests": [
            "test_pg201_deflecting_palm_prevents_chosen_source_and_reflects_damage",
            "test_pg201_deflecting_palm_combat_window_chooses_largest_lethal_source",
        ],
        "batch_strategy": "metadata_batch_after_pg_precheck",
    },
    "opponent_damage_spell": {
        "effects": {"damage_each_opponent"},
        "support_status": "runtime_supported_family",
        "implementation_unit": "one-shot spell resolution that deals fixed noncombat damage to each live opponent",
        "family_tests": [
            "test_pg206_boltwave_damages_each_opponent",
        ],
        "batch_strategy": "metadata_batch_after_pg_precheck",
    },
    "controlled_creature_etb_damage_engine": {
        "effects": {"creature", "passive"},
        "support_status": "runtime_supported_family",
        "implementation_unit": "battlefield trigger when a creature controlled by the source controller enters and damages each live opponent",
        "family_tests": [
            "test_pg207_another_creature_enter_damage_each_opponent_excludes_source_entering",
            "test_pg207_impact_tremors_damages_each_opponent_when_token_enters",
        ],
        "batch_strategy": "metadata_batch_after_pg_precheck",
    },
    "targeted_protection": {
        "effects": {"grant_protection_from_chosen_color"},
        "support_status": "runtime_supported_family",
        "implementation_unit": "targeted own-creature protection grant and cleanup-aware target legality",
        "family_tests": [
            "test_pg204_gods_willing_grants_protection_to_best_creature_until_cleanup",
        ],
        "batch_strategy": "metadata_batch_after_pg_precheck",
    },
    "phase_out_protection": {
        "effects": {"phase_out"},
        "support_status": "runtime_supported_family",
        "implementation_unit": "phase-out protection for controlled permanents with land inclusion/exclusion flags",
        "family_tests": [
            "test_pg205_clever_concealment_phases_controlled_nonland_permanents_only",
        ],
        "batch_strategy": "metadata_batch_after_pg_precheck",
    },
    "tutor": {
        "effects": {"tutor"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "creature": {
        "effects": {"creature"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "creature permanents with exact-scope ETB, death, combat, and activated behavior",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "passive": {
        "effects": {"passive"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "static battlefield annotation and passive support execution",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
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
            "draw_cards",
        },
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "target legality, resolution, zone transition, and event provenance",
        "family_tests": [],
        "batch_strategy": "split_by_scope_before_metadata_batch",
    },
    "recursion": {
        "effects": {"recursion"},
        "support_status": "runtime_family_partially_supported_review_required",
        "implementation_unit": "graveyard target selection, zone movement to hand or battlefield, and replacement-cost annotations",
        "family_tests": [
            "test_profound_journey_rebounds_and_returns_permanents_to_battlefield",
            "test_pg202_redress_fate_returns_all_artifact_enchantment_cards",
        ],
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


def xmage_target_classes(card: dict[str, Any]) -> set[str]:
    nested = (card.get("xmage") or {}).get("target_classes") or []
    summarized = card.get("xmage_target_classes") or []
    return {str(value or "") for value in [*nested, *summarized] if value}


def xmage_condition_classes(card: dict[str, Any]) -> set[str]:
    return {str(value or "") for value in ((card.get("xmage") or {}).get("condition_classes") or []) if value}


def family_for_effect(effect: str | None) -> str:
    effect = str(effect or "external_reference_required_manual_model")
    for family_id, definition in FAMILY_DEFINITIONS.items():
        if family_id == "controlled_creature_etb_damage_engine":
            continue
        if effect in definition["effects"]:
            return family_id
    return "manual_model"


def family_for_effect_json(effect_json: dict[str, Any]) -> str:
    if (
        str(effect_json.get("battle_model_scope") or "") == "controlled_creature_enters_damage_each_opponent_v1"
        and effect_json.get("trigger") == "creature_you_control_enters"
        and effect_json.get("trigger_effect") == "damage_each_opponent"
    ):
        return "controlled_creature_etb_damage_engine"
    return family_for_effect(effect_json.get("effect"))


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
    ("recursion", "return_target_permanent_from_graveyard_to_battlefield_rebound_v1"),
    ("recursion", "return_all_artifact_enchantment_cards_from_graveyard_to_battlefield_miracle_v1"),
    ("recursion", "return_all_artifact_enchantment_cards_from_graveyard_to_battlefield_v1"),
    ("recursion", "return_all_artifact_cards_from_graveyard_to_battlefield_haste_eot_v1"),
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
    "recursion": {"FlashbackAbility", "MiracleAbility"},
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
        if scope == "return_target_permanent_from_graveyard_to_battlefield_rebound_v1":
            return (
                types == {"SORCERY"}
                and effect_classes == {"ReturnFromGraveyardToBattlefieldTargetEffect"}
                and ability_classes == {"ReboundAbility"}
                and str(effect_json.get("target") or "") == "permanent"
                and str(effect_json.get("destination") or "") == "battlefield"
                and int(effect_json.get("count") or 0) == 1
                and bool(effect_json.get("rebound"))
            )
        if scope == "return_all_artifact_enchantment_cards_from_graveyard_to_battlefield_miracle_v1":
            return (
                types == {"SORCERY"}
                and effect_classes == {"ReturnFromYourGraveyardToBattlefieldAllEffect"}
                and ability_classes == {"MiracleAbility"}
                and str(effect_json.get("target") or "") == "artifact_or_enchantment"
                and str(effect_json.get("destination") or "") == "battlefield"
                and bool(effect_json.get("return_all_matching"))
                and effect_json.get("target_card_types") == ["artifact", "enchantment"]
                and bool(effect_json.get("miracle"))
                and effect_json.get("miracle_cost") == "{3}{W}"
            )
        if scope == "return_all_artifact_enchantment_cards_from_graveyard_to_battlefield_v1":
            return (
                types == {"SORCERY"}
                and effect_classes == {"ReturnFromYourGraveyardToBattlefieldAllEffect"}
                and not ability_classes
                and str(effect_json.get("target") or "") == "artifact_or_enchantment"
                and str(effect_json.get("destination") or "") == "battlefield"
                and bool(effect_json.get("return_all_matching"))
                and effect_json.get("target_card_types") == ["artifact", "enchantment"]
            )
        if scope == "return_all_artifact_cards_from_graveyard_to_battlefield_haste_eot_v1":
            return (
                types == {"SORCERY"}
                and effect_json.get("target_card_types") == ["artifact"]
                and str(effect_json.get("target") or "") == "artifact"
                and str(effect_json.get("destination") or "") == "battlefield"
                and bool(effect_json.get("return_all_matching"))
                and bool(effect_json.get("grants_haste_until_eot"))
            )
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
    cost_classes = xmage_cost_classes(card)
    target_classes = xmage_target_classes(card)

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

    if effect == "creature" and scope == "vigilance_three_three_creatures_tap_any_color_v1":
        return (
            types == {"CREATURE", "ENCHANTMENT"}
            and "GainAbilityControlledEffect" in effect_classes
            and {"AnyColorManaAbility", "SimpleStaticAbility", "VigilanceAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 3
            and int(effect_json.get("toughness") or 0) == 3
            and bool(effect_json.get("vigilance"))
            and bool(effect_json.get("creatures_tap_for_any_color"))
            and effect_json.get("death_return_status") == "annotation_only"
        )

    if effect == "creature" and scope == "sun_titan_etb_attack_return_permanent_mv_lte_3_v1":
        return (
            types == {"CREATURE"}
            and "ReturnFromGraveyardToBattlefieldTargetEffect" in effect_classes
            and {"EntersBattlefieldOrAttacksSourceTriggeredAbility", "VigilanceAbility"}.issubset(ability_classes)
            and "TargetCardInYourGraveyard" in target_classes
            and int(effect_json.get("power") or 0) == 6
            and int(effect_json.get("toughness") or 0) == 6
            and bool(effect_json.get("vigilance"))
            and int(effect_json.get("etb_recursion_count") or 0) == 1
            and effect_json.get("etb_recursion_target") == "permanent"
            and effect_json.get("etb_recursion_destination") == "battlefield"
            and int(effect_json.get("etb_recursion_mana_value_max") or 0) == 3
            and bool(effect_json.get("attack_trigger_graveyard_recursion"))
            and int(effect_json.get("attack_recursion_count") or 0) == 1
            and effect_json.get("attack_recursion_target") == "permanent"
            and effect_json.get("attack_recursion_destination") == "battlefield"
            and int(effect_json.get("attack_recursion_mana_value_max") or 0) == 3
        )

    if effect == "creature" and scope == "graveyard_upkeep_return_self_to_hand_v1":
        return (
            types == {"CREATURE"}
            and "ReturnSourceFromGraveyardToHandEffect" in effect_classes
            and "BeginningOfUpkeepTriggeredAbility" in ability_classes
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("graveyard_upkeep_return_self_to_hand"))
            and bool(effect_json.get("graveyard_upkeep_optional"))
            and effect_json.get("graveyard_upkeep_trigger_zone") == "graveyard"
            and effect_json.get("graveyard_upkeep_trigger_controller") == "source_controller"
        )

    if effect == "creature" and scope == "goldspan_dragon_attack_or_target_treasure_double_mana_v1":
        return (
            types == {"CREATURE"}
            and "CreateTokenEffect" in effect_classes
            and "GainAbilityControlledEffect" in effect_classes
            and {"AttacksTriggeredAbility", "BecomesTargetSourceTriggeredAbility", "OrTriggeredAbility"}.issubset(ability_classes)
            and {"FlyingAbility", "HasteAbility", "SimpleStaticAbility", "SimpleManaAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 4
            and int(effect_json.get("toughness") or 0) == 4
            and bool(effect_json.get("flying"))
            and bool(effect_json.get("haste"))
            and bool(effect_json.get("attack_or_becomes_target_create_treasure"))
            and bool(effect_json.get("attack_trigger_create_treasure"))
            and bool(effect_json.get("becomes_spell_target_create_treasure"))
            and int(effect_json.get("treasure_count") or 0) == 1
            and int(effect_json.get("treasure_mana_value") or 0) == 2
            and bool(effect_json.get("controlled_treasures_add_two_mana"))
        )

    if effect == "creature" and scope == "surly_badgersaur_discard_card_type_triggers_v1":
        return (
            types == {"CREATURE"}
            and {"AddCountersSourceEffect", "CreateTokenEffect", "FightTargetSourceEffect"}.issubset(effect_classes)
            and "DiscardCardControllerTriggeredAbility" in ability_classes
            and "TargetPermanent" in target_classes
            and int(effect_json.get("power") or 0) == 3
            and int(effect_json.get("toughness") or 0) == 3
            and effect_json.get("trigger") == "controller_discard"
            and bool(effect_json.get("controller_discard_creature_add_plus_one_counter"))
            and effect_json.get("controller_discard_counter_type") == "+1/+1"
            and int(effect_json.get("controller_discard_counter_count") or 0) == 1
            and bool(effect_json.get("controller_discard_land_create_treasure"))
            and int(effect_json.get("controller_discard_treasure_count") or 0) == 1
            and bool(effect_json.get("controller_discard_noncreature_nonland_fight"))
            and effect_json.get("controller_discard_fight_target") == "up_to_one_creature_you_dont_control"
            and bool(effect_json.get("controller_discard_fight_optional"))
        )

    if effect == "creature" and scope == "taii_wakeen_noncombat_damage_equal_toughness_draw_plus_x_v1":
        return (
            types == {"CREATURE"}
            and {"DrawCardSourceControllerEffect", "TaiiWakeenPerfectShotEffect"}.issubset(effect_classes)
            and {"TaiiWakeenPerfectShotTriggeredAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
            and "TapSourceCost" in cost_classes
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 3
            and effect_json.get("trigger") == "source_you_control_noncombat_damage_to_creature_equal_toughness"
            and bool(effect_json.get("noncombat_damage_to_creature_equal_toughness_draw"))
            and int(effect_json.get("noncombat_damage_equal_toughness_draw_count") or 0) == 1
            and bool(effect_json.get("activated_noncombat_damage_plus_x_until_eot"))
            and bool(effect_json.get("activation_cost_x_generic"))
            and bool(effect_json.get("activation_requires_tap"))
            and effect_json.get("damage_modifier_applies_to") == "sources_you_control_noncombat_damage"
            and effect_json.get("damage_modifier_duration") == "until_end_of_turn"
        )

    if effect == "draw_engine" and scope == "opponent_second_draw_second_spell_two_attackers_draw_v1":
        return (
            types == {"ENCHANTMENT"}
            and effect_classes == {"DrawCardSourceControllerEffect"}
            and {"SkipExtraTurnsAbility", "TroubleInPairsTriggeredAbility"}.issubset(ability_classes)
            and not cost_classes
            and int(effect_json.get("draw_count") or 0) == 1
            and bool(effect_json.get("skip_opponent_extra_turns"))
            and bool(effect_json.get("opponent_attacks_you_with_two_or_more_creatures_draw"))
            and bool(effect_json.get("opponent_second_card_draw_each_turn"))
            and bool(effect_json.get("opponent_second_spell_each_turn"))
            and effect_json.get("trigger") == "opponent_second_spell"
            and int(effect_json.get("tax") or 0) == 0
        )

    if effect == "damage_prevention_reflect" and scope == "prevent_next_damage_from_chosen_source_to_you_reflect_to_controller_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"PreventNextDamageFromChosenSourceEffect"}
            and not ability_classes
            and not cost_classes
            and bool(effect_json.get("instant"))
            and bool(effect_json.get("prevent_next_damage_from_chosen_source"))
            and effect_json.get("prevent_damage_to") == "you"
            and effect_json.get("prevent_damage_duration") == "until_end_of_turn"
            and bool(effect_json.get("reflect_prevented_damage"))
            and effect_json.get("reflect_target") == "chosen_source_controller"
            and bool(effect_json.get("source_choice_required"))
        )

    if effect == "damage_each_opponent" and scope == "spell_damage_each_opponent_v1":
        return (
            types.issubset({"INSTANT", "SORCERY"})
            and bool(types)
            and effect_classes == {"DamagePlayersEffect"}
            and not ability_classes
            and not cost_classes
            and int(effect_json.get("amount") or effect_json.get("damage") or 0) > 0
            and effect_json.get("target_controller") == "opponents"
            and bool(effect_json.get("instant")) == ("INSTANT" in types)
            and bool(effect_json.get("sorcery")) == ("SORCERY" in types)
        )

    if effect == "board_wipe" and scope == "destroy_all_lands_v1":
        return (
            types == {"SORCERY"}
            and effect_classes == {"DestroyAllEffect"}
            and not ability_classes
            and not cost_classes
            and effect_json.get("destroy_card_types") == ["land"]
            and bool(effect_json.get("destroy_all_lands"))
            and effect_json.get("destination") == "graveyard"
            and bool(effect_json.get("sorcery"))
        )

    if effect in {"creature", "passive"} and scope == "controlled_creature_enters_damage_each_opponent_v1":
        allowed_abilities = {
            "EntersBattlefieldControlledTriggeredAbility",
            "OffspringAbility",
            "UnearthAbility",
        }
        return (
            types in ({"CREATURE"}, {"ENCHANTMENT"}, {"ARTIFACT", "CREATURE"})
            and effect_classes == {"DamagePlayersEffect"}
            and "EntersBattlefieldControlledTriggeredAbility" in ability_classes
            and ability_classes.issubset(allowed_abilities)
            and int(effect_json.get("trigger_damage_each_opponent") or effect_json.get("damage") or 0) > 0
            and effect_json.get("trigger") == "creature_you_control_enters"
            and effect_json.get("trigger_effect") == "damage_each_opponent"
            and effect_json.get("target_controller") == "opponents"
            and not cost_classes.difference({"ManaCostsImpl", "ManaCost", "GenericManaCost"})
        )

    if effect == "creature" and scope == "glint_horn_buccaneer_discard_damage_attack_loot_v1":
        return (
            types == {"CREATURE"}
            and {"DamagePlayersEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
            and "ActivateIfConditionActivatedAbility" in ability_classes
            and "DiscardCardCost" in cost_classes
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 4
            and bool(effect_json.get("haste"))
            and effect_json.get("trigger") == "controller_discard"
            and int(effect_json.get("controller_discard_damage_each_opponent") or 0) == 1
            and bool(effect_json.get("attacking_activated_discard_draw"))
            and effect_json.get("attacking_activated_discard_draw_cost") == "{1}{R}"
            and int(effect_json.get("attacking_activated_discard_count") or 0) == 1
            and int(effect_json.get("attacking_activated_draw_count") or 0) == 1
        )

    if effect == "token_maker" and scope == "instant_sorcery_cast_create_1_1_red_elemental_v1":
        return (
            types == {"CREATURE"}
            and "CreateTokenEffect" in effect_classes
            and "SpellCastControllerTriggeredAbility" in ability_classes
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 1
            and effect_json.get("trigger") == "instant_sorcery_cast"
            and effect_json.get("trigger_effect") == "token_maker"
            and int(effect_json.get("trigger_token_count") or 0) == 1
            and int(effect_json.get("token_count") or 0) == 1
            and effect_json.get("token_name") == "Elemental Token"
            and effect_json.get("token_subtype") == "Elemental"
            and effect_json.get("token_colors") == ["R"]
            and int(effect_json.get("token_power") or 0) == 1
            and int(effect_json.get("token_toughness") or 0) == 1
        )

    if effect == "token_maker" and scope == "noncreature_spell_cast_create_1_1_white_monk_prowess_v1":
        return (
            types == {"CREATURE"}
            and "CreateTokenEffect" in effect_classes
            and "SpellCastControllerTriggeredAbility" in ability_classes
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 2
            and bool(effect_json.get("prowess"))
            and effect_json.get("trigger") == "noncreature_spell_cast"
            and effect_json.get("trigger_effect") == "token_maker"
            and int(effect_json.get("trigger_token_count") or 0) == 1
            and int(effect_json.get("token_count") or 0) == 1
            and effect_json.get("token_name") == "Monk Token"
            and effect_json.get("token_subtype") == "Monk"
            and effect_json.get("token_colors") == ["W"]
            and int(effect_json.get("token_power") or 0) == 1
            and int(effect_json.get("token_toughness") or 0) == 1
            and effect_json.get("token_keywords") == ["prowess"]
            and bool(effect_json.get("token_prowess"))
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

    if (
        effect == "composite_resolution"
        and scope == "create_four_birds_gift_phase_all_life_lock_protection_exile_self_v1"
    ):
        components = effect_json.get("_composite_rule_components") or []
        token_component = next(
            (component for component in components if component.get("effect") == "token_maker"),
            {},
        )
        phase_component = next(
            (component for component in components if component.get("effect") == "phase_out"),
            {},
        )
        return (
            types == {"INSTANT"}
            and "GiftAbility" in ability_classes
            and {
                "CreateTokenEffect",
                "ExileSpellEffect",
                "LifeTotalCantChangeControllerEffect",
                "GainAbilityControllerEffect",
            }.issubset(effect_classes)
            and bool(effect_json.get("instant"))
            and bool(effect_json.get("gift_extra_turn"))
            and bool(effect_json.get("gift_default_promised"))
            and bool(effect_json.get("exiles_self"))
            and int(token_component.get("token_count") or 0) == 4
            and token_component.get("token_name") == "Bird Token"
            and token_component.get("token_colors") == ["U"]
            and bool(token_component.get("token_flying"))
            and bool(phase_component.get("gift_required"))
            and bool(phase_component.get("phase_out_all_permanents_you_control"))
            and bool(phase_component.get("phase_out_includes_lands"))
            and bool(phase_component.get("life_total_cant_change"))
            and bool(phase_component.get("protection_from_everything"))
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

    if effect == "counter_spell" and scope == "counter_spell_unless_controller_pays_three_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"CounterUnlessPaysEffect"}
            and not ability_classes
            and effect_json.get("target") == "spell"
            and bool(effect_json.get("instant"))
            and int(effect_json.get("unless_controller_pays_generic") or 0) == 3
        )

    if effect == "counter_spell" and scope == "counter_instant_or_sorcery_unless_controller_pays_three_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"CounterUnlessPaysEffect"}
            and not ability_classes
            and effect_json.get("target") == "instant_or_sorcery_spell"
            and bool(effect_json.get("instant"))
            and int(effect_json.get("unless_controller_pays_generic") or 0) == 3
        )

    if effect == "counter_spell" and scope == "counter_noncreature_spell_unless_controller_pays_two_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"CounterUnlessPaysEffect"}
            and not ability_classes
            and effect_json.get("target") == "noncreature_spell"
            and bool(effect_json.get("instant"))
            and int(effect_json.get("unless_controller_pays_generic") or 0) == 2
        )

    if effect == "brain_freeze" and scope == "storm_target_player_mill_fixed_count_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"MillCardsTargetEffect"}
            and ability_classes == {"StormAbility"}
            and bool(effect_json.get("instant"))
            and effect_json.get("target") == "player"
            and int(effect_json.get("mill_count") or 0) == 3
            and bool(effect_json.get("storm"))
        )

    if effect == "ramp_ritual" and scope == "three_black_mana_ritual_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"BasicManaEffect"}
            and not ability_classes
            and bool(effect_json.get("instant"))
            and int(effect_json.get("mana_produced") or 0) == 3
            and effect_json.get("produces") == "B"
        )

    if effect == "ramp_ritual" and scope == "threshold_three_or_five_black_mana_ritual_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"BasicManaEffect", "ConditionalManaEffect"}
            and not ability_classes
            and "ThresholdCondition" in {
                str(value or "")
                for value in ((card.get("xmage") or {}).get("condition_classes") or [])
                if value
            }
            and bool(effect_json.get("instant"))
            and int(effect_json.get("mana_produced") or 0) == 3
            and effect_json.get("produces") == "B"
            and int(effect_json.get("threshold_graveyard_count") or 0) == 7
            and int(effect_json.get("threshold_mana_produced") or 0) == 5
        )

    if effect == "ramp_ritual" and scope == "three_red_mana_ritual_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"BasicManaEffect"}
            and not ability_classes
            and bool(effect_json.get("instant"))
            and int(effect_json.get("mana_produced") or 0) == 3
            and effect_json.get("produces") == "R"
        )

    if effect == "ramp_ritual" and scope == "three_red_mana_arcane_splice_ritual_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"BasicManaEffect"}
            and ability_classes == {"SpliceAbility"}
            and bool(effect_json.get("instant"))
            and int(effect_json.get("mana_produced") or 0) == 3
            and effect_json.get("produces") == "R"
            and bool(effect_json.get("subtype_arcane"))
            and effect_json.get("splice_arcane_cost") == "{1}{R}"
        )

    if effect == "ramp_ritual" and scope == "sacrifice_creature_add_four_black_mana_ritual_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"BasicManaEffect"}
            and not ability_classes
            and "SacrificeTargetCost" in cost_classes
            and bool(effect_json.get("instant"))
            and bool(effect_json.get("requires_sacrifice_creature"))
            and int(effect_json.get("mana_produced") or 0) == 4
            and effect_json.get("produces") == "B"
        )

    if effect == "ramp_ritual" and scope == "sacrifice_creature_add_three_red_mana_ritual_v1":
        return (
            types == {"SORCERY"}
            and effect_classes == {"BasicManaEffect"}
            and not ability_classes
            and "SacrificeTargetCost" in cost_classes
            and not bool(effect_json.get("instant"))
            and bool(effect_json.get("requires_sacrifice_creature"))
            and int(effect_json.get("mana_produced") or 0) == 3
            and effect_json.get("produces") == "R"
        )

    if effect == "ramp_ritual" and scope == "hand_exile_add_one_green_mana_ritual_v1":
        return (
            types == {"CREATURE"}
            and not effect_classes
            and ability_classes == {"SimpleManaAbility"}
            and cost_classes == {"ExileSourceFromHandCost"}
            and bool(effect_json.get("hand_exile_mana_ability"))
            and int(effect_json.get("mana_produced") or 0) == 1
            and effect_json.get("produces") == "G"
        )

    if effect == "ramp_permanent" and scope == "self_sacrifice_fetch_land_two_land_subtypes_v1":
        land_subtypes_any = effect_json.get("land_subtypes_any") or []
        return (
            types == {"LAND"}
            and not effect_classes
            and ability_classes == {"FetchLandActivatedAbility"}
            and int(effect_json.get("activation_cost_generic") or 0) == 0
            and bool(effect_json.get("activation_requires_tap"))
            and bool(effect_json.get("activated_self_sacrifice_land_tutor"))
            and int(effect_json.get("activated_pay_life") or 0) == 1
            and int(effect_json.get("land_count") or 0) == 1
            and int(effect_json.get("lands_to_battlefield") or 0) == 1
            and not bool(effect_json.get("land_enters_tapped"))
            and isinstance(land_subtypes_any, list)
            and len(land_subtypes_any) == 2
        )

    if effect == "tutor" and scope == "instant_or_sorcery_tutor_to_top_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"SearchLibraryPutOnLibraryEffect"}
            and not ability_classes
            and bool(effect_json.get("instant"))
            and effect_json.get("target") == "instant_or_sorcery_to_top"
        )

    if effect == "tutor" and scope == "creature_tutor_to_top_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"SearchLibraryPutOnLibraryEffect"}
            and not ability_classes
            and bool(effect_json.get("instant"))
            and effect_json.get("target") == "creature_to_top"
        )

    if effect == "tutor" and scope == "any_tutor_to_top_lose_two_life_v1":
        return (
            types in ({"INSTANT"}, {"SORCERY"})
            and effect_classes == {"LoseLifeSourceControllerEffect", "SearchLibraryPutOnLibraryEffect"}
            and not ability_classes
            and bool(effect_json.get("instant")) == (types == {"INSTANT"})
            and effect_json.get("target") == "any_to_top"
            and int(effect_json.get("controller_loses_life_after_tutor") or 0) == 2
        )

    if effect == "tutor" and scope == "any_tutor_to_hand_v1":
        return (
            types in ({"INSTANT"}, {"SORCERY"})
            and effect_classes == {"SearchLibraryPutInHandEffect"}
            and not ability_classes
            and not cost_classes
            and bool(effect_json.get("instant")) == (types == {"INSTANT"})
            and effect_json.get("target") == "any_to_hand"
        )

    if effect == "tutor" and scope == "sacrifice_creature_any_tutor_to_hand_v1":
        return (
            types in ({"INSTANT"}, {"SORCERY"})
            and effect_classes == {"SearchLibraryPutInHandEffect"}
            and not ability_classes
            and cost_classes == {"SacrificeTargetCost"}
            and bool(effect_json.get("instant")) == (types == {"INSTANT"})
            and effect_json.get("target") == "any_to_hand"
            and bool(effect_json.get("requires_sacrifice_creature"))
        )

    if effect == "tutor" and scope == "land_tutor_to_hand_v1":
        return (
            types in ({"INSTANT"}, {"SORCERY"})
            and effect_classes == {"SearchLibraryPutInHandEffect"}
            and not ability_classes
            and not cost_classes
            and bool(effect_json.get("instant")) == (types == {"INSTANT"})
            and effect_json.get("target") == "land_to_hand"
        )

    if effect == "ramp_permanent" and scope == "activated_self_sacrifice_land_tutor_to_hand_artifact_v1":
        return (
            types == {"ARTIFACT"}
            and effect_classes == {"SearchLibraryPutInHandEffect"}
            and "SimpleActivatedAbility" in ability_classes
            and {"GenericManaCost", "TapSourceCost", "SacrificeSourceCost"}.issubset(cost_classes)
            and bool(effect_json.get("activated_self_sacrifice_tutor_to_hand"))
            and int(effect_json.get("activation_cost_generic") or 0) == 2
            and bool(effect_json.get("activation_requires_tap"))
            and effect_json.get("tutor_target") == "land"
            and effect_json.get("tutor_destination") == "hand"
        )

    if effect == "ramp_permanent" and scope == "activated_self_sacrifice_artifact_mana_ability_or_basic_land_tutor_to_hand_v1":
        return (
            types == {"ARTIFACT"}
            and effect_classes == {"SearchLibraryPutInHandEffect"}
            and "SimpleActivatedAbility" in ability_classes
            and {"GenericManaCost", "TapSourceCost", "SacrificeSourceCost"}.issubset(cost_classes)
            and bool(effect_json.get("activated_self_sacrifice_tutor_to_hand"))
            and int(effect_json.get("activation_cost_generic") or 0) == 1
            and bool(effect_json.get("activation_requires_tap"))
            and effect_json.get("tutor_target") == "artifact_mana_ability_or_basic_land"
            and effect_json.get("tutor_destination") == "hand"
        )

    if effect == "creature" and scope == "spellseeker_etb_instant_or_sorcery_mana_value_2_or_less_to_hand_v1":
        return (
            types == {"CREATURE"}
            and effect_classes == {"SearchLibraryPutInHandEffect"}
            and ability_classes == {"EntersBattlefieldTriggeredAbility"}
            and not cost_classes
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and effect_json.get("etb_tutor_target") == "cheap_instant_or_sorcery"
            and effect_json.get("etb_tutor_status") == "runtime_library_to_hand"
        )

    if effect == "creature" and scope == "trophy_mage_etb_artifact_mana_value_3_to_hand_v1":
        return (
            types == {"CREATURE"}
            and effect_classes == {"SearchLibraryPutInHandEffect"}
            and ability_classes == {"EntersBattlefieldTriggeredAbility"}
            and not cost_classes
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 2
            and effect_json.get("etb_tutor_target") == "artifact_mana_value_3"
            and effect_json.get("etb_tutor_status") == "runtime_library_to_hand"
        )

    if effect == "creature" and scope == "activated_opponent_more_lands_land_tutor_to_hand_creature_v1":
        return (
            types == {"CREATURE"}
            and effect_classes == {"SearchLibraryPutInHandEffect"}
            and "ActivateIfConditionActivatedAbility" in ability_classes
            and "TapSourceCost" in cost_classes
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("land_tutor_to_hand_activated"))
            and int(effect_json.get("activation_cost_generic") or 0) == 0
            and effect_json.get("activation_cost_colors") == ["W"]
            and bool(effect_json.get("activation_requires_tap"))
            and effect_json.get("activation_condition") == "opponent_controls_more_lands"
            and effect_json.get("tutor_target") == "land"
            and effect_json.get("tutor_destination") == "hand"
        )

    if effect == "creature" and scope == "sand_scout_etb_desert_if_behind_lands_land_graveyard_token_v1":
        return (
            types == {"CREATURE"}
            and {"SearchLibraryPutInPlayEffect", "CreateTokenEffect"}.issubset(effect_classes)
            and {
                "EntersBattlefieldTriggeredAbility",
                "PutCardIntoGraveFromAnywhereAllTriggeredAbility",
            }.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 2
            and int(effect_json.get("etb_land_ramp_count") or 0) == 1
            and effect_json.get("etb_land_ramp_condition") == "opponent_controls_more_lands"
            and effect_json.get("land_subtypes_any") == ["desert"]
            and bool(effect_json.get("land_enters_tapped"))
            and bool(effect_json.get("land_cards_to_your_graveyard_create_token"))
            and bool(effect_json.get("land_graveyard_trigger_once_each_turn"))
            and effect_json.get("land_graveyard_token_name") == "Sand Warrior Token"
            and effect_json.get("land_graveyard_token_subtype") == "Sand Warrior"
            and effect_json.get("land_graveyard_token_colors") == ["R", "G", "W"]
            and int(effect_json.get("land_graveyard_token_power") or 0) == 1
            and int(effect_json.get("land_graveyard_token_toughness") or 0) == 1
        )

    if effect == "creature" and scope == "activated_land_tutor_with_land_sacrifice_and_graveyard_growth_v1":
        return (
            types == {"CREATURE"}
            and {
                "BoostSourceEffect",
                "ConditionalContinuousEffect",
                "SearchLibraryPutInPlayEffect",
            }.issubset(effect_classes)
            and {"SimpleActivatedAbility", "SimpleStaticAbility"}.issubset(ability_classes)
            and {"GenericManaCost", "SacrificeTargetCost", "TapSourceCost"}.issubset(cost_classes)
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 2
            and bool(effect_json.get("land_tutor_activated"))
            and int(effect_json.get("activation_cost_generic") or 0) == 2
            and bool(effect_json.get("activation_requires_tap"))
            and bool(effect_json.get("requires_sacrifice_land"))
            and int(effect_json.get("land_count") or 0) == 1
            and int(effect_json.get("lands_to_battlefield") or 0) == 1
            and bool(effect_json.get("land_enters_tapped"))
            and effect_json.get("tutor_target") == "land"
            and bool(effect_json.get("plus_two_two_if_three_lands_in_your_graveyard"))
        )

    if effect == "tutor" and scope == "convoke_creature_tutor_to_battlefield_mana_value_x_or_less_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"SearchLibraryWithLessCMCPutInPlayEffect"}
            and "ConvokeAbility" in ability_classes
            and bool(effect_json.get("instant"))
            and effect_json.get("target") == "creature_to_battlefield"
            and bool(effect_json.get("target_mana_value_max_from_x"))
            and bool(effect_json.get("convoke"))
        )

    if effect == "tutor" and scope == "green_creature_tutor_to_battlefield_mana_value_x_or_less_then_shuffle_self_v1":
        return (
            types == {"SORCERY"}
            and {"SearchLibraryWithLessCMCPutInPlayEffect", "ShuffleSpellEffect"}.issubset(effect_classes)
            and not ability_classes
            and not bool(effect_json.get("instant"))
            and effect_json.get("target") == "green_creature_to_battlefield"
            and bool(effect_json.get("target_mana_value_max_from_x"))
            and bool(effect_json.get("shuffle_self_into_library_on_resolution"))
        )

    if effect == "tutor" and scope == "improvise_artifact_tutor_to_battlefield_mana_value_x_or_less_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"SearchLibraryWithLessCMCPutInPlayEffect"}
            and "ImproviseAbility" in ability_classes
            and bool(effect_json.get("instant"))
            and effect_json.get("target") == "artifact_to_battlefield"
            and bool(effect_json.get("target_mana_value_max_from_x"))
            and bool(effect_json.get("improvise"))
        )

    if effect == "tutor" and scope == "creature_tutor_to_battlefield_mana_value_x_or_less_harmonize_v1":
        return (
            types == {"SORCERY"}
            and effect_classes == {"SearchLibraryPutInPlayEffect"}
            and "HarmonizeAbility" in ability_classes
            and not bool(effect_json.get("instant"))
            and effect_json.get("target") == "creature_to_battlefield"
            and bool(effect_json.get("target_mana_value_max_from_x"))
            and bool(effect_json.get("harmonize"))
        )

    if effect == "copy_spell" and scope == "first_instant_sorcery_cast_each_turn_copy_own_spell_v1":
        return (
            types == {"ENCHANTMENT"}
            and effect_classes == {"CopyTargetStackObjectEffect"}
            and {"DoubleVisionCopyTriggeredAbility", "SpellCastControllerTriggeredAbility"}.issubset(ability_classes)
            and effect_json.get("trigger") == "instant_sorcery_cast"
            and effect_json.get("trigger_effect") == "copy_spell"
            and effect_json.get("target") == "own_instant_or_sorcery_on_stack"
            and bool(effect_json.get("may_choose_new_targets"))
            and bool(effect_json.get("trigger_first_instant_or_sorcery_each_turn"))
        )

    if effect == "copy_spell" and scope == "instant_sorcery_cast_copy_own_spell_v1":
        return (
            types == {"ENCHANTMENT"}
            and effect_classes == {"CopyTargetStackObjectEffect"}
            and ability_classes == {"SpellCastControllerTriggeredAbility"}
            and effect_json.get("trigger") == "instant_sorcery_cast"
            and effect_json.get("trigger_effect") == "copy_spell"
            and effect_json.get("target") == "own_instant_or_sorcery_on_stack"
            and bool(effect_json.get("may_choose_new_targets"))
            and not bool(effect_json.get("trigger_first_instant_or_sorcery_each_turn"))
        )

    if effect == "copy_spell" and scope == "pyromancer_ascension_quest_counter_copy_spell_v1":
        return (
            types == {"ENCHANTMENT"}
            and {"AddCountersSourceEffect", "CopyTargetStackObjectEffect"}.issubset(effect_classes)
            and {
                "PyromancerAscensionQuestTriggeredAbility",
                "PyromancerAscensionCopyTriggeredAbility",
            }.issubset(ability_classes)
            and effect_json.get("trigger") == "instant_sorcery_cast"
            and effect_json.get("trigger_effect") == "pyromancer_ascension"
            and effect_json.get("target") == "own_instant_or_sorcery_on_stack"
            and bool(effect_json.get("may_choose_new_targets"))
            and bool(effect_json.get("quest_counter_on_same_name_in_graveyard"))
            and effect_json.get("quest_counter_name_match_zone") == "graveyard"
            and int(effect_json.get("quest_counter_threshold_to_copy") or 0) == 2
        )

    if effect == "copy_spell" and scope == "copy_target_instant_or_sorcery_spell_may_choose_new_targets_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"CopyTargetStackObjectEffect"}
            and ability_classes == {"CommanderStormAbility"}
            and not cost_classes
            and bool(effect_json.get("instant"))
            and effect_json.get("target") == "instant_or_sorcery_spell"
            and bool(effect_json.get("may_choose_new_targets"))
            and effect_json.get("choose_new_targets_status") == "may"
            and bool(effect_json.get("commander_storm"))
        )

    if effect == "untap_land_engine" and scope == "x_tap_untap_x_lands_v1":
        return (
            types == {"ARTIFACT"}
            and effect_classes == {"UntapTargetEffect"}
            and ability_classes == {"SimpleActivatedAbility"}
            and cost_classes == {"TapSourceCost"}
            and bool(effect_json.get("activated_untap_lands_for_mana_unlock"))
            and bool(effect_json.get("activation_requires_tap"))
            and bool(effect_json.get("activation_cost_generic_from_x"))
            and bool(effect_json.get("untap_target_land_count_from_x"))
            and effect_json.get("untap_target_land_restriction") == "land"
        )

    if effect == "untap_land_engine" and scope == "tap_untapped_creature_untap_target_basic_land_v1":
        return (
            types == {"ENCHANTMENT"}
            and effect_classes == {"UntapTargetEffect"}
            and ability_classes == {"SimpleActivatedAbility"}
            and cost_classes == {"TapTargetCost"}
            and bool(effect_json.get("activated_untap_lands_for_mana_unlock"))
            and bool(effect_json.get("activation_taps_untapped_creature_you_control"))
            and int(effect_json.get("untap_target_land_count") or 0) == 1
            and bool(effect_json.get("untap_target_land_basic_only"))
        )

    if effect == "untap_land_engine" and scope == "creature_x_tap_untap_x_lands_v1":
        return (
            types == {"CREATURE"}
            and effect_classes == {"UntapTargetEffect"}
            and ability_classes == {"SimpleActivatedAbility"}
            and cost_classes == {"TapSourceCost"}
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 2
            and bool(effect_json.get("activated_untap_lands_for_mana_unlock"))
            and bool(effect_json.get("activation_requires_tap"))
            and bool(effect_json.get("activation_cost_generic_from_x"))
            and bool(effect_json.get("untap_target_land_count_from_x"))
            and effect_json.get("untap_target_land_restriction") == "land"
        )

    if effect == "untap_land_engine" and scope == "pay_two_return_land_untap_target_land_v1":
        return (
            types == {"CREATURE"}
            and effect_classes == {"UntapTargetEffect"}
            and {"FlyingAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
            and {"GenericManaCost", "ReturnToHandChosenControlledPermanentCost"}.issubset(cost_classes)
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("flying"))
            and bool(effect_json.get("activated_untap_lands_for_mana_unlock"))
            and int(effect_json.get("activation_cost_generic") or 0) == 2
            and bool(effect_json.get("activation_returns_land_to_hand"))
            and int(effect_json.get("untap_target_land_count") or 0) == 1
            and effect_json.get("untap_target_land_restriction") == "land"
        )

    if effect == "extra_turn" and scope == "single_extra_turn_then_lose_game_v1":
        return (
            types in ({"INSTANT"}, {"SORCERY"})
            and effect_classes == {"AddExtraTurnControllerEffect"}
            and not ability_classes
            and not cost_classes
            and bool(effect_json.get("instant")) == (types == {"INSTANT"})
            and int(effect_json.get("turns") or 0) == 1
            and bool(effect_json.get("lose_after_extra_turn"))
        )

    if effect == "dig_to_hand" and scope == "look_top_n_pick_m_to_hand_rest_graveyard_v1":
        look_count = int(effect_json.get("look_count") or 0)
        pick_count = int(effect_json.get("pick_count") or 0)
        return (
            types in ({"INSTANT"}, {"SORCERY"})
            and effect_classes == {"LookLibraryAndPickControllerEffect"}
            and not ability_classes
            and not cost_classes
            and bool(effect_json.get("instant")) == (types == {"INSTANT"})
            and look_count > 0
            and pick_count > 0
            and pick_count <= look_count
            and effect_json.get("selection_destination") == "hand"
            and effect_json.get("remainder_destination") == "graveyard"
        )

    if effect == "pile_selection_draw" and scope == "reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1":
        look_count = int(effect_json.get("look_count") or 0)
        return (
            types in ({"INSTANT"}, {"SORCERY"})
            and effect_classes == {"RevealAndSeparatePilesEffect"}
            and not ability_classes
            and not cost_classes
            and bool(effect_json.get("instant")) == (types == {"INSTANT"})
            and look_count > 0
            and int(effect_json.get("pile_count") or 0) == 2
            and effect_json.get("splitter") in {"controller", "opponent"}
            and effect_json.get("chooser") in {"controller", "opponent"}
            and effect_json.get("selection_destination") == "hand"
            and effect_json.get("remainder_destination") == "graveyard"
        )

    if effect == "treasure_maker" and scope == "single_treasure_creation_v1":
        return (
            types == {"SORCERY"}
            and "CreateTokenEffect" in effect_classes
            and int(effect_json.get("treasure_count") or 0) == 1
        )

    if effect == "treasure_maker" and scope == "discard_draw_two_create_two_treasures_v1":
        return (
            types == {"SORCERY"}
            and {"CreateTokenEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
            and int(effect_json.get("treasure_count") or 0) == 2
            and int(effect_json.get("draw_count") or 0) == 2
            and bool(effect_json.get("requires_discard_card"))
        )

    if effect == "treasure_maker" and scope == "activated_xx_tap_sacrifice_create_x_treasures_v1":
        return (
            types == {"ARTIFACT", "LAND"}
            and "CreateTokenEffect" in effect_classes
            and {"ColorlessManaAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
            and {"TapSourceCost", "SacrificeSourceCost"}.issubset(cost_classes)
            and bool(effect_json.get("activation_requires_tap"))
            and bool(effect_json.get("activation_requires_sacrifice"))
            and bool(effect_json.get("activation_cost_generic_is_x_twice"))
            and effect_json.get("treasure_count_source") == "x_value"
            and int(effect_json.get("treasure_count_per_x") or 0) == 1
        )

    if effect == "copy_creature_token" and scope == "copy_target_creature_you_control_haste_sacrifice_end_step_v1":
        return (
            "SORCERY" in types
            and "CreateTokenCopyTargetEffect" in effect_classes
            and effect_json.get("copy_target_types") == ["creature"]
            and effect_json.get("target_controller") == "own"
            and bool(effect_json.get("token_haste"))
            and bool(effect_json.get("sacrifice_token_at_end_step"))
        )

    if effect == "copy_creature_token" and scope == "copy_target_permanent_v1":
        return (
            types == {"SORCERY"}
            and "CreateTokenCopyTargetEffect" in effect_classes
            and effect_json.get("copy_target_types") == ["permanent"]
            and effect_json.get("target_controller") == "any"
            and not bool(effect_json.get("token_haste"))
            and not bool(effect_json.get("sacrifice_token_at_end_step"))
            and not bool(effect_json.get("exile_token_at_end_step"))
        )

    if effect == "copy_creature_token" and scope == "copy_each_creature_target_player_controls_v1":
        return (
            types == {"SORCERY"}
            and "CreateTokenCopyTargetEffect" in effect_classes
            and effect_json.get("copy_target_types") == ["creature"]
            and effect_json.get("target_controller") == "opponent"
            and bool(effect_json.get("copy_all_matching_targets"))
        )

    if effect == "copy_creature_token" and scope == "copy_target_another_creature_you_control_haste_draw_on_death_sacrifice_end_step_v1":
        return (
            types == {"CREATURE"}
            and "CreateTokenCopyTargetEffect" in effect_classes
            and effect_json.get("copy_target_types") == ["creature"]
            and effect_json.get("target_controller") == "own"
            and bool(effect_json.get("exclude_source_from_copy_targets"))
            and bool(effect_json.get("token_haste"))
            and int(effect_json.get("token_draw_cards_when_this_dies") or 0) == 1
            and bool(effect_json.get("sacrifice_token_at_end_step"))
        )

    if effect == "copy_creature_token" and scope == "copy_target_another_creature_you_control_x_instant_sorcery_plus_one_haste_exile_end_step_v1":
        return (
            types == {"CREATURE"}
            and "CreateTokenCopyTargetEffect" in effect_classes
            and "BeginningOfCombatTriggeredAbility" in ability_classes
            and effect_json.get("copy_target_types") == ["creature"]
            and effect_json.get("target_controller") == "own"
            and bool(effect_json.get("exclude_source_from_copy_targets"))
            and effect_json.get("token_count_source") == "instant_or_sorcery_spells_cast_this_turn_plus_one"
            and bool(effect_json.get("token_haste"))
            and bool(effect_json.get("exile_token_at_end_step"))
        )

    if effect == "copy_creature_token" and scope == "copy_target_another_creature_you_control_balloon_1_1_red_flying_haste_sacrifice_end_step_v1":
        return (
            types == {"CREATURE"}
            and "CreateTokenCopyTargetEffect" in effect_classes
            and "ActivateAsSorceryActivatedAbility" in ability_classes
            and effect_json.get("copy_target_types") == ["creature"]
            and effect_json.get("target_controller") == "own"
            and bool(effect_json.get("exclude_source_from_copy_targets"))
            and bool(effect_json.get("force_token_creature"))
            and int(effect_json.get("token_power") or 0) == 1
            and int(effect_json.get("token_toughness") or 0) == 1
            and effect_json.get("token_extra_colors") == ["R"]
            and effect_json.get("token_subtype") == "Balloon"
            and bool(effect_json.get("token_flying"))
            and bool(effect_json.get("token_haste"))
            and bool(effect_json.get("sacrifice_token_at_end_step"))
        )

    if effect == "copy_permanent_etb" and scope == "etb_copy_target_permanent_with_optional_extra_type_v1":
        target_types = effect_json.get("copy_target_types")
        additional_types = effect_json.get("copy_additional_types") or []
        return (
            bool(types)
            and types.issubset({"ARTIFACT", "CREATURE", "ENCHANTMENT"})
            and "CopyPermanentEffect" in effect_classes
            and "EntersBattlefieldAbility" in ability_classes
            and target_types in (
                ["artifact"],
                ["artifact", "creature"],
                ["artifact", "enchantment"],
                ["enchantment"],
                ["nonland_permanent"],
            )
            and effect_json.get("target_controller") == "any"
            and set(additional_types).issubset({"artifact", "enchantment"})
        )

    if effect == "copy_permanent_etb" and scope == "etb_copy_target_creature_with_copy_applier_modifiers_v1":
        additional_types = effect_json.get("copy_additional_types") or []
        additional_subtypes = effect_json.get("copy_additional_subtypes") or []
        granted_keywords = effect_json.get("copy_granted_keywords") or []
        overwrite_types = effect_json.get("copy_overwrite_types") or []
        overwrite_subtypes = effect_json.get("copy_overwrite_subtypes") or []
        crew_value = effect_json.get("copy_vehicle_crew_value")
        return (
            bool(types)
            and types.issubset({"ARTIFACT", "CREATURE"})
            and "CopyPermanentEffect" in effect_classes
            and "EntersBattlefieldAbility" in ability_classes
            and effect_json.get("copy_target_types") == ["creature"]
            and effect_json.get("target_controller") in {"any", "opponent"}
            and set(additional_types).issubset({"artifact"})
            and set(additional_subtypes).issubset({"Bird", "Illusion"})
            and set(granted_keywords).issubset({"flying", "haste"})
            and set(overwrite_types).issubset({"artifact"})
            and set(overwrite_subtypes).issubset({"Vehicle"})
            and (crew_value is None or int(crew_value) == 3)
            and effect_json.get("copy_target_mana_value_lte_source_mana_value") in {None, False, True}
            and (
                effect_json.get("copy_grant_vanishing_if_missing") is None
                or int(effect_json.get("copy_grant_vanishing_if_missing") or 0) == 3
            )
            and effect_json.get("copy_sacrifice_when_targeted") in {None, False, True}
        )

    if effect == "creature" and scope == "landfall_optional_pay_copy_attached_creature_else_insect_v1":
        return (
            types == {"CREATURE", "ENCHANTMENT"}
            and {"CreateTokenCopyTargetEffect", "CreateTokenEffect", "BoostEnchantedEffect"}.issubset(effect_classes)
            and {"BestowAbility", "LandfallAbility"}.issubset(ability_classes)
            and bool(effect_json.get("is_creature_permanent"))
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("landfall_optional_pay_copy_attached_creature_else_insect"))
            and effect_json.get("landfall_copy_cost") == "{1}{G}"
            and effect_json.get("bestow_cost") == "{1}{G}"
            and int(effect_json.get("bestow_attached_creature_power_bonus") or 0) == 1
            and int(effect_json.get("bestow_attached_creature_toughness_bonus") or 0) == 1
            and effect_json.get("token_name") == "Insect Token"
            and effect_json.get("token_subtype") == "Insect"
            and effect_json.get("token_colors") == ["G"]
            and int(effect_json.get("token_power") or 0) == 1
            and int(effect_json.get("token_toughness") or 0) == 1
        )

    if effect == "ramp_permanent" and scope == "artifact_etb_or_dies_create_treasure_v1":
        return (
            types == {"ARTIFACT"}
            and effect_classes == {"CreateTokenEffect"}
            and ability_classes == {"EntersBattlefieldOrDiesSourceTriggeredAbility"}
            and int(effect_json.get("treasure_count") or 0) == 1
            and int(effect_json.get("enters_treasure") or 0) == 1
            and bool(effect_json.get("dies_or_graveyard_from_battlefield_treasure"))
        )

    if effect == "creature" and scope == "dies_create_treasure_encore_v1":
        return (
            types == {"CREATURE"}
            and effect_classes == {"CreateTokenEffect"}
            and {"DiesSourceTriggeredAbility", "EncoreAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("dies_or_graveyard_from_battlefield_treasure"))
            and int(effect_json.get("treasure_count") or 0) == 1
            and effect_json.get("encore_cost") == "{3}{R}"
        )

    if effect == "creature" and scope == "activated_untap_self_create_1_1_white_kithkin_soldier_token_v1":
        return (
            types == {"CREATURE"}
            and effect_classes == {"CreateTokenEffect"}
            and ability_classes == {"SimpleActivatedAbility"}
            and "UntapSourceCost" in cost_classes
            and bool(effect_json.get("is_creature_permanent"))
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("activated_create_token"))
            and bool(effect_json.get("activation_requires_source_tapped"))
            and bool(effect_json.get("activation_uses_untap_symbol"))
            and int(effect_json.get("activation_cost_generic") or 0) == 1
            and effect_json.get("activation_cost_colors") == ["W"]
            and int(effect_json.get("token_count") or 0) == 1
            and effect_json.get("token_name") == "Kithkin Soldier Token"
            and effect_json.get("token_subtype") == "Kithkin Soldier"
            and effect_json.get("token_colors") == ["W"]
            and int(effect_json.get("token_power") or 0) == 1
            and int(effect_json.get("token_toughness") or 0) == 1
        )

    if effect == "creature" and scope == "etb_copy_target_noncreature_permanent_twice_as_3_3_flying_dragon_v1":
        return (
            types == {"CREATURE"}
            and effect_classes == {"CreateTokenCopyTargetEffect"}
            and "EntersBattlefieldTriggeredAbility" in ability_classes
            and int(effect_json.get("power") or 0) == 4
            and int(effect_json.get("toughness") or 0) == 4
            and bool(effect_json.get("flying"))
            and effect_json.get("etb_copy_target_types") == ["noncreature_permanent"]
            and int(effect_json.get("etb_copy_token_count") or 0) == 2
            and bool(effect_json.get("etb_copy_force_creature"))
            and int(effect_json.get("etb_copy_token_power") or 0) == 3
            and int(effect_json.get("etb_copy_token_toughness") or 0) == 3
            and bool(effect_json.get("etb_copy_token_flying"))
            and effect_json.get("etb_copy_token_subtype") == "Dragon"
        )

    if effect == "ramp_engine" and scope == "opponent_second_spell_each_turn_create_treasure_life_loss_v1":
        return (
            types == {"CREATURE"}
            and {"CreateTokenEffect", "LoseLifeSourceControllerEffect"}.issubset(effect_classes)
            and ability_classes == {"CastSecondSpellTriggeredAbility"}
            and bool(effect_json.get("is_creature_permanent"))
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 1
            and effect_json.get("trigger") == "opponent_spell"
            and bool(effect_json.get("opponent_second_spell_each_turn"))
            and int(effect_json.get("treasure_count") or 0) == 1
            and int(effect_json.get("controller_loses_life_on_trigger") or 0) == 1
            and not bool(effect_json.get("draw_on_enter"))
        )

    if effect == "ramp_engine" and scope == "etb_draw_target_opponent_may_draw_off_turn_once_each_turn_tapped_treasure_v1":
        return (
            types == {"CREATURE"}
            and {"CreateTokenEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
            and {"DrawCardOpponentTriggeredAbility", "EntersBattlefieldTriggeredAbility"}.issubset(ability_classes)
            and bool(effect_json.get("is_creature_permanent"))
            and int(effect_json.get("power") or 0) == 0
            and int(effect_json.get("toughness") or 0) == 3
            and effect_json.get("trigger") == "opponent_draw"
            and int(effect_json.get("treasure_count") or 0) == 1
            and bool(effect_json.get("treasure_tokens_tapped"))
            and bool(effect_json.get("trigger_only_off_turn_opponent_draw"))
            and int(effect_json.get("trigger_limit_each_turn") or 0) == 1
            and int(effect_json.get("etb_draw_count") or 0) == 1
            and int(effect_json.get("etb_target_opponent_may_draw_count") or 0) == 1
            and effect_json.get("etb_target_opponent_may_draw_choice_model")
            == "compact_assume_yes_single_card_v1"
        )

    if effect == "ramp_engine" and scope == "one_or_more_creatures_you_control_combat_damage_player_create_treasure_v1":
        return (
            types == {"CREATURE"}
            and "CreateTokenEffect" in effect_classes
            and effect_classes.issubset({"CreateTokenEffect", "WinGameSourceControllerEffect"})
            and "OneOrMoreCombatDamagePlayerTriggeredAbility" in ability_classes
            and bool(effect_json.get("is_creature_permanent"))
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 4
            and bool(effect_json.get("double_strike"))
            and bool(effect_json.get("trample"))
            and bool(effect_json.get("haste"))
            and effect_json.get("trigger") == "combat_damage_to_player"
            and bool(effect_json.get("trigger_creatures_you_control"))
            and int(effect_json.get("treasure_count") or 0) == 1
            and int(effect_json.get("upkeep_win_if_control_artifacts_at_least") or 0) == 30
            and effect_json.get("upkeep_win_status") == "annotation_only"
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

    if effect == "creature" and scope == "sacrifice_another_creature_or_artifact_put_plus_one_counter_on_self_v1":
        return (
            types == {"CREATURE"}
            and "AddCountersSourceEffect" in effect_classes
            and "SimpleActivatedAbility" in ability_classes
            and "SacrificeTargetCost" in xmage_cost_classes(card)
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 1
            and effect_json.get("activation_cost") == "sacrifice_creature_or_artifact"
            and int(effect_json.get("self_add_plus_one_counter") or 0) == 1
        )

    if effect == "creature" and scope == "one_mana_one_one_green_mana_dork_v1":
        return (
            types == {"CREATURE"}
            and ability_classes == {"GreenManaAbility"}
            and not effect_classes
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("is_mana_source"))
            and int(effect_json.get("mana_produced") or 0) == 1
            and effect_json.get("produces") == "G"
        )

    if effect == "creature" and scope == "one_mana_one_one_black_pain_mana_dork_v1":
        return (
            types == {"CREATURE"}
            and ability_classes == {"SimpleManaAbility"}
            and effect_classes == {"DamageControllerEffect"}
            and xmage_cost_classes(card) == {"TapSourceCost"}
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("is_mana_source"))
            and int(effect_json.get("mana_produced") or 0) == 1
            and effect_json.get("produces") == "B"
            and int(effect_json.get("damage_on_tap") or 0) == 1
            and effect_json.get("tap_damage_status") == "annotation_only"
        )

    if effect == "creature" and scope == "one_mana_one_one_white_mana_dork_v1":
        return (
            types == {"CREATURE"}
            and ability_classes == {"WhiteManaAbility"}
            and not effect_classes
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("is_mana_source"))
            and int(effect_json.get("mana_produced") or 0) == 1
            and effect_json.get("produces") == "W"
        )

    if effect == "creature" and scope == "one_mana_zero_one_flying_any_color_mana_dork_v1":
        return (
            types == {"CREATURE"}
            and ability_classes == {"AnyColorManaAbility", "FlyingAbility"}
            and not effect_classes
            and int(effect_json.get("power") or 0) == 0
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("flying"))
            and bool(effect_json.get("is_mana_source"))
            and int(effect_json.get("mana_produced") or 0) == 1
            and effect_json.get("produces") == "WUBRG"
        )

    if effect == "creature" and scope == "one_mana_zero_one_exalted_tricolor_mana_dork_v1":
        return (
            types == {"CREATURE"}
            and ability_classes in (
                {"BlueManaAbility", "ExaltedAbility", "GreenManaAbility", "WhiteManaAbility"},
                {"BlackManaAbility", "ExaltedAbility", "GreenManaAbility", "RedManaAbility"},
            )
            and not effect_classes
            and int(effect_json.get("power") or 0) == 0
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("exalted"))
            and bool(effect_json.get("is_mana_source"))
            and int(effect_json.get("mana_produced") or 0) == 1
            and effect_json.get("produces") in {"GWU", "BRG"}
        )

    if effect == "creature" and scope == "one_one_color_diversity_mana_dork_v1":
        return (
            types == {"CREATURE"}
            and ability_classes == {"AddEachControlledColorManaAbility"}
            and not effect_classes
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("is_mana_source"))
            and bool(effect_json.get("mana_produced_from_colors_among_permanents"))
            and bool(effect_json.get("mana_colors_from_controlled_permanents"))
            and effect_json.get("produces") == "WUBRG"
        )

    if effect == "creature" and scope == "two_one_green_per_creature_mana_dork_v1":
        return (
            types == {"CREATURE"}
            and ability_classes == {"DynamicManaAbility"}
            and not effect_classes
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("is_mana_source"))
            and bool(effect_json.get("mana_produced_from_controlled_creatures"))
            and effect_json.get("produces") == "G"
        )

    if effect == "land" and scope == "basic_one_color_land_v1":
        return (
            types == {"LAND"}
            and not effect_classes
            and ability_classes in ({"WhiteManaAbility"}, {"RedManaAbility"})
            and int(effect_json.get("mana_produced") or 0) == 1
            and effect_json.get("produces") in {"W", "R"}
            and effect_json.get("basic_land_types") in (["Plains"], ["Mountain"])
        )

    if effect == "land" and scope == "any_color_from_opponent_land_production_v1":
        return (
            types == {"LAND"}
            and not effect_classes
            and ability_classes == {"AnyColorLandsProduceManaAbility"}
            and int(effect_json.get("mana_produced") or 0) == 1
            and effect_json.get("produces") == "WUBRG"
            and bool(effect_json.get("opponent_land_color_dependency"))
        )

    if effect == "land" and scope == "colorless_or_any_color_pain_land_v1":
        return (
            types == {"LAND"}
            and effect_classes == {"DamageControllerEffect"}
            and ability_classes == {"AnyColorManaAbility", "SimpleManaAbility"}
            and xmage_cost_classes(card) == {"TapSourceCost"}
            and int(effect_json.get("mana_produced") or 0) == 1
            and effect_json.get("produces") == "CWUBRG"
            and int(effect_json.get("life_for_colored_mana") or 0) == 3
            and effect_json.get("life_loss_on_colored_mana_status") == "annotation_only"
        )

    if effect == "ramp_permanent" and scope == "creature_support_any_color_mana_rock_v1":
        return (
            types == {"ARTIFACT"}
            and ability_classes == {"AnyColorManaAbility"}
            and not effect_classes
            and xmage_cost_classes(card) == {"TapTargetCost"}
            and int(effect_json.get("mana_produced") or 0) == 1
            and effect_json.get("produces") == "WUBRG"
            and bool(effect_json.get("mana_source_requires_untapped_creature"))
        )

    if effect == "ramp_permanent" and scope == "one_any_color_mana_rock_v1":
        return (
            types == {"ARTIFACT"}
            and ability_classes == {"AnyColorManaAbility"}
            and not effect_classes
            and int(effect_json.get("mana_produced") or 0) == 1
            and effect_json.get("produces") == "WUBRG"
            and not effect_json.get("mana_source_requires_untapped_creature")
        )

    if effect == "ramp_permanent" and scope == "pain_talisman_color_pair_partial_v1":
        return (
            types == {"ARTIFACT"}
            and "ColorlessManaAbility" in ability_classes
            and effect_classes == {"DamageControllerEffect"}
            and int(effect_json.get("mana_produced") or 0) == 1
            and isinstance(effect_json.get("produces"), str)
            and len(effect_json.get("produces")) == 3
            and "C" in effect_json.get("produces")
            and int(effect_json.get("life_for_colored_mana") or 0) == 1
        )

    if effect == "ramp_permanent" and scope == "artifact_or_creature_support_colorless_mana_rock_v1":
        return (
            types == {"ARTIFACT"}
            and "ColorlessManaAbility" in ability_classes
            and "TapTargetCost" in xmage_cost_classes(card)
            and int(effect_json.get("mana_produced") or 0) == 1
            and effect_json.get("produces") == "C"
            and bool(effect_json.get("mana_source_requires_untapped_artifact_or_creature"))
        )

    if effect == "ramp_permanent" and scope == "three_colorless_monolith_mana_rock_v1":
        return (
            types == {"ARTIFACT"}
            and {
                "DontUntapInControllersUntapStepSourceEffect",
                "UntapSourceEffect",
            }.issubset(effect_classes)
            and {
                "SimpleActivatedAbility",
                "SimpleManaAbility",
                "SimpleStaticAbility",
            }.issubset(ability_classes)
            and int(effect_json.get("mana_produced") or 0) == 3
            and effect_json.get("produces") == "C"
            and bool(effect_json.get("does_not_untap_in_untap_step"))
            and int(effect_json.get("activated_untap_cost_generic") or 0) in {3, 4}
        )

    if effect == "land_ramp" and scope == "sacrifice_land_for_any_land_to_battlefield_untapped_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"SearchLibraryPutInPlayEffect"}
            and not ability_classes
            and cost_classes == {"SacrificeTargetCost"}
            and bool(effect_json.get("instant"))
            and bool(effect_json.get("requires_sacrifice_land"))
            and int(effect_json.get("land_count") or 0) == 1
            and int(effect_json.get("lands_to_battlefield") or 0) == 1
            and not bool(effect_json.get("land_enters_tapped"))
            and effect_json.get("tutor_target") == "land"
        )

    if effect == "ramp_permanent" and scope == "two_colorless_mana_rock_v1":
        return (
            types == {"ARTIFACT"}
            and ability_classes == {"SimpleManaAbility"}
            and not effect_classes
            and xmage_cost_classes(card) == {"TapSourceCost"}
            and int(effect_json.get("mana_produced") or 0) == 2
            and effect_json.get("produces") == "C"
        )

    if effect == "ramp_permanent" and scope == "signet_filter_mana_rock_v1":
        return (
            types == {"ARTIFACT"}
            and ability_classes == {"SimpleManaAbility"}
            and not effect_classes
            and xmage_cost_classes(card) == {"GenericManaCost", "TapSourceCost"}
            and int(effect_json.get("mana_produced") or 0) == 1
            and effect_json.get("produces") in {"UR", "GU"}
            and int(effect_json.get("activation_cost_generic") or 0) == 1
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

    if effect == "creature" and scope == "instant_sorcery_cast_add_counter_then_power_damage_target_opponent_v1":
        target_classes = xmage_target_classes(card)
        return (
            types == {"CREATURE"}
            and effect_classes == {"AddCountersSourceEffect", "DamageTargetEffect"}
            and {"FlyingAbility", "SpellCastControllerTriggeredAbility"}.issubset(ability_classes)
            and target_classes == {"TargetOpponent"}
            and int(effect_json.get("power") or 0) == 3
            and int(effect_json.get("toughness") or 0) == 3
            and bool(effect_json.get("flying"))
            and effect_json.get("trigger") == "instant_sorcery_cast"
            and effect_json.get("trigger_effect") == "source_counter_then_power_damage"
            and int(effect_json.get("trigger_add_plus_one_counter") or 0) == 1
            and effect_json.get("trigger_damage_amount_source") == "source_power_after_counter"
            and effect_json.get("target") == "opponent"
        )

    if scope == "opponent_draws_card_damage_that_player_v1":
        common = (
            effect_json.get("trigger") == "opponent_draw"
            and int(effect_json.get("opponent_draw_damage_per_card") or 0) == 1
            and effect_classes == {"DamageTargetEffect"}
            and ability_classes == {"DrawCardOpponentTriggeredAbility"}
        )
        if effect == "creature":
            return (
                common
                and types == {"CREATURE", "ENCHANTMENT"}
                and int(effect_json.get("power") or 0) == 3
                and int(effect_json.get("toughness") or 0) == 4
            )
        if effect == "passive":
            return common and types == {"ENCHANTMENT"}
        return False

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

    if effect == "creature" and scope == "flash_flying_vigilance_etb_x_counters_draw_half_x_opponent_search_growth_v1":
        return (
            types == {"CREATURE"}
            and {"AddCountersSourceEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
            and {"EntersBattlefieldTriggeredAbility", "FlashAbility", "FlyingAbility", "VigilanceAbility", "WanShiTongLibrarianTriggeredAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("flash"))
            and bool(effect_json.get("flying"))
            and bool(effect_json.get("vigilance"))
            and bool(effect_json.get("etb_add_x_plus_one_counters"))
            and bool(effect_json.get("etb_draw_half_x_rounded_down"))
            and bool(effect_json.get("opponent_search_library_add_counter_and_draw"))
        )

    if effect == "creature" and scope == "flash_etb_or_opponent_extra_draw_damage_any_target_amass_orcs_v1":
        return (
            types == {"CREATURE"}
            and {"DamageTargetEffect", "AmassEffect"}.issubset(effect_classes)
            and {"FlashAbility", "OrTriggeredAbility", "EntersBattlefieldTriggeredAbility", "OpponentDrawCardExceptFirstCardDrawStepTriggeredAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("flash"))
            and int(effect_json.get("etb_or_opponent_extra_draw_damage_any_target") or 0) == 1
            and int(effect_json.get("amass_orcs") or 0) == 1
        )

    if effect == "creature" and scope == "flash_cant_be_countered_cast_spell_bounce_spell_or_nonland_v1":
        return (
            types == {"CREATURE"}
            and effect_classes == {"ReturnToHandTargetEffect"}
            and {"CantBeCounteredSourceAbility", "FlashAbility", "SpellCastControllerTriggeredAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 7
            and int(effect_json.get("toughness") or 0) == 8
            and bool(effect_json.get("flash"))
            and bool(effect_json.get("cant_be_countered"))
            and bool(effect_json.get("cast_spell_trigger_bounce_spell_you_dont_control"))
            and bool(effect_json.get("cast_spell_trigger_bounce_nonland_permanent"))
        )

    if effect == "creature" and scope == "graveyard_exile_mana_or_life_shaman_v1":
        return (
            types == {"CREATURE"}
            and {"ExileTargetEffect", "AddManaOfAnyColorEffect", "LoseLifeOpponentsEffect", "GainLifeEffect"}.issubset(effect_classes)
            and ability_classes == {"SimpleActivatedAbility"}
            and "TapSourceCost" in xmage_cost_classes(card)
            and int(effect_json.get("power") or 0) == 1
            and int(effect_json.get("toughness") or 0) == 2
            and bool(effect_json.get("tap_exile_land_from_graveyard_add_one_mana_any_color"))
            and int(effect_json.get("black_tap_exile_instant_or_sorcery_from_graveyard_each_opponent_loses_life") or 0) == 2
            and int(effect_json.get("green_tap_exile_creature_from_graveyard_gain_life") or 0) == 2
        )

    if effect == "creature" and scope == "evoke_etb_red_damage_or_green_land_tutor_lifegain_v1":
        return (
            types == {"CREATURE"}
            and {"DamageTargetEffect", "GainLifeEffect", "SearchLibraryPutInHandEffect"}.issubset(effect_classes)
            and {"EntersBattlefieldTriggeredAbility", "EvokeAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 4
            and int(effect_json.get("toughness") or 0) == 4
            and effect_json.get("evoke_cost") == "{R/G}{R/G}"
            and int(effect_json.get("etb_if_red_red_spent_damage_any_target") or 0) == 3
            and bool(effect_json.get("etb_if_green_green_spent_search_land_to_hand"))
            and int(effect_json.get("etb_if_green_green_spent_gain_life") or 0) == 2
        )

    if effect == "creature" and scope == "defender_sacrifice_for_rr_or_blocking_damage_v1":
        return (
            types == {"CREATURE"}
            and effect_classes == {"DamageTargetEffect"}
            and {"DefenderAbility", "SimpleActivatedAbility", "SimpleManaAbility"}.issubset(ability_classes)
            and "SacrificeSourceCost" in xmage_cost_classes(card)
            and int(effect_json.get("power") or 0) == 0
            and int(effect_json.get("toughness") or 0) == 3
            and bool(effect_json.get("defender"))
            and int(effect_json.get("sacrifice_for_red_mana") or 0) == 2
            and int(effect_json.get("red_sacrifice_damage_blocking_creature") or 0) == 2
        )

    if effect == "creature" and scope == "etb_sacrifice_another_creature_create_treasures_and_x_artifact_reanimate_v1":
        return (
            types == {"CREATURE"}
            and {"OneShotEffect", "ReturnFromGraveyardToBattlefieldTargetEffect", "RuthlessTechnomancerEffect"}.issubset(effect_classes)
            and {"EntersBattlefieldTriggeredAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
            and "SacrificeXTargetCost" in xmage_cost_classes(card)
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 4
            and bool(effect_json.get("etb_may_sacrifice_another_creature_create_treasures_equal_power"))
            and effect_json.get("activated_cost") == "{2}{B}"
            and bool(effect_json.get("activated_sacrifice_x_artifacts_return_creature_with_power_x_or_less"))
        )

    if effect == "creature" and scope == "combat_exile_adapt_finality_reanimate_v1":
        return (
            types == {"CREATURE"}
            and {"EmperorOfBonesEffect", "ExileTargetEffect", "GainAbilityTargetEffect", "SacrificeTargetEffect"}.issubset(effect_classes)
            and {"AdaptAbility", "BeginningOfCombatTriggeredAbility", "OneOrMoreCountersAddedTriggeredAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 2
            and bool(effect_json.get("beginning_of_combat_exile_up_to_one_card_from_graveyard"))
            and effect_json.get("adapt_cost") == "{1}{B}"
            and int(effect_json.get("adapt_counters") or 0) == 2
            and bool(effect_json.get("counters_trigger_reanimate_exiled_creature_with_finality_haste_and_sacrifice_eot"))
        )

    if effect == "creature" and scope == "etb_sacrifice_another_creature_gain_draw_power_or_tapped_green_land_v1":
        return (
            types == {"CREATURE", "LAND"}
            and {"DiscipleOfFreyaliseEffect", "DrawCardSourceControllerEffect", "GainLifeEffect", "OneShotEffect", "TapSourceUnlessPaysEffect"}.issubset(effect_classes)
            and {"AsEntersBattlefieldAbility", "EntersBattlefieldTriggeredAbility", "GreenManaAbility"}.issubset(ability_classes)
            and int(effect_json.get("power") or 0) == 3
            and int(effect_json.get("toughness") or 0) == 3
            and bool(effect_json.get("etb_may_sacrifice_another_creature_gain_life_and_draw_equal_power"))
            and bool(effect_json.get("land_side_pay_three_life_else_tapped"))
            and effect_json.get("land_side_add_mana") == "G"
        )

    if effect == "creature" and scope == "x_etb_counters_add_counter_or_remove_counter_ping_v1":
        return (
            types == {"ARTIFACT", "CREATURE"}
            and {"AddCountersSourceEffect", "DamageTargetEffect", "EntersBattlefieldWithXCountersEffect"}.issubset(effect_classes)
            and {"EntersBattlefieldAbility", "SimpleActivatedAbility"}.issubset(ability_classes)
            and {"GenericManaCost", "RemoveCountersSourceCost"}.issubset(xmage_cost_classes(card))
            and int(effect_json.get("power") or 0) == 0
            and int(effect_json.get("toughness") or 0) == 0
            and bool(effect_json.get("enters_with_x_plus_one_counters"))
            and int(effect_json.get("activated_generic_four_add_plus_one_counter") or 0) == 1
            and int(effect_json.get("activated_remove_plus_one_counter_damage_any_target") or 0) == 1
        )

    if effect == "draw_cards" and scope == "draw_one_and_source_controller_spells_gain_flash_until_eot_v1":
        return (
            types == {"INSTANT"}
            and {"CastAsThoughItHadFlashAllEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
            and int(effect_json.get("count") or 0) == 1
            and bool(effect_json.get("instant"))
            and bool(effect_json.get("source_controller_spells_have_flash_until_eot"))
        )

    if effect == "draw_cards" and scope == "add_two_mana_any_combination_then_draw_v1":
        return (
            types == {"INSTANT"}
            and {"AddManaInAnyCombinationEffect", "DrawCardSourceControllerEffect"}.issubset(effect_classes)
            and not ability_classes
            and int(effect_json.get("count") or 0) == 1
            and bool(effect_json.get("instant"))
            and int(effect_json.get("add_mana_any_combination") or 0) == 2
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

    if effect == "passive" and scope == "graveyard_exile_counter_and_ability_grant_artifact_v1":
        return (
            types == {"ARTIFACT"}
            and {
                "AddCountersTargetEffect",
                "AgathasSoulCauldronAbilityEffect",
                "AgathasSoulCauldronExileEffect",
                "AgathasSoulCauldronManaEffect",
                "AsThoughManaEffect",
                "OneShotEffect",
            }.issubset(effect_classes)
            and {"SimpleActivatedAbility", "SimpleStaticAbility", "ReflexiveTriggeredAbility"}.issubset(ability_classes)
            and "TapSourceCost" in xmage_cost_classes(card)
            and bool(effect_json.get("mana_as_any_color_for_creature_activations"))
            and bool(effect_json.get("plus_one_counter_creatures_gain_activated_abilities_of_exiled_creatures"))
            and bool(effect_json.get("activated_tap_exile_target_card_from_graveyard"))
            and bool(effect_json.get("creature_exile_reflexive_plus_one_counter"))
        )

    if effect == "passive" and scope == "creature_tokens_tap_any_color_creature_graveyard_plant_growth_v1":
        return (
            types == {"ENCHANTMENT"}
            and {"AddCountersAllEffect", "CreateTokenEffect", "GainAbilityControlledEffect"}.issubset(effect_classes)
            and {"CardsLeaveGraveyardTriggeredAbility", "SimpleStaticAbility"}.issubset(ability_classes)
            and bool(effect_json.get("creature_tokens_tap_for_any_color"))
            and bool(effect_json.get("creature_cards_leave_your_graveyard_create_plant_token"))
            and bool(effect_json.get("plant_tokens_get_plus_one_counter_on_creature_graveyard_exit"))
            and bool(effect_json.get("trigger_once_each_graveyard_exit_event"))
            and effect_json.get("token_name") == "Plant Token"
            and effect_json.get("token_subtype") == "Plant"
            and int(effect_json.get("token_power") or 0) == 0
            and int(effect_json.get("token_toughness") or 0) == 1
            and effect_json.get("token_colors") == ["G"]
        )

    if effect == "passive" and scope == "creatures_tap_any_color_static_enchantment_v1":
        return (
            types == {"ENCHANTMENT"}
            and effect_classes == {"GainAbilityControlledEffect"}
            and ability_classes == {"AnyColorManaAbility", "SimpleStaticAbility"}
            and bool(effect_json.get("creatures_tap_for_any_color"))
        )

    if effect == "passive" and scope == "opponent_discards_card_damage_that_player_v1":
        return (
            types == {"ENCHANTMENT"}
            and effect_classes == {"DamageTargetEffect"}
            and ability_classes == {"DiscardsACardOpponentTriggeredAbility"}
            and not cost_classes
            and effect_json.get("trigger") == "opponent_discard"
            and int(effect_json.get("opponent_discard_damage_per_card") or 0) == 2
        )

    if effect == "passive" and scope == "controller_discards_card_damage_any_target_and_gain_life_v1":
        return (
            types == {"ENCHANTMENT"}
            and {"DamageTargetEffect", "GainLifeEffect"}.issubset(effect_classes)
            and ability_classes == {"DiscardCardControllerTriggeredAbility"}
            and not cost_classes
            and effect_json.get("trigger") == "controller_discard"
            and int(effect_json.get("controller_discard_damage_any_target") or 0) == 1
            and int(effect_json.get("controller_discard_gain_life") or 0) == 1
        )

    if effect == "draw_engine" and scope == "cool_but_rude_class_attack_rummage_level_damage_tutor_v1":
        return (
            types == {"ENCHANTMENT"}
            and {
                "DamagePlayersEffect",
                "DiscardControllerEffect",
                "DrawCardSourceControllerEffect",
                "GainClassAbilitySourceEffect",
                "SearchLibraryPutInHandEffect",
            }.issubset(effect_classes)
            and {
                "AttacksWithCreaturesTriggeredAbility",
                "BecomesClassLevelTriggeredAbility",
                "ClassLevelAbility",
                "ClassReminderAbility",
                "SimpleStaticAbility",
            }.issubset(ability_classes)
            and "DiscardCardCost" in cost_classes
            and bool(effect_json.get("attack_trigger_optional_discard_draw"))
            and effect_json.get("trigger") == "controller_discard"
            and int(effect_json.get("class_level_start") or 0) == 1
            and (effect_json.get("class_level_costs") or {}) == {"2": "{1}{R}", "3": "{1}{R}"}
            and int(effect_json.get("controller_discard_damage_each_opponent") or 0) == 2
            and int(effect_json.get("controller_discard_damage_each_opponent_level_min") or 0) == 2
            and bool(effect_json.get("class_level3_tutor_any_to_hand_random_discard"))
            and effect_json.get("draw_on_enter") is False
        )

    if (
        effect == "free_cast"
        and scope == "cast_up_to_two_instant_sorcery_hand_graveyard_total_mv_lte_6_exile_replacement_v1"
    ):
        return (
            types == {"INSTANT"}
            and {
                "ExileSpellEffect",
                "InvokeCalamityEffect",
                "InvokeCalamityReplacementEffect",
                "OneShotEffect",
            }.issubset(effect_classes)
            and not ability_classes
            and not cost_classes
            and bool(effect_json.get("instant"))
            and effect_json.get("free_cast_from_zones") == ["hand", "graveyard"]
            and effect_json.get("free_cast_card_types") == ["instant", "sorcery"]
            and int(effect_json.get("free_cast_max_count") or 0) == 2
            and int(effect_json.get("free_cast_total_mana_value_max") or 0) == 6
            and bool(effect_json.get("cast_without_paying_mana_cost"))
            and bool(effect_json.get("selected_spells_exile_instead_of_graveyard"))
            and bool(effect_json.get("exiles_self"))
        )

    if effect == "direct_damage" and scope == "damage_any_target_and_gain_life_v1":
        return (
            types.issubset({"INSTANT", "SORCERY"})
            and bool(types)
            and effect_classes == {"DamageTargetEffect", "GainLifeEffect"}
            and not ability_classes
            and not cost_classes
            and str(effect_json.get("target") or "") == "any_target"
            and int(effect_json.get("damage") or 0) > 0
            and int(effect_json.get("gain_life") or 0) > 0
            and int(effect_json.get("damage") or 0) == int(effect_json.get("gain_life") or 0)
            and bool(effect_json.get("instant")) == ("INSTANT" in types)
        )

    if effect == "creature" and scope == "magda_dwarf_tap_treasure_and_five_treasure_tutor_v1":
        return (
            types == {"CREATURE"}
            and {
                "BoostControlledEffect",
                "CreateTokenEffect",
                "SearchLibraryPutInPlayEffect",
            }.issubset(effect_classes)
            and {
                "BecomesTappedTriggeredAbility",
                "SimpleActivatedAbility",
                "SimpleStaticAbility",
            }.issubset(ability_classes)
            and "SacrificeTargetCost" in xmage_cost_classes(card)
            and int(effect_json.get("power") or 0) == 2
            and int(effect_json.get("toughness") or 0) == 1
            and bool(effect_json.get("other_dwarves_you_control_get_plus_one_power"))
            and bool(effect_json.get("controlled_dwarf_becomes_tapped_creates_treasure"))
            and bool(effect_json.get("activated_sacrifice_five_treasures_tutor_artifact_or_dragon"))
            and int(effect_json.get("activated_treasure_tutor_cost") or 0) == 5
            and effect_json.get("activated_treasure_tutor_destination") == "battlefield"
        )

    if effect == "draw_engine" and scope == "skip_draw_discard_exile_pay_life_face_down_draw_next_end_step_v1":
        return (
            types == {"ENCHANTMENT"}
            and {
                "ExileTargetEffect",
                "NecropotenceEffect",
                "OneShotEffect",
                "ReturnToHandTargetEffect",
                "SkipDrawStepEffect",
            }.issubset(effect_classes)
            and {
                "AtTheBeginOfNextEndStepDelayedTriggeredAbility",
                "NecropotenceTriggeredAbility",
                "SimpleActivatedAbility",
                "SimpleStaticAbility",
            }.issubset(ability_classes)
            and "PayLifeCost" in xmage_cost_classes(card)
            and bool(effect_json.get("skip_draw_step"))
            and bool(effect_json.get("discard_trigger_exiles_discarded_card_from_graveyard"))
            and int(effect_json.get("activated_pay_life") or 0) == 1
            and bool(effect_json.get("activated_exile_top_card_face_down"))
            and bool(effect_json.get("activated_put_exiled_card_into_hand_next_end_step"))
        )

    if effect == "draw_engine" and scope == "opponent_spell_pay_one_or_draw_engine_v1":
        return (
            types == {"ENCHANTMENT"}
            and effect_classes == {"OneShotEffect", "RhysticStudyDrawEffect"}
            and ability_classes == {"SpellCastOpponentTriggeredAbility"}
            and not cost_classes
            and effect_json.get("trigger") == "opponent_spell"
            and int(effect_json.get("tax") or 0) == 1
            and not bool(effect_json.get("draw_on_enter"))
        )

    if effect == "draw_engine" and scope == "opponent_noncreature_spell_pay_four_draw_engine_with_cumulative_upkeep_v1":
        return (
            types == {"ENCHANTMENT"}
            and effect_classes == {"MysticRemoraEffect", "OneShotEffect"}
            and {"CumulativeUpkeepAbility", "MysticRemoraTriggeredAbility"}.issubset(ability_classes)
            and not cost_classes
            and effect_json.get("trigger") == "opponent_noncreature_spell"
            and int(effect_json.get("tax") or 0) == 4
            and not bool(effect_json.get("draw_on_enter"))
            and int(effect_json.get("cumulative_upkeep_generic") or 0) == 1
        )

    if effect == "draw_engine" and scope == "opponent_second_draw_second_spell_two_attackers_draw_v1":
        return (
            types == {"ENCHANTMENT"}
            and effect_classes == {"DrawCardSourceControllerEffect"}
            and {"SkipExtraTurnsAbility", "TroubleInPairsTriggeredAbility"}.issubset(ability_classes)
            and not cost_classes
            and int(effect_json.get("draw_count") or 0) == 1
            and bool(effect_json.get("skip_opponent_extra_turns"))
            and bool(effect_json.get("opponent_attacks_you_with_two_or_more_creatures_draw"))
            and bool(effect_json.get("opponent_second_card_draw_each_turn"))
            and bool(effect_json.get("opponent_second_spell_each_turn"))
            and effect_json.get("trigger") == "opponent_second_spell"
            and int(effect_json.get("tax") or 0) == 0
        )

    if effect == "damage_prevention_reflect" and scope == "prevent_next_damage_from_chosen_source_to_you_reflect_to_controller_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"PreventNextDamageFromChosenSourceEffect"}
            and not ability_classes
            and not cost_classes
            and bool(effect_json.get("instant"))
            and bool(effect_json.get("prevent_next_damage_from_chosen_source"))
            and effect_json.get("prevent_damage_to") == "you"
            and effect_json.get("prevent_damage_duration") == "until_end_of_turn"
            and bool(effect_json.get("reflect_prevented_damage"))
            and effect_json.get("reflect_target") == "chosen_source_controller"
            and bool(effect_json.get("source_choice_required"))
        )

    if effect == "draw_engine" and scope == "opponent_discards_card_may_draw_v1":
        return (
            types == {"ARTIFACT"}
            and effect_classes == {"DrawCardSourceControllerEffect"}
            and ability_classes == {"DiscardsACardOpponentTriggeredAbility"}
            and not cost_classes
            and effect_json.get("trigger") == "opponent_discard"
            and int(effect_json.get("opponent_discard_draw_per_card") or 0) == 1
            and not bool(effect_json.get("draw_on_enter"))
        )

    if effect == "artifact" and scope == "multikicker_charge_counter_mana_rock_v1":
        return (
            types == {"ARTIFACT"}
            and effect_classes == {"AddCountersSourceEffect"}
            and {"DynamicManaAbility", "EntersBattlefieldAbility", "MultikickerAbility"}.issubset(ability_classes)
            and effect_json.get("multikicker_cost") == "{2}"
            and bool(effect_json.get("etb_charge_counters_per_kick"))
            and bool(effect_json.get("tap_add_colorless_per_charge_counter"))
        )

    if effect == "modal_spell" and scope == "search_creature_or_land_or_counter_fight_or_exile_artifact_enchantment_v1":
        return (
            types == {"INSTANT"}
            and {"AddCountersTargetEffect", "DamageWithPowerFromOneToAnotherTargetEffect", "ExileTargetEffect", "SearchEffect", "SearchLibraryPutInHandOrOnBattlefieldEffect"}.issubset(effect_classes)
            and not ability_classes
            and bool(effect_json.get("instant"))
            and bool(effect_json.get("mode_search_creature_or_land_reveal_put_land_battlefield_tapped_else_hand"))
            and bool(effect_json.get("mode_put_plus_one_counter_on_controlled_creature_then_fight"))
            and bool(effect_json.get("mode_exile_target_artifact_or_enchantment"))
        )

    if effect == "planeswalker" and scope == "opponents_sorcery_speed_only_plus1_sorcery_flash_minus3_bounce_draw_v1":
        return (
            types == {"PLANESWALKER"}
            and {"DrawCardSourceControllerEffect", "ReturnToHandTargetEffect", "CastAsThoughItHadFlashAllEffect", "TeferiTimeRavelerReplacementEffect"}.issubset(effect_classes)
            and {"LoyaltyAbility", "SimpleStaticAbility"}.issubset(ability_classes)
            and int(effect_json.get("starting_loyalty") or 0) == 4
            and bool(effect_json.get("opponents_can_cast_only_as_sorcery"))
            and bool(effect_json.get("plus_one_sorceries_have_flash_until_your_next_turn"))
            and int(effect_json.get("minus_three_bounce_up_to_one_artifact_creature_or_enchantment_draw") or 0) == 1
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

    if effect == "modal_spell" and scope == "choose_three_pump_blink_tapped_or_create_eldrazi_scion_v1":
        return (
            types == {"INSTANT"}
            and {
                "BoostTargetEffect",
                "CreateTokenEffect",
                "ExileThenReturnTargetEffect",
            }.issubset(effect_classes)
            and (
                (card.get("xmage") or {}).get("class_name") == "EldraziConfluence"
                or (
                    "TargetCreaturePermanent" in xmage_target_classes(card)
                    and "TargetNonlandPermanent" in xmage_target_classes(card)
                )
            )
            and not ability_classes
            and bool(effect_json.get("instant"))
            and int(effect_json.get("modal_choose_count") or 0) == 3
            and bool(effect_json.get("modal_may_repeat_modes"))
            and bool(effect_json.get("mode_target_creature_plus_three_minus_three"))
            and bool(effect_json.get("mode_blink_target_nonland_permanent_tapped"))
            and bool(effect_json.get("mode_create_eldrazi_scion"))
            and effect_json.get("token_name") == "Eldrazi Scion Token"
            and effect_json.get("token_subtype") == "Eldrazi Scion"
            and int(effect_json.get("token_power") or 0) == 1
            and int(effect_json.get("token_toughness") or 0) == 1
            and effect_json.get("token_colors") == []
            and bool(effect_json.get("token_sacrifice_for_colorless_mana"))
        )

    if effect == "bounce" and scope == "gift_bounce_opponent_creature_or_nonland_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"ReturnToHandTargetEffect"}
            and ability_classes == {"GiftAbility"}
            and bool(effect_json.get("instant"))
            and bool(effect_json.get("gift_tapped_fish"))
            and effect_json.get("target") == "opponent_creature"
            and effect_json.get("gift_promised_target") == "opponent_nonland_permanent"
        )

    if effect == "bounce" and scope == "return_target_creature_then_untap_up_to_two_lands_v1":
        return (
            types == {"INSTANT"}
            and effect_classes == {"ReturnToHandTargetEffect", "UntapLandsEffect"}
            and not ability_classes
            and bool(effect_json.get("instant"))
            and effect_json.get("target") == "creature"
            and int(effect_json.get("untap_lands_count") or 0) == 2
        )

    if effect == "bounce" and scope == "return_target_spell_or_opponent_nonland_permanent_or_tapped_blue_land_v1":
        return (
            types == {"INSTANT", "LAND"}
            and {"ReturnToHandTargetEffect", "TapSourceUnlessPaysEffect"}.issubset(effect_classes)
            and {"AsEntersBattlefieldAbility", "BlueManaAbility"}.issubset(ability_classes)
            and "PayLifeCost" in xmage_cost_classes(card)
            and bool(effect_json.get("instant"))
            and effect_json.get("target") == "spell_or_opponent_nonland_permanent"
            and bool(effect_json.get("land_side_pay_three_life_else_tapped"))
            and effect_json.get("land_side_add_mana") == "U"
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
    if (
        family.get("implementation_unit")
        == "battlefield trigger when a creature controlled by the source controller enters and damages each live opponent"
    ):
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
    family_id = family_for_effect_json(effect_json)
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
        "xmage_target_classes": sorted(xmage_target_classes(card)),
        "xmage_condition_classes": sorted(xmage_condition_classes(card)),
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
