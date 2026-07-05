#!/usr/bin/env python3
"""Model the next Lorehold pressure-learning step after the mana queue closed.

This is a deckbuilding-learning artifact, not a deck generator. It combines the
current internal 607 evidence with reviewed Commander deckbuilding principles
and produces the next allowed learning routes. Its main job is to keep powerful
cards, contextual packages, lands, ramp, artifacts, and staples in separate
lanes until a named cut plan and battle gate prove a real deck improvement.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_ROUTER = REPORT_DIR / "lorehold_post_mana_base_learning_router_20260705_current.json"
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_SEED_SAFE = REPORT_DIR / "lorehold_seed_safe_cut_hypothesis_20260704_role_tag_repair.json"
DEFAULT_TRACE_EXPANDER = REPORT_DIR / "lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.json"
DEFAULT_PRESSURE_MICRO = REPORT_DIR / "lorehold_pressure_micro_package_planner_20260704_current.json"
DEFAULT_PRESSURE_RESOLVER = REPORT_DIR / "lorehold_pressure_safe_cut_pool_resolver_20260704_current.json"
DEFAULT_PRESSURE_CONTRACT = REPORT_DIR / "lorehold_pressure_safe_spell_payoff_contract_20260704_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_pressure_safe_cut_expansion_model_20260705_current"

EXTERNAL_DECKBUILDING_LEARNING = [
    {
        "source": "Wizards Commander format",
        "url": "https://magic.wizards.com/en/formats/commander",
        "learning": (
            "Commander legality, singleton, commander count, and color identity are "
            "entry gates. They do not prove that a legal card belongs in Lorehold 607."
        ),
        "model_effect": "legal_identity_gate_only",
    },
    {
        "source": "Official Commander rules",
        "url": "https://mtgcommander.net/index.php/rules/",
        "learning": (
            "The format requires exactly 100 cards including the commander, obeys "
            "color identity, and permits duplicate names only when rules text allows it."
        ),
        "model_effect": "shape_singleton_color_identity_gate",
    },
    {
        "source": "EDHREC How to Build a Commander Deck",
        "url": "https://edhrec.com/articles/how-to-build-a-commander-deck",
        "learning": (
            "Deck construction should check ramp, card flow, interaction, lands, "
            "curve, and commander plan together. Category counts start the process; "
            "they are not final proof."
        ),
        "model_effect": "role_density_and_curve_are_inputs_not_promotion",
    },
    {
        "source": "Commander Spellbook Storm-Kiln Artist + Haze of Rage",
        "url": "https://commanderspellbook.com/combo/3940-5195/",
        "learning": (
            "Storm-Kiln Artist plus Haze of Rage is a red legal combo lane with "
            "infinite mana, storm, magecraft, and Treasure implications."
        ),
        "model_effect": "combo_package_research_requires_runtime_cut_and_battle_proof",
    },
    {
        "source": "Scryfall card data",
        "url": "https://scryfall.com/docs/api/cards",
        "learning": (
            "Card legality, identity, type, oracle text, and game-changer metadata "
            "are card-data facts. ManaLoom must combine them with commander-context "
            "and battle evidence before changing 607."
        ),
        "model_effect": "card_data_is_not_deck_quality_by_itself",
    },
]

STAPLE_AND_ARTIFACT_POLICY = [
    {
        "card_name": "Mana Vault",
        "lane": "artifact_fast_mana_game_changer",
        "current_learning_status": "blocked_not_auto_include",
        "reason": (
            "Legal/colorless power is real, but prior Lorehold evidence rejected the "
            "one-card Bender's Waterskin replacement. Early mana is protected unless "
            "a same-lane plan preserves the miracle timing window."
        ),
    },
    {
        "card_name": "The One Ring",
        "lane": "artifact_draw_protection_game_changer",
        "current_learning_status": "blocked_not_auto_include",
        "reason": (
            "The card is a powerful draw/protection engine, but tested draw/value "
            "cuts lost to protected 607. Its value is contextual only if a safe "
            "draw/protection cut and natural trace proof appear."
        ),
    },
    {
        "card_name": "Storm-Kiln Artist",
        "lane": "contextual_spell_payoff_mana_extension",
        "current_learning_status": "research_package_only",
        "reason": (
            "It fits Lorehold's spell-chain pressure/treasure lane, but prior "
            "evidence forbids treating it as a generic mana-rock replacement."
        ),
    },
    {
        "card_name": "Plateau",
        "lane": "land_untapped_typed_dual",
        "current_learning_status": "simple_swap_rejected",
        "reason": (
            "A cleaner land can still fail if the active shell loses battle timing. "
            "Both Plateau over Radiant Summit and Plateau over Turbulent Steppe were "
            "rejected in copied-DB diagnostics."
        ),
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def as_bool(value: Any) -> bool:
    return bool(value) if value is not None else False


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    source = payload.get("summary")
    return dict(source) if isinstance(source, Mapping) else {}


def list_of_maps(value: Any) -> list[dict[str, Any]]:
    return [dict(row) for row in as_list(value) if isinstance(row, Mapping)]


def first_non_empty_list(*values: Any) -> list[Any]:
    for value in values:
        rows = as_list(value)
        if rows:
            return rows
    return []


def extract_primary_adds(
    pressure_contract: Mapping[str, Any], pressure_resolver: Mapping[str, Any]
) -> list[dict[str, Any]]:
    preflight = list_of_maps(pressure_contract.get("primary_package_preflight"))
    if preflight:
        return [
            {
                "card_name": str(row.get("card_name") or ""),
                "role": row.get("role"),
                "preflight_status": row.get("preflight_status"),
                "commander_legal_status": row.get("commander_legal_status"),
                "verified_auto_battle_rule_count": as_int(row.get("verified_auto_battle_rule_count")),
                "value_test": row.get("value_test"),
            }
            for row in preflight
            if row.get("card_name")
        ]
    return [{"card_name": str(name)} for name in as_list(pressure_resolver.get("primary_adds"))]


def seed_safe_names(seed_safe_report: Mapping[str, Any]) -> list[str]:
    return [
        str(row["card_name"])
        for row in list_of_maps(seed_safe_report.get("seed_safe_cut_candidates"))
        if row.get("card_name")
    ]


def same_lane_names(seed_safe_report: Mapping[str, Any], trace_expander: Mapping[str, Any]) -> list[str]:
    names: list[str] = []
    for row in list_of_maps(seed_safe_report.get("same_lane_only_cut_slots")):
        if row.get("card_name"):
            names.append(str(row["card_name"]))
    for row in list_of_maps(trace_expander.get("same_lane_hard_blocked_queue")):
        if row.get("card_name") and str(row["card_name"]) not in names:
            names.append(str(row["card_name"]))
    for name in as_list(summary(seed_safe_report).get("same_lane_only_cut_cards")):
        if str(name) not in names:
            names.append(str(name))
    return names


def cut_row_index(*reports: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    keys = (
        "cut_slots",
        "all_cut_slots",
        "same_lane_only_cut_slots",
        "same_lane_hard_blocked_queue",
        "hard_blocked_queue",
        "reviewable_evidence_gap_queue",
        "seed_safe_cut_queue",
    )
    for report in reports:
        for key in keys:
            for row in list_of_maps(report.get(key)):
                name = row.get("card_name")
                if not name:
                    continue
                current = rows.setdefault(str(name), {})
                current.update(row)
    return rows


def target_status(row: Mapping[str, Any], same_lane_only: set[str], seed_safe: set[str]) -> str:
    name = str(row.get("card_name") or "")
    blockers = {str(item) for item in as_list(row.get("blockers"))}
    manual_status = str(row.get("manual_status") or "")
    if name in seed_safe:
        return "seed_safe_ready_requires_package_preflight"
    if name in same_lane_only or "same_lane_only_requires_concrete_same_lane_add" in blockers:
        return "same_lane_microbenchmark_only"
    if manual_status == "measured_high_cut_exposure" or "measured_high_cut_exposure" in blockers:
        return "blocked_high_exposure_anchor"
    if manual_status == "structural_dependency" or "structural_dependency" in blockers:
        return "blocked_structural_dependency"
    if "mana_base_never_cut" in blockers or "never_cut_lane" in blockers:
        return "blocked_never_cut_lane"
    if "prior_rejected_cut" in blockers or "prior_rejected_signature" in blockers:
        return "blocked_prior_rejected_signature"
    if "protected_cut" in blockers:
        return "blocked_protected_anchor"
    return "blocked_no_cut_safety_proof"


def cut_expansion_targets(
    seed_safe_report: Mapping[str, Any], trace_expander: Mapping[str, Any]
) -> list[dict[str, Any]]:
    seed_safe = set(seed_safe_names(seed_safe_report))
    same_lane = set(same_lane_names(seed_safe_report, trace_expander))
    index = cut_row_index(seed_safe_report, trace_expander)
    top_names = [
        str(name)
        for name in first_non_empty_list(
            summary(trace_expander).get("top_near_miss_cut_cards"),
            summary(seed_safe_report).get("same_lane_only_cut_cards"),
            index.keys(),
        )
    ][:16]
    rows = []
    for rank, name in enumerate(top_names, 1):
        row = dict(index.get(name) or {"card_name": name})
        status = target_status(row, same_lane, seed_safe)
        rows.append(
            {
                "rank": rank,
                "card_name": name,
                "lane": row.get("lane"),
                "manual_status": row.get("manual_status"),
                "current_status": row.get("status"),
                "investigation_status": status,
                "unique_exposure_count": as_int(row.get("unique_exposure_count")),
                "direct_event_count": as_int(row.get("direct_event_count")),
                "blockers": as_list(row.get("blockers")),
            }
        )
    return rows


def pressure_package_routes(
    primary_adds: list[dict[str, Any]],
    pressure_micro: Mapping[str, Any],
    seed_safe_cut_count: int,
) -> list[dict[str, Any]]:
    micro_rows = list_of_maps(pressure_micro.get("micro_package_queue"))
    routes: list[dict[str, Any]] = []
    for row in micro_rows:
        required = as_int(row.get("required_cut_count"))
        routes.append(
            {
                "route_key": row.get("package_key"),
                "adds": as_list(row.get("adds")),
                "required_cut_count": required,
                "available_seed_safe_cut_count": seed_safe_cut_count,
                "natural_trigger_count": as_int(row.get("natural_trigger_count")),
                "status": row.get("status"),
                "gate_ready": bool(row.get("gate_ready")),
                "promotion_use": "not_allowed_without_seed_safe_cut_and_strategy_matrix",
            }
        )
    primary_names = [str(row["card_name"]) for row in primary_adds if row.get("card_name")]
    if primary_names:
        routes.insert(
            0,
            {
                "route_key": "primary_four_card_pressure_package",
                "adds": primary_names,
                "required_cut_count": len(primary_names),
                "available_seed_safe_cut_count": seed_safe_cut_count,
                "natural_trigger_count": sum(as_int(row.get("natural_trigger_count")) for row in micro_rows),
                "status": (
                    "gate_candidate_requires_full_preflight"
                    if seed_safe_cut_count >= len(primary_names)
                    else "blocked_no_seed_safe_cut_plan"
                ),
                "gate_ready": seed_safe_cut_count >= len(primary_names),
                "promotion_use": "not_allowed_without_four_named_safe_cuts_and_battle_trace_proof",
            },
        )
    routes.append(
        {
            "route_key": "storm_kiln_artist_haze_of_rage_combo_research",
            "adds": ["Storm-Kiln Artist", "Haze of Rage"],
            "required_cut_count": 2,
            "available_seed_safe_cut_count": seed_safe_cut_count,
            "natural_trigger_count": 0,
            "status": "research_only_runtime_and_cut_safety_required",
            "gate_ready": False,
            "promotion_use": "combo_source_signal_only_until_runtime_cut_and_battle_evidence_exist",
        }
    )
    return routes


def deckbuilding_priority_model(value_model: Mapping[str, Any]) -> dict[str, Any]:
    value_summary = summary(value_model)
    mana_foundation = value_summary.get("mana_foundation")
    return {
        "planning_order": [
            "legal_identity_and_deck_shape",
            "commander_intent_and_win_plan",
            "mana_foundation_lands_sources_ramp",
            "card_flow_selection_and_resource_engine",
            "interaction_protection_and_resilience",
            "commander_specific_packages",
            "staple_impact_by_role",
            "same_lane_cut_cost",
            "battle_and_replay_validation",
        ],
        "current_607_mana_foundation": mana_foundation if isinstance(mana_foundation, Mapping) else {},
        "current_607_lane_profile": value_summary.get("lane_profile") or {},
        "staple_artifact_land_learning": STAPLE_AND_ARTIFACT_POLICY,
        "rule": (
            "A card's generic power becomes actionable only after it improves a "
            "specific Lorehold lane and has a safe cut. Legal, famous, expensive, "
            "or game-changer cards are hypotheses, not automatic upgrades."
        ),
    }


def build_model(
    *,
    router: Mapping[str, Any],
    value_model: Mapping[str, Any],
    seed_safe_report: Mapping[str, Any],
    trace_expander: Mapping[str, Any],
    pressure_micro: Mapping[str, Any],
    pressure_resolver: Mapping[str, Any],
    pressure_contract: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    seed_summary = summary(seed_safe_report)
    trace_summary = summary(trace_expander)
    micro_summary = summary(pressure_micro)
    resolver_summary = summary(pressure_resolver)
    contract_summary = summary(pressure_contract)

    seed_safe_count = as_int(seed_summary.get("seed_safe_cut_ready_count"))
    same_lane_count = as_int(seed_summary.get("same_lane_only_count"))
    reviewable_gap_count = as_int(trace_summary.get("reviewable_evidence_gap_count"))
    gate_ready_cut_count = as_int(resolver_summary.get("gate_ready_cut_count"))
    primary_adds = extract_primary_adds(pressure_contract, pressure_resolver)
    package_routes = pressure_package_routes(primary_adds, pressure_micro, seed_safe_count)
    gate_ready_route_count = sum(1 for row in package_routes if row["gate_ready"])

    if seed_safe_count and gate_ready_route_count:
        status = "pressure_cut_expansion_gate_candidate_requires_preflight"
        recommended_next_action = "run_named_safe_cut_preflight_before_any_natural_battle"
    else:
        status = "pressure_cut_expansion_no_seed_safe_cut_keep_607"
        recommended_next_action = "build_diagnostic_same_lane_microbenchmarks_and_more_trace_mining"

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_pressure_safe_cut_expansion_model",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "status": status,
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "external_deckbuilding_learning": EXTERNAL_DECKBUILDING_LEARNING,
        "summary": {
            "current_baseline": "deck_607",
            "router_status": router.get("status"),
            "seed_safe_cut_ready_count": seed_safe_count,
            "same_lane_only_cut_count": same_lane_count,
            "reviewable_evidence_gap_count": reviewable_gap_count,
            "hard_blocked_count": as_int(trace_summary.get("hard_blocked_count")),
            "gate_ready_cut_count": gate_ready_cut_count,
            "gate_ready_package_count": as_int(micro_summary.get("gate_ready_package_count")),
            "primary_add_count": as_int(contract_summary.get("primary_package_size"))
            or as_int(resolver_summary.get("primary_add_count"))
            or len(primary_adds),
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "ready_deck_change_count": 0,
            "recommended_next_action": recommended_next_action,
        },
        "deckbuilding_priority_model": deckbuilding_priority_model(value_model),
        "primary_pressure_adds": primary_adds,
        "pressure_package_routes": package_routes,
        "cut_expansion_targets": cut_expansion_targets(seed_safe_report, trace_expander),
        "decision": {
            "keep_607_as_protected_baseline": True,
            "promotion_allowed": False,
            "natural_battle_allowed_now": False,
            "reason": (
                "The model has real external pressure/combo signals and internal "
                "trigger evidence, but zero seed-safe cuts. The next deckbuilding "
                "lesson is cut-cost discovery, not another natural battle gate."
            ),
            "next_actions": [
                "do_not_mutate_or_replace_deck_607",
                "do_not_run_natural_battle_for_pressure_package_until_seed_safe_cut_exists",
                "treat Creative Technique and Bender's Waterskin as diagnostic-only same-lane cases",
                "keep Mana Vault and The One Ring as legal staple hypotheses blocked by prior evidence and cut safety",
                "mine or generate more trace evidence specifically for low-exposure non-anchor slots",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = payload["summary"]
    lines = [
        "# Lorehold Pressure Safe-Cut Expansion Model",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- current_baseline: `{summary_row['current_baseline']}`",
        f"- seed_safe_cut_ready_count: `{summary_row['seed_safe_cut_ready_count']}`",
        f"- same_lane_only_cut_count: `{summary_row['same_lane_only_cut_count']}`",
        f"- gate_ready_package_count: `{summary_row['gate_ready_package_count']}`",
        f"- natural_battle_allowed_now: `{str(summary_row['natural_battle_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(summary_row['promotion_allowed']).lower()}`",
        "",
        "## Deckbuilding Priority Model",
        "",
        "| Priority | Meaning |",
        "| ---: | --- |",
    ]
    for index, item in enumerate(payload["deckbuilding_priority_model"]["planning_order"], 1):
        lines.append(f"| {index} | `{item}` |")
    lines.extend(
        [
            "",
            "## Staple, Artifact, And Land Learning",
            "",
            "| Card | Lane | Status | Reason |",
            "| --- | --- | --- | --- |",
        ]
    )
    for row in payload["deckbuilding_priority_model"]["staple_artifact_land_learning"]:
        lines.append(
            f"| {row['card_name']} | `{row['lane']}` | `{row['current_learning_status']}` | {row['reason']} |"
        )
    lines.extend(
        [
            "",
            "## Pressure Package Routes",
            "",
            "| Route | Adds | Status | Required Cuts | Seed-Safe Cuts | Gate Ready |",
            "| --- | --- | --- | ---: | ---: | --- |",
        ]
    )
    for row in payload["pressure_package_routes"]:
        lines.append(
            "| {route} | {adds} | `{status}` | {required} | {safe} | `{ready}` |".format(
                route=row["route_key"],
                adds=", ".join(row["adds"]),
                status=row["status"],
                required=row["required_cut_count"],
                safe=row["available_seed_safe_cut_count"],
                ready=str(row["gate_ready"]).lower(),
            )
        )
    lines.extend(
        [
            "",
            "## Cut Expansion Targets",
            "",
            "| Rank | Card | Lane | Investigation Status | Exposure | Direct Events |",
            "| ---: | --- | --- | --- | ---: | ---: |",
        ]
    )
    for row in payload["cut_expansion_targets"]:
        lines.append(
            "| {rank} | {card} | `{lane}` | `{status}` | {exposure} | {events} |".format(
                rank=row["rank"],
                card=row["card_name"],
                lane=row.get("lane") or "",
                status=row["investigation_status"],
                exposure=row["unique_exposure_count"],
                events=row["direct_event_count"],
            )
        )
    lines.extend(["", "## External Learning", ""])
    for row in payload["external_deckbuilding_learning"]:
        lines.append(f"- {row['source']}: {row['url']} -> `{row['model_effect']}`")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append("- next_actions:")
    for action in decision["next_actions"]:
        lines.append(f"  - {action}")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--router", type=Path, default=DEFAULT_ROUTER)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--seed-safe", type=Path, default=DEFAULT_SEED_SAFE)
    parser.add_argument("--trace-expander", type=Path, default=DEFAULT_TRACE_EXPANDER)
    parser.add_argument("--pressure-micro", type=Path, default=DEFAULT_PRESSURE_MICRO)
    parser.add_argument("--pressure-resolver", type=Path, default=DEFAULT_PRESSURE_RESOLVER)
    parser.add_argument("--pressure-contract", type=Path, default=DEFAULT_PRESSURE_CONTRACT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    paths = {
        "router": args.router,
        "value_model": args.value_model,
        "seed_safe_cut_report": args.seed_safe,
        "trace_cut_evidence_expander": args.trace_expander,
        "pressure_micro_package_planner": args.pressure_micro,
        "pressure_safe_cut_pool_resolver": args.pressure_resolver,
        "pressure_safe_spell_payoff_contract": args.pressure_contract,
    }
    payload = build_model(
        router=read_json(args.router),
        value_model=read_json(args.value_model),
        seed_safe_report=read_json(args.seed_safe),
        trace_expander=read_json(args.trace_expander),
        pressure_micro=read_json(args.pressure_micro),
        pressure_resolver=read_json(args.pressure_resolver),
        pressure_contract=read_json(args.pressure_contract),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
