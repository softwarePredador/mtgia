#!/usr/bin/env python3
"""Review generated usage traces before contextual cut reclassification.

This read-only gate consumes generated current-scope usage traces for
contextual stage-only cuts. A card that was used by the target deck is not a
value-safe cut by trace alone; it needs same-lane replacement proof or a stronger
negative/neutral trace review before any candidate copy can open.
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
DEFAULT_TRACE_GENERATOR = (
    REPORT_DIR / "global_commander_contextual_usage_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_contextual_usage_trace_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1"
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


def card_rows(generator_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    aggregate = generator_payload.get("aggregate_card_trace") or {}
    for card_name, trace in aggregate.items():
        if isinstance(trace, Mapping):
            rows.append({"card_name": str(card_name), **dict(trace)})
    return rows


def review_card(row: Mapping[str, Any]) -> dict[str, Any]:
    usage = int(row.get("usage_event_count") or 0)
    exposure = int(row.get("exposure_event_count") or 0)
    decisions = int(row.get("decision_trace_count") or 0)
    if usage > 0:
        status = "usage_observed_blocks_value_safe_reclassification"
        decision = "not_value_safe_from_current_trace"
        requirements = [
            "same_lane_replacement_proof",
            "strategy_matrix_recheck_after_replacement",
            "battle_or_replay_gate_if_replacement_is_material",
        ]
    elif exposure > 0 or decisions > 0:
        status = "seen_without_usage_needs_negative_trace_review"
        decision = "manual_review_only_no_reclassification"
        requirements = [
            "explain_nonuse_context",
            "confirm role floor preserved",
            "collect_additional_seed_or_same_lane_trace",
        ]
    else:
        status = "not_seen_needs_more_trace_before_reclassification"
        decision = "insufficient_evidence"
        requirements = ["increase_seed_count_or_force_access_trace"]
    return {
        "card_name": row.get("card_name"),
        "status": status,
        "decision": decision,
        "usage_event_count": usage,
        "exposure_event_count": exposure,
        "decision_trace_count": decisions,
        "event_types": row.get("event_types") or {},
        "first_usage_event": row.get("first_usage_event"),
        "first_exposure_event": row.get("first_exposure_event"),
        "first_decision_trace": row.get("first_decision_trace"),
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
        "required_next_evidence": requirements,
    }


def build_report(*, trace_generator_report: Path) -> dict[str, Any]:
    generator_payload = load_json(trace_generator_report)
    summary = generator_payload.get("summary") or {}
    reviewed = [review_card(row) for row in card_rows(generator_payload)]
    usage_blocked = [
        row["card_name"]
        for row in reviewed
        if row["status"] == "usage_observed_blocks_value_safe_reclassification"
    ]
    not_seen = [row["card_name"] for row in reviewed if row["status"] == "not_seen_needs_more_trace_before_reclassification"]
    if usage_blocked:
        status = "contextual_usage_trace_review_blocks_value_safe_reclassification"
        next_gate = "find_new_cut_source_lane_or_same_lane_replacement_proof_before_candidate_copy"
    elif not_seen:
        status = "contextual_usage_trace_review_needs_more_trace"
        next_gate = "increase_seed_count_or_force_access_trace_for_contextual_cards"
    else:
        status = "contextual_usage_trace_review_manual_negative_trace_review_required"
        next_gate = "manual_negative_trace_review_before_reclassification"
    blockers = []
    if usage_blocked:
        blockers.append("contextual_cards_used_by_target_deck:" + ",".join(usage_blocked))
    if not_seen:
        blockers.append("contextual_cards_not_seen_in_generated_trace:" + ",".join(not_seen))
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_contextual_usage_trace_reviewer",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "input_artifacts": {"trace_generator_report": rel(trace_generator_report)},
        "summary": {
            "deck_id": str(summary.get("deck_id") or ""),
            "commander": str(summary.get("commander") or ""),
            "reviewed_card_count": len(reviewed),
            "usage_blocked_card_count": len(usage_blocked),
            "usage_blocked_cards": usage_blocked,
            "not_seen_card_count": len(not_seen),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "review_rows": reviewed,
        "policy": {
            "usage_boundary": "Observed use by the target deck is evidence against automatic value-safe cutting.",
            "replacement_boundary": "A used contextual staple needs same-lane replacement proof before any reclassification.",
            "battle_boundary": "This reviewer does not open battle or promotion gates.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Contextual Usage Trace Reviewer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- reviewed_card_count: `{summary['reviewed_card_count']}`",
        f"- usage_blocked_card_count: `{summary['usage_blocked_card_count']}`",
        f"- not_seen_card_count: `{summary['not_seen_card_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Review Rows",
        "",
        "| Card | Status | Usage | Exposure | Decisions | Decision |",
        "| --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in payload["review_rows"]:
        lines.append(
            "| `{card}` | `{status}` | {usage} | {exposure} | {decisions} | `{decision}` |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                usage=row.get("usage_event_count"),
                exposure=row.get("exposure_event_count"),
                decisions=row.get("decision_trace_count"),
                decision=row.get("decision"),
            )
        )
    lines.extend(["", "## Blockers", ""])
    if payload["candidate_copy_blockers"]:
        for blocker in payload["candidate_copy_blockers"]:
            lines.append(f"- `{blocker}`")
    else:
        lines.append("- none")
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
    parser.add_argument("--trace-generator-report", type=Path, default=DEFAULT_TRACE_GENERATOR)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(trace_generator_report=args.trace_generator_report)
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
