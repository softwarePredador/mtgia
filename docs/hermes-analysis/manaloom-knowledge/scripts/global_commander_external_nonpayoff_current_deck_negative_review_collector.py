#!/usr/bin/env python3
"""Collect negative-review traces for external candidates already in deck.

This gate follows
``global_commander_external_nonpayoff_seed_exhaustion_recovery_router.py``.
It reuses existing current-scope replay artifacts for external nonpayoff
candidates that are already in the current deck. Use blocks cut consideration;
seen-without-use needs manual negative review; unseen needs force access or a
broader replay window. No deck action is opened here.
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
DEFAULT_RECOVERY_ROUTER_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_TRACE_GENERATOR_REPORT = (
    REPORT_DIR / "global_commander_contextual_usage_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_current_deck_negative_review_collector_20260705_kaalia_value_safe_stage1_repair_scope1"
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


def target_rows(router_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [
        dict(row)
        for row in router_payload.get("current_deck_negative_review_rows") or []
        if isinstance(row, Mapping) and row.get("card_name")
    ]
    rows.sort(key=lambda row: (str(row.get("target_cut_role") or ""), str(row.get("card_name") or "")))
    return rows


def unique_cards(rows: list[Mapping[str, Any]]) -> list[str]:
    cards: list[str] = []
    seen: set[str] = set()
    for row in rows:
        card = str(row.get("card_name") or "").strip()
        key = card.lower()
        if card and key not in seen:
            seen.add(key)
            cards.append(card)
    return cards


def empty_card_summary(cards: list[str]) -> dict[str, dict[str, Any]]:
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
    event_types = target.setdefault("event_types", {})
    for event, count in (source.get("event_types") or {}).items():
        event_types[str(event)] = int(event_types.get(str(event)) or 0) + int(count or 0)
    for key in ("first_usage_event", "first_exposure_event", "first_decision_trace"):
        if target.get(key) is None and source.get(key) is not None:
            target[key] = source.get(key)


def collect_trace_summaries(
    *,
    trace_generator_payload: Mapping[str, Any],
    card_names: list[str],
    target_player: str,
) -> tuple[list[dict[str, Any]], dict[str, dict[str, Any]]]:
    aggregate = empty_card_summary(card_names)
    seed_rows: list[dict[str, Any]] = []
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


def source_rows_by_card(rows: list[Mapping[str, Any]]) -> dict[str, dict[str, Any]]:
    return {str(row.get("card_name") or ""): dict(row) for row in rows if row.get("card_name")}


def classify_candidate(card: str, trace: Mapping[str, Any], source_row: Mapping[str, Any]) -> dict[str, Any]:
    usage = int(trace.get("usage_event_count") or 0)
    exposure = int(trace.get("exposure_event_count") or 0)
    decisions = int(trace.get("decision_trace_count") or 0)
    if usage:
        status = "external_current_deck_candidate_used_by_target_blocks_negative_review"
        decision = "not_cuttable_from_current_trace"
        next_evidence = "find_new_external_source_or_explicit_same_lane_replacement_proof"
    elif exposure or decisions:
        status = "external_current_deck_candidate_seen_without_usage_needs_manual_negative_review"
        decision = "manual_negative_trace_review_required"
        next_evidence = "inspect_current_trace_nonuse_context_before_cut_consideration"
    else:
        status = "external_current_deck_candidate_not_seen_needs_force_access_or_broader_trace"
        decision = "insufficient_current_trace"
        next_evidence = "force_access_or_expand_replay_window_before_negative_review"
    return {
        "card_name": card,
        "target_cut_role": source_row.get("target_cut_role"),
        "status": status,
        "decision": decision,
        "source_review_status": source_row.get("review_status"),
        "usage_event_count": usage,
        "exposure_event_count": exposure,
        "decision_trace_count": decisions,
        "event_types": trace.get("event_types") or {},
        "first_usage_event": trace.get("first_usage_event"),
        "first_exposure_event": trace.get("first_exposure_event"),
        "first_decision_trace": trace.get("first_decision_trace"),
        "next_evidence": next_evidence,
        "card_level_cut_permission_now": False,
        "negative_review_cleared_now": False,
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
    }


def choose_status_and_next_gate(review_rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    if not review_rows:
        return (
            "external_current_deck_negative_review_blocks_no_candidates",
            "expand_external_nonpayoff_source_candidate_pool",
        )
    if any(row["status"] == "external_current_deck_candidate_used_by_target_blocks_negative_review" for row in review_rows):
        return (
            "external_current_deck_negative_review_blocks_used_candidates",
            "find_new_external_source_or_explicit_same_lane_replacement_proof",
        )
    if any(row["status"] == "external_current_deck_candidate_seen_without_usage_needs_manual_negative_review" for row in review_rows):
        return (
            "external_current_deck_negative_review_needs_manual_review",
            "manual_negative_trace_review_for_seen_external_candidates",
        )
    return (
        "external_current_deck_negative_review_needs_force_access",
        "force_access_or_expand_replay_window_for_external_current_deck_candidates",
    )


def build_report(*, recovery_router_report: Path, trace_generator_report: Path) -> dict[str, Any]:
    router_payload = load_json(recovery_router_report)
    trace_payload = load_json(trace_generator_report)
    router_summary = router_payload.get("summary") or {}
    trace_summary = trace_payload.get("summary") or {}
    commander = str(router_summary.get("commander") or trace_summary.get("commander") or "")
    rows = target_rows(router_payload)
    cards = unique_cards(rows)
    source_rows = source_rows_by_card(rows)
    seed_reports, aggregate = collect_trace_summaries(
        trace_generator_payload=trace_payload,
        card_names=cards,
        target_player=commander,
    )
    review_rows = [classify_candidate(card, aggregate[card], source_rows.get(card, {})) for card in cards]
    used = [row["card_name"] for row in review_rows if row["status"] == "external_current_deck_candidate_used_by_target_blocks_negative_review"]
    seen = [row["card_name"] for row in review_rows if row["status"] == "external_current_deck_candidate_seen_without_usage_needs_manual_negative_review"]
    unseen = [row["card_name"] for row in review_rows if row["status"] == "external_current_deck_candidate_not_seen_needs_force_access_or_broader_trace"]
    status, next_gate = choose_status_and_next_gate(review_rows)
    blockers = []
    if used:
        blockers.append("external_current_deck_candidates_used_by_target:" + ",".join(used))
    if seen:
        blockers.append("external_current_deck_candidates_seen_need_manual_review:" + ",".join(seen))
    if unseen:
        blockers.append("external_current_deck_candidates_unseen_need_force_access:" + ",".join(unseen))
    blockers.append("candidate_copy_closed_until_negative_review_or_fresh_cut_source_exists")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_nonpayoff_current_deck_negative_review_collector",
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
        "negative_review_cleared_now": False,
        "input_artifacts": {
            "recovery_router_report": rel(recovery_router_report),
            "trace_generator_report": rel(trace_generator_report),
        },
        "summary": {
            "deck_id": str(router_summary.get("deck_id") or trace_summary.get("deck_id") or ""),
            "commander": commander,
            "current_deck_candidate_count": len(cards),
            "usage_blocked_candidate_count": len(used),
            "seen_without_usage_count": len(seen),
            "not_seen_count": len(unseen),
            "seed_report_count": len(seed_reports),
            "card_level_cut_permission_count": 0,
            "negative_review_cleared_count": 0,
            "candidate_copy_allowed_count": 0,
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "review_rows": review_rows,
        "seed_reports": seed_reports,
        "policy": {
            "negative_review_boundary": "A current-deck external candidate must not be treated as cuttable when target-deck use is observed.",
            "trace_boundary": "This collector reuses existing current-scope replay artifacts and does not run a battle gate.",
            "promotion_boundary": "No candidate copy, deck mutation, battle gate, value-safe reclassification, or promotion is opened by this report.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff Current Deck Negative Review Collector",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- current_deck_candidate_count: `{summary['current_deck_candidate_count']}`",
        f"- usage_blocked_candidate_count: `{summary['usage_blocked_candidate_count']}`",
        f"- seen_without_usage_count: `{summary['seen_without_usage_count']}`",
        f"- not_seen_count: `{summary['not_seen_count']}`",
        f"- seed_report_count: `{summary['seed_report_count']}`",
        f"- card_level_cut_permission_count: `{summary['card_level_cut_permission_count']}`",
        f"- negative_review_cleared_count: `{summary['negative_review_cleared_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Review Rows",
        "",
        "| Card | Role | Status | Usage | Exposure | Decisions | Next Evidence |",
        "| --- | --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in payload["review_rows"]:
        lines.append(
            "| `{card}` | `{role}` | `{status}` | {usage} | {exposure} | {decisions} | `{next}` |".format(
                card=row.get("card_name"),
                role=row.get("target_cut_role"),
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
    parser.add_argument("--recovery-router-report", type=Path, default=DEFAULT_RECOVERY_ROUTER_REPORT)
    parser.add_argument("--trace-generator-report", type=Path, default=DEFAULT_TRACE_GENERATOR_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        recovery_router_report=args.recovery_router_report,
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
