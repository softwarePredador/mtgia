#!/usr/bin/env python3
"""Synthesize the next Commander recovery lane after forced cut access blocks.

This read-only gate consumes the post-forced cut-source report, the post-forced
package scope reducer, and the source package artifacts. It does not create a
candidate copy, run battle, mutate SQLite/PostgreSQL, or promote a package.
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
DEFAULT_PACKAGE_SYNTHESIS_REPORT = (
    REPORT_DIR / "global_commander_payoff_package_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_CUT_SOURCE_REPORT = (
    REPORT_DIR / "global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.json"
)
DEFAULT_SCOPE_REDUCER_REPORT = (
    REPORT_DIR / "global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.json"
)
DEFAULT_PROFILE_REPAIR_REPORT = (
    REPORT_DIR / "global_commander_profile_repair_candidate_model_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PAYOFF_SOURCE_REPORT = (
    REPORT_DIR / "global_commander_payoff_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_post_forced_recovery_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1"
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


def reason_counts(rows: list[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        for reason in row.get(field) or []:
            if reason:
                counts[str(reason)] += 1
    return dict(sorted(counts.items(), key=lambda item: (-item[1], item[0])))


def top_names(rows: list[Mapping[str, Any]], limit: int = 12) -> list[str]:
    names = []
    for row in rows:
        name = str(row.get("card_name") or row.get("add") or row.get("cut") or "").strip()
        if name and name not in names:
            names.append(name)
        if len(names) >= limit:
            break
    return names


def positive_budget_roles(cut_summary: Mapping[str, Any]) -> dict[str, int]:
    budgets = cut_summary.get("remaining_cut_budget_after_selection") or cut_summary.get("over_target_cut_budgets") or {}
    return {str(role): as_int(count) for role, count in budgets.items() if as_int(count) > 0}


def blocked_cut_rows(profile_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [
        dict(row)
        for row in profile_payload.get("blocked_cut_review_pool") or []
        if isinstance(row, Mapping) and row.get("card_name")
    ]


def profile_review_cut_rows(profile_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [
        dict(row)
        for row in profile_payload.get("global_cut_review_pool") or []
        if isinstance(row, Mapping) and row.get("card_name")
    ]


def selected_add_rows(package_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [
        dict(row)
        for row in package_payload.get("selected_add_package") or []
        if isinstance(row, Mapping) and row.get("card_name")
    ]


def recovery_actions(
    *,
    value_safe_count: int,
    scoped_pair_count: int,
    forced_usage_blocked_count: int,
    required_cut_count: int,
    cut_roles: Mapping[str, int],
    stage_only_count: int,
) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    if value_safe_count == 0:
        actions.append(
            {
                "priority": "P0",
                "action": "mine_new_value_safe_cut_source_before_package_resynthesis",
                "status": "required_now",
                "reason": "No value-safe cuts remain after forced-access review.",
                "target_cut_roles": dict(cut_roles),
                "required_cut_count": required_cut_count,
                "candidate_copy_allowed": False,
            }
        )
    if forced_usage_blocked_count > 0 or stage_only_count > 0:
        actions.append(
            {
                "priority": "P1",
                "action": "build_same_lane_or_equal_gate_proof_for_stage_only_cuts",
                "status": "diagnostic_only",
                "reason": "Used, structural, contextual, or attack-window cuts cannot become value-safe without explicit proof.",
                "forced_usage_blocked_count": forced_usage_blocked_count,
                "stage_only_cut_count": stage_only_count,
                "candidate_copy_allowed": False,
            }
        )
    if scoped_pair_count == 0:
        actions.append(
            {
                "priority": "P2",
                "action": "resynthesize_smaller_package_only_after_fresh_cut_proof",
                "status": "blocked_until_new_cut_source",
                "reason": "A smaller package still needs at least one value-safe cut pair.",
                "candidate_copy_allowed": False,
            }
        )
    actions.append(
        {
            "priority": "P3",
            "action": "keep_current_package_closed",
            "status": "closed_no_deck_action",
            "reason": "Current evidence does not authorize copy, natural battle, promotion, or deck mutation.",
            "candidate_copy_allowed": False,
        }
    )
    return actions


def build_report(
    *,
    package_synthesis_report: Path,
    cut_source_report: Path,
    scope_reducer_report: Path,
    profile_repair_report: Path,
    payoff_source_report: Path,
) -> dict[str, Any]:
    package_payload = load_json(package_synthesis_report)
    cut_payload = load_json(cut_source_report)
    reducer_payload = load_json(scope_reducer_report)
    profile_payload = load_json(profile_repair_report)
    payoff_payload = load_json(payoff_source_report)
    package_summary = package_payload.get("summary") or {}
    cut_summary = cut_payload.get("summary") or {}
    reducer_summary = reducer_payload.get("summary") or {}
    payoff_summary = payoff_payload.get("summary") or {}

    value_safe_count = as_int(cut_summary.get("value_safe_cut_count") or reducer_summary.get("value_safe_cut_count"))
    scoped_pair_count = as_int(reducer_summary.get("scoped_pair_count"))
    forced_usage_blocked_count = as_int(cut_summary.get("forced_usage_blocked_count") or reducer_summary.get("forced_usage_blocked_count"))
    required_cut_count = as_int(cut_summary.get("required_cut_count") or package_summary.get("selected_add_count"))
    stage_only_rows = [
        dict(row)
        for row in cut_payload.get("stage_only_cut_candidates") or []
        if isinstance(row, Mapping)
    ]
    blocked_cut_sample = [
        dict(row)
        for row in cut_payload.get("blocked_cut_candidates") or []
        if isinstance(row, Mapping)
    ]
    review_cut_rows = profile_review_cut_rows(profile_payload)
    blocked_profile_cuts = blocked_cut_rows(profile_payload)
    selected_adds = selected_add_rows(package_payload)
    cut_roles = positive_budget_roles(cut_summary)
    actions = recovery_actions(
        value_safe_count=value_safe_count,
        scoped_pair_count=scoped_pair_count,
        forced_usage_blocked_count=forced_usage_blocked_count,
        required_cut_count=required_cut_count,
        cut_roles=cut_roles,
        stage_only_count=len(stage_only_rows),
    )
    status = "post_forced_recovery_blocks_candidate_copy_needs_new_cut_source"
    next_gate = "mine_new_value_safe_cut_source_before_package_resynthesis"
    if value_safe_count > 0 and scoped_pair_count > 0:
        status = "post_forced_recovery_has_reduced_scope_materializer_route"
        next_gate = "materialize_reduced_scope_candidate_copy"
    elif value_safe_count > 0:
        status = "post_forced_recovery_needs_smaller_package_pairing"
        next_gate = "resynthesize_smaller_package_with_available_value_safe_cuts"
    blocker_rows: list[str] = []
    if value_safe_count == 0:
        blocker_rows.append("no_value_safe_cut_source_after_forced_access")
    if scoped_pair_count == 0:
        blocker_rows.append("no_reduced_scope_pair_after_forced_access")
    if forced_usage_blocked_count > 0:
        blocker_rows.append("forced_access_usage_blocks_reclassification")
    if status != "post_forced_recovery_has_reduced_scope_materializer_route":
        blocker_rows.append("current_package_closed_no_deck_action")

    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_post_forced_recovery_synthesizer",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": status == "post_forced_recovery_has_reduced_scope_materializer_route",
        "input_artifacts": {
            "package_synthesis_report": rel(package_synthesis_report),
            "cut_source_report": rel(cut_source_report),
            "scope_reducer_report": rel(scope_reducer_report),
            "profile_repair_report": rel(profile_repair_report),
            "payoff_source_report": rel(payoff_source_report),
        },
        "summary": {
            "deck_id": str(package_summary.get("deck_id") or cut_summary.get("deck_id") or reducer_summary.get("deck_id") or ""),
            "commander": str(package_summary.get("commander") or cut_summary.get("commander") or reducer_summary.get("commander") or ""),
            "selected_add_count": len(selected_adds),
            "required_cut_count": required_cut_count,
            "value_safe_cut_count": value_safe_count,
            "stage_only_cut_count": len(stage_only_rows),
            "blocked_cut_sample_count": len(blocked_cut_sample),
            "profile_review_cut_count": len(review_cut_rows),
            "profile_blocked_cut_count": len(blocked_profile_cuts),
            "forced_usage_blocked_count": forced_usage_blocked_count,
            "scoped_pair_count": scoped_pair_count,
            "dropped_add_count": as_int(reducer_summary.get("dropped_add_count")),
            "ready_payoff_candidate_count": as_int(payoff_summary.get("ready_candidate_count")),
            "target_cut_roles": cut_roles,
            "next_gate": next_gate,
        },
        "recovery_actions": actions,
        "candidate_copy_blockers": blocker_rows,
        "selected_adds": [
            {
                "card_name": row.get("card_name"),
                "selected_for_axis": row.get("selected_for_axis") or row.get("axis"),
                "covered_axes": row.get("covered_axes") or [],
                "score": row.get("score") or 0,
            }
            for row in selected_adds
        ],
        "profile_review_cuts": top_names(review_cut_rows),
        "stage_only_cut_names": top_names(stage_only_rows, limit=20),
        "stage_only_reason_counts": reason_counts(stage_only_rows, "stage_reasons"),
        "blocked_cut_reason_counts": reason_counts(blocked_cut_sample, "block_reasons"),
        "policy": {
            "recovery_boundary": "This report chooses the next evidence lane; it is not a deck action.",
            "cut_boundary": "A smaller package cannot advance without at least one value-safe cut pair.",
            "forced_access_boundary": "Forced access can block a cut; it cannot prove a cut is safe.",
            "battle_boundary": "Battle and promotion remain closed until copy/materializer and strategy gates pass.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Post-Forced Recovery Synthesizer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- selected_add_count: `{summary['selected_add_count']}`",
        f"- required_cut_count: `{summary['required_cut_count']}`",
        f"- value_safe_cut_count: `{summary['value_safe_cut_count']}`",
        f"- stage_only_cut_count: `{summary['stage_only_cut_count']}`",
        f"- forced_usage_blocked_count: `{summary['forced_usage_blocked_count']}`",
        f"- scoped_pair_count: `{summary['scoped_pair_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Recovery Actions",
        "",
        "| Priority | Action | Status | Reason |",
        "| --- | --- | --- | --- |",
    ]
    for row in payload["recovery_actions"]:
        lines.append(
            "| `{priority}` | `{action}` | `{status}` | {reason} |".format(
                priority=row.get("priority"),
                action=row.get("action"),
                status=row.get("status"),
                reason=row.get("reason"),
            )
        )
    lines.extend(["", "## Target Cut Roles", ""])
    for role, count in summary["target_cut_roles"].items():
        lines.append(f"- `{role}`: `{count}`")
    lines.extend(["", "## Selected Adds", ""])
    for row in payload["selected_adds"]:
        lines.append(
            f"- `{row.get('card_name')}`: axis `{row.get('selected_for_axis')}`, score `{row.get('score')}`"
        )
    lines.extend(["", "## Stage-Only Cut Reason Counts", ""])
    for reason, count in payload["stage_only_reason_counts"].items():
        lines.append(f"- `{reason}`: `{count}`")
    lines.extend(["", "## Blockers", ""])
    for blocker in [row for row in payload["candidate_copy_blockers"] if row]:
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
    parser.add_argument("--package-synthesis-report", type=Path, default=DEFAULT_PACKAGE_SYNTHESIS_REPORT)
    parser.add_argument("--cut-source-report", type=Path, default=DEFAULT_CUT_SOURCE_REPORT)
    parser.add_argument("--scope-reducer-report", type=Path, default=DEFAULT_SCOPE_REDUCER_REPORT)
    parser.add_argument("--profile-repair-report", type=Path, default=DEFAULT_PROFILE_REPAIR_REPORT)
    parser.add_argument("--payoff-source-report", type=Path, default=DEFAULT_PAYOFF_SOURCE_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        package_synthesis_report=args.package_synthesis_report,
        cut_source_report=args.cut_source_report,
        scope_reducer_report=args.scope_reducer_report,
        profile_repair_report=args.profile_repair_report,
        payoff_source_report=args.payoff_source_report,
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
