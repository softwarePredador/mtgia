#!/usr/bin/env python3
"""Consolidate Lorehold promotion-gate evidence.

This read-only audit consumes natural equal battle gates and decides whether a
candidate can replace protected baseline deck_607. It does not mutate
PostgreSQL, Hermes SQLite, or deck contents.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

BASELINE_KEY = "deck_607"
CHALLENGER_KEYS = ("deck_614", "deck_615")
PRESSURE_OPPONENTS = {"Winota, Joiner of Forces #39 (real)"}

DEFAULT_GATE_PATHS = [
    REPORT_DIR / "lorehold_promotion_gate_607_614_615_20260629_seed42_real8_games3.json",
    REPORT_DIR / "lorehold_promotion_gate_607_614_615_20260629_seed7_real8_games3.json",
    REPORT_DIR / "lorehold_promotion_gate_607_614_615_20260629_seed20260625_real8_games3.json",
]

KEY_STRATEGIC_GAMES = [
    "lorehold_cost_paid",
    "lorehold_spell_cast",
    "lorehold_upkeep_rummage",
    "miracle_cast",
    "topdeck_manipulation_activated",
    "discard_to_top_replacement",
    "birgi_spell_cast_mana",
    "spell_cast_mana_trigger",
]

FOCUS_CARDS = [
    "Approach of the Second Sun",
    "Aetherflux Reservoir",
    "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
    "Mana Vault",
    "Rise of the Eldrazi",
    "Sensei's Divining Top",
    "Scroll Rack",
    "The One Ring",
    "The Mind Stone",
    "Molecule Man",
    "Surge to Victory",
    "Mizzix's Mastery",
    "Seething Song",
    "Call Forth the Tempest",
    "Land Tax",
    "Library of Leng",
    "Squee, Goblin Nabob",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def as_float(value: Any) -> float:
    try:
        return float(value or 0.0)
    except Exception:
        return 0.0


def init_deck_row(deck_key: str) -> dict[str, Any]:
    return {
        "deck_key": deck_key,
        "deck_name": None,
        "archetype": None,
        "structural_rank": None,
        "games": 0,
        "wins": 0,
        "losses": 0,
        "stalls": 0,
        "win_turn_weighted_sum": 0.0,
        "win_reasons": Counter(),
        "seed_windows": {},
        "opponents": defaultdict(lambda: {"games": 0, "wins": 0, "losses": 0, "stalls": 0}),
        "strategic_event_counts": Counter(),
        "strategic_game_counts": Counter(),
        "early_loss_count": 0,
        "loss_turn_sum": 0,
        "loss_turn_count": 0,
        "focus_access": defaultdict(
            lambda: {
                "trace_games": 0,
                "accessed_games": 0,
                "near_access_games": 0,
                "drawn_games": 0,
                "opening_hand_games": 0,
                "library_only_games": 0,
                "trace_count": 0,
            }
        ),
        "card_use_metrics": defaultdict(Counter),
    }


def merge_result(row: dict[str, Any], result: Mapping[str, Any], seed: str) -> None:
    row["deck_name"] = result.get("deck_name") or row["deck_name"]
    row["archetype"] = result.get("archetype") or row["archetype"]
    row["structural_rank"] = result.get("structural_rank") or row["structural_rank"]
    games = as_int(result.get("games"))
    wins = as_int(result.get("wins"))
    losses = as_int(result.get("losses"))
    stalls = as_int(result.get("stalls"))
    row["games"] += games
    row["wins"] += wins
    row["losses"] += losses
    row["stalls"] += stalls
    row["win_turn_weighted_sum"] += as_float(result.get("avg_win_turn")) * wins
    row["seed_windows"][seed] = {
        "games": games,
        "wins": wins,
        "losses": losses,
        "stalls": stalls,
        "win_rate": round(wins / max(1, games) * 100.0, 2),
    }
    row["win_reasons"].update({str(k): as_int(v) for k, v in (result.get("win_reasons") or {}).items()})

    for opponent in result.get("opponents") or []:
        name = str(opponent.get("opponent") or "unknown")
        target = row["opponents"][name]
        o_wins = as_int(opponent.get("wins"))
        o_losses = as_int(opponent.get("losses"))
        o_stalls = as_int(opponent.get("stalls"))
        target["wins"] += o_wins
        target["losses"] += o_losses
        target["stalls"] += o_stalls
        target["games"] += o_wins + o_losses + o_stalls

    telemetry = result.get("telemetry") if isinstance(result.get("telemetry"), Mapping) else {}
    row["strategic_event_counts"].update(
        {str(k): as_int(v) for k, v in (telemetry.get("strategic_event_counts") or {}).items()}
    )
    for key, value in (telemetry.get("strategic_games") or {}).items():
        if isinstance(value, Mapping):
            row["strategic_game_counts"][str(key)] += as_int(value.get("games"))

    focus_summary = telemetry.get("focus_card_access_summary") or {}
    for card in FOCUS_CARDS:
        payload = focus_summary.get(card)
        if not isinstance(payload, Mapping):
            continue
        target = row["focus_access"][card]
        for field in target:
            target[field] += as_int(payload.get(field))

    has_game_card_counts = False
    for game in result.get("game_results") or []:
        card_event_counts = game.get("card_event_counts") or {}
        if card_event_counts:
            has_game_card_counts = True
        for key, count in card_event_counts.items():
            if ":" not in str(key):
                continue
            metric_name, card_name = str(key).split(":", 1)
            if card_name in FOCUS_CARDS:
                row["card_use_metrics"][card_name][metric_name] += as_int(count)
        if game.get("result") != "loss":
            continue
        turns = as_int(game.get("turns"))
        row["loss_turn_sum"] += turns
        row["loss_turn_count"] += 1
        if turns and turns <= 9:
            row["early_loss_count"] += 1

    if not has_game_card_counts:
        for metric in telemetry.get("top_cards") or []:
            key = str(metric.get("key") or "")
            if ":" not in key:
                continue
            metric_name, card_name = key.split(":", 1)
            if card_name in FOCUS_CARDS:
                row["card_use_metrics"][card_name][metric_name] += as_int(metric.get("count"))


def finalize_deck_row(row: Mapping[str, Any]) -> dict[str, Any]:
    games = as_int(row.get("games"))
    wins = as_int(row.get("wins"))
    losses = as_int(row.get("losses"))
    avg_win_turn = round(float(row.get("win_turn_weighted_sum") or 0.0) / max(1, wins), 2)
    avg_loss_turn = round(float(row.get("loss_turn_sum") or 0.0) / max(1, as_int(row.get("loss_turn_count"))), 2)
    opponents = {
        name: {
            **dict(value),
            "win_rate": round(as_int(value.get("wins")) / max(1, as_int(value.get("games"))) * 100.0, 2),
        }
        for name, value in sorted(row.get("opponents", {}).items())
    }
    return {
        "deck_key": row["deck_key"],
        "deck_name": row.get("deck_name"),
        "archetype": row.get("archetype"),
        "structural_rank": row.get("structural_rank"),
        "games": games,
        "wins": wins,
        "losses": losses,
        "stalls": as_int(row.get("stalls")),
        "win_rate": round(wins / max(1, games) * 100.0, 2),
        "avg_win_turn": avg_win_turn,
        "avg_loss_turn": avg_loss_turn,
        "early_loss_count": as_int(row.get("early_loss_count")),
        "early_loss_rate": round(as_int(row.get("early_loss_count")) / max(1, losses) * 100.0, 2),
        "win_reasons": dict(sorted((row.get("win_reasons") or {}).items())),
        "seed_windows": dict(sorted((row.get("seed_windows") or {}).items())),
        "opponents": opponents,
        "pressure_opponents": {
            name: opponents.get(name, {"games": 0, "wins": 0, "losses": 0, "stalls": 0, "win_rate": 0.0})
            for name in sorted(PRESSURE_OPPONENTS)
        },
        "strategic_event_counts": dict(sorted((row.get("strategic_event_counts") or {}).items())),
        "strategic_game_counts": {
            key: as_int((row.get("strategic_game_counts") or {}).get(key))
            for key in KEY_STRATEGIC_GAMES
        },
        "focus_access": {
            card: dict(values)
            for card, values in sorted((row.get("focus_access") or {}).items())
            if any(as_int(value) for value in values.values())
        },
        "card_use_metrics": {
            card: dict(sorted(metrics.items()))
            for card, metrics in sorted((row.get("card_use_metrics") or {}).items())
            if metrics
        },
    }


def candidate_assessment(candidate: Mapping[str, Any], baseline: Mapping[str, Any]) -> dict[str, Any]:
    reasons: list[str] = []
    passes: list[str] = []

    if as_int(candidate.get("wins")) >= as_int(baseline.get("wins")):
        passes.append("aggregate_wins_tie_or_beat_baseline")
    else:
        reasons.append(
            f"aggregate wins {candidate.get('wins')}/{candidate.get('games')} below baseline "
            f"{baseline.get('wins')}/{baseline.get('games')}"
        )

    candidate_seed_wins = 0
    seed_count = 0
    for seed, baseline_seed in (baseline.get("seed_windows") or {}).items():
        seed_count += 1
        cand_seed = (candidate.get("seed_windows") or {}).get(seed) or {}
        if as_int(cand_seed.get("wins")) >= as_int(baseline_seed.get("wins")):
            candidate_seed_wins += 1
    if candidate_seed_wins >= max(1, (seed_count // 2) + 1):
        passes.append("seed_window_majority_tie_or_beat")
    else:
        reasons.append(f"tied/beat baseline in only {candidate_seed_wins}/{seed_count} seed windows")

    pressure_failures = []
    for opponent in PRESSURE_OPPONENTS:
        cand_row = (candidate.get("pressure_opponents") or {}).get(opponent) or {}
        base_row = (baseline.get("pressure_opponents") or {}).get(opponent) or {}
        if as_int(cand_row.get("wins")) < as_int(base_row.get("wins")):
            pressure_failures.append(
                f"{opponent}: {cand_row.get('wins', 0)}/{cand_row.get('games', 0)} "
                f"below baseline {base_row.get('wins', 0)}/{base_row.get('games', 0)}"
            )
    if pressure_failures:
        reasons.extend(pressure_failures)
    else:
        passes.append("no_pressure_matchup_regression")

    strategic = candidate.get("strategic_game_counts") or {}
    if as_int(strategic.get("lorehold_spell_cast")) and as_int(strategic.get("miracle_cast")):
        passes.append("commander_plan_trace_present")
    else:
        reasons.append("missing Lorehold spell-cast plus miracle trace")

    if as_int(candidate.get("early_loss_count")) > as_int(baseline.get("early_loss_count")):
        reasons.append(
            f"early losses {candidate.get('early_loss_count')} exceed baseline {baseline.get('early_loss_count')}"
        )

    status = "promote" if not reasons else "do_not_promote"
    return {
        "deck_key": candidate.get("deck_key"),
        "status": status,
        "passes": passes,
        "blockers": reasons,
    }


def build_report(
    gate_paths: Iterable[Path],
    *,
    baseline_key: str = BASELINE_KEY,
    candidate_keys: Iterable[str] = CHALLENGER_KEYS,
) -> dict[str, Any]:
    gates: list[dict[str, Any]] = []
    aggregates: dict[str, dict[str, Any]] = {}
    input_paths = list(gate_paths)
    candidate_key_tuple = tuple(dict.fromkeys(str(key) for key in candidate_keys))
    consumed_keys = {baseline_key, *candidate_key_tuple}
    for path in input_paths:
        payload = read_json(path)
        gates.append(
            {
                "path": rel(path),
                "status": payload.get("status"),
                "games_per_opponent": payload.get("games_per_opponent"),
                "opponent_kind": payload.get("opponent_kind"),
                "opponent_seed": payload.get("opponent_seed"),
                "simulation_seed": payload.get("simulation_seed"),
                "forced_access_mode": payload.get("forced_access_mode"),
                "deck_process_isolation": payload.get("deck_process_isolation"),
                "opponents": payload.get("opponents") or [],
            }
        )
        seed = str(payload.get("simulation_seed"))
        for result in payload.get("results") or []:
            deck_key = str(result.get("deck_key") or "")
            if deck_key not in consumed_keys:
                continue
            row = aggregates.setdefault(deck_key, init_deck_row(deck_key))
            merge_result(row, result, seed)

    finalized = {deck_key: finalize_deck_row(row) for deck_key, row in sorted(aggregates.items())}
    baseline = finalized.get(baseline_key)
    candidate_rows = [
        candidate_assessment(finalized[key], baseline)
        for key in candidate_key_tuple
        if baseline and key in finalized
    ]
    promoted = [row["deck_key"] for row in candidate_rows if row["status"] == "promote"]
    best_challenger = None
    challengers = [finalized[key] for key in candidate_key_tuple if key in finalized]
    if challengers:
        best_challenger = max(challengers, key=lambda row: (as_int(row.get("wins")), -as_int(row.get("early_loss_count"))))

    decision_status = "promote_challenger" if promoted else "keep_protected_baseline"
    decision = {
        "status": decision_status,
        "protected_baseline": baseline_key,
        "candidate_keys": list(candidate_key_tuple),
        "promoted_deck_keys": promoted,
        "best_challenger_for_package_followup": (best_challenger or {}).get("deck_key"),
        "ready_for_real_deck_change": bool(promoted),
        "summary": (
            "No challenger cleared aggregate, seed-window, pressure-matchup, and trace gates."
            if not promoted
            else f"Promotion allowed for {', '.join(promoted)}."
        ),
        "recommended_next_action": (
            "Keep deck_607 as baseline; create a narrow package test from deck_615 pressure/mana positives "
            "instead of swapping decks blindly."
            if not promoted
            else "Prepare guarded deck promotion package and rerun validation after swap."
        ),
    }

    return {
        "generated_at": utc_now(),
        "status": "pass",
        "postgres_writes": False,
        "source_db_mutated": False,
        "gate_paths": [rel(path) for path in input_paths],
        "gate_inputs": gates,
        "baseline_key": baseline_key,
        "candidate_keys": list(candidate_key_tuple),
        "deck_aggregates": finalized,
        "candidate_assessments": candidate_rows,
        "decision": decision,
    }


def markdown_card_metrics(deck: Mapping[str, Any], cards: list[str]) -> list[str]:
    lines = [
        "| Card | Accessed Games | Drawn Games | Near Access Games | Use Metrics |",
        "| --- | ---: | ---: | ---: | --- |",
    ]
    access = deck.get("focus_access") or {}
    metrics = deck.get("card_use_metrics") or {}
    for card in cards:
        access_row = access.get(card) or {}
        metric_row = metrics.get(card) or {}
        if not access_row and not metric_row:
            continue
        metric_text = ", ".join(f"{key}={value}" for key, value in sorted(metric_row.items())) or "none"
        lines.append(
            f"| {card} | {as_int(access_row.get('accessed_games'))} | "
            f"{as_int(access_row.get('drawn_games'))} | "
            f"{as_int(access_row.get('near_access_games'))} | {metric_text} |"
        )
    return lines


def write_markdown(report: Mapping[str, Any], path: Path) -> None:
    decision = report["decision"]
    lines = [
        "# Lorehold Promotion Gate Decision Audit",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        f"- Decision: `{decision['status']}`",
        f"- Protected baseline: `{decision['protected_baseline']}`",
        f"- Candidate keys: `{json.dumps(decision['candidate_keys'])}`",
        f"- Promoted deck keys: `{json.dumps(decision['promoted_deck_keys'])}`",
        f"- Ready for real deck change: `{str(decision['ready_for_real_deck_change']).lower()}`",
        f"- Best challenger for package follow-up: `{decision['best_challenger_for_package_followup']}`",
        f"- Summary: {decision['summary']}",
        f"- Recommended next action: {decision['recommended_next_action']}",
        "",
        "## Gate Inputs",
        "",
        "| Seed | Games/Opp | Opponents | Forced Access | Status |",
        "| ---: | ---: | ---: | --- | --- |",
    ]
    for gate in report["gate_inputs"]:
        lines.append(
            f"| {gate.get('simulation_seed')} | {gate.get('games_per_opponent')} | "
            f"{len(gate.get('opponents') or [])} | `{gate.get('forced_access_mode')}` | `{gate.get('status')}` |"
        )

    lines.extend(
        [
            "",
            "## Aggregate Result",
            "",
            "| Deck | Structural Rank | Games | W | L | WR | Avg Win Turn | Early Losses | Winota W-L | Win Reasons |",
            "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |",
        ]
    )
    for deck_key, deck in sorted(report["deck_aggregates"].items()):
        winota = (deck.get("pressure_opponents") or {}).get("Winota, Joiner of Forces #39 (real)") or {}
        reasons = ", ".join(f"{key}={value}" for key, value in (deck.get("win_reasons") or {}).items()) or "none"
        lines.append(
            f"| `{deck_key}` | {deck.get('structural_rank')} | {deck.get('games')} | {deck.get('wins')} | "
            f"{deck.get('losses')} | {deck.get('win_rate')}% | {deck.get('avg_win_turn')} | "
            f"{deck.get('early_loss_count')} | {winota.get('wins', 0)}-{winota.get('losses', 0)} | {reasons} |"
        )

    lines.extend(["", "## Candidate Assessments", ""])
    for row in report["candidate_assessments"]:
        lines.append(f"### {row['deck_key']}")
        lines.append("")
        lines.append(f"- Status: `{row['status']}`")
        lines.append(f"- Passes: {', '.join(row['passes']) or 'none'}")
        lines.append(f"- Blockers: {'; '.join(row['blockers']) or 'none'}")
        lines.append("")

    lines.extend(["## Strategic Game Counts", ""])
    lines.append("| Deck | " + " | ".join(KEY_STRATEGIC_GAMES) + " |")
    lines.append("| --- | " + " | ".join("---:" for _ in KEY_STRATEGIC_GAMES) + " |")
    for deck_key, deck in sorted(report["deck_aggregates"].items()):
        counts = deck.get("strategic_game_counts") or {}
        lines.append("| `" + deck_key + "` | " + " | ".join(str(counts.get(key, 0)) for key in KEY_STRATEGIC_GAMES) + " |")

    lines.extend(["", "## Key Card Trace And Use Evidence", ""])
    for deck_key, deck in sorted(report["deck_aggregates"].items()):
        lines.append(f"### {deck_key}")
        lines.append("")
        lines.extend(markdown_card_metrics(deck, FOCUS_CARDS))
        lines.append("")

    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gate", action="append", dest="gate_paths", type=Path, default=None)
    parser.add_argument("--baseline-key", default=BASELINE_KEY)
    parser.add_argument(
        "--candidate-key",
        action="append",
        dest="candidate_keys",
        default=None,
        help="Deck key to assess against the protected baseline. Defaults to deck_614 and deck_615.",
    )
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_promotion_gate_decision_audit_20260629_current",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report(
        args.gate_paths or DEFAULT_GATE_PATHS,
        baseline_key=args.baseline_key,
        candidate_keys=args.candidate_keys or CHALLENGER_KEYS,
    )
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(report, indent=2, ensure_ascii=True, sort_keys=True) + "\n", encoding="utf-8")
    write_markdown(report, md_path)
    print(json.dumps({"status": report["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
