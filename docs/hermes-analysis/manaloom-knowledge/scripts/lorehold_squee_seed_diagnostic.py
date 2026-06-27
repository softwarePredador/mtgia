#!/usr/bin/env python3
"""Diagnose seed-level Squee performance in the Lorehold 607 candidate.

This is read-only. It consumes existing battle-gate JSON artifacts and writes a
source-backed report explaining whether Squee is acting as a central engine or
only as a conditional micro-upgrade when the topdeck/miracle engine is already
working.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

CANDIDATE_KEY = "candidate_607_squee_hashseed0_isolated_cached_timeout_v3"

DEFAULT_SUITE_GATES = [
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed7_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed13_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed21_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed42_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed99_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed123_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260624_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260625_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260626_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260627_v1.json",
]

DEFAULT_DIAGNOSTIC_GATES = [
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_diag_seed42_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_diag_seed7_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_diag_seed20260625_20260627_v1.json",
]

EVENT_KEYS = [
    "miracle_cast",
    "topdeck_manipulation_activated",
    "lorehold_spell_cast",
    "lorehold_cost_paid",
    "lorehold_upkeep_rummage",
    "lorehold_spell_rummage",
    "squee_to_graveyard",
    "squee_upkeep_return",
    "squee_return_after_known_graveyard_entry",
    "squee_return_without_known_graveyard_entry",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def seed_label(payload: Mapping[str, Any], path: Path) -> str:
    if payload.get("simulation_seed") is not None:
        return str(payload["simulation_seed"])
    match = re.search(r"seed(\d+)", path.name)
    return match.group(1) if match else "unknown"


def strategic_events(result: Mapping[str, Any]) -> dict[str, int]:
    events = ((result.get("telemetry") or {}).get("strategic_event_counts") or {})
    return {key: int(events.get(key) or 0) for key in EVENT_KEYS}


def compact_result(result: Mapping[str, Any]) -> dict[str, Any]:
    events = strategic_events(result)
    return {
        "deck_key": result.get("deck_key"),
        "deck_name": result.get("deck_name"),
        "games": int(result.get("games") or 0),
        "wins": int(result.get("wins") or 0),
        "losses": int(result.get("losses") or 0),
        "stalls": int(result.get("stalls") or 0),
        "win_rate": float(result.get("win_rate") or 0),
        "avg_win_turn": float(result.get("avg_win_turn") or 0),
        "strategic_events": events,
    }


def aggregate_suite(paths: list[Path]) -> dict[str, Any]:
    totals: dict[str, Counter[str]] = defaultdict(Counter)
    rows: list[dict[str, Any]] = []
    for path in paths:
        payload = read_json(path)
        if not payload:
            continue
        seed = seed_label(payload, path)
        for result in payload.get("results") or []:
            compact = compact_result(result)
            key = str(compact["deck_key"])
            rows.append({"source": str(path), "seed": seed, **compact})
            totals[key]["games"] += compact["games"]
            totals[key]["wins"] += compact["wins"]
            totals[key]["losses"] += compact["losses"]
            totals[key]["stalls"] += compact["stalls"]
            for event, count in compact["strategic_events"].items():
                totals[key][event] += count

    summary = {}
    for key, counts in sorted(totals.items()):
        games = max(1, int(counts["games"] or 0))
        summary[key] = {
            "games": int(counts["games"]),
            "wins": int(counts["wins"]),
            "losses": int(counts["losses"]),
            "stalls": int(counts["stalls"]),
            "win_rate": round(100.0 * int(counts["wins"]) / games, 2),
            "strategic_events": {event: int(counts[event]) for event in EVENT_KEYS if counts[event]},
        }
    return {"rows": rows, "summary": summary}


def summarize_games_by_result(result: Mapping[str, Any]) -> list[dict[str, Any]]:
    buckets: dict[str, Counter[str]] = defaultdict(Counter)
    for game in result.get("game_results") or []:
        outcome = str(game.get("result") or "unknown")
        bucket = buckets[outcome]
        bucket["games"] += 1
        bucket["turns"] += int(game.get("turns") or 0)
        counts = game.get("strategic_event_counts") or {}
        for event in EVENT_KEYS:
            value = int(counts.get(event) or 0)
            bucket[event] += value
            if value:
                bucket[f"games_with:{event}"] += 1

    rows = []
    for outcome, bucket in sorted(buckets.items()):
        games = max(1, int(bucket["games"]))
        rows.append(
            {
                "result": outcome,
                "games": int(bucket["games"]),
                "avg_turns": round(float(bucket["turns"]) / games, 2),
                "strategic_events": {event: int(bucket[event]) for event in EVENT_KEYS if bucket[event]},
                "games_with": {
                    event: int(bucket[f"games_with:{event}"])
                    for event in EVENT_KEYS
                    if bucket[f"games_with:{event}"]
                },
            }
        )
    return rows


def candidate_game_lens(result: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for game in result.get("game_results") or []:
        counts = game.get("strategic_event_counts") or {}
        rows.append(
            {
                "game_id": game.get("game_id"),
                "opponent": game.get("opponent"),
                "result": game.get("result"),
                "turns": int(game.get("turns") or 0),
                "miracle_cast": int(counts.get("miracle_cast") or 0),
                "topdeck_manipulation_activated": int(counts.get("topdeck_manipulation_activated") or 0),
                "lorehold_spell_cast": int(counts.get("lorehold_spell_cast") or 0),
                "squee_to_graveyard": int(counts.get("squee_to_graveyard") or 0),
                "squee_upkeep_return": int(counts.get("squee_upkeep_return") or 0),
            }
        )
    return rows


def load_diagnostic_gates(paths: list[Path]) -> list[dict[str, Any]]:
    gates = []
    for path in paths:
        payload = read_json(path)
        if not payload:
            continue
        seed = seed_label(payload, path)
        results = [compact_result(result) for result in payload.get("results") or []]
        candidate = next(
            (result for result in payload.get("results") or [] if result.get("deck_key") == CANDIDATE_KEY),
            {},
        )
        gates.append(
            {
                "source": str(path),
                "seed": seed,
                "status": payload.get("status"),
                "python_hash_seed": payload.get("python_hash_seed"),
                "deck_process_isolation": bool(payload.get("deck_process_isolation")),
                "game_timeout_seconds": payload.get("game_timeout_seconds"),
                "results": results,
                "candidate_by_result": summarize_games_by_result(candidate),
                "candidate_game_lens": candidate_game_lens(candidate),
            }
        )
    return sorted(gates, key=lambda item: (str(item["seed"]) != "42", str(item["seed"])))


def build_findings(report: Mapping[str, Any]) -> list[str]:
    gates = {str(item["seed"]): item for item in report.get("diagnostic_gates") or []}

    def candidate_events(seed: str) -> tuple[dict[str, Any], dict[str, int]]:
        gate = gates.get(seed) or {}
        result = next((row for row in gate.get("results") or [] if row.get("deck_key") == CANDIDATE_KEY), {})
        return result, result.get("strategic_events") or {}

    seed42, ev42 = candidate_events("42")
    seed7, ev7 = candidate_events("7")
    seed20260625, ev20260625 = candidate_events("20260625")
    suite = (report.get("suite_summary") or {}).get(CANDIDATE_KEY, {})
    deck607 = (report.get("suite_summary") or {}).get("deck_607", {})
    return [
        (
            "The 10-seed suite keeps Squee only narrowly ahead: "
            f"{suite.get('wins', 0)}W/{suite.get('losses', 0)}L vs deck_607 "
            f"{deck607.get('wins', 0)}W/{deck607.get('losses', 0)}L. "
            "That is evidence to keep testing, not evidence to lock the final list."
        ),
        (
            "Seed 42 is the success case: candidate "
            f"{seed42.get('wins', 0)}W/{seed42.get('losses', 0)}L with "
            f"topdeck={ev42.get('topdeck_manipulation_activated', 0)}, "
            f"miracle={ev42.get('miracle_cast', 0)}, "
            f"squee_gy={ev42.get('squee_to_graveyard', 0)}, "
            f"squee_return={ev42.get('squee_upkeep_return', 0)}."
        ),
        (
            "Seeds 7 and 20260625 are the anti-cases: candidate "
            f"{seed7.get('wins', 0)}W/{seed7.get('losses', 0)}L and "
            f"{seed20260625.get('wins', 0)}W/{seed20260625.get('losses', 0)}L, with "
            f"squee_gy={ev7.get('squee_to_graveyard', 0)}/{ev20260625.get('squee_to_graveyard', 0)} "
            f"and squee_return={ev7.get('squee_upkeep_return', 0)}/{ev20260625.get('squee_upkeep_return', 0)}."
        ),
        (
            "The practical read is that Squee is not yet a self-sufficient plan. "
            "It helps when the topdeck/miracle/spell-volume engine is alive, but in failure seeds it does not appear or convert."
        ),
    ]


def build_report(args: argparse.Namespace) -> dict[str, Any]:
    suite = aggregate_suite(args.suite_gates)
    report = {
        "generated_at": utc_now(),
        "candidate_key": CANDIDATE_KEY,
        "suite_gates": [str(path) for path in args.suite_gates],
        "diagnostic_gate_paths": [str(path) for path in args.diagnostic_gates],
        "suite_summary": suite["summary"],
        "suite_rows": suite["rows"],
        "diagnostic_gates": load_diagnostic_gates(args.diagnostic_gates),
        "postgres_writes": False,
        "source_db_mutated": False,
        "next_tests": [
            "Do not promote Squee as final on the current evidence; treat it as a provisional micro-upgrade.",
            "Test one topdeck consistency package against 607+Squee, because the winning seed is topdeck/miracle rich and the failure seeds are not.",
            "Test one explicit Squee-enabler package with discard/rummage access, because current traces prove graveyard recurrence but not the intended discard-fuel loop.",
            "Keep per-game telemetry on all decisive gates so future swaps can be explained by actual game outcomes, not aggregate counters alone.",
        ],
    }
    report["findings"] = build_findings(report)
    return report


def render_markdown(report: Mapping[str, Any]) -> str:
    lines = [
        "# Lorehold Squee Seed Diagnostic",
        "",
        f"- generated_at: `{report['generated_at']}`",
        f"- candidate_key: `{report['candidate_key']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Findings",
        "",
    ]
    for finding in report.get("findings") or []:
        lines.append(f"- {finding}")

    lines.extend(
        [
            "",
            "## 10-Seed Suite Summary",
            "",
            "| Deck | Games | W | L | S | WR | Miracle | Topdeck | Spell Cast | Cost Paid | Squee GY | Squee Return |",
            "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for key, row in sorted((report.get("suite_summary") or {}).items()):
        ev = row.get("strategic_events") or {}
        lines.append(
            f"| `{key}` | {row.get('games')} | {row.get('wins')} | {row.get('losses')} | {row.get('stalls')} | "
            f"{float(row.get('win_rate') or 0):.2f}% | {ev.get('miracle_cast', 0)} | "
            f"{ev.get('topdeck_manipulation_activated', 0)} | {ev.get('lorehold_spell_cast', 0)} | "
            f"{ev.get('lorehold_cost_paid', 0)} | {ev.get('squee_to_graveyard', 0)} | "
            f"{ev.get('squee_upkeep_return', 0)} |"
        )

    lines.extend(
        [
            "",
            "## Diagnostic Gates",
            "",
            "| Seed | Deck | Games | W | L | S | WR | Miracle | Topdeck | Spell Cast | Cost Paid | Squee GY | Squee Return |",
            "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for gate in report.get("diagnostic_gates") or []:
        for row in gate.get("results") or []:
            ev = row.get("strategic_events") or {}
            lines.append(
                f"| {gate.get('seed')} | `{row.get('deck_key')}` | {row.get('games')} | {row.get('wins')} | "
                f"{row.get('losses')} | {row.get('stalls')} | {float(row.get('win_rate') or 0):.2f}% | "
                f"{ev.get('miracle_cast', 0)} | {ev.get('topdeck_manipulation_activated', 0)} | "
                f"{ev.get('lorehold_spell_cast', 0)} | {ev.get('lorehold_cost_paid', 0)} | "
                f"{ev.get('squee_to_graveyard', 0)} | {ev.get('squee_upkeep_return', 0)} |"
            )

    lines.extend(
        [
            "",
            "## Candidate Outcome Lens",
            "",
            "| Seed | Result | Games | Avg Turns | Miracle | Topdeck | Spell Cast | Squee GY | Squee Return | Games With Topdeck | Games With Squee GY |",
            "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for gate in report.get("diagnostic_gates") or []:
        for row in gate.get("candidate_by_result") or []:
            ev = row.get("strategic_events") or {}
            games_with = row.get("games_with") or {}
            lines.append(
                f"| {gate.get('seed')} | {row.get('result')} | {row.get('games')} | "
                f"{float(row.get('avg_turns') or 0):.2f} | {ev.get('miracle_cast', 0)} | "
                f"{ev.get('topdeck_manipulation_activated', 0)} | {ev.get('lorehold_spell_cast', 0)} | "
                f"{ev.get('squee_to_graveyard', 0)} | {ev.get('squee_upkeep_return', 0)} | "
                f"{games_with.get('topdeck_manipulation_activated', 0)} | {games_with.get('squee_to_graveyard', 0)} |"
            )

    lines.extend(["", "## Next Tests", ""])
    for item in report.get("next_tests") or []:
        lines.append(f"- {item}")
    return "\n".join(lines) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--suite-gate", dest="suite_gates", type=Path, action="append")
    parser.add_argument("--diagnostic-gate", dest="diagnostic_gates", type=Path, action="append")
    parser.add_argument("--stem", default="lorehold_squee_seed_diagnostic_20260627_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.suite_gates:
        args.suite_gates = DEFAULT_SUITE_GATES
    if not args.diagnostic_gates:
        args.diagnostic_gates = DEFAULT_DIAGNOSTIC_GATES
    report = build_report(args)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(report, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(report), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
