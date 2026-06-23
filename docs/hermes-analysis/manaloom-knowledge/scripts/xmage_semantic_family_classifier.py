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
    "artifact_tap_colorless_mana_or_pay_tap_sac_draw_one_v1",
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


def promotion_lane(card: dict[str, Any], family: dict[str, Any]) -> str:
    if card.get("status") == "blocked_missing_xmage_class":
        return "blocked_missing_xmage_source"
    if not card.get("ready_for_structured_pull"):
        return "mapper_metadata_or_test_scenario_required"
    if generic_runtime_batch_safe(card):
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
