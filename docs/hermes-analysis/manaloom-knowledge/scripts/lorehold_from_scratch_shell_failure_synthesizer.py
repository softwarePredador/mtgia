#!/usr/bin/env python3
"""Synthesize failed Lorehold from-scratch shell evidence.

This helper is read-only. It turns current from-scratch challenger gates into
machine-readable learning constraints so the planner does not keep routing back
to broad shell attempts after the same failure mode has already been tested.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
PROTECTED_BASELINE_KEY = "deck_607"

DEFAULT_FROM_SCRATCH_CHALLENGER_REPORTS = [
    REPORT_DIR / "lorehold_from_scratch_challengers_20260630_goal_definitive_learning_v1.json",
    REPORT_DIR / "lorehold_from_scratch_challengers_20260630_goal_pressure_repair_v1.json",
    REPORT_DIR / "lorehold_from_scratch_challengers_20260630_goal_pressure_conversion_v1.json",
    REPORT_DIR / "lorehold_from_scratch_challengers_20260630_access_density_control_v1.json",
]
DEFAULT_FROM_SCRATCH_GATE_REPORTS = [
    REPORT_DIR
    / "lorehold_from_scratch_challengers_20260630_goal_definitive_learning_v1_recursion_discard_engine_confirm8x3.json",
    REPORT_DIR
    / "lorehold_from_scratch_challengers_20260630_goal_pressure_repair_v1_recursion_discard_pressure_repair_confirm8x3_sources_v3.json",
    REPORT_DIR
    / "lorehold_from_scratch_challengers_20260630_goal_pressure_conversion_v1_miracle_pressure_conversion_fixed607_gate_summary.json",
    REPORT_DIR
    / "lorehold_from_scratch_challengers_20260630_access_density_control_v1_access_density_control_fixed607_gate.json",
    REPORT_DIR
    / "lorehold_from_scratch_challengers_20260630_access_density_control_v1_access_density_control_forced_tutors_pipe_opening_gate.json",
]

STRATEGIC_KEYS = (
    "miracle_cast",
    "topdeck_manipulation_activated",
    "lorehold_cost_paid",
    "lorehold_spell_cast",
    "lorehold_upkeep_rummage",
    "discard_to_top_replacement",
    "lorehold_rummage_discard_to_top",
    "lorehold_rummage_discards_squee",
    "squee_to_graveyard",
    "squee_upkeep_return",
    "static_cost_reduction_total",
    "birgi_spell_cast_mana",
    "spell_cast_mana_trigger",
)
KEY_PACKAGE_CARDS = (
    "Aetherflux Reservoir",
    "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
    "Boros Charm",
    "Enlightened Tutor",
    "Faithless Looting",
    "Gamble",
    "Squee, Goblin Nabob",
    "Underworld Breach",
    "Wheel of Fortune",
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


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


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


def strategic_games(row: Mapping[str, Any]) -> Mapping[str, Any]:
    telemetry = row.get("telemetry") if isinstance(row.get("telemetry"), Mapping) else {}
    games = telemetry.get("strategic_games") if isinstance(telemetry, Mapping) else {}
    return games if isinstance(games, Mapping) else {}


def strategic_game_count(row: Mapping[str, Any], key: str) -> int:
    value = strategic_games(row).get(key)
    if isinstance(value, Mapping):
        return as_int(value.get("games"))
    return 0


def record_from_result(row: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "deck_key": row.get("deck_key"),
        "wins": as_int(row.get("wins")),
        "losses": as_int(row.get("losses")),
        "stalls": as_int(row.get("stalls")),
        "games": as_int(row.get("games")),
        "win_rate": as_float(row.get("win_rate")),
    }


def package_card_events(row: Mapping[str, Any]) -> dict[str, dict[str, int]]:
    telemetry = row.get("telemetry") if isinstance(row.get("telemetry"), Mapping) else {}
    counts = telemetry.get("card_event_counts") if isinstance(telemetry, Mapping) else {}
    counts = counts if isinstance(counts, Mapping) else {}
    out: dict[str, dict[str, int]] = {}
    for card in KEY_PACKAGE_CARDS:
        events = {
            str(event).split(":", 1)[0]: as_int(count)
            for event, count in counts.items()
            if f":{card}" in str(event)
        }
        if events:
            out[card] = dict(sorted(events.items()))
    return out


def candidate_definitions(
    reports: list[tuple[Path, dict[str, Any]]],
) -> dict[str, dict[str, Any]]:
    definitions: dict[str, dict[str, Any]] = {}
    for path, payload in reports:
        rows = payload.get("candidates")
        if not isinstance(rows, list):
            rows = [payload]
        for row in rows:
            if not isinstance(row, Mapping) or not row.get("candidate_key"):
                continue
            ranges = (
                (row.get("commander_intent_alignment") or {}).get("package_ranges")
                if isinstance(row.get("commander_intent_alignment"), Mapping)
                else {}
            )
            ranges = ranges if isinstance(ranges, Mapping) else {}
            overfilled = [
                lane
                for lane, data in ranges.items()
                if isinstance(data, Mapping) and str(data.get("status")) == "overfilled"
            ]
            definitions[str(row["candidate_key"])] = {
                "source_report": rel(path),
                "candidate_key": row.get("candidate_key"),
                "candidate_name": row.get("candidate_name"),
                "plan_key": row.get("plan_key"),
                "required_cards": row.get("required_cards") or [],
                "missing_required_cards": row.get("missing_required_cards") or [],
                "strategy_package_counts": row.get("strategy_package_counts") or {},
                "overfilled_lanes": sorted(overfilled),
                "land_quantity": row.get("land_quantity"),
                "quantity_total": row.get("quantity_total"),
            }
    return definitions


def classify_gate_row(
    *,
    gate_path: Path,
    payload: Mapping[str, Any],
    baseline: Mapping[str, Any],
    candidate: Mapping[str, Any],
    definition: Mapping[str, Any] | None,
) -> dict[str, Any]:
    forced_mode = str(
        payload.get("forced_access_mode")
        or candidate.get("forced_access_mode")
        or baseline.get("forced_access_mode")
        or "none"
    )
    candidate_key = str(candidate.get("deck_key") or "")
    baseline_record = record_from_result(baseline)
    candidate_record = record_from_result(candidate)
    delta_wins = candidate_record["wins"] - baseline_record["wins"]
    delta_losses = candidate_record["losses"] - baseline_record["losses"]
    gate_kind = "forced_access_diagnostic" if forced_mode != "none" else "natural_gate"
    if gate_kind == "natural_gate" and candidate_record["games"] < 24:
        gate_kind = "natural_smoke_gate"

    metric_deltas = {
        key: strategic_game_count(candidate, key) - strategic_game_count(baseline, key)
        for key in STRATEGIC_KEYS
    }
    failures: list[str] = []
    if delta_wins < 0:
        failures.append("wins_below_protected_607")
    if delta_losses > 0:
        failures.append("losses_above_protected_607")
    if forced_mode != "none" and delta_wins < 0:
        failures.append("forced_access_no_conversion")
    if metric_deltas["miracle_cast"] < 0:
        failures.append("miracle_floor_regressed")
    if metric_deltas["topdeck_manipulation_activated"] < 0:
        failures.append("topdeck_floor_regressed")
    if metric_deltas["lorehold_spell_cast"] < 0:
        failures.append("lorehold_spell_floor_regressed")
    if metric_deltas["lorehold_upkeep_rummage"] < 0:
        failures.append("upkeep_rummage_floor_regressed")
    if (
        strategic_game_count(candidate, "squee_to_graveyard") > 0
        and strategic_game_count(candidate, "squee_upkeep_return") == 0
    ):
        failures.append("squee_graveyard_entry_not_converting")
    if (
        strategic_game_count(candidate, "squee_upkeep_return") > 0
        and delta_wins < 0
    ):
        failures.append("positive_squee_telemetry_not_converting")
    if definition and definition.get("overfilled_lanes"):
        failures.append("package_lanes_overfilled")

    package_events = package_card_events(candidate)
    if not package_events and gate_kind != "forced_access_diagnostic":
        failures.append("new_package_cards_not_observed")

    if gate_kind == "forced_access_diagnostic":
        status = "forced_access_rejected" if delta_wins < 0 else "forced_access_signal_only"
    elif delta_wins >= 0:
        status = "natural_non_negative_signal"
    else:
        status = "natural_rejected"

    return {
        "source_report": rel(gate_path),
        "gate_kind": gate_kind,
        "forced_access_mode": forced_mode,
        "candidate_key": candidate_key,
        "candidate_name": (definition or {}).get("candidate_name"),
        "baseline": baseline_record,
        "candidate": candidate_record,
        "delta_wins": delta_wins,
        "delta_losses": delta_losses,
        "metric_deltas": metric_deltas,
        "baseline_metric_games": {
            key: strategic_game_count(baseline, key) for key in STRATEGIC_KEYS
        },
        "candidate_metric_games": {
            key: strategic_game_count(candidate, key) for key in STRATEGIC_KEYS
        },
        "package_card_events": package_events,
        "overfilled_lanes": list((definition or {}).get("overfilled_lanes") or []),
        "required_package_cards_observed": sorted(package_events),
        "status": status,
        "failure_modes": sorted(set(failures)),
        "can_promote_from_gate": status == "natural_non_negative_signal" and gate_kind == "natural_gate",
    }


def synthesize(
    *,
    challenger_reports: list[tuple[Path, dict[str, Any]]],
    gate_reports: list[tuple[Path, dict[str, Any]]],
) -> dict[str, Any]:
    definitions = candidate_definitions(challenger_reports)
    gate_rows: list[dict[str, Any]] = []
    for path, payload in gate_reports:
        results = [row for row in payload.get("results") or [] if isinstance(row, Mapping)]
        baseline = next(
            (row for row in results if row.get("deck_key") == PROTECTED_BASELINE_KEY),
            None,
        )
        if not baseline:
            continue
        for row in results:
            if row.get("deck_key") in {None, "", PROTECTED_BASELINE_KEY}:
                continue
            candidate_key = str(row.get("deck_key") or "")
            gate_rows.append(
                classify_gate_row(
                    gate_path=path,
                    payload=payload,
                    baseline=baseline,
                    candidate=row,
                    definition=definitions.get(candidate_key),
                )
            )

    gate_rows.sort(
        key=lambda row: (
            -as_int(row.get("delta_wins")),
            row.get("gate_kind") or "",
            row.get("candidate_key") or "",
            row.get("source_report") or "",
        )
    )
    unique_candidates = sorted({str(row["candidate_key"]) for row in gate_rows})
    status_counts = Counter(str(row.get("status") or "") for row in gate_rows)
    failure_counts = Counter(
        failure for row in gate_rows for failure in row.get("failure_modes") or []
    )
    natural_rows = [row for row in gate_rows if str(row.get("gate_kind", "")).startswith("natural")]
    forced_rows = [row for row in gate_rows if row.get("gate_kind") == "forced_access_diagnostic"]
    promotable_rows = [row for row in gate_rows if row.get("can_promote_from_gate")]
    best_natural_delta = max((as_int(row.get("delta_wins")) for row in natural_rows), default=None)
    best_forced_delta = max((as_int(row.get("delta_wins")) for row in forced_rows), default=None)

    if promotable_rows:
        recommended = "confirm_non_negative_from_scratch_shell_signal"
        can_run_next_gate = True
        blockers: list[str] = [
            "non-negative shell signal is still shell-level, not individual-card promotion proof",
            "confirmation must use protected 607 and the same opponent/seed contract",
        ]
    else:
        recommended = "mine_closing_window_trace_before_next_shell"
        can_run_next_gate = False
        blockers = [
            "all current from-scratch shells are below protected 607",
            "forced tutor/access evidence still failed to convert into wins",
            "broad shell changes overfill package lanes or regress miracle/topdeck cadence",
            "another battle gate without a predeclared trace target would repeat prior work",
        ]

    constraints = [
        {
            "constraint_key": "protected_607_remains_baseline",
            "requirement": "Do not replace deck_607 unless a natural equal gate ties or beats it.",
        },
        {
            "constraint_key": "forced_access_is_diagnostic_only",
            "requirement": "Forced access can prove a card was seen/used, but cannot promote a deck.",
        },
        {
            "constraint_key": "preserve_miracle_topdeck_floor",
            "requirement": "Next shell must predeclare miracle/topdeck targets and avoid regressing the 607 cadence.",
        },
        {
            "constraint_key": "avoid_overfilled_access_recursion_shells",
            "requirement": "Do not add tutors, recursion, hand filter, and conversion density at once without lane balance.",
        },
        {
            "constraint_key": "require_conversion_window_trace",
            "requirement": "Next candidate must target a named closing-window failure and prove the added cards were naturally accessed or exercised by focused test.",
        },
    ]
    next_requirements = {
        "can_run_next_battle_gate": can_run_next_gate,
        "recommended_next_action": recommended,
        "required_before_next_shell": [
            "mine 607 win traces versus candidate loss traces for closing-window sequence differences",
            "name the exact lane or pressure failure being repaired",
            "predeclare target metrics for miracle games, topdeck manipulation games, and conversion-card access",
            "keep forced-access diagnostics separate from natural promotion evidence",
            "block exact shell reruns unless the deck list or runtime model materially changes",
        ],
    }
    return {
        "generated_at": utc_now(),
        "artifact_type": "from_scratch_shell_failure_synthesis",
        "protected_baseline": PROTECTED_BASELINE_KEY,
        "postgres_writes": False,
        "source_db_mutated": False,
        "challenger_reports": [rel(path) for path, _payload in challenger_reports],
        "gate_reports": [rel(path) for path, _payload in gate_reports],
        "candidate_definitions": definitions,
        "shell_gate_rows": gate_rows,
        "learning_constraints": constraints,
        "next_hypothesis_requirements": next_requirements,
        "summary": {
            "tested_shell_count": len(unique_candidates),
            "tested_shell_keys": unique_candidates,
            "gate_report_count": len(gate_reports),
            "shell_gate_row_count": len(gate_rows),
            "natural_gate_row_count": len(natural_rows),
            "forced_gate_row_count": len(forced_rows),
            "promotable_shell_signal_count": len(promotable_rows),
            "status_counts": dict(sorted(status_counts.items())),
            "failure_mode_counts": dict(sorted(failure_counts.items())),
            "best_natural_delta_wins": best_natural_delta,
            "best_forced_delta_wins": best_forced_delta,
            "can_run_next_battle_gate": can_run_next_gate,
            "recommended_next_action": recommended,
            "blockers": blockers,
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    lines = [
        "# Lorehold From-Scratch Shell Failure Synthesis",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Protected baseline: `{payload['protected_baseline']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        f"- Recommended next action: `{payload['summary']['recommended_next_action']}`",
        f"- Can run next battle gate: `{str(payload['summary']['can_run_next_battle_gate']).lower()}`",
        f"- Tested shells: `{', '.join(payload['summary']['tested_shell_keys']) or '-'}`",
        f"- Gate rows: `{payload['summary']['shell_gate_row_count']}`",
        f"- Status counts: `{json.dumps(payload['summary']['status_counts'], sort_keys=True)}`",
        f"- Failure mode counts: `{json.dumps(payload['summary']['failure_mode_counts'], sort_keys=True)}`",
        "",
        "## Blockers",
        "",
    ]
    for blocker in payload["summary"].get("blockers") or []:
        lines.append(f"- {blocker}")
    lines.extend(["", "## Gate Rows", ""])
    lines.append("| Candidate | Gate | Forced | Record | 607 Record | Delta W | Failures |")
    lines.append("| --- | --- | --- | --- | --- | ---: | --- |")
    for row in payload.get("shell_gate_rows") or []:
        candidate = row.get("candidate") or {}
        baseline = row.get("baseline") or {}
        lines.append(
            "| {candidate_key} | {gate} | {forced} | {cw}/{cl}/{cs} | {bw}/{bl}/{bs} | {delta} | {failures} |".format(
                candidate_key=row.get("candidate_key") or "",
                gate=row.get("gate_kind") or "",
                forced=row.get("forced_access_mode") or "none",
                cw=candidate.get("wins", 0),
                cl=candidate.get("losses", 0),
                cs=candidate.get("stalls", 0),
                bw=baseline.get("wins", 0),
                bl=baseline.get("losses", 0),
                bs=baseline.get("stalls", 0),
                delta=row.get("delta_wins", 0),
                failures=", ".join(row.get("failure_modes") or []) or "-",
            )
        )
    lines.extend(["", "## Learning Constraints", ""])
    for row in payload.get("learning_constraints") or []:
        lines.append(f"- `{row['constraint_key']}`: {row['requirement']}")
    lines.extend(["", "## Required Before Next Shell", ""])
    for item in (payload.get("next_hypothesis_requirements") or {}).get(
        "required_before_next_shell"
    ) or []:
        lines.append(f"- {item}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--from-scratch-report", type=Path, action="append")
    parser.add_argument("--from-scratch-gate-report", type=Path, action="append")
    parser.add_argument(
        "--stem",
        default="lorehold_from_scratch_shell_failure_synthesis_20260630_current",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    challenger_reports = read_existing_json(
        args.from_scratch_report or DEFAULT_FROM_SCRATCH_CHALLENGER_REPORTS
    )
    gate_reports = read_existing_json(
        args.from_scratch_gate_report or DEFAULT_FROM_SCRATCH_GATE_REPORTS
    )
    payload = synthesize(
        challenger_reports=challenger_reports,
        gate_reports=gate_reports,
    )
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
