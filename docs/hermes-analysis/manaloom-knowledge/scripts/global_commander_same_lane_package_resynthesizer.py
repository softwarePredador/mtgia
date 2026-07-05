#!/usr/bin/env python3
"""Resynthesize Commander package requirements around same-lane cuts.

This read-only gate consumes the package-axis broadening plan and the current
package synthesis. It converts exhausted target cut roles into explicit add-axis
requirements before any package can be paired again. It does not name new cards,
copy a deck, mutate SQLite/PostgreSQL, run battle, or promote a package.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_BROADENING_REPORT = (
    REPORT_DIR / "global_commander_package_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1_external_policy.json"
)
DEFAULT_PACKAGE_SYNTHESIS_REPORT = (
    REPORT_DIR / "global_commander_payoff_package_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PAYOFF_SOURCE_REPORT = (
    REPORT_DIR / "global_commander_payoff_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_same_lane_package_resynthesizer_20260705_kaalia_value_safe_stage1_repair_scope1"
)

CUT_ROLE_TO_REQUIRED_ADD_AXIS = {
    "haste_protection_silence": "commander_attack_window",
    "mana_acceleration": "mana_acceleration_replacement",
    "tutors_access": "tutors_access_replacement",
}


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


def positive_counts(value: object) -> dict[str, int]:
    if not isinstance(value, Mapping):
        return {}
    return {str(key): as_int(count) for key, count in value.items() if as_int(count) > 0}


def selected_add_rows(package_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [
        dict(row)
        for row in package_payload.get("selected_add_package") or []
        if isinstance(row, Mapping) and row.get("card_name")
    ]


def selected_cut_rows(package_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [
        dict(row)
        for row in package_payload.get("selected_cut_package") or []
        if isinstance(row, Mapping) and row.get("card_name")
    ]


def row_axes(row: Mapping[str, Any]) -> set[str]:
    axes = set(as_list(row.get("covered_axes")))
    axis = str(row.get("selected_for_axis") or "").strip()
    if axis:
        axes.add(axis)
    return axes


def requirement_for_cut_role(role: str, count: int, add_rows: list[Mapping[str, Any]]) -> dict[str, Any]:
    required_axis = CUT_ROLE_TO_REQUIRED_ADD_AXIS.get(role, role)
    explicit_adds = [
        {
            "card_name": row.get("card_name"),
            "covered_axes": sorted(row_axes(row)),
            "selected_for_axis": row.get("selected_for_axis"),
        }
        for row in add_rows
        if required_axis in row_axes(row) or role in row_axes(row)
    ]
    if explicit_adds:
        status = "same_lane_add_axis_present_needs_cut_proof"
        next_gate = "collect_value_safe_cut_proof_for_same_lane_axis"
    else:
        status = "source_lane_required_before_package_resynthesis"
        next_gate = "expand_same_lane_add_source_lane_for_role"
    return {
        "cut_role": role,
        "target_cut_count": count,
        "required_add_axis": required_axis,
        "explicit_same_lane_add_count": len(explicit_adds),
        "explicit_same_lane_adds": explicit_adds,
        "status": status,
        "next_gate": next_gate,
        "candidate_copy_allowed": False,
    }


def selected_cut_diagnostics(cut_rows: list[Mapping[str, Any]], requirements: list[Mapping[str, Any]]) -> list[dict[str, Any]]:
    required_by_role = {str(row["cut_role"]): str(row["required_add_axis"]) for row in requirements}
    diagnostics: list[dict[str, Any]] = []
    for row in cut_rows:
        roles = as_list(row.get("matching_over_target_roles"))
        missing_axes = sorted(required_by_role[role] for role in roles if role in required_by_role)
        diagnostics.append(
            {
                "card_name": row.get("card_name"),
                "matching_over_target_roles": roles,
                "required_replacement_axes": missing_axes,
                "status": "cut_held_until_same_lane_replacement_and_value_safe_proof",
                "candidate_copy_allowed": False,
            }
        )
    return diagnostics


def held_add_diagnostics(add_rows: list[Mapping[str, Any]], requirements: list[Mapping[str, Any]]) -> list[dict[str, Any]]:
    required_axes = {str(row["required_add_axis"]) for row in requirements}
    held: list[dict[str, Any]] = []
    for row in add_rows:
        axes = row_axes(row)
        if axes & required_axes:
            continue
        held.append(
            {
                "card_name": row.get("card_name"),
                "selected_for_axis": row.get("selected_for_axis"),
                "covered_axes": sorted(axes),
                "fit_reasons": as_list(row.get("fit_reasons")),
                "status": "held_payoff_add_not_pairable_with_current_cut_roles",
                "guardrail": "payoff_axis_needs_own_value_safe_cut_or_same_lane_package_cut",
                "candidate_copy_allowed": False,
            }
        )
    return held


def resynthesis_actions(
    *,
    requirements: list[Mapping[str, Any]],
    held_add_count: int,
    ready_axis_count: int,
    value_safe_cut_count: int,
) -> list[dict[str, Any]]:
    actions = [
        {
            "priority": "P0",
            "action": "expand_same_lane_add_source_lanes_for_target_cut_roles",
            "status": "required_now",
            "reason": "Every exhausted cut role needs an explicit replacement add lane before package pairing.",
            "target_roles": [row["cut_role"] for row in requirements],
            "candidate_copy_allowed": False,
        }
    ]
    if held_add_count:
        actions.append(
            {
                "priority": "P1",
                "action": "hold_payoff_package_until_payoff_lane_has_own_cuts",
                "status": "held",
                "reason": "Payoff adds remain useful source candidates but cannot consume ramp, tutor, or attack-window cuts.",
                "held_add_count": held_add_count,
                "candidate_copy_allowed": False,
            }
        )
    if ready_axis_count and value_safe_cut_count == 0:
        actions.append(
            {
                "priority": "P2",
                "action": "collect_value_safe_cut_proof_for_existing_same_lane_axes",
                "status": "blocked_until_cut_proof",
                "reason": "An explicit add axis still does not authorize a cut without value-safe or equal-gate proof.",
                "ready_axis_count": ready_axis_count,
                "candidate_copy_allowed": False,
            }
        )
    actions.append(
        {
            "priority": "P3",
            "action": "keep_package_resynthesis_closed_to_deck_action",
            "status": "closed_no_deck_action",
            "reason": "Requirements are not a materialized package and do not open battle or promotion.",
            "candidate_copy_allowed": False,
        }
    )
    return actions


def build_report(
    *,
    broadening_report: Path,
    package_synthesis_report: Path,
    payoff_source_report: Path,
) -> dict[str, Any]:
    broadening_payload = load_json(broadening_report)
    package_payload = load_json(package_synthesis_report)
    payoff_payload = load_json(payoff_source_report)
    broadening_summary = broadening_payload.get("summary") or {}
    package_summary = package_payload.get("summary") or {}
    payoff_summary = payoff_payload.get("summary") or {}
    target_roles = positive_counts(broadening_summary.get("target_cut_roles"))
    add_rows = selected_add_rows(package_payload)
    cut_rows = selected_cut_rows(package_payload)
    requirements = [
        requirement_for_cut_role(role, count, add_rows)
        for role, count in sorted(target_roles.items())
    ]
    ready_axis_count = sum(
        1 for row in requirements if as_int(row.get("explicit_same_lane_add_count")) > 0
    )
    held_adds = held_add_diagnostics(add_rows, requirements)
    cut_diagnostics = selected_cut_diagnostics(cut_rows, requirements)
    value_safe_cut_count = as_int(broadening_summary.get("value_safe_cut_count"))
    if ready_axis_count and value_safe_cut_count > 0:
        status = "same_lane_package_resynthesis_has_pair_candidates"
        next_gate = "rerun_package_scope_reducer_with_same_lane_requirements"
    else:
        status = "same_lane_package_resynthesis_blocks_candidate_copy_needs_source_lanes"
        next_gate = "expand_same_lane_add_source_lanes_for_target_cut_roles"
    blockers = []
    if ready_axis_count < len(requirements):
        blockers.append("same_lane_add_source_lanes_missing_for_target_cut_roles")
    if ready_axis_count and value_safe_cut_count == 0:
        blockers.append("same_lane_axes_still_need_value_safe_cut_proof")
    if not blockers:
        blockers.append("same_lane_pairs_need_scope_reducer_before_candidate_copy")
    blockers.extend(
        [
            "payoff_adds_held_until_payoff_lane_has_own_cuts",
            "candidate_copy_closed_until_named_same_lane_value_safe_pairs_exist",
        ]
    )
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_same_lane_package_resynthesizer",
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
            "broadening_report": rel(broadening_report),
            "package_synthesis_report": rel(package_synthesis_report),
            "payoff_source_report": rel(payoff_source_report),
        },
        "summary": {
            "deck_id": str(broadening_summary.get("deck_id") or package_summary.get("deck_id") or ""),
            "commander": str(broadening_summary.get("commander") or package_summary.get("commander") or ""),
            "package_axes": as_list(broadening_summary.get("package_axes")),
            "target_cut_roles": target_roles,
            "selected_add_count": len(add_rows),
            "selected_cut_count": len(cut_rows),
            "held_payoff_add_count": len(held_adds),
            "same_lane_axis_requirement_count": len(requirements),
            "satisfied_same_lane_axis_count": ready_axis_count,
            "value_safe_cut_count": value_safe_cut_count,
            "payoff_source_ready_candidate_count": as_int(payoff_summary.get("ready_candidate_count")),
            "ready_pair_count": 0 if value_safe_cut_count == 0 else ready_axis_count,
            "next_gate": next_gate,
        },
        "same_lane_axis_requirements": requirements,
        "held_payoff_adds": held_adds,
        "selected_cut_diagnostics": cut_diagnostics,
        "resynthesis_actions": resynthesis_actions(
            requirements=requirements,
            held_add_count=len(held_adds),
            ready_axis_count=ready_axis_count,
            value_safe_cut_count=value_safe_cut_count,
        ),
        "candidate_copy_blockers": blockers,
        "policy": {
            "resynthesis_boundary": "This gate creates source-lane requirements, not deck changes.",
            "same_lane_boundary": "A cut role must be replaced by an explicit same-lane add axis or separately proven by equal-gate evidence.",
            "payoff_boundary": "Payoff source candidates stay held when current cut pressure is ramp, tutor, or attack-window pressure.",
            "battle_boundary": "No battle or promotion opens from requirements alone.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Same-Lane Package Resynthesizer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- package_axes: `{', '.join(summary['package_axes'])}`",
        f"- selected_add_count: `{summary['selected_add_count']}`",
        f"- selected_cut_count: `{summary['selected_cut_count']}`",
        f"- held_payoff_add_count: `{summary['held_payoff_add_count']}`",
        f"- same_lane_axis_requirement_count: `{summary['same_lane_axis_requirement_count']}`",
        f"- satisfied_same_lane_axis_count: `{summary['satisfied_same_lane_axis_count']}`",
        f"- value_safe_cut_count: `{summary['value_safe_cut_count']}`",
        f"- ready_pair_count: `{summary['ready_pair_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Same-Lane Axis Requirements",
        "",
        "| Cut Role | Target Cuts | Required Add Axis | Explicit Adds | Status | Next Gate |",
        "| --- | ---: | --- | ---: | --- | --- |",
    ]
    for row in payload["same_lane_axis_requirements"]:
        lines.append(
            "| `{role}` | {count} | `{axis}` | {adds} | `{status}` | `{next}` |".format(
                role=row.get("cut_role"),
                count=row.get("target_cut_count"),
                axis=row.get("required_add_axis"),
                adds=row.get("explicit_same_lane_add_count"),
                status=row.get("status"),
                next=row.get("next_gate"),
            )
        )
    lines.extend(["", "## Held Payoff Adds", ""])
    for row in payload["held_payoff_adds"]:
        lines.append(
            "- `{card}`: axis `{axis}`, guardrail `{guardrail}`".format(
                card=row.get("card_name"),
                axis=row.get("selected_for_axis"),
                guardrail=row.get("guardrail"),
            )
        )
    lines.extend(["", "## Selected Cut Diagnostics", ""])
    for row in payload["selected_cut_diagnostics"]:
        lines.append(
            "- `{card}`: roles `{roles}`, required replacement axes `{axes}`".format(
                card=row.get("card_name"),
                roles=", ".join(row.get("matching_over_target_roles") or []),
                axes=", ".join(row.get("required_replacement_axes") or []),
            )
        )
    lines.extend(
        [
            "",
            "## Resynthesis Actions",
            "",
            "| Priority | Action | Status | Reason |",
            "| --- | --- | --- | --- |",
        ]
    )
    for row in payload["resynthesis_actions"]:
        lines.append(
            "| `{priority}` | `{action}` | `{status}` | {reason} |".format(
                priority=row.get("priority"),
                action=row.get("action"),
                status=row.get("status"),
                reason=row.get("reason"),
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
    parser.add_argument("--broadening-report", type=Path, default=DEFAULT_BROADENING_REPORT)
    parser.add_argument("--package-synthesis-report", type=Path, default=DEFAULT_PACKAGE_SYNTHESIS_REPORT)
    parser.add_argument("--payoff-source-report", type=Path, default=DEFAULT_PAYOFF_SOURCE_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        broadening_report=args.broadening_report,
        package_synthesis_report=args.package_synthesis_report,
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
