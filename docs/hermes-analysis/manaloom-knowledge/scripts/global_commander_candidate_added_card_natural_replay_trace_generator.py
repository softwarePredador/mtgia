#!/usr/bin/env python3
"""Generate natural replay traces for unexercised candidate added cards.

This gate follows a blocked candidate battle-probe audit and checks whether the
added cards that were missing exercise can be drawn/cast/used without forced
access. It does not run a battle gate, mutate decks, or promote anything. A pass
only means the package can move to a larger equal battle gate.
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

from global_commander_candidate_added_card_exposure_trace_generator import (
    empty_card_summary,
    merge_card_summary,
    resolve_path,
    summarize_trace_files,
    unexercised_added_cards,
)
from global_commander_deck_contract_audit import REPO_ROOT


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_BATTLE_PROBE_AUDIT = (
    REPORT_DIR / "global_commander_candidate_battle_probe_audit_20260706_lorehold_profile_repair_package.json"
)
DEFAULT_BATTLE_REPLAY = SCRIPT_DIR / "battle_replay_v10_3.py"
DEFAULT_REPLAY_DIR = (
    REPORT_DIR / "global_commander_candidate_added_card_natural_replays_20260706_lorehold_profile_repair_package"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_candidate_added_card_natural_replay_trace_generator_20260706_lorehold_profile_repair_package"
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


def run_natural_replay_seed(
    *,
    seed: int,
    deck_id: str,
    db_path: Path,
    replay_dir: Path,
    battle_replay: Path,
    timeout: int,
    real_opponent_seed: str,
    focus_cards: list[str],
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> dict[str, Any]:
    replay_dir.mkdir(parents=True, exist_ok=True)
    replay_txt = replay_dir / f"natural_added_replay_seed_{seed}.txt"
    events_path = replay_dir / f"natural_added_replay_seed_{seed}.events.jsonl"
    decisions_path = replay_dir / f"natural_added_replay_seed_{seed}.decision_trace.jsonl"
    provenance_path = replay_dir / f"natural_added_deck_provenance_seed_{seed}.json"
    env = os.environ.copy()
    env.update(
        {
            "MANALOOM_KNOWLEDGE_DB": str(db_path),
            "MANALOOM_BATTLE_TARGET_DECK_ID": str(deck_id),
            "MANALOOM_BATTLE_REAL_OPPONENT_SEED": str(real_opponent_seed),
            "MANALOOM_FOCUS_ACCESS_CARDS": json.dumps(focus_cards, ensure_ascii=True),
            "REPLAY_SEED": str(seed),
            "REPLAY_OUT": str(replay_txt),
            "REPLAY_EVENTS_OUT": str(events_path),
            "DECISION_TRACE_OUT": str(decisions_path),
            "REPLAY_DECK_PROVENANCE_OUT": str(provenance_path),
        }
    )
    env.pop("MANALOOM_FORCE_FOCUS_ACCESS_MODE", None)
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
    if exercise > 0:
        status = "natural_added_card_exercised"
        next_gate = "include_in_larger_equal_gate_candidate_package"
    elif exposure > 0 or decisions > 0:
        status = "natural_added_card_seen_without_exercise_blocks_larger_gate"
        next_gate = "expand_natural_seed_window_or_review_nonuse_context"
    else:
        status = "natural_added_card_unseen_blocks_larger_gate"
        next_gate = "expand_natural_seed_window_or_review_add_accessibility"
    return {
        "card_name": card,
        "status": status,
        "exercise_event_count": exercise,
        "exposure_event_count": exposure,
        "decision_trace_count": decisions,
        "event_types": trace.get("event_types") or {},
        "first_exercise_event": trace.get("first_exercise_event"),
        "first_exposure_event": trace.get("first_exposure_event"),
        "first_decision_trace": trace.get("first_decision_trace"),
        "next_gate": next_gate,
    }


def build_report(
    *,
    battle_probe_audit: Path,
    replay_dir: Path = DEFAULT_REPLAY_DIR,
    seed_start: int = 100,
    seed_count: int = 5,
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
        run = run_natural_replay_seed(
            seed=seed,
            deck_id=deck_id,
            db_path=candidate_db,
            replay_dir=replay_dir,
            battle_replay=battle_replay,
            timeout=timeout,
            real_opponent_seed=real_opponent_seed,
            focus_cards=cards,
            runner=runner,
        )
        row: dict[str, Any] = {
            "seed": seed,
            "status": "natural_replay_generated" if run["returncode"] == 0 else "natural_replay_generation_failed",
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
    generated_count = sum(1 for row in seed_rows if row["status"] == "natural_replay_generated")
    larger_gate_allowed = bool(cards and generated_count > 0 and not unexercised)
    if not cards:
        status = "candidate_added_card_natural_replay_no_blocked_adds"
        next_gate = "run_larger_equal_battle_gate_if_probe_metrics_allow"
    elif generated_count == 0:
        status = "candidate_added_card_natural_replay_generation_failed"
        next_gate = "fix_natural_added_card_replay_generation"
    elif larger_gate_allowed:
        status = "candidate_added_card_natural_replay_all_exercised_ready_for_larger_gate"
        next_gate = "run_larger_equal_battle_gate"
    else:
        status = "candidate_added_card_natural_replay_blocks_larger_gate"
        next_gate = "expand_natural_seed_window_or_review_unexercised_added_card_fit"
    blockers: list[str] = []
    if unexercised:
        blockers.append("natural_replay_unexercised_added_cards:" + ",".join(unexercised))
    if generated_count < max(1, seed_count):
        blockers.append(f"natural_replay_generation_failures:{max(1, seed_count) - generated_count}")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_candidate_added_card_natural_replay_trace_generator",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "natural_replay_performed": generated_count > 0,
        "forced_access_used": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "larger_battle_gate_allowed_next": larger_gate_allowed,
        "candidate_copy_allowed_now": False,
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
            "exercised_added_cards": exercised,
            "unexercised_added_cards": unexercised,
            "next_gate": next_gate,
        },
        "larger_gate_blockers": blockers,
        "review_rows": review_rows,
        "seed_reports": seed_rows,
        "policy": {
            "natural_replay_boundary": "This report collects natural replay evidence only; it does not run the larger battle gate.",
            "larger_gate_boundary": "A larger equal battle gate may run only after blocker adds are naturally exercised or the package is revised.",
            "promotion_boundary": "No deck mutation or promotion is opened by this report.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Candidate Added Card Natural Replay Trace Generator",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- focus_card_count: `{summary['focus_card_count']}`",
        f"- focus_cards: `{', '.join(summary['focus_cards'])}`",
        f"- seed_count: `{summary['seed_count']}`",
        f"- generated_replay_count: `{summary['generated_replay_count']}`",
        f"- exercised_added_cards: `{summary['exercised_added_cards']}`",
        f"- unexercised_added_cards: `{summary['unexercised_added_cards']}`",
        f"- forced_access_used: `{str(payload['forced_access_used']).lower()}`",
        f"- larger_battle_gate_allowed_next: `{str(payload['larger_battle_gate_allowed_next']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Review Rows",
        "",
        "| Card | Status | Exercise | Exposure | Decisions | Next Gate |",
        "| --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in payload["review_rows"]:
        lines.append(
            "| `{card}` | `{status}` | {exercise} | {exposure} | {decisions} | `{next}` |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                exercise=row.get("exercise_event_count"),
                exposure=row.get("exposure_event_count"),
                decisions=row.get("decision_trace_count"),
                next=row.get("next_gate"),
            )
        )
    lines.extend(["", "## Larger Gate Blockers", ""])
    if payload["larger_gate_blockers"]:
        for blocker in payload["larger_gate_blockers"]:
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
    parser.add_argument("--battle-probe-audit", type=Path, default=DEFAULT_BATTLE_PROBE_AUDIT)
    parser.add_argument("--replay-dir", type=Path, default=DEFAULT_REPLAY_DIR)
    parser.add_argument("--seed-start", type=int, default=100)
    parser.add_argument("--seed-count", type=int, default=5)
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
