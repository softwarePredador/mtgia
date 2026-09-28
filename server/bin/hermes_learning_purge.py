#!/usr/bin/env python3
"""Expurgo do SQLite do Hermes para o outbox da exclusão (BT-PRIV-002, D-68).

Quem chama é o consumidor `hermes_learning_sqlite` do job
`manaloom_account_deletion_outbox`, pelo `HermesLearningPurge` de
`server/lib/privacy/account_deletion_outbox.dart`. Este script só mexe no
knowledge.db. Quem decide quais decks saem é o job, no PostgreSQL, comparando o
HMAC de cada id com os tombstones da exclusão. A chave do HMAC fica na
`privacy_keyring` e nunca sai do banco.

O knowledge.db guarda ids de deck do PostgreSQL em dois lugares:
- `user_learning_events.deck_id`, escrito por `server/bin/pull_learning_events.py`;
- o `pg_deck_id=<uuid>` do `notes` das cópias de deck (`decks` e `deck_cards`) que
  `sync_pg_target_deck_to_hermes.py` grava.

Comandos (JSON no stdout; o stderr nunca leva id):
  list  --db PATH   lista os ids de deck do PostgreSQL que o knowledge.db guarda.
                    Abre só para leitura e não cria o arquivo.
  purge --db PATH   lê {"deck_ids": [...]} do stdin. Sob o lock de escrita do
                    SQLite (BEGIN IMMEDIATE), apaga os eventos desses decks e as
                    cópias. Depois, ainda sob o lock, lista de novo os ids que
                    ficaram e devolve essa lista. O alimentador pega o mesmo lock
                    antes de conferir no PostgreSQL se o evento ainda existe, então
                    o que ele gravar depois deste commit já passou por essa
                    conferência.

Saída: 0 ok; 3 o knowledge.db não existe; 4 o banco está ocupado; 1 erro.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
from pathlib import Path

SCHEMA = "hermes_learning_purge_v1"
EXIT_OK = 0
EXIT_ERROR = 1
EXIT_ABSENT = 3
EXIT_BUSY = 4
DEFAULT_BUSY_TIMEOUT_MS = 30_000
_PG_DECK_ID = re.compile(r"(?:^|\s)pg_deck_id=([0-9A-Fa-f-]{36})(?:\s|$)")
_CHUNK = 500


def _tables(conn: sqlite3.Connection) -> set[str]:
    return {
        row[0]
        for row in conn.execute("SELECT name FROM sqlite_master WHERE type = 'table'")
    }


def _columns(conn: sqlite3.Connection, table: str) -> set[str]:
    return {row[1] for row in conn.execute(f"PRAGMA table_info({table})")}


def _event_deck_ids(conn: sqlite3.Connection, tables: set[str]) -> list[str]:
    if "user_learning_events" not in tables:
        return []
    if "deck_id" not in _columns(conn, "user_learning_events"):
        return []
    return [
        str(row[0])
        for row in conn.execute(
            "SELECT DISTINCT deck_id FROM user_learning_events "
            "WHERE deck_id IS NOT NULL AND deck_id <> ''"
        )
    ]


def _copies(conn: sqlite3.Connection, tables: set[str]) -> list[tuple[object, str]]:
    """(id da cópia no Hermes, pg_deck_id) de cada deck copiado do PostgreSQL."""
    if "decks" not in tables or "notes" not in _columns(conn, "decks"):
        return []
    copies = []
    for deck_id, notes in conn.execute(
        "SELECT id, notes FROM decks WHERE notes LIKE '%pg_deck_id=%'"
    ):
        match = _PG_DECK_ID.search(str(notes or ""))
        if match:
            copies.append((deck_id, match.group(1)))
    return copies


def _candidates(conn: sqlite3.Connection) -> dict[str, object]:
    tables = _tables(conn)
    events = _event_deck_ids(conn, tables)
    copies = _copies(conn, tables)
    return {
        "deck_ids": sorted(set(events) | {pg_id for _, pg_id in copies}),
        "event_decks": len(events),
        "copied_decks": len(copies),
    }


def _chunks(values: list, size: int = _CHUNK):
    for start in range(0, len(values), size):
        yield values[start : start + size]


def _delete_in(conn: sqlite3.Connection, table: str, column: str, values: list) -> int:
    deleted = 0
    for chunk in _chunks(values):
        placeholders = ",".join("?" for _ in chunk)
        cursor = conn.execute(
            f"DELETE FROM {table} WHERE {column} IN ({placeholders})", chunk
        )
        deleted += cursor.rowcount if cursor.rowcount > 0 else 0
    return deleted


def _is_busy(error: sqlite3.OperationalError) -> bool:
    text = str(error).lower()
    return "locked" in text or "busy" in text


def command_list(db: Path) -> tuple[int, dict]:
    if not db.is_file():
        return EXIT_ABSENT, {"schema": SCHEMA, "status": "absent"}
    try:
        conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True, timeout=5)
        try:
            payload = _candidates(conn)
        finally:
            conn.close()
    except sqlite3.OperationalError as error:
        if _is_busy(error):
            return EXIT_BUSY, {"schema": SCHEMA, "status": "busy"}
        raise
    return EXIT_OK, {"schema": SCHEMA, "status": "ok", **payload}


def command_purge(db: Path, deck_ids: list[str], busy_timeout_ms: int) -> tuple[int, dict]:
    if not db.is_file():
        return EXIT_ABSENT, {"schema": SCHEMA, "status": "absent"}
    wanted = sorted({str(deck_id) for deck_id in deck_ids if str(deck_id)})
    conn = sqlite3.connect(
        str(db), timeout=max(busy_timeout_ms, 0) / 1000, isolation_level=None
    )
    try:
        try:
            conn.execute("BEGIN IMMEDIATE")
        except sqlite3.OperationalError as error:
            if _is_busy(error):
                return EXIT_BUSY, {"schema": SCHEMA, "status": "busy"}
            raise
        try:
            tables = _tables(conn)
            events_deleted = 0
            if wanted and "user_learning_events" in tables:
                events_deleted = _delete_in(
                    conn, "user_learning_events", "deck_id", wanted
                )
            wanted_set = set(wanted)
            copy_ids = [
                copy_id
                for copy_id, pg_deck_id in _copies(conn, tables)
                if pg_deck_id in wanted_set
            ]
            deck_cards_deleted = 0
            decks_deleted = 0
            if copy_ids:
                if "deck_cards" in tables:
                    deck_cards_deleted = _delete_in(
                        conn, "deck_cards", "deck_id", copy_ids
                    )
                decks_deleted = _delete_in(conn, "decks", "id", copy_ids)
            remaining = _candidates(conn)
            conn.execute("COMMIT")
        except BaseException:
            conn.execute("ROLLBACK")
            raise
    finally:
        conn.close()
    return EXIT_OK, {
        "schema": SCHEMA,
        "status": "ok",
        "events_deleted": events_deleted,
        "decks_deleted": decks_deleted,
        "deck_cards_deleted": deck_cards_deleted,
        "remaining_deck_ids": remaining["deck_ids"],
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("command", choices=("list", "purge"))
    parser.add_argument("--db", required=True)
    parser.add_argument(
        "--busy-timeout-ms",
        type=int,
        default=int(
            os.environ.get("HERMES_PURGE_BUSY_TIMEOUT_MS", DEFAULT_BUSY_TIMEOUT_MS)
        ),
    )
    args = parser.parse_args(argv)
    db = Path(args.db)
    try:
        if args.command == "list":
            code, payload = command_list(db)
        else:
            request = json.loads(sys.stdin.read() or "{}")
            deck_ids = request.get("deck_ids") or []
            if not isinstance(deck_ids, list):
                print("hermes_learning_purge: deck_ids precisa ser lista", file=sys.stderr)
                return EXIT_ERROR
            code, payload = command_purge(db, deck_ids, args.busy_timeout_ms)
    except sqlite3.Error as error:
        print(f"hermes_learning_purge: sqlite {type(error).__name__}", file=sys.stderr)
        return EXIT_ERROR
    except (OSError, ValueError) as error:
        print(f"hermes_learning_purge: {type(error).__name__}", file=sys.stderr)
        return EXIT_ERROR
    print(json.dumps(payload, sort_keys=True))
    return code


if __name__ == "__main__":
    sys.exit(main())
