#!/usr/bin/env python3
"""Generate current-scope usage traces for contextual Commander stage cuts.

This gate runs structured replay generation against an isolated Commander DB
copy and summarizes whether contextual cut cards were exposed, decided on, or
actually used in events. It is trace generation only: it does not mutate any DB,
does not reclassify cuts, does not materialize candidates, and does not promote
or open a battle gate.
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

from global_commander_deck_contract_audit import REPO_ROOT
from master_optimizer_common import normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_CONTEXTUAL_EVIDENCE_REPORT = (
    REPORT_DIR / "global_commander_contextual_stage_cut_evidence_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_USAGE_TRACE_SCOUT = (
    REPORT_DIR / "global_commander_contextual_usage_trace_scout_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_BATTLE_REPLAY = SCRIPT_DIR / "battle_replay_v10_3.py"
DEFAULT_REPLAY_DIR = (
    REPORT_DIR / "global_commander_contextual_usage_trace_replays_20260705_kaalia_value_safe_stage1_repair_scope1"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_contextual_usage_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1"
)

USAGE_EVENT_TYPES = {
    "activated_ability",
    "cast_announced",
    "commander_cast",
    "cost_paid",
    "creature_cast",
    "spell_cast",
    "spell_resolved",
    "trigger_put_on_stack",
    "trigger_resolved",
    "tutor_resolved",
    "utility_artifact_activated",
}
EXPOSURE_EVENT_TYPES = {
    "turn_start",
    "turn_end",
    "draw_step",
    "card_drawn",
    "mulligan_result",
}


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


def iter_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    if not path.exists():
        return rows
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows


def target_cards(payload: Mapping[str, Any]) -> list[str]:
    cards = []
    for row in payload.get("contextual_evidence_rows") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            cards.append(str(row["card_name"]))
    return cards


def selected_db(payload: Mapping[str, Any]) -> Path:
    inputs = payload.get("input_artifacts") or {}
    value = str(inputs.get("selected_db") or "").strip()
    if not value:
        raise ValueError("contextual evidence report does not contain input_artifacts.selected_db")
    path = Path(value)
    return path if path.is_absolute() else REPO_ROOT / path


def card_mentioned(row: Mapping[str, Any], card_name: str) -> bool:
    encoded = json.dumps(row, sort_keys=True, ensure_ascii=True, default=str)
    return normalize_name(card_name) in normalize_name(encoded)


def empty_card_summary(card_names: list[str]) -> dict[str, dict[str, Any]]:
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
        for card in card_names
    }


def compact_row(row: Mapping[str, Any]) -> dict[str, Any]:
    compact = {
        "event": row.get("event") or row.get("decision_type") or row.get("actual_outcome"),
        "turn": row.get("turn"),
        "player": row.get("player") or row.get("active_player"),
        "card": row.get("card") or row.get("stack_object") or row.get("source"),
    }
    return {key: value for key, value in compact.items() if value not in (None, "")}


def row_belongs_to_target_player(row: Mapping[str, Any], target_player: str) -> bool:
    if not target_player:
        return True
    for key in ("player", "active_player", "attacker", "controller"):
        if str(row.get(key) or "") == target_player:
            return True
    return False


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
    for row in events:
        if not row_belongs_to_target_player(row, target_player):
            continue
        event_type = str(row.get("event") or "unknown")
        for card in card_names:
            if not card_mentioned(row, card):
                continue
            summary = cards[card]
            summary["event_types"][event_type] = int(summary["event_types"].get(event_type) or 0) + 1
            if event_type in USAGE_EVENT_TYPES:
                summary["usage_event_count"] += 1
                if summary["first_usage_event"] is None:
                    summary["first_usage_event"] = compact_row(row)
            elif event_type in EXPOSURE_EVENT_TYPES:
                summary["exposure_event_count"] += 1
                if summary["first_exposure_event"] is None:
                    summary["first_exposure_event"] = compact_row(row)
            else:
                summary["reference_event_count"] += 1
    for row in decisions:
        if not row_belongs_to_target_player(row, target_player):
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
        "target_player": target_player,
        "cards": cards,
    }


def load_provenance(path: Path) -> dict[str, Any]:
    payload = load_json(path) if path.exists() else {}
    decks = payload.get("decks") or []
    target = decks[0] if decks and isinstance(decks[0], Mapping) else {}
    return {
        "path": rel(path),
        "target_deck_id": target.get("target_deck_id"),
        "name": target.get("name"),
        "source_ref": target.get("source_ref"),
        "construction_is_valid": (target.get("construction_report") or {}).get("is_valid"),
        "construction_issues": (target.get("construction_report") or {}).get("issues") or [],
    }


def run_replay_seed(
    *,
    seed: int,
    deck_id: str,
    db_path: Path,
    replay_dir: Path,
    battle_replay: Path,
    timeout: int,
    real_opponent_seed: str,
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> dict[str, Any]:
    replay_dir.mkdir(parents=True, exist_ok=True)
    replay_txt = replay_dir / f"replay_seed_{seed}.txt"
    events_path = replay_dir / f"replay_seed_{seed}.events.jsonl"
    decisions_path = replay_dir / f"replay_seed_{seed}.decision_trace.jsonl"
    provenance_path = replay_dir / f"deck_provenance_seed_{seed}.json"
    env = os.environ.copy()
    env.update(
        {
            "MANALOOM_KNOWLEDGE_DB": str(db_path),
            "MANALOOM_BATTLE_TARGET_DECK_ID": str(deck_id),
            "MANALOOM_BATTLE_REAL_OPPONENT_SEED": str(real_opponent_seed),
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


def aggregate_cards(seed_rows: list[Mapping[str, Any]], card_names: list[str]) -> dict[str, dict[str, Any]]:
    aggregate = empty_card_summary(card_names)
    for seed_row in seed_rows:
        for card, summary in (seed_row.get("cards") or {}).items():
            if card not in aggregate:
                continue
            target = aggregate[card]
            for key in ("usage_event_count", "exposure_event_count", "decision_trace_count", "reference_event_count"):
                target[key] += int(summary.get(key) or 0)
            for event_type, count in (summary.get("event_types") or {}).items():
                target["event_types"][event_type] = int(target["event_types"].get(event_type) or 0) + int(count or 0)
            for first_key in ("first_usage_event", "first_exposure_event", "first_decision_trace"):
                if target[first_key] is None and summary.get(first_key):
                    target[first_key] = {
                        "seed": seed_row.get("seed"),
                        **summary[first_key],
                    }
    return aggregate


def build_report(
    *,
    contextual_evidence_report: Path,
    usage_trace_scout: Path | None = None,
    replay_dir: Path = DEFAULT_REPLAY_DIR,
    seed_start: int = 42,
    seed_count: int = 1,
    battle_replay: Path = DEFAULT_BATTLE_REPLAY,
    timeout: int = 300,
    real_opponent_seed: str = "20260705",
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> dict[str, Any]:
    contextual_payload = load_json(contextual_evidence_report)
    summary = contextual_payload.get("summary") or {}
    deck_id = str(summary.get("deck_id") or "")
    commander = str(summary.get("commander") or "")
    cards = target_cards(contextual_payload)
    db_path = selected_db(contextual_payload)
    seed_rows: list[dict[str, Any]] = []
    for seed in range(seed_start, seed_start + max(1, seed_count)):
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
        row: dict[str, Any] = {
            "seed": seed,
            "status": "replay_generated" if run["returncode"] == 0 else "replay_generation_failed",
            "returncode": run["returncode"],
            "replay_txt": rel(run["replay_txt"]),
            "events_path": rel(run["events_path"]),
            "decisions_path": rel(run["decisions_path"]),
            "provenance_path": rel(run["provenance_path"]),
            "stdout_tail": run["stdout_tail"],
            "stderr_tail": run["stderr_tail"],
            "provenance": load_provenance(run["provenance_path"]),
        }
        if run["returncode"] == 0:
            row.update(
                summarize_trace_files(
                    events_path=run["events_path"],
                    decisions_path=run["decisions_path"],
                    card_names=cards,
                    target_player=commander,
                )
            )
        else:
            row.update({"event_count": 0, "decision_count": 0, "cards": empty_card_summary(cards)})
        seed_rows.append(row)
    aggregate = aggregate_cards(seed_rows, cards)
    generated_count = sum(1 for row in seed_rows if row["status"] == "replay_generated")
    usage_cards = [card for card, row in aggregate.items() if int(row["usage_event_count"]) > 0]
    exposure_cards = [card for card, row in aggregate.items() if int(row["exposure_event_count"]) > 0]
    decision_cards = [card for card, row in aggregate.items() if int(row["decision_trace_count"]) > 0]
    missing_usage_cards = [card for card in cards if card not in usage_cards]
    if generated_count == 0:
        status = "contextual_usage_trace_generation_failed"
        next_gate = "fix_replay_generation_before_usage_trace_reclassification"
    elif len(usage_cards) == len(cards):
        status = "contextual_usage_trace_generated_all_current_usage_review_required"
        next_gate = "review_generated_usage_trace_before_value_safe_reclassification"
    elif usage_cards:
        status = "contextual_usage_trace_generated_partial_current_usage_review_required"
        next_gate = "review_used_cards_and_generate_focused_trace_for_missing_cards_before_reclassification"
    elif exposure_cards or decision_cards:
        status = "contextual_usage_trace_generated_exposure_without_usage"
        next_gate = "collect_negative_or_usage_decision_trace_for_seen_cards"
    else:
        status = "contextual_usage_trace_generated_no_target_exposure"
        next_gate = "increase_seed_count_or_force_access_trace_for_contextual_cards"
    blockers = []
    if missing_usage_cards:
        blockers.append("current_scope_usage_missing_for_cards:" + ",".join(missing_usage_cards))
    if generated_count < max(1, seed_count):
        blockers.append(f"replay_generation_failures:{max(1, seed_count) - generated_count}")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_contextual_usage_trace_generator",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_replay_performed": generated_count > 0,
        "battle_gate_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "input_artifacts": {
            "contextual_evidence_report": rel(contextual_evidence_report),
            "usage_trace_scout": rel(usage_trace_scout) if usage_trace_scout else "",
            "selected_db": rel(db_path),
            "battle_replay": rel(battle_replay),
            "replay_dir": rel(replay_dir),
        },
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "contextual_card_count": len(cards),
            "seed_start": seed_start,
            "seed_count": max(1, seed_count),
            "generated_replay_count": generated_count,
            "usage_event_card_count": len(usage_cards),
            "exposure_event_card_count": len(exposure_cards),
            "decision_trace_card_count": len(decision_cards),
            "usage_event_cards": usage_cards,
            "missing_usage_cards": missing_usage_cards,
            "exposure_event_cards": exposure_cards,
            "decision_trace_cards": decision_cards,
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "aggregate_card_trace": aggregate,
        "seed_reports": seed_rows,
        "policy": {
            "trace_generation_boundary": "Structured replay generation is evidence collection only, not a promotion battle gate.",
            "usage_boundary": "A card needs current-scope usage events or stronger focused trace before value-safe reclassification.",
            "mutation_boundary": "The selected SQLite DB is read as source; this script must not mutate deck_cards or PostgreSQL.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Contextual Usage Trace Generator",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- seed_start: `{summary['seed_start']}`",
        f"- seed_count: `{summary['seed_count']}`",
        f"- generated_replay_count: `{summary['generated_replay_count']}`",
        f"- usage_event_card_count: `{summary['usage_event_card_count']}`",
        f"- exposure_event_card_count: `{summary['exposure_event_card_count']}`",
        f"- decision_trace_card_count: `{summary['decision_trace_card_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_replay_performed: `{str(payload['battle_replay_performed']).lower()}`",
        f"- battle_gate_performed: `{str(payload['battle_gate_performed']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Aggregate Card Trace",
        "",
        "| Card | Usage Events | Exposure Events | Decision Traces | Event Types |",
        "| --- | ---: | ---: | ---: | --- |",
    ]
    for card, row in payload["aggregate_card_trace"].items():
        lines.append(
            "| `{card}` | {usage} | {exposure} | {decision} | `{events}` |".format(
                card=card,
                usage=row["usage_event_count"],
                exposure=row["exposure_event_count"],
                decision=row["decision_trace_count"],
                events=json.dumps(row.get("event_types") or {}, sort_keys=True),
            )
        )
    lines.extend(["", "## Seed Reports", ""])
    for row in payload["seed_reports"]:
        lines.append(
            "- seed `{seed}`: `{status}`, events `{events}`, decisions `{decisions}`, provenance `{source}`.".format(
                seed=row.get("seed"),
                status=row.get("status"),
                events=row.get("event_count"),
                decisions=row.get("decision_count"),
                source=(row.get("provenance") or {}).get("source_ref"),
            )
        )
    lines.extend(["", "## Blockers", ""])
    if payload["candidate_copy_blockers"]:
        for blocker in payload["candidate_copy_blockers"]:
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
    parser.add_argument("--contextual-evidence-report", type=Path, default=DEFAULT_CONTEXTUAL_EVIDENCE_REPORT)
    parser.add_argument("--usage-trace-scout", type=Path, default=DEFAULT_USAGE_TRACE_SCOUT)
    parser.add_argument("--replay-dir", type=Path, default=DEFAULT_REPLAY_DIR)
    parser.add_argument("--seed-start", type=int, default=42)
    parser.add_argument("--seed-count", type=int, default=1)
    parser.add_argument("--battle-replay", type=Path, default=DEFAULT_BATTLE_REPLAY)
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--real-opponent-seed", default="20260705")
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        contextual_evidence_report=args.contextual_evidence_report,
        usage_trace_scout=args.usage_trace_scout,
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
