#!/usr/bin/env python3
"""Plan evidence needed before stage-only Commander cuts can become value-safe.

This read-only gate consumes a cut-source lane report after a synthesized
package still lacks value-safe cuts. It does not materialize decks, run battles,
mutate SQLite/PostgreSQL, or promote any cut. Its job is to classify why each
stage-only cut is not value-safe yet and name the next evidence lane.
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
DEFAULT_CUT_SOURCE_LANE_REPORT = (
    REPORT_DIR / "global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_stage_only_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1"
)

REASON_POLICIES = {
    "contextual_staple_requires_stage_review": {
        "evidence_lane": "contextual_staple_same_lane_usage_review",
        "burden": 1,
        "requirement": "prove the card is replaceable in its over-target lane without weakening current profile floors",
    },
    "attack_window_cut_requires_same_lane_stage_proof": {
        "evidence_lane": "attack_window_same_lane_replacement_trace",
        "burden": 3,
        "requirement": "name a same-lane attack-window replacement and prove haste/protection/extracombat floor is preserved",
    },
    "commander_expected_package_anchor_requires_stage_proof": {
        "evidence_lane": "expected_package_anchor_replacement_proof",
        "burden": 4,
        "requirement": "prove the expected package function is replaced before the card can be cut",
    },
    "structural_foundation_staple_requires_same_lane_or_battle_proof": {
        "evidence_lane": "structural_staple_same_lane_or_equal_gate_proof",
        "burden": 5,
        "requirement": "provide same-lane replacement proof or a replay-backed equal gate before cutting a structural staple",
    },
    "global_battle_feedback_requires_new_same_lane_or_gate": {
        "evidence_lane": "global_battle_feedback_reopen_proof",
        "burden": 6,
        "requirement": "show a materially new source lane or battle gate because prior global feedback blocks this cut",
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


def stage_only_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in payload.get("stage_only_cut_candidates") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            rows.append(dict(row))
    return rows


def policy_for_reason(reason: str) -> dict[str, Any]:
    return dict(
        REASON_POLICIES.get(
            reason,
            {
                "evidence_lane": "manual_stage_only_cut_review",
                "burden": 7,
                "requirement": "manually classify this stage-only reason before cut reclassification",
            },
        )
    )


def evidence_row(row: Mapping[str, Any]) -> dict[str, Any]:
    reasons = [str(reason) for reason in row.get("stage_reasons") or [] if reason]
    policies = [policy_for_reason(reason) for reason in reasons] or [policy_for_reason("manual_stage_only_cut_review")]
    max_burden = max(int(policy.get("burden") or 0) for policy in policies)
    min_burden = min(int(policy.get("burden") or 0) for policy in policies)
    return {
        "card_name": row.get("card_name"),
        "status": "stage_only_cut_needs_evidence_before_value_safe",
        "score": row.get("score") or 0,
        "profile_roles": row.get("profile_roles") or [],
        "matching_over_target_roles": row.get("matching_over_target_roles") or [],
        "stage_reasons": reasons,
        "evidence_lanes": [policy["evidence_lane"] for policy in policies],
        "requirements": [policy["requirement"] for policy in policies],
        "minimum_evidence_burden": min_burden,
        "maximum_evidence_burden": max_burden,
        "reclassification_allowed_now": False,
        "candidate_copy_allowed_now": False,
    }


def plan_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    planned = [evidence_row(row) for row in rows]
    planned.sort(
        key=lambda row: (
            int(row["maximum_evidence_burden"]),
            int(row["minimum_evidence_burden"]),
            -int(row.get("score") or 0),
            str(row.get("card_name") or ""),
        )
    )
    return planned


def reason_counts(planned: list[dict[str, Any]]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for row in planned:
        for reason in row.get("stage_reasons") or []:
            counts[str(reason)] = counts.get(str(reason), 0) + 1
    return counts


def lane_counts(planned: list[dict[str, Any]]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for row in planned:
        for lane in row.get("evidence_lanes") or []:
            counts[str(lane)] = counts.get(str(lane), 0) + 1
    return counts


def build_report(*, cut_source_lane_report: Path) -> dict[str, Any]:
    cut_payload = load_json(cut_source_lane_report)
    summary = cut_payload.get("summary") or {}
    planned = plan_rows(stage_only_rows(cut_payload))
    evidence_ready = bool(planned)
    return {
        "generated_at": utc_now(),
        "status": (
            "stage_only_cut_evidence_plan_ready"
            if evidence_ready
            else "stage_only_cut_evidence_plan_blocks_no_stage_only_rows"
        ),
        "artifact_type": "global_commander_stage_only_cut_evidence_plan",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "input_artifacts": {"cut_source_lane_report": rel(cut_source_lane_report)},
        "summary": {
            "deck_id": str(summary.get("deck_id") or ""),
            "commander": str(summary.get("commander") or ""),
            "cut_source_status": cut_payload.get("status"),
            "required_cut_count": summary.get("required_cut_count"),
            "value_safe_cut_count": summary.get("value_safe_cut_count"),
            "stage_only_cut_count": len(planned),
            "blocked_cut_count": summary.get("blocked_cut_count"),
            "reason_counts": reason_counts(planned),
            "evidence_lane_counts": lane_counts(planned),
            "next_gate": (
                "collect_stage_only_cut_evidence_before_value_safe_reclassification"
                if evidence_ready
                else "find_new_cut_source_lane_before_package_materialization"
            ),
        },
        "candidate_copy_blockers": [
            "stage_only_cuts_require_evidence_before_value_safe_reclassification"
            if evidence_ready
            else "no_stage_only_cut_rows_to_backfill"
        ],
        "evidence_plan_rows": planned,
        "policy": {
            "evidence_boundary": "This plan names evidence to collect; it does not reclassify any cut as value-safe.",
            "battle_boundary": "Battle remains closed until a candidate copy, strategy matrix, and replay gates pass.",
            "staple_boundary": "Structural staples and expected package anchors require stronger proof than contextual staples.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Stage-Only Cut Evidence Plan",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- cut_source_status: `{summary['cut_source_status']}`",
        f"- required_cut_count: `{summary['required_cut_count']}`",
        f"- value_safe_cut_count: `{summary['value_safe_cut_count']}`",
        f"- stage_only_cut_count: `{summary['stage_only_cut_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Evidence Plan Rows",
        "",
        "| Burden | Cut | Matching Roles | Reasons | Evidence Lanes |",
        "| ---: | --- | --- | --- | --- |",
    ]
    for row in payload["evidence_plan_rows"]:
        lines.append(
            "| {burden} | `{card}` | `{roles}` | `{reasons}` | `{lanes}` |".format(
                burden=row["maximum_evidence_burden"],
                card=row["card_name"],
                roles=", ".join(row.get("matching_over_target_roles") or []),
                reasons=", ".join(row.get("stage_reasons") or []),
                lanes=", ".join(row.get("evidence_lanes") or []),
            )
        )
    if not payload["evidence_plan_rows"]:
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
    parser.add_argument("--cut-source-lane-report", type=Path, default=DEFAULT_CUT_SOURCE_LANE_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(cut_source_lane_report=args.cut_source_lane_report)
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
