#!/usr/bin/env python3
"""Collect existing trace evidence for fresh Commander cut-source hypotheses."""

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
DEFAULT_MINER_REPORT = (
    REPORT_DIR / "global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_TRACE_GENERATOR_REPORT = (
    REPORT_DIR / "global_commander_contextual_usage_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_cut_source_hypothesis_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1"
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


def hypothesis_cards(miner_payload: Mapping[str, Any]) -> list[str]:
    cards: list[str] = []
    for row in miner_payload.get("fresh_cut_source_hypotheses") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            card = str(row["card_name"])
            if card not in cards:
                cards.append(card)
    return cards


def source_rows_by_card(miner_payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        str(row["card_name"]): dict(row)
        for row in miner_payload.get("fresh_cut_source_hypotheses") or []
        if isinstance(row, Mapping) and row.get("card_name")
    }


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


def classify_hypothesis(card: str, trace: Mapping[str, Any], source_row: Mapping[str, Any]) -> dict[str, Any]:
    usage = int(trace.get("usage_event_count") or 0)
    exposure = int(trace.get("exposure_event_count") or 0)
    decisions = int(trace.get("decision_trace_count") or 0)
    if usage > 0:
        status = "hypothesis_used_by_target_trace_blocks_value_safe"
        decision = "not_value_safe_from_existing_hypothesis_trace"
        next_evidence = "find_different_cut_or_same_lane_replacement_proof"
    elif exposure > 0 or decisions > 0:
        status = "hypothesis_seen_without_usage_needs_negative_review"
        decision = "manual_negative_trace_review_only"
        next_evidence = "explain_nonuse_or_force_access_before_reclassification"
    else:
        status = "hypothesis_not_seen_needs_more_trace_or_force_access"
        decision = "insufficient_existing_trace"
        next_evidence = "expand_replay_window_or_force_access_before_reclassification"
    return {
        "cut_card": card,
        "status": status,
        "decision": decision,
        "source_score": source_row.get("score") or 0,
        "source_reasons": source_row.get("reasons") or [],
        "profile_roles": source_row.get("profile_roles") or [],
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


def build_report(*, miner_report: Path, trace_generator_report: Path) -> dict[str, Any]:
    miner_payload = load_json(miner_report)
    trace_payload = load_json(trace_generator_report)
    miner_summary = miner_payload.get("summary") or {}
    trace_summary = trace_payload.get("summary") or {}
    commander = str(miner_summary.get("commander") or trace_summary.get("commander") or "")
    cards = hypothesis_cards(miner_payload)
    source_rows = source_rows_by_card(miner_payload)
    seed_rows, aggregate = collect_seed_reports(
        trace_generator_payload=trace_payload,
        card_names=cards,
        target_player=commander,
    )
    review_rows = [classify_hypothesis(card, aggregate[card], source_rows.get(card, {})) for card in cards]
    usage_blocked = [row["cut_card"] for row in review_rows if row["status"] == "hypothesis_used_by_target_trace_blocks_value_safe"]
    seen_without_usage = [row["cut_card"] for row in review_rows if row["status"] == "hypothesis_seen_without_usage_needs_negative_review"]
    not_seen = [row["cut_card"] for row in review_rows if row["status"] == "hypothesis_not_seen_needs_more_trace_or_force_access"]
    if usage_blocked:
        status = "cut_source_hypothesis_trace_blocks_used_hypotheses"
        next_gate = "mine_more_hypotheses_or_build_same_lane_proof"
    elif seen_without_usage:
        status = "cut_source_hypothesis_trace_needs_negative_review"
        next_gate = "manual_negative_trace_review_or_force_access_for_seen_hypotheses"
    else:
        status = "cut_source_hypothesis_trace_needs_more_replay"
        next_gate = "expand_replay_window_or_force_access_for_unseen_hypotheses"
    blockers = []
    if usage_blocked:
        blockers.append("hypothesis_cards_used_by_target_deck:" + ",".join(usage_blocked))
    if seen_without_usage:
        blockers.append("hypothesis_cards_seen_without_usage:" + ",".join(seen_without_usage))
    if not_seen:
        blockers.append("hypothesis_cards_not_seen:" + ",".join(not_seen))
    blockers.append("candidate_copy_closed_until_hypothesis_has_negative_or_same_lane_proof")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_cut_source_hypothesis_trace_collector",
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
            "trace_generator_report": rel(trace_generator_report),
        },
        "summary": {
            "deck_id": str(miner_summary.get("deck_id") or trace_summary.get("deck_id") or ""),
            "commander": commander,
            "hypothesis_count": len(cards),
            "usage_blocked_hypothesis_count": len(usage_blocked),
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
            "usage_boundary": "A hypothesis used by the target deck is not value-safe from this trace.",
            "unseen_boundary": "No exposure in existing traces is insufficient proof; force-access or broader replay is required.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Cut-Source Hypothesis Trace Collector",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- hypothesis_count: `{summary['hypothesis_count']}`",
        f"- usage_blocked_hypothesis_count: `{summary['usage_blocked_hypothesis_count']}`",
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
    parser.add_argument("--miner-report", type=Path, default=DEFAULT_MINER_REPORT)
    parser.add_argument("--trace-generator-report", type=Path, default=DEFAULT_TRACE_GENERATOR_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(miner_report=args.miner_report, trace_generator_report=args.trace_generator_report)
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
