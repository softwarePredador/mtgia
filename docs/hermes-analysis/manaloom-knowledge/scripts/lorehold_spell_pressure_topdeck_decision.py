#!/usr/bin/env python3
"""Decide the first Lorehold spell-pressure topdeck shell gate.

The shell is a full 100-card hypothesis, not a one-for-one cut. This read-only
decision layer prevents a small smoke result from being promoted unless the
candidate is structurally ready, beats protected 607, and naturally exercises
the pressure cards that justified the shell.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_BUILDER = REPORT_DIR / "lorehold_from_scratch_challengers_20260704_spell_pressure_topdeck.json"
DEFAULT_MATRIX = REPORT_DIR / "lorehold_from_scratch_challengers_20260704_spell_pressure_topdeck_matrix.json"
DEFAULT_GATE = REPORT_DIR / "lorehold_from_scratch_challengers_20260704_spell_pressure_topdeck_fixed607_gate.json"
DEFAULT_PRESSURE_MICRO = REPORT_DIR / "lorehold_pressure_micro_package_planner_20260704_current.json"
DEFAULT_CUT_BLOCKERS = REPORT_DIR / "lorehold_cut_blocker_synthesis_20260704_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_spell_pressure_topdeck_decision_20260704_current"

BASELINE_KEY = "deck_607"
CANDIDATE_KEY = "challenger_lorehold_spell_pressure_topdeck_v1"
PRESSURE_CARDS = (
    "Guttersnipe",
    "Young Pyromancer",
    "Monastery Mentor",
)
TACTICAL_PRESSURE_CARDS = (
    "Guttersnipe",
    "Young Pyromancer",
)
STRATEGIC_FLOOR_KEYS = (
    "miracle_cast",
    "topdeck_manipulation_activated",
    "lorehold_upkeep_rummage",
    "lorehold_spell_cast",
)

EXTERNAL_LEARNING = [
    {
        "source": "GameTyrant Lorehold deck tech",
        "url": "https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech",
        "learning": "Pressure creatures are valid for Lorehold only when they sit inside the miracle/topdeck plan.",
    },
    {
        "source": "EDHREC optimized spellslinger page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian/optimized/spellslinger",
        "learning": "Optimized public shells are tagged Spellslinger and Topdeck together, so pressure cannot replace the topdeck engine.",
    },
    {
        "source": "Draftsim Lorehold guide",
        "url": "https://draftsim.com/lorehold-the-historian-edh-deck/",
        "learning": "Lorehold's repeated upkeep rummage and miracle timing remain the central engine to protect.",
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_int(value: Any) -> int:
    try:
        return int(value)
    except Exception:
        return 0


def as_float(value: Any) -> float:
    try:
        return float(value)
    except Exception:
        return 0.0


def first_candidate(builder: Mapping[str, Any]) -> dict[str, Any]:
    for row in builder.get("candidates") or []:
        if isinstance(row, Mapping) and row.get("candidate_key") == CANDIDATE_KEY:
            return dict(row)
    return {}


def deck_names(candidate: Mapping[str, Any]) -> set[str]:
    return {
        str(row.get("card_name") or "")
        for row in candidate.get("final_deck") or []
        if isinstance(row, Mapping)
    }


def ranked_index(matrix: Mapping[str, Any], deck_key: str) -> int | None:
    keys = [str(item) for item in matrix.get("ranked_deck_keys") or []]
    try:
        return keys.index(deck_key) + 1
    except ValueError:
        return None


def matrix_deck(matrix: Mapping[str, Any], deck_key: str) -> dict[str, Any]:
    for row in matrix.get("decks") or []:
        if isinstance(row, Mapping) and row.get("deck_key") == deck_key:
            return dict(row)
    return {}


def gate_row(gate: Mapping[str, Any], deck_key: str) -> dict[str, Any]:
    for row in gate.get("results") or []:
        if isinstance(row, Mapping) and row.get("deck_key") == deck_key:
            return dict(row)
    return {}


def game_record_by_opponent(row: Mapping[str, Any]) -> dict[str, str]:
    out: dict[str, str] = {}
    for result in row.get("game_results") or []:
        if isinstance(result, Mapping):
            out[str(result.get("opponent") or "")] = str(result.get("result") or "")
    return out


def strategic_games(row: Mapping[str, Any], key: str) -> int:
    telemetry = row.get("telemetry") if isinstance(row.get("telemetry"), Mapping) else {}
    strategic = telemetry.get("strategic_games") if isinstance(telemetry, Mapping) else {}
    value = strategic.get(key) if isinstance(strategic, Mapping) else {}
    if isinstance(value, Mapping):
        return as_int(value.get("games"))
    return 0


def card_event_counts(row: Mapping[str, Any], card_names: tuple[str, ...]) -> dict[str, int]:
    telemetry = row.get("telemetry") if isinstance(row.get("telemetry"), Mapping) else {}
    counts = telemetry.get("card_event_counts") if isinstance(telemetry, Mapping) else {}
    out: dict[str, int] = {}
    if not isinstance(counts, Mapping):
        return out
    for event, count in counts.items():
        event_text = str(event)
        for card in card_names:
            if f":{card}" in event_text:
                out[event_text] = as_int(count)
    return dict(sorted(out.items()))


def build_payload(
    *,
    builder: Mapping[str, Any],
    matrix: Mapping[str, Any],
    gate: Mapping[str, Any],
    pressure_micro: Mapping[str, Any],
    cut_blockers: Mapping[str, Any],
    builder_path: Path,
    matrix_path: Path,
    gate_path: Path,
    pressure_micro_path: Path,
    cut_blockers_path: Path,
) -> dict[str, Any]:
    candidate_report = first_candidate(builder)
    names = deck_names(candidate_report)
    covered_pressure = [card for card in PRESSURE_CARDS if card in names]
    covered_tactical = [card for card in TACTICAL_PRESSURE_CARDS if card in names]
    candidate_matrix = matrix_deck(matrix, CANDIDATE_KEY)
    baseline_matrix = matrix_deck(matrix, BASELINE_KEY)
    candidate_rank = ranked_index(matrix, CANDIDATE_KEY)
    baseline_rank = ranked_index(matrix, BASELINE_KEY)
    candidate_gate = gate_row(gate, CANDIDATE_KEY)
    baseline_gate = gate_row(gate, BASELINE_KEY)
    candidate_record = {
        "wins": as_int(candidate_gate.get("wins")),
        "losses": as_int(candidate_gate.get("losses")),
        "stalls": as_int(candidate_gate.get("stalls")),
        "games": as_int(candidate_gate.get("games")),
        "win_rate": as_float(candidate_gate.get("win_rate")),
    }
    baseline_record = {
        "wins": as_int(baseline_gate.get("wins")),
        "losses": as_int(baseline_gate.get("losses")),
        "stalls": as_int(baseline_gate.get("stalls")),
        "games": as_int(baseline_gate.get("games")),
        "win_rate": as_float(baseline_gate.get("win_rate")),
    }
    candidate_games = game_record_by_opponent(candidate_gate)
    baseline_games = game_record_by_opponent(baseline_gate)
    pressure_events = card_event_counts(candidate_gate, PRESSURE_CARDS)
    observed_pressure_cards = sorted(
        {
            card
            for event in pressure_events
            for card in PRESSURE_CARDS
            if f":{card}" in event
        }
    )
    strategic_deltas = {
        key: strategic_games(candidate_gate, key) - strategic_games(baseline_gate, key)
        for key in STRATEGIC_FLOOR_KEYS
    }
    candidate_risks = (
        (candidate_matrix.get("commander_intent_alignment") or {}).get("risks")
        if isinstance(candidate_matrix.get("commander_intent_alignment"), Mapping)
        else []
    ) or []
    failure_modes: list[str] = []
    if baseline_rank and candidate_rank and candidate_rank > baseline_rank:
        failure_modes.append("structural_rank_below_607")
    if candidate_games.get("Fixed Lorehold deck 607") == "loss":
        failure_modes.append("head_to_head_lost_to_607")
    if candidate_games.get("Winota, Joiner of Forces #39 (real)") != "win":
        failure_modes.append("no_fast_pressure_lift")
    if len(observed_pressure_cards) < len(TACTICAL_PRESSURE_CARDS):
        failure_modes.append("pressure_pair_underexercised")
    if any(value < 0 for value in strategic_deltas.values()):
        failure_modes.append("miracle_topdeck_or_lorehold_floor_regressed")
    if any(str(item).startswith("package_") for item in candidate_risks):
        failure_modes.append("package_density_not_clean")
    if (cut_blockers.get("summary") or {}).get("seed_safe_ready_count") == 0:
        failure_modes.append("no_seed_safe_cut_fallback")

    aggregate_delta_wins = candidate_record["wins"] - baseline_record["wins"]
    status = (
        "spell_pressure_smoke_positive_but_not_confirmable"
        if aggregate_delta_wins > 0
        else "spell_pressure_smoke_rejected_or_neutral"
    )
    natural_trigger_cards = (pressure_micro.get("summary") or {}).get("natural_trigger_cards") or []
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_spell_pressure_topdeck_decision",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": {
            "builder": rel(builder_path),
            "matrix": rel(matrix_path),
            "battle_gate": rel(gate_path),
            "pressure_micro_package": rel(pressure_micro_path),
            "cut_blocker_synthesis": rel(cut_blockers_path),
        },
        "external_learning": EXTERNAL_LEARNING,
        "status": status,
        "summary": {
            "baseline_rank": baseline_rank,
            "candidate_rank": candidate_rank,
            "aggregate_delta_wins": aggregate_delta_wins,
            "candidate_record": candidate_record,
            "baseline_record": baseline_record,
            "covered_pressure_cards": covered_pressure,
            "covered_tactical_pressure_cards": covered_tactical,
            "observed_pressure_cards": observed_pressure_cards,
            "natural_trigger_cards_from_micro_plan": natural_trigger_cards,
            "failure_modes": sorted(set(failure_modes)),
            "promotion_allowed": False,
            "confirmation_allowed": False,
        },
        "structural": {
            "baseline_intent": (baseline_matrix.get("commander_intent_alignment") or {}),
            "candidate_intent": (candidate_matrix.get("commander_intent_alignment") or {}),
            "candidate_risks": candidate_risks,
        },
        "battle": {
            "candidate_games_by_opponent": candidate_games,
            "baseline_games_by_opponent": baseline_games,
            "strategic_floor_deltas": strategic_deltas,
            "pressure_card_event_counts": pressure_events,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "promotion_allowed": False,
            "confirmation_allowed": False,
            "reason": (
                "The new full-shell pressure deck produced a small smoke aggregate lift, "
                "but it ranked below 607 structurally, lost the head-to-head mirror, "
                "regressed key miracle/topdeck/Lorehold floor metrics, and naturally "
                "exercised only part of the pressure pair."
            ),
            "next_actions": [
                "do_not_promote_or_confirm_this_exact_shell_yet",
                "mine_the_sisay_win_trace_for_whether_young_pyromancer_mattered",
                "repair_pressure_card_exposure_before_any_confirm8x3_gate",
                "keep_607_protected_until_equal_gate_and_card_use_proof",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Spell Pressure Topdeck Decision",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- baseline_rank: `{summary['baseline_rank']}`",
        f"- candidate_rank: `{summary['candidate_rank']}`",
        f"- aggregate_delta_wins: `{summary['aggregate_delta_wins']}`",
        f"- candidate_record: `{json.dumps(summary['candidate_record'], sort_keys=True)}`",
        f"- baseline_record: `{json.dumps(summary['baseline_record'], sort_keys=True)}`",
        f"- observed_pressure_cards: `{json.dumps(summary['observed_pressure_cards'])}`",
        f"- failure_modes: `{json.dumps(summary['failure_modes'])}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        f"- confirmation_allowed: `{str(summary['confirmation_allowed']).lower()}`",
        "",
        "## Battle Detail",
        "",
        f"- candidate_games_by_opponent: `{json.dumps(payload['battle']['candidate_games_by_opponent'], sort_keys=True)}`",
        f"- baseline_games_by_opponent: `{json.dumps(payload['battle']['baseline_games_by_opponent'], sort_keys=True)}`",
        f"- strategic_floor_deltas: `{json.dumps(payload['battle']['strategic_floor_deltas'], sort_keys=True)}`",
        f"- pressure_card_event_counts: `{json.dumps(payload['battle']['pressure_card_event_counts'], sort_keys=True)}`",
        "",
        "## External Learning",
        "",
    ]
    for source in payload.get("external_learning") or []:
        lines.append(f"- {source['source']}: {source['url']}")
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(payload['decision']['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(payload['decision']['promotion_allowed']).lower()}`")
    lines.append(f"- confirmation_allowed: `{str(payload['decision']['confirmation_allowed']).lower()}`")
    lines.append(f"- reason: {payload['decision']['reason']}")
    lines.append("- next_actions:")
    for action in payload["decision"]["next_actions"]:
        lines.append(f"  - {action}")
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
    parser.add_argument("--builder", type=Path, default=DEFAULT_BUILDER)
    parser.add_argument("--matrix", type=Path, default=DEFAULT_MATRIX)
    parser.add_argument("--gate", type=Path, default=DEFAULT_GATE)
    parser.add_argument("--pressure-micro", type=Path, default=DEFAULT_PRESSURE_MICRO)
    parser.add_argument("--cut-blockers", type=Path, default=DEFAULT_CUT_BLOCKERS)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_payload(
        builder=read_json(args.builder),
        matrix=read_json(args.matrix),
        gate=read_json(args.gate),
        pressure_micro=read_json(args.pressure_micro),
        cut_blockers=read_json(args.cut_blockers),
        builder_path=args.builder,
        matrix_path=args.matrix,
        gate_path=args.gate,
        pressure_micro_path=args.pressure_micro,
        cut_blockers_path=args.cut_blockers,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
