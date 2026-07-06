#!/usr/bin/env python3
"""Audit a larger global Commander battle gate against protected baseline rules."""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_GATE_REPORT = (
    REPORT_DIR / "global_commander_larger_equal_battle_gate_20260706_lorehold_profile_repair_vs607_v2.json"
)
DEFAULT_STRATEGY_REPORT = (
    REPORT_DIR / "global_commander_candidate_package_strategy_matrix_20260706_lorehold_profile_repair_package.json"
)
DEFAULT_NATURAL_REPLAY_REPORT = (
    REPORT_DIR / "global_commander_candidate_added_card_natural_replay_trace_generator_20260706_lorehold_profile_repair_package.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_larger_battle_gate_audit_20260706_lorehold_profile_repair_vs607"
)
DEFAULT_CANDIDATE_KEY = "candidate_profile_repair_package"
DEFAULT_PROTECTED_BASELINE_KEY = "deck_607"
DEFAULT_IMMEDIATE_BASE_KEY = "deck_612"
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


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def resolve_path(path: Path | str) -> Path:
    value = Path(path)
    return value if value.is_absolute() else REPO_ROOT / value


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def result_by_key(gate: Mapping[str, Any], key: str) -> dict[str, Any]:
    for row in gate.get("results") or []:
        if isinstance(row, Mapping) and str(row.get("deck_key") or "") == key:
            return dict(row)
    return {}


def win_summary(row: Mapping[str, Any]) -> dict[str, Any]:
    construction_report = (
        row.get("construction_report") if isinstance(row.get("construction_report"), Mapping) else {}
    )
    return {
        "deck_key": row.get("deck_key"),
        "deck_name": row.get("deck_name"),
        "archetype": row.get("archetype"),
        "games": int(row.get("games") or 0),
        "wins": int(row.get("wins") or 0),
        "losses": int(row.get("losses") or 0),
        "stalls": int(row.get("stalls") or 0),
        "win_rate": float(row.get("win_rate") or 0.0),
        "avg_win_turn": float(row.get("avg_win_turn") or 0.0),
        "construction_valid": construction_validity(row),
        "deck_shape": construction_report.get("deck_shape") or {},
        "opponents": row.get("opponents") or [],
    }


def construction_validity(row: Mapping[str, Any]) -> bool | None:
    if "construction_valid" in row:
        return bool(row.get("construction_valid"))
    construction_report = (
        row.get("construction_report") if isinstance(row.get("construction_report"), Mapping) else {}
    )
    if "is_valid" in construction_report:
        return bool(construction_report.get("is_valid"))
    return None


def compare(candidate: Mapping[str, Any], other: Mapping[str, Any]) -> dict[str, Any]:
    candidate_wins = int(candidate.get("wins") or 0)
    other_wins = int(other.get("wins") or 0)
    candidate_wr = float(candidate.get("win_rate") or 0.0)
    other_wr = float(other.get("win_rate") or 0.0)
    return {
        "candidate_wins": candidate_wins,
        "other_wins": other_wins,
        "win_delta": candidate_wins - other_wins,
        "candidate_win_rate": candidate_wr,
        "other_win_rate": other_wr,
        "win_rate_delta": round(candidate_wr - other_wr, 2),
        "candidate_beats_other": candidate_wins > other_wins,
    }


def card_event_counts(row: Mapping[str, Any], card: str) -> dict[str, int]:
    telemetry = row.get("telemetry") if isinstance(row.get("telemetry"), Mapping) else {}
    counts = telemetry.get("card_event_counts") if isinstance(telemetry.get("card_event_counts"), Mapping) else {}
    result: dict[str, int] = {}
    suffix = f":{card}"
    for key, count in counts.items():
        key = str(key)
        if not key.endswith(suffix):
            continue
        event = key[: -len(suffix)]
        if event in EXERCISE_EVENT_NAMES:
            result[event] = result.get(event, 0) + int(count or 0)
    return result


def focus_summary(row: Mapping[str, Any], card: str) -> dict[str, Any]:
    telemetry = row.get("telemetry") if isinstance(row.get("telemetry"), Mapping) else {}
    summary = (
        telemetry.get("focus_card_access_summary")
        if isinstance(telemetry.get("focus_card_access_summary"), Mapping)
        else {}
    )
    value = summary.get(card)
    return dict(value) if isinstance(value, Mapping) else {}


def added_card_rows(candidate: Mapping[str, Any], added_cards: list[str]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for card in added_cards:
        events = card_event_counts(candidate, card)
        focus = focus_summary(candidate, card)
        exercise_count = sum(events.values())
        accessed_games = int(focus.get("accessed_games") or 0)
        drawn_games = int(focus.get("drawn_games") or 0)
        if exercise_count > 0:
            status = "larger_gate_added_card_exercised"
        elif accessed_games > 0 or drawn_games > 0:
            status = "larger_gate_added_card_accessed_without_exercise"
        else:
            status = "larger_gate_added_card_unseen_or_unaccessed"
        rows.append(
            {
                "card_name": card,
                "status": status,
                "exercise_event_count": exercise_count,
                "exercise_events": events,
                "accessed_games": accessed_games,
                "drawn_games": drawn_games,
                "near_access_games": int(focus.get("near_access_games") or 0),
                "opening_hand_games": int(focus.get("opening_hand_games") or 0),
                "trace_games": int(focus.get("trace_games") or 0),
                "zone_counts": focus.get("zone_counts") or {},
            }
        )
    return rows


def build_report(
    *,
    gate_report: Path,
    strategy_report: Path,
    natural_replay_report: Path,
    candidate_key: str,
    protected_baseline_key: str,
    immediate_base_key: str,
) -> dict[str, Any]:
    gate_report = resolve_path(gate_report)
    strategy_report = resolve_path(strategy_report)
    natural_replay_report = resolve_path(natural_replay_report)
    gate = load_json(gate_report)
    strategy = load_json(strategy_report)
    natural = load_json(natural_replay_report) if natural_replay_report.exists() else {}
    strategy_summary = strategy.get("summary") or {}
    added_cards = [str(card) for card in strategy_summary.get("package_adds") or []]
    candidate = result_by_key(gate, candidate_key)
    protected = result_by_key(gate, protected_baseline_key)
    immediate = result_by_key(gate, immediate_base_key)
    blockers: list[str] = []
    if not candidate:
        blockers.append(f"candidate_result_missing:{candidate_key}")
    if not protected:
        blockers.append(f"protected_baseline_missing:{protected_baseline_key}")
    if not immediate:
        blockers.append(f"immediate_base_missing:{immediate_base_key}")
    for key, row in (
        ("candidate", candidate),
        ("protected_baseline", protected),
        ("immediate_base", immediate),
    ):
        if row and construction_validity(row) is False:
            blockers.append(f"{key}_construction_invalid")
    if gate.get("forced_access_mode") != "none":
        blockers.append(f"forced_access_mode_not_none:{gate.get('forced_access_mode')}")
    if int(gate.get("games_per_opponent") or 0) < 3 or len(gate.get("opponents") or []) < 8:
        blockers.append("larger_gate_sample_too_small")

    protected_comparison = compare(candidate, protected) if candidate and protected else {}
    immediate_comparison = compare(candidate, immediate) if candidate and immediate else {}
    if protected_comparison and not protected_comparison["candidate_beats_other"]:
        blockers.append("candidate_did_not_beat_protected_baseline")

    card_rows = added_card_rows(candidate, added_cards) if candidate else []
    unexercised = [
        row["card_name"]
        for row in card_rows
        if int(row["exercise_event_count"] or 0) == 0
    ]
    if unexercised:
        blockers.append("larger_gate_unexercised_added_cards:" + ",".join(unexercised))

    if blockers:
        status = "larger_battle_gate_blocks_promotion"
        next_gate = "repair_package_or_convert_to_global_learning_no_promotion"
    else:
        status = "larger_battle_gate_candidate_beats_protected_baseline"
        next_gate = "run_final_promotion_review"

    return {
        "generated_at": utc_now(),
        "artifact_type": "global_commander_larger_battle_gate_audit",
        "status": status,
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "promotion_allowed": False if blockers else True,
        "deck_mutation_allowed": False,
        "input_artifacts": {
            "gate_report": rel(gate_report),
            "strategy_report": rel(strategy_report),
            "natural_replay_report": rel(natural_replay_report),
        },
        "summary": {
            "candidate_key": candidate_key,
            "protected_baseline_key": protected_baseline_key,
            "immediate_base_key": immediate_base_key,
            "commander": strategy_summary.get("commander"),
            "deck_id": strategy_summary.get("deck_id"),
            "games_per_opponent": gate.get("games_per_opponent"),
            "opponent_count": len(gate.get("opponents") or []),
            "forced_access_mode": gate.get("forced_access_mode"),
            "candidate_vs_protected": protected_comparison,
            "candidate_vs_immediate_base": immediate_comparison,
            "natural_replay_status": natural.get("status"),
            "natural_replay_larger_gate_allowed_next": natural.get("larger_battle_gate_allowed_next"),
            "added_card_count": len(added_cards),
            "larger_gate_exercised_added_cards": [
                row["card_name"] for row in card_rows if row["exercise_event_count"] > 0
            ],
            "larger_gate_unexercised_added_cards": unexercised,
            "next_gate": next_gate,
        },
        "blockers": blockers,
        "results": {
            "candidate": win_summary(candidate),
            "protected_baseline": win_summary(protected),
            "immediate_base": win_summary(immediate),
        },
        "added_card_review_rows": card_rows,
        "global_learning": [
            "A package can repair a weaker base shell and still fail protected-baseline replacement.",
            "Natural replay access is necessary but not sufficient; the larger gate must also beat the protected baseline.",
            "Added cards without larger-gate exercise remain learning evidence, not promotion evidence.",
        ],
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    candidate = payload["results"]["candidate"]
    protected = payload["results"]["protected_baseline"]
    immediate = payload["results"]["immediate_base"]
    lines = [
        "# Global Commander Larger Battle Gate Audit",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary.get('commander')}`",
        f"- candidate_key: `{summary['candidate_key']}`",
        f"- protected_baseline_key: `{summary['protected_baseline_key']}`",
        f"- immediate_base_key: `{summary['immediate_base_key']}`",
        f"- games_per_opponent: `{summary['games_per_opponent']}`",
        f"- opponent_count: `{summary['opponent_count']}`",
        f"- forced_access_mode: `{summary['forced_access_mode']}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Result",
        "",
        f"- protected baseline: `{protected.get('wins')}W/{protected.get('losses')}L/{protected.get('stalls')}S`, WR `{protected.get('win_rate')}`",
        f"- immediate base: `{immediate.get('wins')}W/{immediate.get('losses')}L/{immediate.get('stalls')}S`, WR `{immediate.get('win_rate')}`",
        f"- candidate: `{candidate.get('wins')}W/{candidate.get('losses')}L/{candidate.get('stalls')}S`, WR `{candidate.get('win_rate')}`",
        f"- candidate_vs_protected_win_delta: `{summary['candidate_vs_protected'].get('win_delta')}`",
        f"- candidate_vs_immediate_base_win_delta: `{summary['candidate_vs_immediate_base'].get('win_delta')}`",
        "",
        "## Added Cards",
        "",
        "| Card | Status | Exercise | Accessed Games | Drawn Games | Events |",
        "| --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in payload["added_card_review_rows"]:
        lines.append(
            "| `{card}` | `{status}` | {exercise} | {accessed} | {drawn} | `{events}` |".format(
                card=row["card_name"],
                status=row["status"],
                exercise=row["exercise_event_count"],
                accessed=row["accessed_games"],
                drawn=row["drawn_games"],
                events=row["exercise_events"],
            )
        )
    lines.extend(["", "## Blockers", ""])
    if payload["blockers"]:
        lines.extend(f"- `{blocker}`" for blocker in payload["blockers"])
    else:
        lines.append("- none")
    lines.extend(["", "## Global Learning", ""])
    lines.extend(f"- {item}" for item in payload["global_learning"])
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix = resolve_path(out_prefix)
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gate-report", type=Path, default=DEFAULT_GATE_REPORT)
    parser.add_argument("--strategy-report", type=Path, default=DEFAULT_STRATEGY_REPORT)
    parser.add_argument("--natural-replay-report", type=Path, default=DEFAULT_NATURAL_REPLAY_REPORT)
    parser.add_argument("--candidate-key", default=DEFAULT_CANDIDATE_KEY)
    parser.add_argument("--protected-baseline-key", default=DEFAULT_PROTECTED_BASELINE_KEY)
    parser.add_argument("--immediate-base-key", default=DEFAULT_IMMEDIATE_BASE_KEY)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        gate_report=args.gate_report,
        strategy_report=args.strategy_report,
        natural_replay_report=args.natural_replay_report,
        candidate_key=args.candidate_key,
        protected_baseline_key=args.protected_baseline_key,
        immediate_base_key=args.immediate_base_key,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "promotion_allowed": payload["promotion_allowed"],
                "blockers": payload["blockers"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
