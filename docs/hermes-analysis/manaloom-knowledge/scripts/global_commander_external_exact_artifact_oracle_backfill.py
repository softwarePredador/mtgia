#!/usr/bin/env python3
"""Backfill local Oracle cache rows for reviewed external artifact-engine seeds.

This gate follows
``global_commander_external_exact_artifact_engine_candidate_reviewer``. It can
populate missing local Hermes `card_oracle_cache` rows from live Scryfall for
external exact artifact-engine seeds that were already reviewed as Commander
legal and absent from the current deck. It does not alter deck rows, run
battles, promote cards, or write PostgreSQL.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
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
)
from master_optimizer_common import normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_REVIEWER_REPORT = (
    REPORT_DIR / "global_commander_external_exact_artifact_engine_candidate_reviewer_20260706_current.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_external_exact_artifact_oracle_backfill_20260706_current"
)
SCRYFALL_NAMED = "https://api.scryfall.com/cards/named"
BACKFILL_SOURCE = "scryfall_external_exact_artifact_engine_backfill"


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


def scryfall_named_url(name: str) -> str:
    return f"{SCRYFALL_NAMED}?exact={urllib.parse.quote(name)}"


def fetch_scryfall_named(name: str, *, timeout: int = 45) -> dict[str, Any]:
    url = scryfall_named_url(name)
    completed = subprocess.run(
        ["curl", "-fsSL", url],
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    if completed.returncode != 0:
        return {
            "name": name,
            "url": url,
            "status": "fetch_failed",
            "error": (completed.stderr or completed.stdout or "")[:1000],
        }
    payload = json.loads(completed.stdout)
    payload["fetch_status"] = "fetched"
    payload["fetch_url"] = url
    return payload


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


def first_face_value(card: Mapping[str, Any], key: str) -> Any:
    if card.get(key) not in (None, ""):
        return card.get(key)
    faces = card.get("card_faces")
    if isinstance(faces, list):
        for face in faces:
            if isinstance(face, Mapping) and face.get(key) not in (None, ""):
                return face.get(key)
    return None


def candidate_names(reviewer_payload: Mapping[str, Any]) -> list[str]:
    names = []
    for row in reviewer_payload.get("reviewed_candidate_rows") or []:
        if not isinstance(row, Mapping):
            continue
        blockers = set(str(blocker) for blocker in row.get("blockers") or [])
        if (
            row.get("external_status") == "external_exact_engine_candidate_ready_for_local_review"
            and "missing_local_oracle_cache" in blockers
            and "already_in_current_deck" not in blockers
        ):
            names.append(str(row.get("card_name") or ""))
    return sorted({name for name in names if name})


def local_oracle_exists(conn: sqlite3.Connection, name: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM card_oracle_cache WHERE normalized_name = ? OR lower(name) = lower(?) LIMIT 1",
        (normalize_name(name), name),
    ).fetchone()
    return bool(row)


def backfill_row_from_card(card: Mapping[str, Any], *, fetched_name: str) -> tuple[dict[str, Any], list[str]]:
    name = str(card.get("name") or fetched_name)
    oracle_text = card_oracle_text(card)
    type_line = card_type_line(card)
    signals = exact_engine_signals(type_line, oracle_text)
    exact_status = exact_replacement_status(signals)
    color_identity = {str(item).upper() for item in card.get("color_identity") or []}
    legality = str((card.get("legalities") or {}).get("commander") or "unknown")
    blockers = []
    if legality != "legal":
        blockers.append(f"commander_legality:{legality}")
    if not color_identity.issubset(COMMANDER_IDENTITY):
        blockers.append("outside_commander_color_identity")
    if exact_status not in {
        "exact_type_conversion_engine_candidate",
        "exact_artifact_spell_payoff_candidate",
    }:
        blockers.append(f"scryfall_oracle_not_exact_engine_candidate:{exact_status}")
    row = {
        "normalized_name": normalize_name(name),
        "name": name,
        "mana_cost": first_face_value(card, "mana_cost"),
        "colors_json": json.dumps(card.get("colors") or [], sort_keys=True),
        "color_identity_json": json.dumps(sorted(color_identity), sort_keys=True),
        "type_line": type_line,
        "oracle_text": oracle_text,
        "cmc": card.get("cmc"),
        "power": first_face_value(card, "power"),
        "toughness": first_face_value(card, "toughness"),
        "keywords_json": json.dumps(card.get("keywords") or [], sort_keys=True),
        "scryfall_id": card.get("id"),
        "source": BACKFILL_SOURCE,
        "updated_at": utc_now(),
        "card_id": None,
        "commander_legality": legality,
        "signals": signals,
        "exact_status": exact_status,
        "blockers": blockers,
        "scryfall_uri": card.get("scryfall_uri"),
        "fetch_url": card.get("fetch_url"),
    }
    return row, blockers


def insert_backfill_row(conn: sqlite3.Connection, row: Mapping[str, Any]) -> None:
    conn.execute(
        """
        INSERT INTO card_oracle_cache(
          normalized_name, name, mana_cost, colors_json, color_identity_json,
          type_line, oracle_text, cmc, power, toughness, keywords_json,
          scryfall_id, source, updated_at, card_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            row["normalized_name"],
            row["name"],
            row["mana_cost"],
            row["colors_json"],
            row["color_identity_json"],
            row["type_line"],
            row["oracle_text"],
            row["cmc"],
            row["power"],
            row["toughness"],
            row["keywords_json"],
            row["scryfall_id"],
            row["source"],
            row["updated_at"],
            row["card_id"],
        ),
    )
    conn.execute(
        """
        INSERT INTO card_legalities(card_name, format, status, scryfall_id, synced_at)
        VALUES (?, 'commander', ?, ?, ?)
        ON CONFLICT(card_name, format) DO UPDATE SET
          status = excluded.status,
          scryfall_id = coalesce(card_legalities.scryfall_id, excluded.scryfall_id),
          synced_at = excluded.synced_at
        """,
        (row["name"], row["commander_legality"], row["scryfall_id"], row["updated_at"]),
    )


def build_report(
    *,
    reviewer_report: Path = DEFAULT_REVIEWER_REPORT,
    apply: bool = False,
    fetcher: Callable[[str], Mapping[str, Any]] = fetch_scryfall_named,
) -> dict[str, Any]:
    reviewer_payload = load_json(reviewer_report)
    source_db = resolve_repo_path(
        (reviewer_payload.get("input_artifacts") or {}).get("source_db"),
        default=SCRIPT_DIR / "knowledge.db",
    )
    names = candidate_names(reviewer_payload)
    rows = []
    inserted = 0
    with sqlite3.connect(source_db) as conn:
        conn.row_factory = sqlite3.Row
        for name in names:
            row: dict[str, Any] = {
                "card_name": name,
                "status": "not_started",
                "blockers": [],
                "applied": False,
            }
            if local_oracle_exists(conn, name):
                row["status"] = "local_oracle_already_present"
                row["blockers"] = ["local_oracle_already_present"]
                rows.append(row)
                continue
            fetched = dict(fetcher(name))
            if fetched.get("fetch_status") != "fetched" and fetched.get("object") == "error":
                row.update(
                    {
                        "status": "scryfall_fetch_failed",
                        "fetch_url": fetched.get("fetch_url") or scryfall_named_url(name),
                        "error": fetched.get("details") or fetched.get("error"),
                        "blockers": ["scryfall_fetch_failed"],
                    }
                )
                rows.append(row)
                continue
            if fetched.get("status") == "fetch_failed":
                row.update(
                    {
                        "status": "scryfall_fetch_failed",
                        "fetch_url": fetched.get("url") or scryfall_named_url(name),
                        "error": fetched.get("error"),
                        "blockers": ["scryfall_fetch_failed"],
                    }
                )
                rows.append(row)
                continue
            backfill, blockers = backfill_row_from_card(fetched, fetched_name=name)
            row.update(
                {
                    "status": "backfill_ready" if not blockers else "backfill_blocked",
                    "scryfall_name": backfill["name"],
                    "scryfall_id": backfill["scryfall_id"],
                    "scryfall_uri": backfill["scryfall_uri"],
                    "fetch_url": backfill["fetch_url"],
                    "exact_status": backfill["exact_status"],
                    "signals": backfill["signals"],
                    "commander_legality": backfill["commander_legality"],
                    "color_identity": json.loads(backfill["color_identity_json"]),
                    "oracle_excerpt": " ".join(str(backfill["oracle_text"] or "").split())[:320],
                    "blockers": blockers,
                }
            )
            if apply and not blockers:
                insert_backfill_row(conn, backfill)
                inserted += 1
                row["status"] = "backfill_applied"
                row["applied"] = True
            rows.append(row)
        if apply:
            conn.commit()

    status_counts = Counter(row["status"] for row in rows)
    blocker_counts = Counter(blocker for row in rows for blocker in row.get("blockers") or [])
    ready_count = sum(1 for row in rows if row["status"] == "backfill_ready")
    if apply:
        status = "external_exact_artifact_oracle_backfill_applied_review_rerun_required"
        next_gate = "rerun_external_exact_artifact_engine_candidate_reviewer_after_backfill"
    elif ready_count:
        status = "external_exact_artifact_oracle_backfill_plan_ready"
        next_gate = "apply_external_exact_artifact_oracle_backfill_then_rerun_reviewer"
    else:
        status = "external_exact_artifact_oracle_backfill_blocked"
        next_gate = "expand_external_source_or_fix_fetch_blockers_before_candidate_copy"
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_exact_artifact_oracle_backfill",
        "postgres_writes": False,
        "source_db_mutated": bool(apply and inserted),
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "deck_rows_mutated": False,
        "mutation_allowed": bool(apply),
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "reviewer_report": artifact_rel(reviewer_report),
            "reviewer_status": reviewer_payload.get("status"),
            "source_db": artifact_rel(source_db),
        },
        "summary": {
            "candidate_backfill_count": len(names),
            "backfill_ready_count": ready_count,
            "backfill_applied_count": inserted,
            "status_counts": dict(sorted(status_counts.items())),
            "blocker_counts": dict(sorted(blocker_counts.items())),
            "next_gate": next_gate,
        },
        "backfill_rows": rows,
        "policy": {
            "scope": "Only missing local Oracle rows for reviewed external exact engine seeds are eligible.",
            "deck_boundary": "No deck_cards rows are inserted, updated, or deleted.",
            "product_boundary": "This is a Hermes SQLite cache backfill, not PostgreSQL product truth.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Exact Artifact Oracle Backfill",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- candidate_backfill_count: `{summary['candidate_backfill_count']}`",
        f"- backfill_ready_count: `{summary['backfill_ready_count']}`",
        f"- backfill_applied_count: `{summary['backfill_applied_count']}`",
        f"- source_db_mutated: `{str(payload['source_db_mutated']).lower()}`",
        f"- deck_rows_mutated: `{str(payload['deck_rows_mutated']).lower()}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Backfill Rows",
        "",
        "| Card | Status | Exact Status | Signals | Color | Applied | Blockers |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for row in payload["backfill_rows"]:
        lines.append(
            "| `{card}` | `{status}` | `{exact}` | `{signals}` | `{color}` | `{applied}` | {blockers} |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                exact=row.get("exact_status") or "",
                signals=",".join(row.get("signals") or []),
                color=",".join(row.get("color_identity") or []),
                applied=str(row.get("applied")).lower(),
                blockers=", ".join(row.get("blockers") or []) or "-",
            )
        )
    if not payload["backfill_rows"]:
        lines.append("| none |  |  |  |  |  |  |")
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
    parser.add_argument("--reviewer-report", type=Path, default=DEFAULT_REVIEWER_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    payload = build_report(reviewer_report=args.reviewer_report, apply=args.apply)
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
