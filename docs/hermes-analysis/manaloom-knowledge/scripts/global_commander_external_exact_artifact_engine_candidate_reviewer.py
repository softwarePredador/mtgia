#!/usr/bin/env python3
"""Review external exact artifact-engine candidates against local Hermes data.

This read-only gate follows
``global_commander_external_exact_artifact_engine_source_expander``. External
Scryfall rows can seed learning, but candidate copy requires local identity,
Oracle text, Commander legality, current-deck absence, and exact engine signals.
This script does not mutate SQLite, copy decks, run battles, or promote cards.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT, rel
from global_commander_engine_exact_replacement_or_new_cut_finder import (
    COMMANDER_IDENTITY,
    exact_engine_signals,
    exact_replacement_status,
    parse_color_identity,
)
from master_optimizer_common import normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_EXPANDER_REPORT = (
    REPORT_DIR / "global_commander_external_exact_artifact_engine_source_expander_20260706_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_external_exact_artifact_engine_candidate_reviewer_20260706_current"
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def artifact_rel(path: Path) -> str:
    candidate = path if path.is_absolute() else REPO_ROOT / path
    try:
        return rel(candidate)
    except ValueError:
        return str(path)


def resolve_repo_path(raw: object, *, default: Path) -> Path:
    value = str(raw or "").strip()
    if not value:
        return default
    path = Path(value)
    return path if path.is_absolute() else REPO_ROOT / path


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def local_card_row(conn: sqlite3.Connection, name: str) -> sqlite3.Row | None:
    key = normalize_name(name)
    return conn.execute(
        "SELECT name, color_identity_json, type_line, oracle_text, scryfall_id "
        "FROM card_oracle_cache "
        "WHERE lower(name) = lower(?) OR normalized_name = ? "
        "ORDER BY CASE WHEN lower(name) = lower(?) THEN 0 ELSE 1 END "
        "LIMIT 1",
        (name, key, name),
    ).fetchone()


def local_commander_legality(conn: sqlite3.Connection, name: str) -> str:
    row = conn.execute(
        "SELECT status FROM card_legalities "
        "WHERE lower(format) = 'commander' AND lower(card_name) = lower(?) "
        "LIMIT 1",
        (name,),
    ).fetchone()
    return str(row["status"] or "") if row else ""


def in_current_deck(conn: sqlite3.Connection, *, deck_id: str, name: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM deck_cards WHERE deck_id = ? AND lower(card_name) = lower(?) LIMIT 1",
        (deck_id, name),
    ).fetchone()
    return bool(row)


def review_candidate(
    conn: sqlite3.Connection,
    row: Mapping[str, Any],
    *,
    deck_id: str,
) -> dict[str, Any]:
    name = str(row.get("card_name") or "")
    input_status = str(row.get("status") or "")
    blockers: list[str] = []
    if input_status != "external_exact_engine_candidate_ready_for_local_review":
        blockers.append(f"external_status_not_ready_for_local_review:{input_status}")

    local = local_card_row(conn, name)
    local_status = "missing_local_oracle_cache"
    local_signals: list[str] = []
    local_color_identity: list[str] = []
    local_type_line = ""
    local_oracle_excerpt = ""
    local_scryfall_id = ""
    if local is None:
        blockers.append("missing_local_oracle_cache")
    else:
        local_type_line = str(local["type_line"] or "")
        local_oracle = str(local["oracle_text"] or "")
        local_oracle_excerpt = " ".join(local_oracle.split())[:320]
        local_scryfall_id = str(local["scryfall_id"] or "")
        local_signals = exact_engine_signals(local_type_line, local_oracle)
        local_status = exact_replacement_status(local_signals)
        local_color_identity = sorted(parse_color_identity(local["color_identity_json"]))
        if local_status not in {
            "exact_type_conversion_engine_candidate",
            "exact_artifact_spell_payoff_candidate",
        }:
            blockers.append(f"local_oracle_not_exact_engine_candidate:{local_status}")
        if not set(local_color_identity).issubset(COMMANDER_IDENTITY):
            blockers.append("outside_commander_color_identity")

    legality = local_commander_legality(conn, name) or str(row.get("commander_legality") or "")
    if not legality:
        blockers.append("missing_local_commander_legality")
    elif legality != "legal":
        blockers.append(f"commander_legality:{legality}")

    already_in_deck = in_current_deck(conn, deck_id=deck_id, name=name)
    if already_in_deck:
        blockers.append("already_in_current_deck")

    ready = not blockers and input_status == "external_exact_engine_candidate_ready_for_local_review"
    return {
        "card_name": name,
        "status": (
            "local_external_exact_engine_candidate_ready_for_add_cut_review"
            if ready
            else "external_exact_engine_candidate_local_review_blocked"
        ),
        "external_status": input_status,
        "external_raw_exact_status": row.get("raw_exact_status"),
        "external_signals": row.get("signals") or [],
        "local_exact_status": local_status,
        "local_signals": local_signals,
        "local_oracle_present": local is not None,
        "local_commander_legality": legality or None,
        "already_in_current_deck": already_in_deck,
        "local_color_identity": local_color_identity,
        "external_color_identity": row.get("color_identity") or [],
        "local_scryfall_id": local_scryfall_id or None,
        "external_oracle_id": row.get("oracle_id"),
        "external_scryfall_uri": row.get("scryfall_uri"),
        "local_type_line": local_type_line,
        "local_oracle_excerpt": local_oracle_excerpt,
        "external_oracle_excerpt": row.get("oracle_excerpt"),
        "blockers": blockers,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "mutation_allowed": False,
    }


def build_report(*, expander_report: Path = DEFAULT_EXPANDER_REPORT) -> dict[str, Any]:
    expander_payload = load_json(expander_report)
    summary = expander_payload.get("summary") or {}
    deck_id = str(summary.get("deck_id") or "")
    commander = str(summary.get("commander") or "")
    source_db = resolve_repo_path(
        (expander_payload.get("input_artifacts") or {}).get("source_db"),
        default=SCRIPT_DIR / "knowledge.db",
    )
    external_rows = [
        row
        for row in expander_payload.get("external_candidate_rows") or []
        if isinstance(row, Mapping)
    ]
    with sqlite3.connect(source_db) as conn:
        conn.row_factory = sqlite3.Row
        reviewed_rows = [review_candidate(conn, row, deck_id=deck_id) for row in external_rows]

    ready_rows = [
        row
        for row in reviewed_rows
        if row["status"] == "local_external_exact_engine_candidate_ready_for_add_cut_review"
    ]
    external_ready_rows = [
        row
        for row in reviewed_rows
        if row["external_status"] == "external_exact_engine_candidate_ready_for_local_review"
    ]
    missing_local_oracle = [row for row in external_ready_rows if "missing_local_oracle_cache" in row["blockers"]]
    status_counts = Counter(row["status"] for row in reviewed_rows)
    blocker_counts = Counter(blocker for row in reviewed_rows for blocker in row["blockers"])
    if ready_rows:
        status = "external_exact_artifact_engine_candidate_review_ready_for_add_cut_model"
        next_gate = "model_external_exact_artifact_engine_add_cut_pairs_before_candidate_copy"
    else:
        status = "external_exact_artifact_engine_candidate_review_blocks_candidate_copy"
        next_gate = "backfill_local_oracle_cache_for_external_exact_engine_seeds_before_add_cut_review"

    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_exact_artifact_engine_candidate_reviewer",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "mutation_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "expander_report": artifact_rel(expander_report),
            "expander_status": expander_payload.get("status"),
            "source_db": artifact_rel(source_db),
        },
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "external_candidate_count": len(external_rows),
            "external_ready_input_count": len(external_ready_rows),
            "reviewed_candidate_count": len(reviewed_rows),
            "local_review_ready_count": len(ready_rows),
            "missing_local_oracle_count": len(missing_local_oracle),
            "status_counts": dict(sorted(status_counts.items())),
            "blocker_counts": dict(sorted(blocker_counts.items())),
            "next_gate": next_gate,
        },
        "reviewed_candidate_rows": reviewed_rows,
        "policy": {
            "external_boundary": "External source rows are learning seeds until local Oracle and legality agree.",
            "candidate_copy_boundary": "Candidate copy remains closed until local review produces exact add/cut pairs.",
            "missing_local_oracle_boundary": "Missing local Oracle rows require a cache backfill gate, not manual deck insertion.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Exact Artifact Engine Candidate Reviewer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- external_candidate_count: `{summary['external_candidate_count']}`",
        f"- external_ready_input_count: `{summary['external_ready_input_count']}`",
        f"- local_review_ready_count: `{summary['local_review_ready_count']}`",
        f"- missing_local_oracle_count: `{summary['missing_local_oracle_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Reviewed Candidates",
        "",
        "| Card | Status | Local Oracle | Local Status | Legality | Blockers |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for row in payload["reviewed_candidate_rows"]:
        lines.append(
            "| `{card}` | `{status}` | `{oracle}` | `{local}` | `{legality}` | {blockers} |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                oracle=str(row.get("local_oracle_present")).lower(),
                local=row.get("local_exact_status"),
                legality=row.get("local_commander_legality") or "",
                blockers=", ".join(row.get("blockers") or []) or "-",
            )
        )
    if not payload["reviewed_candidate_rows"]:
        lines.append("| none |  |  |  |  |  |")
    lines.extend(["", "## Blocker Counts", ""])
    for blocker, count in summary["blocker_counts"].items():
        lines.append(f"- `{blocker}`: `{count}`")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--expander-report", type=Path, default=DEFAULT_EXPANDER_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(expander_report=args.expander_report)
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "summary": payload["summary"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
