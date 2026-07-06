#!/usr/bin/env python3
"""Generate forced-access traces for unexposed alternative ramp cut targets.

This gate consumes the alternative ramp cut natural trace report and forces
access only for targets that remained unexposed. Forced access is diagnostic
evidence only; it does not authorize a cut, copy, battle gate, mutation, or
promotion.
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
DEFAULT_ALTERNATIVE_TRACE_REPORT = REPORT_DIR / "global_commander_ramp_alternative_cut_trace_generator_20260706_current.json"
DEFAULT_REPLAY_DIR = REPORT_DIR / "global_commander_ramp_alternative_cut_forced_access_replays_20260706_current"
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_ramp_alternative_cut_forced_access_trace_generator_20260706_current"

NO_EXPOSURE_STATUS = "alternative_ramp_cut_no_current_exposure_needs_force_access_or_more_trace"


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


def focus_cards(trace_payload: Mapping[str, Any]) -> list[str]:
    cards: list[str] = []
    for row in trace_payload.get("review_rows") or []:
        if not isinstance(row, Mapping) or row.get("status") != NO_EXPOSURE_STATUS:
            continue
        card = str(row.get("card_name") or "").strip()
        if card and card not in cards:
            cards.append(card)
    return cards


def classify_card(card: str, trace: Mapping[str, Any], forced: Mapping[str, Any]) -> dict[str, Any]:
    usage = int(trace.get("usage_event_count") or 0)
    exposure = int(trace.get("exposure_event_count") or 0)
    decisions = int(trace.get("decision_trace_count") or 0)
    moved_or_present = int(forced.get("moved_count") or 0) + int(forced.get("already_in_hand_count") or 0)
    not_found = int(forced.get("not_found_count") or 0)
    if usage > 0:
        status = "alternative_ramp_cut_forced_access_usage_observed_blocks_cut"
        decision = "not_cut_safe_after_forced_access_usage"
        next_gate = "expand_ramp_cut_source_or_pivot_role_axis_after_alternative_forced_access"
    elif moved_or_present > 0 and (exposure > 0 or decisions > 0):
        status = "alternative_ramp_cut_forced_seen_without_usage_needs_manual_negative_review"
        decision = "manual_negative_forced_trace_review_only"
        next_gate = "manual_negative_forced_trace_review_for_alternative_ramp_cut"
    elif moved_or_present > 0:
        status = "alternative_ramp_cut_forced_available_but_no_usage_blocks_cut_clearance"
        decision = "forced_access_no_usage_is_not_cut_proof"
        next_gate = "expand_forced_replay_window_or_pivot_ramp_cut_source"
    elif not_found > 0:
        status = "alternative_ramp_cut_forced_card_not_found_blocks_cut_clearance"
        decision = "source_db_card_absent_or_name_mismatch"
        next_gate = "validate_alternative_ramp_cut_identity_before_more_trace"
    else:
        status = "alternative_ramp_cut_forced_not_applied_blocks_cut_clearance"
        decision = "fix_forced_access_runtime_or_expand_ramp_cut_lane"
        next_gate = "fix_force_access_scope_before_alternative_ramp_cut_clearance"
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


def choose_status(review_rows: list[Mapping[str, Any]], cards: list[str]) -> tuple[str, str]:
    usage_blocked = [row for row in review_rows if row["status"] == "alternative_ramp_cut_forced_access_usage_observed_blocks_cut"]
    manual = [
        row
        for row in review_rows
        if row["status"]
        in {
            "alternative_ramp_cut_forced_seen_without_usage_needs_manual_negative_review",
            "alternative_ramp_cut_forced_available_but_no_usage_blocks_cut_clearance",
        }
    ]
    failures = [
        row
        for row in review_rows
        if row["status"]
        in {
            "alternative_ramp_cut_forced_card_not_found_blocks_cut_clearance",
            "alternative_ramp_cut_forced_not_applied_blocks_cut_clearance",
        }
    ]
    if usage_blocked:
        return (
            "ramp_alternative_cut_forced_access_blocks_used_targets",
            "expand_ramp_cut_source_or_pivot_role_axis_after_alternative_forced_access",
        )
    if manual:
        return (
            "ramp_alternative_cut_forced_access_needs_manual_negative_review",
            "manual_negative_forced_trace_review_for_alternative_ramp_cut",
        )
    if failures:
        return (
            "ramp_alternative_cut_forced_access_failed_to_apply",
            "fix_force_access_or_card_identity_for_alternative_ramp_cut",
        )
    if cards:
        return ("ramp_alternative_cut_forced_access_inconclusive", "expand_forced_replay_window_for_alternative_ramp_cut")
    return ("ramp_alternative_cut_forced_access_no_targets", "expand_external_ramp_cut_or_pivot_role_axis")


def build_report(
    *,
    alternative_trace_report: Path,
    replay_dir: Path = DEFAULT_REPLAY_DIR,
    seed_start: int = 120,
    seed_count: int = 3,
    forced_access_mode: str = "opening_hand",
    timeout: int = 300,
    real_opponent_seed: str = "20260706",
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> dict[str, Any]:
    trace_payload = load_json(alternative_trace_report)
    artifacts = trace_payload.get("input_artifacts") or {}
    db_path = resolve_path(artifacts.get("source_db"), default=SCRIPT_DIR / "knowledge.db")
    battle_replay = resolve_path(artifacts.get("battle_replay"), default=SCRIPT_DIR / "battle_replay_v10_3.py")
    deck_id = str(trace_payload.get("deck_id") or "")
    commander = str(trace_payload.get("commander") or "")
    cards = focus_cards(trace_payload)
    trace_aggregate = empty_card_summary(cards)
    forced_aggregate = {
        card: {
            "moved_count": 0,
            "already_in_hand_count": 0,
            "not_found_count": 0,
            "first_event": None,
            "statuses": {},
        }
        for card in cards
    }
    seed_rows = []
    for seed in range(seed_start, seed_start + max(1, seed_count)):
        if not cards:
            break
        run = run_forced_replay_seed(
            seed=seed,
            deck_id=deck_id,
            db_path=db_path,
            replay_dir=replay_dir,
            battle_replay=battle_replay,
            timeout=timeout,
            real_opponent_seed=real_opponent_seed,
            focus_cards=cards,
            forced_access_mode=forced_access_mode,
            runner=runner,
        )
        row_status = "alternative_ramp_cut_forced_replay_generated" if run["returncode"] == 0 else "alternative_ramp_cut_forced_replay_failed"
        trace_summary = (
            summarize_trace_files(
                events_path=run["events_path"],
                decisions_path=run["decisions_path"],
                card_names=cards,
                target_player=commander,
            )
            if run["returncode"] == 0
            else {"event_count": 0, "decision_count": 0, "cards": empty_card_summary(cards)}
        )
        forced_summary = forced_access_summary(run["events_path"], cards, commander)
        for card in cards:
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
    review_rows = [classify_card(card, trace_aggregate[card], forced_aggregate[card]) for card in cards]
    usage_blocked = [row["card_name"] for row in review_rows if row["status"] == "alternative_ramp_cut_forced_access_usage_observed_blocks_cut"]
    manual = [
        row["card_name"]
        for row in review_rows
        if row["status"]
        in {
            "alternative_ramp_cut_forced_seen_without_usage_needs_manual_negative_review",
            "alternative_ramp_cut_forced_available_but_no_usage_blocks_cut_clearance",
        }
    ]
    failures = [
        row["card_name"]
        for row in review_rows
        if row["status"]
        in {
            "alternative_ramp_cut_forced_card_not_found_blocks_cut_clearance",
            "alternative_ramp_cut_forced_not_applied_blocks_cut_clearance",
        }
    ]
    status, next_gate = choose_status(review_rows, cards)
    blockers = []
    if usage_blocked:
        blockers.append("alternative_ramp_cut_forced_usage_observed_blocks_cut:" + ",".join(usage_blocked))
    if manual:
        blockers.append("alternative_ramp_cut_forced_manual_negative_review_required:" + ",".join(manual))
    if failures:
        blockers.append("alternative_ramp_cut_forced_application_blocked:" + ",".join(failures))
    blockers.append("candidate_copy_closed_after_alternative_ramp_cut_forced_access")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_ramp_alternative_cut_forced_access_trace_generator",
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
            "alternative_trace_report": artifact_rel(alternative_trace_report),
            "source_db": artifact_rel(db_path),
            "battle_replay": artifact_rel(battle_replay),
            "replay_dir": artifact_rel(replay_dir),
        },
        "summary": {
            "focus_card_count": len(cards),
            "focus_cards": cards,
            "seed_start": seed_start,
            "seed_count": max(1, seed_count) if cards else 0,
            "generated_replay_count": sum(1 for row in seed_rows if row.get("status") == "alternative_ramp_cut_forced_replay_generated"),
            "forced_access_mode": forced_access_mode,
            "usage_blocked_count": len(usage_blocked),
            "manual_review_count": len(manual),
            "force_failure_count": len(failures),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "review_rows": review_rows,
        "seed_rows": seed_rows,
        "candidate_copy_blockers": blockers,
        "policy": {
            "forced_access_boundary": "Forced access is diagnostic evidence only; it is not a natural battle gate.",
            "alternative_cut_boundary": "Alternative ramp cuts used under forced access are blocked as cuts.",
            "promotion_boundary": "No candidate copy, deck mutation, battle gate, or promotion is opened by this report.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Ramp Alternative Cut Forced Access Trace Generator",
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
    parser.add_argument("--alternative-trace-report", type=Path, default=DEFAULT_ALTERNATIVE_TRACE_REPORT)
    parser.add_argument("--replay-dir", type=Path, default=DEFAULT_REPLAY_DIR)
    parser.add_argument("--seed-start", type=int, default=120)
    parser.add_argument("--seed-count", type=int, default=3)
    parser.add_argument("--forced-access-mode", default="opening_hand")
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--real-opponent-seed", default="20260706")
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        alternative_trace_report=args.alternative_trace_report,
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
