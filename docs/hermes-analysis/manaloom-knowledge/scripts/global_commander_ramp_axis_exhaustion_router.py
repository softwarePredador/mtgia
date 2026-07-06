#!/usr/bin/env python3
"""Route global Commander learning after current ramp cut lanes exhaust.

This read-only router consumes the ramp forced-recovery report and the
alternative ramp forced-access report. It marks the current ramp cut lane as
exhausted only when no exact replacement is ready and the alternative ramp cut
targets are also usage-blocked. It does not copy decks, mutate data, run battle
gates, or promote changes.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT, rel


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_RECOVERY_REPORT = REPORT_DIR / "global_commander_ramp_cut_forced_recovery_router_20260706_current.json"
DEFAULT_ALTERNATIVE_FORCED_REPORT = (
    REPORT_DIR / "global_commander_ramp_alternative_cut_forced_access_trace_generator_20260706_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_ramp_axis_exhaustion_router_20260706_current"


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


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def blocked_names(rows: list[Mapping[str, Any]], status: str) -> list[str]:
    names = []
    for row in rows:
        if row.get("status") != status:
            continue
        name = str(row.get("card_name") or "").strip()
        if name and name not in names:
            names.append(name)
    return names


def build_report(*, recovery_report: Path, alternative_forced_report: Path) -> dict[str, Any]:
    recovery_payload = load_json(recovery_report)
    forced_payload = load_json(alternative_forced_report)
    recovery_summary = recovery_payload.get("summary") or {}
    forced_summary = forced_payload.get("summary") or {}
    deck_id = str(recovery_payload.get("deck_id") or forced_payload.get("deck_id") or "")
    commander = str(recovery_payload.get("commander") or forced_payload.get("commander") or "")
    blocked_ramp_cut_count = as_int(recovery_summary.get("blocked_ramp_cut_count"))
    replacement_exact_ready_count = as_int(recovery_summary.get("replacement_exact_ready_count"))
    alternative_forced_usage_blocked_count = as_int(forced_summary.get("usage_blocked_count"))
    alternative_focus_card_count = as_int(forced_summary.get("focus_card_count"))
    current_ramp_lane_exhausted = bool(
        blocked_ramp_cut_count >= 9
        and replacement_exact_ready_count == 0
        and alternative_focus_card_count > 0
        and alternative_forced_usage_blocked_count >= alternative_focus_card_count
    )
    status = "ramp_axis_exhausted_requires_global_role_axis_pivot"
    next_gate = "return_to_global_role_axis_learning_priority_after_ramp_axis_exhaustion"
    if not current_ramp_lane_exhausted:
        status = "ramp_axis_exhaustion_not_proven"
        next_gate = "recheck_ramp_recovery_and_alternative_forced_access"
    blockers = [
        "candidate_copy_closed_after_ramp_axis_exhaustion_router",
        "battle_gate_closed_after_ramp_axis_exhaustion_router",
    ]
    if current_ramp_lane_exhausted:
        blockers.append("ramp_axis_current_cut_lane_exhausted")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_ramp_axis_exhaustion_router",
        "deck_id": deck_id,
        "commander": commander,
        "exhausted_role_axis": "ramp" if current_ramp_lane_exhausted else None,
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "ramp_forced_recovery_router": artifact_rel(recovery_report),
            "alternative_ramp_forced_access_trace_generator": artifact_rel(alternative_forced_report),
        },
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "blocked_ramp_cut_count": blocked_ramp_cut_count,
            "replacement_exact_ready_count": replacement_exact_ready_count,
            "alternative_focus_card_count": alternative_focus_card_count,
            "alternative_forced_usage_blocked_count": alternative_forced_usage_blocked_count,
            "current_ramp_lane_exhausted": current_ramp_lane_exhausted,
            "next_gate": next_gate,
        },
        "blocked_current_ramp_cuts": [row.get("card_name") for row in recovery_payload.get("blocked_cut_rows") or []],
        "blocked_alternative_ramp_cuts": blocked_names(
            forced_payload.get("review_rows") or [],
            "alternative_ramp_cut_forced_access_usage_observed_blocks_cut",
        ),
        "candidate_copy_blockers": blockers,
        "policy": {
            "axis_boundary": "An exhausted ramp axis is a learning route signal, not permission to cut cards.",
            "pivot_boundary": "The next step must return to global role-axis learning before more same-deck ramp source search.",
            "mutation_boundary": "No deck mutation, candidate copy, battle gate, or promotion is opened by this router.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Ramp Axis Exhaustion Router",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{payload['commander']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- exhausted_role_axis: `{payload['exhausted_role_axis']}`",
        f"- blocked_ramp_cut_count: `{summary['blocked_ramp_cut_count']}`",
        f"- replacement_exact_ready_count: `{summary['replacement_exact_ready_count']}`",
        f"- alternative_focus_card_count: `{summary['alternative_focus_card_count']}`",
        f"- alternative_forced_usage_blocked_count: `{summary['alternative_forced_usage_blocked_count']}`",
        f"- current_ramp_lane_exhausted: `{str(summary['current_ramp_lane_exhausted']).lower()}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Blocked Current Ramp Cuts",
        "",
    ]
    for name in payload["blocked_current_ramp_cuts"]:
        lines.append(f"- `{name}`")
    lines.extend(["", "## Blocked Alternative Ramp Cuts", ""])
    for name in payload["blocked_alternative_ramp_cuts"]:
        lines.append(f"- `{name}`")
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
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
    parser.add_argument("--recovery-report", type=Path, default=DEFAULT_RECOVERY_REPORT)
    parser.add_argument("--alternative-forced-report", type=Path, default=DEFAULT_ALTERNATIVE_FORCED_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        recovery_report=args.recovery_report,
        alternative_forced_report=args.alternative_forced_report,
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
