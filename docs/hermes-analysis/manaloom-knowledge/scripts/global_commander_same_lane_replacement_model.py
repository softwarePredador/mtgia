#!/usr/bin/env python3
"""Model same-lane replacement routes after contextual usage blocks cuts.

This read-only gate consumes the contextual usage reviewer, stage-only cut
evidence plan, cut-source lane report, and synthesized package. It answers the
next practical question after a contextual card was used by the target deck:
is there a real same-lane replacement route, or must the deckbuilder find a
different cut source lane?
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_USAGE_REVIEWER_REPORT = (
    REPORT_DIR / "global_commander_contextual_usage_trace_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_STAGE_ONLY_CUT_EVIDENCE_PLAN = (
    REPORT_DIR / "global_commander_stage_only_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_CUT_SOURCE_LANE_REPORT = (
    REPORT_DIR / "global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PACKAGE_SYNTHESIS_REPORT = (
    REPORT_DIR / "global_commander_payoff_package_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_same_lane_replacement_model_20260705_kaalia_value_safe_stage1_repair_scope1"
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def unique_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    seen: set[str] = set()
    out: list[dict[str, Any]] = []
    for row in rows:
        key = normalize_name(str(row.get("card_name") or ""))
        if not key or key in seen:
            continue
        seen.add(key)
        out.append(row)
    return out


def stage_source_rows(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for row in payload.get("stage_only_cut_candidates") or []:
        if not isinstance(row, Mapping):
            continue
        key = normalize_name(str(row.get("card_name") or ""))
        if key:
            rows[key] = dict(row)
    return rows


def evidence_plan_rows(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for row in payload.get("evidence_plan_rows") or []:
        if not isinstance(row, Mapping):
            continue
        key = normalize_name(str(row.get("card_name") or ""))
        if key:
            rows[key] = dict(row)
    return rows


def usage_blocked_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in payload.get("review_rows") or []:
        if not isinstance(row, Mapping):
            continue
        if str(row.get("status") or "") != "usage_observed_blocks_value_safe_reclassification":
            continue
        rows.append(dict(row))
    rows.sort(key=lambda row: str(row.get("card_name") or ""))
    return rows


def package_add_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for key in ("selected_add_package", "unpaired_adds"):
        for row in payload.get(key) or []:
            if isinstance(row, Mapping) and row.get("card_name"):
                rows.append(dict(row))
    rows.sort(key=lambda row: (-int(row.get("score") or 0), str(row.get("card_name") or "")))
    return unique_rows(rows)


def cut_roles(stage_row: Mapping[str, Any], plan_row: Mapping[str, Any]) -> set[str]:
    roles = set(as_list(stage_row.get("matching_over_target_roles")))
    if not roles:
        roles = set(as_list(plan_row.get("matching_over_target_roles")))
    if not roles:
        roles = set(as_list(stage_row.get("profile_roles")))
    return roles


def add_profile_roles(add_row: Mapping[str, Any]) -> set[str]:
    return set(as_list(add_row.get("profile_roles")))


def add_explicit_covered_roles(add_row: Mapping[str, Any]) -> set[str]:
    roles = set(as_list(add_row.get("covered_axes")))
    selected_axis = str(add_row.get("selected_for_axis") or "")
    if selected_axis:
        roles.add(selected_axis)
    return roles


def replacement_route_for_cut(
    *,
    review_row: Mapping[str, Any],
    stage_row: Mapping[str, Any],
    plan_row: Mapping[str, Any],
    add_rows: list[dict[str, Any]],
) -> dict[str, Any]:
    roles = cut_roles(stage_row, plan_row)
    strong_routes = []
    incidental_overlaps = []
    for add in add_rows:
        profile_overlap = sorted(roles & add_profile_roles(add))
        explicit_overlap = sorted(roles & add_explicit_covered_roles(add))
        if explicit_overlap:
            strong_routes.append(
                {
                    "add_card": add.get("card_name"),
                    "status": "same_lane_replacement_route_needs_proof",
                    "overlap_roles": explicit_overlap,
                    "selected_for_axis": add.get("selected_for_axis"),
                    "covered_axes": as_list(add.get("covered_axes")),
                    "profile_roles": as_list(add.get("profile_roles")),
                    "score": add.get("score") or 0,
                }
            )
        elif profile_overlap:
            incidental_overlaps.append(
                {
                    "add_card": add.get("card_name"),
                    "status": "incidental_role_overlap_not_same_lane_proof",
                    "overlap_roles": profile_overlap,
                    "selected_for_axis": add.get("selected_for_axis"),
                    "covered_axes": as_list(add.get("covered_axes")),
                    "profile_roles": as_list(add.get("profile_roles")),
                    "score": add.get("score") or 0,
                }
            )
    if strong_routes:
        decision = "same_lane_replacement_route_found_but_unproven"
        required_next_evidence = [
            "source_lane_proves_replacement_covers_cut_function",
            "strategy_matrix_recheck_after_cut_replacement",
            "replay_or_battle_gate_with_added_and_cut_lane_exercised_before_promotion",
        ]
    else:
        decision = "blocked_no_same_lane_replacement_route"
        required_next_evidence = [
            "find_different_cut_source_lane",
            "expand_same_lane_replacement_pool_for_cut_role",
            "do_not_reclassify_used_contextual_card_as_value_safe",
        ]
    return {
        "cut_card": review_row.get("card_name"),
        "status": "usage_blocked_cut_requires_replacement_proof",
        "decision": decision,
        "cut_roles": sorted(roles),
        "stage_reasons": as_list(stage_row.get("stage_reasons")),
        "usage_event_count": int(review_row.get("usage_event_count") or 0),
        "decision_trace_count": int(review_row.get("decision_trace_count") or 0),
        "same_lane_replacement_routes": strong_routes,
        "incidental_role_overlaps": incidental_overlaps,
        "same_lane_replacement_proof_allowed_now": False,
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
        "required_next_evidence": required_next_evidence,
    }


def remaining_stage_only_rows(
    *,
    stage_rows: Mapping[str, dict[str, Any]],
    plan_rows: Mapping[str, dict[str, Any]],
    blocked_cut_keys: set[str],
) -> list[dict[str, Any]]:
    rows = []
    for key, stage_row in stage_rows.items():
        if key in blocked_cut_keys:
            continue
        plan_row = plan_rows.get(key, {})
        burden = int(plan_row.get("maximum_evidence_burden") or 7)
        reasons = as_list(stage_row.get("stage_reasons"))
        lanes = as_list(plan_row.get("evidence_lanes"))
        if "structural_staple_same_lane_or_equal_gate_proof" in lanes:
            route = "collect_structural_staple_same_lane_or_equal_gate_proof"
        elif "expected_package_anchor_replacement_proof" in lanes:
            route = "collect_expected_package_anchor_replacement_proof"
        elif "attack_window_same_lane_replacement_trace" in lanes:
            route = "collect_attack_window_same_lane_replacement_trace"
        elif "global_battle_feedback_reopen_proof" in lanes:
            route = "collect_new_global_battle_feedback_reopen_proof"
        else:
            route = "manual_new_cut_source_lane_review"
        rows.append(
            {
                "cut_card": stage_row.get("card_name"),
                "status": "remaining_stage_only_cut_source_requires_evidence",
                "cut_roles": sorted(cut_roles(stage_row, plan_row)),
                "stage_reasons": reasons,
                "evidence_lanes": lanes,
                "maximum_evidence_burden": burden,
                "score": stage_row.get("score") or 0,
                "recommended_next_route": route,
                "value_safe_reclassification_allowed": False,
                "candidate_copy_allowed": False,
            }
        )
    rows.sort(
        key=lambda row: (
            int(row["maximum_evidence_burden"]),
            -int(row.get("score") or 0),
            str(row.get("cut_card") or ""),
        )
    )
    return rows


def build_report(
    *,
    usage_reviewer_report: Path,
    stage_only_cut_evidence_plan: Path,
    cut_source_lane_report: Path,
    package_synthesis_report: Path,
) -> dict[str, Any]:
    usage_payload = load_json(usage_reviewer_report)
    plan_payload = load_json(stage_only_cut_evidence_plan)
    cut_payload = load_json(cut_source_lane_report)
    package_payload = load_json(package_synthesis_report)

    usage_summary = usage_payload.get("summary") or {}
    stage_rows = stage_source_rows(cut_payload)
    plan_rows = evidence_plan_rows(plan_payload)
    add_rows = package_add_rows(package_payload)
    blocked_usage = usage_blocked_rows(usage_payload)
    blocked_keys = {normalize_name(str(row.get("card_name") or "")) for row in blocked_usage}

    replacement_rows = [
        replacement_route_for_cut(
            review_row=row,
            stage_row=stage_rows.get(normalize_name(str(row.get("card_name") or "")), {}),
            plan_row=plan_rows.get(normalize_name(str(row.get("card_name") or "")), {}),
            add_rows=add_rows,
        )
        for row in blocked_usage
    ]
    remaining_rows = remaining_stage_only_rows(
        stage_rows=stage_rows,
        plan_rows=plan_rows,
        blocked_cut_keys=blocked_keys,
    )
    same_lane_route_count = sum(len(row["same_lane_replacement_routes"]) for row in replacement_rows)
    incidental_overlap_count = sum(len(row["incidental_role_overlaps"]) for row in replacement_rows)
    if same_lane_route_count:
        status = "same_lane_replacement_model_needs_proof_before_candidate_copy"
        next_gate = "collect_same_lane_replacement_proof_for_usage_blocked_contextual_cuts"
    elif remaining_rows:
        status = "same_lane_replacement_model_routes_to_new_cut_source_lane"
        next_gate = "collect_new_cut_source_lane_evidence_after_contextual_usage_block"
    else:
        status = "same_lane_replacement_model_blocks_no_cut_source_lane"
        next_gate = "expand_commander_cut_source_lane_beyond_current_stage_only_pool"

    blockers = []
    if blocked_usage:
        blockers.append(
            "contextual_usage_blocked_cuts:" + ",".join(str(row.get("card_name") or "") for row in blocked_usage)
        )
    if not same_lane_route_count and blocked_usage:
        blockers.append("no_explicit_same_lane_replacement_route_for_usage_blocked_contextual_cuts")
    blockers.append("value_safe_reclassification_still_closed")

    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_same_lane_replacement_model",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "same_lane_replacement_proof_allowed_now": False,
        "input_artifacts": {
            "usage_reviewer_report": rel(usage_reviewer_report),
            "stage_only_cut_evidence_plan": rel(stage_only_cut_evidence_plan),
            "cut_source_lane_report": rel(cut_source_lane_report),
            "package_synthesis_report": rel(package_synthesis_report),
        },
        "summary": {
            "deck_id": str(usage_summary.get("deck_id") or ""),
            "commander": str(usage_summary.get("commander") or ""),
            "usage_blocked_cut_count": len(blocked_usage),
            "same_lane_replacement_route_count": same_lane_route_count,
            "incidental_role_overlap_count": incidental_overlap_count,
            "remaining_stage_only_cut_source_count": len(remaining_rows),
            "package_add_count": len(add_rows),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "usage_blocked_replacement_rows": replacement_rows,
        "remaining_cut_source_lane_rows": remaining_rows,
        "policy": {
            "same_lane_boundary": "A card used by the target deck needs explicit same-lane replacement proof before reclassification.",
            "incidental_overlap_boundary": "An added payoff with incidental mana/card text is not same-lane proof unless it explicitly covers the cut lane.",
            "mutation_boundary": "This model does not copy decks, mutate DBs, run battles, reclassify cuts, or open promotion.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Same-Lane Replacement Model",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- usage_blocked_cut_count: `{summary['usage_blocked_cut_count']}`",
        f"- same_lane_replacement_route_count: `{summary['same_lane_replacement_route_count']}`",
        f"- incidental_role_overlap_count: `{summary['incidental_role_overlap_count']}`",
        f"- remaining_stage_only_cut_source_count: `{summary['remaining_stage_only_cut_source_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Usage-Blocked Cuts",
        "",
        "| Cut | Decision | Roles | Same-Lane Routes | Incidental Overlaps |",
        "| --- | --- | --- | ---: | ---: |",
    ]
    for row in payload["usage_blocked_replacement_rows"]:
        lines.append(
            "| `{cut}` | `{decision}` | `{roles}` | {routes} | {overlaps} |".format(
                cut=row.get("cut_card"),
                decision=row.get("decision"),
                roles=", ".join(row.get("cut_roles") or []),
                routes=len(row.get("same_lane_replacement_routes") or []),
                overlaps=len(row.get("incidental_role_overlaps") or []),
            )
        )
    if not payload["usage_blocked_replacement_rows"]:
        lines.append("| none | `-` | `-` | 0 | 0 |")
    lines.extend(
        [
            "",
            "## Remaining Cut Source Lane Rows",
            "",
            "| Burden | Cut | Roles | Route | Reasons |",
            "| ---: | --- | --- | --- | --- |",
        ]
    )
    for row in payload["remaining_cut_source_lane_rows"]:
        lines.append(
            "| {burden} | `{cut}` | `{roles}` | `{route}` | `{reasons}` |".format(
                burden=row.get("maximum_evidence_burden"),
                cut=row.get("cut_card"),
                roles=", ".join(row.get("cut_roles") or []),
                route=row.get("recommended_next_route"),
                reasons=", ".join(row.get("stage_reasons") or []),
            )
        )
    if not payload["remaining_cut_source_lane_rows"]:
        lines.append("| 0 | none | `-` | `-` | `-` |")
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
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
    parser.add_argument("--usage-reviewer-report", type=Path, default=DEFAULT_USAGE_REVIEWER_REPORT)
    parser.add_argument("--stage-only-cut-evidence-plan", type=Path, default=DEFAULT_STAGE_ONLY_CUT_EVIDENCE_PLAN)
    parser.add_argument("--cut-source-lane-report", type=Path, default=DEFAULT_CUT_SOURCE_LANE_REPORT)
    parser.add_argument("--package-synthesis-report", type=Path, default=DEFAULT_PACKAGE_SYNTHESIS_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        usage_reviewer_report=args.usage_reviewer_report,
        stage_only_cut_evidence_plan=args.stage_only_cut_evidence_plan,
        cut_source_lane_report=args.cut_source_lane_report,
        package_synthesis_report=args.package_synthesis_report,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "summary": payload["summary"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
