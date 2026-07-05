#!/usr/bin/env python3
"""Plan evidence for same-lane stage-only Commander cuts.

This read-only gate consumes the same-lane cut pair collector. It explains why
stage-only cuts cannot yet become value-safe and names the next evidence lanes.
It does not reclassify cuts, copy decks, mutate SQLite/PostgreSQL, run battle,
or promote anything.
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
DEFAULT_CUT_PAIR_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_cut_pair_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_same_lane_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1"
)

REASON_POLICIES = {
    "target_role_is_protected_profile_lane_requires_trace_or_equal_gate": {
        "evidence_lane": "protected_same_lane_usage_trace_or_equal_gate",
        "burden": 6,
        "requirement": "prove the protected lane is preserved by the add and that cutting this card does not weaken the commander attack window",
    },
    "structural_foundation_staple_requires_same_lane_or_battle_proof": {
        "evidence_lane": "structural_staple_same_lane_or_equal_gate_proof",
        "burden": 6,
        "requirement": "prove same-lane replacement or replay-backed equal gate before cutting a structural format staple",
    },
    "global_battle_feedback_requires_new_same_lane_or_gate": {
        "evidence_lane": "prior_failed_gate_reopen_proof",
        "burden": 7,
        "requirement": "show materially new same-lane evidence because prior global feedback already blocked this cut",
    },
    "commander_expected_package_anchor_requires_stage_proof": {
        "evidence_lane": "expected_package_anchor_replacement_proof",
        "burden": 5,
        "requirement": "prove the expected commander package function remains covered after the cut",
    },
    "contextual_staple_requires_stage_review": {
        "evidence_lane": "contextual_staple_usage_and_replacement_review",
        "burden": 4,
        "requirement": "check current deck usage and replacement coverage before treating the contextual staple as value-safe",
    },
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


def policy_for_reason(reason: str) -> dict[str, Any]:
    if reason.startswith("non_target_cut_risk:"):
        return {
            "evidence_lane": "cross_role_risk_trace_or_new_cut_source",
            "burden": 5,
            "requirement": "prove the non-target role is redundant or find a cut without cross-role risk",
        }
    if reason.startswith("other_protected_profile_role_"):
        return {
            "evidence_lane": "multi_role_protected_lane_replacement_proof",
            "burden": 6,
            "requirement": "prove every protected secondary role is replaced before any value-safe reclassification",
        }
    return dict(
        REASON_POLICIES.get(
            reason,
            {
                "evidence_lane": "manual_same_lane_cut_review",
                "burden": 7,
                "requirement": "manually classify this same-lane stage-only reason before reclassification",
            },
        )
    )


def stage_only_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in payload.get("stage_only_cut_candidates") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            rows.append(dict(row))
    return rows


def blocked_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in payload.get("blocked_cut_candidates") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            rows.append(dict(row))
    return rows


def plan_row(row: Mapping[str, Any]) -> dict[str, Any]:
    reasons = [str(reason) for reason in row.get("stage_reasons") or [] if reason]
    policies = [policy_for_reason(reason) for reason in reasons] or [policy_for_reason("")]
    burdens = [as_int(policy.get("burden")) for policy in policies]
    return {
        "card_name": row.get("card_name"),
        "target_cut_role": row.get("target_cut_role"),
        "status": "same_lane_stage_only_cut_needs_evidence",
        "score": as_int(row.get("score")),
        "profile_roles": row.get("profile_roles") or [],
        "risk_flags": row.get("risk_flags") or [],
        "stage_reasons": reasons,
        "evidence_lanes": [str(policy["evidence_lane"]) for policy in policies],
        "requirements": [str(policy["requirement"]) for policy in policies],
        "minimum_evidence_burden": min(burdens) if burdens else 7,
        "maximum_evidence_burden": max(burdens) if burdens else 7,
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
    }


def plan_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    planned = [plan_row(row) for row in rows]
    planned.sort(
        key=lambda row: (
            as_int(row.get("maximum_evidence_burden")),
            as_int(row.get("minimum_evidence_burden")),
            -as_int(row.get("score")),
            str(row.get("card_name") or ""),
            str(row.get("target_cut_role") or ""),
        )
    )
    return planned


def count_values(rows: list[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        value = row.get(field)
        if isinstance(value, list):
            for item in value:
                if str(item or "").strip():
                    counts[str(item)] += 1
        elif str(value or "").strip():
            counts[str(value)] += 1
    return dict(counts)


def blocked_reason_counts(rows: list[Mapping[str, Any]]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        for reason in row.get("block_reasons") or []:
            counts[str(reason)] += 1
    return dict(counts)


def choose_status_and_next_gate(planned_count: int, ready_pair_count: int) -> tuple[str, str]:
    if ready_pair_count > 0:
        return (
            "same_lane_cut_evidence_plan_ready_pairs_need_scope_reducer",
            "run_same_lane_package_scope_reducer_before_candidate_copy",
        )
    if planned_count > 0:
        return (
            "same_lane_cut_evidence_plan_ready_no_deck_action",
            "collect_trace_or_external_evidence_for_same_lane_stage_only_cuts",
        )
    return (
        "same_lane_cut_evidence_plan_blocks_no_stage_only_lane",
        "broaden_same_lane_cut_source_research",
    )


def build_report(*, cut_pair_report: Path) -> dict[str, Any]:
    payload = load_json(cut_pair_report)
    summary = payload.get("summary") or {}
    planned = plan_rows(stage_only_rows(payload))
    blocked = blocked_rows(payload)
    status, next_gate = choose_status_and_next_gate(
        planned_count=len(planned),
        ready_pair_count=as_int(summary.get("ready_pair_count")),
    )
    blockers = [
        "candidate_copy_closed_until_value_safe_same_lane_pair_exists",
        "value_safe_reclassification_closed_until_evidence_plan_is_satisfied",
    ]
    if planned:
        blockers.append(f"same_lane_stage_only_cut_evidence_required:{len(planned)}")
    if blocked:
        blockers.append(f"hard_blocked_same_lane_cut_candidates:{len(blocked)}")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_same_lane_cut_evidence_plan",
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
        "input_artifacts": {"cut_pair_report": rel(cut_pair_report)},
        "summary": {
            "deck_id": str(summary.get("deck_id") or ""),
            "commander": str(summary.get("commander") or ""),
            "cut_pair_status": payload.get("status"),
            "selected_add_count": as_int(summary.get("selected_add_count")),
            "ready_pair_count": as_int(summary.get("ready_pair_count")),
            "unpaired_add_count": as_int(summary.get("unpaired_add_count")),
            "stage_only_cut_evidence_count": len(planned),
            "hard_blocked_cut_count": len(blocked),
            "target_role_counts": count_values(planned, "target_cut_role"),
            "reason_counts": count_values(planned, "stage_reasons"),
            "evidence_lane_counts": count_values(planned, "evidence_lanes"),
            "blocked_reason_counts": blocked_reason_counts(blocked),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "evidence_plan_rows": planned,
        "hard_blocked_cut_sample": blocked[:30],
        "policy": {
            "evidence_boundary": "This plan names missing proof; it does not reclassify stage-only cuts.",
            "same_lane_boundary": "Same-lane cuts still need trace, staple, anchor, or equal-gate proof when stage-only reasons exist.",
            "hard_block_boundary": "Lands and commander payoff slots remain blocked, not stage-only candidates.",
            "battle_boundary": "No battle or promotion opens from this evidence plan.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Same-Lane Cut Evidence Plan",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- cut_pair_status: `{summary['cut_pair_status']}`",
        f"- selected_add_count: `{summary['selected_add_count']}`",
        f"- ready_pair_count: `{summary['ready_pair_count']}`",
        f"- unpaired_add_count: `{summary['unpaired_add_count']}`",
        f"- stage_only_cut_evidence_count: `{summary['stage_only_cut_evidence_count']}`",
        f"- hard_blocked_cut_count: `{summary['hard_blocked_cut_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Evidence Lanes",
        "",
        "| Lane | Count |",
        "| --- | ---: |",
    ]
    for lane, count in summary["evidence_lane_counts"].items():
        lines.append(f"| `{lane}` | {count} |")
    if not summary["evidence_lane_counts"]:
        lines.append("| `none` | 0 |")
    lines.extend(
        [
            "",
            "## Evidence Plan Rows",
            "",
            "| Burden | Cut | Role | Reasons | Evidence Lanes |",
            "| ---: | --- | --- | --- | --- |",
        ]
    )
    for row in payload["evidence_plan_rows"][:30]:
        lines.append(
            "| {burden} | `{card}` | `{role}` | `{reasons}` | `{lanes}` |".format(
                burden=row["maximum_evidence_burden"],
                card=row["card_name"],
                role=row["target_cut_role"],
                reasons=", ".join(row.get("stage_reasons") or []),
                lanes=", ".join(row.get("evidence_lanes") or []),
            )
        )
    if not payload["evidence_plan_rows"]:
        lines.append("| 0 | none | `-` | `-` | `-` |")
    lines.extend(["", "## Hard-Blocked Cut Sample", ""])
    for row in payload["hard_blocked_cut_sample"][:12]:
        lines.append(
            "- `{card}` ({role}): `{reasons}`".format(
                card=row.get("card_name"),
                role=row.get("target_cut_role"),
                reasons=", ".join(row.get("block_reasons") or []),
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
    parser.add_argument("--cut-pair-report", type=Path, default=DEFAULT_CUT_PAIR_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(cut_pair_report=args.cut_pair_report)
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
