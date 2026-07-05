#!/usr/bin/env python3
"""Mine protected-607 floor traces for current Lorehold trace-gap cut slots.

The trace-gap scout identifies low-exposure or floor-sensitive cards that may
look cuttable. This miner checks the opposite question before any deck build:
did protected deck 607 win same-slot games while a candidate lost and the
candidate cut slot card produced real card events for 607?

This is read-only. It does not mutate deck 607, materialize a candidate, run a
battle, or write PostgreSQL/SQLite.
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
DEFAULT_SCOUT = REPORT_DIR / "lorehold_topdeck_mana_trace_gap_scout_20260705_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_gap_floor_trace_miner_20260705_current"

CORE_STRATEGIC_EVENTS = (
    "miracle_cast",
    "topdeck_manipulation_activated",
    "discard_to_top_replacement",
    "lorehold_rummage_discard_to_top",
    "lorehold_cost_paid",
    "lorehold_spell_cast",
    "lorehold_upkeep_rummage",
    "static_cost_reduction_total",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_dict(value: Any) -> dict[str, Any]:
    return dict(value) if isinstance(value, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def default_gate_paths() -> list[Path]:
    return sorted(
        path
        for path in REPORT_DIR.glob("lorehold*.json")
        if path.is_file()
        and path.name != DEFAULT_SCOUT.name
        and not path.name.startswith(DEFAULT_OUT_PREFIX.name)
    )


def read_existing_json(paths: Iterable[Path]) -> list[tuple[Path, dict[str, Any]]]:
    loaded: list[tuple[Path, dict[str, Any]]] = []
    for path in sorted(paths):
        try:
            payload = read_json(path)
        except Exception:
            continue
        if payload:
            loaded.append((path, payload))
    return loaded


def target_gap_rows(trace_gap_scout: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in as_list(trace_gap_scout.get("trace_gap_rows")):
        if not isinstance(row, Mapping):
            continue
        if not str(row.get("gap_status") or "").startswith("unprobed"):
            continue
        rows.append(dict(row))
    rows.sort(
        key=lambda row: (
            as_int(row.get("unique_exposure_count")),
            str(row.get("card_name") or ""),
        )
    )
    return rows


def result_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [dict(row) for row in as_list(payload.get("results")) if isinstance(row, Mapping)]


def baseline_result(payload: Mapping[str, Any]) -> dict[str, Any]:
    for row in result_rows(payload):
        if row.get("deck_key") == PROTECTED_BASELINE_KEY:
            return row
    return {}


def candidate_results(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [
        row
        for row in result_rows(payload)
        if row.get("deck_key") and row.get("deck_key") != PROTECTED_BASELINE_KEY
    ]


def game_slot(game: Mapping[str, Any]) -> tuple[str, int]:
    return (str(game.get("opponent") or ""), as_int(game.get("game_index")))


def event_family(event_key: str) -> str:
    return event_key.split(":", 1)[0]


def card_event_counts(game: Mapping[str, Any], card_name: str) -> dict[str, int]:
    counts = as_dict(game.get("card_event_counts"))
    out: dict[str, int] = {}
    for key, value in counts.items():
        text = str(key)
        if card_name in text and as_int(value) > 0:
            out[text] = as_int(value)
    return dict(sorted(out.items()))


def strategic_delta(baseline_game: Mapping[str, Any], candidate_game: Mapping[str, Any]) -> dict[str, int]:
    baseline_counts = as_dict(baseline_game.get("strategic_event_counts"))
    candidate_counts = as_dict(candidate_game.get("strategic_event_counts"))
    return {
        event: as_int(baseline_counts.get(event)) - as_int(candidate_counts.get(event))
        for event in CORE_STRATEGIC_EVENTS
    }


def comparison_signature(
    *,
    payload: Mapping[str, Any],
    target_card: str,
    candidate_key: str,
    baseline_game: Mapping[str, Any],
    candidate_game: Mapping[str, Any],
) -> tuple[Any, ...]:
    return (
        target_card,
        payload.get("simulation_seed"),
        payload.get("opponent_seed"),
        candidate_key,
        baseline_game.get("opponent"),
        baseline_game.get("game_index"),
        baseline_game.get("game_id"),
        candidate_game.get("game_id"),
    )


def build_trace_rows(
    *,
    trace_gap_scout: Mapping[str, Any],
    gate_reports: list[tuple[Path, dict[str, Any]]],
) -> list[dict[str, Any]]:
    targets = target_gap_rows(trace_gap_scout)
    target_by_name = {str(row.get("card_name") or ""): row for row in targets}
    rows_by_signature: dict[tuple[Any, ...], dict[str, Any]] = {}
    for path, payload in gate_reports:
        baseline = baseline_result(payload)
        if not baseline:
            continue
        baseline_games = {
            game_slot(game): game
            for game in as_list(baseline.get("game_results"))
            if isinstance(game, Mapping)
        }
        for candidate in candidate_results(payload):
            candidate_key = str(candidate.get("deck_key") or "")
            for candidate_game in as_list(candidate.get("game_results")):
                if not isinstance(candidate_game, Mapping) or candidate_game.get("result") != "loss":
                    continue
                baseline_game = baseline_games.get(game_slot(candidate_game))
                if not baseline_game or baseline_game.get("result") != "win":
                    continue
                for target_card, target_row in target_by_name.items():
                    baseline_events = card_event_counts(baseline_game, target_card)
                    if not baseline_events:
                        continue
                    candidate_events = card_event_counts(candidate_game, target_card)
                    baseline_event_total = sum(baseline_events.values())
                    candidate_event_total = sum(candidate_events.values())
                    delta = baseline_event_total - candidate_event_total
                    signature = comparison_signature(
                        payload=payload,
                        target_card=target_card,
                        candidate_key=candidate_key,
                        baseline_game=baseline_game,
                        candidate_game=candidate_game,
                    )
                    existing = rows_by_signature.get(signature)
                    if existing:
                        existing.setdefault("source_reports", [])
                        source_reports = set(existing["source_reports"])
                        source_reports.add(rel(path))
                        existing["source_reports"] = sorted(source_reports)
                        continue
                    strategic = strategic_delta(baseline_game, candidate_game)
                    rows_by_signature[signature] = {
                        "target_card": target_card,
                        "target_gap_status": target_row.get("gap_status") or "",
                        "target_role": target_row.get("role") or "",
                        "target_unique_exposure_count": as_int(target_row.get("unique_exposure_count")),
                        "source_reports": [rel(path)],
                        "simulation_seed": payload.get("simulation_seed"),
                        "opponent_seed": payload.get("opponent_seed"),
                        "candidate_key": candidate_key,
                        "opponent": baseline_game.get("opponent"),
                        "opponent_archetype": baseline_game.get("opponent_archetype"),
                        "game_index": baseline_game.get("game_index"),
                        "baseline_game_id": baseline_game.get("game_id"),
                        "candidate_game_id": candidate_game.get("game_id"),
                        "baseline_result": baseline_game.get("result"),
                        "candidate_result": candidate_game.get("result"),
                        "baseline_reason": baseline_game.get("reason"),
                        "candidate_reason": candidate_game.get("reason"),
                        "baseline_turns": as_int(baseline_game.get("turns")),
                        "candidate_turns": as_int(candidate_game.get("turns")),
                        "turn_delta_607_minus_candidate": as_int(baseline_game.get("turns"))
                        - as_int(candidate_game.get("turns")),
                        "baseline_target_event_counts": baseline_events,
                        "candidate_target_event_counts": candidate_events,
                        "baseline_target_event_total": baseline_event_total,
                        "candidate_target_event_total": candidate_event_total,
                        "target_event_delta_607_minus_candidate": delta,
                        "target_event_delta_positive": delta > 0,
                        "strategic_event_delta_607_minus_candidate": strategic,
                        "positive_strategic_deltas": {
                            key: value for key, value in strategic.items() if value > 0
                        },
                        "floor_trace_status": (
                            "candidate_loss_positive_floor_delta"
                            if delta > 0
                            else "candidate_loss_baseline_used_target_without_positive_delta"
                        ),
                    }
    rows = list(rows_by_signature.values())
    rows.sort(
        key=lambda row: (
            str(row.get("target_card") or ""),
            str(row.get("candidate_key") or ""),
            str(row.get("opponent") or ""),
            as_int(row.get("game_index")),
            str(row.get("baseline_game_id") or ""),
        )
    )
    return rows


def aggregate_target_rows(
    *,
    target_rows: list[dict[str, Any]],
    trace_rows: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    by_target: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in trace_rows:
        by_target[str(row.get("target_card") or "")].append(row)

    summaries: list[dict[str, Any]] = []
    for target in target_rows:
        card = str(target.get("card_name") or "")
        rows = by_target.get(card, [])
        candidate_counts: Counter[str] = Counter()
        opponent_counts: Counter[str] = Counter()
        event_family_counts: Counter[str] = Counter()
        strategic_counts: Counter[str] = Counter()
        source_reports: set[str] = set()
        positive_delta_count = 0
        total_baseline_events = 0
        total_delta = 0
        for row in rows:
            candidate_counts[str(row.get("candidate_key") or "")] += 1
            opponent_counts[str(row.get("opponent") or "")] += 1
            source_reports.update(str(path) for path in as_list(row.get("source_reports")))
            total_baseline_events += as_int(row.get("baseline_target_event_total"))
            total_delta += max(0, as_int(row.get("target_event_delta_607_minus_candidate")))
            if row.get("target_event_delta_positive"):
                positive_delta_count += 1
            for key, value in as_dict(row.get("baseline_target_event_counts")).items():
                event_family_counts[event_family(str(key))] += as_int(value)
            for key, value in as_dict(row.get("positive_strategic_deltas")).items():
                strategic_counts[str(key)] += as_int(value)
        if positive_delta_count:
            floor_status = "floor_trace_found_cut_blocked"
            cut_decision = "protect_cut_slot_until_same_lane_replacement_preserves_floor"
        elif rows:
            floor_status = "baseline_win_trace_found_but_no_positive_delta"
            cut_decision = "still_not_safe_cut_requires_stronger_delta_trace"
        else:
            floor_status = "no_same_slot_floor_trace_found"
            cut_decision = "still_not_safe_cut_collect_more_targeted_trace"
        summaries.append(
            {
                "card_name": card,
                "gap_status": target.get("gap_status") or "",
                "role": target.get("role") or "",
                "unique_exposure_count": as_int(target.get("unique_exposure_count")),
                "direct_event_count": as_int(target.get("direct_event_count")),
                "floor_trace_status": floor_status,
                "cut_decision": cut_decision,
                "same_slot_607_win_candidate_loss_trace_count": len(rows),
                "positive_target_delta_trace_count": positive_delta_count,
                "baseline_target_event_total": total_baseline_events,
                "positive_target_event_delta_total": total_delta,
                "source_report_count": len(source_reports),
                "candidate_counts": dict(sorted(candidate_counts.items())),
                "opponent_counts": dict(sorted(opponent_counts.items())),
                "target_event_family_counts": dict(sorted(event_family_counts.items())),
                "top_positive_strategic_deltas": [
                    {"event": key, "delta_total": value}
                    for key, value in strategic_counts.most_common(8)
                ],
                "example_traces": sorted(
                    rows,
                    key=lambda row: (
                        -as_int(row.get("target_event_delta_607_minus_candidate")),
                        -as_int(row.get("baseline_target_event_total")),
                        str(row.get("candidate_key") or ""),
                    ),
                )[:8],
            }
        )
    summaries.sort(
        key=lambda row: (
            0 if row["floor_trace_status"] == "floor_trace_found_cut_blocked" else 1,
            as_int(row.get("unique_exposure_count")),
            str(row.get("card_name")),
        )
    )
    return summaries


def missing_inputs(
    *,
    trace_gap_scout: Mapping[str, Any],
    gate_reports: list[tuple[Path, dict[str, Any]]],
) -> list[str]:
    missing: list[str] = []
    if not trace_gap_scout:
        missing.append("trace_gap_scout")
    if not gate_reports:
        missing.append("gate_reports")
    return missing


def build_report(
    *,
    trace_gap_scout: Mapping[str, Any],
    gate_reports: list[tuple[Path, dict[str, Any]]],
    scout_path: Path,
) -> dict[str, Any]:
    missing = missing_inputs(trace_gap_scout=trace_gap_scout, gate_reports=gate_reports)
    targets = [] if missing else target_gap_rows(trace_gap_scout)
    traces = [] if missing else build_trace_rows(
        trace_gap_scout=trace_gap_scout,
        gate_reports=gate_reports,
    )
    target_summaries = aggregate_target_rows(target_rows=targets, trace_rows=traces) if targets else []
    floor_trace_found_count = sum(
        1 for row in target_summaries if row.get("floor_trace_status") == "floor_trace_found_cut_blocked"
    )
    if missing:
        status = "gap_floor_trace_miner_inputs_missing_keep_607"
        next_action = "rerun_missing_gap_floor_trace_inputs"
    elif floor_trace_found_count:
        status = "gap_floor_trace_miner_found_floor_evidence_keep_607"
        next_action = "feed_floor_trace_blockers_back_into_cut_models_before_structure_matrix"
    else:
        status = "gap_floor_trace_miner_no_floor_trace_found_keep_607"
        next_action = "collect_more_targeted_replay_or_battle_trace_before_structure_matrix"
    scanned_game_report_count = sum(
        1
        for _path, payload in gate_reports
        if any(as_list(row.get("game_results")) for row in result_rows(payload))
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_gap_floor_trace_miner",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": PROTECTED_BASELINE_KEY,
        "status": status,
        "source_reports": {
            "trace_gap_scout": rel(scout_path),
        },
        "summary": {
            "decision_status": status,
            "missing_inputs": missing,
            "scanned_gate_report_count": len(gate_reports),
            "scanned_game_result_report_count": scanned_game_report_count,
            "target_card_count": len(targets),
            "target_with_floor_trace_count": floor_trace_found_count,
            "same_slot_607_win_candidate_loss_trace_count": len(traces),
            "positive_target_delta_trace_count": sum(
                1 for row in traces if row.get("target_event_delta_positive")
            ),
            "structure_matrix_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "recommended_next_action": next_action,
        },
        "target_floor_summaries": target_summaries,
        "floor_trace_rows": traces,
        "source_evidence": {
            "trace_gap_scout_summary": summary(trace_gap_scout),
            "gate_report_sample": [rel(path) for path, _payload in gate_reports[:20]],
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "structure_matrix_allowed_now": False,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "At least one unprobed gap card has same-slot evidence where protected "
                "607 won, a candidate lost, and the gap card produced real 607 events. "
                "These rows become cut blockers, not candidate materialization rows."
            )
            if floor_trace_found_count
            else (
                "No same-slot floor trace was found for the current unprobed gap cards; "
                "the gap remains unresolved and no structure matrix can open."
            ),
            "next_actions": [
                next_action,
                "do_not_mutate_deck_607",
                "do_not_treat_low_exposure_as_cut_safety",
                "do_not_materialize_candidate_deck_from_floor_trace_rows",
                "require same-lane replacement trace before any structure matrix row",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = summary(payload)
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Gap Floor Trace Miner",
        "",
        f"- Generated at: `{payload.get('generated_at')}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload.get('status')}`",
        f"- Scanned gate reports: `{summary_row.get('scanned_gate_report_count')}`",
        f"- Scanned game-result reports: `{summary_row.get('scanned_game_result_report_count')}`",
        f"- Target cards: `{summary_row.get('target_card_count')}`",
        f"- Targets with floor trace: `{summary_row.get('target_with_floor_trace_count')}`",
        "- Same-slot 607-win/candidate-loss traces: "
        f"`{summary_row.get('same_slot_607_win_candidate_loss_trace_count')}`",
        f"- Positive target-delta traces: `{summary_row.get('positive_target_delta_trace_count')}`",
        f"- Structure matrix allowed now: `{str(summary_row.get('structure_matrix_allowed_now')).lower()}`",
        "- Candidate deck materialization allowed now: "
        f"`{str(summary_row.get('candidate_deck_materialization_allowed_now')).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary_row.get('natural_battle_gate_allowed_now')).lower()}`",
        f"- Promotion allowed now: `{str(summary_row.get('promotion_allowed_now')).lower()}`",
        f"- Recommended next action: `{summary_row.get('recommended_next_action')}`",
        "",
        "## Target Floor Summaries",
        "",
        "| Card | Status | Traces | Positive Delta | Event Total | Sources | Decision |",
        "| --- | --- | ---: | ---: | ---: | ---: | --- |",
    ]
    for row in as_list(payload.get("target_floor_summaries")):
        if not isinstance(row, Mapping):
            continue
        lines.append(
            "| {card} | `{status}` | {traces} | {positive} | {events} | {sources} | `{decision}` |".format(
                card=row.get("card_name") or "",
                status=row.get("floor_trace_status") or "",
                traces=row.get("same_slot_607_win_candidate_loss_trace_count") or 0,
                positive=row.get("positive_target_delta_trace_count") or 0,
                events=row.get("baseline_target_event_total") or 0,
                sources=row.get("source_report_count") or 0,
                decision=row.get("cut_decision") or "",
            )
        )
    lines.extend(["", "## Example Traces", ""])
    for target in as_list(payload.get("target_floor_summaries")):
        if not isinstance(target, Mapping):
            continue
        lines.append(f"### {target.get('card_name')}")
        examples = as_list(target.get("example_traces"))[:3]
        if not examples:
            lines.append("")
            lines.append("- No same-slot floor trace found.")
            lines.append("")
            continue
        lines.append("")
        for row in examples:
            lines.append(
                "- `{candidate}` lost to `{opponent}` game `{game}` while 607 won; "
                "target delta `{delta}`, 607 events `{events}`, source `{source}`.".format(
                    candidate=row.get("candidate_key") or "",
                    opponent=row.get("opponent") or "",
                    game=row.get("game_index"),
                    delta=row.get("target_event_delta_607_minus_candidate"),
                    events=json.dumps(row.get("baseline_target_event_counts") or {}, sort_keys=True),
                    source=(as_list(row.get("source_reports")) or [""])[0],
                )
            )
        lines.append("")
    lines.extend(["## Decision", ""])
    lines.append(
        f"- keep_607_as_protected_baseline: `{str(decision.get('keep_607_as_protected_baseline')).lower()}`"
    )
    lines.append(f"- deck_action_allowed: `{str(decision.get('deck_action_allowed')).lower()}`")
    lines.append(
        "- candidate_deck_materialization_allowed_now: "
        f"`{str(decision.get('candidate_deck_materialization_allowed_now')).lower()}`"
    )
    lines.append(f"- forced_access_allowed_now: `{str(decision.get('forced_access_allowed_now')).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision.get('natural_battle_allowed_now')).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision.get('promotion_allowed')).lower()}`")
    lines.append(f"- reason: {decision.get('reason')}")
    lines.append("- next_actions:")
    for action in as_list(decision.get("next_actions")):
        lines.append(f"  - {action}")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trace-gap-scout", type=Path, default=DEFAULT_SCOUT)
    parser.add_argument("--gate-report", type=Path, action="append", default=None)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    gate_paths = args.gate_report if args.gate_report else default_gate_paths()
    payload = build_report(
        trace_gap_scout=read_json(args.trace_gap_scout),
        gate_reports=read_existing_json(gate_paths),
        scout_path=args.trace_gap_scout,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "target_card_count": payload["summary"]["target_card_count"],
                "target_with_floor_trace_count": payload["summary"]["target_with_floor_trace_count"],
                "json": rel(json_path),
                "markdown": rel(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
