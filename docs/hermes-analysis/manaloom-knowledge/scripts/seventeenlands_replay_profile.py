#!/usr/bin/env python3
"""Profile public 17Lands replay_data files for ManaLoom battle/deckbuilder.

The output is intentionally read-only evidence. 17Lands replay_data is useful
for behavior priors such as turn cadence, mana spend, combat pressure, and
cast sequencing. It is not a rules oracle and should not promote card rules by
itself.
"""

from __future__ import annotations

import argparse
import csv
import gzip
import io
import json
import re
import subprocess
import sys
from collections import Counter, defaultdict
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterator, TextIO
from urllib.parse import urlparse


DEFAULT_REPLAY_URL = (
    "https://17lands-public.s3.amazonaws.com/analysis_data/replay_data/"
    "replay_data_public.LCI.PremierDraft.csv.gz"
)
TURN_COLUMN_RE = re.compile(r"^(user|oppo)_turn_(\d+)_(.+)$")
ID_LIST_SUFFIXES = {
    "cards_drawn",
    "cards_tutored",
    "cards_drawn_or_tutored",
    "cards_discarded",
    "lands_played",
    "creatures_cast",
    "non_creatures_cast",
    "user_instants_sorceries_cast",
    "oppo_instants_sorceries_cast",
    "user_abilities",
    "oppo_abilities",
    "creatures_attacked",
    "creatures_blocked",
    "creatures_unblocked",
    "creatures_blocking",
    "user_creatures_killed_combat",
    "oppo_creatures_killed_combat",
    "user_creatures_killed_non_combat",
    "oppo_creatures_killed_non_combat",
}
EOT_LIST_SUFFIXES = {
    "eot_user_lands_in_play",
    "eot_oppo_lands_in_play",
    "eot_user_creatures_in_play",
    "eot_oppo_creatures_in_play",
    "eot_user_non_creatures_in_play",
    "eot_oppo_non_creatures_in_play",
}
EOT_SCALAR_SUFFIXES = {
    "eot_user_cards_in_hand",
    "eot_oppo_cards_in_hand",
    "eot_user_life",
    "eot_oppo_life",
}
SCALAR_SUFFIXES = {
    "oppo_combat_damage_taken",
    "user_combat_damage_taken",
    "user_mana_spent",
    "oppo_mana_spent",
    *EOT_SCALAR_SUFFIXES,
}
BASE_ID_LIST_COLUMNS = {
    "candidate_hand_1",
    "candidate_hand_2",
    "candidate_hand_3",
    "candidate_hand_4",
    "candidate_hand_5",
    "candidate_hand_6",
    "candidate_hand_7",
    "opening_hand",
}
IMPORTANT_SUFFIXES = [
    "cards_drawn",
    "cards_tutored",
    "cards_drawn_or_tutored",
    "cards_discarded",
    "lands_played",
    "creatures_cast",
    "non_creatures_cast",
    "user_instants_sorceries_cast",
    "oppo_instants_sorceries_cast",
    "user_abilities",
    "oppo_abilities",
    "creatures_attacked",
    "creatures_blocked",
    "creatures_unblocked",
    "creatures_blocking",
    "oppo_combat_damage_taken",
    "user_combat_damage_taken",
    "user_mana_spent",
    "oppo_mana_spent",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, indent=2, sort_keys=True)


def is_url(source: str) -> bool:
    return urlparse(source).scheme in {"http", "https"}


@contextmanager
def open_text_source(source: str) -> Iterator[TextIO]:
    process: subprocess.Popen[bytes] | None = None
    text: TextIO | None = None
    try:
        if is_url(source):
            process = subprocess.Popen(
                ["curl", "-L", "--fail", "--silent", "--show-error", source],
                stdout=subprocess.PIPE,
            )
            if process.stdout is None:
                raise RuntimeError("curl did not expose stdout")
            raw: io.BufferedIOBase = process.stdout
            if source.endswith(".gz"):
                text = io.TextIOWrapper(
                    gzip.GzipFile(fileobj=raw), encoding="utf-8", newline=""
                )
            else:
                text = io.TextIOWrapper(raw, encoding="utf-8", newline="")
        else:
            path = Path(source)
            if path.suffix == ".gz":
                text = gzip.open(path, "rt", encoding="utf-8", newline="")
            else:
                text = path.open("r", encoding="utf-8", newline="")
        yield text
    finally:
        if text is not None:
            try:
                text.close()
            except OSError:
                pass
        if process is not None:
            if process.poll() is None:
                process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()


def read_sample_rows(source: str, sample_rows: int) -> tuple[list[str], list[dict[str, str]]]:
    with open_text_source(source) as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            raise ValueError("CSV source has no header")
        fieldnames = list(reader.fieldnames)
        rows: list[dict[str, str]] = []
        for index, row in enumerate(reader):
            if index >= sample_rows:
                break
            rows.append({key: value for key, value in row.items() if key is not None})
    return fieldnames, rows


def turn_column_parts(name: str) -> tuple[str, int, str] | None:
    match = TURN_COLUMN_RE.match(name)
    if not match:
        return None
    return match.group(1), int(match.group(2)), match.group(3)


def classify_header(fieldnames: list[str]) -> dict[str, Any]:
    side_counts: Counter[str] = Counter()
    suffix_counts: Counter[str] = Counter()
    turn_counts: Counter[int] = Counter()
    turn_columns: list[str] = []
    max_turn = 0
    for name in fieldnames:
        parts = turn_column_parts(name)
        if parts is None:
            continue
        side, turn, suffix = parts
        turn_columns.append(name)
        side_counts[side] += 1
        suffix_counts[suffix] += 1
        turn_counts[turn] += 1
        max_turn = max(max_turn, turn)
    return {
        "field_count": len(fieldnames),
        "base_column_count": len(fieldnames) - len(turn_columns),
        "turn_column_count": len(turn_columns),
        "max_turn_column": max_turn,
        "turn_side_counts": dict(sorted(side_counts.items())),
        "turn_suffix_count": len(suffix_counts),
        "turn_suffixes": sorted(suffix_counts),
        "turn_columns_per_turn": {
            str(key): int(value) for key, value in sorted(turn_counts.items())
        },
    }


def split_id_list(raw: Any) -> list[str]:
    text = str(raw or "").strip()
    if not text or text in {"0", "0.0", "None", "nan"}:
        return []
    text = text.strip("[]")
    parts = re.split(r"[|,;\s]+", text)
    return [part for part in parts if part and part not in {"0", "0.0"}]


def row_num_turns(row: dict[str, str]) -> int | None:
    value = parse_float(row.get("num_turns"))
    if value is None:
        return None
    return int(value)


def turn_reached(row: dict[str, str], turn: int) -> bool:
    num_turns = row_num_turns(row)
    return num_turns is None or turn <= num_turns


def parse_float(raw: Any) -> float | None:
    text = str(raw or "").strip()
    if not text:
        return None
    try:
        return float(text)
    except ValueError:
        return None


def owner_from_suffix(active_side: str, suffix: str) -> str:
    if suffix.startswith("eot_user_"):
        return "user"
    if suffix.startswith("eot_oppo_"):
        return "oppo"
    if suffix.startswith("user_"):
        return "user"
    if suffix.startswith("oppo_"):
        return "oppo"
    return active_side


def event_type_for_suffix(suffix: str) -> str:
    if suffix == "cards_drawn":
        return "draw_card"
    if suffix == "cards_tutored":
        return "tutor_card"
    if suffix == "cards_drawn_or_tutored":
        return "draw_or_tutor_card"
    if suffix == "cards_discarded":
        return "discard_card"
    if suffix == "lands_played":
        return "play_land"
    if suffix == "creatures_cast":
        return "cast_creature"
    if suffix == "non_creatures_cast":
        return "cast_noncreature"
    if suffix.endswith("_instants_sorceries_cast"):
        return "cast_instant_or_sorcery"
    if suffix.endswith("_abilities"):
        return "activate_ability"
    if suffix == "creatures_attacked":
        return "attack"
    if suffix == "creatures_blocked":
        return "blocked_attacker"
    if suffix == "creatures_unblocked":
        return "unblocked_attacker"
    if suffix == "creatures_blocking":
        return "block"
    if suffix.endswith("_creatures_killed_combat"):
        return "creature_killed_combat"
    if suffix.endswith("_creatures_killed_non_combat"):
        return "creature_killed_noncombat"
    if suffix.endswith("_combat_damage_taken"):
        return "combat_damage"
    if suffix.endswith("_mana_spent"):
        return "mana_spent"
    if suffix in EOT_LIST_SUFFIXES:
        return "end_turn_battlefield_card"
    if suffix.startswith("eot_"):
        return "end_turn_state"
    return suffix


def is_meaningful_turn_value(suffix: str, raw: Any) -> bool:
    if suffix in ID_LIST_SUFFIXES or suffix in EOT_LIST_SUFFIXES:
        return bool(split_id_list(raw))
    value = parse_float(raw)
    if value is None:
        return False
    if suffix in EOT_SCALAR_SUFFIXES:
        return True
    return value != 0.0


def normalize_turn_events(
    row: dict[str, str],
    fieldnames: list[str],
    *,
    max_events: int = 120,
) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    for name in fieldnames:
        raw = row.get(name)
        if raw is None or str(raw).strip() == "":
            continue
        parts = turn_column_parts(name)
        if parts is None:
            continue
        active_side, turn, suffix = parts
        if not turn_reached(row, turn) or not is_meaningful_turn_value(suffix, raw):
            continue
        if suffix in ID_LIST_SUFFIXES:
            for arena_id in split_id_list(raw):
                events.append(
                    {
                        "active_side": active_side,
                        "arena_id": arena_id,
                        "event_type": event_type_for_suffix(suffix),
                        "owner_side": owner_from_suffix(active_side, suffix),
                        "raw_column": name,
                        "turn": turn,
                    }
                )
        elif suffix in EOT_LIST_SUFFIXES:
            for arena_id in split_id_list(raw):
                events.append(
                    {
                        "active_side": active_side,
                        "arena_id": arena_id,
                        "event_type": event_type_for_suffix(suffix),
                        "owner_side": owner_from_suffix(active_side, suffix),
                        "raw_column": name,
                        "turn": turn,
                    }
                )
        elif suffix in SCALAR_SUFFIXES:
            value = parse_float(raw)
            if value is None:
                continue
            events.append(
                {
                    "active_side": active_side,
                    "event_type": event_type_for_suffix(suffix),
                    "owner_side": owner_from_suffix(active_side, suffix),
                    "raw_column": name,
                    "turn": turn,
                    "value": value,
                }
            )
        if len(events) >= max_events:
            return events[:max_events]
    return events


def identity_for_row(row: dict[str, str]) -> dict[str, Any]:
    keys = [
        "expansion",
        "event_type",
        "draft_id",
        "draft_time",
        "match_number",
        "game_number",
        "game_time",
        "rank",
        "opp_rank",
        "main_colors",
        "splash_colors",
        "opp_colors",
        "on_play",
        "num_mulligans",
        "opp_num_mulligans",
        "num_turns",
        "won",
    ]
    return {key: row.get(key, "") for key in keys if key in row}


def update_turn_metric(
    turn_metrics: dict[str, dict[str, Any]],
    active_side: str,
    turn: int,
    suffix: str,
    raw: str,
) -> None:
    bucket = turn_metrics.setdefault(
        str(turn),
        {
            "creature_cast_entries": 0,
            "land_play_entries": 0,
            "noncreature_cast_entries": 0,
            "spell_action_entries": 0,
            "total_combat_damage": 0.0,
            "active_mana_spent_positive_observations": 0,
            "active_mana_spent_sum_positive": 0.0,
        },
    )
    ids = split_id_list(raw) if suffix in ID_LIST_SUFFIXES else []
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
    elif suffix in {"oppo_combat_damage_taken", "user_combat_damage_taken"}:
        bucket["total_combat_damage"] += parse_float(raw) or 0.0
    elif suffix == f"{active_side}_mana_spent":
        value = parse_float(raw)
        if value is not None and value > 0:
            bucket["active_mana_spent_sum_positive"] += value
            bucket["active_mana_spent_positive_observations"] += 1


def finalize_turn_metrics(turn_metrics: dict[str, dict[str, Any]]) -> dict[str, dict[str, Any]]:
    finalized: dict[str, dict[str, Any]] = {}
    for turn, bucket in sorted(turn_metrics.items(), key=lambda item: int(item[0])):
        observations = int(bucket["active_mana_spent_positive_observations"])
        avg_mana = None
        if observations:
            avg_mana = round(
                float(bucket["active_mana_spent_sum_positive"]) / observations, 3
            )
        finalized[turn] = {
            "active_mana_spent_avg_positive": avg_mana,
            "active_mana_spent_positive_observations": observations,
            "creature_cast_entries": int(bucket["creature_cast_entries"]),
            "land_play_entries": int(bucket["land_play_entries"]),
            "noncreature_cast_entries": int(bucket["noncreature_cast_entries"]),
            "spell_action_entries": int(bucket["spell_action_entries"]),
            "total_combat_damage": round(float(bucket["total_combat_damage"]), 3),
        }
    return finalized


def profile_rows(
    *,
    source: str,
    source_label: str,
    fieldnames: list[str],
    rows: list[dict[str, str]],
) -> dict[str, Any]:
    header = classify_header(fieldnames)
    nonempty_suffix_counts: Counter[str] = Counter()
    arena_id_counts: Counter[str] = Counter()
    colors: Counter[str] = Counter()
    opp_colors: Counter[str] = Counter()
    outcomes: Counter[str] = Counter()
    turn_count_distribution: Counter[str] = Counter()
    turn_metrics: dict[str, dict[str, Any]] = {}

    for row in rows:
        colors[row.get("main_colors", "") or "(empty)"] += 1
        opp_colors[row.get("opp_colors", "") or "(empty)"] += 1
        outcomes[row.get("won", "") or "(empty)"] += 1
        turn_count_distribution[row.get("num_turns", "") or "(empty)"] += 1
        for base_column in BASE_ID_LIST_COLUMNS:
            for arena_id in split_id_list(row.get(base_column)):
                arena_id_counts[arena_id] += 1
        for name in fieldnames:
            raw = row.get(name)
            if raw is None or str(raw).strip() == "":
                continue
            parts = turn_column_parts(name)
            if parts is None:
                continue
            active_side, turn, suffix = parts
            if not turn_reached(row, turn) or not is_meaningful_turn_value(suffix, raw):
                continue
            nonempty_suffix_counts[suffix] += 1
            if suffix in ID_LIST_SUFFIXES:
                for arena_id in split_id_list(raw):
                    arena_id_counts[arena_id] += 1
            if suffix in IMPORTANT_SUFFIXES:
                update_turn_metric(turn_metrics, active_side, turn, suffix, raw)

    first_game = rows[0] if rows else {}
    report = {
        "generated_at": utc_now(),
        "source": source,
        "source_label": source_label,
        "postgres_writes": False,
        "source_db_mutated": False,
        "rows_sampled": len(rows),
        "header": header,
        "sample_game_identity": identity_for_row(first_game) if first_game else {},
        "sample_game_normalized_events": normalize_turn_events(first_game, fieldnames)
        if first_game
        else [],
        "sample_summary": {
            "main_colors_top": dict(colors.most_common(12)),
            "opponent_colors_top": dict(opp_colors.most_common(12)),
            "outcomes": dict(sorted(outcomes.items())),
            "num_turns_distribution_top": dict(turn_count_distribution.most_common(15)),
            "nonempty_suffix_counts_top": dict(nonempty_suffix_counts.most_common(30)),
            "top_arena_ids": dict(arena_id_counts.most_common(40)),
            "top_card_like_arena_ids": {
                key: value
                for key, value in arena_id_counts.most_common(80)
                if is_card_like_arena_id(key)
            },
            "turn_behavior_metrics": finalize_turn_metrics(turn_metrics),
        },
        "recommended_use": [
            "Calibrate battle/deckbuilder tempo priors: land drops, mana spend, cast timing, combat pressure.",
            "Compare ManaLoom simulated games against real MTGA limited cadence before tuning heuristics.",
            "Build exposure-aware tests that require a card/action to be observed before judging a candidate swap.",
            "Map arena_id to card names only as reference metadata; keep reviewed rules in PostgreSQL/Hermes flows.",
        ],
        "not_recommended_use": [
            "Do not promote card battle rules directly from replay_data.",
            "Do not treat PremierDraft behavior as Commander/Lorehold strategy proof.",
            "Do not infer exact stack, target selection, replacement effects, or hidden choices from these columns alone.",
        ],
        "next_integration_steps": [
            "Persist this profile as an artifact, not a database write.",
            "Use the normalized event schema as an adapter target for ManaLoom battle replay comparators.",
            "Add per-card observation gates to deckbuilder experiments so substitutions are scored only when drawn/cast/used.",
            "Use Scryfall arena_id resolution only as a cache-backed annotation layer.",
        ],
        "arena_id_notes": [
            "Small numeric IDs can be hidden/unknown Arena-side markers in replay_data, not Scryfall-resolvable cards.",
            "EOT *_in_play columns are treated as battlefield card ID lists, not scalar counts.",
        ],
    }
    return report


def load_json(path: Path) -> Any:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def resolve_arena_id_with_scryfall(arena_id: str) -> dict[str, Any]:
    url = f"https://api.scryfall.com/cards/arena/{arena_id}"
    process = subprocess.run(
        ["curl", "-L", "--fail", "--silent", "--show-error", url],
        capture_output=True,
        text=True,
        check=False,
        timeout=20,
    )
    if process.returncode != 0:
        return {
            "arena_id": arena_id,
            "resolved": False,
            "error": process.stderr.strip() or f"curl_exit_{process.returncode}",
        }
    payload = json.loads(process.stdout)
    return {
        "arena_id": arena_id,
        "name": payload.get("name"),
        "oracle_id": payload.get("oracle_id"),
        "resolved": True,
        "scryfall_id": payload.get("id"),
    }


def is_card_like_arena_id(arena_id: str) -> bool:
    try:
        return int(arena_id) >= 1000
    except ValueError:
        return False


def annotate_card_names(
    report: dict[str, Any],
    *,
    cache_path: Path | None,
    max_lookups: int,
) -> dict[str, Any]:
    cache: dict[str, Any] = {}
    if cache_path is not None:
        cache = load_json(cache_path)
    top_ids = list(report["sample_summary"]["top_arena_ids"].keys())
    annotations: dict[str, Any] = {}
    lookup_count = 0
    cache_changed = False
    for arena_id in top_ids:
        if not is_card_like_arena_id(arena_id):
            annotations[arena_id] = {
                "arena_id": arena_id,
                "resolved": False,
                "skipped": True,
                "reason": "likely_hidden_or_unknown_marker",
            }
            continue
        if arena_id in cache:
            annotations[arena_id] = cache[arena_id]
            continue
        if lookup_count >= max_lookups:
            annotations[arena_id] = {"arena_id": arena_id, "resolved": False, "skipped": True}
            continue
        resolved = resolve_arena_id_with_scryfall(arena_id)
        annotations[arena_id] = resolved
        cache[arena_id] = resolved
        lookup_count += 1
        cache_changed = True
    if cache_path is not None and cache_changed:
        cache_path.parent.mkdir(parents=True, exist_ok=True)
        cache_path.write_text(stable_json(cache) + "\n", encoding="utf-8")
    report["arena_id_annotations"] = annotations
    report["arena_id_annotation_source"] = {
        "cache_path": str(cache_path) if cache_path is not None else None,
        "lookups_attempted": lookup_count,
        "resolver": "Scryfall /cards/arena/{arena_id} via curl",
    }
    return report


def render_markdown(report: dict[str, Any]) -> str:
    header = report["header"]
    summary = report["sample_summary"]
    lines = [
        "# 17Lands replay_data Profile",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Source: `{report['source_label']}`",
        f"- Rows sampled: `{report['rows_sampled']}`",
        f"- PostgreSQL writes: `{report['postgres_writes']}`",
        f"- Source DB mutated: `{report['source_db_mutated']}`",
        "",
        "## Shape",
        "",
        f"- Fields: `{header['field_count']}`",
        f"- Base columns: `{header['base_column_count']}`",
        f"- Turn columns: `{header['turn_column_count']}`",
        f"- Max turn column: `{header['max_turn_column']}`",
        f"- Turn suffixes: `{header['turn_suffix_count']}`",
        f"- Turn side counts: `{header['turn_side_counts']}`",
        "",
        "## What This Can Improve",
        "",
    ]
    for item in report["recommended_use"]:
        lines.append(f"- {item}")
    lines.extend(["", "## What This Must Not Be Used For", ""])
    for item in report["not_recommended_use"]:
        lines.append(f"- {item}")
    lines.extend(["", "## Sample Game", ""])
    for key, value in report["sample_game_identity"].items():
        lines.append(f"- {key}: `{value}`")
    lines.extend(["", "## Top Signals", ""])
    lines.append(f"- Outcomes: `{summary['outcomes']}`")
    lines.append(f"- Main colors top: `{summary['main_colors_top']}`")
    lines.append(f"- Opponent colors top: `{summary['opponent_colors_top']}`")
    lines.append(
        f"- Nonempty turn suffixes top: `{summary['nonempty_suffix_counts_top']}`"
    )
    lines.append(f"- Card-like Arena IDs top: `{summary['top_card_like_arena_ids']}`")
    lines.extend(["", "## Arena ID Notes", ""])
    for item in report["arena_id_notes"]:
        lines.append(f"- {item}")
    lines.extend(["", "## Turn Behavior Metrics", ""])
    for turn, metrics in list(summary["turn_behavior_metrics"].items())[:12]:
        lines.append(f"- Turn {turn}: `{metrics}`")
    if "arena_id_annotations" in report:
        lines.extend(["", "## Arena ID Annotations", ""])
        for arena_id, payload in list(report["arena_id_annotations"].items())[:20]:
            lines.append(f"- `{arena_id}`: `{payload}`")
    lines.extend(["", "## Next Integration Steps", ""])
    for item in report["next_integration_steps"]:
        lines.append(f"- {item}")
    lines.append("")
    return "\n".join(lines)


def run(
    *,
    source: str,
    source_label: str,
    sample_rows: int,
    resolve_card_names: bool = False,
    cache_path: Path | None = None,
    max_card_name_lookups: int = 10,
) -> dict[str, Any]:
    fieldnames, rows = read_sample_rows(source, sample_rows)
    report = profile_rows(
        source=source,
        source_label=source_label,
        fieldnames=fieldnames,
        rows=rows,
    )
    if resolve_card_names:
        annotate_card_names(
            report,
            cache_path=cache_path,
            max_lookups=max_card_name_lookups,
        )
    return report


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", default=DEFAULT_REPLAY_URL)
    parser.add_argument("--source-label", default="17Lands LCI PremierDraft replay_data")
    parser.add_argument("--sample-rows", type=int, default=500)
    parser.add_argument("--output-json", type=Path)
    parser.add_argument("--output-md", type=Path)
    parser.add_argument("--resolve-card-names", action="store_true")
    parser.add_argument(
        "--arena-id-cache",
        type=Path,
        default=Path("docs/hermes-analysis/master_optimizer_reports/arena_id_cache.json"),
    )
    parser.add_argument("--max-card-name-lookups", type=int, default=10)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.sample_rows <= 0:
        raise SystemExit("--sample-rows must be positive")
    report = run(
        source=args.source,
        source_label=args.source_label,
        sample_rows=args.sample_rows,
        resolve_card_names=args.resolve_card_names,
        cache_path=args.arena_id_cache if args.resolve_card_names else None,
        max_card_name_lookups=args.max_card_name_lookups,
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
