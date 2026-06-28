#!/usr/bin/env python3
"""Build a family-level XMage queue for Lorehold runtime rule gaps.

This report is read-only. It consumes the Lorehold variant gap miner, takes the
variant-only cards still blocked by runtime rule gaps, resolves their local
XMage Java implementations, and groups the result by ManaLoom semantic family.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import xmage_batch_validity_audit as validity_audit
import xmage_local_rule_indexer as local_indexer
import xmage_semantic_family_classifier as family_classifier


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_MINER_REPORT = (
    REPORT_DIR / "lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json"
)
DEFAULT_XMAGE_ROOT = Path("/Users/desenvolvimentomobile/Downloads/mage-master")


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def write_markdown(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def candidate_rows(miner_report: dict[str, Any]) -> list[dict[str, Any]]:
    rows = miner_report.get("all_variant_candidates") or miner_report.get("top_variant_candidates") or []
    return [row for row in rows if isinstance(row, dict)]


def blocked_runtime_rows(miner_report: dict[str, Any]) -> list[dict[str, Any]]:
    rows = [
        row
        for row in candidate_rows(miner_report)
        if row.get("status") == "blocked_runtime_rule_gap"
    ]
    rows.sort(
        key=lambda row: (
            -int(row.get("score") or 0),
            -int(row.get("variant_deck_count") or 0),
            str(row.get("card_name") or ""),
        )
    )
    return rows


def severity_for_candidate(row: dict[str, Any]) -> str:
    if int(row.get("variant_deck_count") or 0) >= 3 or int(row.get("score") or 0) >= 20:
        return "high"
    return "medium"


def build_blocked_coherence_report(
    *,
    miner_report: dict[str, Any],
    blocked_rows: list[dict[str, Any]],
) -> dict[str, Any]:
    cards: list[dict[str, Any]] = []
    for index, row in enumerate(blocked_rows, start=1):
        cards.append(
            {
                "card_name": row.get("card_name"),
                "severity": severity_for_candidate(row),
                "type_line": row.get("type_line"),
                "oracle_hash": None,
                "priority_score": int(row.get("score") or 0),
                "impact_rank": index,
                "active_rule_count": int(row.get("active_rule_count") or 0),
                "trusted_executable_rule_count": 0,
                "review_only_rule_count": int(row.get("review_only_rule_count") or 0),
                "findings": [
                    {
                        "code": "no_active_battle_rule",
                        "detail": "Lorehold variant candidate is blocked_runtime_rule_gap in the variant gap miner.",
                    }
                ],
                "variant_decks": list(row.get("variant_decks") or []),
                "variant_deck_count": int(row.get("variant_deck_count") or 0),
                "variant_total_quantity": int(row.get("variant_total_quantity") or 0),
                "lane": row.get("lane"),
                "functional_tags": row.get("functional_tags") or {},
            }
        )
    severities = Counter(card["severity"] for card in cards)
    deck_ids = [
        int(miner_report.get("base_deck_id") or 0),
        *[int(deck_id) for deck_id in miner_report.get("variant_deck_ids") or []],
    ]
    return {
        "generated_at": utc_now(),
        "source": "lorehold_variant_gap_miner",
        "scope": "lorehold_variant_only_cards_blocked_by_runtime_rule_gap",
        "deck_id": miner_report.get("base_deck_id"),
        "source_deck_ids": deck_ids,
        "source_miner_summary": miner_report.get("summary") or {},
        "total_cards": len(cards),
        "severity_counts": dict(sorted(severities.items())),
        "cards": cards,
    }


def candidate_lookup(blocked_rows: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    return {
        normalize_key(row.get("card_name")): row
        for row in blocked_rows
        if row.get("card_name")
    }


def card_signal_group(card: dict[str, Any]) -> str:
    abilities = set(card.get("xmage_ability_classes") or [])
    effects = set(card.get("xmage_effect_classes") or [])
    targets = set(card.get("xmage_target_classes") or [])
    conditions = set(card.get("xmage_condition_classes") or [])
    signals: list[str] = []
    if targets:
        signals.append("targeting")
    if any("Draw" in value for value in effects):
        signals.append("draw")
    if any("Damage" in value for value in effects):
        signals.append("damage")
    if any("Token" in value for value in effects):
        signals.append("token")
    if any("Mana" in value or "CostReduction" in value or "CostIncreasing" in value for value in effects):
        signals.append("mana_or_cost")
    if any("Mill" in value for value in effects):
        signals.append("mill")
    if conditions:
        signals.append("condition")
    if any("TriggeredAbility" in value or value.endswith("TriggeredAbility") for value in abilities):
        signals.append("triggered_ability")
    if "SimpleActivatedAbility" in abilities or any(value.endswith("ActivatedAbility") for value in abilities):
        signals.append("activated_ability")
    if "SimpleStaticAbility" in abilities or any(value.endswith("StaticAbility") for value in abilities):
        signals.append("static_ability")
    return ";".join(signals) if signals else "no_structural_signal"


TARGETED_INTERACTION_SUBFAMILY_META = {
    "targeted_damage_etb_power_to_any_target": {
        "status": "runtime_supported_family",
        "implementation_unit": (
            "triggered damage equal to the entering controlled creature power, "
            "with target selection and optional opponent targeting tax"
        ),
        "next_step": "prepare PG metadata package after PostgreSQL precheck, then gate Terror of the Peaks ETB damage lines",
        "family_tests": [
            "test_terror_of_the_peaks_damages_any_target_equal_to_entering_creature_power",
            "test_terror_of_the_peaks_applies_opponent_targeting_tax",
        ],
        "priority": 20,
    },
    "spell_color_trigger_damage_life_engine": {
        "status": "runtime_supported_family",
        "implementation_unit": (
            "red/white spell-cast triggers that separately deal targeted damage, "
            "gain life, and annotate static creature boosts"
        ),
        "next_step": "prepare PG metadata package after PostgreSQL precheck, then gate Balefire spell-color lines",
        "family_tests": [
            "test_balefire_liege_red_spell_deals_three_to_target_player_or_planeswalker",
            "test_balefire_liege_white_spell_gains_three_life",
            "test_balefire_liege_red_white_spell_fires_both_triggers",
        ],
        "priority": 15,
    },
    "instant_sorcery_lifelink_lifegain_damage_engine": {
        "status": "runtime_supported_family",
        "implementation_unit": (
            "instant/sorcery lifelink grant plus white instant/sorcery lifegain trigger "
            "that deals three damage to a target"
        ),
        "next_step": "prepare PG metadata package after PostgreSQL precheck, then gate Firesong burn/lifegain lines",
        "family_tests": [
            "test_firesong_grants_lifelink_to_red_instant_and_sorcery_spells",
            "test_firesong_white_instant_lifegain_triggers_three_damage",
        ],
        "priority": 15,
    },
    "source_damaged_reflect_to_any_target": {
        "status": "runtime_supported_family",
        "implementation_unit": (
            "source-creature dealt-damage trigger that deals the same amount to any chosen target"
        ),
        "next_step": "prepare PG metadata package after PostgreSQL precheck, then gate Boros Reckoner reflection lines",
        "family_tests": [
            "test_boros_reckoner_reflects_damage_to_selected_any_target",
            "test_boros_reckoner_reflection_uses_saved_damage_amount",
        ],
        "priority": 25,
    },
    "creature_damage_controller_reflect_global": {
        "status": "runtime_supported_family",
        "implementation_unit": (
            "global creature-damaged trigger that deals the same damage to that creature controller"
        ),
        "next_step": "prepare PG metadata package after PostgreSQL precheck, then gate Repercussion sweeper synergy",
        "family_tests": [
            "test_repercussion_damages_creature_controller_after_survived_creature_damage",
            "test_repercussion_stacks_with_blasphemous_act_board_damage",
        ],
        "priority": 35,
    },
    "excess_damage_redirect_to_any_target": {
        "status": "runtime_family_implementation_required",
        "implementation_unit": (
            "excess noncombat damage trigger that redirects overflow damage to another target"
        ),
        "next_step": "implement Toralf excess-damage batch trigger and MDFC hammer activated damage separately",
        "family_tests": [
            "test_toralf_redirects_excess_noncombat_damage_to_any_target",
            "test_toralf_hammer_deals_three_and_returns_to_hand_after_unattach",
        ],
        "priority": 30,
    },
    "targeted_interaction_split_review": {
        "status": "split_family_scope_review_required",
        "implementation_unit": "targeted direct-damage variant requires manual subfamily assignment",
        "next_step": "inspect XMage ability/effect/target classes and add a deterministic subfamily mapping",
        "family_tests": [],
        "priority": 5,
    },
}


def targeted_interaction_subfamily(card: dict[str, Any]) -> dict[str, Any] | None:
    if card.get("family_id") != "targeted_interaction":
        return None
    effect = str(card.get("effect") or "")
    scope = str(card.get("battle_model_scope") or "")
    runtime_scopes = {
        "controlled_other_creature_enters_power_damage_any_target_v1",
        "red_instant_sorcery_lifelink_white_lifegain_damage_v1",
        "red_spell_damage_white_spell_lifegain_static_creature_boost_v1",
        "source_dealt_damage_reflect_to_any_target_v1",
    }
    if effect != "direct_damage" and scope not in runtime_scopes:
        return None

    abilities = set(card.get("xmage_ability_classes") or [])
    effects = set(card.get("xmage_effect_classes") or [])
    targets = set(card.get("xmage_target_classes") or [])
    conditions = set(card.get("xmage_condition_classes") or [])

    if "ToralfGodOfFuryTriggeredAbility" in abilities or "ToralfsHammerEffect" in effects:
        subfamily_id = "excess_damage_redirect_to_any_target"
    elif "DealtDamageAnyTriggeredAbility" in abilities:
        subfamily_id = "creature_damage_controller_reflect_global"
    elif "DealtDamageToSourceTriggeredAbility" in abilities:
        subfamily_id = "source_damaged_reflect_to_any_target"
    elif "FiresongAndSunspeakerTriggeredAbility" in abilities:
        subfamily_id = "instant_sorcery_lifelink_lifegain_damage_engine"
    elif "SpellCastControllerTriggeredAbility" in abilities and {
        "GainLifeEffect",
        "DamageTargetEffect",
    }.issubset(effects):
        subfamily_id = "spell_color_trigger_damage_life_engine"
    elif (
        "EntersBattlefieldControlledTriggeredAbility" in abilities
        and "DamageTargetEffect" in effects
        and "TargetAnyTarget" in targets
    ):
        subfamily_id = "targeted_damage_etb_power_to_any_target"
    else:
        subfamily_id = "targeted_interaction_split_review"

    meta = dict(TARGETED_INTERACTION_SUBFAMILY_META[subfamily_id])
    meta["subfamily_id"] = subfamily_id
    meta["signal_group"] = card_signal_group(card)
    meta["requires_condition_model"] = bool(conditions)
    return meta


def xmage_signal_groups(cards: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, list[dict[str, Any]]] = {}
    for card in cards:
        grouped.setdefault(card_signal_group(card), []).append(card)
    rows: list[dict[str, Any]] = []
    for signal_group, group_cards in grouped.items():
        lane_counts = Counter(card.get("candidate_lane") or "unknown" for card in group_cards)
        promotion_counts = Counter(card.get("promotion_lane") or "unknown" for card in group_cards)
        sorted_cards = sorted(
            group_cards,
            key=lambda card: (
                -int(card.get("candidate_score") or 0),
                -int(card.get("variant_deck_count") or 0),
                str(card.get("card_name") or ""),
            ),
        )
        rows.append(
            {
                "signal_group": signal_group,
                "card_count": len(sorted_cards),
                "candidate_lane_counts": dict(sorted(lane_counts.items())),
                "promotion_lane_counts": dict(sorted(promotion_counts.items())),
                "sample_cards": [card.get("card_name") for card in sorted_cards[:8]],
                "top_cards": sorted_cards[:12],
            }
        )
    rows.sort(key=lambda row: (-int(row["card_count"]), row["signal_group"]))
    return rows


def build_family_queue(
    *,
    family_report: dict[str, Any],
    blocked_rows: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    candidates = candidate_lookup(blocked_rows)
    queue: list[dict[str, Any]] = []
    for family in family_report.get("families") or []:
        cards: list[dict[str, Any]] = []
        for card in family.get("cards") or []:
            source = candidates.get(normalize_key(card.get("card_name"))) or {}
            cards.append(
                {
                    "card_name": card.get("card_name"),
                    "family_id": family.get("family_id"),
                    "candidate_score": int(source.get("score") or 0),
                    "candidate_lane": source.get("lane") or "unknown",
                    "variant_decks": list(source.get("variant_decks") or []),
                    "variant_deck_count": int(source.get("variant_deck_count") or 0),
                    "promotion_lane": card.get("promotion_lane"),
                    "family_support_status": card.get("family_support_status"),
                    "effect": card.get("effect"),
                    "battle_model_scope": card.get("battle_model_scope"),
                    "ready_for_structured_pull": bool(card.get("ready_for_structured_pull")),
                    "valid_xmage_source": bool(card.get("valid_xmage_source")),
                    "xmage_class": card.get("xmage_class"),
                    "xmage_path": card.get("xmage_path"),
                    "xmage_ability_classes": list(card.get("xmage_ability_classes") or []),
                    "xmage_effect_classes": list(card.get("xmage_effect_classes") or []),
                    "xmage_target_classes": list(card.get("xmage_target_classes") or []),
                    "xmage_condition_classes": list(card.get("xmage_condition_classes") or []),
                    "focused_test_scenario_count": int(card.get("focused_test_scenario_count") or 0),
                }
            )
            subfamily = targeted_interaction_subfamily(cards[-1])
            if subfamily:
                cards[-1]["targeted_interaction_subfamily"] = subfamily
        lane_counts = Counter(card["candidate_lane"] for card in cards)
        promotion_counts = Counter(card["promotion_lane"] for card in cards)
        subfamily_counts = Counter(
            (card.get("targeted_interaction_subfamily") or {}).get("subfamily_id")
            for card in cards
            if card.get("targeted_interaction_subfamily")
        )
        subfamily_status_counts = Counter(
            (card.get("targeted_interaction_subfamily") or {}).get("status")
            for card in cards
            if card.get("targeted_interaction_subfamily")
        )
        cards.sort(
            key=lambda card: (
                -int((card.get("targeted_interaction_subfamily") or {}).get("priority") or 0),
                -int(card.get("candidate_score") or 0),
                -int(card.get("variant_deck_count") or 0),
                str(card.get("card_name") or ""),
            )
        )
        queue.append(
            {
                "family_id": family.get("family_id"),
                "card_count": len(cards),
                "candidate_lane_counts": dict(sorted(lane_counts.items())),
                "promotion_lane_counts": dict(sorted(promotion_counts.items())),
                "support_status": family.get("support_status"),
                "batch_strategy": family.get("batch_strategy"),
                "implementation_unit": family.get("implementation_unit"),
                "family_tests": list(family.get("family_tests") or []),
                "targeted_interaction_subfamily_counts": dict(sorted(subfamily_counts.items())),
                "targeted_interaction_subfamily_status_counts": dict(
                    sorted(subfamily_status_counts.items())
                ),
                "xmage_signal_groups": xmage_signal_groups(cards),
                "cards": cards,
            }
        )
    queue.sort(
        key=lambda family: (
            -int(family.get("card_count") or 0),
            str(family.get("support_status") or ""),
            str(family.get("family_id") or ""),
        )
    )
    return queue


def build_queue_report(
    *,
    miner_report: dict[str, Any],
    xmage_root: Path,
) -> dict[str, Any]:
    blocked_rows = blocked_runtime_rows(miner_report)
    coherence_report = build_blocked_coherence_report(
        miner_report=miner_report,
        blocked_rows=blocked_rows,
    )
    index_report = local_indexer.build_index_report(
        [str(row.get("card_name") or "") for row in blocked_rows],
        xmage_root=xmage_root,
        source={
            "kind": "lorehold_runtime_gap_family_queue",
            "miner_summary": miner_report.get("summary") or {},
        },
    )
    validity_report = validity_audit.build_audit(
        coherence_report=coherence_report,
        xmage_index=index_report,
        external_harvest=None,
    )
    family_report = family_classifier.build_family_report(validity_report)
    family_queue = build_family_queue(
        family_report=family_report,
        blocked_rows=blocked_rows,
    )
    promotion_counts = Counter(
        card.get("promotion_lane")
        for family in family_queue
        for card in family.get("cards") or []
    )
    targeted_subfamily_counts = Counter(
        (card.get("targeted_interaction_subfamily") or {}).get("subfamily_id")
        for family in family_queue
        for card in family.get("cards") or []
        if card.get("targeted_interaction_subfamily")
    )
    targeted_subfamily_status_counts = Counter(
        (card.get("targeted_interaction_subfamily") or {}).get("status")
        for family in family_queue
        for card in family.get("cards") or []
        if card.get("targeted_interaction_subfamily")
    )
    candidate_lane_counts = Counter(row.get("lane") or "unknown" for row in blocked_rows)
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "mutations_performed": [],
        "source": {
            "miner_report": miner_report.get("_source_path"),
            "xmage_root": str(xmage_root),
            "base_deck_id": miner_report.get("base_deck_id"),
            "variant_deck_ids": miner_report.get("variant_deck_ids") or [],
        },
        "summary": {
            "blocked_runtime_rule_gap_count": len(blocked_rows),
            "candidate_lane_counts": dict(sorted(candidate_lane_counts.items())),
            "xmage_index_summary": index_report.get("summary") or {},
            "validity_summary": validity_report.get("summary") or {},
            "family_summary": family_report.get("summary") or {},
            "promotion_lane_counts": dict(sorted(promotion_counts.items())),
            "targeted_interaction_subfamily_counts": dict(sorted(targeted_subfamily_counts.items())),
            "targeted_interaction_subfamily_status_counts": dict(
                sorted(targeted_subfamily_status_counts.items())
            ),
            "family_count": len(family_queue),
        },
        "blocked_coherence_report": coherence_report,
        "xmage_index_report": index_report,
        "validity_report": validity_report,
        "family_report": family_report,
        "family_queue": family_queue,
    }


def render_markdown(report: dict[str, Any]) -> str:
    summary = report.get("summary") or {}
    lines = [
        "# Lorehold Runtime Gap Family Queue",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- XMage root: `{(report.get('source') or {}).get('xmage_root')}`",
        "- PostgreSQL writes: `false`",
        "- SQLite source mutated: `false`",
        f"- Blocked runtime cards: `{summary.get('blocked_runtime_rule_gap_count')}`",
        f"- Candidate lanes: `{json.dumps(summary.get('candidate_lane_counts'), sort_keys=True)}`",
        f"- Promotion lanes: `{json.dumps(summary.get('promotion_lane_counts'), sort_keys=True)}`",
        f"- Targeted interaction subfamilies: `{json.dumps(summary.get('targeted_interaction_subfamily_counts'), sort_keys=True)}`",
        f"- Targeted interaction subfamily statuses: `{json.dumps(summary.get('targeted_interaction_subfamily_status_counts'), sort_keys=True)}`",
        f"- Family count: `{summary.get('family_count')}`",
        "",
        "## Family Queue",
        "",
        "| Rank | Family | Cards | Support | Batch strategy | Candidate lanes | Promotion lanes | Implementation unit |",
        "| ---: | --- | ---: | --- | --- | --- | --- | --- |",
    ]
    for index, family in enumerate(report.get("family_queue") or [], start=1):
        lines.append(
            "| {rank} | `{family_id}` | {count} | `{support}` | `{strategy}` | `{candidate_lanes}` | `{promotion_lanes}` | {unit} |".format(
                rank=index,
                family_id=family.get("family_id"),
                count=family.get("card_count"),
                support=family.get("support_status"),
                strategy=family.get("batch_strategy"),
                candidate_lanes=json.dumps(family.get("candidate_lane_counts"), sort_keys=True),
                promotion_lanes=json.dumps(family.get("promotion_lane_counts"), sort_keys=True),
                unit=family.get("implementation_unit") or "",
            )
        )
    lines.extend(["", "## Cards By Family", ""])
    for family in report.get("family_queue") or []:
        lines.extend(
            [
                f"### {family.get('family_id')}",
                "",
                f"- Support: `{family.get('support_status')}`",
                f"- Batch strategy: `{family.get('batch_strategy')}`",
                f"- Family tests: `{json.dumps(family.get('family_tests'), sort_keys=True)}`",
                f"- Targeted interaction subfamilies: `{json.dumps(family.get('targeted_interaction_subfamily_counts'), sort_keys=True)}`",
                f"- Targeted interaction subfamily statuses: `{json.dumps(family.get('targeted_interaction_subfamily_status_counts'), sort_keys=True)}`",
                "",
                "Signal groups:",
                "",
            ]
        )
        for group in family.get("xmage_signal_groups") or []:
            lines.append(
                "- `{signal}`: {count} cards; lanes `{lanes}`; samples `{samples}`".format(
                    signal=group.get("signal_group"),
                    count=group.get("card_count"),
                    lanes=json.dumps(group.get("candidate_lane_counts"), sort_keys=True),
                    samples=", ".join(str(card) for card in group.get("sample_cards") or []),
                )
            )
        lines.extend(
            [
                "",
                "| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |",
                "| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |",
            ]
        )
        for card in family.get("cards") or []:
            subfamily = card.get("targeted_interaction_subfamily") or {}
            lines.append(
                "| `{card}` | {score} | `{decks}` | `{lane}` | `{promotion}` | `{subfamily}` | {step} | `{effect}` | `{scope}` | `{klass}` |".format(
                    card=card.get("card_name"),
                    score=card.get("candidate_score"),
                    decks=", ".join(str(deck_id) for deck_id in card.get("variant_decks") or []),
                    lane=card.get("candidate_lane"),
                    promotion=card.get("promotion_lane"),
                    subfamily=subfamily.get("subfamily_id") or "",
                    step=subfamily.get("next_step") or "",
                    effect=card.get("effect"),
                    scope=card.get("battle_model_scope"),
                    klass=card.get("xmage_class"),
                )
            )
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--miner-report", type=Path, default=DEFAULT_MINER_REPORT)
    parser.add_argument("--xmage-root", type=Path, default=DEFAULT_XMAGE_ROOT)
    parser.add_argument("--output-prefix")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    miner_report = read_json(args.miner_report)
    miner_report["_source_path"] = str(args.miner_report)
    report = build_queue_report(
        miner_report=miner_report,
        xmage_root=args.xmage_root,
    )
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    output_prefix = Path(
        args.output_prefix
        or REPORT_DIR / f"lorehold_runtime_gap_family_queue_{timestamp}"
    )
    files = {
        "queue_json": output_prefix.with_suffix(".json"),
        "queue_md": output_prefix.with_suffix(".md"),
        "blocked_coherence_json": output_prefix.with_name(output_prefix.name + "_blocked_coherence.json"),
        "xmage_index_json": output_prefix.with_name(output_prefix.name + "_xmage_index.json"),
        "validity_json": output_prefix.with_name(output_prefix.name + "_validity.json"),
        "families_json": output_prefix.with_name(output_prefix.name + "_families.json"),
    }
    write_json(files["queue_json"], report)
    write_markdown(files["queue_md"], render_markdown(report))
    write_json(files["blocked_coherence_json"], report["blocked_coherence_report"])
    write_json(files["xmage_index_json"], report["xmage_index_report"])
    write_json(files["validity_json"], report["validity_report"])
    write_json(files["families_json"], report["family_report"])
    print(f"queue_json={files['queue_json']}")
    print(f"queue_md={files['queue_md']}")
    print(f"blocked_runtime_rule_gap_count={report['summary']['blocked_runtime_rule_gap_count']}")
    print(f"promotion_lane_counts={json.dumps(report['summary']['promotion_lane_counts'], sort_keys=True)}")
    print(f"family_count={report['summary']['family_count']}")
    print("mutations_performed=[]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
