#!/usr/bin/env python3
"""Route recovery after same-lane stage cuts are used in trace.

This read-only gate consumes the same-lane stage-cut trace collector and the
same-lane source package. A used cut cannot become value-safe from the current
trace; this router decides whether it needs explicit same-lane replacement
proof or a fresh cut-source lane. It does not mutate decks, run battle,
materialize candidates, reclassify cuts, or promote anything.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_TRACE_COLLECTOR_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_stage_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PACKAGE_SOURCE_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_package_source_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_same_lane_used_cut_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1"
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


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def selected_adds_by_role(package_payload: Mapping[str, Any]) -> dict[str, list[dict[str, Any]]]:
    by_role: dict[str, list[dict[str, Any]]] = {}
    for row in package_payload.get("selected_add_package") or []:
        if not isinstance(row, Mapping) or not row.get("card_name"):
            continue
        role = str(row.get("replaces_cut_role") or "")
        if not role:
            continue
        by_role.setdefault(role, []).append(dict(row))
    for role in by_role:
        by_role[role].sort(key=lambda row: (-as_int(row.get("score")), str(row.get("card_name") or "")))
    return by_role


def review_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [
        dict(row)
        for row in payload.get("review_rows") or []
        if isinstance(row, Mapping) and row.get("card_name")
    ]


def used_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [
        row
        for row in review_rows(payload)
        if row.get("status") == "same_lane_stage_cut_usage_trace_blocks_value_safe"
    ]
    rows.sort(key=lambda row: (-as_int(row.get("usage_event_count")), str(row.get("card_name") or "")))
    return rows


def selected_add_routes_for_cut(
    *,
    cut_row: Mapping[str, Any],
    adds_by_role: Mapping[str, list[dict[str, Any]]],
) -> list[dict[str, Any]]:
    role = str(cut_row.get("target_cut_role") or "")
    routes = []
    cut_key = normalize_name(str(cut_row.get("card_name") or ""))
    for add in adds_by_role.get(role) or []:
        add_key = normalize_name(str(add.get("card_name") or ""))
        if add_key == cut_key:
            continue
        routes.append(
            {
                "add_card": add.get("card_name"),
                "add_axis": add.get("selected_for_axis"),
                "same_lane_role": role,
                "add_score": as_int(add.get("score")),
                "status": "explicit_same_lane_add_route_requires_replacement_proof",
                "required_proof": [
                    "prove_added_card_replaces_used_cut_function",
                    "rerun_strategy_matrix_after_any_candidate_copy",
                    "equal_gate_with_relevant_card_usage_before_promotion",
                ],
            }
        )
    return routes


def route_for_used_cut(
    *,
    cut_row: Mapping[str, Any],
    adds_by_role: Mapping[str, list[dict[str, Any]]],
) -> dict[str, Any]:
    routes = selected_add_routes_for_cut(cut_row=cut_row, adds_by_role=adds_by_role)
    evidence_lanes = as_list(cut_row.get("evidence_lanes"))
    stage_reasons = as_list(cut_row.get("stage_reasons"))
    structural_or_anchor = any(
        reason in stage_reasons
        for reason in (
            "structural_foundation_staple_requires_same_lane_or_battle_proof",
            "commander_expected_package_anchor_requires_stage_proof",
            "global_battle_feedback_requires_new_same_lane_or_gate",
        )
    )
    if routes and structural_or_anchor:
        decision = "used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source"
        next_evidence = "prefer_new_cut_source_unless_replacement_proof_is_explicit"
    elif routes:
        decision = "used_cut_has_same_lane_add_route_but_not_value_safe"
        next_evidence = "collect_explicit_replacement_proof_or_equal_gate"
    else:
        decision = "used_cut_has_no_same_lane_add_route"
        next_evidence = "find_new_same_lane_cut_source_or_broaden_axis"
    return {
        "cut_card": cut_row.get("card_name"),
        "target_cut_role": cut_row.get("target_cut_role"),
        "decision": decision,
        "usage_event_count": as_int(cut_row.get("usage_event_count")),
        "exposure_event_count": as_int(cut_row.get("exposure_event_count")),
        "decision_trace_count": as_int(cut_row.get("decision_trace_count")),
        "stage_reasons": stage_reasons,
        "evidence_lanes": evidence_lanes,
        "same_lane_add_routes": routes,
        "route_count": len(routes),
        "next_evidence": next_evidence,
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
    }


def count_by(rows: list[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        counts[str(row.get(field) or "unknown")] += 1
    return dict(counts)


def choose_status_and_next_gate(rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    if not rows:
        return (
            "same_lane_used_cut_recovery_blocks_no_used_cuts",
            "review_seen_or_external_stage_cuts_before_recovery",
        )
    strict = [
        row
        for row in rows
        if row.get("decision") == "used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source"
    ]
    missing = [row for row in rows if row.get("decision") == "used_cut_has_no_same_lane_add_route"]
    if strict or missing:
        return (
            "same_lane_used_cut_recovery_routes_to_new_cut_source",
            "mine_or_research_new_same_lane_cut_source_before_candidate_copy",
        )
    return (
        "same_lane_used_cut_recovery_needs_replacement_proof",
        "collect_explicit_same_lane_replacement_proof_for_used_cuts",
    )


def build_report(*, trace_collector_report: Path, package_source_report: Path) -> dict[str, Any]:
    trace_payload = load_json(trace_collector_report)
    package_payload = load_json(package_source_report)
    trace_summary = trace_payload.get("summary") or {}
    package_summary = package_payload.get("summary") or {}
    adds_by_role = selected_adds_by_role(package_payload)
    rows = [route_for_used_cut(cut_row=row, adds_by_role=adds_by_role) for row in used_rows(trace_payload)]
    status, next_gate = choose_status_and_next_gate(rows)
    strict_count = sum(
        1
        for row in rows
        if row["decision"] == "used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source"
    )
    no_route_count = sum(1 for row in rows if row["decision"] == "used_cut_has_no_same_lane_add_route")
    proof_count = sum(1 for row in rows if row["decision"] == "used_cut_has_same_lane_add_route_but_not_value_safe")
    blockers = [
        "used_stage_cuts_are_not_value_safe_from_current_trace",
        "candidate_copy_closed_until_new_cut_source_or_explicit_replacement_proof",
    ]
    if strict_count:
        blockers.append(f"used_structural_or_anchor_cuts_need_strict_recovery:{strict_count}")
    if no_route_count:
        blockers.append(f"used_cuts_without_same_lane_add_route:{no_route_count}")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_same_lane_used_cut_recovery_router",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "battle_replay_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "input_artifacts": {
            "trace_collector_report": rel(trace_collector_report),
            "package_source_report": rel(package_source_report),
        },
        "summary": {
            "deck_id": str(trace_summary.get("deck_id") or package_summary.get("deck_id") or ""),
            "commander": str(trace_summary.get("commander") or package_summary.get("commander") or ""),
            "used_cut_count": len(rows),
            "strict_recovery_count": strict_count,
            "same_lane_replacement_proof_count": proof_count,
            "no_same_lane_route_count": no_route_count,
            "decision_counts": count_by(rows, "decision"),
            "target_role_counts": count_by(rows, "target_cut_role"),
            "selected_add_count": as_int(package_summary.get("selected_add_count")),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "used_cut_recovery_rows": rows,
        "policy": {
            "usage_boundary": "A used cut is not value-safe unless later proof replaces its function or finds a different cut.",
            "structural_boundary": "Structural staples, expected anchors, and prior failed-gate cuts should prefer new cut-source lanes unless replacement proof is explicit.",
            "candidate_copy_boundary": "This router never opens candidate copy or battle.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Same-Lane Used Cut Recovery Router",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- used_cut_count: `{summary['used_cut_count']}`",
        f"- strict_recovery_count: `{summary['strict_recovery_count']}`",
        f"- same_lane_replacement_proof_count: `{summary['same_lane_replacement_proof_count']}`",
        f"- no_same_lane_route_count: `{summary['no_same_lane_route_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Used Cut Recovery Rows",
        "",
        "| Cut | Role | Usage | Routes | Decision | Next Evidence |",
        "| --- | --- | ---: | ---: | --- | --- |",
    ]
    for row in payload["used_cut_recovery_rows"]:
        lines.append(
            "| `{cut}` | `{role}` | {usage} | {routes} | `{decision}` | `{next}` |".format(
                cut=row.get("cut_card"),
                role=row.get("target_cut_role"),
                usage=row.get("usage_event_count"),
                routes=row.get("route_count"),
                decision=row.get("decision"),
                next=row.get("next_evidence"),
            )
        )
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
    parser.add_argument("--trace-collector-report", type=Path, default=DEFAULT_TRACE_COLLECTOR_REPORT)
    parser.add_argument("--package-source-report", type=Path, default=DEFAULT_PACKAGE_SOURCE_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        trace_collector_report=args.trace_collector_report,
        package_source_report=args.package_source_report,
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
