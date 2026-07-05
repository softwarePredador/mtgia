#!/usr/bin/env python3
"""Model same-lane proof for freshly mined Commander cut hypotheses.

This read-only gate consumes the fresh cut-source hypothesis trace report and
the synthesized package that still needs cuts. It answers whether any used or
seen hypothesis has an explicit same-lane replacement route in the current add
package, without reclassifying cuts, copying decks, running battle, or promoting
anything.
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
DEFAULT_TRACE_COLLECTOR_REPORT = (
    REPORT_DIR / "global_commander_cut_source_hypothesis_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_MINER_REPORT = (
    REPORT_DIR / "global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PACKAGE_SYNTHESIS_REPORT = (
    REPORT_DIR / "global_commander_payoff_package_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_cut_hypothesis_same_lane_proof_20260705_kaalia_value_safe_stage1_repair_scope1"
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


def source_rows_by_card(miner_payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for row in miner_payload.get("fresh_cut_source_hypotheses") or []:
        if not isinstance(row, Mapping):
            continue
        key = normalize_name(str(row.get("card_name") or ""))
        if key:
            rows[key] = dict(row)
    return rows


def hypothesis_trace_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in payload.get("review_rows") or []:
        if not isinstance(row, Mapping):
            continue
        if row.get("cut_card"):
            rows.append(dict(row))
    rows.sort(key=lambda row: str(row.get("cut_card") or ""))
    return rows


def package_add_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for key in ("selected_add_package", "unpaired_adds"):
        for row in payload.get(key) or []:
            if isinstance(row, Mapping) and row.get("card_name"):
                rows.append(dict(row))
    rows.sort(key=lambda row: (-int(row.get("score") or 0), str(row.get("card_name") or "")))
    return unique_rows(rows)


def hypothesis_roles(trace_row: Mapping[str, Any], source_row: Mapping[str, Any]) -> set[str]:
    roles = set(as_list(trace_row.get("matching_over_target_roles")))
    roles.update(as_list(source_row.get("matching_over_target_roles")))
    roles.update(as_list(trace_row.get("profile_roles")))
    roles.update(as_list(source_row.get("profile_roles")))
    return roles


def add_profile_roles(add_row: Mapping[str, Any]) -> set[str]:
    return set(as_list(add_row.get("profile_roles")))


def add_explicit_covered_roles(add_row: Mapping[str, Any]) -> set[str]:
    roles = set(as_list(add_row.get("covered_axes")))
    selected_axis = str(add_row.get("selected_for_axis") or "")
    if selected_axis:
        roles.add(selected_axis)
    return roles


def trace_group(row: Mapping[str, Any]) -> str:
    status = str(row.get("status") or "")
    usage = int(row.get("usage_event_count") or 0)
    exposure = int(row.get("exposure_event_count") or 0)
    decisions = int(row.get("decision_trace_count") or 0)
    if usage > 0 or "used_by_target" in status:
        return "usage_blocked"
    if exposure > 0 or decisions > 0 or "seen_without_usage" in status:
        return "seen_without_usage"
    return "not_seen"


def proof_row_for_hypothesis(
    *,
    trace_row: Mapping[str, Any],
    source_row: Mapping[str, Any],
    add_rows: list[dict[str, Any]],
) -> dict[str, Any]:
    roles = hypothesis_roles(trace_row, source_row)
    strong_routes = []
    incidental_overlaps = []
    for add in add_rows:
        explicit_overlap = sorted(roles & add_explicit_covered_roles(add))
        profile_overlap = sorted(roles & add_profile_roles(add))
        if explicit_overlap:
            strong_routes.append(
                {
                    "add_card": add.get("card_name"),
                    "status": "explicit_same_lane_route_requires_proof",
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
                    "status": "incidental_hypothesis_role_overlap_not_same_lane_proof",
                    "overlap_roles": profile_overlap,
                    "selected_for_axis": add.get("selected_for_axis"),
                    "covered_axes": as_list(add.get("covered_axes")),
                    "profile_roles": as_list(add.get("profile_roles")),
                    "score": add.get("score") or 0,
                }
            )

    group = trace_group(trace_row)
    if strong_routes:
        decision = "explicit_same_lane_route_found_but_proof_still_required"
        required_next_evidence = [
            "prove_replacement_covers_the_cut_function_not_only_profile_overlap",
            "rerun_package_strategy_matrix_after_any_replacement",
            "equal_replay_or_battle_gate_with_add_and_cut_lane_exercised_before_promotion",
        ]
    elif group == "usage_blocked":
        decision = "blocked_no_explicit_same_lane_route_for_used_hypothesis"
        required_next_evidence = [
            "mine_more_value_safe_cut_hypotheses",
            "expand_external_or_internal_cut_source_research",
            "do_not_reclassify_used_hypothesis_as_value_safe",
        ]
    elif group == "seen_without_usage":
        decision = "blocked_seen_without_usage_needs_negative_or_force_access_review"
        required_next_evidence = [
            "manual_negative_trace_review_or_force_access",
            "prove_nonuse_was_structural_before_reclassification",
            "keep_candidate_copy_closed",
        ]
    else:
        decision = "blocked_not_seen_needs_more_trace_before_reclassification"
        required_next_evidence = [
            "expand_replay_window_or_force_access",
            "prove_absence_is_reliable_before_reclassification",
            "keep_candidate_copy_closed",
        ]

    return {
        "cut_card": trace_row.get("cut_card"),
        "trace_status": trace_row.get("status"),
        "trace_group": group,
        "decision": decision,
        "cut_roles": sorted(roles),
        "source_score": source_row.get("score") or trace_row.get("source_score") or 0,
        "source_reasons": as_list(source_row.get("reasons")) or as_list(trace_row.get("source_reasons")),
        "usage_event_count": int(trace_row.get("usage_event_count") or 0),
        "exposure_event_count": int(trace_row.get("exposure_event_count") or 0),
        "decision_trace_count": int(trace_row.get("decision_trace_count") or 0),
        "same_lane_replacement_routes": strong_routes,
        "incidental_role_overlaps": incidental_overlaps,
        "same_lane_replacement_proof_allowed_now": False,
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
        "required_next_evidence": required_next_evidence,
    }


def build_report(
    *,
    trace_collector_report: Path,
    miner_report: Path,
    package_synthesis_report: Path,
) -> dict[str, Any]:
    trace_payload = load_json(trace_collector_report)
    miner_payload = load_json(miner_report)
    package_payload = load_json(package_synthesis_report)
    trace_summary = trace_payload.get("summary") or {}
    miner_summary = miner_payload.get("summary") or {}
    package_summary = package_payload.get("summary") or {}

    source_rows = source_rows_by_card(miner_payload)
    add_rows = package_add_rows(package_payload)
    review_rows = [
        proof_row_for_hypothesis(
            trace_row=row,
            source_row=source_rows.get(normalize_name(str(row.get("cut_card") or "")), {}),
            add_rows=add_rows,
        )
        for row in hypothesis_trace_rows(trace_payload)
    ]

    usage_blocked = [row for row in review_rows if row["trace_group"] == "usage_blocked"]
    seen_without_usage = [row for row in review_rows if row["trace_group"] == "seen_without_usage"]
    not_seen = [row for row in review_rows if row["trace_group"] == "not_seen"]
    same_lane_route_count = sum(len(row["same_lane_replacement_routes"]) for row in review_rows)
    incidental_overlap_count = sum(len(row["incidental_role_overlaps"]) for row in review_rows)
    add_axes = sorted(
        {
            role
            for add in add_rows
            for role in add_explicit_covered_roles(add)
            if role
        }
    )

    if same_lane_route_count:
        status = "cut_hypothesis_same_lane_proof_needs_explicit_evidence"
        next_gate = "collect_same_lane_or_equal_gate_proof_for_hypothesis_cuts"
    elif usage_blocked:
        status = "cut_hypothesis_same_lane_proof_routes_to_more_mining"
        next_gate = "mine_more_hypotheses_or_external_cut_source_research"
    elif seen_without_usage:
        status = "cut_hypothesis_same_lane_proof_needs_negative_review"
        next_gate = "manual_negative_review_or_force_access_for_seen_hypotheses"
    else:
        status = "cut_hypothesis_same_lane_proof_needs_more_trace"
        next_gate = "expand_replay_window_or_force_access_for_unseen_hypotheses"

    blockers = []
    if usage_blocked:
        blockers.append(
            "usage_blocked_hypotheses:" + ",".join(str(row.get("cut_card") or "") for row in usage_blocked)
        )
    if seen_without_usage:
        blockers.append(
            "seen_without_usage_requires_negative_review:"
            + ",".join(str(row.get("cut_card") or "") for row in seen_without_usage)
        )
    if not same_lane_route_count and usage_blocked:
        blockers.append("no_explicit_same_lane_route_for_usage_blocked_hypotheses")
    blockers.append("candidate_copy_closed_until_hypothesis_has_negative_trace_or_explicit_same_lane_equal_gate")

    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_cut_hypothesis_same_lane_proof",
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
        "same_lane_replacement_proof_allowed_now": False,
        "input_artifacts": {
            "trace_collector_report": rel(trace_collector_report),
            "miner_report": rel(miner_report),
            "package_synthesis_report": rel(package_synthesis_report),
        },
        "summary": {
            "deck_id": str(trace_summary.get("deck_id") or miner_summary.get("deck_id") or package_summary.get("deck_id") or ""),
            "commander": str(
                trace_summary.get("commander") or miner_summary.get("commander") or package_summary.get("commander") or ""
            ),
            "hypothesis_count": len(review_rows),
            "usage_blocked_hypothesis_count": len(usage_blocked),
            "seen_without_usage_count": len(seen_without_usage),
            "not_seen_count": len(not_seen),
            "explicit_same_lane_route_count": same_lane_route_count,
            "incidental_role_overlap_count": incidental_overlap_count,
            "package_add_count": len(add_rows),
            "package_explicit_add_axes": add_axes,
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "hypothesis_same_lane_rows": review_rows,
        "policy": {
            "same_lane_boundary": "Only package add covered_axes or selected_for_axis create an explicit same-lane route.",
            "incidental_overlap_boundary": "Shared profile_roles on a payoff card are incidental overlap, not value-safe cut proof.",
            "trace_boundary": "Used hypotheses stay blocked; seen-without-usage hypotheses still need negative review or force-access.",
            "mutation_boundary": "This proof model does not copy decks, mutate DBs, run battles, reclassify cuts, or open promotion.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Cut-Hypothesis Same-Lane Proof",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- hypothesis_count: `{summary['hypothesis_count']}`",
        f"- usage_blocked_hypothesis_count: `{summary['usage_blocked_hypothesis_count']}`",
        f"- seen_without_usage_count: `{summary['seen_without_usage_count']}`",
        f"- not_seen_count: `{summary['not_seen_count']}`",
        f"- explicit_same_lane_route_count: `{summary['explicit_same_lane_route_count']}`",
        f"- incidental_role_overlap_count: `{summary['incidental_role_overlap_count']}`",
        f"- package_explicit_add_axes: `{', '.join(summary['package_explicit_add_axes'])}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Hypothesis Rows",
        "",
        "| Cut | Trace Group | Decision | Roles | Same-Lane Routes | Incidental Overlaps |",
        "| --- | --- | --- | --- | ---: | ---: |",
    ]
    for row in payload["hypothesis_same_lane_rows"]:
        lines.append(
            "| `{cut}` | `{group}` | `{decision}` | `{roles}` | {routes} | {overlaps} |".format(
                cut=row.get("cut_card"),
                group=row.get("trace_group"),
                decision=row.get("decision"),
                roles=", ".join(row.get("cut_roles") or []),
                routes=len(row.get("same_lane_replacement_routes") or []),
                overlaps=len(row.get("incidental_role_overlaps") or []),
            )
        )
    if not payload["hypothesis_same_lane_rows"]:
        lines.append("| none | `-` | `-` | `-` | 0 | 0 |")
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
    parser.add_argument("--miner-report", type=Path, default=DEFAULT_MINER_REPORT)
    parser.add_argument("--package-synthesis-report", type=Path, default=DEFAULT_PACKAGE_SYNTHESIS_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        trace_collector_report=args.trace_collector_report,
        miner_report=args.miner_report,
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
