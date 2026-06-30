#!/usr/bin/env python3
"""Mine Lorehold closing-window trace gaps from rejected shell gates.

The input gates already ran. This read-only miner compares exact same-opponent
game slots where protected deck_607 won and a from-scratch challenger lost. The
output is a trace-targeted hypothesis queue, not a deck change.
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
PROTECTED_BASELINE_KEY = "deck_607"

DEFAULT_GATE_REPORTS = [
    REPORT_DIR
    / "lorehold_from_scratch_challengers_20260630_goal_definitive_learning_v1_recursion_discard_engine_confirm8x3.json",
    REPORT_DIR
    / "lorehold_from_scratch_challengers_20260630_goal_pressure_repair_v1_recursion_discard_pressure_repair_confirm8x3_sources_v3.json",
    REPORT_DIR
    / "lorehold_from_scratch_challengers_20260630_access_density_control_v1_access_density_control_fixed607_gate.json",
    REPORT_DIR
    / "lorehold_from_scratch_challengers_20260630_access_density_control_v1_access_density_control_forced_tutors_pipe_opening_gate.json",
]

CORE_EVENTS = (
    "miracle_cast",
    "topdeck_manipulation_activated",
    "lorehold_cost_paid",
    "lorehold_spell_cast",
    "lorehold_upkeep_rummage",
    "static_cost_reduction_total",
    "birgi_spell_cast_mana",
    "squee_upkeep_return",
)
ANCHOR_CARD_NAMES = (
    "Approach of the Second Sun",
    "Bender's Waterskin",
    "Big Score",
    "Creative Technique",
    "Jeska's Will",
    "Lorehold, the Historian",
    "Mizzix's Mastery",
    "Molecule Man",
    "Scroll Rack",
    "Sensei's Divining Top",
    "Storm Herd",
    "Surge to Victory",
    "The Scarlet Witch",
    "Victory Chimes",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def read_existing_json(paths: Iterable[Path]) -> list[tuple[Path, dict[str, Any]]]:
    loaded: list[tuple[Path, dict[str, Any]]] = []
    for path in paths:
        if path.exists():
            loaded.append((path, read_json(path)))
    return loaded


def as_int(value: Any) -> int:
    try:
        return int(value)
    except Exception:
        return 0


def game_slot(game: Mapping[str, Any]) -> tuple[str, int]:
    return (str(game.get("opponent") or ""), as_int(game.get("game_index")))


def event_counts(game: Mapping[str, Any]) -> Mapping[str, Any]:
    value = game.get("strategic_event_counts")
    return value if isinstance(value, Mapping) else {}


def card_counts(game: Mapping[str, Any]) -> Mapping[str, Any]:
    value = game.get("card_event_counts")
    return value if isinstance(value, Mapping) else {}


def delta_counts(
    baseline: Mapping[str, Any],
    candidate: Mapping[str, Any],
    keys: Iterable[str],
) -> dict[str, int]:
    baseline_counts = event_counts(baseline)
    candidate_counts = event_counts(candidate)
    return {
        key: as_int(baseline_counts.get(key)) - as_int(candidate_counts.get(key))
        for key in keys
    }


def anchor_card_deltas(
    baseline: Mapping[str, Any],
    candidate: Mapping[str, Any],
) -> dict[str, int]:
    baseline_counts = card_counts(baseline)
    candidate_counts = card_counts(candidate)
    out: dict[str, int] = {}
    for key, value in baseline_counts.items():
        text = str(key)
        if not any(card in text for card in ANCHOR_CARD_NAMES):
            continue
        delta = as_int(value) - as_int(candidate_counts.get(key))
        if delta > 0:
            out[text] = delta
    return dict(sorted(out.items(), key=lambda row: (-row[1], row[0]))[:12])


def classify_comparison(
    baseline: Mapping[str, Any],
    candidate: Mapping[str, Any],
    deltas: Mapping[str, int],
    card_deltas: Mapping[str, int],
) -> list[str]:
    gaps: list[str] = []
    if "life_zero" in str(candidate.get("reason") or ""):
        gaps.append("candidate_died_before_closing_window")
    if as_int(candidate.get("turns")) + 2 < as_int(baseline.get("turns")):
        gaps.append("candidate_lost_multiple_turns_before_607_finish")
    if deltas.get("miracle_cast", 0) > 0:
        gaps.append("miracle_cast_deficit")
    if deltas.get("topdeck_manipulation_activated", 0) > 0:
        gaps.append("topdeck_activation_deficit")
    if deltas.get("lorehold_spell_cast", 0) > 0:
        gaps.append("lorehold_spell_volume_deficit")
    if deltas.get("lorehold_upkeep_rummage", 0) > 0:
        gaps.append("upkeep_rummage_deficit")
    if deltas.get("static_cost_reduction_total", 0) > 0:
        gaps.append("static_cost_reduction_deficit")
    if any("Approach of the Second Sun" in key for key in card_deltas):
        gaps.append("approach_conversion_missing")
    if any("Sensei's Divining Top" in key or "Scroll Rack" in key for key in card_deltas):
        gaps.append("topdeck_engine_card_deficit")
    if any("Bender's Waterskin" in key or "Victory Chimes" in key for key in card_deltas):
        gaps.append("607_mana_timing_anchor_deficit")
    return sorted(set(gaps))


def source_side_rows(payload: Mapping[str, Any]) -> tuple[dict[str, Any] | None, list[dict[str, Any]]]:
    results = [row for row in payload.get("results") or [] if isinstance(row, dict)]
    baseline = next((row for row in results if row.get("deck_key") == PROTECTED_BASELINE_KEY), None)
    challengers = [row for row in results if row.get("deck_key") != PROTECTED_BASELINE_KEY]
    return baseline, challengers


def mine_report(path: Path, payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    baseline_result, challengers = source_side_rows(payload)
    if not baseline_result:
        return []
    baseline_games = {
        game_slot(game): game
        for game in baseline_result.get("game_results") or []
        if isinstance(game, Mapping)
    }
    rows: list[dict[str, Any]] = []
    for challenger in challengers:
        candidate_key = str(challenger.get("deck_key") or "")
        for game in challenger.get("game_results") or []:
            if not isinstance(game, Mapping) or game.get("result") != "loss":
                continue
            baseline_game = baseline_games.get(game_slot(game))
            if not baseline_game or baseline_game.get("result") != "win":
                continue
            deltas = delta_counts(baseline_game, game, CORE_EVENTS)
            positive_deltas = {key: value for key, value in deltas.items() if value > 0}
            card_deltas = anchor_card_deltas(baseline_game, game)
            rows.append(
                {
                    "source_report": rel(path),
                    "candidate_key": candidate_key,
                    "opponent": baseline_game.get("opponent"),
                    "opponent_archetype": baseline_game.get("opponent_archetype"),
                    "game_index": baseline_game.get("game_index"),
                    "baseline_game_id": baseline_game.get("game_id"),
                    "candidate_game_id": game.get("game_id"),
                    "baseline_result": baseline_game.get("result"),
                    "candidate_result": game.get("result"),
                    "baseline_reason": baseline_game.get("reason"),
                    "candidate_reason": game.get("reason"),
                    "baseline_turns": as_int(baseline_game.get("turns")),
                    "candidate_turns": as_int(game.get("turns")),
                    "turn_delta_607_minus_candidate": as_int(baseline_game.get("turns"))
                    - as_int(game.get("turns")),
                    "strategic_event_delta_607_minus_candidate": deltas,
                    "positive_strategic_deltas": positive_deltas,
                    "anchor_card_event_delta_607_minus_candidate": card_deltas,
                    "gap_tags": classify_comparison(baseline_game, game, deltas, card_deltas),
                }
            )
    return rows


def aggregate(rows: list[dict[str, Any]]) -> dict[str, Any]:
    candidate_counts: Counter[str] = Counter()
    opponent_counts: Counter[str] = Counter()
    gap_counts: Counter[str] = Counter()
    event_delta_totals: Counter[str] = Counter()
    card_delta_totals: Counter[str] = Counter()
    turn_deltas: list[int] = []
    for row in rows:
        candidate_counts[str(row.get("candidate_key") or "")] += 1
        opponent_counts[str(row.get("opponent") or "")] += 1
        turn_deltas.append(as_int(row.get("turn_delta_607_minus_candidate")))
        for tag in row.get("gap_tags") or []:
            gap_counts[str(tag)] += 1
        for key, value in (row.get("positive_strategic_deltas") or {}).items():
            event_delta_totals[str(key)] += as_int(value)
        for key, value in (row.get("anchor_card_event_delta_607_minus_candidate") or {}).items():
            card_delta_totals[str(key)] += as_int(value)
    return {
        "comparison_count": len(rows),
        "candidate_counts": dict(sorted(candidate_counts.items())),
        "opponent_counts": dict(sorted(opponent_counts.items())),
        "gap_counts": dict(sorted(gap_counts.items())),
        "top_strategic_deficits": [
            {"event": key, "delta_total": value}
            for key, value in event_delta_totals.most_common(10)
        ],
        "top_anchor_card_deficits": [
            {"event": key, "delta_total": value}
            for key, value in card_delta_totals.most_common(16)
        ],
        "avg_607_turn_advantage": round(sum(turn_deltas) / len(turn_deltas), 2)
        if turn_deltas
        else 0.0,
    }


def build_hypotheses(summary: Mapping[str, Any]) -> list[dict[str, Any]]:
    if as_int(summary.get("comparison_count")) <= 0:
        return []
    top_deficits = [row["event"] for row in summary.get("top_strategic_deficits") or []]
    top_cards = [row["event"] for row in summary.get("top_anchor_card_deficits") or []]
    return [
        {
            "hypothesis_key": "preserve_topdeck_miracle_floor_micro_package",
            "status": "ready_for_micro_package_model",
            "target_gap_tags": [
                "miracle_cast_deficit",
                "topdeck_activation_deficit",
                "topdeck_engine_card_deficit",
            ],
            "requirements": [
                "do not cut Sensei's Divining Top, Scroll Rack, Bender's Waterskin, or Victory Chimes",
                "predeclare miracle_cast and topdeck_manipulation_activated targets before gate",
                "candidate must not overfill hand_filter plus graveyard_recursion plus conversion lanes together",
            ],
            "evidence_events": top_deficits[:6],
            "evidence_cards": top_cards[:8],
        },
        {
            "hypothesis_key": "pressure_survival_without_engine_cuts",
            "status": "ready_for_micro_package_model",
            "target_gap_tags": [
                "candidate_died_before_closing_window",
                "candidate_lost_multiple_turns_before_607_finish",
            ],
            "requirements": [
                "repair early pressure only with cards that preserve the 607 topdeck/miracle floor",
                "Winota/Sisay/Vivi losses must be evaluated by same opponent slot before confirmation",
            ],
            "evidence_events": top_deficits[:6],
            "evidence_cards": top_cards[:8],
        },
        {
            "hypothesis_key": "approach_big_spell_conversion_preservation",
            "status": "ready_for_micro_package_model",
            "target_gap_tags": ["approach_conversion_missing", "lorehold_spell_volume_deficit"],
            "requirements": [
                "protect Approach of the Second Sun, Mizzix's Mastery, and high-impact spell volume",
                "do not treat tutor access as sufficient unless it restores spell volume and finish conversion",
            ],
            "evidence_events": top_deficits[:6],
            "evidence_cards": top_cards[:8],
        },
    ]


def mine(gate_reports: list[tuple[Path, dict[str, Any]]]) -> dict[str, Any]:
    rows: list[dict[str, Any]] = []
    for path, payload in gate_reports:
        rows.extend(mine_report(path, payload))
    rows.sort(
        key=lambda row: (
            row.get("candidate_key") or "",
            row.get("opponent") or "",
            as_int(row.get("game_index")),
            row.get("source_report") or "",
        )
    )
    summary = aggregate(rows)
    hypotheses = build_hypotheses(summary)
    recommended = (
        "build_trace_targeted_micro_package_from_closing_window"
        if hypotheses
        else "add_game_results_before_closing_window_mining"
    )
    next_steps = [
        "Use the hypothesis queue to build only a micro-package, not another broad shell.",
        "Protect 607 anchors observed in winning close windows.",
        "Predeclare target metrics before any battle gate.",
        "Reject any package that improves access but loses miracle/topdeck/spell-volume deltas.",
    ]
    return {
        "generated_at": utc_now(),
        "artifact_type": "closing_window_trace_miner",
        "protected_baseline": PROTECTED_BASELINE_KEY,
        "postgres_writes": False,
        "source_db_mutated": False,
        "gate_reports": [rel(path) for path, _payload in gate_reports],
        "closing_window_comparisons": rows,
        "hypothesis_queue": hypotheses,
        "summary": {
            **summary,
            "recommended_next_action": recommended,
            "ready_micro_package_hypothesis_count": len(hypotheses),
            "next_steps": next_steps,
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload.get("summary") or {}
    lines = [
        "# Lorehold Closing Window Trace Miner",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Protected baseline: `{payload['protected_baseline']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        f"- Recommended next action: `{summary.get('recommended_next_action')}`",
        f"- Comparison count: `{summary.get('comparison_count')}`",
        f"- Ready micro-package hypotheses: `{summary.get('ready_micro_package_hypothesis_count')}`",
        f"- Average 607 turn advantage: `{summary.get('avg_607_turn_advantage')}`",
        f"- Gap counts: `{json.dumps(summary.get('gap_counts') or {}, sort_keys=True)}`",
        "",
        "## Top Strategic Deficits",
        "",
    ]
    for row in summary.get("top_strategic_deficits") or []:
        lines.append(f"- `{row['event']}`: `{row['delta_total']}`")
    lines.extend(["", "## Top Anchor Card Deficits", ""])
    for row in summary.get("top_anchor_card_deficits") or []:
        lines.append(f"- `{row['event']}`: `{row['delta_total']}`")
    lines.extend(["", "## Hypotheses", ""])
    for row in payload.get("hypothesis_queue") or []:
        lines.append(f"### {row['hypothesis_key']}")
        lines.append("")
        lines.append(f"- Status: `{row['status']}`")
        lines.append(f"- Target gaps: `{', '.join(row.get('target_gap_tags') or [])}`")
        for requirement in row.get("requirements") or []:
            lines.append(f"- Requirement: {requirement}")
        lines.append("")
    lines.extend(["## Comparisons", ""])
    lines.append("| Candidate | Opponent | Game | 607 | Candidate | Turn delta | Gaps |")
    lines.append("| --- | --- | ---: | --- | --- | ---: | --- |")
    for row in payload.get("closing_window_comparisons") or []:
        lines.append(
            "| {candidate} | {opponent} | {game} | {b_reason} T{b_turns} | {c_reason} T{c_turns} | {delta} | {gaps} |".format(
                candidate=row.get("candidate_key") or "",
                opponent=row.get("opponent") or "",
                game=row.get("game_index"),
                b_reason=row.get("baseline_reason") or "",
                b_turns=row.get("baseline_turns"),
                c_reason=row.get("candidate_reason") or "",
                c_turns=row.get("candidate_turns"),
                delta=row.get("turn_delta_607_minus_candidate"),
                gaps=", ".join(row.get("gap_tags") or []) or "-",
            )
        )
    lines.extend(["", "## Next Steps", ""])
    for step in summary.get("next_steps") or []:
        lines.append(f"- {step}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gate-report", type=Path, action="append")
    parser.add_argument("--stem", default="lorehold_closing_window_trace_miner_20260630_current")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    gate_reports = read_existing_json(args.gate_report or DEFAULT_GATE_REPORTS)
    payload = mine(gate_reports)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
