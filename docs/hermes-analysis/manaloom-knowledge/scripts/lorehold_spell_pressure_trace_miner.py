#!/usr/bin/env python3
"""Mine the Lorehold spell-pressure gate for card-use learning.

The spell-pressure topdeck shell produced a small smoke lift, but that is not
card-level proof. This miner asks a narrower question: did the winning game use
the pressure cards that justified the shell, or did the protected
miracle/topdeck engine carry the win?
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

DEFAULT_GATE = REPORT_DIR / "lorehold_from_scratch_challengers_20260704_spell_pressure_topdeck_fixed607_gate.json"
DEFAULT_DECISION = REPORT_DIR / "lorehold_spell_pressure_topdeck_decision_20260704_current.json"
DEFAULT_MATRIX = REPORT_DIR / "lorehold_from_scratch_challengers_20260704_spell_pressure_topdeck_matrix.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_spell_pressure_trace_miner_20260704_current"

BASELINE_KEY = "deck_607"
CANDIDATE_KEY = "challenger_lorehold_spell_pressure_topdeck_v1"

TESTED_PRESSURE_CARDS = (
    "Guttersnipe",
    "Young Pyromancer",
    "Monastery Mentor",
)
NEXT_PRESSURE_PRIORITY_CARDS = (
    "Guttersnipe",
    "Storm-Kiln Artist",
)
CORE_CARD_NAMES = (
    "Lorehold, the Historian",
    "Scroll Rack",
    "Sensei's Divining Top",
    "Library of Leng",
    "Bender's Waterskin",
    "Victory Chimes",
    "Mizzix's Mastery",
    "Approach of the Second Sun",
    "Hit the Mother Lode",
)
CORE_STRATEGIC_EVENTS = (
    "discard_to_top_replacement",
    "lorehold_rummage_discard_to_top",
    "lorehold_spell_cast",
    "lorehold_upkeep_rummage",
    "miracle_cast",
    "topdeck_manipulation_activated",
)
PRESSURE_CONVERSION_STRATEGIC_EVENTS = (
    "spell_cast_mana_trigger",
    "birgi_spell_cast_mana",
    "thor_noncreature_damage",
    "thor_noncreature_damage_amount",
)
PRESSURE_CONVERSION_CARD_EVENT_PREFIXES = (
    "trigger_resolved",
    "spell_resolved",
    "damage_dealt",
    "noncreature_damage",
    "treasure_created",
)

EXTERNAL_LEARNING = [
    {
        "source": "EDHREC average optimized spellslinger",
        "url": "https://edhrec.com/average-decks/lorehold-the-historian/optimized/spellslinger",
        "learning": (
            "The current optimized average shows Topdeck and Spellslinger together, "
            "and includes Guttersnipe, Storm-Kiln Artist, Scroll Rack, Sensei's "
            "Divining Top, Bender's Waterskin, and Victory Chimes as one coherent shell."
        ),
    },
    {
        "source": "EDHREC Boros Miracles budget article",
        "url": "https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget",
        "learning": (
            "Lorehold wants a high instant/sorcery density to avoid miracle duds; "
            "Bender's Waterskin is specifically useful because it untaps on opposing "
            "turns for miracle costs."
        ),
    },
    {
        "source": "GameTyrant Lorehold deck tech",
        "url": "https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech",
        "learning": (
            "Pressure cards are valid only as support for the topdeck/miracle plan: "
            "Monastery Mentor and Young Pyromancer create bodies, while Guttersnipe "
            "converts spell chains into damage."
        ),
    },
    {
        "source": "Card Kingdom Lorehold synergy article",
        "url": "https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/",
        "learning": (
            "Lorehold is a cost-reducing, miracle-making rummage commander, so "
            "engine timing and resource conversion outrank generic creature pressure."
        ),
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


def gate_row(gate: Mapping[str, Any], deck_key: str) -> dict[str, Any]:
    for row in gate.get("results") or []:
        if isinstance(row, Mapping) and row.get("deck_key") == deck_key:
            return dict(row)
    return {}


def event_subset(events: Mapping[str, Any], names: tuple[str, ...]) -> dict[str, int]:
    out: dict[str, int] = {}
    for event, count in events.items():
        event_text = str(event)
        if any(f":{name}" in event_text for name in names):
            out[event_text] = as_int(count)
    return dict(sorted(out.items()))


def pressure_conversion_subset(
    card_events: Mapping[str, Any],
    strategic_events: Mapping[str, Any],
    names: tuple[str, ...],
) -> dict[str, int]:
    out: dict[str, int] = {}
    for event, count in card_events.items():
        event_text = str(event)
        if not any(f":{name}" in event_text for name in names):
            continue
        if event_text.startswith(PRESSURE_CONVERSION_CARD_EVENT_PREFIXES):
            out[event_text] = as_int(count)
    for event, count in strategic_events.items():
        event_text = str(event)
        if event_text in PRESSURE_CONVERSION_STRATEGIC_EVENTS:
            out[event_text] = as_int(count)
    return dict(sorted(out.items()))


def strategic_subset(events: Mapping[str, Any]) -> dict[str, int]:
    out: dict[str, int] = {}
    for event, count in events.items():
        if str(event) in CORE_STRATEGIC_EVENTS:
            out[str(event)] = as_int(count)
    return dict(sorted(out.items()))


def event_total(events: Mapping[str, Any]) -> int:
    return sum(as_int(count) for count in events.values())


def game_rows(deck_row: Mapping[str, Any], tested_pressure_cards: tuple[str, ...]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for game in deck_row.get("game_results") or []:
        if not isinstance(game, Mapping):
            continue
        card_events = game.get("card_event_counts") if isinstance(game.get("card_event_counts"), Mapping) else {}
        strategic_events = (
            game.get("strategic_event_counts")
            if isinstance(game.get("strategic_event_counts"), Mapping)
            else {}
        )
        pressure_events = event_subset(card_events, tested_pressure_cards)
        pressure_conversion_events = pressure_conversion_subset(
            card_events,
            strategic_events,
            tested_pressure_cards,
        )
        core_card_events = event_subset(card_events, CORE_CARD_NAMES)
        core_strategic_events = strategic_subset(strategic_events)
        rows.append(
            {
                "game_id": str(game.get("game_id") or ""),
                "opponent": str(game.get("opponent") or ""),
                "result": str(game.get("result") or ""),
                "turns": as_int(game.get("turns")),
                "reason": str(game.get("reason") or ""),
                "pressure_card_event_counts": pressure_events,
                "pressure_event_total": event_total(pressure_events),
                "pressure_conversion_event_counts": pressure_conversion_events,
                "pressure_conversion_event_total": event_total(pressure_conversion_events),
                "observed_pressure_cards": sorted(
                    {
                        card
                        for event in pressure_events
                        for card in tested_pressure_cards
                        if f":{card}" in event
                    }
                ),
                "core_card_event_counts": core_card_events,
                "core_strategic_event_counts": core_strategic_events,
                "core_event_total": event_total(core_card_events) + event_total(core_strategic_events),
            }
        )
    return rows


def count_games(rows: list[Mapping[str, Any]], *, result: str, min_pressure_events: int = 0) -> int:
    return sum(
        1
        for row in rows
        if row.get("result") == result and as_int(row.get("pressure_event_total")) > min_pressure_events
    )


def count_conversion_games(rows: list[Mapping[str, Any]], *, result: str) -> int:
    return sum(
        1
        for row in rows
        if row.get("result") == result and as_int(row.get("pressure_conversion_event_total")) > 0
    )


def pressure_cards_by_result(rows: list[Mapping[str, Any]]) -> dict[str, list[str]]:
    grouped: dict[str, set[str]] = {"win": set(), "loss": set(), "stall": set()}
    for row in rows:
        result = str(row.get("result") or "")
        grouped.setdefault(result, set()).update(str(card) for card in row.get("observed_pressure_cards") or [])
    return {result: sorted(cards) for result, cards in sorted(grouped.items()) if cards}


def find_sisay_win(rows: list[Mapping[str, Any]]) -> dict[str, Any]:
    for row in rows:
        if row.get("result") == "win" and "Sisay" in str(row.get("opponent") or ""):
            return dict(row)
    return {}


def ranked_index(matrix: Mapping[str, Any], deck_key: str) -> int | None:
    keys = [str(item) for item in matrix.get("ranked_deck_keys") or []]
    try:
        return keys.index(deck_key) + 1
    except ValueError:
        return None


def summary_rank(
    *,
    decision: Mapping[str, Any],
    matrix: Mapping[str, Any],
    deck_key: str,
    field_name: str,
) -> int | None:
    matrix_rank = ranked_index(matrix, deck_key)
    if matrix_rank:
        return matrix_rank
    summary = decision.get("summary") if isinstance(decision.get("summary"), Mapping) else {}
    value = summary.get(field_name) if isinstance(summary, Mapping) else None
    try:
        return int(value) if value is not None else None
    except Exception:
        return None


def build_payload(
    *,
    gate: Mapping[str, Any],
    decision: Mapping[str, Any],
    matrix: Mapping[str, Any],
    gate_path: Path,
    decision_path: Path,
    matrix_path: Path | None = None,
    candidate_key: str = CANDIDATE_KEY,
    baseline_key: str = BASELINE_KEY,
    tested_pressure_cards: tuple[str, ...] = TESTED_PRESSURE_CARDS,
    next_pressure_priority_cards: tuple[str, ...] = NEXT_PRESSURE_PRIORITY_CARDS,
) -> dict[str, Any]:
    decision_for_candidate = decision if candidate_key == CANDIDATE_KEY else {}
    candidate_gate = gate_row(gate, candidate_key)
    baseline_gate = gate_row(gate, baseline_key)
    rows = game_rows(candidate_gate, tested_pressure_cards)
    wins = [row for row in rows if row["result"] == "win"]
    losses = [row for row in rows if row["result"] == "loss"]
    sisay_win = find_sisay_win(rows)
    wins_with_pressure = count_games(rows, result="win")
    losses_with_pressure = count_games(rows, result="loss")
    wins_with_pressure_conversion = count_conversion_games(rows, result="win")
    losses_with_pressure_conversion = count_conversion_games(rows, result="loss")
    baseline_rank = summary_rank(
        decision=decision_for_candidate,
        matrix=matrix,
        deck_key=baseline_key,
        field_name="baseline_rank",
    )
    candidate_rank = summary_rank(
        decision=decision_for_candidate,
        matrix=matrix,
        deck_key=candidate_key,
        field_name="candidate_rank",
    )
    failure_modes: list[str] = []
    if wins and wins_with_pressure == 0:
        failure_modes.append("winning_game_has_no_pressure_card_events")
    if losses_with_pressure and wins_with_pressure == 0:
        failure_modes.append("pressure_seen_only_in_losses")
    if wins_with_pressure and wins_with_pressure_conversion == 0:
        failure_modes.append("pressure_seen_without_conversion_events")
    if sisay_win and as_int(sisay_win.get("core_event_total")) > 0:
        failure_modes.append("sisay_win_carried_by_core_topdeck_miracle_engine")
    if baseline_rank and candidate_rank and candidate_rank > baseline_rank:
        failure_modes.append("still_structurally_below_607")
    if any(row["opponent"] == "Fixed Lorehold deck 607" and row["result"] == "loss" for row in rows):
        failure_modes.append("head_to_head_lost_to_607")
    if (decision_for_candidate.get("summary") or {}).get("confirmation_allowed") is False:
        failure_modes.append("parent_decision_blocks_confirmation")
    if "winning_game_has_no_pressure_card_events" in failure_modes:
        status = "pressure_trace_refutes_pressure_causality"
    elif "pressure_seen_without_conversion_events" in failure_modes:
        status = "pressure_trace_partial_presence_not_conversion_proof"
    else:
        status = "pressure_trace_has_conversion_signal_requires_equal_gate"
    source_reports = {"battle_gate": rel(gate_path)}
    if decision_for_candidate:
        source_reports["parent_decision"] = rel(decision_path)
    if matrix_path is not None:
        source_reports["matrix"] = rel(matrix_path)
    if candidate_key == CANDIDATE_KEY:
        next_actions = [
            "do_not_confirm_current_spell_pressure_topdeck_shell",
            "treat_young_pyromancer_result_as_loss_only_sampling_not_win_proof",
            "mine_or_generate_a_storm_kiln_plus_guttersnipe_hypothesis_before_more_token_pressure",
            "require_seed_safe_same_lane_cuts_before_any_new_natural_gate",
        ]
    else:
        next_actions = [
            "do_not_confirm_current_spell_pressure_mana_conversion_shell",
            "treat_storm_kiln_cost_paid_as_exposure_not_conversion_proof",
            "repair_structural_overfill_before_larger_seed_window",
            "keep_607_protected_until_head_to_head_and_conversion_trace_pass",
        ]
    payload = {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_spell_pressure_trace_miner",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": source_reports,
        "external_learning": EXTERNAL_LEARNING,
        "status": status,
        "summary": {
            "candidate_key": candidate_key,
            "baseline_key": baseline_key,
            "baseline_rank": baseline_rank,
            "candidate_rank": candidate_rank,
            "tested_pressure_cards": list(tested_pressure_cards),
            "candidate_record": {
                "wins": as_int(candidate_gate.get("wins")),
                "losses": as_int(candidate_gate.get("losses")),
                "stalls": as_int(candidate_gate.get("stalls")),
                "games": as_int(candidate_gate.get("games")),
            },
            "baseline_record": {
                "wins": as_int(baseline_gate.get("wins")),
                "losses": as_int(baseline_gate.get("losses")),
                "stalls": as_int(baseline_gate.get("stalls")),
                "games": as_int(baseline_gate.get("games")),
            },
            "candidate_win_count": len(wins),
            "candidate_loss_count": len(losses),
            "wins_with_pressure_card_events": wins_with_pressure,
            "losses_with_pressure_card_events": losses_with_pressure,
            "wins_with_pressure_conversion_events": wins_with_pressure_conversion,
            "losses_with_pressure_conversion_events": losses_with_pressure_conversion,
            "pressure_cards_by_result": pressure_cards_by_result(rows),
            "failure_modes": sorted(set(failure_modes)),
            "promotion_allowed": False,
            "confirmation_allowed": False,
        },
        "sisay_win_trace": sisay_win,
        "candidate_games": rows,
        "deckbuilding_priority_update": {
            "protect_607_baseline": True,
            "protect_engine_cards": [
                "Bender's Waterskin",
                "Library of Leng",
                "Scroll Rack",
                "Sensei's Divining Top",
                "The Mind Stone",
                "The Scarlet Witch",
                "Victory Chimes",
            ],
            "demote_until_proven": [
                "Young Pyromancer",
                "Monastery Mentor",
            ],
            "next_pressure_priority": list(next_pressure_priority_cards),
            "reason": (
                "Pressure cards are only useful when they execute their role inside "
                "the protected Lorehold topdeck/miracle engine. A mere cost-paid or "
                "cast event is exposure, not proof of conversion; require a trigger, "
                "damage, mana-conversion, or spell-resolution signal before treating "
                "the pressure package as learned value."
            ),
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "promotion_allowed": False,
            "confirmation_allowed": False,
            "next_actions": next_actions,
        },
    }
    if status == "pressure_trace_refutes_pressure_causality":
        payload["deckbuilding_priority_update"]["reason"] = (
            "The only candidate win did not use the tested pressure creatures. "
            "It used the protected Lorehold topdeck/miracle engine, especially "
            "Scroll Rack, Sensei's Divining Top, discard-to-top replacement, "
            "Lorehold rummage, and Mizzix's Mastery. Future pressure tests "
            "should prefer mana-conversion pressure such as Storm-Kiln Artist "
            "plus Guttersnipe only if seed-safe same-lane cuts exist."
        )
    return payload


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    priority = payload["deckbuilding_priority_update"]
    lines = [
        "# Lorehold Spell Pressure Trace Miner",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- candidate_record: `{json.dumps(summary['candidate_record'], sort_keys=True)}`",
        f"- baseline_record: `{json.dumps(summary['baseline_record'], sort_keys=True)}`",
        f"- baseline_rank: `{summary['baseline_rank']}`",
        f"- candidate_rank: `{summary['candidate_rank']}`",
        f"- tested_pressure_cards: `{json.dumps(summary['tested_pressure_cards'])}`",
        f"- wins_with_pressure_card_events: `{summary['wins_with_pressure_card_events']}`",
        f"- losses_with_pressure_card_events: `{summary['losses_with_pressure_card_events']}`",
        f"- wins_with_pressure_conversion_events: `{summary['wins_with_pressure_conversion_events']}`",
        f"- losses_with_pressure_conversion_events: `{summary['losses_with_pressure_conversion_events']}`",
        f"- pressure_cards_by_result: `{json.dumps(summary['pressure_cards_by_result'], sort_keys=True)}`",
        f"- failure_modes: `{json.dumps(summary['failure_modes'])}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        f"- confirmation_allowed: `{str(summary['confirmation_allowed']).lower()}`",
        "",
        "## Sisay Win Trace",
        "",
    ]
    sisay = payload.get("sisay_win_trace") or {}
    if sisay:
        lines.extend(
            [
                f"- opponent: `{sisay.get('opponent', '')}`",
                f"- turns: `{sisay.get('turns', 0)}`",
                f"- pressure_card_event_counts: `{json.dumps(sisay.get('pressure_card_event_counts', {}), sort_keys=True)}`",
                f"- pressure_conversion_event_counts: `{json.dumps(sisay.get('pressure_conversion_event_counts', {}), sort_keys=True)}`",
                f"- core_strategic_event_counts: `{json.dumps(sisay.get('core_strategic_event_counts', {}), sort_keys=True)}`",
                f"- core_card_event_counts: `{json.dumps(sisay.get('core_card_event_counts', {}), sort_keys=True)}`",
            ]
        )
    else:
        lines.append("- no_sisay_win_trace: `true`")
    lines.extend(
        [
            "",
            "## Deckbuilding Priority Update",
            "",
            f"- protect_engine_cards: `{json.dumps(priority['protect_engine_cards'])}`",
            f"- demote_until_proven: `{json.dumps(priority['demote_until_proven'])}`",
            f"- next_pressure_priority: `{json.dumps(priority['next_pressure_priority'])}`",
            f"- reason: {priority['reason']}",
            "",
            "## External Learning",
            "",
        ]
    )
    for source in payload.get("external_learning") or []:
        lines.append(f"- {source['source']}: {source['url']}")
    lines.extend(["", "## Decision", ""])
    for action in payload["decision"]["next_actions"]:
        lines.append(f"- {action}")
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
    parser.add_argument("--gate", type=Path, default=DEFAULT_GATE)
    parser.add_argument("--decision", type=Path, default=DEFAULT_DECISION)
    parser.add_argument("--matrix", type=Path, default=DEFAULT_MATRIX)
    parser.add_argument("--candidate-key", default=CANDIDATE_KEY)
    parser.add_argument("--baseline-key", default=BASELINE_KEY)
    parser.add_argument("--tested-pressure-cards", default=",".join(TESTED_PRESSURE_CARDS))
    parser.add_argument("--next-pressure-priority-cards", default=",".join(NEXT_PRESSURE_PRIORITY_CARDS))
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    tested_pressure_cards = tuple(card.strip() for card in args.tested_pressure_cards.split(",") if card.strip())
    next_pressure_priority_cards = tuple(
        card.strip() for card in args.next_pressure_priority_cards.split(",") if card.strip()
    )
    payload = build_payload(
        gate=read_json(args.gate),
        decision=read_json(args.decision) if args.decision.exists() else {},
        matrix=read_json(args.matrix) if args.matrix.exists() else {},
        gate_path=args.gate,
        decision_path=args.decision,
        matrix_path=args.matrix if args.matrix.exists() else None,
        candidate_key=args.candidate_key,
        baseline_key=args.baseline_key,
        tested_pressure_cards=tested_pressure_cards,
        next_pressure_priority_cards=next_pressure_priority_cards,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
