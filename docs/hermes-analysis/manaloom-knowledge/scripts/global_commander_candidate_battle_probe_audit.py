#!/usr/bin/env python3
"""Audit a global Commander candidate-copy battle/replay probe.

This report does not run battles and does not promote decks. It consolidates a
small equal-seed battle probe plus one structured replay into a gate verdict:
whether the candidate can continue to a larger battle gate, or whether promotion
stays blocked because the candidate underperformed or added cards were not
exercised in replay evidence.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_candidate_battle_probe_audit_20260705_kaalia_nonland_floor"
EXERCISE_EVENT_NAMES = {
    "activated_ability",
    "additional_cost_paid",
    "board_wipe_resolved",
    "cast_announced",
    "class_level_gained",
    "commander_cast",
    "conditional_mana_life_cost_paid",
    "cost_paid",
    "creature_cast",
    "discard_then_draw",
    "draw_cards_resolved",
    "end_step_instant",
    "instant_removal",
    "land_played",
    "land_tax_trigger_resolved",
    "lorehold_upkeep_rummage",
    "miracle_cast",
    "permanent_moved_from_battlefield",
    "recursion_resolved",
    "removal_resolved",
    "spell_cast",
    "spell_resolved",
    "topdeck_manipulation_activated",
    "treasure_created",
    "trigger_resolved",
    "utility_artifact_activated",
    "utility_land_activated",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def safe_rel(path: Path) -> str:
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


def deck_card_counter(db_path: Path, deck_id: int) -> Counter[str]:
    with sqlite3.connect(db_path) as conn:
        rows = conn.execute(
            "SELECT card_name, COALESCE(quantity, 1) FROM deck_cards WHERE deck_id=?",
            (deck_id,),
        ).fetchall()
    counts: Counter[str] = Counter()
    for name, quantity in rows:
        if str(name or "").strip():
            counts[str(name)] += int(quantity or 1)
    return counts


def commander_name(db_path: Path, deck_id: int) -> str:
    with sqlite3.connect(db_path) as conn:
        row = conn.execute(
            """
            SELECT card_name
            FROM deck_cards
            WHERE deck_id=? AND COALESCE(is_commander, 0)=1
            ORDER BY card_name
            LIMIT 1
            """,
            (deck_id,),
        ).fetchone()
    return str(row[0]) if row else ""


def compare_decks(base_db: Path, candidate_db: Path, deck_id: int) -> dict[str, Any]:
    base = deck_card_counter(base_db, deck_id)
    candidate = deck_card_counter(candidate_db, deck_id)
    added: list[str] = []
    cut: list[str] = []
    for name in sorted(set(base) | set(candidate)):
        delta = candidate[name] - base[name]
        if delta > 0:
            added.extend([name] * delta)
        elif delta < 0:
            cut.extend([name] * abs(delta))
    return {
        "deck_id": deck_id,
        "base_count": sum(base.values()),
        "candidate_count": sum(candidate.values()),
        "added_cards": added,
        "cut_cards": cut,
    }


def metrics_summary(path: Path) -> dict[str, Any]:
    payload = load_json(path)
    meta = payload.get("metadata") or {}
    return {
        "path": safe_rel(path),
        "win_rate": float(meta.get("win_rate") or 0.0),
        "wins": int(meta.get("wins") or 0),
        "losses": int(meta.get("losses") or 0),
        "stalls": int(meta.get("stalls") or 0),
        "total_games": int(meta.get("total_games") or 0),
        "games_per_opponent": int(meta.get("games_per_opponent") or 0),
        "opponents": int(meta.get("opponents") or 0),
        "opponent_kind": meta.get("opponent_kind"),
        "evaluation_mode": meta.get("evaluation_mode"),
        "evaluation_target_player": meta.get("evaluation_target_player"),
        "event_counts": payload.get("event_counts") or {},
        "warnings": payload.get("warnings") or [],
    }


def card_mentions(
    rows: list[dict[str, Any]],
    cards: list[str],
    *,
    exercise_event_names: set[str] | None = None,
) -> dict[str, dict[str, Any]]:
    evidence = {
        card: {
            "mention_count": 0,
            "exercise_count": 0,
            "events": {},
            "exercise_events": {},
            "example": None,
            "exercise_example": None,
        }
        for card in cards
    }
    for row in rows:
        encoded = json.dumps(row, sort_keys=True, ensure_ascii=True, default=str)
        for card in cards:
            if card not in encoded:
                continue
            evidence[card]["mention_count"] += 1
            event = str(row.get("event") or row.get("actual_outcome") or row.get("decision") or "unknown")
            evidence[card]["events"][event] = int(evidence[card]["events"].get(event, 0)) + 1
            if evidence[card]["example"] is None:
                evidence[card]["example"] = row
            if exercise_event_names is not None and event in exercise_event_names:
                evidence[card]["exercise_count"] += 1
                evidence[card]["exercise_events"][event] = int(
                    evidence[card]["exercise_events"].get(event, 0)
                ) + 1
                if evidence[card]["exercise_example"] is None:
                    evidence[card]["exercise_example"] = row
    return evidence


def replay_summary(replay_dir: Path, *, commander: str, added_cards: list[str]) -> dict[str, Any]:
    events_path = replay_dir / "replay.events.jsonl"
    decisions_path = replay_dir / "replay.decision_trace.jsonl"
    provenance_path = replay_dir / "deck_provenance.json"
    events = iter_jsonl(events_path)
    decisions = iter_jsonl(decisions_path)
    provenance = load_json(provenance_path) if provenance_path.exists() else {}
    provenance_names = [
        str(row.get("name") or "")
        for row in provenance.get("decks", [])
        if isinstance(row, Mapping)
    ]
    stale_lorehold_mentions = 0
    if commander and not commander.lower().startswith("lorehold, the historian"):
        for row in events:
            if "Lorehold" in json.dumps(row, sort_keys=True, ensure_ascii=True, default=str):
                stale_lorehold_mentions += 1
        for name in provenance_names:
            if "Lorehold" in name:
                stale_lorehold_mentions += 1
    event_evidence = card_mentions(
        events,
        added_cards,
        exercise_event_names=EXERCISE_EVENT_NAMES,
    )
    decision_evidence = card_mentions(decisions, added_cards)
    exercised = [
        card
        for card in added_cards
        if event_evidence.get(card, {}).get("exercise_count", 0) > 0
    ]
    event_observed_only = [
        card
        for card in added_cards
        if event_evidence.get(card, {}).get("mention_count", 0) > 0
        and event_evidence.get(card, {}).get("exercise_count", 0) == 0
    ]
    decision_only = [
        card
        for card in added_cards
        if event_evidence.get(card, {}).get("mention_count", 0) == 0
        and decision_evidence.get(card, {}).get("mention_count", 0) > 0
    ]
    unobserved = [
        card
        for card in added_cards
        if event_evidence.get(card, {}).get("mention_count", 0) == 0
        and decision_evidence.get(card, {}).get("mention_count", 0) == 0
    ]
    return {
        "replay_dir": safe_rel(replay_dir),
        "events_path": safe_rel(events_path),
        "decisions_path": safe_rel(decisions_path),
        "provenance_path": safe_rel(provenance_path),
        "event_count": len(events),
        "decision_count": len(decisions),
        "provenance_names": provenance_names,
        "stale_lorehold_mentions": stale_lorehold_mentions,
        "added_card_event_evidence": event_evidence,
        "added_card_decision_evidence": decision_evidence,
        "added_cards_exercised_in_events": exercised,
        "added_cards_seen_without_exercise": event_observed_only,
        "added_cards_decision_only": decision_only,
        "added_cards_unobserved": unobserved,
        "added_cards_unexercised_in_events": [
            card for card in added_cards if card not in set(exercised)
        ],
    }


def build_payload(
    *,
    base_db: Path,
    candidate_db: Path,
    deck_id: int,
    base_metrics: Path,
    candidate_metrics: Path,
    replay_dir: Path,
) -> dict[str, Any]:
    commander = commander_name(candidate_db, deck_id)
    deck_diff = compare_decks(base_db, candidate_db, deck_id)
    base = metrics_summary(base_metrics)
    candidate = metrics_summary(candidate_metrics)
    replay = replay_summary(replay_dir, commander=commander, added_cards=deck_diff["added_cards"])
    delta = candidate["win_rate"] - base["win_rate"]
    same_sample = (
        base["total_games"] == candidate["total_games"]
        and base["opponents"] == candidate["opponents"]
        and base["opponent_kind"] == candidate["opponent_kind"]
    )
    blocker_reasons: list[str] = []
    if not same_sample:
        blocker_reasons.append("battle_probe_sample_mismatch")
    if delta < 0:
        blocker_reasons.append("candidate_underperformed_base_probe")
    if replay["stale_lorehold_mentions"]:
        blocker_reasons.append("replay_contains_stale_lorehold_target_mentions")
    if replay["added_cards_unexercised_in_events"]:
        blocker_reasons.append("added_cards_not_exercised_in_replay_events")
    status = "battle_probe_blocks_promotion" if blocker_reasons else "battle_probe_ready_for_larger_gate"
    sample_games = candidate["total_games"] if candidate["total_games"] else base["total_games"]
    return {
        "generated_at": utc_now(),
        "artifact_type": "global_commander_candidate_battle_probe_audit",
        "status": status,
        "deck_id": deck_id,
        "commander": commander,
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_probe_performed": True,
        "promotion_allowed": False,
        "larger_battle_gate_required": True,
        "input_artifacts": {
            "base_db": safe_rel(base_db),
            "candidate_db": safe_rel(candidate_db),
            "base_metrics": safe_rel(base_metrics),
            "candidate_metrics": safe_rel(candidate_metrics),
            "replay_dir": safe_rel(replay_dir),
        },
        "deck_diff": deck_diff,
        "battle_metrics": {
            "base": base,
            "candidate": candidate,
            "win_rate_delta": delta,
            "same_sample_shape": same_sample,
        },
        "replay": replay,
        "blocker_reasons": blocker_reasons,
        "policy": {
            "battle_sample": f"The {sample_games}-game equal-sample probe/gate is diagnostic only and cannot promote a deck by itself.",
            "card_exposure": "Added cards must be drawn/cast/used in replay events before card-level swap evidence is trusted.",
            "promotion": "Promotion remains closed until larger equal battle gate and replay trace pass.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    metrics = payload["battle_metrics"]
    replay = payload["replay"]
    lines = [
        "# Global Commander Candidate Battle Probe Audit",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- commander: `{payload['commander']}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- larger_battle_gate_required: `{str(payload['larger_battle_gate_required']).lower()}`",
        "",
        "## Battle Metrics",
        "",
        f"- base_wr: `{metrics['base']['win_rate']:.1f}`",
        f"- candidate_wr: `{metrics['candidate']['win_rate']:.1f}`",
        f"- win_rate_delta: `{metrics['win_rate_delta']:.1f}`",
        f"- same_sample_shape: `{str(metrics['same_sample_shape']).lower()}`",
        "",
        "## Deck Diff",
        "",
        f"- added_cards: `{payload['deck_diff']['added_cards']}`",
        f"- cut_cards: `{payload['deck_diff']['cut_cards']}`",
        "",
        "## Replay Evidence",
        "",
        f"- replay_dir: `{replay['replay_dir']}`",
        f"- stale_lorehold_mentions: `{replay['stale_lorehold_mentions']}`",
        f"- added_cards_exercised_in_events: `{replay['added_cards_exercised_in_events']}`",
        f"- added_cards_seen_without_exercise: `{replay['added_cards_seen_without_exercise']}`",
        f"- added_cards_decision_only: `{replay['added_cards_decision_only']}`",
        f"- added_cards_unobserved: `{replay['added_cards_unobserved']}`",
        f"- added_cards_unexercised_in_events: `{replay['added_cards_unexercised_in_events']}`",
        "",
        "## Blockers",
        "",
    ]
    if payload["blocker_reasons"]:
        for reason in payload["blocker_reasons"]:
            lines.append(f"- `{reason}`")
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
    parser.add_argument("--base-db", type=Path, required=True)
    parser.add_argument("--candidate-db", type=Path, required=True)
    parser.add_argument("--deck-id", type=int, required=True)
    parser.add_argument("--base-metrics", type=Path, required=True)
    parser.add_argument("--candidate-metrics", type=Path, required=True)
    parser.add_argument("--replay-dir", type=Path, required=True)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_payload(
        base_db=args.base_db,
        candidate_db=args.candidate_db,
        deck_id=args.deck_id,
        base_metrics=args.base_metrics,
        candidate_metrics=args.candidate_metrics,
        replay_dir=args.replay_dir,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
