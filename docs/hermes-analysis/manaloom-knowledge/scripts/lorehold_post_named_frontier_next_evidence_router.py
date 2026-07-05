#!/usr/bin/env python3
"""Route the next Lorehold evidence step after named cut frontiers closed.

This read-only artifact sits after the non-floor probe closure and the named
same-lane cut frontier. It decides which learning evidence should be collected
next without opening deck mutation, structure scoring, forced access, or a
natural battle gate.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_NON_FLOOR_CLOSURE = (
    REPORT_DIR / "lorehold_non_floor_probe_evidence_closure_20260705_current.json"
)
DEFAULT_NAMED_FRONTIER = (
    REPORT_DIR / "lorehold_named_same_lane_cut_frontier_20260705_current.json"
)
DEFAULT_TOPDECK_COLLECTOR = (
    REPORT_DIR / "lorehold_topdeck_floor_trace_evidence_collector_20260705_current.json"
)
DEFAULT_NONANCHOR_MODEL = (
    REPORT_DIR / "lorehold_topdeck_nonanchor_cut_model_miner_20260705_current.json"
)
DEFAULT_MANA_INTEGRATOR = (
    REPORT_DIR / "lorehold_mana_base_decision_integrator_20260705_after_plateau_turbulent_current.json"
)
DEFAULT_CURRENT_BEST = (
    REPORT_DIR / "lorehold_current_best_baseline_synthesis_20260705_non_floor_probe_closure_current.json"
)
DEFAULT_STAPLE_ACCESSIBILITY = (
    REPORT_DIR / "lorehold_staple_accessibility_freshness_audit_20260705_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_post_named_frontier_next_evidence_router_20260705_current"
)

MATRIX_READY_STATUSES = {
    "named_same_lane_cut_frontier_has_structure_contract_rows_no_deck",
}


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


def missing_inputs(payloads: Mapping[str, Mapping[str, Any]]) -> list[str]:
    return [key for key, payload in payloads.items() if not payload]


def clean_prior_targets(nonanchor_model: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in as_list(nonanchor_model.get("target_cut_models")):
        if not isinstance(row, Mapping) or not row.get("clean_prior_target"):
            continue
        rows.append(
            {
                "card_name": row.get("card_name") or "",
                "model_status": row.get("model_status") or "",
                "same_lane_slot_count": as_int(row.get("same_lane_slot_count")),
                "seed_safe_nonanchor_count": as_int(row.get("seed_safe_nonanchor_count")),
                "reviewable_nonanchor_gap_count": as_int(row.get("reviewable_nonanchor_gap_count")),
                "top_blocked_same_lane_slots": [
                    {
                        "card_name": slot.get("card_name") or "",
                        "lane": slot.get("lane") or "",
                        "unique_exposure_count": as_int(slot.get("unique_exposure_count")),
                        "hard_stop_blockers": as_list(slot.get("hard_stop_blockers")),
                    }
                    for slot in as_list(row.get("top_blocked_same_lane_slots"))[:8]
                    if isinstance(slot, Mapping)
                ],
                "next_action": row.get("next_action") or "",
            }
        )
    rows.sort(key=lambda row: (row["card_name"], row["model_status"]))
    return rows


def prior_reject_targets(nonanchor_model: Mapping[str, Any]) -> list[str]:
    return [
        str(row.get("card_name") or "")
        for row in as_list(nonanchor_model.get("target_cut_models"))
        if isinstance(row, Mapping)
        and str(row.get("model_status") or "").startswith("prior_reject_target")
    ]


def rejected_mana_pairs(mana_integrator: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in as_list(mana_integrator.get("annotated_model_ready_pairs")):
        if not isinstance(row, Mapping):
            continue
        if row.get("learning_status") != "blocked_exact_tested_decision":
            continue
        rows.append(
            {
                "add": row.get("add") or "",
                "cut": row.get("cut") or "",
                "decision_status": row.get("decision_status") or "",
                "next_action": row.get("next_action") or "",
                "decision_blockers": as_list(row.get("decision_blockers")),
            }
        )
    rows.sort(key=lambda row: (row["add"], row["cut"]))
    return rows


def staple_rows(staple_accessibility: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in as_list(staple_accessibility.get("cards")):
        if not isinstance(row, Mapping):
            continue
        rows.append(
            {
                "card_name": row.get("card_name") or "",
                "owned": bool(as_dict(row.get("collection")).get("owned")),
                "commander_legal": bool(as_dict(row.get("external")).get("commander_legal")),
                "game_changer": bool(as_dict(row.get("external")).get("game_changer")),
                "readiness_status": as_dict(row.get("hypothesis")).get("readiness_status") or "",
                "promotion_decision": as_dict(row.get("promotion")).get("decision") or "",
                "next_action": row.get("next_action") or "",
            }
        )
    rows.sort(key=lambda row: row["card_name"])
    return rows


def matrix_ready(named_frontier: Mapping[str, Any]) -> bool:
    named_summary = summary(named_frontier)
    return (
        named_frontier.get("status") in MATRIX_READY_STATUSES
        or named_summary.get("structure_matrix_contract_allowed_now") is True
        or as_int(named_summary.get("topdeck_matrix_ready_probe_count")) > 0
        or as_int(named_summary.get("mana_eligible_pair_count")) > 0
    )


def build_routes(
    *,
    non_floor_closure: Mapping[str, Any],
    named_frontier: Mapping[str, Any],
    topdeck_collector: Mapping[str, Any],
    nonanchor_model: Mapping[str, Any],
    mana_integrator: Mapping[str, Any],
    current_best: Mapping[str, Any],
    staple_accessibility: Mapping[str, Any],
) -> list[dict[str, Any]]:
    non_floor_summary = summary(non_floor_closure)
    named_summary = summary(named_frontier)
    collector_summary = summary(topdeck_collector)
    nonanchor_summary = summary(nonanchor_model)
    mana_summary = summary(mana_integrator)
    current_best_summary = summary(current_best)
    clean_targets = clean_prior_targets(nonanchor_model)
    mana_rejects = rejected_mana_pairs(mana_integrator)
    staples = staple_rows(staple_accessibility)
    routes = [
        {
            "route_key": "structure_matrix_contract_review",
            "priority_score": 120 if matrix_ready(named_frontier) else 0,
            "route_status": "available_matrix_contract_review" if matrix_ready(named_frontier) else "closed_no_matrix_ready_rows",
            "learning_allowed_now": matrix_ready(named_frontier),
            "execution_allowed_now": False,
            "deck_action_allowed_now": False,
            "natural_battle_allowed_now": False,
            "why": (
                "Named frontier has a structure-contract row."
                if matrix_ready(named_frontier)
                else "Named frontier has zero topdeck matrix-ready probes and zero eligible mana pairs."
            ),
            "evidence": {
                "topdeck_matrix_ready_probe_count": as_int(
                    named_summary.get("topdeck_matrix_ready_probe_count")
                ),
                "mana_eligible_pair_count": as_int(named_summary.get("mana_eligible_pair_count")),
            },
            "next_action": "write_structure_matrix_contract_for_frontier_rows_no_battle",
        },
        {
            "route_key": "topdeck_new_cut_evidence_scout",
            "priority_score": 100 + len(clean_targets),
            "route_status": (
                "learning_scout_primary_clean_prior_target"
                if clean_targets
                else "learning_scout_requires_new_topdeck_cut_surface"
            ),
            "learning_allowed_now": True,
            "execution_allowed_now": False,
            "deck_action_allowed_now": False,
            "natural_battle_allowed_now": False,
            "why": (
                "Dragon's Rage Channeler is the clean-prior topdeck target, but every same-lane slot is hard-blocked."
                if clean_targets
                else "Topdeck targets have no current clean-prior nonanchor cut path."
            ),
            "evidence": {
                "clean_prior_targets": clean_targets,
                "prior_reject_targets": prior_reject_targets(nonanchor_model),
                "collector_cut_safety_blocked_target_count": as_int(
                    collector_summary.get("cut_safety_blocked_target_count")
                ),
                "seed_safe_nonanchor_count": as_int(nonanchor_summary.get("seed_safe_nonanchor_count")),
                "reviewable_nonanchor_gap_count": as_int(
                    nonanchor_summary.get("reviewable_nonanchor_gap_count")
                ),
            },
            "next_action": "find_new_nonanchor_same_lane_cut_evidence_not_in_current_hard_blocked_slots",
        },
        {
            "route_key": "mana_trace_evidence_scout",
            "priority_score": 80 if mana_rejects else 55,
            "route_status": (
                "learning_scout_distinct_mana_trace_required"
                if mana_rejects
                else "learning_scout_generic_mana_floor_equivalence_required"
            ),
            "learning_allowed_now": True,
            "execution_allowed_now": False,
            "deck_action_allowed_now": False,
            "natural_battle_allowed_now": False,
            "why": (
                "The exact Plateau pairs are rejected; only materially new mana trace evidence can reopen mana."
            ),
            "evidence": {
                "eligible_model_ready_pair_count": as_int(mana_summary.get("eligible_model_ready_pair_count")),
                "exact_rejected_pair_count": as_int(mana_summary.get("exact_rejected_pair_count")),
                "rejected_pairs": mana_rejects,
                "non_floor_generic_mana_probe_count": as_int(
                    non_floor_summary.get("blocked_generic_mana_probe_count")
                ),
            },
            "next_action": "collect_distinct_mana_equivalence_trace_without_retesting_exact_plateau_pairs",
        },
        {
            "route_key": "new_shell_contract_scout",
            "priority_score": 70,
            "route_status": "learning_scout_new_shell_contract_only",
            "learning_allowed_now": True,
            "execution_allowed_now": False,
            "deck_action_allowed_now": False,
            "natural_battle_allowed_now": False,
            "why": "Current-best requires either a new shell contract or new cut evidence before any battle.",
            "evidence": {
                "current_best_status": current_best.get("status") or "",
                "current_best_next_action": current_best_summary.get("recommended_next_action") or "",
                "top_deck_is_607": bool(current_best_summary.get("top_deck_is_607")),
                "current_positive_signal_count": as_int(
                    current_best_summary.get("current_positive_signal_count")
                ),
            },
            "next_action": "define_new_shell_contract_only_if_it_names_floor_metrics_and_cut_evidence",
        },
        {
            "route_key": "staple_retest_scout",
            "priority_score": 40,
            "route_status": "closed_learning_only_prior_rejects",
            "learning_allowed_now": False,
            "execution_allowed_now": False,
            "deck_action_allowed_now": False,
            "natural_battle_allowed_now": False,
            "why": "Mana Vault and The One Ring remain legal/high-priority ideas, not 607 changes.",
            "evidence": {
                "staples": staples,
            },
            "next_action": "do_not_retest_staples_until_new_same_lane_cut_and_trace_hypothesis_exists",
        },
    ]
    routes.sort(
        key=lambda row: (
            0 if row["learning_allowed_now"] and row["priority_score"] else 1,
            -as_int(row["priority_score"]),
            str(row["route_key"]),
        )
    )
    return routes


def select_route(routes: list[Mapping[str, Any]], missing: list[str]) -> tuple[str, str, str]:
    if missing:
        return (
            "repair_missing_inputs_before_next_evidence_route",
            "post_named_frontier_next_evidence_router_inputs_missing_keep_607",
            "rerun_missing_inputs_before_next_evidence_route",
        )
    matrix = next((row for row in routes if row.get("route_key") == "structure_matrix_contract_review"), {})
    if matrix.get("learning_allowed_now") and as_int(matrix.get("priority_score")) > 0:
        return (
            "structure_matrix_contract_review",
            "post_named_frontier_next_evidence_router_matrix_contract_review_no_deck",
            "write_structure_matrix_contract_for_frontier_rows_no_battle",
        )
    topdeck = next((row for row in routes if row.get("route_key") == "topdeck_new_cut_evidence_scout"), {})
    if topdeck.get("learning_allowed_now"):
        return (
            "topdeck_new_cut_evidence_scout",
            "post_named_frontier_next_evidence_router_learning_only_keep_607",
            "find_new_nonanchor_same_lane_cut_evidence_not_in_current_hard_blocked_slots",
        )
    return (
        "new_shell_contract_scout",
        "post_named_frontier_next_evidence_router_new_shell_only_keep_607",
        "define_new_shell_contract_before_any_battle_gate",
    )


def build_report(
    *,
    non_floor_closure: Mapping[str, Any],
    named_frontier: Mapping[str, Any],
    topdeck_collector: Mapping[str, Any],
    nonanchor_model: Mapping[str, Any],
    mana_integrator: Mapping[str, Any],
    current_best: Mapping[str, Any],
    staple_accessibility: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    payloads = {
        "non_floor_closure": non_floor_closure,
        "named_frontier": named_frontier,
        "topdeck_collector": topdeck_collector,
        "nonanchor_model": nonanchor_model,
        "mana_integrator": mana_integrator,
        "current_best": current_best,
        "staple_accessibility": staple_accessibility,
    }
    missing = missing_inputs(payloads)
    routes = [] if missing else build_routes(
        non_floor_closure=non_floor_closure,
        named_frontier=named_frontier,
        topdeck_collector=topdeck_collector,
        nonanchor_model=nonanchor_model,
        mana_integrator=mana_integrator,
        current_best=current_best,
        staple_accessibility=staple_accessibility,
    )
    selected_route, status, next_action = select_route(routes, missing)
    non_floor_summary = summary(non_floor_closure)
    named_summary = summary(named_frontier)
    collector_summary = summary(topdeck_collector)
    nonanchor_summary = summary(nonanchor_model)
    mana_summary = summary(mana_integrator)
    current_best_summary = summary(current_best)
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_post_named_frontier_next_evidence_router",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": {
            "decision_status": status,
            "selected_next_route": selected_route,
            "recommended_next_action": next_action,
            "missing_inputs": missing,
            "non_floor_probe_count": as_int(non_floor_summary.get("non_floor_probe_count")),
            "non_floor_safe_cut_ready_count": as_int(
                non_floor_summary.get("non_floor_safe_cut_ready_count")
            ),
            "non_floor_matrix_candidate_row_eligible_count": as_int(
                non_floor_summary.get("non_floor_matrix_candidate_row_eligible_count")
            ),
            "named_topdeck_matrix_ready_probe_count": as_int(
                named_summary.get("topdeck_matrix_ready_probe_count")
            ),
            "named_mana_eligible_pair_count": as_int(named_summary.get("mana_eligible_pair_count")),
            "topdeck_cut_safety_blocked_target_count": as_int(
                collector_summary.get("cut_safety_blocked_target_count")
            ),
            "topdeck_clean_prior_blocked_target_count": as_int(
                nonanchor_summary.get("clean_prior_blocked_target_count")
            ),
            "topdeck_seed_safe_nonanchor_count": as_int(
                nonanchor_summary.get("seed_safe_nonanchor_count")
            ),
            "topdeck_reviewable_nonanchor_gap_count": as_int(
                nonanchor_summary.get("reviewable_nonanchor_gap_count")
            ),
            "mana_exact_rejected_pair_count": as_int(mana_summary.get("exact_rejected_pair_count")),
            "current_best_top_deck_is_607": bool(current_best_summary.get("top_deck_is_607")),
            "current_positive_signal_count": as_int(
                current_best_summary.get("current_positive_signal_count")
            ),
            "learning_route_count": sum(1 for row in routes if row.get("learning_allowed_now")),
            "execution_ready_route_count": 0,
            "deck_action_allowed_now": False,
            "structure_matrix_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
        },
        "evidence_routes": routes,
        "source_evidence": {
            "non_floor_closure_summary": non_floor_summary,
            "named_frontier_summary": named_summary,
            "topdeck_collector_summary": collector_summary,
            "nonanchor_model_summary": nonanchor_summary,
            "mana_integrator_summary": mana_summary,
            "current_best_summary": current_best_summary,
            "staple_accessibility_summary": summary(staple_accessibility),
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "selected_next_route": selected_route,
            "deck_action_allowed": False,
            "structure_matrix_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "The named same-lane frontier, non-floor probe closure, non-anchor model, "
                "and mana integrator all have zero executable rows. The next valid work "
                "is learning-only evidence discovery, led by a new nonanchor same-lane "
                "cut-evidence scout for the clean-prior topdeck target."
            )
            if not missing
            else "At least one required source report is missing.",
            "next_actions": [
                next_action,
                "do_not_mutate_deck_607",
                "do_not_run_forced_access_or_natural_battle_from_learning_routes",
                "do_not_retest_exact_plateau_pairs_or_prior_rejected_staples_without_new_trace_evidence",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = summary(payload)
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Post-Named Frontier Next Evidence Router",
        "",
        f"- Generated at: `{payload.get('generated_at')}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload.get('status')}`",
        f"- Selected next route: `{summary_row.get('selected_next_route')}`",
        f"- Recommended next action: `{summary_row.get('recommended_next_action')}`",
        f"- Non-floor probes: `{summary_row.get('non_floor_probe_count')}`",
        f"- Non-floor safe cuts: `{summary_row.get('non_floor_safe_cut_ready_count')}`",
        f"- Non-floor matrix rows: `{summary_row.get('non_floor_matrix_candidate_row_eligible_count')}`",
        f"- Topdeck clean-prior blocked targets: `{summary_row.get('topdeck_clean_prior_blocked_target_count')}`",
        f"- Topdeck seed-safe nonanchor cuts: `{summary_row.get('topdeck_seed_safe_nonanchor_count')}`",
        f"- Mana exact rejected pairs: `{summary_row.get('mana_exact_rejected_pair_count')}`",
        f"- Candidate materialization allowed: `{str(summary_row.get('candidate_deck_materialization_allowed_now')).lower()}`",
        f"- Natural battle gate allowed: `{str(summary_row.get('natural_battle_gate_allowed_now')).lower()}`",
        f"- Promotion allowed: `{str(summary_row.get('promotion_allowed_now')).lower()}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Evidence Routes", ""])
    lines.append("| Route | Status | Priority | Learning | Execution | Next action |")
    lines.append("| --- | --- | ---: | ---: | ---: | --- |")
    for row in as_list(payload.get("evidence_routes")):
        if not isinstance(row, Mapping):
            continue
        lines.append(
            "| `{route}` | `{status}` | {priority} | `{learning}` | `{execution}` | `{next}` |".format(
                route=row.get("route_key") or "",
                status=row.get("route_status") or "",
                priority=row.get("priority_score") or 0,
                learning=str(bool(row.get("learning_allowed_now"))).lower(),
                execution=str(bool(row.get("execution_allowed_now"))).lower(),
                next=row.get("next_action") or "",
            )
        )
    lines.extend(["", "## Key Route Evidence", ""])
    for row in as_list(payload.get("evidence_routes")):
        if not isinstance(row, Mapping):
            continue
        if row.get("route_key") not in {"topdeck_new_cut_evidence_scout", "mana_trace_evidence_scout", "staple_retest_scout"}:
            continue
        lines.append(f"### {row.get('route_key')}")
        lines.append(f"- why: {row.get('why')}")
        evidence = as_dict(row.get("evidence"))
        if row.get("route_key") == "topdeck_new_cut_evidence_scout":
            for target in as_list(evidence.get("clean_prior_targets")):
                if isinstance(target, Mapping):
                    lines.append(
                        "- clean_prior_target: `{}` same_lane_slots=`{}` seed_safe=`{}` reviewable=`{}`".format(
                            target.get("card_name") or "",
                            target.get("same_lane_slot_count") or 0,
                            target.get("seed_safe_nonanchor_count") or 0,
                            target.get("reviewable_nonanchor_gap_count") or 0,
                        )
                    )
        if row.get("route_key") == "mana_trace_evidence_scout":
            for pair in as_list(evidence.get("rejected_pairs")):
                if isinstance(pair, Mapping):
                    lines.append(
                        f"- rejected_pair: `{pair.get('add')}` over `{pair.get('cut')}` status=`{pair.get('decision_status')}`"
                    )
        if row.get("route_key") == "staple_retest_scout":
            for staple in as_list(evidence.get("staples")):
                if isinstance(staple, Mapping):
                    lines.append(
                        f"- staple: `{staple.get('card_name')}` owned=`{str(bool(staple.get('owned'))).lower()}` decision=`{staple.get('promotion_decision')}`"
                    )
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision.get('keep_607_as_protected_baseline')).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision.get('deck_action_allowed')).lower()}`")
    lines.append(f"- structure_matrix_allowed_now: `{str(decision.get('structure_matrix_allowed_now')).lower()}`")
    lines.append(f"- candidate_deck_materialization_allowed_now: `{str(decision.get('candidate_deck_materialization_allowed_now')).lower()}`")
    lines.append(f"- forced_access_allowed_now: `{str(decision.get('forced_access_allowed_now')).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision.get('natural_battle_allowed_now')).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision.get('promotion_allowed')).lower()}`")
    lines.append(f"- reason: {decision.get('reason')}")
    lines.append("- next_actions:")
    for action in as_list(decision.get("next_actions")):
        lines.append(f"  - `{action}`")
    return "\n".join(lines).rstrip() + "\n"


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
    parser.add_argument("--non-floor-closure", type=Path, default=DEFAULT_NON_FLOOR_CLOSURE)
    parser.add_argument("--named-frontier", type=Path, default=DEFAULT_NAMED_FRONTIER)
    parser.add_argument("--topdeck-collector", type=Path, default=DEFAULT_TOPDECK_COLLECTOR)
    parser.add_argument("--nonanchor-model", type=Path, default=DEFAULT_NONANCHOR_MODEL)
    parser.add_argument("--mana-integrator", type=Path, default=DEFAULT_MANA_INTEGRATOR)
    parser.add_argument("--current-best", type=Path, default=DEFAULT_CURRENT_BEST)
    parser.add_argument("--staple-accessibility", type=Path, default=DEFAULT_STAPLE_ACCESSIBILITY)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "current_best": args.current_best,
        "mana_integrator": args.mana_integrator,
        "named_frontier": args.named_frontier,
        "non_floor_closure": args.non_floor_closure,
        "nonanchor_model": args.nonanchor_model,
        "staple_accessibility": args.staple_accessibility,
        "topdeck_collector": args.topdeck_collector,
    }
    payload = build_report(
        non_floor_closure=read_json(args.non_floor_closure),
        named_frontier=read_json(args.named_frontier),
        topdeck_collector=read_json(args.topdeck_collector),
        nonanchor_model=read_json(args.nonanchor_model),
        mana_integrator=read_json(args.mana_integrator),
        current_best=read_json(args.current_best),
        staple_accessibility=read_json(args.staple_accessibility),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "selected_next_route": payload["summary"]["selected_next_route"],
                "json": rel(json_path),
                "markdown": rel(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
