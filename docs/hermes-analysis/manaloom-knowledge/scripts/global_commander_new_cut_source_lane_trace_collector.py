#!/usr/bin/env python3
"""Collect trace evidence for remaining cut-source-lane candidates.

This read-only gate runs after the same-lane replacement model routes away from
usage-blocked contextual cuts. It reuses existing replay artifacts to check the
remaining stage-only cut-source cards before any new candidate copy or battle
gate is opened.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_contextual_usage_trace_generator import summarize_trace_files
from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_SAME_LANE_REPLACEMENT_MODEL = (
    REPORT_DIR / "global_commander_same_lane_replacement_model_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_TRACE_GENERATOR_REPORT = (
    REPORT_DIR / "global_commander_contextual_usage_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_new_cut_source_lane_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1"
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


def remaining_cards(payload: Mapping[str, Any]) -> list[str]:
    cards = []
    for row in payload.get("remaining_cut_source_lane_rows") or []:
        if isinstance(row, Mapping) and row.get("cut_card"):
            cards.append(str(row["cut_card"]))
    return cards


def empty_summary(cards: list[str]) -> dict[str, dict[str, Any]]:
    return {
        card: {
            "usage_event_count": 0,
            "exposure_event_count": 0,
            "decision_trace_count": 0,
            "reference_event_count": 0,
            "event_types": {},
            "first_usage_event": None,
            "first_exposure_event": None,
            "first_decision_trace": None,
        }
        for card in cards
    }


def merge_card_summary(target: dict[str, Any], source: Mapping[str, Any]) -> None:
    for key in ("usage_event_count", "exposure_event_count", "decision_trace_count", "reference_event_count"):
        target[key] = int(target.get(key) or 0) + int(source.get(key) or 0)
    target_events = target.setdefault("event_types", {})
    for event, count in (source.get("event_types") or {}).items():
        target_events[str(event)] = int(target_events.get(str(event)) or 0) + int(count or 0)
    for key in ("first_usage_event", "first_exposure_event", "first_decision_trace"):
        if target.get(key) is None and source.get(key) is not None:
            target[key] = source.get(key)


def collect_seed_reports(
    *,
    trace_generator_payload: Mapping[str, Any],
    card_names: list[str],
    target_player: str,
) -> tuple[list[dict[str, Any]], dict[str, dict[str, Any]]]:
    aggregate = empty_summary(card_names)
    seed_rows = []
    for row in trace_generator_payload.get("seed_reports") or []:
        if not isinstance(row, Mapping):
            continue
        events_path = resolve_path(row.get("events_path"))
        decisions_path = resolve_path(row.get("decisions_path"))
        summary = summarize_trace_files(
            events_path=events_path,
            decisions_path=decisions_path,
            card_names=card_names,
            target_player=target_player,
        )
        for card, card_summary in summary["cards"].items():
            merge_card_summary(aggregate[card], card_summary)
        seed_rows.append(
            {
                "seed": row.get("seed"),
                "events_path": rel(events_path),
                "decisions_path": rel(decisions_path),
                "event_count": summary["event_count"],
                "decision_count": summary["decision_count"],
                "cards": summary["cards"],
            }
        )
    return seed_rows, aggregate


def review_card_trace(card: str, trace: Mapping[str, Any], source_row: Mapping[str, Any]) -> dict[str, Any]:
    usage = int(trace.get("usage_event_count") or 0)
    exposure = int(trace.get("exposure_event_count") or 0)
    decisions = int(trace.get("decision_trace_count") or 0)
    if usage > 0:
        status = "remaining_cut_used_by_target_trace_blocks_value_safe"
        decision = "not_value_safe_from_existing_remaining_cut_trace"
        next_evidence = "find_different_cut_or_same_lane_replacement_proof"
    elif exposure > 0 or decisions > 0:
        status = "remaining_cut_seen_without_usage_needs_negative_review"
        decision = "manual_negative_trace_review_only"
        next_evidence = "explain_nonuse_or_force_access_before_reclassification"
    else:
        status = "remaining_cut_not_seen_needs_forced_access_or_more_trace"
        decision = "insufficient_existing_trace"
        next_evidence = "force_access_or_expand_replay_window_before_reclassification"
    return {
        "cut_card": card,
        "status": status,
        "decision": decision,
        "cut_roles": source_row.get("cut_roles") or [],
        "recommended_next_route": source_row.get("recommended_next_route"),
        "maximum_evidence_burden": source_row.get("maximum_evidence_burden"),
        "usage_event_count": usage,
        "exposure_event_count": exposure,
        "decision_trace_count": decisions,
        "event_types": trace.get("event_types") or {},
        "first_usage_event": trace.get("first_usage_event"),
        "first_exposure_event": trace.get("first_exposure_event"),
        "first_decision_trace": trace.get("first_decision_trace"),
        "next_evidence": next_evidence,
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
    }


def source_rows_by_card(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        str(row["cut_card"]): dict(row)
        for row in payload.get("remaining_cut_source_lane_rows") or []
        if isinstance(row, Mapping) and row.get("cut_card")
    }


def build_report(*, same_lane_model_report: Path, trace_generator_report: Path) -> dict[str, Any]:
    model_payload = load_json(same_lane_model_report)
    trace_payload = load_json(trace_generator_report)
    summary = model_payload.get("summary") or {}
    target_player = str(summary.get("commander") or (trace_payload.get("summary") or {}).get("commander") or "")
    cards = remaining_cards(model_payload)
    source_rows = source_rows_by_card(model_payload)
    seed_rows, aggregate = collect_seed_reports(
        trace_generator_payload=trace_payload,
        card_names=cards,
        target_player=target_player,
    )
    review_rows = [review_card_trace(card, aggregate[card], source_rows.get(card, {})) for card in cards]
    usage_blocked = [row["cut_card"] for row in review_rows if row["status"] == "remaining_cut_used_by_target_trace_blocks_value_safe"]
    seen_without_usage = [
        row["cut_card"] for row in review_rows if row["status"] == "remaining_cut_seen_without_usage_needs_negative_review"
    ]
    not_seen = [row["cut_card"] for row in review_rows if row["status"] == "remaining_cut_not_seen_needs_forced_access_or_more_trace"]
    if usage_blocked:
        status = "new_cut_source_lane_trace_blocks_used_remaining_cuts"
    elif seen_without_usage:
        status = "new_cut_source_lane_trace_needs_negative_review"
    else:
        status = "new_cut_source_lane_trace_needs_more_replay"
    next_gate = "force_access_or_expand_cut_source_lane_for_unresolved_remaining_cuts"
    blockers = []
    if usage_blocked:
        blockers.append("remaining_cut_cards_used_by_target_deck:" + ",".join(usage_blocked))
    if seen_without_usage:
        blockers.append("remaining_cut_cards_seen_without_usage:" + ",".join(seen_without_usage))
    if not_seen:
        blockers.append("remaining_cut_cards_not_seen:" + ",".join(not_seen))
    blockers.append("candidate_copy_closed_until_cut_source_lane_has_value_safe_or_proven_same_lane_cut")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_new_cut_source_lane_trace_collector",
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
            "same_lane_model_report": rel(same_lane_model_report),
            "trace_generator_report": rel(trace_generator_report),
        },
        "summary": {
            "deck_id": str(summary.get("deck_id") or ""),
            "commander": target_player,
            "remaining_cut_source_count": len(cards),
            "usage_blocked_remaining_cut_count": len(usage_blocked),
            "seen_without_usage_count": len(seen_without_usage),
            "not_seen_count": len(not_seen),
            "seed_report_count": len(seed_rows),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "review_rows": review_rows,
        "seed_reports": seed_rows,
        "policy": {
            "reuse_boundary": "This collector reuses existing replay artifacts and does not run a new battle.",
            "usage_boundary": "A remaining cut used by the target deck is not value-safe from this trace.",
            "unseen_boundary": "No exposure in existing traces is insufficient proof; force-access or broader replay is required.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander New Cut Source Lane Trace Collector",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- remaining_cut_source_count: `{summary['remaining_cut_source_count']}`",
        f"- usage_blocked_remaining_cut_count: `{summary['usage_blocked_remaining_cut_count']}`",
        f"- seen_without_usage_count: `{summary['seen_without_usage_count']}`",
        f"- not_seen_count: `{summary['not_seen_count']}`",
        f"- seed_report_count: `{summary['seed_report_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Review Rows",
        "",
        "| Cut | Status | Usage | Exposure | Decisions | Next Evidence |",
        "| --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in payload["review_rows"]:
        lines.append(
            "| `{cut}` | `{status}` | {usage} | {exposure} | {decisions} | `{next}` |".format(
                cut=row.get("cut_card"),
                status=row.get("status"),
                usage=row.get("usage_event_count"),
                exposure=row.get("exposure_event_count"),
                decisions=row.get("decision_trace_count"),
                next=row.get("next_evidence"),
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
    parser.add_argument("--same-lane-model-report", type=Path, default=DEFAULT_SAME_LANE_REPLACEMENT_MODEL)
    parser.add_argument("--trace-generator-report", type=Path, default=DEFAULT_TRACE_GENERATOR_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        same_lane_model_report=args.same_lane_model_report,
        trace_generator_report=args.trace_generator_report,
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
