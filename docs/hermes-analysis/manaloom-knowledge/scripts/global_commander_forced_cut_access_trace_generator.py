#!/usr/bin/env python3
"""Generate forced-access traces for unresolved Commander cut candidates.

This diagnostic gate consumes the remaining cut-source trace collector and runs
focused access replays only for cards that were seen without usage or not seen
in the current replay window. It does not open candidate copy, battle, or
promotion gates.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

from global_commander_contextual_usage_trace_generator import iter_jsonl, summarize_trace_files
from global_commander_deck_contract_audit import REPO_ROOT


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_CUT_TRACE_COLLECTOR_REPORT = (
    REPORT_DIR / "global_commander_new_cut_source_lane_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_TRACE_GENERATOR_REPORT = (
    REPORT_DIR / "global_commander_contextual_usage_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_REPLAY_DIR = (
    REPORT_DIR / "global_commander_forced_cut_access_replays_20260705_kaalia_value_safe_stage1_repair_scope1"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_forced_cut_access_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1"
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


def unresolved_cards(cut_trace_payload: Mapping[str, Any]) -> list[str]:
    cards = []
    blocked_status = "remaining_cut_used_by_target_trace_blocks_value_safe"
    for row in cut_trace_payload.get("review_rows") or []:
        if not isinstance(row, Mapping) or row.get("status") == blocked_status:
            continue
        card = str(row.get("cut_card") or "").strip()
        if card and card not in cards:
            cards.append(card)
    return cards


def run_forced_replay_seed(
    *,
    seed: int,
    deck_id: str,
    db_path: Path,
    replay_dir: Path,
    battle_replay: Path,
    timeout: int,
    real_opponent_seed: str,
    focus_cards: list[str],
    forced_access_mode: str,
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> dict[str, Any]:
    replay_dir.mkdir(parents=True, exist_ok=True)
    replay_txt = replay_dir / f"forced_replay_seed_{seed}.txt"
    events_path = replay_dir / f"forced_replay_seed_{seed}.events.jsonl"
    decisions_path = replay_dir / f"forced_replay_seed_{seed}.decision_trace.jsonl"
    provenance_path = replay_dir / f"forced_deck_provenance_seed_{seed}.json"
    env = os.environ.copy()
    env.update(
        {
            "MANALOOM_KNOWLEDGE_DB": str(db_path),
            "MANALOOM_BATTLE_TARGET_DECK_ID": str(deck_id),
            "MANALOOM_BATTLE_REAL_OPPONENT_SEED": str(real_opponent_seed),
            "MANALOOM_FOCUS_ACCESS_CARDS": json.dumps(focus_cards, ensure_ascii=True),
            "MANALOOM_FORCE_FOCUS_ACCESS_MODE": forced_access_mode,
            "REPLAY_SEED": str(seed),
            "REPLAY_OUT": str(replay_txt),
            "REPLAY_EVENTS_OUT": str(events_path),
            "DECISION_TRACE_OUT": str(decisions_path),
            "REPLAY_DECK_PROVENANCE_OUT": str(provenance_path),
        }
    )
    completed = runner(
        [sys.executable, str(battle_replay)],
        cwd=str(SCRIPT_DIR),
        env=env,
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    return {
        "seed": seed,
        "returncode": completed.returncode,
        "stdout_tail": (completed.stdout or "")[-1200:],
        "stderr_tail": (completed.stderr or "")[-1200:],
        "replay_txt": replay_txt,
        "events_path": events_path,
        "decisions_path": decisions_path,
        "provenance_path": provenance_path,
    }


def forced_access_summary(events_path: Path, focus_cards: list[str], target_player: str) -> dict[str, dict[str, Any]]:
    summary = {
        card: {
            "moved_count": 0,
            "already_in_hand_count": 0,
            "not_found_count": 0,
            "first_event": None,
            "statuses": {},
        }
        for card in focus_cards
    }
    for row in iter_jsonl(events_path):
        if row.get("event") != "forced_focus_access_applied":
            continue
        if str(row.get("player") or "") != target_player:
            continue
        card = str(row.get("card") or "")
        if card not in summary:
            continue
        status = str(row.get("status") or "unknown")
        key = {
            "moved": "moved_count",
            "already_in_hand": "already_in_hand_count",
            "not_found": "not_found_count",
        }.get(status)
        if key:
            summary[card][key] += 1
        summary[card]["statuses"][status] = int(summary[card]["statuses"].get(status) or 0) + 1
        if summary[card]["first_event"] is None:
            summary[card]["first_event"] = {
                "event": row.get("event"),
                "turn": row.get("turn"),
                "player": row.get("player"),
                "card": row.get("card"),
                "status": row.get("status"),
                "mode": row.get("mode"),
                "replaced_card": row.get("replaced_card"),
            }
    return summary


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
    target_events = target.setdefault("event_types", {})
    for event, count in (source.get("event_types") or {}).items():
        target_events[str(event)] = int(target_events.get(str(event)) or 0) + int(count or 0)
    for key in ("first_usage_event", "first_exposure_event", "first_decision_trace"):
        if target.get(key) is None and source.get(key) is not None:
            target[key] = source.get(key)


def merge_forced_summary(target: dict[str, Any], source: Mapping[str, Any]) -> None:
    for key in ("moved_count", "already_in_hand_count", "not_found_count"):
        target[key] = int(target.get(key) or 0) + int(source.get(key) or 0)
    statuses = target.setdefault("statuses", {})
    for status, count in (source.get("statuses") or {}).items():
        statuses[str(status)] = int(statuses.get(str(status)) or 0) + int(count or 0)
    if target.get("first_event") is None and source.get("first_event") is not None:
        target["first_event"] = source.get("first_event")


def classify_card(card: str, trace: Mapping[str, Any], forced: Mapping[str, Any]) -> dict[str, Any]:
    usage = int(trace.get("usage_event_count") or 0)
    exposure = int(trace.get("exposure_event_count") or 0)
    decisions = int(trace.get("decision_trace_count") or 0)
    moved = int(forced.get("moved_count") or 0) + int(forced.get("already_in_hand_count") or 0)
    not_found = int(forced.get("not_found_count") or 0)
    if usage > 0:
        status = "forced_access_usage_observed_blocks_value_safe"
        decision = "not_value_safe_after_forced_access_usage"
        next_gate = "find_different_cut_or_same_lane_replacement_proof"
    elif moved > 0 and (exposure > 0 or decisions > 0):
        status = "forced_access_seen_without_usage_needs_manual_negative_review"
        decision = "manual_negative_trace_review_only"
        next_gate = "inspect_forced_trace_nonuse_context_before_reclassification"
    elif moved > 0:
        status = "forced_access_available_but_no_usage_blocks_reclassification"
        decision = "forced_access_no_usage_is_not_cut_proof"
        next_gate = "expand_replay_window_or_find_different_cut"
    elif not_found > 0:
        status = "forced_access_card_not_found_blocks_reclassification"
        decision = "source_db_card_absent_or_name_mismatch"
        next_gate = "validate_card_identity_before_more_trace"
    else:
        status = "forced_access_not_applied_blocks_reclassification"
        decision = "fix_forced_access_runtime_or_expand_cut_lane"
        next_gate = "fix_force_access_scope_before_reclassification"
    return {
        "card_name": card,
        "status": status,
        "decision": decision,
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
        "next_gate": next_gate,
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
    }


def build_report(
    *,
    cut_trace_collector_report: Path,
    trace_generator_report: Path,
    replay_dir: Path = DEFAULT_REPLAY_DIR,
    seed_start: int = 50,
    seed_count: int = 3,
    forced_access_mode: str = "opening_hand",
    timeout: int = 300,
    real_opponent_seed: str = "20260705",
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> dict[str, Any]:
    cut_payload = load_json(cut_trace_collector_report)
    trace_payload = load_json(trace_generator_report)
    summary = cut_payload.get("summary") or {}
    generator_inputs = trace_payload.get("input_artifacts") or {}
    deck_id = str(summary.get("deck_id") or (trace_payload.get("summary") or {}).get("deck_id") or "")
    commander = str(summary.get("commander") or (trace_payload.get("summary") or {}).get("commander") or "")
    db_path = resolve_path(generator_inputs.get("selected_db"))
    battle_replay = resolve_path(generator_inputs.get("battle_replay"))
    focus_cards = unresolved_cards(cut_payload)
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
        row_status = "forced_replay_generated" if run["returncode"] == 0 else "forced_replay_generation_failed"
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
                "replay_txt": rel(run["replay_txt"]),
                "events_path": rel(run["events_path"]),
                "decisions_path": rel(run["decisions_path"]),
                "provenance_path": rel(run["provenance_path"]),
                "event_count": trace_summary["event_count"],
                "decision_count": trace_summary["decision_count"],
                "forced_access": forced_summary,
            }
        )
    review_rows = [classify_card(card, trace_aggregate[card], forced_aggregate[card]) for card in focus_cards]
    usage_blocked = [row["card_name"] for row in review_rows if row["status"] == "forced_access_usage_observed_blocks_value_safe"]
    manual_review = [
        row["card_name"]
        for row in review_rows
        if row["status"] in {"forced_access_seen_without_usage_needs_manual_negative_review", "forced_access_available_but_no_usage_blocks_reclassification"}
    ]
    force_failures = [
        row["card_name"]
        for row in review_rows
        if row["status"] in {"forced_access_card_not_found_blocks_reclassification", "forced_access_not_applied_blocks_reclassification"}
    ]
    if usage_blocked:
        status = "forced_cut_access_trace_blocks_used_unresolved_cuts"
        next_gate = "expand_cut_source_lane_after_forced_access_blocks_current_unresolved_cuts"
    elif manual_review:
        status = "forced_cut_access_trace_needs_manual_negative_review"
        next_gate = "manual_negative_trace_review_or_expand_cut_source_lane"
    else:
        status = "forced_cut_access_trace_failed_to_apply"
        next_gate = "fix_force_access_or_expand_cut_source_lane"
    blockers = []
    if usage_blocked:
        blockers.append("forced_access_usage_observed:" + ",".join(usage_blocked))
    if manual_review:
        blockers.append("forced_access_manual_negative_review_required:" + ",".join(manual_review))
    if force_failures:
        blockers.append("forced_access_application_blocked:" + ",".join(force_failures))
    blockers.append("candidate_copy_closed_after_forced_access_trace")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_forced_cut_access_trace_generator",
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
        "input_artifacts": {
            "cut_trace_collector_report": rel(cut_trace_collector_report),
            "trace_generator_report": rel(trace_generator_report),
            "selected_db": rel(db_path),
            "battle_replay": rel(battle_replay),
            "replay_dir": rel(replay_dir),
        },
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "focus_card_count": len(focus_cards),
            "focus_cards": focus_cards,
            "seed_start": seed_start,
            "seed_count": max(1, seed_count),
            "forced_access_mode": forced_access_mode,
            "usage_blocked_count": len(usage_blocked),
            "manual_review_count": len(manual_review),
            "force_failure_count": len(force_failures),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "review_rows": review_rows,
        "seed_reports": seed_rows,
        "policy": {
            "forced_access_boundary": "Forced access is diagnostic evidence only; it is not a natural battle gate.",
            "target_boundary": "Forced access applies only to the current evaluation target player.",
            "promotion_boundary": "No candidate copy, deck mutation, battle gate, or promotion is opened by this report.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Forced Cut Access Trace Generator",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- focus_card_count: `{summary['focus_card_count']}`",
        f"- focus_cards: `{', '.join(summary['focus_cards'])}`",
        f"- seed_count: `{summary['seed_count']}`",
        f"- forced_access_mode: `{summary['forced_access_mode']}`",
        f"- usage_blocked_count: `{summary['usage_blocked_count']}`",
        f"- manual_review_count: `{summary['manual_review_count']}`",
        f"- force_failure_count: `{summary['force_failure_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
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
    parser.add_argument("--cut-trace-collector-report", type=Path, default=DEFAULT_CUT_TRACE_COLLECTOR_REPORT)
    parser.add_argument("--trace-generator-report", type=Path, default=DEFAULT_TRACE_GENERATOR_REPORT)
    parser.add_argument("--replay-dir", type=Path, default=DEFAULT_REPLAY_DIR)
    parser.add_argument("--seed-start", type=int, default=50)
    parser.add_argument("--seed-count", type=int, default=3)
    parser.add_argument("--forced-access-mode", default="opening_hand")
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--real-opponent-seed", default="20260705")
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        cut_trace_collector_report=args.cut_trace_collector_report,
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
