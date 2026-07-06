#!/usr/bin/env python3
"""Generate forced-access traces for unexposed global Commander ramp cuts.

This gate consumes the ramp cut trace/replacement report and forces access only
for ramp cuts that were not exposed by natural current-scope replay. Forced
access is diagnostic evidence only; it never opens candidate copy, mutation,
battle-gate, or promotion paths.
"""

from __future__ import annotations

import argparse
import json
import subprocess
from collections.abc import Callable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_contextual_usage_trace_generator import summarize_trace_files
from global_commander_deck_contract_audit import REPO_ROOT, rel
from global_commander_forced_cut_access_trace_generator import (
    empty_card_summary,
    forced_access_summary,
    merge_card_summary,
    merge_forced_summary,
    run_forced_replay_seed,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_RAMP_TRACE_REPORT = REPORT_DIR / "global_commander_ramp_cut_trace_replacement_gate_20260706_current.json"
DEFAULT_REPLAY_DIR = REPORT_DIR / "global_commander_ramp_cut_forced_access_replays_20260706_current"
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_ramp_cut_forced_access_trace_generator_20260706_current"

UNEXPOSED_RAMP_STATUS = "ramp_cut_natural_trace_no_target_exposure_needs_force_access"


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def artifact_rel(path: Path) -> str:
    candidate = path if path.is_absolute() else REPO_ROOT / path
    try:
        return rel(candidate)
    except ValueError:
        return str(path)


def resolve_path(value: object, *, default: Path) -> Path:
    raw = str(value or "").strip()
    if not raw:
        return default
    path = Path(raw)
    return path if path.is_absolute() else REPO_ROOT / path


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def forced_focus_cards(ramp_trace_payload: Mapping[str, Any]) -> list[str]:
    cards: list[str] = []
    for row in ramp_trace_payload.get("trace_review_rows") or []:
        if not isinstance(row, Mapping) or row.get("status") != UNEXPOSED_RAMP_STATUS:
            continue
        card = str(row.get("card_name") or "").strip()
        if card and card not in cards:
            cards.append(card)
    return cards


def classify_forced_ramp_cut(card: str, trace: Mapping[str, Any], forced: Mapping[str, Any]) -> dict[str, Any]:
    usage = int(trace.get("usage_event_count") or 0)
    exposure = int(trace.get("exposure_event_count") or 0)
    decisions = int(trace.get("decision_trace_count") or 0)
    moved_or_present = int(forced.get("moved_count") or 0) + int(forced.get("already_in_hand_count") or 0)
    not_found = int(forced.get("not_found_count") or 0)
    if usage > 0:
        status = "ramp_cut_forced_access_usage_observed_blocks_cut"
        decision = "not_cut_safe_after_forced_access_usage"
        next_gate = "find_different_ramp_cut_or_exact_same_lane_replacement_after_forced_access"
    elif moved_or_present > 0 and (exposure > 0 or decisions > 0):
        status = "ramp_cut_forced_access_seen_without_usage_needs_manual_negative_review"
        decision = "manual_negative_forced_trace_review_only"
        next_gate = "manual_negative_forced_trace_review_for_ramp_cut_before_candidate_copy"
    elif moved_or_present > 0:
        status = "ramp_cut_forced_access_available_but_no_usage_blocks_cut_clearance"
        decision = "forced_access_no_usage_is_not_cut_proof"
        next_gate = "expand_forced_replay_window_or_find_different_ramp_cut"
    elif not_found > 0:
        status = "ramp_cut_forced_access_card_not_found_blocks_cut_clearance"
        decision = "source_db_card_absent_or_name_mismatch"
        next_gate = "validate_ramp_cut_identity_before_more_trace"
    else:
        status = "ramp_cut_forced_access_not_applied_blocks_cut_clearance"
        decision = "fix_forced_access_runtime_or_expand_ramp_cut_lane"
        next_gate = "fix_force_access_scope_before_ramp_cut_clearance"
    return {
        "card_name": card,
        "status": status,
        "decision": decision,
        "forced_access_moved_or_present_count": moved_or_present,
        "forced_access_not_found_count": not_found,
        "usage_event_count": usage,
        "exposure_event_count": exposure,
        "decision_trace_count": decisions,
        "event_types": trace.get("event_types") or {},
        "first_forced_access_event": forced.get("first_event"),
        "first_usage_event": trace.get("first_usage_event"),
        "first_exposure_event": trace.get("first_exposure_event"),
        "first_decision_trace": trace.get("first_decision_trace"),
        "next_gate": next_gate,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "mutation_allowed": False,
    }


def choose_status_and_gate(review_rows: list[Mapping[str, Any]], focus_cards: list[str]) -> tuple[str, str]:
    usage_blocked = [row["card_name"] for row in review_rows if row["status"] == "ramp_cut_forced_access_usage_observed_blocks_cut"]
    manual_review = [
        row["card_name"]
        for row in review_rows
        if row["status"]
        in {
            "ramp_cut_forced_access_seen_without_usage_needs_manual_negative_review",
            "ramp_cut_forced_access_available_but_no_usage_blocks_cut_clearance",
        }
    ]
    if usage_blocked:
        return (
            "ramp_cut_forced_access_trace_blocks_used_unexposed_cuts",
            "find_different_ramp_cut_or_exact_same_lane_replacement_after_forced_access",
        )
    if manual_review:
        return (
            "ramp_cut_forced_access_trace_needs_manual_negative_review",
            "manual_negative_forced_trace_review_for_ramp_cut_before_candidate_copy",
        )
    if focus_cards:
        return ("ramp_cut_forced_access_trace_failed_to_apply", "fix_force_access_or_ramp_cut_identity")
    return ("ramp_cut_forced_access_trace_no_unexposed_cuts", "review_ramp_cut_trace_results_before_candidate_copy")


def build_report(
    *,
    ramp_trace_report: Path,
    replay_dir: Path = DEFAULT_REPLAY_DIR,
    seed_start: int = 100,
    seed_count: int = 3,
    forced_access_mode: str = "opening_hand",
    timeout: int = 300,
    real_opponent_seed: str = "20260706",
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> dict[str, Any]:
    ramp_payload = load_json(ramp_trace_report)
    artifacts = ramp_payload.get("input_artifacts") or {}
    deck_id = str(ramp_payload.get("deck_id") or "")
    commander = str(ramp_payload.get("commander") or "")
    db_path = resolve_path(artifacts.get("source_db"), default=SCRIPT_DIR / "knowledge.db")
    battle_replay = resolve_path(artifacts.get("battle_replay"), default=SCRIPT_DIR / "battle_replay_v10_3.py")
    focus_cards = forced_focus_cards(ramp_payload)
    trace_aggregate = empty_card_summary(focus_cards)
    forced_aggregate = {
        card: {
            "moved_count": 0,
            "already_in_hand_count": 0,
            "not_found_count": 0,
            "first_event": None,
            "statuses": {},
        }
        for card in focus_cards
    }
    seed_rows = []
    for seed in range(seed_start, seed_start + max(1, seed_count)):
        if not focus_cards:
            break
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
        row_status = "ramp_cut_forced_replay_generated" if run["returncode"] == 0 else "ramp_cut_forced_replay_failed"
        trace_summary = (
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
            merge_card_summary(trace_aggregate[card], trace_summary["cards"][card])
            merge_forced_summary(forced_aggregate[card], forced_summary[card])
        seed_rows.append(
            {
                "seed": seed,
                "status": row_status,
                "returncode": run["returncode"],
                "replay_txt": artifact_rel(run["replay_txt"]),
                "events_path": artifact_rel(run["events_path"]),
                "decisions_path": artifact_rel(run["decisions_path"]),
                "provenance_path": artifact_rel(run["provenance_path"]),
                "event_count": trace_summary["event_count"],
                "decision_count": trace_summary["decision_count"],
                "forced_access": forced_summary,
            }
        )
    review_rows = [classify_forced_ramp_cut(card, trace_aggregate[card], forced_aggregate[card]) for card in focus_cards]
    usage_blocked = [row["card_name"] for row in review_rows if row["status"] == "ramp_cut_forced_access_usage_observed_blocks_cut"]
    manual_review = [
        row["card_name"]
        for row in review_rows
        if row["status"]
        in {
            "ramp_cut_forced_access_seen_without_usage_needs_manual_negative_review",
            "ramp_cut_forced_access_available_but_no_usage_blocks_cut_clearance",
        }
    ]
    force_failures = [
        row["card_name"]
        for row in review_rows
        if row["status"]
        in {
            "ramp_cut_forced_access_card_not_found_blocks_cut_clearance",
            "ramp_cut_forced_access_not_applied_blocks_cut_clearance",
        }
    ]
    blockers = []
    if usage_blocked:
        blockers.append("forced_access_usage_observed_blocks_ramp_cut:" + ",".join(usage_blocked))
    if manual_review:
        blockers.append("forced_access_manual_negative_review_required:" + ",".join(manual_review))
    if force_failures:
        blockers.append("forced_access_application_blocked:" + ",".join(force_failures))
    blockers.append("candidate_copy_closed_after_ramp_forced_access_trace")
    status, next_gate = choose_status_and_gate(review_rows, focus_cards)
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_ramp_cut_forced_access_trace_generator",
        "deck_id": deck_id,
        "commander": commander,
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_replay_performed": bool(seed_rows),
        "battle_gate_performed": False,
        "forced_access_replay_performed": bool(seed_rows),
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "ramp_trace_report": artifact_rel(ramp_trace_report),
            "source_db": artifact_rel(db_path),
            "battle_replay": artifact_rel(battle_replay),
            "replay_dir": artifact_rel(replay_dir),
        },
        "summary": {
            "focus_card_count": len(focus_cards),
            "focus_cards": focus_cards,
            "seed_start": seed_start,
            "seed_count": max(1, seed_count) if focus_cards else 0,
            "generated_replay_count": sum(1 for row in seed_rows if row.get("status") == "ramp_cut_forced_replay_generated"),
            "forced_access_mode": forced_access_mode,
            "usage_blocked_count": len(usage_blocked),
            "manual_review_count": len(manual_review),
            "force_failure_count": len(force_failures),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "review_rows": review_rows,
        "seed_rows": seed_rows,
        "candidate_copy_blockers": blockers,
        "policy": {
            "forced_access_boundary": "Forced access is diagnostic evidence only; it is not a natural battle gate.",
            "target_boundary": "Forced access applies only to the current evaluation target player.",
            "ramp_cut_boundary": "A ramp cut used under forced access is blocked until a different cut or exact same-lane replacement is proven.",
            "promotion_boundary": "No candidate copy, deck mutation, battle gate, or promotion is opened by this report.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Ramp Cut Forced Access Trace Generator",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{payload['commander']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- focus_card_count: `{summary['focus_card_count']}`",
        f"- focus_cards: `{', '.join(summary['focus_cards'])}`",
        f"- seed_count: `{summary['seed_count']}`",
        f"- generated_replay_count: `{summary['generated_replay_count']}`",
        f"- forced_access_mode: `{summary['forced_access_mode']}`",
        f"- usage_blocked_count: `{summary['usage_blocked_count']}`",
        f"- manual_review_count: `{summary['manual_review_count']}`",
        f"- force_failure_count: `{summary['force_failure_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_replay_performed: `{str(payload['battle_replay_performed']).lower()}`",
        f"- battle_gate_performed: `{str(payload['battle_gate_performed']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Review Rows",
        "",
        "| Card | Status | Forced Present | Usage | Exposure | Decisions | Next Gate |",
        "| --- | --- | ---: | ---: | ---: | ---: | --- |",
    ]
    for row in payload["review_rows"]:
        lines.append(
            "| `{card}` | `{status}` | {forced} | {usage} | {exposure} | {decisions} | `{next}` |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                forced=row.get("forced_access_moved_or_present_count"),
                usage=row.get("usage_event_count"),
                exposure=row.get("exposure_event_count"),
                decisions=row.get("decision_trace_count"),
                next=row.get("next_gate"),
            )
        )
    if not payload["review_rows"]:
        lines.append("| none |  |  |  |  |  |")
    lines.extend(["", "## Seed Reports", ""])
    if payload["seed_rows"]:
        for row in payload["seed_rows"]:
            lines.append(
                f"- seed `{row['seed']}`: `{row['status']}`, events `{row['event_count']}`, decisions `{row['decision_count']}`"
            )
    else:
        lines.append("- none")
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
    parser.add_argument("--ramp-trace-report", type=Path, default=DEFAULT_RAMP_TRACE_REPORT)
    parser.add_argument("--replay-dir", type=Path, default=DEFAULT_REPLAY_DIR)
    parser.add_argument("--seed-start", type=int, default=100)
    parser.add_argument("--seed-count", type=int, default=3)
    parser.add_argument("--forced-access-mode", default="opening_hand")
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--real-opponent-seed", default="20260706")
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        ramp_trace_report=args.ramp_trace_report,
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
