#!/usr/bin/env python3
"""Compare ManaLoom replay events against a 17Lands replay profile.

This is a read-only calibration gate. It does not decide that 17Lands behavior
is correct for Commander. It highlights when a ManaLoom battle replay is far
outside a real Arena cadence for land drops, spell actions, combat damage, and
positive mana spend. It can also report whether candidate cards were actually
observed before deckbuilder scoring.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
from typing import Any


DEFAULT_PRIOR_JSON = Path(
    "docs/hermes-analysis/master_optimizer_reports/"
    "seventeenlands_replay_profile_lci_premierdraft_sample_20260628.json"
)


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, indent=2, sort_keys=True)


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def iter_jsonl(path: Path) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        text = line.strip()
        if not text:
            continue
        try:
            payload = json.loads(text)
        except json.JSONDecodeError as exc:
            raise ValueError(f"{path}:{line_number}: invalid JSONL event") from exc
        if isinstance(payload, dict):
            events.append(payload)
    return events


def normalize_text(value: Any) -> str:
    return " ".join(str(value or "").strip().lower().split())


def parse_int(value: Any) -> int | None:
    if value is None or value == "":
        return None
    try:
        return int(float(str(value)))
    except ValueError:
        return None


def parse_float(value: Any) -> float | None:
    if value is None or value == "":
        return None
    try:
        return float(str(value))
    except ValueError:
        return None


def event_type(event: dict[str, Any]) -> str:
    for key in ("event_type", "type", "event", "kind", "action"):
        value = event.get(key)
        if value:
            return normalize_text(value).replace(" ", "_")
    return "unknown"


def event_turn(event: dict[str, Any]) -> int | None:
    for key in ("turn", "turn_number", "game_turn"):
        value = parse_int(event.get(key))
        if value is not None:
            return value
    return None


def event_value(event: dict[str, Any]) -> float | None:
    mana_before = parse_float(event.get("mana_before"))
    mana_after = parse_float(event.get("mana_after"))
    if mana_before is not None and mana_after is not None:
        return max(0.0, mana_before - mana_after)
    for key in ("value", "amount", "damage", "mana_spent"):
        value = parse_float(event.get(key))
        if value is not None:
            return value
    return None


def event_card_tokens(event: dict[str, Any]) -> set[str]:
    tokens: set[str] = set()
    for key in ("card_name", "name", "card", "source_card", "target_card"):
        value = normalize_text(event.get(key))
        if value:
            tokens.add(value)
    for key in ("arena_id", "card_id", "source_arena_id", "target_arena_id"):
        value = str(event.get(key) or "").strip()
        if value:
            tokens.add(value)
    return tokens


def classify_event(kind: str) -> str | None:
    if kind in {"play_land", "land_played"} or ("land" in kind and "play" in kind):
        return "land_play_entries"
    if "combat_damage" in kind:
        return "total_combat_damage"
    if kind == "cost_paid" or kind == "mana_spent" or "mana_spent" in kind:
        return "active_mana_spent"
    if "cast" in kind and "creature" in kind and "noncreature" not in kind:
        return "creature_cast_entries"
    if "cast" in kind:
        return "noncreature_cast_entries"
    return None


def infer_game_count(events: list[dict[str, Any]], explicit_game_count: int | None) -> int:
    if explicit_game_count is not None:
        return max(1, explicit_game_count)
    game_ids: set[str] = set()
    for event in events:
        for key in ("game_id", "battle_id", "match_id", "replay_id"):
            value = event.get(key)
            if value:
                game_ids.add(str(value))
                break
    return max(1, len(game_ids) if game_ids else (1 if events else 0))


def infer_player_slots(events: list[dict[str, Any]], explicit_player_slots: int | None) -> int:
    if explicit_player_slots is not None:
        return max(1, explicit_player_slots)
    players: set[str] = set()
    for event in events:
        for key in ("player", "active_player"):
            value = normalize_text(event.get(key))
            if value:
                players.add(value)
                break
    return max(1, len(players) if players else 1)


def summarize_events(
    events: list[dict[str, Any]],
    *,
    candidate_cards: list[str],
    game_count: int,
    player_slots: int,
) -> dict[str, Any]:
    per_turn: dict[str, Counter[str]] = {}
    mana_sum: Counter[str] = Counter()
    mana_observations: Counter[str] = Counter()
    candidate_keys = {normalize_text(card): card for card in candidate_cards}
    candidate_report = {
        original: {
            "by_event_type": {},
            "first_turn": None,
            "observed": False,
            "total_events": 0,
        }
        for original in candidate_cards
    }

    for event in events:
        turn = event_turn(event)
        if turn is None or turn < 1:
            continue
        kind = event_type(event)
        metric = classify_event(kind)
        bucket = per_turn.setdefault(str(turn), Counter())
        if metric == "active_mana_spent":
            value = event_value(event)
            if value is not None and value > 0:
                mana_sum[str(turn)] += value
                mana_observations[str(turn)] += 1
        elif metric == "total_combat_damage":
            bucket[metric] += event_value(event) or 0.0
        elif metric is not None:
            bucket[metric] += 1
            if metric in {"creature_cast_entries", "noncreature_cast_entries"}:
                bucket["spell_action_entries"] += 1

        tokens = event_card_tokens(event)
        for normalized, original in candidate_keys.items():
            if normalized not in tokens:
                continue
            row = candidate_report[original]
            row["observed"] = True
            row["total_events"] += 1
            row["by_event_type"][kind] = row["by_event_type"].get(kind, 0) + 1
            if row["first_turn"] is None or turn < row["first_turn"]:
                row["first_turn"] = turn

    turn_summary: dict[str, dict[str, Any]] = {}
    for turn, counts in sorted(per_turn.items(), key=lambda item: int(item[0])):
        observations = int(mana_observations[turn])
        turn_summary[turn] = {
            "active_mana_spent_avg_positive": round(mana_sum[turn] / observations, 3)
            if observations
            else None,
            "active_mana_spent_positive_observations": observations,
            "creature_cast_entries": int(counts["creature_cast_entries"]),
            "land_play_entries": int(counts["land_play_entries"]),
            "noncreature_cast_entries": int(counts["noncreature_cast_entries"]),
            "spell_action_entries": int(counts["spell_action_entries"]),
            "total_combat_damage": float(counts["total_combat_damage"]),
        }

    return {
        "candidate_observations": candidate_report,
        "event_count": len(events),
        "game_count": game_count,
        "player_slots": player_slots,
        "turn_behavior_metrics": turn_summary,
    }


def per_player_slot(value: float | int | None, denominator: int) -> float | None:
    if value is None:
        return None
    return round(float(value) / max(1, denominator), 4)


def ratio(observed: float | None, prior: float | None) -> float | None:
    if observed is None or prior is None or prior == 0:
        return None
    return round(observed / prior, 4)


def compare_to_prior(prior: dict[str, Any], observed: dict[str, Any]) -> dict[str, Any]:
    prior_rows = int(prior.get("rows_sampled") or 1)
    observed_games = int(observed["game_count"] or 1)
    prior_player_slots = 2
    observed_player_slots = int(observed.get("player_slots") or 1)
    prior_denominator = prior_rows * prior_player_slots
    observed_denominator = observed_games * observed_player_slots
    prior_metrics = prior["sample_summary"]["turn_behavior_metrics"]
    observed_metrics = observed["turn_behavior_metrics"]
    keys = [
        "land_play_entries",
        "spell_action_entries",
        "creature_cast_entries",
        "noncreature_cast_entries",
        "total_combat_damage",
    ]
    comparison: dict[str, Any] = {}
    flags: list[dict[str, Any]] = []
    all_turns = sorted(
        {int(turn) for turn in prior_metrics} | {int(turn) for turn in observed_metrics}
    )
    for turn_number in all_turns:
        turn = str(turn_number)
        prior_turn = prior_metrics.get(turn, {})
        observed_turn = observed_metrics.get(turn, {})
        row: dict[str, Any] = {}
        for key in keys:
            prior_per_slot = per_player_slot(prior_turn.get(key), prior_denominator)
            observed_per_slot = per_player_slot(observed_turn.get(key), observed_denominator)
            metric_ratio = ratio(observed_per_slot, prior_per_slot)
            row[key] = {
                "observed_per_player_slot": observed_per_slot,
                "prior_per_player_slot": prior_per_slot,
                "ratio": metric_ratio,
            }
            if metric_ratio is not None and (metric_ratio >= 2.0 or metric_ratio <= 0.5):
                flags.append(
                    {
                        "metric": key,
                        "observed_per_player_slot": observed_per_slot,
                        "prior_per_player_slot": prior_per_slot,
                        "ratio": metric_ratio,
                        "turn": turn_number,
                    }
                )
        prior_mana = prior_turn.get("active_mana_spent_avg_positive")
        observed_mana = observed_turn.get("active_mana_spent_avg_positive")
        row["active_mana_spent_avg_positive"] = {
            "observed": observed_mana,
            "prior": prior_mana,
            "ratio": ratio(observed_mana, prior_mana),
        }
        comparison[turn] = row

    for card, card_report in observed["candidate_observations"].items():
        if not card_report["observed"]:
            flags.append(
                {
                    "card": card,
                    "metric": "candidate_observation",
                    "reason": "candidate_card_never_observed",
                }
            )

    return {
        "comparison_by_turn": comparison,
        "flags": flags,
        "prior_rows_sampled": prior_rows,
        "prior_player_slots": prior_player_slots,
        "observed_game_count": observed_games,
        "observed_player_slots": observed_player_slots,
    }


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# 17Lands Battle Prior Comparison",
        "",
        f"- Prior: `{report['prior_path']}`",
        f"- Events: `{report['events_path']}`",
        f"- Event count: `{report['observed_summary']['event_count']}`",
        f"- Game count: `{report['observed_summary']['game_count']}`",
        f"- Player slots: `{report['observed_summary']['player_slots']}`",
        f"- PostgreSQL writes: `{report['postgres_writes']}`",
        "",
        "## Flags",
        "",
    ]
    if report["comparison"]["flags"]:
        for flag in report["comparison"]["flags"][:40]:
            lines.append(f"- `{flag}`")
    else:
        lines.append("- No ratio or candidate-observation flags.")
    lines.extend(["", "## Candidate Observations", ""])
    for card, payload in report["observed_summary"]["candidate_observations"].items():
        lines.append(f"- {card}: `{payload}`")
    lines.extend(["", "## Turn Comparison", ""])
    for turn, payload in list(report["comparison"]["comparison_by_turn"].items())[:12]:
        lines.append(f"- Turn {turn}: `{payload}`")
    lines.append("")
    return "\n".join(lines)


def run(
    *,
    prior_path: Path,
    events_path: Path,
    candidate_cards: list[str],
    game_count: int | None,
    player_slots: int | None,
) -> dict[str, Any]:
    prior = load_json(prior_path)
    events = iter_jsonl(events_path)
    inferred_game_count = infer_game_count(events, game_count)
    inferred_player_slots = infer_player_slots(events, player_slots)
    observed = summarize_events(
        events,
        candidate_cards=candidate_cards,
        game_count=inferred_game_count,
        player_slots=inferred_player_slots,
    )
    comparison = compare_to_prior(prior, observed)
    return {
        "comparison": comparison,
        "events_path": str(events_path),
        "observed_summary": observed,
        "postgres_writes": False,
        "prior_path": str(prior_path),
        "source_db_mutated": False,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prior-json", type=Path, default=DEFAULT_PRIOR_JSON)
    parser.add_argument("--events-jsonl", type=Path, required=True)
    parser.add_argument("--candidate-card", action="append", default=[])
    parser.add_argument("--game-count", type=int)
    parser.add_argument("--player-slots", type=int)
    parser.add_argument("--output-json", type=Path)
    parser.add_argument("--output-md", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    report = run(
        prior_path=args.prior_json,
        events_path=args.events_jsonl,
        candidate_cards=args.candidate_card,
        game_count=args.game_count,
        player_slots=args.player_slots,
    )
    if args.output_json:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(stable_json(report) + "\n", encoding="utf-8")
    if args.output_md:
        args.output_md.parent.mkdir(parents=True, exist_ok=True)
        args.output_md.write_text(render_markdown(report), encoding="utf-8")
    if not args.output_json and not args.output_md:
        print(stable_json(report))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
