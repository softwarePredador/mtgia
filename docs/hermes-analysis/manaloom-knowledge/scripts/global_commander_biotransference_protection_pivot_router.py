#!/usr/bin/env python3
"""Protect Biotransference and route the engine axis after source exhaustion.

This read-only gate follows
``global_commander_exact_artifact_type_conversion_source_lane_expander``. It
turns the source-lane conclusion into an explicit routing decision: protect
Biotransference when no outside-deck artifact type converter exists, recheck
whether any non-Biotransference engine cut is still viable, and otherwise pivot
back to the global role-axis learning queue. It does not mutate decks, run
battles, or promote packages.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT, rel
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_TYPE_CONVERSION_REPORT = (
    REPORT_DIR / "global_commander_exact_artifact_type_conversion_source_lane_expander_20260706_current.json"
)
DEFAULT_ENGINE_POLICY_REPORT = (
    REPORT_DIR / "global_commander_engine_axis_nonland_cut_policy_model_20260706_current.json"
)
DEFAULT_TRACE_REVIEWER_REPORT = (
    REPORT_DIR / "global_commander_engine_cut_trace_replacement_reviewer_20260706_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_biotransference_protection_pivot_router_20260706_current"
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def artifact_rel(path: Path) -> str:
    candidate = path if path.is_absolute() else REPO_ROOT / path
    try:
        return rel(candidate)
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def first_pool_policy(engine_policy_payload: Mapping[str, Any]) -> Mapping[str, Any]:
    for row in engine_policy_payload.get("pool_policy_rows") or []:
        if isinstance(row, Mapping):
            return row
    return {}


def type_conversion_exhausted(type_payload: Mapping[str, Any]) -> bool:
    summary = type_payload.get("summary") or {}
    if int(summary.get("ready_type_conversion_candidate_count") or 0) != 0:
        return False
    for row in type_payload.get("source_candidate_rows") or []:
        if not isinstance(row, Mapping):
            continue
        if normalize_name(str(row.get("card_name") or "")) == "biotransference" and row.get(
            "already_in_current_deck"
        ):
            return True
    return False


def trace_review_by_card(trace_payload: Mapping[str, Any]) -> dict[str, Mapping[str, Any]]:
    rows = {}
    for row in trace_payload.get("trace_review_rows") or []:
        if isinstance(row, Mapping):
            rows[normalize_name(str(row.get("card_name") or ""))] = row
    return rows


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def route_engine_cut(
    row: Mapping[str, Any],
    *,
    conversion_exhausted: bool,
    trace_rows: Mapping[str, Mapping[str, Any]],
) -> dict[str, Any]:
    card_name = str(row.get("card_name") or "")
    key = normalize_name(card_name)
    roles = as_list(row.get("roles"))
    policy_status = str(row.get("policy_status") or row.get("status") or "")
    blockers = []
    route = "blocked"
    next_gate = "none"
    if "engine" not in roles:
        status = "non_engine_cut_outside_biotransference_protection_router"
        blockers.append("cut_does_not_carry_engine_role")
    elif key == "biotransference":
        if conversion_exhausted:
            status = "biotransference_protected_no_outside_type_conversion_replacement"
            route = "protect_cut"
            blockers.extend(
                [
                    "no_outside_artifact_type_conversion_candidate",
                    "biotransference_is_current_deck_artifact_type_converter",
                ]
            )
            next_gate = "exclude_biotransference_from_candidate_copy"
        else:
            status = "biotransference_requires_type_conversion_source_review"
            blockers.append("type_conversion_source_lane_not_exhausted")
            next_gate = "complete_artifact_type_conversion_source_lane_review"
    elif key in trace_rows:
        trace = trace_rows[key]
        review_status = str(trace.get("review_status") or "")
        if review_status.startswith("trace_review_blocks_negative_clearance"):
            status = "non_biotransference_engine_cut_blocked_by_trace_review"
            blockers.append(review_status)
            if trace.get("reason"):
                blockers.append(str(trace.get("reason")))
            next_gate = "do_not_cut_without_new_same_lane_or_trace_evidence"
        else:
            status = "non_biotransference_engine_cut_needs_pair_model"
            route = "candidate_cut_review"
            next_gate = "model_non_biotransference_engine_cut_pairs_before_candidate_copy"
    elif policy_status == "engine_axis_policy_review_cut_pressure_ready":
        status = "non_biotransference_engine_cut_needs_trace_review"
        blockers.append("missing_current_scope_trace_review_for_non_biotransference_engine_cut")
        next_gate = "generate_or_import_current_scope_usage_trace_for_engine_cut_before_pair_review"
    elif policy_status == "engine_axis_policy_blocks_cut_until_source_lane_review":
        status = "engine_cut_protected_by_commander_plan_signal"
        blockers.extend(as_list(row.get("policy_blockers")) or ["commander_plan_signal_protects_engine_cut"])
        next_gate = "keep_commander_plan_engine_protected"
    else:
        status = "engine_cut_not_available_for_biotransference_pivot"
        blockers.append(policy_status or "unknown_policy_status")
    return {
        "card_name": card_name,
        "status": status,
        "route": route,
        "roles": roles,
        "policy_status": policy_status,
        "policy_bucket": row.get("policy_bucket"),
        "commander_plan_signals": as_list(row.get("commander_plan_signals")),
        "blockers": blockers,
        "next_gate": next_gate,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "promotion_allowed": False,
    }


def build_report(
    *,
    type_conversion_report: Path = DEFAULT_TYPE_CONVERSION_REPORT,
    engine_policy_report: Path = DEFAULT_ENGINE_POLICY_REPORT,
    trace_reviewer_report: Path = DEFAULT_TRACE_REVIEWER_REPORT,
) -> dict[str, Any]:
    type_payload = load_json(type_conversion_report)
    engine_payload = load_json(engine_policy_report)
    trace_payload = load_json(trace_reviewer_report)
    pool = first_pool_policy(engine_payload)
    conversion_exhausted = type_conversion_exhausted(type_payload)
    trace_rows = trace_review_by_card(trace_payload)
    cut_rows = [
        route_engine_cut(row, conversion_exhausted=conversion_exhausted, trace_rows=trace_rows)
        for row in pool.get("policy_cut_rows") or []
        if isinstance(row, Mapping) and "engine" in as_list(row.get("roles"))
    ]
    viable_rows = [row for row in cut_rows if row["route"] == "candidate_cut_review"]
    protected_bio = any(row["status"] == "biotransference_protected_no_outside_type_conversion_replacement" for row in cut_rows)
    status_counts = Counter(row["status"] for row in cut_rows)
    blocker_counts = Counter(blocker for row in cut_rows for blocker in row.get("blockers") or [])
    if protected_bio and not viable_rows:
        status = "biotransference_protected_engine_axis_exhausted_pivot_required"
        next_gate = "return_to_global_role_axis_learning_priority_after_engine_axis_exhaustion"
    elif viable_rows:
        status = "biotransference_protected_non_biotransference_engine_cut_review_available"
        next_gate = "model_non_biotransference_engine_cut_pairs_before_candidate_copy"
    else:
        status = "biotransference_protection_router_blocks_candidate_copy"
        next_gate = "complete_missing_engine_axis_evidence_before_candidate_copy"
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_biotransference_protection_pivot_router",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_rows_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "type_conversion_report": artifact_rel(type_conversion_report),
            "engine_policy_report": artifact_rel(engine_policy_report),
            "trace_reviewer_report": artifact_rel(trace_reviewer_report),
        },
        "summary": {
            "deck_id": str(pool.get("deck_id") or ""),
            "commander": str(pool.get("commander") or ""),
            "type_conversion_lane_exhausted": conversion_exhausted,
            "engine_cut_row_count": len(cut_rows),
            "biotransference_protected": protected_bio,
            "viable_non_biotransference_engine_cut_count": len(viable_rows),
            "status_counts": dict(sorted(status_counts.items())),
            "blocker_counts": dict(sorted(blocker_counts.items())),
            "next_gate": next_gate,
        },
        "engine_cut_route_rows": cut_rows,
        "policy": {
            "biotransference_boundary": "Biotransference stays protected when it is the only exact artifact type-conversion source.",
            "non_biotransference_boundary": "Other engine cuts still need trace and same-lane proof before pair modeling.",
            "pivot_boundary": "When no engine cut remains viable, return to global role-axis learning instead of forcing same-deck source expansion.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Biotransference Protection Pivot Router",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- type_conversion_lane_exhausted: `{str(summary['type_conversion_lane_exhausted']).lower()}`",
        f"- biotransference_protected: `{str(summary['biotransference_protected']).lower()}`",
        f"- viable_non_biotransference_engine_cut_count: `{summary['viable_non_biotransference_engine_cut_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Engine Cut Routes",
        "",
        "| Card | Status | Route | Policy Bucket | Next Gate | Blockers |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for row in payload["engine_cut_route_rows"]:
        lines.append(
            "| `{card}` | `{status}` | `{route}` | `{bucket}` | `{next_gate}` | {blockers} |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                route=row.get("route"),
                bucket=row.get("policy_bucket") or "",
                next_gate=row.get("next_gate"),
                blockers=", ".join(row.get("blockers") or []) or "-",
            )
        )
    if not payload["engine_cut_route_rows"]:
        lines.append("| none |  |  |  |  |  |")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--type-conversion-report", type=Path, default=DEFAULT_TYPE_CONVERSION_REPORT)
    parser.add_argument("--engine-policy-report", type=Path, default=DEFAULT_ENGINE_POLICY_REPORT)
    parser.add_argument("--trace-reviewer-report", type=Path, default=DEFAULT_TRACE_REVIEWER_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        type_conversion_report=args.type_conversion_report,
        engine_policy_report=args.engine_policy_report,
        trace_reviewer_report=args.trace_reviewer_report,
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
