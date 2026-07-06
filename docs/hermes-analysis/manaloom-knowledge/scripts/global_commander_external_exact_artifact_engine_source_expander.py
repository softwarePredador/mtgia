#!/usr/bin/env python3
"""Expand external exact artifact-engine source lanes for Commander decks.

This read-only gate follows
``global_commander_engine_exact_replacement_or_new_cut_finder``. It queries
Scryfall for Commander-legal cards in the target color identity with exact
artifact-spell payoff or artifact type-conversion text, then emits review seeds.
It does not copy decks, mutate databases, run battles, or promote packages.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import urllib.parse
from collections import Counter
from collections.abc import Callable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT, rel
from global_commander_engine_exact_replacement_or_new_cut_finder import (
    COMMANDER_IDENTITY,
    exact_engine_signals,
    exact_replacement_status,
    parse_color_identity,
    primary_pool,
    source_db,
)
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_FINDER_REPORT = (
    REPORT_DIR / "global_commander_engine_exact_replacement_or_new_cut_finder_20260706_current.json"
)
DEFAULT_ENGINE_POLICY_REPORT = (
    REPORT_DIR / "global_commander_engine_axis_nonland_cut_policy_model_20260706_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_external_exact_artifact_engine_source_expander_20260706_current"
)
SCRYFALL_SEARCH = "https://api.scryfall.com/cards/search"
SCRYFALL_QUERIES = (
    'legal:commander id<=wbr o:"whenever you cast an artifact spell"',
    'legal:commander id<=wbr o:"artifact spells you cast"',
    'legal:commander id<=wbr o:"creatures you control are artifacts"',
    'legal:commander id<=wbr o:"creature spells you control"',
    'legal:commander id<=wbr o:"artifact spell"',
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def artifact_rel(path: Path) -> str:
    candidate = path if path.is_absolute() else REPO_ROOT / path
    try:
        return rel(candidate)
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def scryfall_url(query: str) -> str:
    return f"{SCRYFALL_SEARCH}?unique=cards&order=name&q={urllib.parse.quote(query)}"


def fetch_scryfall_cards(query: str, *, timeout: int = 45) -> dict[str, Any]:
    url = scryfall_url(query)
    completed = subprocess.run(
        ["curl", "-fsSL", url],
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    if completed.returncode != 0:
        return {
            "query": query,
            "url": url,
            "status": "fetch_failed",
            "error": (completed.stderr or completed.stdout or "")[:1000],
            "total_cards": 0,
            "cards": [],
        }
    payload = json.loads(completed.stdout)
    return {
        "query": query,
        "url": url,
        "status": "fetched",
        "total_cards": int(payload.get("total_cards") or len(payload.get("data") or [])),
        "cards": payload.get("data") or [],
    }


def current_deck_names(db_path: Path, deck_id: str) -> set[str]:
    import sqlite3

    names: set[str] = set()
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        for row in conn.execute("SELECT card_name FROM deck_cards WHERE deck_id = ?", (deck_id,)):
            names.add(normalize_name(str(row["card_name"] or "")))
    return names


def card_oracle_text(card: Mapping[str, Any]) -> str:
    faces = card.get("card_faces")
    if isinstance(faces, list):
        return "\n".join(str(face.get("oracle_text") or "") for face in faces if isinstance(face, Mapping))
    return str(card.get("oracle_text") or "")


def card_type_line(card: Mapping[str, Any]) -> str:
    faces = card.get("card_faces")
    if isinstance(faces, list):
        return " // ".join(str(face.get("type_line") or "") for face in faces if isinstance(face, Mapping))
    return str(card.get("type_line") or "")


def external_candidate_row(
    card: Mapping[str, Any],
    *,
    query: str,
    current_names: set[str],
) -> dict[str, Any] | None:
    name = str(card.get("name") or "")
    oracle = card_oracle_text(card)
    type_line = card_type_line(card)
    signals = exact_engine_signals(type_line, oracle)
    raw_status = exact_replacement_status(signals)
    if raw_status == "not_exact_engine_replacement":
        return None
    color_identity = {str(item).upper() for item in card.get("color_identity") or []}
    legality = str((card.get("legalities") or {}).get("commander") or "unknown")
    blockers = []
    if legality != "legal":
        blockers.append(f"commander_legality:{legality}")
    if not color_identity.issubset(COMMANDER_IDENTITY):
        blockers.append("outside_commander_color_identity")
    if normalize_name(name) in current_names:
        blockers.append("already_in_current_deck")
    if raw_status == "artifact_spell_support_not_biotransference_replacement":
        blockers.append("support_only_no_token_or_draw_payoff")
    ready = not blockers and raw_status in {
        "exact_type_conversion_engine_candidate",
        "exact_artifact_spell_payoff_candidate",
    }
    return {
        "card_name": name,
        "status": "external_exact_engine_candidate_ready_for_local_review" if ready else raw_status,
        "raw_exact_status": raw_status,
        "signals": signals,
        "color_identity": sorted(color_identity),
        "commander_legality": legality,
        "already_in_current_deck": normalize_name(name) in current_names,
        "source_query": query,
        "scryfall_uri": card.get("scryfall_uri"),
        "oracle_id": card.get("oracle_id"),
        "type_line": type_line,
        "oracle_excerpt": " ".join(oracle.split())[:320],
        "blockers": blockers,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "mutation_allowed": False,
    }


def build_report(
    *,
    finder_report: Path,
    engine_policy_report: Path,
    fetcher: Callable[[str], Mapping[str, Any]] = fetch_scryfall_cards,
) -> dict[str, Any]:
    finder_payload = load_json(finder_report)
    engine_payload = load_json(engine_policy_report)
    pool = primary_pool(engine_payload)
    deck_id = str(pool.get("deck_id") or "")
    commander = str(pool.get("commander") or "")
    db_path = source_db(engine_payload)
    current_names = current_deck_names(db_path, deck_id)
    query_results = [dict(fetcher(query)) for query in SCRYFALL_QUERIES]
    by_name: dict[str, dict[str, Any]] = {}
    for result in query_results:
        query = str(result.get("query") or "")
        for card in result.get("cards") or []:
            if not isinstance(card, Mapping):
                continue
            row = external_candidate_row(card, query=query, current_names=current_names)
            if row is None:
                continue
            key = normalize_name(str(row.get("card_name") or ""))
            existing = by_name.get(key)
            if existing is None:
                by_name[key] = row
            else:
                existing.setdefault("source_queries", [existing.get("source_query")])
                existing["source_queries"].append(query)
    rows = list(by_name.values())
    rows.sort(
        key=lambda row: (
            0 if row["status"] == "external_exact_engine_candidate_ready_for_local_review" else 1,
            str(row.get("card_name") or ""),
        )
    )
    status_counts = Counter(row["status"] for row in rows)
    ready = [row for row in rows if row["status"] == "external_exact_engine_candidate_ready_for_local_review"]
    fetch_failures = [row for row in query_results if row.get("status") != "fetched"]
    blockers = []
    if fetch_failures:
        blockers.append(f"scryfall_fetch_failures:{len(fetch_failures)}")
    if not ready:
        blockers.append("no_external_exact_engine_candidate_ready_for_local_review")
    blockers.append("candidate_copy_closed_after_external_exact_engine_source_expansion")
    if ready:
        status = "external_exact_artifact_engine_source_lanes_expanded_no_deck_action"
        next_gate = "review_external_exact_artifact_engine_candidates_locally_before_candidate_copy"
    else:
        status = "external_exact_artifact_engine_source_lanes_exhausted_locally"
        next_gate = "pivot_back_to_global_role_axis_or_broaden_engine_definition"
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_exact_artifact_engine_source_expander",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "finder_report": artifact_rel(finder_report),
            "engine_policy_report": artifact_rel(engine_policy_report),
            "source_db": artifact_rel(db_path),
            "finder_status": finder_payload.get("status"),
        },
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "source_query_count": len(SCRYFALL_QUERIES),
            "fetched_query_count": sum(1 for row in query_results if row.get("status") == "fetched"),
            "external_candidate_count": len(rows),
            "ready_for_local_review_count": len(ready),
            "status_counts": dict(sorted(status_counts.items())),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "source_query_rows": [
            {
                "query": row.get("query"),
                "url": row.get("url") or scryfall_url(str(row.get("query") or "")),
                "status": row.get("status"),
                "total_cards": row.get("total_cards"),
                "error": row.get("error"),
            }
            for row in query_results
        ],
        "external_candidate_rows": rows,
        "candidate_copy_blockers": blockers,
        "policy": {
            "external_source_boundary": "Scryfall Oracle search is external source-lane evidence, not deck permission.",
            "same_lane_boundary": "Candidates still need local review, current-deck trace, and exact add/cut proof before candidate copy.",
            "mutation_boundary": "This expander reads local deck membership and remote Scryfall data only.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Exact Artifact Engine Source Expander",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- source_query_count: `{summary['source_query_count']}`",
        f"- fetched_query_count: `{summary['fetched_query_count']}`",
        f"- external_candidate_count: `{summary['external_candidate_count']}`",
        f"- ready_for_local_review_count: `{summary['ready_for_local_review_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Source Queries",
        "",
        "| Query | Status | Total | URL |",
        "| --- | --- | ---: | --- |",
    ]
    for row in payload["source_query_rows"]:
        lines.append(
            f"| `{row['query']}` | `{row['status']}` | {row['total_cards']} | {row['url']} |"
        )
    lines.extend(["", "## External Candidates", ""])
    lines.extend(["| Card | Status | Signals | Color | Blockers |", "| --- | --- | --- | --- | --- |"])
    for row in payload["external_candidate_rows"]:
        lines.append(
            "| `{card}` | `{status}` | `{signals}` | `{color}` | {blockers} |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                signals=",".join(row.get("signals") or []),
                color=",".join(row.get("color_identity") or []),
                blockers=", ".join(row.get("blockers") or []) or "-",
            )
        )
    if not payload["external_candidate_rows"]:
        lines.append("| none |  |  |  |  |")
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
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
    parser.add_argument("--finder-report", type=Path, default=DEFAULT_FINDER_REPORT)
    parser.add_argument("--engine-policy-report", type=Path, default=DEFAULT_ENGINE_POLICY_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(finder_report=args.finder_report, engine_policy_report=args.engine_policy_report)
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
