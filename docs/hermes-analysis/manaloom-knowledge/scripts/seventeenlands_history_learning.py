#!/usr/bin/env python3
"""Learn sequential behavior priors from 17Lands replay_data histories.

This is a read-only learner for ManaLoom battle/deckbuilder methodology. It
learns event cadence and card lifecycle patterns from histories; it does not
promote Commander strategy or exact card rules.
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

import seventeenlands_replay_profile as profile


DEFAULT_SOURCE = profile.DEFAULT_REPLAY_URL
ACTION_TOKENS = {
    "lands_played": "land",
    "creatures_cast": "creature_cast",
    "non_creatures_cast": "noncreature_cast",
    "user_instants_sorceries_cast": "instant_sorcery_cast",
    "oppo_instants_sorceries_cast": "instant_sorcery_cast",
    "user_abilities": "ability",
    "oppo_abilities": "ability",
    "creatures_attacked": "attack",
    "creatures_blocked": "block",
    "creatures_unblocked": "unblocked_attack",
    "creatures_blocking": "block",
    "oppo_combat_damage_taken": "combat_damage",
    "user_combat_damage_taken": "combat_damage",
    "user_mana_spent": "mana_spent",
    "oppo_mana_spent": "mana_spent",
}
CARD_ENTRY_KEYS = [
    "ability_entries",
    "attack_or_block_entries",
    "battlefield_eot_entries",
    "creature_cast_entries",
    "direct_use_entries",
    "discard_entries",
    "drawn_entries",
    "drawn_or_tutored_entries",
    "instant_sorcery_cast_entries",
    "land_played_entries",
    "natural_access_entries",
    "noncreature_cast_entries",
    "opening_or_candidate_hand_entries",
    "total_observation_entries",
    "tutored_entries",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, indent=2, sort_keys=True)


def parse_bool(value: Any) -> bool | None:
    text = str(value or "").strip().lower()
    if text in {"true", "1", "yes", "win", "won"}:
        return True
    if text in {"false", "0", "no", "loss", "lost"}:
        return False
    return None


def empty_turn_counter() -> Counter[str]:
    return Counter(
        {
            "ability_entries": 0,
            "combat_damage_sum": 0,
            "creature_cast_entries": 0,
            "games_reached": 0,
            "land_play_entries": 0,
            "mana_spent_positive_observations": 0,
            "mana_spent_sum_positive": 0,
            "noncreature_cast_entries": 0,
            "spell_action_entries": 0,
        }
    )


def empty_game_card_state() -> dict[str, Any]:
    return {
        "access_turn": None,
        "entries": Counter(),
        "use_turn": None,
    }


def min_turn(current: int | None, turn: int | None) -> int | None:
    if turn is None:
        return current
    if current is None:
        return turn
    return min(current, turn)


def update_game_card_state(
    card_state: dict[str, Any],
    *,
    suffix: str | None = None,
    base_column: str | None = None,
    turn: int | None = None,
) -> None:
    entries: Counter[str] = card_state["entries"]
    entries["total_observation_entries"] += 1
    if base_column in profile.BASE_ID_LIST_COLUMNS:
        entries["opening_or_candidate_hand_entries"] += 1
        entries["natural_access_entries"] += 1
        card_state["access_turn"] = min_turn(card_state["access_turn"], turn or 0)
    if suffix in profile.ACCESS_SUFFIXES:
        entries["natural_access_entries"] += 1
        card_state["access_turn"] = min_turn(card_state["access_turn"], turn)
    if suffix in profile.DIRECT_USE_SUFFIXES:
        entries["direct_use_entries"] += 1
        card_state["use_turn"] = min_turn(card_state["use_turn"], turn)

    if suffix == "cards_drawn":
        entries["drawn_entries"] += 1
    elif suffix == "cards_tutored":
        entries["tutored_entries"] += 1
    elif suffix == "cards_drawn_or_tutored":
        entries["drawn_or_tutored_entries"] += 1
    elif suffix == "cards_discarded":
        entries["discard_entries"] += 1
    elif suffix == "lands_played":
        entries["land_played_entries"] += 1
    elif suffix == "creatures_cast":
        entries["creature_cast_entries"] += 1
    elif suffix == "non_creatures_cast":
        entries["noncreature_cast_entries"] += 1
    elif suffix in {"user_instants_sorceries_cast", "oppo_instants_sorceries_cast"}:
        entries["instant_sorcery_cast_entries"] += 1
    elif suffix in {"user_abilities", "oppo_abilities"}:
        entries["ability_entries"] += 1
    elif suffix in {
        "creatures_attacked",
        "creatures_blocked",
        "creatures_unblocked",
        "creatures_blocking",
    }:
        entries["attack_or_block_entries"] += 1
    elif suffix in profile.EOT_LIST_SUFFIXES:
        entries["battlefield_eot_entries"] += 1


def update_turn_metrics(
    bucket: Counter[str],
    *,
    active_side: str,
    suffix: str,
    raw: Any,
) -> None:
    ids = profile.split_id_list(raw) if suffix in profile.ID_LIST_SUFFIXES else []
    if suffix == "lands_played":
        bucket["land_play_entries"] += len(ids)
    elif suffix == "creatures_cast":
        bucket["creature_cast_entries"] += len(ids)
        bucket["spell_action_entries"] += len(ids)
    elif suffix in {
        "non_creatures_cast",
        "user_instants_sorceries_cast",
        "oppo_instants_sorceries_cast",
    }:
        bucket["noncreature_cast_entries"] += len(ids)
        bucket["spell_action_entries"] += len(ids)
    elif suffix in {"user_abilities", "oppo_abilities"}:
        bucket["ability_entries"] += len(ids)
    elif suffix in {"oppo_combat_damage_taken", "user_combat_damage_taken"}:
        bucket["combat_damage_sum"] += profile.parse_float(raw) or 0.0
    elif suffix == f"{active_side}_mana_spent":
        value = profile.parse_float(raw)
        if value is not None and value > 0:
            bucket["mana_spent_sum_positive"] += value
            bucket["mana_spent_positive_observations"] += 1


def sequence_token_for_suffix(suffix: str, raw: Any) -> str | None:
    token = ACTION_TOKENS.get(suffix)
    if token is None:
        return None
    if suffix in profile.ID_LIST_SUFFIXES and not profile.split_id_list(raw):
        return None
    if suffix in profile.SCALAR_SUFFIXES and not profile.is_meaningful_turn_value(suffix, raw):
        return None
    return token


def finalize_turns(
    turn_metrics: Mapping[str, Counter[str]],
    *,
    rows_processed: int,
) -> dict[str, dict[str, Any]]:
    finalized: dict[str, dict[str, Any]] = {}
    for turn, bucket in sorted(turn_metrics.items(), key=lambda item: int(item[0])):
        games_reached = max(1, int(bucket["games_reached"]))
        mana_observations = int(bucket["mana_spent_positive_observations"])
        finalized[turn] = {
            "ability_entries": int(bucket["ability_entries"]),
            "ability_per_reached_game": round(bucket["ability_entries"] / games_reached, 4),
            "combat_damage_avg_per_reached_game": round(bucket["combat_damage_sum"] / games_reached, 4),
            "combat_damage_sum": round(float(bucket["combat_damage_sum"]), 3),
            "creature_cast_entries": int(bucket["creature_cast_entries"]),
            "games_reached": int(bucket["games_reached"]),
            "land_play_entries": int(bucket["land_play_entries"]),
            "land_play_per_reached_game": round(bucket["land_play_entries"] / games_reached, 4),
            "mana_spent_avg_positive": round(bucket["mana_spent_sum_positive"] / mana_observations, 4)
            if mana_observations
            else None,
            "noncreature_cast_entries": int(bucket["noncreature_cast_entries"]),
            "reached_game_rate": round(bucket["games_reached"] / max(1, rows_processed), 4),
            "spell_action_entries": int(bucket["spell_action_entries"]),
            "spell_action_per_reached_game": round(bucket["spell_action_entries"] / games_reached, 4),
        }
    return finalized


def finalize_sequence_counter(counter: Counter[str], limit: int) -> list[dict[str, Any]]:
    return [
        {"pattern": pattern, "games": int(count)}
        for pattern, count in counter.most_common(limit)
    ]


def card_payload(arena_id: str, row: Counter[str]) -> dict[str, Any]:
    access_games = int(row["access_games"])
    used_games = int(row["used_games"])
    lag_samples = int(row["access_to_use_lag_samples"])
    payload: dict[str, Any] = {
        "arena_id": arena_id,
        "access_games": access_games,
        "access_to_use_lag_avg_turns": round(row["access_to_use_lag_sum"] / lag_samples, 4)
        if lag_samples
        else None,
        "access_to_use_lag_samples": lag_samples,
        "avg_first_access_turn": round(row["first_access_turn_sum"] / access_games, 4)
        if access_games
        else None,
        "avg_first_use_turn": round(row["first_use_turn_sum"] / used_games, 4)
        if used_games
        else None,
        "games_seen": int(row["games_seen"]),
        "use_after_access_rate": round(lag_samples / access_games, 4)
        if access_games
        else None,
        "used_games": used_games,
        "win_rate_when_accessed": round(row["wins_accessed"] / access_games, 4)
        if access_games
        else None,
        "win_rate_when_used": round(row["wins_used"] / used_games, 4)
        if used_games
        else None,
    }
    for key in CARD_ENTRY_KEYS:
        payload[key] = int(row[key])
    return payload


def finalize_cards(card_counters: Mapping[str, Counter[str]], limit: int) -> dict[str, Any]:
    rows = [
        card_payload(arena_id, counter)
        for arena_id, counter in card_counters.items()
        if profile.is_card_like_arena_id(arena_id)
    ]
    return {
        "top_by_access_games": sorted(
            rows,
            key=lambda item: (
                item["access_games"],
                item["used_games"],
                item["total_observation_entries"],
            ),
            reverse=True,
        )[:limit],
        "top_by_use_after_access_rate": sorted(
            [row for row in rows if row["access_games"] >= 3 and row["use_after_access_rate"] is not None],
            key=lambda item: (item["use_after_access_rate"], item["access_games"]),
            reverse=True,
        )[:limit],
        "top_by_used_games": sorted(
            rows,
            key=lambda item: (
                item["used_games"],
                item["access_games"],
                item["total_observation_entries"],
            ),
            reverse=True,
        )[:limit],
    }


def update_card_counters(
    card_counters: dict[str, Counter[str]],
    *,
    arena_id: str,
    card_state: Mapping[str, Any],
    won: bool | None,
) -> None:
    counter = card_counters[arena_id]
    entries: Counter[str] = card_state["entries"]
    counter["games_seen"] += 1
    for key in CARD_ENTRY_KEYS:
        counter[key] += int(entries[key])
    access_turn = card_state.get("access_turn")
    use_turn = card_state.get("use_turn")
    if access_turn is not None:
        counter["access_games"] += 1
        counter["first_access_turn_sum"] += int(access_turn)
        if won is True:
            counter["wins_accessed"] += 1
    if use_turn is not None:
        counter["used_games"] += 1
        counter["first_use_turn_sum"] += int(use_turn)
        if won is True:
            counter["wins_used"] += 1
    if access_turn is not None and use_turn is not None:
        counter["access_to_use_lag_samples"] += 1
        counter["access_to_use_lag_sum"] += max(0, int(use_turn) - int(access_turn))


def sorted_turn_fieldnames(fieldnames: Iterable[str]) -> list[str]:
    def sort_key(name: str) -> tuple[int, int, str]:
        parts = profile.turn_column_parts(name)
        if parts is None:
            return (9999, 9, name)
        side, turn, suffix = parts
        return (turn, 0 if side == "user" else 1, suffix)

    return sorted((name for name in fieldnames if profile.turn_column_parts(name)), key=sort_key)


def learn_rows(
    *,
    source: str,
    source_label: str,
    max_rows: int,
    top_card_limit: int,
    top_sequence_limit: int,
    turn_prefix_limit: int,
) -> dict[str, Any]:
    rows_processed = 0
    outcomes: Counter[str] = Counter()
    turn_count_distribution: Counter[str] = Counter()
    turn_metrics: dict[str, Counter[str]] = defaultdict(empty_turn_counter)
    turn_pattern_counts: Counter[str] = Counter()
    game_sequence_counts: Counter[str] = Counter()
    card_counters: dict[str, Counter[str]] = defaultdict(Counter)

    with profile.open_text_source(source) as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            raise ValueError("CSV source has no header")
        fieldnames = list(reader.fieldnames)
        turn_fieldnames = sorted_turn_fieldnames(fieldnames)
        header = profile.classify_header(fieldnames)

        for row_index, row in enumerate(reader):
            if max_rows > 0 and row_index >= max_rows:
                break
            row = {key: value for key, value in row.items() if key is not None}
            rows_processed += 1
            won = parse_bool(row.get("won"))
            outcomes[str(row.get("won", "") or "(empty)")] += 1
            num_turns = profile.row_num_turns(row) or 0
            turn_count_distribution[str(num_turns or "(empty)")] += 1
            for turn in range(1, num_turns + 1):
                turn_metrics[str(turn)]["games_reached"] += 1

            game_cards: dict[str, dict[str, Any]] = defaultdict(empty_game_card_state)
            turn_tokens: dict[int, set[str]] = defaultdict(set)
            for base_column in profile.BASE_ID_LIST_COLUMNS:
                for arena_id in profile.split_id_list(row.get(base_column)):
                    update_game_card_state(
                        game_cards[arena_id],
                        base_column=base_column,
                        turn=0,
                    )

            for name in turn_fieldnames:
                raw = row.get(name)
                if raw is None or str(raw).strip() == "":
                    continue
                parts = profile.turn_column_parts(name)
                if parts is None:
                    continue
                active_side, turn, suffix = parts
                if not profile.turn_reached(row, turn) or not profile.is_meaningful_turn_value(suffix, raw):
                    continue
                turn_bucket = turn_metrics[str(turn)]
                update_turn_metrics(
                    turn_bucket,
                    active_side=active_side,
                    suffix=suffix,
                    raw=raw,
                )
                token = sequence_token_for_suffix(suffix, raw)
                if token is not None:
                    turn_tokens[turn].add(token)
                if suffix in profile.ID_LIST_SUFFIXES or suffix in profile.EOT_LIST_SUFFIXES:
                    for arena_id in profile.split_id_list(raw):
                        update_game_card_state(
                            game_cards[arena_id],
                            suffix=suffix,
                            turn=turn,
                        )

            for arena_id, card_state in game_cards.items():
                update_card_counters(
                    card_counters,
                    arena_id=arena_id,
                    card_state=card_state,
                    won=won,
                )
            sequence_parts = []
            for turn in range(1, min(num_turns, turn_prefix_limit) + 1):
                tokens = turn_tokens.get(turn) or set()
                if not tokens:
                    continue
                label = f"T{turn}:{'+'.join(sorted(tokens))}"
                sequence_parts.append(label)
                turn_pattern_counts[label] += 1
            if sequence_parts:
                game_sequence_counts[" | ".join(sequence_parts)] += 1

    card_lifecycle = finalize_cards(card_counters, top_card_limit)
    report = {
        "card_lifecycle": card_lifecycle,
        "generated_at": utc_now(),
        "header": header,
        "history_learning_contract": {
            "battle_runtime": [
                "Use turn_behavior_by_history to calibrate land/spell/mana/combat cadence.",
                "Use common_turn_patterns to detect implausible battle action sequences.",
            ],
            "deckbuilder": [
                "Use card_lifecycle access/use/lag metrics to require observed exposure before scoring swaps.",
                "Do not treat high win rate on a Limited Arena ID as Commander recommendation.",
            ],
            "limits": [
                "17Lands replay_data does not expose exact stack choices, targets, or complete card rules.",
                "Arena IDs need annotation before card-name interpretation.",
                "PremierDraft histories are behavior priors, not Commander strategy truth.",
            ],
        },
        "max_rows_requested": max_rows,
        "not_postgresql_write": True,
        "outcomes": dict(sorted(outcomes.items())),
        "postgres_writes": False,
        "rows_processed": rows_processed,
        "source": source,
        "source_db_mutated": False,
        "source_label": source_label,
        "turn_behavior_by_history": finalize_turns(
            turn_metrics,
            rows_processed=rows_processed,
        ),
        "turn_count_distribution_top": dict(turn_count_distribution.most_common(20)),
        "sequence_learning": {
            "common_game_prefixes": finalize_sequence_counter(
                game_sequence_counts,
                top_sequence_limit,
            ),
            "common_turn_patterns": finalize_sequence_counter(
                turn_pattern_counts,
                top_sequence_limit,
            ),
            "turn_prefix_limit": turn_prefix_limit,
        },
    }
    return report


def render_markdown(report: Mapping[str, Any]) -> str:
    lines = [
        "# 17Lands History Learning",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Source: `{report['source_label']}`",
        f"- Rows processed: `{report['rows_processed']}`",
        f"- Max rows requested: `{report['max_rows_requested']}`",
        f"- PostgreSQL writes: `{report['postgres_writes']}`",
        f"- Source DB mutated: `{report['source_db_mutated']}`",
        "",
        "## What Was Learned",
        "",
        "- Turn-by-turn cadence for land drops, spell actions, mana spend, abilities, and combat.",
        "- Common game action prefixes from real replay history.",
        "- Card lifecycle aggregates: access, use, access-to-use lag, and outcome-conditioned use rates.",
        "",
        "## History Shape",
        "",
        f"- Header: `{report['header']}`",
        f"- Outcomes: `{report['outcomes']}`",
        f"- Turn count distribution top: `{report['turn_count_distribution_top']}`",
        "",
        "## Turn Behavior",
        "",
    ]
    for turn, payload in list(report["turn_behavior_by_history"].items())[:12]:
        lines.append(f"- Turn {turn}: `{payload}`")
    lines.extend(["", "## Common Turn Patterns", ""])
    for payload in report["sequence_learning"]["common_turn_patterns"][:20]:
        lines.append(f"- `{payload}`")
    lines.extend(["", "## Common Game Prefixes", ""])
    for payload in report["sequence_learning"]["common_game_prefixes"][:12]:
        lines.append(f"- `{payload}`")
    lines.extend(["", "## Card Lifecycle Top By Use", ""])
    for payload in report["card_lifecycle"]["top_by_used_games"][:20]:
        lines.append(f"- `{payload}`")
    lines.extend(["", "## Integration Contract", ""])
    for area, items in report["history_learning_contract"].items():
        lines.append(f"- {area}: `{items}`")
    lines.append("")
    return "\n".join(lines)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", default=DEFAULT_SOURCE)
    parser.add_argument("--source-label", default="17Lands LCI PremierDraft replay_data")
    parser.add_argument(
        "--max-rows",
        type=int,
        default=0,
        help="0 means stream the whole source.",
    )
    parser.add_argument("--top-card-limit", type=int, default=40)
    parser.add_argument("--top-sequence-limit", type=int, default=40)
    parser.add_argument("--turn-prefix-limit", type=int, default=6)
    parser.add_argument("--output-json", type=Path)
    parser.add_argument("--output-md", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.max_rows < 0:
        raise SystemExit("--max-rows must be >= 0")
    report = learn_rows(
        source=args.source,
        source_label=args.source_label,
        max_rows=args.max_rows,
        top_card_limit=args.top_card_limit,
        top_sequence_limit=args.top_sequence_limit,
        turn_prefix_limit=args.turn_prefix_limit,
    )
    if args.output_json:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(stable_json(report) + "\n", encoding="utf-8")
    if args.output_md:
        args.output_md.parent.mkdir(parents=True, exist_ok=True)
        args.output_md.write_text(render_markdown(report), encoding="utf-8")
    if not args.output_json and not args.output_md:
        sys.stdout.write(stable_json(report) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
