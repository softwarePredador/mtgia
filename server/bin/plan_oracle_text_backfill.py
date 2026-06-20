#!/usr/bin/env python3
"""Read-only oracle text backfill planner for ManaLoom card data gaps.

The planner reads PostgreSQL through the same env path used by the learned-deck
coherence audit, aggregates current deck/learned-deck impact, and optionally
looks up exact Scryfall candidates. It never mutates PostgreSQL.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from psycopg2.extras import RealDictCursor


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
LEARNED_AUDIT_PATH = SCRIPT_DIR / "learned_deck_coherence_audit.py"
SCRYFALL_NAMED_URL = "https://api.scryfall.com/cards/named"
USER_AGENT = "ManaLoomOracleTextBackfillPlan/1.0"


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_learned_audit_module():
    spec = importlib.util.spec_from_file_location(
        "learned_deck_coherence_audit",
        LEARNED_AUDIT_PATH,
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to load {LEARNED_AUDIT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def normalize_key(value: str | None) -> str:
    if not value:
        return ""
    return " ".join(value.strip().lower().split())


def scryfall_oracle_text(card: dict[str, Any]) -> str:
    oracle_text = str(card.get("oracle_text") or "").strip()
    if oracle_text:
        return oracle_text

    faces = card.get("card_faces")
    if not isinstance(faces, list):
        return ""

    chunks: list[str] = []
    for face in faces:
        if not isinstance(face, dict):
            continue
        face_text = str(face.get("oracle_text") or "").strip()
        if not face_text:
            continue
        face_name = str(face.get("name") or "").strip()
        chunks.append(f"{face_name}: {face_text}" if face_name else face_text)
    return "\n//\n".join(chunks)


def scryfall_candidate(card: dict[str, Any]) -> dict[str, Any]:
    oracle_text = scryfall_oracle_text(card)
    return {
        "found": True,
        "id": card.get("id"),
        "oracle_id": card.get("oracle_id"),
        "name": card.get("name"),
        "type_line": card.get("type_line"),
        "layout": card.get("layout"),
        "oracle_text_present": bool(oracle_text),
        "oracle_text_length": len(oracle_text),
        "color_identity": card.get("color_identity") or [],
    }


def fetch_scryfall_exact(name: str, timeout_seconds: int) -> dict[str, Any]:
    query = urllib.parse.urlencode({"exact": name})
    request = urllib.request.Request(
        f"{SCRYFALL_NAMED_URL}?{query}",
        headers={
            "Accept": "application/json",
            "User-Agent": USER_AGENT,
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
            decoded = json.loads(response.read().decode("utf-8"))
            if isinstance(decoded, dict) and decoded.get("object") != "error":
                return scryfall_candidate(decoded)
            return {
                "found": False,
                "error": decoded.get("details") if isinstance(decoded, dict) else None,
            }
    except urllib.error.HTTPError as error:
        details = None
        try:
            decoded = json.loads(error.read().decode("utf-8"))
            details = decoded.get("details") if isinstance(decoded, dict) else None
        except Exception:
            details = str(error)
        return {"found": False, "status": error.code, "error": details}
    except Exception as error:
        curl_result = fetch_scryfall_exact_with_curl(name, timeout_seconds)
        if curl_result.get("found"):
            return curl_result | {"transport": "curl_fallback"}
        return {
            "found": False,
            "error": str(error),
            "curl_fallback": curl_result,
        }


def fetch_scryfall_exact_with_curl(
    name: str,
    timeout_seconds: int,
) -> dict[str, Any]:
    query = urllib.parse.urlencode({"exact": name})
    url = f"{SCRYFALL_NAMED_URL}?{query}"
    try:
        result = subprocess.run(
            ["curl", "-sL", "--max-time", str(timeout_seconds), url],
            capture_output=True,
            text=True,
            timeout=timeout_seconds + 5,
            check=False,
        )
    except Exception as error:
        return {"found": False, "error": str(error)}

    if result.returncode != 0:
        return {
            "found": False,
            "error": f"curl returned {result.returncode}",
            "stderr": result.stderr.strip(),
        }

    try:
        decoded = json.loads(result.stdout)
    except Exception as error:
        return {"found": False, "error": f"invalid curl JSON: {error}"}

    if isinstance(decoded, dict) and decoded.get("object") != "error":
        return scryfall_candidate(decoded)
    return {
        "found": False,
        "status": decoded.get("status") if isinstance(decoded, dict) else None,
        "error": decoded.get("details") if isinstance(decoded, dict) else None,
    }


@dataclass
class OracleGapItem:
    name: str
    card_ids: set[str] = field(default_factory=set)
    missing_oracle_id: bool = False
    missing_oracle_text: bool = False
    deck_card_rows: int = 0
    deck_card_quantity: int = 0
    active_learned_refs: set[str] = field(default_factory=set)
    active_learned_commanders: set[str] = field(default_factory=set)
    active_learned_quantity: int = 0

    def merge_deck_card_row(self, row: dict[str, Any]) -> None:
        if row.get("card_id"):
            self.card_ids.add(str(row["card_id"]))
        self.missing_oracle_id = self.missing_oracle_id or bool(
            row.get("missing_oracle_id")
        )
        self.missing_oracle_text = self.missing_oracle_text or bool(
            row.get("missing_oracle_text")
        )
        self.deck_card_rows += int(row.get("deck_card_rows") or 0)
        self.deck_card_quantity += int(row.get("deck_card_quantity") or 0)

    def merge_learned_gap(
        self,
        *,
        source_ref: str,
        commander_name: str,
        card_id: str | None,
        quantity: int,
        missing_oracle_id: bool,
        missing_oracle_text: bool,
    ) -> None:
        if card_id:
            self.card_ids.add(card_id)
        self.active_learned_refs.add(source_ref)
        self.active_learned_commanders.add(commander_name)
        self.active_learned_quantity += quantity
        self.missing_oracle_id = self.missing_oracle_id or missing_oracle_id
        self.missing_oracle_text = self.missing_oracle_text or missing_oracle_text

    def to_json(self, scryfall: dict[str, Any] | None) -> dict[str, Any]:
        found = bool(scryfall and scryfall.get("found"))
        return {
            "name": self.name,
            "card_ids": sorted(self.card_ids),
            "missing_fields": [
                field_name
                for field_name, missing in [
                    ("oracle_id", self.missing_oracle_id),
                    ("oracle_text", self.missing_oracle_text),
                ]
                if missing
            ],
            "deck_card_rows": self.deck_card_rows,
            "deck_card_quantity": self.deck_card_quantity,
            "active_learned_refs": sorted(self.active_learned_refs),
            "active_learned_commanders": sorted(self.active_learned_commanders),
            "active_learned_quantity": self.active_learned_quantity,
            "scryfall": scryfall or {"found": False, "skipped": True},
            "backfill_ready": found
            and bool(scryfall.get("oracle_id"))
            and bool(scryfall.get("oracle_text_present")),
        }


def pg_oracle_base_summary(conn) -> dict[str, int]:
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            SELECT
              COUNT(*)::int AS total_cards,
              COUNT(*) FILTER (
                WHERE oracle_id IS NULL OR BTRIM(oracle_id::text) = ''
              )::int AS missing_oracle_id,
              COUNT(*) FILTER (
                WHERE oracle_text IS NULL OR BTRIM(oracle_text) = ''
              )::int AS missing_oracle_text,
              COUNT(*) FILTER (
                WHERE oracle_id IS NULL OR BTRIM(oracle_id::text) = ''
                   OR oracle_text IS NULL OR BTRIM(oracle_text) = ''
              )::int AS missing_any
            FROM cards
            """
        )
        return {key: int(value or 0) for key, value in dict(cur.fetchone()).items()}


def load_deck_card_gap_items(conn) -> dict[str, OracleGapItem]:
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            SELECT
              c.id::text AS card_id,
              c.name,
              COUNT(DISTINCT dc.id)::int AS deck_card_rows,
              COALESCE(SUM(dc.quantity), 0)::int AS deck_card_quantity,
              BOOL_OR(c.oracle_id IS NULL OR BTRIM(c.oracle_id::text) = '')
                AS missing_oracle_id,
              BOOL_OR(c.oracle_text IS NULL OR BTRIM(c.oracle_text) = '')
                AS missing_oracle_text
            FROM cards c
            JOIN deck_cards dc ON dc.card_id = c.id
            WHERE c.oracle_id IS NULL OR BTRIM(c.oracle_id::text) = ''
               OR c.oracle_text IS NULL OR BTRIM(c.oracle_text) = ''
            GROUP BY c.id, c.name
            ORDER BY deck_card_quantity DESC, c.name
            """
        )
        rows = cur.fetchall()

    items: dict[str, OracleGapItem] = {}
    for row in rows:
        name = str(row["name"] or "")
        key = normalize_key(name)
        item = items.setdefault(key, OracleGapItem(name=name))
        item.merge_deck_card_row(dict(row))
    return items


def merge_active_learned_gaps(items: dict[str, OracleGapItem], audit_module) -> None:
    conn = audit_module.connect_pg()
    try:
        lookup = audit_module.load_card_lookup(conn)
        audits = audit_module.load_active_learned_decks(conn, lookup)
    finally:
        conn.close()

    for audit in audits:
        for resolved in audit.resolved_cards:
            identity = resolved.identity
            if identity is None:
                continue
            missing_oracle_id = not bool(identity.oracle_id)
            missing_oracle_text = not bool(identity.oracle_text.strip())
            if (
                missing_oracle_text
                and audit_module.accepted_empty_oracle_text_reason(
                    identity.canonical_name
                )
            ):
                missing_oracle_text = False
            if not missing_oracle_id and not missing_oracle_text:
                continue
            name = identity.canonical_name or resolved.line.name
            key = normalize_key(name)
            item = items.setdefault(key, OracleGapItem(name=name))
            item.merge_learned_gap(
                source_ref=audit.source_ref,
                commander_name=audit.commander_name,
                card_id=identity.card_id,
                quantity=resolved.line.quantity,
                missing_oracle_id=missing_oracle_id,
                missing_oracle_text=missing_oracle_text,
            )


def parse_names_arg(raw: str | None) -> set[str]:
    if raw is None:
        return set()
    return {normalize_key(value) for value in raw.split(",") if normalize_key(value)}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--names",
        help="Comma-separated card names to focus; default includes current deck/learned gaps.",
    )
    parser.add_argument("--limit", type=int, default=0, help="Limit planned items.")
    parser.add_argument(
        "--no-scryfall",
        action="store_true",
        help="Skip Scryfall exact-name lookups.",
    )
    parser.add_argument("--delay-ms", type=int, default=100)
    parser.add_argument("--timeout-seconds", type=int, default=20)
    args = parser.parse_args(argv)

    audit_module = load_learned_audit_module()
    conn = audit_module.connect_pg()
    try:
        base_summary = pg_oracle_base_summary(conn)
        items = load_deck_card_gap_items(conn)
    finally:
        conn.close()

    merge_active_learned_gaps(items, audit_module)

    focus = parse_names_arg(args.names)
    planned = [
        item
        for key, item in sorted(items.items())
        if not focus or key in focus
    ]
    planned.sort(
        key=lambda item: (
            -(item.deck_card_quantity + item.active_learned_quantity),
            item.name.lower(),
        )
    )
    if args.limit and args.limit > 0:
        planned = planned[: args.limit]

    scryfall_by_name: dict[str, dict[str, Any]] = {}
    if not args.no_scryfall:
        for index, item in enumerate(planned):
            scryfall_by_name[item.name] = fetch_scryfall_exact(
                item.name,
                args.timeout_seconds,
            )
            if index < len(planned) - 1 and args.delay_ms > 0:
                time.sleep(args.delay_ms / 1000)

    output_items = [
        item.to_json(scryfall_by_name.get(item.name))
        for item in planned
    ]
    output = {
        "status": "PASS",
        "mode": "read_only",
        "db_mutations": False,
        "generated_at": utc_now(),
        "source": {
            "postgres": "server/.env via learned_deck_coherence_audit.connect_pg",
            "scryfall": None if args.no_scryfall else SCRYFALL_NAMED_URL,
        },
        "base_oracle_summary": base_summary,
        "counts": {
            "planned_items": len(output_items),
            "deck_card_gap_items": sum(1 for item in items.values() if item.deck_card_rows),
            "active_learned_gap_items": sum(
                1 for item in items.values() if item.active_learned_refs
            ),
            "scryfall_found": sum(
                1 for item in output_items if item["scryfall"].get("found")
            ),
            "backfill_ready": sum(
                1 for item in output_items if item["backfill_ready"]
            ),
        },
        "items": output_items,
    }
    print(json.dumps(output, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
