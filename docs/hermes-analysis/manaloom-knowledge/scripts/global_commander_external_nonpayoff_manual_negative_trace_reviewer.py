#!/usr/bin/env python3
"""Manually review seen-without-usage external nonpayoff current-deck cards.

This read-only gate follows
``global_commander_external_nonpayoff_current_deck_negative_review_collector``
when current-deck candidates are seen without usage. It inspects the source row
and current trace summary to prevent passive/static cards or lands from being
treated as cuttable merely because no explicit usage event was emitted.
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
DEFAULT_NEGATIVE_REVIEW_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_current_deck_negative_review_collector_20260706_kaalia_value_safe_stage1_live_research.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_manual_negative_trace_reviewer_20260706_kaalia_value_safe_stage1_live_research"
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def resolve_path(value: object) -> Path:
    path = Path(str(value or ""))
    return path if path.is_absolute() else REPO_ROOT / path


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def source_rows_by_card(router_payload: Mapping[str, Any]) -> dict[str, Mapping[str, Any]]:
    return {
        str(row.get("card_name") or ""): row
        for row in router_payload.get("current_deck_negative_review_rows") or []
        if isinstance(row, Mapping) and row.get("card_name")
    }


def source_router_path(negative_payload: Mapping[str, Any]) -> Path | None:
    inputs = negative_payload.get("input_artifacts") or {}
    raw = inputs.get("recovery_router_report")
    if not raw:
        return None
    return resolve_path(raw)


def has_static_silence_effect(source_row: Mapping[str, Any]) -> bool:
    text = " ".join(
        [
            str(source_row.get("type_line") or ""),
            " ".join(str(item) for item in source_row.get("local_role_evidence_terms") or []),
            str(source_row.get("candidate_signal") or ""),
        ]
    ).lower()
    return "can't cast spells" in text and ("creature" in text or "opponents" in text)


def has_land_lane_signal(source_row: Mapping[str, Any], review_row: Mapping[str, Any]) -> bool:
    type_line = str(source_row.get("type_line") or "").lower()
    event_types = review_row.get("event_types") or {}
    return "land" in type_line or int(event_types.get("land_played") or 0) > 0


def classify_review(row: Mapping[str, Any], source_row: Mapping[str, Any]) -> dict[str, Any]:
    card_name = str(row.get("card_name") or "")
    usage = int(row.get("usage_event_count") or 0)
    exposure = int(row.get("exposure_event_count") or 0)
    decisions = int(row.get("decision_trace_count") or 0)
    if usage:
        status = "manual_negative_trace_review_blocks_used_current_deck_card"
        decision = "not_cuttable_from_current_trace"
        reason = "Target-deck usage was observed, so negative review cannot clear this card."
    elif has_land_lane_signal(source_row, row):
        status = "manual_negative_trace_review_blocks_land_lane_seen_without_usage"
        decision = "land_seen_without_explicit_mode_use_is_not_cut_proof"
        reason = "A land or land-lane card can carry mana/color/haste value without an explicit usage event."
    elif has_static_silence_effect(source_row):
        status = "manual_negative_trace_review_blocks_static_silence_without_activation"
        decision = "passive_static_effect_needs_stronger_negative_evidence"
        reason = "Static silence effects do not require an activation/cast event after they are on board."
    elif exposure or decisions:
        status = "manual_negative_trace_review_requires_forced_or_broader_context"
        decision = "seen_without_usage_is_weak_negative_evidence"
        reason = "The card was seen but current trace lacks enough context to prove it is safely cuttable."
    else:
        status = "manual_negative_trace_review_requires_force_access"
        decision = "unseen_in_current_trace"
        reason = "The card was not meaningfully exposed in current traces."
    return {
        "card_name": card_name,
        "target_cut_role": row.get("target_cut_role"),
        "collector_status": row.get("status"),
        "manual_review_status": status,
        "decision": decision,
        "reason": reason,
        "usage_event_count": usage,
        "exposure_event_count": exposure,
        "decision_trace_count": decisions,
        "event_types": row.get("event_types") or {},
        "source_type_line": source_row.get("type_line"),
        "source_role_terms": source_row.get("local_role_evidence_terms") or [],
        "first_usage_event": row.get("first_usage_event"),
        "first_exposure_event": row.get("first_exposure_event"),
        "first_decision_trace": row.get("first_decision_trace"),
        "manual_negative_review_cleared_now": False,
        "card_level_cut_permission_now": False,
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
    }


def choose_status(review_rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    if not review_rows:
        return (
            "external_nonpayoff_manual_negative_trace_review_blocks_no_candidates",
            "expand_external_nonpayoff_source_candidate_pool",
        )
    return (
        "external_nonpayoff_manual_negative_trace_review_blocks_current_deck_cuts",
        "find_new_external_source_or_explicit_same_lane_replacement_proof",
    )


def build_report(*, negative_review_report: Path) -> dict[str, Any]:
    negative_payload = load_json(negative_review_report)
    router_path = source_router_path(negative_payload)
    router_payload = load_json(router_path) if router_path and router_path.exists() else {}
    source_rows = source_rows_by_card(router_payload)
    review_rows = [
        classify_review(row, source_rows.get(str(row.get("card_name") or ""), {}))
        for row in negative_payload.get("review_rows") or []
        if isinstance(row, Mapping)
    ]
    status, next_gate = choose_status(review_rows)
    cleared = [row for row in review_rows if row.get("manual_negative_review_cleared_now")]
    used_blocked = [
        row for row in review_rows if row.get("manual_review_status") == "manual_negative_trace_review_blocks_used_current_deck_card"
    ]
    passive_blocked = [
        row for row in review_rows if row.get("manual_review_status") == "manual_negative_trace_review_blocks_static_silence_without_activation"
    ]
    land_blocked = [
        row for row in review_rows if row.get("manual_review_status") == "manual_negative_trace_review_blocks_land_lane_seen_without_usage"
    ]
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_nonpayoff_manual_negative_trace_reviewer",
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
        "card_level_cut_permission_now": False,
        "manual_negative_review_cleared_now": False,
        "input_artifacts": {
            "negative_review_report": rel(negative_review_report),
            "recovery_router_report": rel(router_path) if router_path else "",
        },
        "summary": {
            "deck_id": str((negative_payload.get("summary") or {}).get("deck_id") or ""),
            "commander": str((negative_payload.get("summary") or {}).get("commander") or ""),
            "manual_review_candidate_count": len(review_rows),
            "manual_negative_review_cleared_count": len(cleared),
            "used_blocked_count": len(used_blocked),
            "static_silence_blocked_count": len(passive_blocked),
            "land_lane_blocked_count": len(land_blocked),
            "candidate_copy_allowed_count": 0,
            "card_level_cut_permission_count": 0,
            "next_gate": next_gate,
        },
        "review_rows": review_rows,
        "candidate_copy_blockers": [
            "manual_negative_review_cleared_no_current_deck_cards",
            "static_or_land_seen_without_usage_is_not_cut_permission",
            "candidate_copy_closed_until_fresh_cut_source_or_explicit_same_lane_replacement_exists",
        ],
        "policy": {
            "manual_review_boundary": "Manual negative trace review can block weak cut evidence but does not create add/cut permission.",
            "static_effect_boundary": "Passive or static effects require stronger negative evidence than lack of activation logs.",
            "land_lane_boundary": "Land play and mana-base context must route through mana-base review, not generic nonuse.",
            "mutation_boundary": "This reviewer does not copy decks, mutate DBs, run battles, reclassify cuts, or promote packages.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff Manual Negative Trace Reviewer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- manual_review_candidate_count: `{summary['manual_review_candidate_count']}`",
        f"- manual_negative_review_cleared_count: `{summary['manual_negative_review_cleared_count']}`",
        f"- used_blocked_count: `{summary['used_blocked_count']}`",
        f"- static_silence_blocked_count: `{summary['static_silence_blocked_count']}`",
        f"- land_lane_blocked_count: `{summary['land_lane_blocked_count']}`",
        f"- candidate_copy_allowed_count: `{summary['candidate_copy_allowed_count']}`",
        f"- card_level_cut_permission_count: `{summary['card_level_cut_permission_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Manual Review Rows",
        "",
        "| Card | Role | Manual Status | Usage | Exposure | Decisions | Reason |",
        "| --- | --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in payload["review_rows"]:
        reason = str(row.get("reason") or "").replace("|", "/")
        lines.append(
            "| `{card}` | `{role}` | `{status}` | {usage} | {exposure} | {decisions} | {reason} |".format(
                card=row.get("card_name"),
                role=row.get("target_cut_role"),
                status=row.get("manual_review_status"),
                usage=row.get("usage_event_count"),
                exposure=row.get("exposure_event_count"),
                decisions=row.get("decision_trace_count"),
                reason=reason,
            )
        )
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
    parser.add_argument("--negative-review-report", type=Path, default=DEFAULT_NEGATIVE_REVIEW_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(negative_review_report=args.negative_review_report)
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
