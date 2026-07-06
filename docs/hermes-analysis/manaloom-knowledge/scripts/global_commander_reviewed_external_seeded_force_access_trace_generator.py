#!/usr/bin/env python3
"""Generate forced-access traces for reviewed external seeded hypotheses.

This diagnostic gate follows
``global_commander_reviewed_external_seeded_cut_trace_collector.py``. It only
targets seeded cut hypotheses that were not seen in the existing replay window.
Forced access is diagnostic evidence: it can show visibility and use, but it
does not open card-level cut permission, candidate copy, battle, promotion, or
value-safe reclassification.
"""

from __future__ import annotations

import argparse
import json
import subprocess
from collections.abc import Mapping
from pathlib import Path
from typing import Any, Callable

from global_commander_contextual_usage_trace_generator import summarize_trace_files
from global_commander_deck_contract_audit import REPO_ROOT
from global_commander_forced_cut_access_trace_generator import (
    empty_card_summary,
    forced_access_summary,
    load_json,
    merge_card_summary,
    merge_forced_summary,
    rel,
    run_forced_replay_seed,
    utc_now,
)


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_SEEDED_TRACE_COLLECTOR_REPORT = (
    REPORT_DIR
    / "global_commander_reviewed_external_seeded_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_TRACE_GENERATOR_REPORT = (
    REPORT_DIR / "global_commander_contextual_usage_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_REPLAY_DIR = (
    REPORT_DIR
    / "global_commander_reviewed_external_seeded_force_access_replays_20260705_kaalia_value_safe_stage1_repair_scope1"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_reviewed_external_seeded_force_access_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1"
)
UNSEEN_STATUS = "reviewed_seeded_cut_hypothesis_not_seen_needs_force_access_or_broader_trace"


def resolve_optional_input(inputs: Mapping[str, Any], key: str) -> Path | None:
    value = str(inputs.get(key) or "").strip()
    if not value:
        return None
    path = Path(value)
    return path if path.is_absolute() else REPO_ROOT / path


def focus_hypothesis_rows(trace_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [
        dict(row)
        for row in trace_payload.get("review_rows") or []
        if isinstance(row, Mapping) and row.get("cut_card") and row.get("status") == UNSEEN_STATUS
    ]
    rows.sort(key=lambda row: (-int(row.get("source_score") or 0), str(row.get("cut_card") or "")))
    return rows


def unique_cards(rows: list[Mapping[str, Any]]) -> list[str]:
    cards: list[str] = []
    seen: set[str] = set()
    for row in rows:
        card = str(row.get("cut_card") or "").strip()
        key = card.lower()
        if card and key not in seen:
            seen.add(key)
            cards.append(card)
    return cards


def source_rows_by_card(rows: list[Mapping[str, Any]]) -> dict[str, dict[str, Any]]:
    return {str(row.get("cut_card") or ""): dict(row) for row in rows if row.get("cut_card")}


def forced_empty_summary(cards: list[str]) -> dict[str, dict[str, Any]]:
    return {
        card: {
            "moved_count": 0,
            "already_in_hand_count": 0,
            "not_found_count": 0,
            "first_event": None,
            "statuses": {},
        }
        for card in cards
    }


def classify_seeded_forced_access(
    *,
    card: str,
    trace: Mapping[str, Any],
    forced: Mapping[str, Any],
    source_row: Mapping[str, Any],
    missing_inputs: list[str],
) -> dict[str, Any]:
    usage = int(trace.get("usage_event_count") or 0)
    exposure = int(trace.get("exposure_event_count") or 0)
    decisions = int(trace.get("decision_trace_count") or 0)
    moved = int(forced.get("moved_count") or 0) + int(forced.get("already_in_hand_count") or 0)
    not_found = int(forced.get("not_found_count") or 0)
    if missing_inputs:
        status = "reviewed_seeded_forced_access_input_missing_blocks_trace"
        decision = "regenerate_or_restore_isolated_trace_inputs"
        next_gate = "regenerate_isolated_candidate_db_before_seeded_force_access"
    elif usage > 0:
        status = "reviewed_seeded_forced_access_usage_observed_blocks_cut"
        decision = "not_value_safe_after_forced_access_usage"
        next_gate = "map_forced_usage_block_to_policy_or_find_new_same_lane_cut_source"
    elif moved > 0 and (exposure > 0 or decisions > 0):
        status = "reviewed_seeded_forced_access_seen_without_usage_needs_manual_negative_review"
        decision = "manual_negative_trace_review_only"
        next_gate = "inspect_forced_nonuse_context_before_reclassification"
    elif moved > 0:
        status = "reviewed_seeded_forced_access_available_but_no_usage_blocks_cut_permission"
        decision = "forced_access_no_usage_is_not_cut_proof"
        next_gate = "expand_replay_window_or_find_different_cut_source"
    elif not_found > 0:
        status = "reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission"
        decision = "seeded_hypothesis_source_db_mismatch_or_already_removed"
        next_gate = "rerun_seeded_cut_source_miner_against_current_evaluation_db"
    else:
        status = "reviewed_seeded_forced_access_not_applied_blocks_cut_permission"
        decision = "fix_force_access_scope_or_expand_replay_window"
        next_gate = "fix_force_access_scope_before_cut_review"
    return {
        "cut_card": card,
        "target_cut_role": source_row.get("target_cut_role"),
        "status": status,
        "decision": decision,
        "source_score": source_row.get("source_score") or 0,
        "source_reasons": source_row.get("source_reasons") or [],
        "profile_roles": source_row.get("profile_roles") or [],
        "forced_access_moved_or_present_count": moved,
        "forced_access_not_found_count": not_found,
        "usage_event_count": usage,
        "exposure_event_count": exposure,
        "decision_trace_count": decisions,
        "event_types": trace.get("event_types") or {},
        "first_forced_access_event": forced.get("first_event"),
        "first_usage_event": trace.get("first_usage_event"),
        "first_exposure_event": trace.get("first_exposure_event"),
        "first_decision_trace": trace.get("first_decision_trace"),
        "missing_inputs": missing_inputs,
        "next_gate": next_gate,
        "card_level_cut_permission_now": False,
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
    }


def choose_status_and_next_gate(
    *,
    focus_cards: list[str],
    review_rows: list[Mapping[str, Any]],
    missing_inputs: list[str],
) -> tuple[str, str]:
    if missing_inputs:
        return (
            "reviewed_external_seeded_forced_access_missing_inputs",
            "regenerate_isolated_candidate_db_before_seeded_force_access",
        )
    if not focus_cards:
        return (
            "reviewed_external_seeded_forced_access_blocks_no_unseen_hypotheses",
            "return_to_seeded_trace_review_or_policy_mapping",
        )
    if any(row["status"] == "reviewed_seeded_forced_access_usage_observed_blocks_cut" for row in review_rows):
        return (
            "reviewed_external_seeded_forced_access_blocks_used_hypotheses",
            "map_forced_usage_blocks_to_policy_or_mine_new_same_lane_cut_source",
        )
    if any(
        row["status"] == "reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission"
        for row in review_rows
    ):
        return (
            "reviewed_external_seeded_forced_access_blocks_absent_hypotheses",
            "rerun_seeded_cut_source_miner_against_current_evaluation_db",
        )
    if any(
        row["status"]
        in {
            "reviewed_seeded_forced_access_seen_without_usage_needs_manual_negative_review",
            "reviewed_seeded_forced_access_available_but_no_usage_blocks_cut_permission",
        }
        for row in review_rows
    ):
        return (
            "reviewed_external_seeded_forced_access_needs_negative_review",
            "manual_negative_review_or_expand_replay_window_for_seeded_hypotheses",
        )
    return (
        "reviewed_external_seeded_forced_access_failed_to_apply",
        "fix_force_access_or_expand_replay_window_for_seeded_hypotheses",
    )


def build_report(
    *,
    seeded_trace_collector_report: Path,
    trace_generator_report: Path,
    replay_dir: Path = DEFAULT_REPLAY_DIR,
    seed_start: int = 53,
    seed_count: int = 3,
    forced_access_mode: str = "opening_hand",
    timeout: int = 300,
    real_opponent_seed: str = "20260705",
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> dict[str, Any]:
    seeded_trace_payload = load_json(seeded_trace_collector_report)
    trace_payload = load_json(trace_generator_report)
    seeded_summary = seeded_trace_payload.get("summary") or {}
    trace_summary = trace_payload.get("summary") or {}
    commander = str(seeded_summary.get("commander") or trace_summary.get("commander") or "")
    deck_id = str(seeded_summary.get("deck_id") or trace_summary.get("deck_id") or "")
    input_artifacts = trace_payload.get("input_artifacts") or {}
    db_path = resolve_optional_input(input_artifacts, "selected_db")
    battle_replay = resolve_optional_input(input_artifacts, "battle_replay")
    missing_inputs: list[str] = []
    if db_path is None or not db_path.exists():
        missing_inputs.append(f"selected_db:{rel(db_path) if db_path is not None else 'missing'}")
    if battle_replay is None or not battle_replay.exists():
        missing_inputs.append(f"battle_replay:{rel(battle_replay) if battle_replay is not None else 'missing'}")

    source_rows = focus_hypothesis_rows(seeded_trace_payload)
    focus_cards = unique_cards(source_rows)
    source_by_card = source_rows_by_card(source_rows)
    trace_aggregate = empty_card_summary(focus_cards)
    forced_aggregate = forced_empty_summary(focus_cards)
    seed_rows = []

    if focus_cards and not missing_inputs and db_path is not None and battle_replay is not None:
        for seed in range(seed_start, seed_start + max(1, seed_count)):
            run = run_forced_replay_seed(
                seed=seed,
                deck_id=deck_id,
                db_path=db_path,
                replay_dir=replay_dir,
                battle_replay=battle_replay,
                timeout=timeout,
                real_opponent_seed=real_opponent_seed,
                focus_cards=focus_cards,
                forced_access_mode=forced_access_mode,
                runner=runner,
            )
            row_status = "seeded_forced_replay_generated" if run["returncode"] == 0 else "seeded_forced_replay_generation_failed"
            trace_summary_for_seed = (
                summarize_trace_files(
                    events_path=run["events_path"],
                    decisions_path=run["decisions_path"],
                    card_names=focus_cards,
                    target_player=commander,
                )
                if run["returncode"] == 0
                else {"event_count": 0, "decision_count": 0, "cards": empty_card_summary(focus_cards)}
            )
            forced_summary = forced_access_summary(run["events_path"], focus_cards, commander)
            for card in focus_cards:
                merge_card_summary(trace_aggregate[card], trace_summary_for_seed["cards"][card])
                merge_forced_summary(forced_aggregate[card], forced_summary[card])
            seed_rows.append(
                {
                    "seed": seed,
                    "status": row_status,
                    "returncode": run["returncode"],
                    "replay_txt": rel(run["replay_txt"]),
                    "events_path": rel(run["events_path"]),
                    "decisions_path": rel(run["decisions_path"]),
                    "provenance_path": rel(run["provenance_path"]),
                    "event_count": trace_summary_for_seed["event_count"],
                    "decision_count": trace_summary_for_seed["decision_count"],
                    "forced_access": forced_summary,
                }
            )

    review_rows = [
        classify_seeded_forced_access(
            card=card,
            trace=trace_aggregate[card],
            forced=forced_aggregate[card],
            source_row=source_by_card.get(card, {}),
            missing_inputs=missing_inputs,
        )
        for card in focus_cards
    ]
    usage_blocked = [
        row["cut_card"] for row in review_rows if row["status"] == "reviewed_seeded_forced_access_usage_observed_blocks_cut"
    ]
    manual_review = [
        row["cut_card"]
        for row in review_rows
        if row["status"]
        in {
            "reviewed_seeded_forced_access_seen_without_usage_needs_manual_negative_review",
            "reviewed_seeded_forced_access_available_but_no_usage_blocks_cut_permission",
        }
    ]
    force_failures = [
        row["cut_card"]
        for row in review_rows
        if row["status"]
        in {
            "reviewed_seeded_forced_access_not_applied_blocks_cut_permission",
            "reviewed_seeded_forced_access_input_missing_blocks_trace",
        }
    ]
    selected_db_absent = [
        row["cut_card"]
        for row in review_rows
        if row["status"] == "reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission"
    ]
    status, next_gate = choose_status_and_next_gate(
        focus_cards=focus_cards,
        review_rows=review_rows,
        missing_inputs=missing_inputs,
    )
    blockers = []
    if missing_inputs:
        blockers.append("seeded_forced_access_missing_inputs:" + ",".join(missing_inputs))
    if usage_blocked:
        blockers.append("seeded_forced_access_usage_observed:" + ",".join(usage_blocked))
    if manual_review:
        blockers.append("seeded_forced_access_manual_negative_review_required:" + ",".join(manual_review))
    if force_failures:
        blockers.append("seeded_forced_access_application_blocked:" + ",".join(force_failures))
    if selected_db_absent:
        blockers.append("seeded_hypotheses_absent_from_selected_db:" + ",".join(selected_db_absent))
    blockers.append("candidate_copy_closed_after_seeded_forced_access_trace")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_reviewed_external_seeded_force_access_trace_generator",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "forced_access_replay_performed": bool(seed_rows),
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "card_level_cut_permission_now": False,
        "input_artifacts": {
            "seeded_trace_collector_report": rel(seeded_trace_collector_report),
            "trace_generator_report": rel(trace_generator_report),
            "selected_db": rel(db_path) if db_path is not None else "",
            "battle_replay": rel(battle_replay) if battle_replay is not None else "",
            "replay_dir": rel(replay_dir),
        },
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "source_hypothesis_count": int(seeded_summary.get("hypothesis_count") or len(seeded_trace_payload.get("review_rows") or [])),
            "focus_hypothesis_count": len(focus_cards),
            "focus_cards": focus_cards,
            "seed_start": seed_start,
            "seed_count": max(1, seed_count) if focus_cards and not missing_inputs else 0,
            "forced_access_mode": forced_access_mode,
            "usage_blocked_count": len(usage_blocked),
            "manual_review_count": len(manual_review),
            "force_failure_count": len(force_failures),
            "selected_db_absent_count": len(selected_db_absent),
            "missing_input_count": len(missing_inputs),
            "card_level_cut_permission_count": 0,
            "candidate_copy_allowed_count": 0,
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "review_rows": review_rows,
        "seed_reports": seed_rows,
        "policy": {
            "forced_access_boundary": "Forced access is diagnostic evidence only; it is not a natural battle gate.",
            "seeded_hypothesis_boundary": "Reviewed external seeds can target trace work, but do not create card-level cut permission.",
            "target_boundary": "Forced access applies only to the current evaluation target player.",
            "promotion_boundary": "No candidate copy, deck mutation, battle gate, value-safe reclassification, or promotion is opened by this report.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Reviewed External Seeded Force Access Trace Generator",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- source_hypothesis_count: `{summary['source_hypothesis_count']}`",
        f"- focus_hypothesis_count: `{summary['focus_hypothesis_count']}`",
        f"- focus_cards: `{', '.join(summary['focus_cards'])}`",
        f"- seed_count: `{summary['seed_count']}`",
        f"- forced_access_mode: `{summary['forced_access_mode']}`",
        f"- usage_blocked_count: `{summary['usage_blocked_count']}`",
        f"- manual_review_count: `{summary['manual_review_count']}`",
        f"- force_failure_count: `{summary['force_failure_count']}`",
        f"- selected_db_absent_count: `{summary['selected_db_absent_count']}`",
        f"- missing_input_count: `{summary['missing_input_count']}`",
        f"- card_level_cut_permission_count: `{summary['card_level_cut_permission_count']}`",
        f"- candidate_copy_allowed_count: `{summary['candidate_copy_allowed_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Review Rows",
        "",
        "| Cut | Role | Status | Forced Present | Usage | Exposure | Decisions | Source Score | Next Gate |",
        "| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | --- |",
    ]
    for row in payload["review_rows"]:
        lines.append(
            "| `{cut}` | `{role}` | `{status}` | {forced} | {usage} | {exposure} | {decisions} | {score} | `{next}` |".format(
                cut=row.get("cut_card"),
                role=row.get("target_cut_role"),
                status=row.get("status"),
                forced=row.get("forced_access_moved_or_present_count"),
                usage=row.get("usage_event_count"),
                exposure=row.get("exposure_event_count"),
                decisions=row.get("decision_trace_count"),
                score=row.get("source_score"),
                next=row.get("next_gate"),
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
    parser.add_argument("--seeded-trace-collector-report", type=Path, default=DEFAULT_SEEDED_TRACE_COLLECTOR_REPORT)
    parser.add_argument("--trace-generator-report", type=Path, default=DEFAULT_TRACE_GENERATOR_REPORT)
    parser.add_argument("--replay-dir", type=Path, default=DEFAULT_REPLAY_DIR)
    parser.add_argument("--seed-start", type=int, default=53)
    parser.add_argument("--seed-count", type=int, default=3)
    parser.add_argument("--forced-access-mode", default="opening_hand")
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--real-opponent-seed", default="20260705")
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        seeded_trace_collector_report=args.seeded_trace_collector_report,
        trace_generator_report=args.trace_generator_report,
        replay_dir=args.replay_dir,
        seed_start=args.seed_start,
        seed_count=args.seed_count,
        forced_access_mode=args.forced_access_mode,
        timeout=args.timeout,
        real_opponent_seed=args.real_opponent_seed,
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
