#!/usr/bin/env python3
"""Audit Commander Game Changer discovery coverage.

The bracket policy can know a card is a Game Changer while the deckbuilder
candidate source (`format_staples`) does not. This read-only audit checks that
gap without implying any card belongs in a protected deck.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sqlite3
from collections import Counter
from collections.abc import Mapping, Sequence
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from master_optimizer_common import (
    normalize_name,
    resolve_default_knowledge_db,
    sqlite_connection_has_table,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_BRACKET_POLICY = REPO_ROOT / "server" / "lib" / "edh_bracket_policy.dart"
DEFAULT_COLLECTION = SCRIPT_DIR / "user_collection.csv"
DEFAULT_DECK_ID = 607
BOROS_COLORS = {"R", "W"}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    return conn


def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def row_dict(row: sqlite3.Row | None) -> dict[str, Any]:
    return dict(row) if row else {}


def parse_json_list(value: Any) -> list[str]:
    if value in (None, ""):
        return []
    if isinstance(value, list):
        return [str(item) for item in value]
    try:
        parsed = json.loads(str(value))
    except json.JSONDecodeError:
        return []
    if isinstance(parsed, list):
        return [str(item) for item in parsed]
    return []


def read_game_changer_names(policy_path: Path) -> list[str]:
    if not policy_path.exists():
        return []
    text = policy_path.read_text(encoding="utf-8")
    match = re.search(
        r"officialGameChangerNamesForBracketPolicy\s*=\s*<String>\{(?P<body>.*?)\};",
        text,
        re.DOTALL,
    )
    if not match:
        return []
    names = [raw.replace("\\'", "'") for raw in re.findall(r"'((?:\\'|[^'])*)'", match.group("body"))]
    seen: set[str] = set()
    ordered: list[str] = []
    for name in names:
        key = normalize_name(name)
        if key in seen:
            continue
        seen.add(key)
        ordered.append(name)
    return ordered


def load_collection(path: Path) -> dict[str, int]:
    if not path.exists():
        return {}
    out: dict[str, int] = {}
    with path.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            english_name = (row.get("Card (EN)") or row.get("card_name") or "").strip()
            if not english_name:
                continue
            key = normalize_name(english_name)
            out[key] = out.get(key, 0) + as_int(row.get("Quantidade") or row.get("quantity"), 0)
    return out


def format_staple(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "format_staples"):
        return {}
    row = conn.execute(
        """
        SELECT card_name, archetype, category, color_identity, edhrec_rank,
               is_banned, scryfall_id
        FROM format_staples
        WHERE lower(format) = 'commander'
          AND lower(card_name) = lower(?)
        ORDER BY coalesce(edhrec_rank, 999999)
        LIMIT 1
        """,
        (card_name,),
    ).fetchone()
    return row_dict(row)


def oracle_lookup(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "card_oracle_cache"):
        return {}
    row = conn.execute(
        """
        SELECT name, mana_cost, color_identity_json, type_line, oracle_text,
               cmc, scryfall_id, card_id
        FROM card_oracle_cache
        WHERE normalized_name = ?
           OR lower(name) = lower(?)
        LIMIT 1
        """,
        (normalize_name(card_name), card_name),
    ).fetchone()
    return row_dict(row)


def commander_legality(conn: sqlite3.Connection, card_name: str) -> str | None:
    if not sqlite_connection_has_table(conn, "card_legalities"):
        return None
    row = conn.execute(
        """
        SELECT status
        FROM card_legalities
        WHERE lower(format) = 'commander'
          AND lower(card_name) = lower(?)
        LIMIT 1
        """,
        (card_name,),
    ).fetchone()
    return str(row["status"]) if row else None


def present_in_deck(conn: sqlite3.Connection, deck_id: int, card_name: str) -> bool:
    if not sqlite_connection_has_table(conn, "deck_cards"):
        return False
    row = conn.execute(
        """
        SELECT 1
        FROM deck_cards
        WHERE deck_id = ?
          AND lower(card_name) = lower(?)
        LIMIT 1
        """,
        (deck_id, card_name),
    ).fetchone()
    return bool(row)


def game_changers_table_status(conn: sqlite3.Connection, names: Sequence[str]) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "game_changers"):
        return {
            "present": False,
            "row_count": 0,
            "missing_from_table_count": len(names),
            "extra_table_count": 0,
        }
    rows = conn.execute(
        "SELECT card_name FROM game_changers WHERE card_name IS NOT NULL AND trim(card_name) <> ''"
    ).fetchall()
    table_names = {normalize_name(str(row["card_name"])) for row in rows}
    policy_names = {normalize_name(name) for name in names}
    return {
        "present": True,
        "row_count": len(table_names),
        "missing_from_table_count": len(policy_names - table_names),
        "extra_table_count": len(table_names - policy_names),
    }


def color_identity_allowed(color_identity: Sequence[str]) -> bool | None:
    if not color_identity:
        return True
    return set(color_identity).issubset(BOROS_COLORS)


def classify_row(row: Mapping[str, Any]) -> str:
    if not row["oracle"]["present"]:
        return "identity_gap_missing_oracle_cache"
    if row["commander_legality"] != "legal":
        return "legality_gap_not_confirmed_legal"
    if not row["format_staples"]["present"]:
        return "discovery_gap_missing_format_staples"
    return "discovery_ready_in_format_staples"


def build_row(
    *,
    conn: sqlite3.Connection,
    deck_id: int,
    card_name: str,
    collection: Mapping[str, int],
) -> dict[str, Any]:
    oracle = oracle_lookup(conn, card_name)
    color_identity = parse_json_list(oracle.get("color_identity_json"))
    staple = format_staple(conn, card_name)
    row: dict[str, Any] = {
        "card_name": card_name,
        "normalized_name": normalize_name(card_name),
        "format_staples": {
            "present": bool(staple),
            "edhrec_rank": as_int(staple.get("edhrec_rank"), 0) if staple else None,
            "archetype": staple.get("archetype") if staple else None,
            "is_banned": bool(as_int(staple.get("is_banned"), 0)) if staple else None,
        },
        "oracle": {
            "present": bool(oracle),
            "type_line": oracle.get("type_line"),
            "mana_cost": oracle.get("mana_cost"),
            "color_identity": color_identity,
            "color_identity_allowed_lorehold": color_identity_allowed(color_identity),
        },
        "commander_legality": commander_legality(conn, card_name),
        "collection_quantity": collection.get(normalize_name(card_name), 0),
        "present_in_deck": present_in_deck(conn, deck_id, card_name),
    }
    row["status"] = classify_row(row)
    return row


def build_audit(
    *,
    conn: sqlite3.Connection,
    db_path: Path,
    bracket_policy_path: Path,
    collection_path: Path,
    deck_id: int,
) -> dict[str, Any]:
    names = read_game_changer_names(bracket_policy_path)
    collection = load_collection(collection_path)
    rows = [
        build_row(conn=conn, deck_id=deck_id, card_name=name, collection=collection)
        for name in names
    ]
    status_counts = Counter(str(row["status"]) for row in rows)
    lorehold_allowed = [
        row
        for row in rows
        if row["oracle"]["present"] is True
        and row["oracle"]["color_identity_allowed_lorehold"] is True
        and row["commander_legality"] == "legal"
    ]
    missing_staples_lorehold = [
        row
        for row in lorehold_allowed
        if not row["format_staples"]["present"]
    ]
    table_status = game_changers_table_status(conn, names)
    status = (
        "game_changer_discovery_gap_found_report_only"
        if missing_staples_lorehold or status_counts.get("identity_gap_missing_oracle_cache", 0)
        else "game_changer_discovery_covered"
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "game_changer_discovery_gap_audit",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_id": deck_id,
        "source_db": rel(db_path),
        "bracket_policy": rel(bracket_policy_path),
        "collection_source": rel(collection_path),
        "status": status,
        "summary": {
            "game_changers_in_policy": len(names),
            "game_changers_table_present": table_status["present"],
            "game_changers_table_row_count": table_status["row_count"],
            "game_changers_table_missing_count": table_status["missing_from_table_count"],
            "format_staples_present_count": sum(1 for row in rows if row["format_staples"]["present"]),
            "format_staples_missing_count": sum(1 for row in rows if not row["format_staples"]["present"]),
            "oracle_missing_count": status_counts.get("identity_gap_missing_oracle_cache", 0),
            "commander_legal_count": sum(1 for row in rows if row["commander_legality"] == "legal"),
            "lorehold_legal_color_allowed_count": len(lorehold_allowed),
            "lorehold_legal_color_allowed_missing_format_staples_count": len(missing_staples_lorehold),
            "owned_game_changer_count": sum(1 for row in rows if row["collection_quantity"] > 0),
            "deck_game_changer_count": sum(1 for row in rows if row["present_in_deck"]),
            "status_counts": dict(sorted(status_counts.items())),
        },
        "rows": rows,
        "lorehold_legal_color_allowed_missing_format_staples": missing_staples_lorehold,
        "decision": {
            "no_deck_promotion": True,
            "reason": (
                "Game Changer discovery coverage is metadata only. Missing format_staples rows should "
                "be repaired as candidate-source coverage, not interpreted as proof that a card belongs "
                "in protected deck 607."
            ),
            "next_action": (
                "Use the bracket Game Changer list as a supplemental discovery lane and repair missing "
                "identity/staple rows before relying on format_staples-only candidate generation."
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Game Changer Discovery Gap Audit",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- deck_id: `{payload['deck_id']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Summary",
        "",
        f"- game changers in policy: `{summary['game_changers_in_policy']}`",
        f"- game_changers table present: `{str(summary['game_changers_table_present']).lower()}`",
        f"- format_staples present: `{summary['format_staples_present_count']}`",
        f"- format_staples missing: `{summary['format_staples_missing_count']}`",
        f"- oracle missing: `{summary['oracle_missing_count']}`",
        f"- commander legal: `{summary['commander_legal_count']}`",
        f"- Lorehold-legal/color-allowed missing format_staples: `{summary['lorehold_legal_color_allowed_missing_format_staples_count']}`",
        f"- owned Game Changers: `{summary['owned_game_changer_count']}`",
        f"- deck-607 Game Changers: `{summary['deck_game_changer_count']}`",
        f"- status counts: `{json.dumps(summary['status_counts'], sort_keys=True)}`",
        "",
        "## Lorehold-Relevant Missing format_staples Rows",
        "",
        "| Card | Owned | In 607 | Oracle | Commander | Color Identity | Status |",
        "| --- | ---: | --- | --- | --- | --- | --- |",
    ]
    for row in payload["lorehold_legal_color_allowed_missing_format_staples"]:
        lines.append(
            "| {card} | {owned} | `{in_deck}` | `{oracle}` | `{legal}` | `{ci}` | `{status}` |".format(
                card=row["card_name"],
                owned=row["collection_quantity"],
                in_deck=row["present_in_deck"],
                oracle=row["oracle"]["present"],
                legal=row["commander_legality"],
                ci="".join(row["oracle"]["color_identity"]) or "colorless",
                status=row["status"],
            )
        )
    lines.extend(
        [
            "",
            "## Decision",
            "",
            f"- no_deck_promotion: `{str(payload['decision']['no_deck_promotion']).lower()}`",
            f"- reason: {payload['decision']['reason']}",
            f"- next_action: `{payload['decision']['next_action']}`",
        ]
    )
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_DECK_ID)
    parser.add_argument("--bracket-policy", type=Path, default=DEFAULT_BRACKET_POLICY)
    parser.add_argument("--collection", type=Path, default=DEFAULT_COLLECTION)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "game_changer_discovery_gap_audit",
    )
    args = parser.parse_args()
    with connect(args.db) as conn:
        payload = build_audit(
            conn=conn,
            db_path=args.db,
            bracket_policy_path=args.bracket_policy,
            collection_path=args.collection,
            deck_id=args.deck_id,
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
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
