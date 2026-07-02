#!/usr/bin/env python3
"""Summarize the Lorehold Squee graveyard-entry probe from current artifacts.

This script is read-only. It does not run battles and does not mutate any DB; it
joins the focus-access trace audit with the small runtime Squee recuts to decide
whether the next Lorehold work should be Squee sequencing or access density.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

FALLBACK_TRACE_AUDIT = REPORT_DIR / "lorehold_failure_targeted_trace_audit_20260628_v3_focus_access.json"
DEFAULT_RUNTIME_GATES = [
    REPORT_DIR / "lorehold_runtime_squee_rummage_gate_20260628_seed7_v1.json",
    REPORT_DIR / "lorehold_runtime_squee_rummage_gate_20260628_seed20260625_v1.json",
    REPORT_DIR / "lorehold_runtime_squee_rummage_gate_20260628_seed42_v1.json",
]

SQUEE_EVENTS = [
    "lorehold_rummage_discards_squee",
    "lorehold_spell_rummage_discards_squee",
    "squee_to_graveyard",
    "squee_upkeep_return",
    "squee_return_after_known_graveyard_entry",
]


def newest_report(pattern: str, fallback: Path) -> Path:
    matches = sorted(
        REPORT_DIR.glob(pattern),
        key=lambda path: (path.stat().st_mtime, path.name),
        reverse=True,
    )
    return matches[0] if matches else fallback


def default_trace_audit() -> Path:
    return newest_report(
        "lorehold_failure_targeted_trace_audit_20260630_definitive_learning_v*.json",
        FALLBACK_TRACE_AUDIT,
    )


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def int_count(row: Mapping[str, Any], key: str) -> int:
    return int(row.get(key) or 0)


def squee_discard_count(events: Mapping[str, Any]) -> int:
    return int_count(events, "lorehold_rummage_discards_squee") + int_count(
        events, "lorehold_spell_rummage_discards_squee"
    )


def event_compact(events: Mapping[str, Any]) -> dict[str, int]:
    keys = [
        "lorehold_upkeep_rummage",
        "lorehold_spell_rummage",
        "miracle_cast",
        "topdeck_manipulation_activated",
        "discard_to_top_replacement",
        *SQUEE_EVENTS,
    ]
    return {key: int_count(events, key) for key in keys if int_count(events, key)}


def squee_focus_observation(seed_record: Mapping[str, Any]) -> dict[str, Any]:
    observation = next(
        (
            row
            for row in seed_record.get("card_observations") or []
            if row.get("card_name") == "Squee, Goblin Nabob"
        ),
        {},
    )
    focus_access = observation.get("focus_access") or {}
    return {
        "evidence_level": observation.get("evidence_level") or "",
        "opening_zones": focus_access.get("opening_zones") or {},
        "early_zones": focus_access.get("early_zones") or {},
        "first_hand_or_battlefield": focus_access.get("first_hand_or_battlefield"),
        "min_library_position": focus_access.get("min_library_position"),
        "squee_trace_matches": observation.get("squee_trace_matches") or {},
    }


def trace_seed_rows(trace_audit: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for seed, record in (trace_audit.get("primary_seed_records") or {}).items():
        events = record.get("aggregate_event_counts") or {}
        squee = squee_focus_observation(record)
        rows[str(seed)] = {
            "seed": str(seed),
            "source": record.get("source") or "",
            "trace_data_level": record.get("trace_data_level") or "",
            "record": {
                "wins": int_count(record, "wins"),
                "losses": int_count(record, "losses"),
                "stalls": int_count(record, "stalls"),
                "win_rate": float(record.get("win_rate") or 0.0),
            },
            "events": event_compact(events),
            "squee_focus": squee,
            "squee_reached_hand_or_battlefield": bool(squee.get("first_hand_or_battlefield")),
            "squee_material_event_count": sum(int_count(events, key) for key in SQUEE_EVENTS),
        }
    return rows


def runtime_gate_row(path: Path) -> dict[str, Any]:
    payload = read_json(path)
    result = next(iter(payload.get("results") or []), {})
    telemetry = result.get("telemetry") or {}
    events = telemetry.get("strategic_event_counts") or {}
    return {
        "source": str(path),
        "seed": str(payload.get("simulation_seed")),
        "status": payload.get("status"),
        "python_hash_seed": payload.get("python_hash_seed"),
        "opponent_seed": payload.get("opponent_seed"),
        "games_per_opponent": payload.get("games_per_opponent"),
        "deck_process_isolation": bool(payload.get("deck_process_isolation")),
        "game_timeout_seconds": payload.get("game_timeout_seconds"),
        "deck_key": result.get("deck_key"),
        "record": {
            "wins": int_count(result, "wins"),
            "losses": int_count(result, "losses"),
            "stalls": int_count(result, "stalls"),
            "win_rate": float(result.get("win_rate") or 0.0),
        },
        "events": event_compact(events),
        "squee_discard_count": squee_discard_count(events),
        "squee_material_event_count": sum(int_count(events, key) for key in SQUEE_EVENTS),
    }


def runtime_gate_rows(paths: list[Path]) -> dict[str, dict[str, Any]]:
    rows = {}
    for path in paths:
        if path.exists():
            row = runtime_gate_row(path)
            rows[row["seed"]] = row
    return rows


def classify_probe(
    trace_rows: Mapping[str, dict[str, Any]],
    runtime_rows: Mapping[str, dict[str, Any]],
) -> dict[str, Any]:
    seed42 = runtime_rows.get("42") or {}
    seed7_trace = trace_rows.get("7") or {}
    seed20260625_trace = trace_rows.get("20260625") or {}
    modeled_when_accessed = (
        int_count(seed42.get("events") or {}, "squee_to_graveyard") > 0
        and int_count(seed42.get("events") or {}, "squee_upkeep_return") > 0
        and int(seed42.get("squee_discard_count") or 0) > 0
    )
    weak_focus_missing = [
        seed
        for seed, row in (("7", seed7_trace), ("20260625", seed20260625_trace))
        if row and not row.get("squee_reached_hand_or_battlefield")
    ]
    weak_material_missing = [
        seed
        for seed, row in (("7", seed7_trace), ("20260625", seed20260625_trace))
        if row and int(row.get("squee_material_event_count") or 0) == 0
    ]
    weak_runtime_nonwinning = [
        seed
        for seed in ("7", "20260625")
        if (runtime_rows.get(seed) or {}).get("record", {}).get("wins", 0)
        <= (runtime_rows.get(seed) or {}).get("record", {}).get("losses", 0)
    ]
    if modeled_when_accessed and weak_material_missing:
        status = "squee_route_modeled_but_access_gap_remains"
        next_action = "target_access_density_not_squee_sequencing"
    elif modeled_when_accessed:
        status = "squee_route_modeled_needs_broader_gate"
        next_action = "run_seed_window_anchor_if_package_exists"
    else:
        status = "squee_route_probe_incomplete"
        next_action = "add_or_rerun_squee_graveyard_entry_probe"
    return {
        "status": status,
        "next_action": next_action,
        "modeled_when_accessed": modeled_when_accessed,
        "weak_focus_missing_squee_access_seeds": weak_focus_missing,
        "weak_material_missing_squee_seeds": weak_material_missing,
        "weak_runtime_nonwinning_seeds": weak_runtime_nonwinning,
        "seed42_anchor_record": (seed42.get("record") or {}),
    }


def build_report(
    *,
    trace_audit: dict[str, Any],
    runtime_gate_paths: list[Path],
    trace_path: Path | None = None,
) -> dict[str, Any]:
    trace_path = trace_path or default_trace_audit()
    trace_rows = trace_seed_rows(trace_audit)
    runtime_rows = runtime_gate_rows(runtime_gate_paths)
    classification = classify_probe(trace_rows, runtime_rows)
    event_totals: Counter[str] = Counter()
    for row in runtime_rows.values():
        event_totals.update(row.get("events") or {})
    return {
        "generated_at": utc_now(),
        "trace_audit": str(trace_path),
        "runtime_gates": [str(path) for path in runtime_gate_paths],
        "postgres_writes": False,
        "source_db_mutated": False,
        "summary": {
            **classification,
            "trace_seed_count": len(trace_rows),
            "runtime_gate_count": len(runtime_rows),
            "runtime_squee_event_totals": {
                key: int(event_totals[key])
                for key in SQUEE_EVENTS
                if int(event_totals[key])
            },
        },
        "trace_seed_rows": dict(sorted(trace_rows.items())),
        "runtime_gate_rows": dict(sorted(runtime_rows.items())),
        "decision": {
            "keep_squee_runtime_model": classification["modeled_when_accessed"],
            "do_not_cut_squee_for_current_recursion_candidates": True,
            "do_not_create_squee_sequencing_swap": classification["status"]
            == "squee_route_modeled_but_access_gap_remains",
            "next_package_constraint": (
                "Any next package must increase access/conversion while preserving seed-42 "
                "Squee/miracle/topdeck telemetry."
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Squee Graveyard Entry Probe",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Trace audit: `{payload['trace_audit']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Status: `{summary['status']}`",
        f"- Next action: `{summary['next_action']}`",
        f"- Modeled when accessed: `{str(summary['modeled_when_accessed']).lower()}`",
        f"- Weak seeds missing Squee material events: `{', '.join(summary['weak_material_missing_squee_seeds']) or '-'}`",
        f"- Weak seeds missing focus access to Squee: `{', '.join(summary['weak_focus_missing_squee_access_seeds']) or '-'}`",
        f"- Seed-42 anchor record: `{summary['seed42_anchor_record']}`",
        "",
        "## Runtime Gates",
        "",
        "| Seed | Record | Squee Discards | Squee GY | Squee Return | Miracle | Topdeck |",
        "| ---: | --- | ---: | ---: | ---: | ---: | ---: |",
    ]
    for seed, row in payload["runtime_gate_rows"].items():
        events = row.get("events") or {}
        record = row.get("record") or {}
        lines.append(
            "| {seed} | `{wins}-{losses}-{stalls}` | {discard} | {gy} | {ret} | {miracle} | {topdeck} |".format(
                seed=seed,
                wins=record.get("wins", 0),
                losses=record.get("losses", 0),
                stalls=record.get("stalls", 0),
                discard=row.get("squee_discard_count", 0),
                gy=events.get("squee_to_graveyard", 0),
                ret=events.get("squee_upkeep_return", 0),
                miracle=events.get("miracle_cast", 0),
                topdeck=events.get("topdeck_manipulation_activated", 0),
            )
        )
    lines.extend(
        [
            "",
            "## Focus Trace Access",
            "",
            "| Seed | Record | Squee Reached Hand/Battlefield | Material Squee Events | Min Library Pos | Early Zones |",
            "| ---: | --- | --- | ---: | ---: | --- |",
        ]
    )
    for seed, row in payload["trace_seed_rows"].items():
        record = row.get("record") or {}
        focus = row.get("squee_focus") or {}
        lines.append(
            "| {seed} | `{wins}-{losses}-{stalls}` | `{reached}` | {events} | {pos} | `{zones}` |".format(
                seed=seed,
                wins=record.get("wins", 0),
                losses=record.get("losses", 0),
                stalls=record.get("stalls", 0),
                reached=str(row.get("squee_reached_hand_or_battlefield", False)).lower(),
                events=row.get("squee_material_event_count", 0),
                pos=focus.get("min_library_position"),
                zones=json.dumps(focus.get("early_zones") or {}, sort_keys=True),
            )
        )
    decision = payload["decision"]
    lines.extend(["", "## Decision", ""])
    for key, value in decision.items():
        lines.append(f"- `{key}`: `{value}`")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trace-audit", type=Path, default=default_trace_audit())
    parser.add_argument("--runtime-gates", type=Path, nargs="*", default=DEFAULT_RUNTIME_GATES)
    parser.add_argument("--stem", default="lorehold_squee_graveyard_entry_probe_current")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_report(
        trace_audit=read_json(args.trace_audit),
        runtime_gate_paths=list(args.runtime_gates),
        trace_path=args.trace_audit,
    )
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
