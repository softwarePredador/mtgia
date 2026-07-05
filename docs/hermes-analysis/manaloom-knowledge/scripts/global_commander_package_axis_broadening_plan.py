#!/usr/bin/env python3
"""Plan the next Commander package axis after value-safe cut mining exhausts.

This read-only gate consumes the policy-aware value-safe cut miner plus the
current package/cut reports. It decides whether the current package axis can be
resynthesized, needs same-lane add requirements, or needs broader external cut
research. It never copies a deck, mutates SQLite/PostgreSQL, runs battle, or
promotes a package.
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
DEFAULT_MINER_REPORT = (
    REPORT_DIR / "global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1_external_policy.json"
)
DEFAULT_PACKAGE_SYNTHESIS_REPORT = (
    REPORT_DIR / "global_commander_payoff_package_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_CUT_SOURCE_REPORT = (
    REPORT_DIR / "global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_POLICY_REPORT = (
    REPORT_DIR / "global_commander_external_corpus_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_CORPUS_REPORT = (
    REPORT_DIR / "global_commander_external_reference_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_package_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1_external_policy"
)

INCIDENTAL_SIGNAL_BY_CUT_ROLE = {
    "haste_protection_silence": {"haste", "protection_or_lock_payload", "combat_keywords"},
    "mana_acceleration": {"mana_or_treasure_payload"},
    "tutors_access": {"tutor_payload", "library_search_payload"},
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


def package_axes(add_rows: list[Mapping[str, Any]]) -> list[str]:
    axes: set[str] = set()
    for row in add_rows:
        axes.update(as_list(row.get("covered_axes")))
        axis = str(row.get("selected_for_axis") or "").strip()
        if axis:
            axes.add(axis)
    return sorted(axes)


def target_cut_roles(miner_summary: Mapping[str, Any], cut_summary: Mapping[str, Any]) -> dict[str, int]:
    miner_roles = positive_counts(miner_summary.get("target_cut_roles"))
    if miner_roles:
        return miner_roles
    return positive_counts(
        cut_summary.get("remaining_cut_budget_after_selection")
        or cut_summary.get("over_target_cut_budgets")
    )


def incidental_signals_for_add(row: Mapping[str, Any], cut_roles: Mapping[str, int]) -> dict[str, list[str]]:
    fit_reasons = set(as_list(row.get("fit_reasons")))
    signals: dict[str, list[str]] = {}
    for role in cut_roles:
        hits = sorted(fit_reasons & INCIDENTAL_SIGNAL_BY_CUT_ROLE.get(role, set()))
        if hits:
            signals[role] = hits
    return signals


def lane_alignment(
    *,
    axes: list[str],
    cut_roles: Mapping[str, int],
    add_rows: list[Mapping[str, Any]],
) -> dict[str, Any]:
    axis_set = set(axes)
    cut_role_set = set(cut_roles)
    same_lane_axes = sorted(axis_set & cut_role_set)
    unmatched_cut_roles = sorted(cut_role_set - axis_set)
    incidental_rows = [
        {
            "card_name": row.get("card_name"),
            "selected_for_axis": row.get("selected_for_axis"),
            "incidental_signals": incidental_signals_for_add(row, cut_roles),
            "guardrail": "incidental_payload_is_not_same_lane_cut_proof",
        }
        for row in add_rows
        if incidental_signals_for_add(row, cut_roles)
    ]
    if not cut_roles:
        status = "target_cut_roles_missing_needs_cut_lane_recheck"
    elif not same_lane_axes:
        status = "package_axis_mismatch_with_exhausted_cut_lanes"
    elif unmatched_cut_roles:
        status = "partial_same_lane_axis_coverage_needs_explicit_cut_proof"
    else:
        status = "same_lane_axis_present_needs_value_safe_cut_proof"
    return {
        "lane_alignment_status": status,
        "package_axes": axes,
        "target_cut_roles": dict(cut_roles),
        "same_lane_axes": same_lane_axes,
        "unmatched_cut_roles": unmatched_cut_roles,
        "incidental_secondary_signal_count": len(incidental_rows),
        "incidental_secondary_signals": incidental_rows,
    }


def broadening_actions(
    *,
    miner_summary: Mapping[str, Any],
    alignment: Mapping[str, Any],
    value_safe_cut_count: int,
    selected_add_count: int,
    selected_cut_count: int,
    policy_summary: Mapping[str, Any],
    corpus_summary: Mapping[str, Any],
) -> list[dict[str, Any]]:
    hypothesis_count = as_int(miner_summary.get("hypothesis_count"))
    actions: list[dict[str, Any]] = []
    if hypothesis_count > 0:
        actions.append(
            {
                "priority": "P0",
                "action": "collect_usage_trace_for_remaining_fresh_hypotheses",
                "status": "required_before_axis_broadening",
                "reason": "Fresh cut-source hypotheses still exist and must be traced before package-axis resynthesis.",
                "candidate_copy_allowed": False,
            }
        )
        return actions
    if alignment.get("lane_alignment_status") == "package_axis_mismatch_with_exhausted_cut_lanes":
        actions.append(
            {
                "priority": "P0",
                "action": "resynthesize_package_with_same_lane_axis_requirements",
                "status": "required_now",
                "reason": "The current add package is not competing in the same lanes as the exhausted cut pressure.",
                "package_axes": alignment.get("package_axes") or [],
                "target_cut_roles": alignment.get("target_cut_roles") or {},
                "candidate_copy_allowed": False,
            }
        )
    else:
        actions.append(
            {
                "priority": "P0",
                "action": "collect_or_validate_same_lane_value_safe_cut_pairs_before_resynthesis",
                "status": "required_now",
                "reason": "Same-lane axes are present or partial, but value-safe cut proof is still missing.",
                "same_lane_axes": alignment.get("same_lane_axes") or [],
                "candidate_copy_allowed": False,
            }
        )
    if as_int(policy_summary.get("rerun_miner_allowed_card_count")) == 0:
        actions.append(
            {
                "priority": "P1",
                "action": "collect_external_nonpayoff_cut_lane_corpus",
                "status": "evidence_lane",
                "reason": "The external policy consumed current hypotheses; target cut roles need new source context before reuse.",
                "policy_row_count": as_int(policy_summary.get("policy_row_count")),
                "corpus_source_count": as_int(corpus_summary.get("source_count")),
                "candidate_copy_allowed": False,
            }
        )
    if value_safe_cut_count == 0 or selected_cut_count < selected_add_count:
        actions.append(
            {
                "priority": "P2",
                "action": "reduce_package_to_existing_value_safe_pairs_only_after_proof",
                "status": "blocked_until_cut_pair_exists",
                "reason": "No reduced package may advance without at least one value-safe add/cut pair.",
                "selected_add_count": selected_add_count,
                "selected_cut_count": selected_cut_count,
                "value_safe_cut_count": value_safe_cut_count,
                "candidate_copy_allowed": False,
            }
        )
    actions.append(
        {
            "priority": "P3",
            "action": "keep_current_package_closed",
            "status": "closed_no_deck_action",
            "reason": "Current evidence does not authorize deck copy, battle, promotion, or mutation.",
            "candidate_copy_allowed": False,
        }
    )
    return actions


def choose_status_and_next_gate(miner_summary: Mapping[str, Any], alignment_status: str) -> tuple[str, str]:
    if as_int(miner_summary.get("hypothesis_count")) > 0:
        return (
            "package_axis_broadening_not_ready_hypotheses_need_trace",
            "collect_usage_trace_for_new_cut_source_hypotheses",
        )
    if alignment_status == "package_axis_mismatch_with_exhausted_cut_lanes":
        return (
            "commander_package_axis_broadening_plan_ready_no_deck_action",
            "resynthesize_package_with_same_lane_axis_requirements",
        )
    return (
        "commander_package_axis_broadening_plan_ready_no_deck_action",
        "collect_or_validate_same_lane_value_safe_cut_pairs_before_resynthesis",
    )


def build_report(
    *,
    miner_report: Path,
    package_synthesis_report: Path,
    cut_source_report: Path,
    policy_report: Path,
    corpus_report: Path,
) -> dict[str, Any]:
    miner_payload = load_json(miner_report)
    package_payload = load_json(package_synthesis_report)
    cut_payload = load_json(cut_source_report)
    policy_payload = load_json(policy_report)
    corpus_payload = load_json(corpus_report)
    miner_summary = miner_payload.get("summary") or {}
    package_summary = package_payload.get("summary") or {}
    cut_summary = cut_payload.get("summary") or {}
    policy_summary = policy_payload.get("summary") or {}
    corpus_summary = corpus_payload.get("summary") or {}
    add_rows = selected_add_rows(package_payload)
    cut_rows = selected_cut_rows(package_payload)
    cut_roles = target_cut_roles(miner_summary, cut_summary)
    alignment = lane_alignment(axes=package_axes(add_rows), cut_roles=cut_roles, add_rows=add_rows)
    value_safe_cut_count = as_int(cut_summary.get("value_safe_cut_count"))
    status, next_gate = choose_status_and_next_gate(miner_summary, str(alignment["lane_alignment_status"]))
    actions = broadening_actions(
        miner_summary=miner_summary,
        alignment=alignment,
        value_safe_cut_count=value_safe_cut_count,
        selected_add_count=len(add_rows),
        selected_cut_count=len(cut_rows),
        policy_summary=policy_summary,
        corpus_summary=corpus_summary,
    )
    blockers = [
        "policy_aware_miner_has_no_fresh_value_safe_cut_hypotheses"
        if as_int(miner_summary.get("hypothesis_count")) == 0
        else "fresh_cut_source_hypotheses_need_trace_before_axis_broadening",
        "current_package_axis_not_authorized_for_cross_lane_cuts"
        if alignment["lane_alignment_status"] == "package_axis_mismatch_with_exhausted_cut_lanes"
        else "same_lane_axis_still_needs_value_safe_cut_proof",
        "candidate_copy_closed_until_value_safe_same_lane_pair_exists",
    ]
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_package_axis_broadening_plan",
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
            "miner_report": rel(miner_report),
            "package_synthesis_report": rel(package_synthesis_report),
            "cut_source_report": rel(cut_source_report),
            "policy_report": rel(policy_report),
            "corpus_report": rel(corpus_report),
        },
        "summary": {
            "deck_id": str(miner_summary.get("deck_id") or package_summary.get("deck_id") or cut_summary.get("deck_id") or ""),
            "commander": str(
                miner_summary.get("commander")
                or package_summary.get("commander")
                or cut_summary.get("commander")
                or ""
            ),
            "selected_add_count": len(add_rows),
            "selected_cut_count": len(cut_rows),
            "unpaired_add_count": as_int(package_summary.get("unpaired_add_count")),
            "value_safe_cut_count": value_safe_cut_count,
            "fresh_hypothesis_count": as_int(miner_summary.get("hypothesis_count")),
            "blocked_hypothesis_count": as_int(miner_summary.get("blocked_hypothesis_count")),
            "external_policy_exclusion_count": as_int(miner_summary.get("external_policy_exclusion_count")),
            "policy_row_count": as_int(policy_summary.get("policy_row_count")),
            "corpus_source_count": as_int(corpus_summary.get("source_count")),
            "lane_alignment_status": alignment["lane_alignment_status"],
            "package_axes": alignment["package_axes"],
            "target_cut_roles": alignment["target_cut_roles"],
            "same_lane_axes": alignment["same_lane_axes"],
            "unmatched_cut_roles": alignment["unmatched_cut_roles"],
            "incidental_secondary_signal_count": alignment["incidental_secondary_signal_count"],
            "next_gate": next_gate,
        },
        "broadening_actions": actions,
        "candidate_copy_blockers": blockers,
        "selected_add_axis_diagnostics": [
            {
                "card_name": row.get("card_name"),
                "selected_for_axis": row.get("selected_for_axis"),
                "covered_axes": as_list(row.get("covered_axes")),
                "incidental_signals": incidental_signals_for_add(row, cut_roles),
                "guardrail": "incidental_payload_is_not_same_lane_cut_proof",
            }
            for row in add_rows
        ],
        "selected_cut_lane_diagnostics": [
            {
                "card_name": row.get("card_name"),
                "matching_over_target_roles": as_list(row.get("matching_over_target_roles")),
                "cut_reasons": as_list(row.get("cut_reasons")),
                "guardrail": "selected_cut_still_needs_value_safe_or_equal_gate_proof",
            }
            for row in cut_rows
        ],
        "policy": {
            "axis_boundary": "A payoff add package cannot justify cuts from ramp, tutor, haste/protection, or other lanes without explicit same-lane/equal-gate proof.",
            "incidental_signal_boundary": "Secondary text such as haste, treasure, draw, or protection on a payoff is not same-lane replacement proof by itself.",
            "cut_boundary": "External absence, stage-only status, and forced-access diagnostics do not create value-safe cuts.",
            "battle_boundary": "This plan does not run battle or open promotion.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Package Axis Broadening Plan",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- selected_add_count: `{summary['selected_add_count']}`",
        f"- selected_cut_count: `{summary['selected_cut_count']}`",
        f"- unpaired_add_count: `{summary['unpaired_add_count']}`",
        f"- value_safe_cut_count: `{summary['value_safe_cut_count']}`",
        f"- fresh_hypothesis_count: `{summary['fresh_hypothesis_count']}`",
        f"- blocked_hypothesis_count: `{summary['blocked_hypothesis_count']}`",
        f"- external_policy_exclusion_count: `{summary['external_policy_exclusion_count']}`",
        f"- lane_alignment_status: `{summary['lane_alignment_status']}`",
        f"- package_axes: `{', '.join(summary['package_axes'])}`",
        f"- unmatched_cut_roles: `{', '.join(summary['unmatched_cut_roles'])}`",
        f"- incidental_secondary_signal_count: `{summary['incidental_secondary_signal_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Broadening Actions",
        "",
        "| Priority | Action | Status | Reason |",
        "| --- | --- | --- | --- |",
    ]
    for row in payload["broadening_actions"]:
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
        same_lane = "yes" if role in summary["same_lane_axes"] else "no"
        lines.append(f"- `{role}`: `{count}`; same_lane_add_axis_present=`{same_lane}`")
    lines.extend(
        [
            "",
            "## Selected Add Axis Diagnostics",
            "",
            "| Add | Axis | Covered Axes | Incidental Signals | Guardrail |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    for row in payload["selected_add_axis_diagnostics"]:
        signals = []
        for role, hits in (row.get("incidental_signals") or {}).items():
            signals.append(f"{role}:{','.join(hits)}")
        lines.append(
            "| `{card}` | `{axis}` | `{axes}` | `{signals}` | `{guardrail}` |".format(
                card=row.get("card_name"),
                axis=row.get("selected_for_axis"),
                axes=", ".join(row.get("covered_axes") or []),
                signals="; ".join(signals),
                guardrail=row.get("guardrail"),
            )
        )
    lines.extend(["", "## Selected Cut Lane Diagnostics", ""])
    for row in payload["selected_cut_lane_diagnostics"]:
        lines.append(
            "- `{card}`: roles `{roles}`, guardrail `{guardrail}`".format(
                card=row.get("card_name"),
                roles=", ".join(row.get("matching_over_target_roles") or []),
                guardrail=row.get("guardrail"),
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
    parser.add_argument("--miner-report", type=Path, default=DEFAULT_MINER_REPORT)
    parser.add_argument("--package-synthesis-report", type=Path, default=DEFAULT_PACKAGE_SYNTHESIS_REPORT)
    parser.add_argument("--cut-source-report", type=Path, default=DEFAULT_CUT_SOURCE_REPORT)
    parser.add_argument("--policy-report", type=Path, default=DEFAULT_POLICY_REPORT)
    parser.add_argument("--corpus-report", type=Path, default=DEFAULT_CORPUS_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        miner_report=args.miner_report,
        package_synthesis_report=args.package_synthesis_report,
        cut_source_report=args.cut_source_report,
        policy_report=args.policy_report,
        corpus_report=args.corpus_report,
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
