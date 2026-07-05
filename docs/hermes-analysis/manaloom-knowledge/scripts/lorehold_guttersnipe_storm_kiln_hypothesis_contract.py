#!/usr/bin/env python3
"""Write the Guttersnipe + Storm-Kiln Lorehold learning contract.

This read-only artifact turns the best engine-preserving pressure/conversion
route into a concrete pre-battle contract. It does not build a deck. Its job is
to prove whether the route has named safe cuts and to predeclare the event,
metric, and matchup requirements that must be satisfied before any natural
battle gate can be run against protected deck 607.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_ENGINE_ROUTER = (
    REPORT_DIR / "lorehold_engine_preserving_pressure_conversion_router_20260705_current_relearn.json"
)
DEFAULT_SEED_SAFE = REPORT_DIR / "lorehold_seed_safe_cut_hypothesis_20260704_role_tag_repair.json"
DEFAULT_TRACE_EXPANDER = REPORT_DIR / "lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.json"
DEFAULT_CLOSING_TRACE = REPORT_DIR / "lorehold_closing_window_trace_miner_20260704_role_tag_repair.json"
DEFAULT_MIRACLE_TRACE = REPORT_DIR / "lorehold_miracle_trace_failure_miner_20260704_current.json"
DEFAULT_PACKAGE_ROUTER = (
    REPORT_DIR / "lorehold_pressure_package_size_router_20260705_current_relearn.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_guttersnipe_storm_kiln_hypothesis_contract_20260705_current_relearn"
)

TARGET_ROUTE_KEY = "guttersnipe_storm_kiln_engine_preserving_pair"
TARGET_ADDS = ["Guttersnipe", "Storm-Kiln Artist"]

EVENT_REQUIREMENTS = [
    {
        "requirement_key": "guttersnipe_direct_spell_damage",
        "required": True,
        "event_family": "Guttersnipe trigger/damage",
        "measurement": (
            "At least one candidate win or protected equal-gate game must show "
            "Guttersnipe converting instant/sorcery casts into direct opponent damage."
        ),
    },
    {
        "requirement_key": "storm_kiln_treasure_conversion",
        "required": True,
        "event_family": "trigger_resolved:Storm-Kiln Artist and treasure_created:Storm-Kiln Artist",
        "measurement": (
            "Storm-Kiln must create Treasures from instant/sorcery casts or copies, "
            "and those Treasures must connect to spell-chain or survival value."
        ),
    },
    {
        "requirement_key": "no_proxy_win_without_new_cards",
        "required": True,
        "event_family": "card-use causality",
        "measurement": (
            "A win carried only by existing 607 topdeck/miracle cards is not proof "
            "for Guttersnipe or Storm-Kiln."
        ),
    },
]

ENGINE_FLOOR_REQUIREMENTS = [
    "same_seed_same_opponent_matrix_against_protected_deck_607",
    "no_regression_in_winota_fast_pressure_slice",
    "no_regression_in_miracle_cast_and_topdeck_manipulation_counts",
    "no_regression_in_lorehold_spell_cast_and_upkeep_rummage_counts",
    "preserve_early_mana_floor_and_protection_shell",
    "preserve_approach_conversion_or_explain_replacement_win_path",
]

HARD_STOP_CUT_CLASSES = [
    "commander",
    "mana_base",
    "early_mana",
    "protection",
    "topdeck_miracle_setup",
    "miracle_or_finisher_core",
    "measured_high_cut_exposure",
    "prior_rejected_cut",
    "structural_dependency",
    "protected_cut",
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


def as_dict(value: Any) -> dict[str, Any]:
    return dict(value) if isinstance(value, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def route_by_key(engine_router: Mapping[str, Any], route_key: str) -> dict[str, Any]:
    for row in as_list(engine_router.get("routes")):
        if isinstance(row, Mapping) and row.get("route_key") == route_key:
            return dict(row)
    return {}


def package_by_key(package_router: Mapping[str, Any], package_key: str) -> dict[str, Any]:
    for row in as_list(package_router.get("packages")):
        if isinstance(row, Mapping) and row.get("package_key") == package_key:
            return dict(row)
    return {}


def named_seed_safe_cuts(seed_safe_report: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in as_list(seed_safe_report.get("seed_safe_cut_candidates")):
        if isinstance(row, Mapping) and row.get("card_name"):
            rows.append(
                {
                    "card_name": row.get("card_name"),
                    "lane": row.get("lane") or "",
                    "score": row.get("score"),
                    "unique_exposure_count": row.get("unique_exposure_count"),
                    "blockers": as_list(row.get("blockers")),
                }
            )
    return rows


def same_lane_only_slots(
    seed_safe_report: Mapping[str, Any], trace_expander: Mapping[str, Any]
) -> list[dict[str, Any]]:
    by_name: dict[str, dict[str, Any]] = {}
    for source_key in ("same_lane_only_cut_slots", "same_lane_hard_blocked_queue"):
        source = seed_safe_report if source_key == "same_lane_only_cut_slots" else trace_expander
        for row in as_list(source.get(source_key)):
            if isinstance(row, Mapping) and row.get("card_name"):
                current = by_name.setdefault(str(row["card_name"]), {"card_name": row["card_name"]})
                current.update(
                    {
                        "lane": row.get("lane") or current.get("lane") or "",
                        "status": row.get("status") or current.get("status") or "",
                        "manual_status": row.get("manual_status") or current.get("manual_status") or "",
                        "unique_exposure_count": row.get("unique_exposure_count")
                        if row.get("unique_exposure_count") is not None
                        else current.get("unique_exposure_count"),
                        "direct_event_count": row.get("direct_event_count")
                        if row.get("direct_event_count") is not None
                        else current.get("direct_event_count"),
                        "blockers": sorted(
                            set(as_list(current.get("blockers")) + as_list(row.get("blockers")))
                        ),
                    }
                )
    for name in as_list(summary(seed_safe_report).get("same_lane_only_cut_cards")):
        by_name.setdefault(str(name), {"card_name": str(name), "blockers": []})
    return sorted(by_name.values(), key=lambda row: str(row.get("card_name") or ""))


def top_near_miss_names(trace_expander: Mapping[str, Any]) -> list[str]:
    names = [str(name) for name in as_list(summary(trace_expander).get("top_near_miss_cut_cards"))]
    return names[:12]


def blocker_counts(*reports: Mapping[str, Any]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for report in reports:
        for blocker, count in as_dict(summary(report).get("blocker_counts")).items():
            counts[str(blocker)] += as_int(count)
    return dict(sorted(counts.items()))


def decision_status(
    *,
    target_route: Mapping[str, Any],
    seed_safe_cuts: Sequence[Mapping[str, Any]],
    required_cut_count: int,
) -> tuple[str, str]:
    if not target_route:
        return (
            "hypothesis_contract_blocked_missing_engine_preserving_route",
            "rebuild_engine_preserving_router_before_contract_or_battle",
        )
    if target_route.get("gate_ready") and len(seed_safe_cuts) >= required_cut_count:
        return (
            "hypothesis_contract_ready_for_structure_matrix",
            "run_structure_matrix_before_equal_battle_gate",
        )
    return (
        "hypothesis_contract_written_blocked_no_named_safe_cuts",
        "mine_or_create_cut_evidence_for_two_named_same_lane_nonanchor_slots",
    )


def build_report(
    *,
    engine_router: Mapping[str, Any],
    seed_safe_report: Mapping[str, Any],
    trace_expander: Mapping[str, Any],
    closing_trace: Mapping[str, Any],
    miracle_trace: Mapping[str, Any],
    package_router: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    route = route_by_key(engine_router, TARGET_ROUTE_KEY)
    package_key = str(route.get("package_key") or "pressure_2_card_guttersnipe_storm_kiln_artist")
    package_row = package_by_key(package_router, package_key)
    seed_summary = summary(seed_safe_report)
    trace_summary = summary(trace_expander)
    closing_summary = summary(closing_trace)
    miracle_summary = summary(miracle_trace)
    seed_safe_cuts = named_seed_safe_cuts(seed_safe_report)
    required_cut_count = 2
    status, next_action = decision_status(
        target_route=route,
        seed_safe_cuts=seed_safe_cuts,
        required_cut_count=required_cut_count,
    )
    same_lane_slots = same_lane_only_slots(seed_safe_report, trace_expander)
    cut_shortage = max(0, required_cut_count - len(seed_safe_cuts))
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_guttersnipe_storm_kiln_hypothesis_contract",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "status": status,
        "summary": {
            "decision_status": status,
            "target_route_key": TARGET_ROUTE_KEY,
            "target_adds": TARGET_ADDS,
            "required_cut_count": required_cut_count,
            "available_named_seed_safe_cut_count": len(seed_safe_cuts),
            "cut_shortage": cut_shortage,
            "same_lane_only_cut_count": as_int(seed_summary.get("same_lane_only_count")),
            "hard_blocked_count": as_int(trace_summary.get("hard_blocked_count"))
            or as_int(seed_summary.get("blocked_count")),
            "ready_deck_change_count": 0,
            "promotion_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "structure_matrix_allowed_now": status == "hypothesis_contract_ready_for_structure_matrix",
            "closing_window_comparison_count": as_int(closing_summary.get("comparison_count")),
            "avg_607_turn_advantage": closing_summary.get("avg_607_turn_advantage") or 0,
            "miracle_trace_failure_flag_count": len(
                as_list(miracle_summary.get("blocking_failure_flags"))
            ),
            "router_route_status": route.get("status") or "",
            "package_status": package_row.get("status") or route.get("package_status") or "",
            "recommended_next_action": next_action,
        },
        "candidate_package_contract": {
            "adds": TARGET_ADDS,
            "route_key": TARGET_ROUTE_KEY,
            "lane": route.get("lane") or "engine_preserving_pressure_conversion_pair",
            "package_key": package_key,
            "required_cut_count": required_cut_count,
            "available_named_seed_safe_cuts": seed_safe_cuts,
            "same_lane_only_slots_not_seed_safe": same_lane_slots,
            "top_near_miss_cut_cards": top_near_miss_names(trace_expander),
            "hard_stop_cut_classes": HARD_STOP_CUT_CLASSES,
            "event_requirements": EVENT_REQUIREMENTS,
            "engine_floor_requirements": ENGINE_FLOOR_REQUIREMENTS,
            "battle_gate_requirements": [
                "structure_matrix_passes_before_battle",
                "copied_db_only_until_promotion_gate_passes",
                "same_seed_same_opponents_against_current_607",
                "direct_card_use_evidence_for_each_added_card",
                "Winota fast-pressure slice must tie or improve",
            ],
        },
        "route_evidence": route,
        "package_router_row": package_row,
        "cut_evidence": {
            "seed_safe_summary": seed_summary,
            "trace_cut_summary": trace_summary,
            "combined_blocker_counts": blocker_counts(seed_safe_report, trace_expander),
            "named_seed_safe_cuts": seed_safe_cuts,
            "same_lane_only_slots_not_seed_safe": same_lane_slots,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "Guttersnipe plus Storm-Kiln is the best next learning route, but it "
                "requires two named seed-safe cuts and the current evidence has zero."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_run_natural_battle_until_two_named_safe_cuts_exist",
                "mine low-exposure non-anchor cut evidence before any package build",
                "require direct Guttersnipe damage and Storm-Kiln Treasure events in future tests",
                "preserve topdeck, miracle, mana, protection, and Winota fast-pressure floors",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = payload["summary"]
    contract = payload["candidate_package_contract"]
    lines = [
        "# Lorehold Guttersnipe + Storm-Kiln Hypothesis Contract",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{summary_row['decision_status']}`",
        f"- Target route: `{summary_row['target_route_key']}`",
        f"- Target adds: `{', '.join(summary_row['target_adds'])}`",
        f"- Required cuts: `{summary_row['required_cut_count']}`",
        f"- Available named seed-safe cuts: `{summary_row['available_named_seed_safe_cut_count']}`",
        f"- Cut shortage: `{summary_row['cut_shortage']}`",
        f"- Natural battle gate allowed now: `{str(summary_row['natural_battle_gate_allowed_now']).lower()}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(
        [
            "",
            "## Cut Status",
            "",
            "### Named Seed-Safe Cuts",
            "",
        ]
    )
    safe_cuts = as_list(contract.get("available_named_seed_safe_cuts"))
    if safe_cuts:
        for row in safe_cuts:
            lines.append(f"- `{row.get('card_name')}` lane `{row.get('lane')}`")
    else:
        lines.append("- None.")
    lines.extend(["", "### Same-Lane Only Slots Not Seed-Safe", ""])
    same_lane = as_list(contract.get("same_lane_only_slots_not_seed_safe"))
    if same_lane:
        for row in same_lane:
            lines.append(
                f"- `{row.get('card_name')}` lane `{row.get('lane') or ''}` blockers "
                f"`{', '.join(as_list(row.get('blockers'))) or '-'}`."
            )
    else:
        lines.append("- None.")
    lines.extend(["", "## Event Requirements", ""])
    for row in as_list(contract.get("event_requirements")):
        lines.append(f"- `{row.get('requirement_key')}`: {row.get('measurement')}")
    lines.extend(["", "## Engine Floor Requirements", ""])
    for item in as_list(contract.get("engine_floor_requirements")):
        lines.append(f"- `{item}`")
    lines.extend(["", "## Hard Stop Cut Classes", ""])
    for item in as_list(contract.get("hard_stop_cut_classes")):
        lines.append(f"- `{item}`")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append("- next_actions:")
    for action in decision["next_actions"]:
        lines.append(f"  - {action}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine-router", type=Path, default=DEFAULT_ENGINE_ROUTER)
    parser.add_argument("--seed-safe", type=Path, default=DEFAULT_SEED_SAFE)
    parser.add_argument("--trace-expander", type=Path, default=DEFAULT_TRACE_EXPANDER)
    parser.add_argument("--closing-trace", type=Path, default=DEFAULT_CLOSING_TRACE)
    parser.add_argument("--miracle-trace", type=Path, default=DEFAULT_MIRACLE_TRACE)
    parser.add_argument("--package-router", type=Path, default=DEFAULT_PACKAGE_ROUTER)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "engine_router": args.engine_router,
        "seed_safe_cut_report": args.seed_safe,
        "trace_cut_evidence_expander": args.trace_expander,
        "closing_trace": args.closing_trace,
        "miracle_trace": args.miracle_trace,
        "package_router": args.package_router,
    }
    payload = build_report(
        engine_router=read_json(args.engine_router),
        seed_safe_report=read_json(args.seed_safe),
        trace_expander=read_json(args.trace_expander),
        closing_trace=read_json(args.closing_trace),
        miracle_trace=read_json(args.miracle_trace),
        package_router=read_json(args.package_router),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
