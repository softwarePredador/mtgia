#!/usr/bin/env python3
"""Classify Lorehold loss modes from existing battle-gate JSON artifacts.

The classifier is intentionally read-only. It does not rerun battle, mutate
SQLite, or touch PostgreSQL. It turns per-game gate telemetry into a small loss
taxonomy so the next deck hypothesis starts from the observed failure mode
rather than from a plausible card idea.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_OUTPUT_STEM = "lorehold_loss_failure_classifier_20260627_conversion_pressure_v2"


CAUSE_LABELS = {
    "second_approach_window_failed_under_pressure": "Approach seen, second window failed under pressure",
    "second_approach_window_failed": "Approach seen, second window failed",
    "topdeck_without_miracle_conversion_under_pressure": "Discard/topdeck happened but no miracle conversion under pressure",
    "topdeck_without_miracle_conversion": "Discard/topdeck happened but no miracle conversion",
    "topdeck_miracle_without_approach_under_pressure": "Topdeck/miracle happened but no Approach conversion under pressure",
    "topdeck_miracle_without_approach": "Topdeck/miracle happened but no Approach conversion",
    "mana_spell_bottleneck_under_pressure": "Low spell volume before combat-pressure death",
    "mana_spell_bottleneck": "Low spell volume before loss",
    "missing_engine_under_combat_pressure": "No Library/topdeck/miracle engine before combat-pressure death",
    "missing_library_topdeck_engine": "No Library/topdeck/miracle engine seen before loss",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def default_gate_paths() -> list[Path]:
    patterns = [
        "lorehold_library_pressure_conversion_gate_20260627_seed*_v1_library_pressure_v1_*.json",
        "lorehold_life_floor_conversion_gate_20260627_seed*_v1_life_floor_v1_*.json",
        "lorehold_spellchain_conversion_gate_20260627_seed*_v1_spellchain_v1_*.json",
    ]
    paths: list[Path] = []
    for pattern in patterns:
        paths.extend(REPORT_DIR.glob(pattern))
    return sorted(path for path in paths if "_partial" not in path.name)


def package_key_for_result(deck_key: str) -> str:
    if deck_key == "deck_6":
        return "baseline_squee_champion"
    if deck_key.startswith("synergy_"):
        return deck_key.removeprefix("synergy_")
    return deck_key


def int_value(mapping: dict[str, Any], key: str) -> int:
    return int(mapping.get(key) or 0)


def game_signals(game: dict[str, Any]) -> dict[str, Any]:
    events = game.get("event_counts") or {}
    strategic = game.get("strategic_event_counts") or {}
    reason = str(game.get("reason") or "")
    turns = int(game.get("turns") or 0)
    combat_events = (
        int_value(events, "combat")
        + int_value(events, "combat_result")
        + int_value(events, "multi_defender_attack")
    )
    pressure_death = reason.startswith("life_zero") and (
        combat_events >= 8
        or int_value(events, "player_eliminated") > 0
        or int_value(events, "damage_resolved") > 0
    )
    lorehold_spell_cast = int_value(strategic, "lorehold_spell_cast")
    lorehold_cost_paid = int_value(strategic, "lorehold_cost_paid")
    low_spell_volume = turns <= 7 and (lorehold_spell_cast <= 4 or lorehold_cost_paid <= 6)
    return {
        "turns": turns,
        "reason": reason,
        "approach_cast_tracked": int_value(events, "approach_cast_tracked"),
        "approach_first_resolution": int_value(events, "approach_first_resolution"),
        "miracle_cast": int_value(strategic, "miracle_cast"),
        "topdeck_manipulation_activated": int_value(strategic, "topdeck_manipulation_activated"),
        "discard_to_top_replacement": int_value(strategic, "discard_to_top_replacement"),
        "lorehold_rummage_discard_to_top": int_value(strategic, "lorehold_rummage_discard_to_top"),
        "lorehold_spell_rummage_discard_to_top": int_value(
            strategic,
            "lorehold_spell_rummage_discard_to_top",
        ),
        "lorehold_upkeep_rummage": int_value(strategic, "lorehold_upkeep_rummage"),
        "lorehold_spell_rummage": int_value(strategic, "lorehold_spell_rummage"),
        "lorehold_spell_cast": lorehold_spell_cast,
        "lorehold_cost_paid": lorehold_cost_paid,
        "squee_to_graveyard": int_value(strategic, "squee_to_graveyard"),
        "squee_upkeep_return": int_value(strategic, "squee_upkeep_return"),
        "combat": int_value(events, "combat"),
        "combat_result": int_value(events, "combat_result"),
        "multi_defender_attack": int_value(events, "multi_defender_attack"),
        "player_eliminated": int_value(events, "player_eliminated"),
        "pressure_death": pressure_death,
        "low_spell_volume": low_spell_volume,
    }


def classify_loss(game: dict[str, Any]) -> dict[str, Any]:
    signals = game_signals(game)
    approach_seen = (
        signals["approach_cast_tracked"] > 0
        or signals["approach_first_resolution"] > 0
    )
    discard_to_top_seen = signals["discard_to_top_replacement"] > 0
    topdeck_seen = signals["topdeck_manipulation_activated"] > 0
    miracle_seen = signals["miracle_cast"] > 0
    engine_seen = discard_to_top_seen or topdeck_seen or miracle_seen
    under_pressure = bool(signals["pressure_death"])

    if approach_seen:
        primary = (
            "second_approach_window_failed_under_pressure"
            if under_pressure
            else "second_approach_window_failed"
        )
    elif (discard_to_top_seen or topdeck_seen) and not miracle_seen:
        primary = (
            "topdeck_without_miracle_conversion_under_pressure"
            if under_pressure
            else "topdeck_without_miracle_conversion"
        )
    elif engine_seen:
        primary = (
            "topdeck_miracle_without_approach_under_pressure"
            if under_pressure
            else "topdeck_miracle_without_approach"
        )
    elif signals["low_spell_volume"]:
        primary = (
            "mana_spell_bottleneck_under_pressure"
            if under_pressure
            else "mana_spell_bottleneck"
        )
    elif under_pressure:
        primary = "missing_engine_under_combat_pressure"
    else:
        primary = "missing_library_topdeck_engine"

    flags: list[str] = []
    if under_pressure:
        flags.append("combat_pressure_death")
    if approach_seen:
        flags.append("approach_seen")
    if discard_to_top_seen:
        flags.append("discard_to_top_seen")
    else:
        flags.append("discard_to_top_missing")
    if topdeck_seen:
        flags.append("topdeck_seen")
    else:
        flags.append("topdeck_missing")
    if miracle_seen:
        flags.append("miracle_seen")
    else:
        flags.append("miracle_missing")
    if signals["low_spell_volume"]:
        flags.append("low_spell_volume")
    if signals["squee_to_graveyard"] == 0 and signals["squee_upkeep_return"] == 0:
        flags.append("squee_loop_absent")

    return {
        "primary_cause": primary,
        "primary_cause_label": CAUSE_LABELS[primary],
        "flags": flags,
        "signals": signals,
    }


def sort_seed(value: Any) -> tuple[int, str]:
    text = str(value)
    return (int(text), text) if re.fullmatch(r"\d+", text) else (10**12, text)


def collect_loss_rows(paths: list[Path]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    seen_baseline_games: set[tuple[Any, str]] = set()
    for path in sorted(paths):
        payload = read_json(path)
        seed = payload.get("simulation_seed")
        for result in payload.get("results") or []:
            deck_key = str(result.get("deck_key") or "")
            package_key = package_key_for_result(deck_key)
            for game in result.get("game_results") or []:
                if game.get("result") != "loss":
                    continue
                game_id = str(game.get("game_id") or "")
                if deck_key == "deck_6":
                    dedupe_key = (seed, game_id)
                    if dedupe_key in seen_baseline_games:
                        continue
                    seen_baseline_games.add(dedupe_key)
                classified = classify_loss(game)
                rows.append(
                    {
                        "seed": seed,
                        "package_key": package_key,
                        "deck_key": deck_key,
                        "game_id": game_id,
                        "game_index": game.get("game_index"),
                        "opponent": game.get("opponent"),
                        "opponent_archetype": game.get("opponent_archetype"),
                        "picked_opponents": game.get("picked_opponents") or [],
                        "turns": int(game.get("turns") or 0),
                        "reason": str(game.get("reason") or ""),
                        "source": str(path),
                        **classified,
                    }
                )
    return rows


def aggregate_rows(rows: list[dict[str, Any]]) -> dict[str, Any]:
    by_scope: dict[tuple[Any, str, str], dict[str, Any]] = {}
    global_causes: Counter[str] = Counter()
    for row in rows:
        key = (row["seed"], row["package_key"], row["deck_key"])
        entry = by_scope.setdefault(
            key,
            {
                "seed": row["seed"],
                "package_key": row["package_key"],
                "deck_key": row["deck_key"],
                "losses": 0,
                "turn_sum": 0,
                "primary_cause_counts": Counter(),
                "flag_counts": Counter(),
                "opponent_counts": Counter(),
                "signal_totals": Counter(),
            },
        )
        entry["losses"] += 1
        entry["turn_sum"] += int(row["turns"] or 0)
        entry["primary_cause_counts"][row["primary_cause"]] += 1
        global_causes[row["primary_cause"]] += 1
        entry["opponent_counts"][str(row.get("opponent") or "")] += 1
        for flag in row.get("flags") or []:
            entry["flag_counts"][flag] += 1
        for signal, value in (row.get("signals") or {}).items():
            if isinstance(value, bool):
                entry["signal_totals"][signal] += int(value)
            elif isinstance(value, int):
                entry["signal_totals"][signal] += value

    summary_rows = []
    for entry in by_scope.values():
        losses = max(1, int(entry["losses"]))
        summary_rows.append(
            {
                "seed": entry["seed"],
                "package_key": entry["package_key"],
                "deck_key": entry["deck_key"],
                "losses": entry["losses"],
                "avg_loss_turn": round(entry["turn_sum"] / losses, 2),
                "primary_cause_counts": dict(entry["primary_cause_counts"]),
                "flag_counts": dict(entry["flag_counts"]),
                "opponent_counts": dict(entry["opponent_counts"]),
                "signal_totals": dict(entry["signal_totals"]),
            }
        )
    summary_rows.sort(key=lambda item: (sort_seed(item["seed"]), item["package_key"], item["deck_key"]))
    return {
        "total_loss_games": len(rows),
        "primary_cause_counts": dict(global_causes),
        "summary_rows": summary_rows,
    }


def build_report(paths: list[Path]) -> dict[str, Any]:
    rows = collect_loss_rows(paths)
    aggregate = aggregate_rows(rows)
    return {
        "generated_at": utc_now(),
        "scope": "losses from Library/pressure, life-floor, and spellchain conversion detailed gates",
        "postgres_writes": False,
        "source_db_mutated": False,
        "input_paths": [str(path) for path in paths],
        "classification_rules": [
            "Approach events outrank stale reason text when classifying second-window failures.",
            "Discard/topdeck without miracle is separated from missing-engine losses.",
            "Life-zero losses with combat/player-elimination events receive a combat-pressure flag.",
            "Low spell volume is only primary when no Library/topdeck/miracle engine appeared.",
        ],
        **aggregate,
        "loss_rows": sorted(
            rows,
            key=lambda item: (
                sort_seed(item["seed"]),
                item["package_key"],
                item["deck_key"],
                item["game_id"],
            ),
        ),
    }


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Loss Failure Classifier - 2026-06-27 v2",
        "",
        f"- Generated at: `{report['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        f"- Input gates: `{len(report['input_paths'])}`",
        "",
        "## Method",
        "",
    ]
    for rule in report["classification_rules"]:
        lines.append(f"- {rule}")
    lines.extend(
        [
            "",
            "## Aggregate",
            "",
            f"- Classified loss games: `{report['total_loss_games']}`",
            f"- Cause counts: `{json.dumps(report['primary_cause_counts'], sort_keys=True)}`",
            "",
            "| Seed | Package | Deck | Losses | Avg Loss Turn | Primary Causes | Pressure | Approach | Discard-Top | Topdeck | Miracle | Low Spell |",
            "| ---: | --- | --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in report["summary_rows"]:
        flags = row.get("flag_counts") or {}
        causes = ", ".join(f"{key}={value}" for key, value in sorted((row.get("primary_cause_counts") or {}).items()))
        lines.append(
            "| {seed} | `{package}` | `{deck}` | {losses} | {avg:.2f} | {causes} | {pressure} | {approach} | {discard_top} | {topdeck} | {miracle} | {low_spell} |".format(
                seed=row["seed"],
                package=row["package_key"],
                deck=row["deck_key"],
                losses=row["losses"],
                avg=float(row["avg_loss_turn"]),
                causes=causes,
                pressure=flags.get("combat_pressure_death", 0),
                approach=flags.get("approach_seen", 0),
                discard_top=flags.get("discard_to_top_seen", 0),
                topdeck=flags.get("topdeck_seen", 0),
                miracle=flags.get("miracle_seen", 0),
                low_spell=flags.get("low_spell_volume", 0),
            )
        )
    lines.extend(
        [
            "",
            "## Per-Game Losses",
            "",
            "| Seed | Package | Game | Opponent | Turns | Cause | Flags | Evidence |",
            "| ---: | --- | --- | --- | ---: | --- | --- | --- |",
        ]
    )
    for row in report["loss_rows"]:
        signals = row.get("signals") or {}
        evidence = (
            f"approach={signals.get('approach_cast_tracked', 0)}/first={signals.get('approach_first_resolution', 0)}; "
            f"discardTop={signals.get('discard_to_top_replacement', 0)}; "
            f"topdeck={signals.get('topdeck_manipulation_activated', 0)}; "
            f"miracle={signals.get('miracle_cast', 0)}; "
            f"spell={signals.get('lorehold_spell_cast', 0)}; "
            f"combat={signals.get('combat', 0)}/{signals.get('combat_result', 0)}"
        )
        lines.append(
            "| {seed} | `{package}` | `{game}` | {opponent} | {turns} | `{cause}` | {flags} | {evidence} |".format(
                seed=row["seed"],
                package=row["package_key"],
                game=row["game_id"],
                opponent=row.get("opponent"),
                turns=row["turns"],
                cause=row["primary_cause"],
                flags=", ".join(row.get("flags") or []),
                evidence=evidence,
            )
        )
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--gate-json",
        action="append",
        type=Path,
        default=None,
        help="Detailed battle-gate JSON to classify. Defaults to Library/pressure detailed gates.",
    )
    parser.add_argument(
        "--output-stem",
        default=DEFAULT_OUTPUT_STEM,
        help="Output filename stem under master_optimizer_reports.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = args.gate_json or default_gate_paths()
    if not paths:
        raise SystemExit("no gate JSON files found")
    report = build_report(paths)
    json_path = REPORT_DIR / f"{args.output_stem}.json"
    md_path = REPORT_DIR / f"{args.output_stem}.md"
    json_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    md_path.write_text(render_markdown(report), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
