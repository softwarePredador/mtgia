#!/usr/bin/env python3
"""Route follow-up gates for ramp cut usage/same-lane blockers.

This read-only gate consumes
``global_commander_ramp_cut_usage_same_lane_proof_scout`` output and turns its
blockers into explicit next actions. It does not run battles, copy decks, mutate
databases, force traces, or promote packages.
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


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_SCOUT_REPORT = (
    REPORT_DIR / "global_commander_ramp_cut_usage_same_lane_proof_scout_20260706_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_ramp_cut_followup_router_20260706_current"


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


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def cut_followup_row(row: Mapping[str, Any]) -> dict[str, Any]:
    status = str(row.get("status") or "")
    card = str(row.get("card_name") or "")
    if status == "ramp_cut_usage_observed_blocks_candidate_copy":
        route_kind = "replacement_required"
        next_gate = "find_different_ramp_cut_or_explicit_same_lane_replacement_before_candidate_copy"
        reason = "current_scope_usage_observed"
        required_evidence = "different_cut_source_or_explicit_same_lane_replacement_proof"
    elif status == "ramp_cut_missing_current_scope_usage_trace":
        route_kind = "trace_required"
        next_gate = "generate_or_import_current_scope_usage_trace_for_ramp_cut_before_pair_review"
        reason = "missing_current_scope_usage_or_negative_trace"
        required_evidence = "current_scope_usage_or_negative_trace"
    elif status == "ramp_cut_seen_without_usage_needs_negative_review":
        route_kind = "negative_trace_review_required"
        next_gate = "manual_negative_trace_review_for_ramp_cut_before_pair_review"
        reason = "seen_without_usage_needs_manual_review"
        required_evidence = "manual_negative_trace_review"
    elif status == "ramp_cut_text_trace_candidate_needs_structured_review":
        route_kind = "structured_trace_review_required"
        next_gate = "review_text_trace_candidate_for_ramp_cut_before_pair_review"
        reason = "text_trace_candidate_not_structured_proof"
        required_evidence = "structured_trace_or_replay_reference"
    else:
        route_kind = "manual_review_required"
        next_gate = "manual_review_unclassified_ramp_cut_status"
        reason = "unclassified_cut_status"
        required_evidence = "manual_cut_status_review"
    return {
        "card_name": card,
        "deck_id": str(row.get("deck_id") or ""),
        "commander": str(row.get("commander") or ""),
        "cut_status": status,
        "trace_group": str(row.get("trace_group") or ""),
        "roles": as_list(row.get("roles")),
        "matching_excess_roles": as_list(row.get("matching_excess_roles")),
        "policy_bucket": row.get("policy_bucket"),
        "route_kind": route_kind,
        "reason": reason,
        "required_evidence": required_evidence,
        "next_gate": next_gate,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "promotion_allowed": False,
        "mutation_allowed": False,
    }


def build_cut_followups(scout_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [
        cut_followup_row(row)
        for row in scout_payload.get("cut_evidence_rows") or []
        if isinstance(row, Mapping)
    ]
    rows.sort(key=lambda row: (str(row.get("route_kind") or ""), str(row.get("card_name") or "")))
    return rows


def build_pair_followups(
    scout_payload: Mapping[str, Any],
    cut_followups: list[Mapping[str, Any]],
) -> list[dict[str, Any]]:
    by_cut = {str(row.get("card_name") or ""): row for row in cut_followups}
    rows: list[dict[str, Any]] = []
    for pair in scout_payload.get("pair_review_rows") or []:
        if not isinstance(pair, Mapping):
            continue
        cut_name = str(pair.get("cut") or "")
        followup = by_cut.get(cut_name, {})
        pair_blockers = as_list(pair.get("blockers"))
        no_same_lane = "no_explicit_same_lane_replacement_route" in pair_blockers
        if no_same_lane:
            pair_next_gate = "find_explicit_same_lane_replacement_route_for_pair_before_candidate_copy"
        else:
            pair_next_gate = str(followup.get("next_gate") or "manual_pair_review_before_candidate_copy")
        rows.append(
            {
                "add": pair.get("add"),
                "cut": cut_name,
                "pair_status": pair.get("status"),
                "candidate_role": pair.get("candidate_role"),
                "cut_roles": as_list(pair.get("cut_roles")),
                "explicit_same_lane_roles": as_list(pair.get("explicit_same_lane_roles")),
                "blockers": pair_blockers,
                "cut_route_kind": followup.get("route_kind"),
                "cut_next_gate": followup.get("next_gate"),
                "pair_next_gate": pair_next_gate,
                "candidate_copy_allowed": False,
                "battle_gate_allowed": False,
                "promotion_allowed": False,
                "mutation_allowed": False,
            }
        )
    rows.sort(key=lambda row: (str(row.get("cut") or ""), str(row.get("add") or "")))
    return rows


def build_trace_plan_rows(cut_followups: list[Mapping[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in cut_followups:
        if row.get("route_kind") != "trace_required":
            continue
        rows.append(
            {
                "card_name": row.get("card_name"),
                "deck_id": row.get("deck_id"),
                "commander": row.get("commander"),
                "required_trace": "current_scope_usage_or_negative_trace",
                "primary_route": "generate_or_import_current_scope_usage_trace_for_ramp_cut",
                "fallback_route": "force_access_trace_only_after_current_scope_trace_gap_is_confirmed",
                "candidate_copy_allowed": False,
                "battle_gate_allowed": False,
                "mutation_allowed": False,
            }
        )
    return rows


def build_structured_review_rows(cut_followups: list[Mapping[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in cut_followups:
        if row.get("route_kind") != "structured_trace_review_required":
            continue
        rows.append(
            {
                "card_name": row.get("card_name"),
                "deck_id": row.get("deck_id"),
                "commander": row.get("commander"),
                "required_review": "structured_trace_or_replay_reference_review",
                "primary_route": "review_text_trace_candidate_for_ramp_cut",
                "fallback_route": "generate_current_scope_trace_if_text_reference_is_not_structured_proof",
                "candidate_copy_allowed": False,
                "battle_gate_allowed": False,
                "mutation_allowed": False,
            }
        )
    return rows


def build_replacement_search_rows(cut_followups: list[Mapping[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in cut_followups:
        if row.get("route_kind") != "replacement_required":
            continue
        rows.append(
            {
                "card_name": row.get("card_name"),
                "deck_id": row.get("deck_id"),
                "commander": row.get("commander"),
                "blocked_reason": row.get("reason"),
                "required_replacement_roles": as_list(row.get("roles")),
                "allowed_recovery_routes": [
                    "find_different_ramp_cut_with_current_scope_negative_evidence",
                    "prove_explicit_same_lane_replacement_before_candidate_copy",
                ],
                "blocked_recovery_routes": [
                    "cross_lane_removal_add_for_ramp_cut_without_same_lane_route",
                    "candidate_copy_from_usage_observed_cut",
                ],
                "candidate_copy_allowed": False,
                "battle_gate_allowed": False,
                "mutation_allowed": False,
            }
        )
    return rows


def choose_status_and_gate(
    *,
    pair_ready_count: int,
    trace_plan_rows: list[Mapping[str, Any]],
    replacement_rows: list[Mapping[str, Any]],
    structured_review_rows: list[Mapping[str, Any]],
) -> tuple[str, str]:
    if pair_ready_count:
        return (
            "ramp_cut_followup_router_ready_for_manual_pair_review",
            "manual_review_ramp_cut_pair_before_candidate_copy",
        )
    has_trace = bool(trace_plan_rows)
    has_replacement = bool(replacement_rows)
    has_structured = bool(structured_review_rows)
    if has_trace and has_replacement and has_structured:
        return (
            "ramp_cut_followup_router_blocks_candidate_copy",
            "run_trace_plan_structured_review_and_replacement_search_before_candidate_copy",
        )
    if has_trace and has_replacement:
        return (
            "ramp_cut_followup_router_blocks_candidate_copy",
            "run_trace_plan_and_replacement_search_before_candidate_copy",
        )
    if has_trace and has_structured:
        return (
            "ramp_cut_followup_router_blocks_candidate_copy",
            "run_trace_plan_and_structured_review_before_candidate_copy",
        )
    if has_replacement and has_structured:
        return (
            "ramp_cut_followup_router_blocks_candidate_copy",
            "run_structured_review_and_replacement_search_before_candidate_copy",
        )
    if has_trace:
        return ("ramp_cut_followup_router_blocks_candidate_copy", "run_current_scope_trace_plan_before_candidate_copy")
    if has_replacement:
        return (
            "ramp_cut_followup_router_blocks_candidate_copy",
            "find_different_ramp_cut_or_same_lane_replacement_before_candidate_copy",
        )
    if has_structured:
        return (
            "ramp_cut_followup_router_blocks_candidate_copy",
            "review_structured_ramp_trace_candidates_before_candidate_copy",
        )
    return ("ramp_cut_followup_router_needs_manual_review", "manual_review_ramp_cut_followup_router")


def build_report(*, scout_report: Path) -> dict[str, Any]:
    scout_payload = load_json(scout_report)
    cut_followups = build_cut_followups(scout_payload)
    pair_followups = build_pair_followups(scout_payload, cut_followups)
    trace_plan_rows = build_trace_plan_rows(cut_followups)
    structured_review_rows = build_structured_review_rows(cut_followups)
    replacement_rows = build_replacement_search_rows(cut_followups)
    route_counts = Counter(str(row.get("route_kind") or "") for row in cut_followups)
    pair_ready_count = sum(
        1
        for row in pair_followups
        if row.get("pair_status") == "ramp_cut_pair_ready_for_manual_candidate_copy_review"
    )
    no_same_lane_pair_count = sum(
        1
        for row in pair_followups
        if "no_explicit_same_lane_replacement_route" in as_list(row.get("blockers"))
    )
    status, next_gate = choose_status_and_gate(
        pair_ready_count=pair_ready_count,
        trace_plan_rows=trace_plan_rows,
        replacement_rows=replacement_rows,
        structured_review_rows=structured_review_rows,
    )
    blockers: list[str] = []
    blockers.extend(str(item) for item in scout_payload.get("candidate_copy_blockers") or [])
    if trace_plan_rows:
        blockers.append("trace_required_for_ramp_cuts:" + ",".join(str(row.get("card_name") or "") for row in trace_plan_rows))
    if structured_review_rows:
        blockers.append(
            "structured_trace_review_required_for_ramp_cuts:"
            + ",".join(str(row.get("card_name") or "") for row in structured_review_rows)
        )
    if replacement_rows:
        blockers.append(
            "replacement_required_for_used_ramp_cuts:"
            + ",".join(str(row.get("card_name") or "") for row in replacement_rows)
        )
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_ramp_cut_followup_router",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_run_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "scout_report": artifact_rel(scout_report),
            "scout_status": scout_payload.get("status"),
        },
        "summary": {
            "cut_count": len(cut_followups),
            "usage_blocked_cut_count": route_counts.get("replacement_required", 0),
            "missing_trace_cut_count": route_counts.get("trace_required", 0),
            "structured_trace_review_required_count": route_counts.get("structured_trace_review_required", 0),
            "negative_trace_review_required_count": route_counts.get("negative_trace_review_required", 0),
            "replacement_required_count": len(replacement_rows),
            "trace_plan_count": len(trace_plan_rows),
            "structured_review_count": len(structured_review_rows),
            "pair_count": len(pair_followups),
            "pair_ready_count": pair_ready_count,
            "pair_blocked_count": len(pair_followups) - pair_ready_count,
            "no_explicit_same_lane_pair_count": no_same_lane_pair_count,
            "route_kind_counts": dict(sorted(route_counts.items())),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "cut_followup_rows": cut_followups,
        "pair_followup_rows": pair_followups,
        "trace_plan_rows": trace_plan_rows,
        "structured_review_rows": structured_review_rows,
        "replacement_search_rows": replacement_rows,
        "candidate_copy_blockers": blockers,
        "policy": {
            "usage_boundary": "A cut with current-scope target usage routes to a different cut or explicit same-lane replacement proof.",
            "trace_boundary": "A cut without current-scope usage or negative trace routes to trace generation/import before pair review.",
            "structured_trace_boundary": "A text trace candidate is scout evidence only until reviewed as structured proof.",
            "same_lane_boundary": "Cross-lane removal additions cannot replace ramp cuts without explicit same-lane route evidence.",
            "mutation_boundary": "This router does not copy decks, run battles, mutate DBs, force traces, or promote packages.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Ramp Cut Follow-Up Router",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- cut_count: `{summary['cut_count']}`",
        f"- usage_blocked_cut_count: `{summary['usage_blocked_cut_count']}`",
        f"- missing_trace_cut_count: `{summary['missing_trace_cut_count']}`",
        f"- structured_trace_review_required_count: `{summary['structured_trace_review_required_count']}`",
        f"- replacement_required_count: `{summary['replacement_required_count']}`",
        f"- trace_plan_count: `{summary['trace_plan_count']}`",
        f"- structured_review_count: `{summary['structured_review_count']}`",
        f"- pair_count: `{summary['pair_count']}`",
        f"- pair_ready_count: `{summary['pair_ready_count']}`",
        f"- no_explicit_same_lane_pair_count: `{summary['no_explicit_same_lane_pair_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_run_performed: `{str(payload['battle_run_performed']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Cut Follow-Ups",
        "",
        "| Cut | Route | Required Evidence | Next Gate |",
        "| --- | --- | --- | --- |",
    ]
    for row in payload["cut_followup_rows"]:
        lines.append(
            "| `{card}` | `{route}` | `{evidence}` | `{next}` |".format(
                card=row.get("card_name"),
                route=row.get("route_kind"),
                evidence=row.get("required_evidence"),
                next=row.get("next_gate"),
            )
        )
    if not payload["cut_followup_rows"]:
        lines.append("| none |  |  |  |")
    lines.extend(["", "## Pair Follow-Ups", ""])
    lines.extend(["| Pair | Pair Gate | Cut Gate | Blockers |", "| --- | --- | --- | --- |"])
    for row in payload["pair_followup_rows"]:
        lines.append(
            "| `+{add} / -{cut}` | `{pair_gate}` | `{cut_gate}` | {blockers} |".format(
                add=row.get("add"),
                cut=row.get("cut"),
                pair_gate=row.get("pair_next_gate"),
                cut_gate=row.get("cut_next_gate"),
                blockers=", ".join(row.get("blockers") or []) or "-",
            )
        )
    if not payload["pair_followup_rows"]:
        lines.append("| none |  |  |  |")
    lines.extend(["", "## Trace Plan", ""])
    if payload["trace_plan_rows"]:
        for row in payload["trace_plan_rows"]:
            lines.append(f"- `{row['card_name']}`: `{row['primary_route']}`; fallback `{row['fallback_route']}`")
    else:
        lines.append("- none")
    lines.extend(["", "## Structured Review", ""])
    if payload["structured_review_rows"]:
        for row in payload["structured_review_rows"]:
            lines.append(f"- `{row['card_name']}`: `{row['primary_route']}`; fallback `{row['fallback_route']}`")
    else:
        lines.append("- none")
    lines.extend(["", "## Replacement Search", ""])
    if payload["replacement_search_rows"]:
        for row in payload["replacement_search_rows"]:
            roles = ",".join(row.get("required_replacement_roles") or [])
            lines.append(f"- `{row['card_name']}`: same-lane roles required `{roles}`")
    else:
        lines.append("- none")
    lines.extend(["", "## Blockers", ""])
    if payload["candidate_copy_blockers"]:
        for blocker in payload["candidate_copy_blockers"]:
            lines.append(f"- `{blocker}`")
    else:
        lines.append("- none")
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
    parser.add_argument("--scout-report", type=Path, default=DEFAULT_SCOUT_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(scout_report=args.scout_report)
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
