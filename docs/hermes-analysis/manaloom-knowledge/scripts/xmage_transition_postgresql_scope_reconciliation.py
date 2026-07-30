#!/usr/bin/env python3
"""Reconcile one pinned XMage transition with PostgreSQL product truth.

The command is intentionally accepted only through
``server/bin/with_new_server_pg.sh --read-only``. It performs two SELECT
queries, emits no database identifiers or credentials, and classifies every
transition card without treating a catalog miss as semantic evidence.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

from db_helper import connect


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DEFAULT_EVIDENCE = (
    REPO_ROOT / "docs/qa/evidence/XMAGE_PIN_TRANSITION_34d81ea_2c43ec8.json"
)
SCHEMA_VERSION = (
    "manaloom_xmage_postgresql_scope_reconciliation_v1_2026-07-28"
)
SCOPE_STATUSES = {
    "product_in_scope",
    "released_missing_from_postgresql",
    "future_deferred",
    "external_runtime_gap",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"JSON root must be an object: {path}")
    return payload


def canonical_json_sha256(payload: Any) -> str:
    encoded = json.dumps(
        payload,
        ensure_ascii=True,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def normalize_name(value: str) -> str:
    return " ".join(value.strip().casefold().split())


def _card_rows(evidence: Mapping[str, Any]) -> list[dict[str, Any]]:
    raw_cards = evidence.get("cards")
    if not isinstance(raw_cards, list):
        raise ValueError("evidence.cards must be a list")
    cards = [row for row in raw_cards if isinstance(row, dict)]
    if len(cards) != len(raw_cards) or not cards:
        raise ValueError("every evidence card must be an object")
    names = [str(row.get("card_name") or "") for row in cards]
    if any(not name for name in names) or len(names) != len(set(names)):
        raise ValueError("transition card names must be non-empty and unique")
    return cards


def build_reconciliation(
    evidence: Mapping[str, Any],
    postgres_matches: Mapping[str, list[Mapping[str, Any]]],
    *,
    transaction_read_only: bool,
    queries_executed: int,
) -> dict[str, Any]:
    cards = _card_rows(evidence)
    results: list[dict[str, Any]] = []
    ambiguity_count = 0

    for card in sorted(cards, key=lambda row: str(row["card_name"]).casefold()):
        card_name = str(card["card_name"])
        normalized = normalize_name(card_name)
        matches = [
            row
            for row in postgres_matches.get(normalized, [])
            if isinstance(row, Mapping)
        ]
        identity_count = sum(int(row.get("identity_count") or 0) for row in matches)
        printing_count = sum(int(row.get("printing_count") or 0) for row in matches)
        canonical_names = sorted(
            {
                str(row.get("canonical_name") or "")
                for row in matches
                if row.get("canonical_name")
            },
            key=str.casefold,
        )
        ambiguous = (
            len({normalize_name(value) for value in canonical_names}) > 1
            or identity_count > 1
        )
        if ambiguous:
            ambiguity_count += 1

        release_scope = str(
            card.get("release_scope_as_of_2026_07_28") or ""
        )
        runtime_status = str(card.get("runtime_catalog_status") or "")
        if identity_count > 0:
            product_scope_status = (
                "external_runtime_gap"
                if runtime_status == "unsupported"
                else "product_in_scope"
            )
        elif release_scope == "future_only":
            product_scope_status = "future_deferred"
        else:
            product_scope_status = "released_missing_from_postgresql"

        set_codes = sorted(
            {
                str(value)
                for row in matches
                for value in (row.get("set_codes") or [])
                if value
            }
        )
        release_dates = sorted(
            {
                str(value)
                for row in matches
                for value in (row.get("release_dates") or [])
                if value
            }
        )
        results.append(
            {
                "card_name": card_name,
                "product_scope_status": product_scope_status,
                "postgresql_match_count": identity_count,
                "postgresql_printing_count": printing_count,
                "canonical_names": canonical_names,
                "set_codes": set_codes,
                "release_dates": release_dates,
                "release_scope_as_of_2026_07_28": release_scope,
                "runtime_catalog_status": runtime_status,
                "ambiguous": ambiguous,
            }
        )

    counts = Counter(str(row["product_scope_status"]) for row in results)
    scope_counts = {status: counts.get(status, 0) for status in sorted(SCOPE_STATUSES)}
    valid = (
        transaction_read_only
        and queries_executed == 2
        and len(results) == len(cards)
        and ambiguity_count == 0
        and set(scope_counts) == SCOPE_STATUSES
    )
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at_utc": utc_now(),
        "status": "pass" if valid else "fail",
        "canonical_wrapper": "server/bin/with_new_server_pg.sh",
        "transaction_mode": "read_only",
        "transaction_read_only": transaction_read_only,
        "writes_performed": False,
        "queries_executed": queries_executed,
        "requested_card_count": len(cards),
        "reconciled_card_count": len(results),
        "ambiguity_count": ambiguity_count,
        "scope_counts": scope_counts,
        "rows_sha256": canonical_json_sha256(results),
        "card_results": results,
        "boundary": (
            "PostgreSQL decides product exposure. A miss, future deferment, or "
            "runtime catalog hit is never semantic proof for the card."
        ),
    }


def fetch_postgres_matches(
    card_names: Iterable[str],
) -> tuple[dict[str, list[dict[str, Any]]], bool, int]:
    normalized_names = sorted({normalize_name(name) for name in card_names})
    with connect() as connection:
        connection.set_session(readonly=True, autocommit=False)
        with connection.cursor() as cursor:
            cursor.execute("SELECT current_setting('transaction_read_only')")
            row = cursor.fetchone()
            transaction_read_only = bool(row and str(row[0]).lower() == "on")
            cursor.execute(
                """
                SELECT
                  LOWER(TRIM(c.name)) AS normalized_name,
                  MIN(c.name) AS canonical_name,
                  COUNT(DISTINCT COALESCE(c.oracle_id::text, c.id::text))::int
                    AS identity_count,
                  COUNT(DISTINCT c.id)::int AS printing_count,
                  ARRAY_REMOVE(ARRAY_AGG(DISTINCT UPPER(c.set_code)), NULL)
                    AS set_codes,
                  ARRAY_REMOVE(
                    ARRAY_AGG(DISTINCT s.release_date::text),
                    NULL
                  ) AS release_dates
                FROM cards c
                LEFT JOIN sets s ON UPPER(s.code) = UPPER(c.set_code)
                WHERE LOWER(TRIM(c.name)) = ANY(%s)
                GROUP BY LOWER(TRIM(c.name))
                ORDER BY LOWER(TRIM(c.name))
                """,
                (normalized_names,),
            )
            rows = cursor.fetchall()
        connection.rollback()

    matches: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        normalized = normalize_name(str(row[0] or ""))
        matches.setdefault(normalized, []).append(
            {
                "canonical_name": str(row[1] or ""),
                "identity_count": int(row[2] or 0),
                "printing_count": int(row[3] or 0),
                "set_codes": list(row[4] or []),
                "release_dates": list(row[5] or []),
            }
        )
    return matches, transaction_read_only, 2


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence", type=Path, default=DEFAULT_EVIDENCE)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if os.environ.get("MANALOOM_PG_WRAPPER_MODE") != "read-only":
        print("xmage_transition_postgresql_scope_error=read_only_wrapper_required")
        return 2
    try:
        evidence = load_json(args.evidence)
        cards = _card_rows(evidence)
        matches, read_only, query_count = fetch_postgres_matches(
            str(row["card_name"]) for row in cards
        )
        report = build_reconciliation(
            evidence,
            matches,
            transaction_read_only=read_only,
            queries_executed=query_count,
        )
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(report, indent=2, ensure_ascii=True, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"xmage_transition_postgresql_scope_error={exc}")
        return 2
    print(f"status={report['status']}")
    print(f"requested_cards={report['requested_card_count']}")
    print(f"reconciled_cards={report['reconciled_card_count']}")
    print(f"ambiguities={report['ambiguity_count']}")
    print(
        "product_in_scope="
        f"{report['scope_counts']['product_in_scope']}"
    )
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
