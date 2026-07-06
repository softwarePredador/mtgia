#!/usr/bin/env python3
"""Expand exact artifact type-conversion source lane before cutting Biotransference.

This read-only gate follows the add/cut pair model. It searches live Scryfall
for Commander-legal, color-identity-compatible cards that explicitly make
creatures or creature spells into artifacts. If no outside-deck exact converter
exists, Biotransference remains protected and candidate copy stays closed.
"""

from __future__ import annotations

import argparse
import json
import subprocess
from collections import Counter
from collections.abc import Callable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT, rel
from global_commander_engine_exact_replacement_or_new_cut_finder import (
    COMMANDER_IDENTITY,
    exact_engine_signals,
)
from global_commander_external_exact_artifact_engine_source_expander import (
    current_deck_names,
    scryfall_url,
)
from master_optimizer_common import normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_PAIR_MODEL_REPORT = (
    REPORT_DIR / "global_commander_external_exact_artifact_engine_add_cut_pair_model_20260706_current.json"
)
DEFAULT_CANDIDATE_REVIEWER_REPORT = (
    REPORT_DIR / "global_commander_external_exact_artifact_engine_candidate_reviewer_20260706_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_exact_artifact_type_conversion_source_lane_expander_20260706_current"
)
SCRYFALL_TYPE_CONVERSION_QUERIES = (
    'legal:commander id<=wbr o:"creatures you control are artifacts"',
    'legal:commander id<=wbr o:"creature spells you control are artifacts"',
    'legal:commander id<=wbr o:"creature cards you own" o:"are artifacts"',
    'legal:commander id<=wbr o:"artifacts in addition to their other types" o:"creatures you control"',
    'legal:commander id<=wbr o:"are artifacts in addition to their other types"',
)


def fetch_scryfall_cards_allow_empty(query: str, *, timeout: int = 45) -> dict[str, Any]:
    url = scryfall_url(query)
    completed = subprocess.run(
        ["curl", "-sSL", url],
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
    if payload.get("object") == "error" and payload.get("code") == "not_found":
        return {
            "query": query,
            "url": url,
            "status": "fetched",
            "total_cards": 0,
            "cards": [],
        }
    return {
        "query": query,
        "url": url,
        "status": "fetched",
        "total_cards": int(payload.get("total_cards") or len(payload.get("data") or [])),
        "cards": payload.get("data") or [],
    }


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


def source_db_from_reports(
    pair_payload: Mapping[str, Any],
    candidate_payload: Mapping[str, Any],
) -> Path:
    raw = (pair_payload.get("input_artifacts") or {}).get("source_db") or (
        candidate_payload.get("input_artifacts") or {}
    ).get("source_db")
    return resolve_repo_path(raw, default=SCRIPT_DIR / "knowledge.db")


def deck_id_from_reports(
    pair_payload: Mapping[str, Any],
    candidate_payload: Mapping[str, Any],
) -> str:
    summary = candidate_payload.get("summary") or {}
    if summary.get("deck_id"):
        return str(summary.get("deck_id"))
    return "619"


def source_candidate_row(
    card: Mapping[str, Any],
    *,
    query: str,
    current_names: set[str],
) -> dict[str, Any] | None:
    name = str(card.get("name") or "")
    oracle = card_oracle_text(card)
    type_line = card_type_line(card)
    signals = exact_engine_signals(type_line, oracle)
    if "artifact_type_conversion_engine" not in signals:
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
    ready = not blockers
    return {
        "card_name": name,
        "status": (
            "exact_artifact_type_conversion_source_ready_for_add_cut_model"
            if ready
            else "exact_artifact_type_conversion_source_blocked"
        ),
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
    pair_model_report: Path = DEFAULT_PAIR_MODEL_REPORT,
    candidate_reviewer_report: Path = DEFAULT_CANDIDATE_REVIEWER_REPORT,
    fetcher: Callable[[str], Mapping[str, Any]] = fetch_scryfall_cards_allow_empty,
) -> dict[str, Any]:
    pair_payload = load_json(pair_model_report)
    candidate_payload = load_json(candidate_reviewer_report)
    source_db = source_db_from_reports(pair_payload, candidate_payload)
    deck_id = deck_id_from_reports(pair_payload, candidate_payload)
    current_names = current_deck_names(source_db, deck_id)
    query_results = [dict(fetcher(query)) for query in SCRYFALL_TYPE_CONVERSION_QUERIES]
    by_name: dict[str, dict[str, Any]] = {}
    for result in query_results:
        query = str(result.get("query") or "")
        for card in result.get("cards") or []:
            if not isinstance(card, Mapping):
                continue
            row = source_candidate_row(card, query=query, current_names=current_names)
            if row is None:
                continue
            key = normalize_name(str(row.get("card_name") or ""))
            by_name.setdefault(key, row)
    rows = list(by_name.values())
    rows.sort(key=lambda row: (0 if row["status"].endswith("_ready_for_add_cut_model") else 1, row["card_name"]))
    ready_rows = [
        row for row in rows if row["status"] == "exact_artifact_type_conversion_source_ready_for_add_cut_model"
    ]
    status_counts = Counter(row["status"] for row in rows)
    blocker_counts = Counter(blocker for row in rows for blocker in row.get("blockers") or [])
    fetch_failures = [row for row in query_results if row.get("status") != "fetched"]
    if ready_rows:
        status = "exact_artifact_type_conversion_source_lane_ready_for_add_cut_model"
        next_gate = "model_type_conversion_add_cut_pairs_before_candidate_copy"
    else:
        status = "exact_artifact_type_conversion_source_lane_exhausted_keep_biotransference_protected"
        next_gate = "protect_biotransference_and_pivot_to_non_biotransference_engine_cut_or_global_axis"
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_exact_artifact_type_conversion_source_lane_expander",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_rows_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "pair_model_report": artifact_rel(pair_model_report),
            "candidate_reviewer_report": artifact_rel(candidate_reviewer_report),
            "source_db": artifact_rel(source_db),
        },
        "summary": {
            "deck_id": deck_id,
            "source_query_count": len(SCRYFALL_TYPE_CONVERSION_QUERIES),
            "fetched_query_count": sum(1 for row in query_results if row.get("status") == "fetched"),
            "fetch_failure_count": len(fetch_failures),
            "type_conversion_candidate_count": len(rows),
            "ready_type_conversion_candidate_count": len(ready_rows),
            "status_counts": dict(sorted(status_counts.items())),
            "blocker_counts": dict(sorted(blocker_counts.items())),
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
        "source_candidate_rows": rows,
        "policy": {
            "type_conversion_boundary": "Biotransference cannot be cut unless another legal outside-deck card covers artifact type conversion.",
            "candidate_copy_boundary": "Source expansion never opens candidate copy directly.",
            "battle_boundary": "No battle probe is useful while no add/cut pair can preserve exact same-lane signals.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Exact Artifact Type Conversion Source Lane Expander",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- source_query_count: `{summary['source_query_count']}`",
        f"- fetched_query_count: `{summary['fetched_query_count']}`",
        f"- type_conversion_candidate_count: `{summary['type_conversion_candidate_count']}`",
        f"- ready_type_conversion_candidate_count: `{summary['ready_type_conversion_candidate_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Source Candidates",
        "",
        "| Card | Status | Signals | Color | Blockers |",
        "| --- | --- | --- | --- | --- |",
    ]
    for row in payload["source_candidate_rows"]:
        lines.append(
            "| `{card}` | `{status}` | `{signals}` | `{color}` | {blockers} |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                signals=",".join(row.get("signals") or []),
                color=",".join(row.get("color_identity") or []),
                blockers=", ".join(row.get("blockers") or []) or "-",
            )
        )
    if not payload["source_candidate_rows"]:
        lines.append("| none |  |  |  |  |")
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
    parser.add_argument("--pair-model-report", type=Path, default=DEFAULT_PAIR_MODEL_REPORT)
    parser.add_argument("--candidate-reviewer-report", type=Path, default=DEFAULT_CANDIDATE_REVIEWER_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        pair_model_report=args.pair_model_report,
        candidate_reviewer_report=args.candidate_reviewer_report,
    )
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
