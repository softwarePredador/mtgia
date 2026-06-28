#!/usr/bin/env python3
"""Materialize and validate the documented canonical Lorehold deck state.

This script resolves the current project ambiguity between:

- the live Hermes reports, where the approved local swap is
  Wheel of Misfortune over Reforge the Soul; and
- a stale local knowledge.db copy that may still contain Reforge the Soul.

It never mutates product/Postgres data. With --apply-local-sqlite it only
updates the local Hermes SQLite deck_cards row for deck_id=6 after creating a
backup beside the database.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from master_optimizer_common import get_deck_summary


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_DECK_ID = 6
DEFAULT_BACKUP_KEEP = 5
RUNTIME_BACKUP_DIR = Path("/data/manaloom-ops/knowledge-backups")

DOCUMENTED_SERVER_HASH = "12c55613ae4f7bcd4c934fae4253cfa75fcc4946352a18a61365835427e90c08"
DOCUMENTED_SERVER_WR = "87.3%"
DOCUMENTED_SWAP_IN = "Wheel of Misfortune"
DOCUMENTED_SWAP_OUT = "Reforge the Soul"
DOCUMENTED_REVERTED_IN = "Plaza of Heroes"
DOCUMENTED_REVERTED_OUT = "Rise of the Eldrazi"


def utc_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_%f")


def normalize(name: str) -> str:
    return " ".join(name.strip().lower().split())


def fetch_one(conn: sqlite3.Connection, query: str, params: tuple[object, ...]) -> sqlite3.Row | None:
    return conn.execute(query, params).fetchone()


def card_count(conn: sqlite3.Connection, deck_id: int, card_name: str) -> int:
    row = fetch_one(
        conn,
        """
        SELECT COALESCE(SUM(quantity), 0)
        FROM deck_cards
        WHERE deck_id=? AND lower(card_name)=lower(?)
        """,
        (deck_id, card_name),
    )
    return int(row[0] or 0) if row else 0


def load_card_metadata(conn: sqlite3.Connection, card_name: str) -> dict[str, object]:
    row = fetch_one(
        conn,
        """
        SELECT name, cmc, type_line, oracle_text
        FROM card_oracle_cache
        WHERE lower(name)=lower(?)
        LIMIT 1
        """,
        (card_name,),
    )
    if not row:
        raise RuntimeError(f"Missing card_oracle_cache metadata for {card_name}")

    tag = "draw"
    rules = conn.execute(
        """
        SELECT deck_role_json
        FROM battle_card_rules
        WHERE lower(card_name)=lower(?)
        """,
        (card_name,),
    ).fetchall()
    tags: list[str] = []
    for rule in rules:
        try:
            category = str(json.loads(rule["deck_role_json"]).get("category") or "")
        except Exception:
            category = ""
        if category:
            tags.append(category)
    if tags:
        tag = tags[0]

    return {
        "card_name": row["name"],
        "functional_tag": tag,
        "cmc": row["cmc"],
        "type_line": row["type_line"],
        "oracle_text": row["oracle_text"],
    }


def positive_int(value: str) -> int:
    parsed = int(value)
    if parsed < 1:
        raise argparse.ArgumentTypeError("must be >= 1")
    return parsed


def default_backup_keep() -> int:
    value = os.environ.get("HERMES_KNOWLEDGE_BACKUP_KEEP") or os.environ.get(
        "MANALOOM_KNOWLEDGE_BACKUP_KEEP"
    )
    if not value:
        return DEFAULT_BACKUP_KEEP
    return positive_int(value)


def resolve_backup_dir(db_path: Path, requested_dir: Path | None) -> Path:
    if requested_dir:
        return requested_dir

    env_dir = os.environ.get("HERMES_KNOWLEDGE_BACKUP_DIR") or os.environ.get(
        "MANALOOM_KNOWLEDGE_BACKUP_DIR"
    )
    if env_dir:
        return Path(env_dir)

    if RUNTIME_BACKUP_DIR.parent.exists():
        return RUNTIME_BACKUP_DIR

    return db_path.parent


def prune_backups(backup_dir: Path, db_path: Path, keep: int) -> list[Path]:
    backups = sorted(
        backup_dir.glob(f"{db_path.name}.bak_lorehold_canonical_*"),
        key=lambda path: (path.stat().st_mtime_ns, path.name),
        reverse=True,
    )
    pruned: list[Path] = []
    for old_backup in backups[keep:]:
        old_backup.unlink()
        pruned.append(old_backup)
    return pruned


def backup_db(db_path: Path, backup_dir: Path, keep: int) -> tuple[Path, list[Path]]:
    backup_dir.mkdir(parents=True, exist_ok=True)
    backup = backup_dir / f"{db_path.name}.bak_lorehold_canonical_{utc_stamp()}"
    shutil.copy2(db_path, backup)
    pruned = prune_backups(backup_dir, db_path, keep)
    return backup, pruned


def apply_documented_swap(
    conn: sqlite3.Connection,
    db_path: Path,
    deck_id: int,
    backup_dir: Path,
    backup_keep: int,
) -> tuple[str, Path | None, list[Path]]:
    in_count = card_count(conn, deck_id, DOCUMENTED_SWAP_IN)
    out_count = card_count(conn, deck_id, DOCUMENTED_SWAP_OUT)

    if in_count == 1 and out_count == 0:
        return "already_aligned", None, []
    if in_count > 0 and out_count > 0:
        raise RuntimeError(
            f"Unsafe state: both {DOCUMENTED_SWAP_IN} and {DOCUMENTED_SWAP_OUT} are present"
        )
    if in_count == 0 and out_count != 1:
        raise RuntimeError(
            f"Unsafe state: expected exactly one {DOCUMENTED_SWAP_OUT}, found {out_count}"
        )

    backup, pruned = backup_db(db_path, backup_dir, backup_keep)
    metadata = load_card_metadata(conn, DOCUMENTED_SWAP_IN)
    conn.execute(
        """
        UPDATE deck_cards
        SET card_name=?,
            functional_tag=?,
            tag_confidence=1.0,
            cmc=?,
            type_line=?,
            oracle_text=?
        WHERE deck_id=? AND lower(card_name)=lower(?)
        """,
        (
            metadata["card_name"],
            metadata["functional_tag"],
            metadata["cmc"],
            metadata["type_line"],
            metadata["oracle_text"],
            deck_id,
            DOCUMENTED_SWAP_OUT,
        ),
    )
    conn.commit()
    return "applied_local_sqlite", backup, pruned


def deck_rows(conn: sqlite3.Connection, deck_id: int) -> list[sqlite3.Row]:
    return conn.execute(
        """
        SELECT card_name, quantity, functional_tag, is_commander, cmc, type_line
        FROM deck_cards
        WHERE deck_id=?
        ORDER BY
          is_commander DESC,
          CASE WHEN lower(COALESCE(type_line, '')) LIKE '%land%' THEN 0 ELSE 1 END,
          COALESCE(cmc, 999),
          card_name
        """,
        (deck_id,),
    ).fetchall()


def classify(row: sqlite3.Row) -> str:
    if int(row["is_commander"] or 0):
        return "commander"
    if "land" in str(row["type_line"] or "").lower():
        return "land"
    return str(row["functional_tag"] or "unknown")


def validate(conn: sqlite3.Connection, deck_id: int) -> list[str]:
    errors: list[str] = []
    rows = deck_rows(conn, deck_id)
    total = sum(int(row["quantity"] or 0) for row in rows)
    commanders = sum(int(row["quantity"] or 0) for row in rows if int(row["is_commander"] or 0))
    lands = sum(
        int(row["quantity"] or 0)
        for row in rows
        if "land" in str(row["type_line"] or "").lower()
    )

    if total != 100:
        errors.append(f"expected 100 cards, found {total}")
    if commanders != 1:
        errors.append(f"expected 1 commander, found {commanders}")
    if lands != 33:
        errors.append(f"expected 33 lands in canonical Hermes state, found {lands}")
    if card_count(conn, deck_id, DOCUMENTED_SWAP_IN) != 1:
        errors.append(f"expected {DOCUMENTED_SWAP_IN} present")
    if card_count(conn, deck_id, DOCUMENTED_SWAP_OUT) != 0:
        errors.append(f"expected {DOCUMENTED_SWAP_OUT} absent")
    if card_count(conn, deck_id, DOCUMENTED_REVERTED_IN) != 0:
        errors.append(f"expected reverted {DOCUMENTED_REVERTED_IN} absent")
    if card_count(conn, deck_id, DOCUMENTED_REVERTED_OUT) != 1:
        errors.append(f"expected {DOCUMENTED_REVERTED_OUT} present")
    return errors


def build_snapshot(
    conn: sqlite3.Connection,
    deck_id: int,
    status: str,
    backup: Path | None,
    backup_dir: Path,
    backup_keep: int,
    pruned_backups: list[Path],
) -> dict[str, object]:
    rows = deck_rows(conn, deck_id)
    summary = get_deck_summary(conn, deck_id)
    role_counts = Counter()
    cards = []
    for row in rows:
        role = classify(row)
        qty = int(row["quantity"] or 0)
        role_counts[role] += qty
        cards.append(
            {
                "quantity": qty,
                "name": row["card_name"],
                "role": role,
                "functional_tag": row["functional_tag"],
                "cmc": row["cmc"],
                "type_line": row["type_line"],
            }
        )

    errors = validate(conn, deck_id)
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "status": "approved" if not errors else "blocked",
        "local_sqlite_action": status,
        "local_backup": str(backup) if backup else None,
        "local_backup_dir": str(backup_dir),
        "local_backup_retention_keep": backup_keep,
        "local_backup_pruned": [str(path) for path in pruned_backups],
        "deck_id": deck_id,
        "documented_server_hash": DOCUMENTED_SERVER_HASH,
        "documented_server_wr": DOCUMENTED_SERVER_WR,
        "local_summary": summary,
        "canonical_decisions": {
            "kept_swap": {
                "add": DOCUMENTED_SWAP_IN,
                "remove": DOCUMENTED_SWAP_OUT,
            },
            "reverted_swap": {
                "add": DOCUMENTED_REVERTED_IN,
                "remove": DOCUMENTED_REVERTED_OUT,
            },
        },
        "validation_errors": errors,
        "role_counts": dict(sorted(role_counts.items())),
        "cards": cards,
        "notes": [
            "This snapshot is Hermes-local canonical evidence, not a product apply.",
            "Production/app mutation still requires product owner approval and backup.",
            "The live Hermes server hash is documented separately because local ignored SQLite copies can drift.",
        ],
    }


def render_markdown(snapshot: dict[str, object]) -> str:
    decisions = snapshot["canonical_decisions"]
    summary = snapshot["local_summary"]
    lines = [
        "# Lorehold Canonical Deck Snapshot",
        "",
        f"- generated_at: {snapshot['generated_at']}",
        f"- status: {snapshot['status']}",
        f"- deck_id: {snapshot['deck_id']}",
        f"- local_sqlite_action: {snapshot['local_sqlite_action']}",
        f"- local_backup: `{snapshot['local_backup']}`",
        f"- local_backup_dir: `{snapshot['local_backup_dir']}`",
        f"- local_backup_retention_keep: {snapshot['local_backup_retention_keep']}",
        f"- local_backup_pruned: {len(snapshot['local_backup_pruned'])}",
        f"- documented_server_hash: `{snapshot['documented_server_hash']}`",
        f"- documented_server_wr: {snapshot['documented_server_wr']}",
        f"- local_hash: `{summary['hash']}`",
        f"- local_semantics_hash: `{summary['semantics_hash']}`",
        f"- local_ruleset_hash: `{summary['ruleset_hash']}`",
        f"- cards: {summary['cards']}",
        f"- lands: {summary['lands']}",
        f"- avg_cmc: {summary['avg_cmc']}",
        "",
        "## Canonical decisions",
        "",
        f"- Kept: add `{decisions['kept_swap']['add']}` over `{decisions['kept_swap']['remove']}`.",
        f"- Reverted: `{decisions['reverted_swap']['add']}` over `{decisions['reverted_swap']['remove']}` did not survive post-apply gate.",
        "- Product/app apply: blocked until explicit approval, backup, dry-run diff and smoke test.",
        "",
        "## Validation",
        "",
    ]
    errors = snapshot["validation_errors"]
    if errors:
        for error in errors:
            lines.append(f"- ERROR: {error}")
    else:
        lines.append("- PASS: 100 cards, exactly 1 commander, 33 lands.")
        lines.append(f"- PASS: `{DOCUMENTED_SWAP_IN}` present and `{DOCUMENTED_SWAP_OUT}` absent.")
        lines.append(f"- PASS: `{DOCUMENTED_REVERTED_IN}` absent and `{DOCUMENTED_REVERTED_OUT}` present.")

    lines.extend(["", "## Role counts", ""])
    for role, qty in snapshot["role_counts"].items():
        lines.append(f"- {role}: {qty}")

    lines.extend(["", "## Decklist", "", "```text"])
    for card in snapshot["cards"]:
        lines.append(f"{card['quantity']} {card['name']}")
    lines.extend(["```", ""])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_DECK_ID)
    parser.add_argument("--apply-local-sqlite", action="store_true")
    parser.add_argument("--backup-dir", type=Path)
    parser.add_argument(
        "--backup-retention",
        type=positive_int,
        default=default_backup_keep(),
    )
    parser.add_argument("--out-dir", type=Path, default=REPORT_DIR)
    parser.add_argument("--prefix", default="lorehold_canonical_snapshot_20260614")
    args = parser.parse_args()

    if not args.db.exists():
        raise SystemExit(f"SQLite DB not found: {args.db}")

    args.out_dir.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(args.db)
    conn.row_factory = sqlite3.Row
    try:
        action = "validated_only"
        backup = None
        pruned_backups: list[Path] = []
        backup_dir = resolve_backup_dir(args.db, args.backup_dir)
        if args.apply_local_sqlite:
            action, backup, pruned_backups = apply_documented_swap(
                conn,
                args.db,
                args.deck_id,
                backup_dir,
                args.backup_retention,
            )
        snapshot = build_snapshot(
            conn,
            args.deck_id,
            action,
            backup,
            backup_dir,
            args.backup_retention,
            pruned_backups,
        )
    finally:
        conn.close()

    json_path = args.out_dir / f"{args.prefix}.json"
    md_path = args.out_dir / f"{args.prefix}.md"
    json_path.write_text(json.dumps(snapshot, ensure_ascii=False, indent=2), encoding="utf-8")
    md_path.write_text(render_markdown(snapshot), encoding="utf-8")

    print(f"status={snapshot['status']}")
    print(f"json={json_path}")
    print(f"markdown={md_path}")
    if snapshot["validation_errors"]:
        for error in snapshot["validation_errors"]:
            print(f"ERROR: {error}")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
