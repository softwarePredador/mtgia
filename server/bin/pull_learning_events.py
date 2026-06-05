#!/usr/bin/env python3
"""Pull deck_learning_events do PG e importa no SQLite Hermes para aprendizado.

Faz parte do loop App → Hermes:
  App cria/salva deck → PG deck_learning_events → este script → SQLite Hermes → aprendizado

Execucao idempotente: eventos ja sincronizados sao ignorados.
"""

import json, os, sqlite3, sys, subprocess
from datetime import datetime, timezone

import psycopg2
import psycopg2.extras

SQLITE_DB = os.environ.get(
    "HERMES_KNOWLEDGE_DB",
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db",
)

SYNC_DIR = os.path.join(
    os.environ.get("MTGIA_SYNC_HOME", "/opt/data/workspace/mtgia-sync"), "server"
)
ENV_FILE = os.path.join(SYNC_DIR, ".env")

def _load_env():
    """Carrega variaveis do .env para os.environ se ainda nao definidas."""
    if not os.path.isfile(ENV_FILE):
        return
    with open(ENV_FILE) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip("\"'")
            if key and key not in os.environ:
                os.environ[key] = value

_load_env()

PG_HOST = os.environ.get("DB_HOST", "143.198.230.247")
PG_PORT = os.environ.get("DB_PORT", "5433")
PG_NAME = os.environ.get("DB_NAME", "halder")
PG_USER = os.environ.get("DB_USER", "")
PG_PASS = os.environ.get("DB_PASS", "")


def main():
    print("=== Pull deck_learning_events from PG ===")

    try:
        conn = psycopg2.connect(
            host=PG_HOST,
            port=PG_PORT,
            dbname=PG_NAME,
            user=PG_USER,
            password=PG_PASS,
            connect_timeout=10,
        )
        conn.autocommit = True
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    except Exception as e:
        print(f"PG connection failed: {e}")
        return 1

    # Busca eventos nao sincronizados (ultimos 500)
    cur.execute("""
        SELECT id, deck_id, commander_name, format, card_count, source,
               event_data, created_at
        FROM deck_learning_events
        WHERE synced_to_hermes = FALSE
        ORDER BY created_at ASC
        LIMIT 500
    """)
    events = cur.fetchall()

    if not events:
        print("Nenhum evento novo.")
        cur.close()
        conn.close()
        return 0

    sqlite = sqlite3.connect(SQLITE_DB)
    _ensure_tables(sqlite)

    imported = 0
    for ev in events:
        ev_id = ev["id"]
        commander = (ev["commander_name"] or "").strip()
        fmt = ev["format"]
        card_count = ev["card_count"]
        source = ev["source"] or "user_created"
        event_data = ev["event_data"] or {}
        created_at = ev["created_at"]

        print(f"  event={ev_id} commander={commander} format={fmt} cards={card_count}")

        # Importa commander se tiver nome
        if commander and fmt.lower() == "commander":
            _import_commander(sqlite, commander)

        # Loga evento no SQLite
        sqlite.execute(
            """INSERT OR REPLACE INTO user_learning_events
               (event_id, deck_id, commander, format, card_count, source, event_data, created_at, imported_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                str(ev_id),
                str(ev["deck_id"]),
                commander,
                fmt,
                card_count,
                source,
                json.dumps(_sanitize_event_data(event_data)),
                created_at.isoformat() if created_at else None,
                datetime.now(timezone.utc).isoformat(),
            ),
        )

        imported += 1

    sqlite.commit()

    # Marca como sincronizado no PG
    event_ids = [str(e["id"]) for e in events]
    placeholders = ",".join(["%s"] * len(event_ids))
    cur.execute(
        f"UPDATE deck_learning_events SET synced_to_hermes = TRUE, synced_at = NOW() WHERE id IN ({placeholders})",
        tuple(event_ids),
    )

    print(f"\nTOTALS imported={imported}")
    sqlite.close()
    cur.close()
    conn.close()
    return 0


def _ensure_tables(sqlite):
    sqlite.execute("""
        CREATE TABLE IF NOT EXISTS user_learning_events (
            event_id TEXT PRIMARY KEY,
            deck_id TEXT,
            commander TEXT,
            format TEXT,
            card_count INTEGER DEFAULT 0,
            source TEXT DEFAULT 'user_created',
            event_data TEXT DEFAULT '{}',
            created_at TEXT,
            imported_at TEXT
        )
    """)


def _import_commander(sqlite, name):
    """Registra comandante no catalogo se ainda nao existe."""
    existing = sqlite.execute(
        "SELECT id FROM commanders WHERE LOWER(name) = LOWER(?)", (name,)
    ).fetchone()
    if existing:
        return
    color_identity = ""  # Poderia deduzir do event_data, mas deixamos simplificado
    sqlite.execute(
        """INSERT INTO commanders (name, color_identity, first_analyzed, last_analyzed, deck_count, insight_count)
           VALUES (?, ?, ?, ?, 1, 0)""",
        (
            name,
            color_identity,
            datetime.now(timezone.utc).isoformat(),
            datetime.now(timezone.utc).isoformat(),
        ),
    )


def _sanitize_event_data(data):
    """Remove campos grandes/desnecessarios para reduzir armazenamento."""
    if isinstance(data, dict):
        result = {}
        for k, v in data.items():
            if k == "cards" and isinstance(v, list):
                result[k] = v[:200]  # limita a 200 cartas
            elif isinstance(v, (str, int, float, bool)):
                result[k] = v
            elif v is None:
                result[k] = None
        return result
    if isinstance(data, list):
        return data[:200]
    return data


if __name__ == "__main__":
    sys.exit(main())
