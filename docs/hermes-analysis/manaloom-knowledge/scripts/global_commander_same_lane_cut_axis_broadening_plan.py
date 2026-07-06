#!/usr/bin/env python3
"""Plan same-lane cut-axis broadening after the current deck is exhausted.

This read-only gate consumes the same-lane new cut source miner, the same-lane
source package, and the same-lane cut-pair collector. It turns "no fresh cut
source remains in the current deck" into explicit next research lanes. It does
not copy a deck, mutate SQLite/PostgreSQL, run battle, reclassify cuts, or
promote anything.
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


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_MINER_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_new_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PACKAGE_SOURCE_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_package_source_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_CUT_PAIR_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_cut_pair_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_same_lane_cut_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1"
)

EXTERNAL_RESEARCH_LANES = [
    "edhrec_commander_and_theme_pages",
    "public_moxfield_archidekt_decklists",
    "commander_spellbook_for_combo_dependency_context",
    "scryfall_oracle_identity_and_legality_crosscheck",
    "local_battle_trace_or_force_access_after_candidate_source_selection",
]


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


def selected_add_rows(package_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [
        dict(row)
        for row in package_payload.get("selected_add_package") or []
        if isinstance(row, Mapping) and row.get("card_name")
    ]
    rows.sort(key=lambda row: (str(row.get("replaces_cut_role") or ""), str(row.get("card_name") or "")))
    return rows


def role_counts(rows: list[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        value = str(row.get(field) or "")
        if value:
            counts[value] += 1
    return dict(counts)


def miner_rows_by_status(miner_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for status_key in (
        "fresh_same_lane_cut_sources",
        "blocked_recycled_cut_sources",
        "blocked_new_cut_sources",
    ):
        for row in miner_payload.get(status_key) or []:
            if isinstance(row, Mapping) and row.get("card_name"):
                rows.append(dict(row))
    return rows


def target_roles(miner_payload: Mapping[str, Any], package_payload: Mapping[str, Any]) -> list[str]:
    summary = miner_payload.get("summary") or {}
    roles = {str(role) for role in summary.get("target_roles") or [] if str(role or "").strip()}
    for row in selected_add_rows(package_payload):
        role = str(row.get("replaces_cut_role") or "")
        if role:
            roles.add(role)
    return sorted(roles)


def count_rows_by_role_and_status(rows: list[Mapping[str, Any]]) -> dict[tuple[str, str], int]:
    counts: Counter[tuple[str, str]] = Counter()
    for row in rows:
        role = str(row.get("target_cut_role") or "")
        status = str(row.get("status") or "")
        if role and status:
            counts[(role, status)] += 1
    return dict(counts)


def role_pressure_rows(
    *,
    roles: list[str],
    miner_payload: Mapping[str, Any],
    package_payload: Mapping[str, Any],
) -> list[dict[str, Any]]:
    rows = miner_rows_by_status(miner_payload)
    by_role_status = count_rows_by_role_and_status(rows)
    add_counts = role_counts(selected_add_rows(package_payload), "replaces_cut_role")
    pressure_rows = []
    for role in roles:
        fresh = by_role_status.get((role, "fresh_same_lane_cut_source_needs_trace"), 0)
        recycled = by_role_status.get((role, "blocked_recycled_cut_source"), 0)
        blocked_new = by_role_status.get((role, "blocked_new_cut_source"), 0)
        add_count = add_counts.get(role, 0)
        if fresh:
            status = "fresh_sources_need_trace_before_broadening"
            next_evidence = "collect_trace_for_new_same_lane_cut_source_hypotheses"
        elif recycled or blocked_new:
            status = "current_deck_same_lane_cut_sources_exhausted"
            next_evidence = "collect_external_nonpayoff_same_lane_cut_corpus"
        else:
            status = "target_role_needs_source_lane_discovery"
            next_evidence = "discover_same_lane_source_candidates_before_package_resynthesis"
        pressure_rows.append(
            {
                "target_cut_role": role,
                "selected_add_count": add_count,
                "fresh_source_count": fresh,
                "blocked_recycled_source_count": recycled,
                "blocked_new_source_count": blocked_new,
                "scanned_source_count": fresh + recycled + blocked_new,
                "status": status,
                "next_evidence": next_evidence,
            }
        )
    return pressure_rows


def choose_status_and_next_gate(
    *,
    miner_summary: Mapping[str, Any],
    pressure_rows: list[Mapping[str, Any]],
) -> tuple[str, str]:
    if as_int(miner_summary.get("fresh_same_lane_cut_source_count")) > 0:
        return (
            "same_lane_cut_axis_broadening_not_ready_fresh_sources_need_trace",
            "collect_trace_for_new_same_lane_cut_source_hypotheses",
        )
    missing_source_roles = [
        row
        for row in pressure_rows
        if row.get("status") == "target_role_needs_source_lane_discovery"
    ]
    if missing_source_roles:
        return (
            "same_lane_cut_axis_broadening_plan_ready_no_deck_action",
            "discover_same_lane_source_candidates_before_package_resynthesis",
        )
    return (
        "same_lane_cut_axis_broadening_plan_ready_no_deck_action",
        "collect_external_nonpayoff_same_lane_cut_corpus_for_exhausted_roles",
    )


def broadening_actions(
    *,
    status: str,
    pressure_rows: list[Mapping[str, Any]],
    cut_pair_summary: Mapping[str, Any],
) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    fresh_roles = [row for row in pressure_rows if as_int(row.get("fresh_source_count")) > 0]
    exhausted_roles = [
        row
        for row in pressure_rows
        if row.get("status") == "current_deck_same_lane_cut_sources_exhausted"
    ]
    missing_roles = [
        row
        for row in pressure_rows
        if row.get("status") == "target_role_needs_source_lane_discovery"
    ]
    if fresh_roles:
        actions.append(
            {
                "priority": "P0",
                "action": "collect_trace_for_new_same_lane_cut_source_hypotheses",
                "status": "required_before_broadening",
                "target_roles": [str(row["target_cut_role"]) for row in fresh_roles],
                "candidate_copy_allowed": False,
            }
        )
        return actions
    if exhausted_roles:
        actions.append(
            {
                "priority": "P0",
                "action": "collect_external_nonpayoff_same_lane_cut_corpus",
                "status": "required_now",
                "target_roles": [str(row["target_cut_role"]) for row in exhausted_roles],
                "research_lanes": EXTERNAL_RESEARCH_LANES,
                "guardrail": "external_presence_cannot_override_target_deck_usage_or_stage_only_trace",
                "candidate_copy_allowed": False,
            }
        )
    if missing_roles:
        actions.append(
            {
                "priority": "P1",
                "action": "discover_same_lane_source_candidates_before_package_resynthesis",
                "status": "required_now",
                "target_roles": [str(row["target_cut_role"]) for row in missing_roles],
                "candidate_copy_allowed": False,
            }
        )
    actions.append(
        {
            "priority": "P2",
            "action": "hold_current_selected_add_package",
            "status": "closed_until_new_cut_source_lane_exists",
            "selected_add_count": as_int(cut_pair_summary.get("selected_add_count")),
            "ready_pair_count": as_int(cut_pair_summary.get("ready_pair_count")),
            "unpaired_add_count": as_int(cut_pair_summary.get("unpaired_add_count")),
            "candidate_copy_allowed": False,
        }
    )
    actions.append(
        {
            "priority": "P3",
            "action": "forbid_recycling_used_seen_stage_only_or_blocked_cuts",
            "status": "always_on_guardrail",
            "reason": "Current deck cut rows already consumed by the evidence chain cannot become fresh without new evidence.",
            "candidate_copy_allowed": False,
        }
    )
    if status != "same_lane_cut_axis_broadening_plan_ready_no_deck_action":
        actions.append(
            {
                "priority": "P4",
                "action": "keep_current_package_closed",
                "status": "closed_no_deck_action",
                "candidate_copy_allowed": False,
            }
        )
    return actions


def build_report(
    *,
    miner_report: Path,
    package_source_report: Path,
    cut_pair_report: Path,
) -> dict[str, Any]:
    miner_payload = load_json(miner_report)
    package_payload = load_json(package_source_report)
    cut_pair_payload = load_json(cut_pair_report)
    miner_summary = miner_payload.get("summary") or {}
    package_summary = package_payload.get("summary") or {}
    cut_pair_summary = cut_pair_payload.get("summary") or {}
    roles = target_roles(miner_payload, package_payload)
    pressure = role_pressure_rows(
        roles=roles,
        miner_payload=miner_payload,
        package_payload=package_payload,
    )
    status, next_gate = choose_status_and_next_gate(miner_summary=miner_summary, pressure_rows=pressure)
    actions = broadening_actions(status=status, pressure_rows=pressure, cut_pair_summary=cut_pair_summary)
    blockers = [
        "candidate_copy_closed_until_external_or_new_same_lane_cut_source_exists",
        "battle_gate_closed_until_value_safe_same_lane_pair_and_candidate_copy_exist",
        "used_seen_stage_only_or_blocked_current_deck_cuts_cannot_be_recycled",
    ]
    if as_int(miner_summary.get("fresh_same_lane_cut_source_count")) == 0:
        blockers.append("current_deck_same_lane_cut_sources_exhausted")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_same_lane_cut_axis_broadening_plan",
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
            "new_cut_source_miner_report": rel(miner_report),
            "package_source_report": rel(package_source_report),
            "cut_pair_report": rel(cut_pair_report),
        },
        "summary": {
            "deck_id": str(
                miner_summary.get("deck_id")
                or package_summary.get("deck_id")
                or cut_pair_summary.get("deck_id")
                or ""
            ),
            "commander": str(
                miner_summary.get("commander")
                or package_summary.get("commander")
                or cut_pair_summary.get("commander")
                or ""
            ),
            "target_role_count": len(roles),
            "target_roles": roles,
            "fresh_same_lane_cut_source_count": as_int(miner_summary.get("fresh_same_lane_cut_source_count")),
            "scanned_same_lane_source_count": as_int(miner_summary.get("scanned_same_lane_source_count")),
            "blocked_recycled_cut_source_count": as_int(miner_summary.get("blocked_recycled_cut_source_count")),
            "ready_pair_count": as_int(cut_pair_summary.get("ready_pair_count")),
            "unpaired_add_count": as_int(cut_pair_summary.get("unpaired_add_count")),
            "action_count": len(actions),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "role_pressure_rows": pressure,
        "broadening_actions": actions,
        "candidate_copy_blockers": blockers,
        "policy": {
            "external_boundary": "External corpus can suggest new cut-source lanes, but cannot override target-deck usage or stage-only trace evidence.",
            "package_boundary": "The selected add package stays held until at least one value-safe same-lane cut pair exists.",
            "battle_boundary": "No battle gate opens before candidate copy plus card-level usage evidence.",
            "recycling_boundary": "Already used, seen, stage-only, blocked, or traced cuts are not fresh sources.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Same-Lane Cut Axis Broadening Plan",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- target_role_count: `{summary['target_role_count']}`",
        f"- scanned_same_lane_source_count: `{summary['scanned_same_lane_source_count']}`",
        f"- fresh_same_lane_cut_source_count: `{summary['fresh_same_lane_cut_source_count']}`",
        f"- blocked_recycled_cut_source_count: `{summary['blocked_recycled_cut_source_count']}`",
        f"- ready_pair_count: `{summary['ready_pair_count']}`",
        f"- unpaired_add_count: `{summary['unpaired_add_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Role Pressure",
        "",
        "| Role | Adds | Fresh | Recycled | Blocked New | Scanned | Status |",
        "| --- | ---: | ---: | ---: | ---: | ---: | --- |",
    ]
    for row in payload["role_pressure_rows"]:
        lines.append(
            "| `{role}` | {adds} | {fresh} | {recycled} | {blocked} | {scanned} | `{status}` |".format(
                role=row.get("target_cut_role"),
                adds=row.get("selected_add_count"),
                fresh=row.get("fresh_source_count"),
                recycled=row.get("blocked_recycled_source_count"),
                blocked=row.get("blocked_new_source_count"),
                scanned=row.get("scanned_source_count"),
                status=row.get("status"),
            )
        )
    lines.extend(["", "## Actions", ""])
    for row in payload["broadening_actions"]:
        lines.append(
            "- `{priority}` `{action}`: `{status}`".format(
                priority=row.get("priority"),
                action=row.get("action"),
                status=row.get("status"),
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
    parser.add_argument("--new-cut-source-miner-report", type=Path, default=DEFAULT_MINER_REPORT)
    parser.add_argument("--package-source-report", type=Path, default=DEFAULT_PACKAGE_SOURCE_REPORT)
    parser.add_argument("--cut-pair-report", type=Path, default=DEFAULT_CUT_PAIR_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        miner_report=args.new_cut_source_miner_report,
        package_source_report=args.package_source_report,
        cut_pair_report=args.cut_pair_report,
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
