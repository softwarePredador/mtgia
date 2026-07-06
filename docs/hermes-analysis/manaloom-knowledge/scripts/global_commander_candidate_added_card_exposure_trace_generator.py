#!/usr/bin/env python3
"""Generate forced-access exposure traces for unexercised candidate adds.

This diagnostic gate consumes a blocked
`global_commander_candidate_battle_probe_audit.py` report, finds candidate adds
that were not exercised in replay events, and runs focused forced-access
replays against the isolated candidate DB. Forced access is not a natural
battle gate and cannot promote a deck; it only tells the next evidence step
whether the added cards can execute when made available to the target deck.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections.abc import Callable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_candidate_battle_probe_audit import EXERCISE_EVENT_NAMES
from global_commander_contextual_usage_trace_generator import (
    card_mentioned,
    compact_row,
    iter_jsonl,
)
from global_commander_deck_contract_audit import REPO_ROOT
from master_optimizer_common import normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_BATTLE_PROBE_AUDIT = (
    REPORT_DIR / "global_commander_candidate_battle_probe_audit_20260706_lorehold_profile_repair_package.json"
)
DEFAULT_BATTLE_REPLAY = SCRIPT_DIR / "battle_replay_v10_3.py"
DEFAULT_REPLAY_DIR = (
    REPORT_DIR / "global_commander_candidate_added_card_exposure_replays_20260706_lorehold_profile_repair_package"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_candidate_added_card_exposure_trace_generator_20260706_lorehold_profile_repair_package"
)
ACTIVE_CARD_KEYS = (
    "card",
    "source",
    "source_name",
    "stack_object",
    "spell",
    "permanent",
    "land",
    "object",
    "ability_source",
    "trigger_source",
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


def unexercised_added_cards(audit_payload: Mapping[str, Any]) -> list[str]:
    replay = audit_payload.get("replay") or {}
    cards = replay.get("added_cards_unexercised_in_events")
    if isinstance(cards, list):
        return [str(card) for card in cards if str(card).strip()]
    deck_diff = audit_payload.get("deck_diff") or {}
    return [str(card) for card in deck_diff.get("added_cards") or [] if str(card).strip()]


def empty_card_summary(cards: list[str]) -> dict[str, dict[str, Any]]:
    return {
        card: {
            "exercise_event_count": 0,
            "exposure_event_count": 0,
            "decision_trace_count": 0,
            "reference_event_count": 0,
            "forced_access_moved_or_present_count": 0,
            "forced_access_not_found_count": 0,
            "event_types": {},
            "forced_access_statuses": {},
            "first_exercise_event": None,
            "first_exposure_event": None,
            "first_decision_trace": None,
            "first_forced_access_event": None,
        }
        for card in cards
    }


def target_aliases(target_player: str) -> set[str]:
    target = str(target_player or "").strip()
    aliases = {target} if target else set()
    if "," in target:
        aliases.add(target.split(",", 1)[0].strip())
    return {alias for alias in aliases if alias}


def row_belongs_to_target_alias(row: Mapping[str, Any], aliases: set[str]) -> bool:
    if not aliases:
        return True
    for key in ("player", "active_player", "attacker", "controller"):
        if str(row.get(key) or "") in aliases:
            return True
    return False


def card_value_matches(value: Any, card: str) -> bool:
    target = normalize_name(card)
    if not target:
        return False
    if isinstance(value, str):
        return normalize_name(value) == target
    if isinstance(value, Mapping):
        for key in ("name", "card", "source", "stack_object"):
            if card_value_matches(value.get(key), card):
                return True
    if isinstance(value, list):
        return any(card_value_matches(item, card) for item in value)
    return False


def active_card_matches(row: Mapping[str, Any], card: str) -> bool:
    return any(card_value_matches(row.get(key), card) for key in ACTIVE_CARD_KEYS)


def forced_access_event(row: Mapping[str, Any], target_alias_set: set[str]) -> bool:
    return (
        row.get("event") == "forced_focus_access_applied"
        and row_belongs_to_target_alias(row, target_alias_set)
    )


def summarize_trace_files(
    *,
    events_path: Path,
    decisions_path: Path,
    card_names: list[str],
    target_player: str,
) -> dict[str, Any]:
    events = iter_jsonl(events_path)
    decisions = iter_jsonl(decisions_path)
    cards = empty_card_summary(card_names)
    target_alias_set = target_aliases(target_player)
    for row in events:
        if not row_belongs_to_target_alias(row, target_alias_set):
            continue
        event_type = str(row.get("event") or "unknown")
        for card in card_names:
            if not card_mentioned(row, card):
                continue
            summary = cards[card]
            summary["event_types"][event_type] = int(summary["event_types"].get(event_type) or 0) + 1
            if forced_access_event(row, target_alias_set) and active_card_matches(row, card):
                status = str(row.get("status") or "unknown")
                summary["forced_access_statuses"][status] = int(
                    summary["forced_access_statuses"].get(status) or 0
                ) + 1
                if status in {"moved", "already_in_hand"}:
                    summary["forced_access_moved_or_present_count"] += 1
                elif status == "not_found":
                    summary["forced_access_not_found_count"] += 1
                if summary["first_forced_access_event"] is None:
                    summary["first_forced_access_event"] = compact_row(row)
            elif event_type in EXERCISE_EVENT_NAMES and active_card_matches(row, card):
                summary["exercise_event_count"] += 1
                if summary["first_exercise_event"] is None:
                    summary["first_exercise_event"] = compact_row(row)
            elif event_type == "focus_card_access_snapshot":
                summary["exposure_event_count"] += 1
                if summary["first_exposure_event"] is None:
                    summary["first_exposure_event"] = compact_row(row)
            else:
                summary["reference_event_count"] += 1
    for row in decisions:
        if not row_belongs_to_target_alias(row, target_alias_set):
            continue
        for card in card_names:
            if not card_mentioned(row, card):
                continue
            summary = cards[card]
            summary["decision_trace_count"] += 1
            if summary["first_decision_trace"] is None:
                summary["first_decision_trace"] = compact_row(row)
    return {
        "event_count": len(events),
        "decision_count": len(decisions),
        "cards": cards,
    }


def merge_card_summary(target: dict[str, Any], source: Mapping[str, Any]) -> None:
    for key in (
        "exercise_event_count",
        "exposure_event_count",
        "decision_trace_count",
        "reference_event_count",
        "forced_access_moved_or_present_count",
        "forced_access_not_found_count",
    ):
        target[key] = int(target.get(key) or 0) + int(source.get(key) or 0)
    for event_type, count in (source.get("event_types") or {}).items():
        target["event_types"][str(event_type)] = int(target["event_types"].get(str(event_type)) or 0) + int(count or 0)
    for status, count in (source.get("forced_access_statuses") or {}).items():
        target["forced_access_statuses"][str(status)] = int(
            target["forced_access_statuses"].get(str(status)) or 0
        ) + int(count or 0)
    for first_key in (
        "first_exercise_event",
        "first_exposure_event",
        "first_decision_trace",
        "first_forced_access_event",
    ):
        if target.get(first_key) is None and source.get(first_key):
            target[first_key] = source.get(first_key)


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
    replay_txt = replay_dir / f"forced_added_replay_seed_{seed}.txt"
    events_path = replay_dir / f"forced_added_replay_seed_{seed}.events.jsonl"
    decisions_path = replay_dir / f"forced_added_replay_seed_{seed}.decision_trace.jsonl"
    provenance_path = replay_dir / f"forced_added_deck_provenance_seed_{seed}.json"
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


def classify_card(card: str, trace: Mapping[str, Any]) -> dict[str, Any]:
    exercise = int(trace.get("exercise_event_count") or 0)
    exposure = int(trace.get("exposure_event_count") or 0)
    decisions = int(trace.get("decision_trace_count") or 0)
    moved = int(trace.get("forced_access_moved_or_present_count") or 0)
    not_found = int(trace.get("forced_access_not_found_count") or 0)
    if exercise > 0:
        status = "forced_added_card_exercised_diagnostic_only"
        next_gate = "seek_natural_replay_or_larger_equal_gate_after_forced_diagnostic"
    elif moved > 0 and (exposure > 0 or decisions > 0):
        status = "forced_added_card_seen_without_exercise_needs_manual_review"
        next_gate = "inspect_forced_nonuse_context_or_expand_seed_window"
    elif moved > 0:
        status = "forced_added_card_present_but_unexercised_blocks_gate"
        next_gate = "expand_seed_window_or_reconsider_add_role_fit"
    elif not_found > 0:
        status = "forced_added_card_not_found_blocks_gate"
        next_gate = "validate_candidate_db_identity_before_more_trace"
    else:
        status = "forced_added_card_access_not_applied_blocks_gate"
        next_gate = "fix_forced_access_scope_before_more_trace"
    return {
        "card_name": card,
        "status": status,
        "exercise_event_count": exercise,
        "exposure_event_count": exposure,
        "decision_trace_count": decisions,
        "forced_access_moved_or_present_count": moved,
        "forced_access_not_found_count": not_found,
        "event_types": trace.get("event_types") or {},
        "forced_access_statuses": trace.get("forced_access_statuses") or {},
        "first_forced_access_event": trace.get("first_forced_access_event"),
        "first_exercise_event": trace.get("first_exercise_event"),
        "first_exposure_event": trace.get("first_exposure_event"),
        "first_decision_trace": trace.get("first_decision_trace"),
        "next_gate": next_gate,
        "natural_gate_satisfied": False,
        "promotion_allowed": False,
    }


def build_report(
    *,
    battle_probe_audit: Path,
    replay_dir: Path = DEFAULT_REPLAY_DIR,
    seed_start: int = 80,
    seed_count: int = 3,
    forced_access_mode: str = "opening_hand",
    battle_replay: Path = DEFAULT_BATTLE_REPLAY,
    timeout: int = 300,
    real_opponent_seed: str = "20260706",
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> dict[str, Any]:
    battle_probe_audit = resolve_path(battle_probe_audit)
    replay_dir = resolve_path(replay_dir)
    battle_replay = resolve_path(battle_replay)
    audit_payload = load_json(battle_probe_audit)
    cards = unexercised_added_cards(audit_payload)
    inputs = audit_payload.get("input_artifacts") or {}
    candidate_db = resolve_path(inputs.get("candidate_db"))
    deck_id = str(audit_payload.get("deck_id") or "")
    commander = str(audit_payload.get("commander") or "")
    aggregate = empty_card_summary(cards)
    seed_rows: list[dict[str, Any]] = []
    for seed in range(seed_start, seed_start + max(1, seed_count)):
        run = run_forced_replay_seed(
            seed=seed,
            deck_id=deck_id,
            db_path=candidate_db,
            replay_dir=replay_dir,
            battle_replay=battle_replay,
            timeout=timeout,
            real_opponent_seed=real_opponent_seed,
            focus_cards=cards,
            forced_access_mode=forced_access_mode,
            runner=runner,
        )
        row: dict[str, Any] = {
            "seed": seed,
            "status": "forced_replay_generated" if run["returncode"] == 0 else "forced_replay_generation_failed",
            "returncode": run["returncode"],
            "replay_txt": rel(run["replay_txt"]),
            "events_path": rel(run["events_path"]),
            "decisions_path": rel(run["decisions_path"]),
            "provenance_path": rel(run["provenance_path"]),
            "stdout_tail": run["stdout_tail"],
            "stderr_tail": run["stderr_tail"],
        }
        if run["returncode"] == 0:
            trace = summarize_trace_files(
                events_path=run["events_path"],
                decisions_path=run["decisions_path"],
                card_names=cards,
                target_player=commander,
            )
            row.update(trace)
            for card in cards:
                merge_card_summary(aggregate[card], trace["cards"][card])
        else:
            row.update({"event_count": 0, "decision_count": 0, "cards": empty_card_summary(cards)})
        seed_rows.append(row)
    review_rows = [classify_card(card, aggregate[card]) for card in cards]
    exercised = [row["card_name"] for row in review_rows if int(row["exercise_event_count"] or 0) > 0]
    unexercised = [row["card_name"] for row in review_rows if int(row["exercise_event_count"] or 0) == 0]
    generated_count = sum(1 for row in seed_rows if row["status"] == "forced_replay_generated")
    if not cards:
        status = "candidate_added_card_exposure_no_unexercised_adds"
        next_gate = "run_larger_equal_gate_if_battle_probe_audit_allows"
    elif generated_count == 0:
        status = "candidate_added_card_exposure_generation_failed"
        next_gate = "fix_forced_added_card_replay_generation"
    elif not unexercised:
        status = "candidate_added_card_forced_exposure_all_exercised_diagnostic_only"
        next_gate = "seek_natural_replay_confirmation_before_larger_equal_gate"
    else:
        status = "candidate_added_card_forced_exposure_blocks_battle_gate"
        next_gate = "expand_seed_window_or_review_unexercised_added_card_fit"
    blockers = ["forced_access_is_diagnostic_not_natural_gate"]
    if unexercised:
        blockers.append("forced_access_unexercised_added_cards:" + ",".join(unexercised))
    if generated_count < max(1, seed_count):
        blockers.append(f"forced_replay_generation_failures:{max(1, seed_count) - generated_count}")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_candidate_added_card_exposure_trace_generator",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "forced_access_replay_performed": generated_count > 0,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "natural_gate_satisfied_now": False,
        "input_artifacts": {
            "battle_probe_audit": rel(battle_probe_audit),
            "candidate_db": rel(candidate_db),
            "battle_replay": rel(battle_replay),
            "replay_dir": rel(replay_dir),
        },
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "focus_card_count": len(cards),
            "focus_cards": cards,
            "seed_start": seed_start,
            "seed_count": max(1, seed_count),
            "generated_replay_count": generated_count,
            "forced_access_mode": forced_access_mode,
            "exercised_added_cards": exercised,
            "unexercised_added_cards": unexercised,
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "review_rows": review_rows,
        "seed_reports": seed_rows,
        "policy": {
            "forced_access_boundary": "Forced access is diagnostic evidence only; it is not a natural battle gate.",
            "added_card_boundary": "An added card must be exercised in target-deck events before its swap evidence is trusted.",
            "promotion_boundary": "No candidate copy, deck mutation, battle gate, or promotion is opened by this report.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Candidate Added Card Exposure Trace Generator",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- focus_card_count: `{summary['focus_card_count']}`",
        f"- focus_cards: `{', '.join(summary['focus_cards'])}`",
        f"- seed_count: `{summary['seed_count']}`",
        f"- generated_replay_count: `{summary['generated_replay_count']}`",
        f"- forced_access_mode: `{summary['forced_access_mode']}`",
        f"- exercised_added_cards: `{summary['exercised_added_cards']}`",
        f"- unexercised_added_cards: `{summary['unexercised_added_cards']}`",
        f"- natural_gate_satisfied_now: `{str(payload['natural_gate_satisfied_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Review Rows",
        "",
        "| Card | Status | Forced Present | Exercise | Exposure | Decisions | Next Gate |",
        "| --- | --- | ---: | ---: | ---: | ---: | --- |",
    ]
    for row in payload["review_rows"]:
        lines.append(
            "| `{card}` | `{status}` | {forced} | {exercise} | {exposure} | {decisions} | `{next}` |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                forced=row.get("forced_access_moved_or_present_count"),
                exercise=row.get("exercise_event_count"),
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
    parser.add_argument("--battle-probe-audit", type=Path, default=DEFAULT_BATTLE_PROBE_AUDIT)
    parser.add_argument("--replay-dir", type=Path, default=DEFAULT_REPLAY_DIR)
    parser.add_argument("--seed-start", type=int, default=80)
    parser.add_argument("--seed-count", type=int, default=3)
    parser.add_argument("--forced-access-mode", default="opening_hand")
    parser.add_argument("--battle-replay", type=Path, default=DEFAULT_BATTLE_REPLAY)
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--real-opponent-seed", default="20260706")
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        battle_probe_audit=args.battle_probe_audit,
        replay_dir=args.replay_dir,
        seed_start=args.seed_start,
        seed_count=args.seed_count,
        forced_access_mode=args.forced_access_mode,
        battle_replay=args.battle_replay,
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
