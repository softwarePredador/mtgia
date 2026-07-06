#!/usr/bin/env python3
"""Generate natural traces for alternative ramp cut targets.

This gate consumes the ramp forced-recovery router and runs current-scope
natural replays for alternative ramp cut targets that still lack card-level
trace. It is evidence collection only and does not open candidate copy,
mutation, battle-gate, or promotion paths.
"""

from __future__ import annotations

import argparse
import json
import subprocess
from collections.abc import Callable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_contextual_usage_trace_generator import empty_card_summary, run_replay_seed, summarize_trace_files
from global_commander_deck_contract_audit import REPO_ROOT, rel


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_RECOVERY_REPORT = REPORT_DIR / "global_commander_ramp_cut_forced_recovery_router_20260706_current.json"
DEFAULT_BATTLE_REPLAY = SCRIPT_DIR / "battle_replay_v10_3.py"
DEFAULT_REPLAY_DIR = REPORT_DIR / "global_commander_ramp_alternative_cut_trace_replays_20260706_current"
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_ramp_alternative_cut_trace_generator_20260706_current"

ALTERNATIVE_TRACE_STATUS = "alternative_cut_needs_current_scope_trace"


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


def focus_cards(recovery_payload: Mapping[str, Any]) -> list[str]:
    cards: list[str] = []
    for row in recovery_payload.get("alternative_cut_rows") or []:
        if not isinstance(row, Mapping) or row.get("status") != ALTERNATIVE_TRACE_STATUS:
            continue
        card = str(row.get("card_name") or "").strip()
        if card and card not in cards:
            cards.append(card)
    return cards


def merge_card_summary(target: dict[str, Any], source: Mapping[str, Any]) -> None:
    for key in ("usage_event_count", "exposure_event_count", "decision_trace_count", "reference_event_count"):
        target[key] = int(target.get(key) or 0) + int(source.get(key) or 0)
    events = target.setdefault("event_types", {})
    for event, count in (source.get("event_types") or {}).items():
        events[str(event)] = int(events.get(str(event)) or 0) + int(count or 0)
    for key in ("first_usage_event", "first_exposure_event", "first_decision_trace"):
        if target.get(key) is None and source.get(key) is not None:
            target[key] = source.get(key)


def classify_card(card: str, summary: Mapping[str, Any]) -> dict[str, Any]:
    usage = int(summary.get("usage_event_count") or 0)
    exposure = int(summary.get("exposure_event_count") or 0)
    decisions = int(summary.get("decision_trace_count") or 0)
    if usage > 0:
        status = "alternative_ramp_cut_natural_trace_usage_observed_blocks_cut"
        decision = "not_cut_safe_after_current_scope_usage"
        next_gate = "find_different_ramp_cut_or_pivot_after_alternative_trace"
    elif exposure > 0 or decisions > 0:
        status = "alternative_ramp_cut_seen_without_usage_needs_manual_negative_review"
        decision = "manual_negative_trace_review_only"
        next_gate = "manual_negative_trace_review_for_alternative_ramp_cut"
    else:
        status = "alternative_ramp_cut_no_current_exposure_needs_force_access_or_more_trace"
        decision = "no_cut_clearance_without_access"
        next_gate = "force_access_or_expand_trace_for_alternative_ramp_cut"
    return {
        "card_name": card,
        "status": status,
        "decision": decision,
        "usage_event_count": usage,
        "exposure_event_count": exposure,
        "decision_trace_count": decisions,
        "event_types": summary.get("event_types") or {},
        "first_usage_event": summary.get("first_usage_event"),
        "first_exposure_event": summary.get("first_exposure_event"),
        "first_decision_trace": summary.get("first_decision_trace"),
        "next_gate": next_gate,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "mutation_allowed": False,
    }


def choose_status(review_rows: list[Mapping[str, Any]], cards: list[str]) -> tuple[str, str]:
    usage_blocked = [row for row in review_rows if row["status"] == "alternative_ramp_cut_natural_trace_usage_observed_blocks_cut"]
    manual = [row for row in review_rows if row["status"] == "alternative_ramp_cut_seen_without_usage_needs_manual_negative_review"]
    no_exposure = [
        row
        for row in review_rows
        if row["status"] == "alternative_ramp_cut_no_current_exposure_needs_force_access_or_more_trace"
    ]
    if usage_blocked:
        return (
            "ramp_alternative_cut_trace_blocks_used_targets",
            "find_different_ramp_cut_or_pivot_after_alternative_trace",
        )
    if manual:
        return (
            "ramp_alternative_cut_trace_needs_manual_negative_review",
            "manual_negative_trace_review_for_alternative_ramp_cut",
        )
    if no_exposure:
        return (
            "ramp_alternative_cut_trace_needs_force_access_or_more_trace",
            "force_access_or_expand_trace_for_alternative_ramp_cut",
        )
    if cards:
        return ("ramp_alternative_cut_trace_inconclusive", "expand_trace_for_alternative_ramp_cut")
    return ("ramp_alternative_cut_trace_no_targets", "expand_external_ramp_cut_or_pivot_role_axis")


def build_report(
    *,
    recovery_report: Path,
    battle_replay: Path = DEFAULT_BATTLE_REPLAY,
    replay_dir: Path = DEFAULT_REPLAY_DIR,
    seed_start: int = 110,
    seed_count: int = 3,
    timeout: int = 300,
    real_opponent_seed: str = "20260706",
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> dict[str, Any]:
    recovery_payload = load_json(recovery_report)
    artifacts = recovery_payload.get("input_artifacts") or {}
    db_path = resolve_path(artifacts.get("source_db"), default=SCRIPT_DIR / "knowledge.db")
    deck_id = str(recovery_payload.get("deck_id") or "")
    commander = str(recovery_payload.get("commander") or "")
    cards = focus_cards(recovery_payload)
    aggregate = empty_card_summary(cards)
    seed_rows = []
    for seed in range(seed_start, seed_start + max(1, seed_count)):
        if not cards:
            break
        run = run_replay_seed(
            seed=seed,
            deck_id=deck_id,
            db_path=db_path,
            replay_dir=replay_dir,
            battle_replay=battle_replay,
            timeout=timeout,
            real_opponent_seed=real_opponent_seed,
            runner=runner,
        )
        row_status = "alternative_ramp_cut_replay_generated" if run["returncode"] == 0 else "alternative_ramp_cut_replay_failed"
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
        for card in cards:
            merge_card_summary(aggregate[card], trace_summary["cards"][card])
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
            }
        )
    review_rows = [classify_card(card, aggregate[card]) for card in cards]
    usage_blocked = [row["card_name"] for row in review_rows if row["status"] == "alternative_ramp_cut_natural_trace_usage_observed_blocks_cut"]
    manual = [row["card_name"] for row in review_rows if row["status"] == "alternative_ramp_cut_seen_without_usage_needs_manual_negative_review"]
    no_exposure = [
        row["card_name"]
        for row in review_rows
        if row["status"] == "alternative_ramp_cut_no_current_exposure_needs_force_access_or_more_trace"
    ]
    status, next_gate = choose_status(review_rows, cards)
    blockers = []
    if usage_blocked:
        blockers.append("alternative_ramp_cut_usage_observed_blocks_cut:" + ",".join(usage_blocked))
    if manual:
        blockers.append("alternative_ramp_cut_manual_negative_review_required:" + ",".join(manual))
    if no_exposure:
        blockers.append("alternative_ramp_cut_no_exposure_requires_force_or_more_trace:" + ",".join(no_exposure))
    blockers.append("candidate_copy_closed_after_alternative_ramp_cut_trace")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_ramp_alternative_cut_trace_generator",
        "deck_id": deck_id,
        "commander": commander,
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_replay_performed": bool(seed_rows),
        "battle_gate_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "recovery_report": artifact_rel(recovery_report),
            "source_db": artifact_rel(db_path),
            "battle_replay": artifact_rel(battle_replay),
            "replay_dir": artifact_rel(replay_dir),
        },
        "summary": {
            "focus_card_count": len(cards),
            "focus_cards": cards,
            "seed_start": seed_start,
            "seed_count": max(1, seed_count) if cards else 0,
            "generated_replay_count": sum(1 for row in seed_rows if row.get("status") == "alternative_ramp_cut_replay_generated"),
            "usage_blocked_count": len(usage_blocked),
            "manual_review_count": len(manual),
            "no_exposure_count": len(no_exposure),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "review_rows": review_rows,
        "seed_rows": seed_rows,
        "candidate_copy_blockers": blockers,
        "policy": {
            "natural_trace_boundary": "Natural trace is evidence collection only, not a battle gate.",
            "alternative_cut_boundary": "Alternative ramp cuts need card-level use or negative review before any cut claim.",
            "promotion_boundary": "No candidate copy, deck mutation, battle gate, or promotion is opened by this report.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Ramp Alternative Cut Trace Generator",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{payload['commander']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- focus_card_count: `{summary['focus_card_count']}`",
        f"- focus_cards: `{', '.join(summary['focus_cards'])}`",
        f"- seed_count: `{summary['seed_count']}`",
        f"- generated_replay_count: `{summary['generated_replay_count']}`",
        f"- usage_blocked_count: `{summary['usage_blocked_count']}`",
        f"- manual_review_count: `{summary['manual_review_count']}`",
        f"- no_exposure_count: `{summary['no_exposure_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_replay_performed: `{str(payload['battle_replay_performed']).lower()}`",
        f"- battle_gate_performed: `{str(payload['battle_gate_performed']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Review Rows",
        "",
        "| Card | Status | Usage | Exposure | Decisions | Next Gate |",
        "| --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in payload["review_rows"]:
        lines.append(
            "| `{card}` | `{status}` | {usage} | {exposure} | {decisions} | `{next}` |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                usage=row.get("usage_event_count"),
                exposure=row.get("exposure_event_count"),
                decisions=row.get("decision_trace_count"),
                next=row.get("next_gate"),
            )
        )
    if not payload["review_rows"]:
        lines.append("| none |  |  |  |  |")
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
    parser.add_argument("--recovery-report", type=Path, default=DEFAULT_RECOVERY_REPORT)
    parser.add_argument("--battle-replay", type=Path, default=DEFAULT_BATTLE_REPLAY)
    parser.add_argument("--replay-dir", type=Path, default=DEFAULT_REPLAY_DIR)
    parser.add_argument("--seed-start", type=int, default=110)
    parser.add_argument("--seed-count", type=int, default=3)
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--real-opponent-seed", default="20260706")
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        recovery_report=args.recovery_report,
        battle_replay=args.battle_replay,
        replay_dir=args.replay_dir,
        seed_start=args.seed_start,
        seed_count=args.seed_count,
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
