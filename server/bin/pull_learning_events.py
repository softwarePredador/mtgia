#!/usr/bin/env python3
"""Pull deck_learning_events do PG para telemetria classificada no Hermes.

Faz parte do loop App → Hermes:
  App salva deck → PG deck_learning_events → este script → SQLite Hermes

Somente eventos ``user_created`` podem ser elegiveis para treinamento. Outras
fontes permanecem no SQLite apenas como telemetria em quarentena.

Execucao idempotente: eventos ja sincronizados sao ignorados.

Exclusao de conta (BT-PRIV-002): o SQLite so recebe evento que ainda existe no
PG, conferido sob o lock de escrita do SQLite (BEGIN IMMEDIATE). O expurgo do
outbox (server/bin/hermes_learning_purge.py) pega o mesmo lock, entao evento
de conta excluida nunca volta ao SQLite depois da varredura.
"""
import json, os, sqlite3, sys
from pathlib import Path
from datetime import datetime, timezone

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_KNOWLEDGE_DB = (
    REPO_ROOT / "docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
)
SYNC_HOME = Path(os.environ.get("MTGIA_SYNC_HOME", str(REPO_ROOT)))
SYNC_SERVER_DIR = Path(os.environ.get("MTGIA_SYNC_SERVER_DIR", str(SYNC_HOME / "server")))
ENV_FILE = Path(os.environ.get("MTGIA_ENV_FILE", str(SYNC_SERVER_DIR / ".env")))

SQLITE_DB = (
    os.environ.get("HERMES_KNOWLEDGE_DB")
    or os.environ.get("MANALOOM_KNOWLEDGE_DB")
    or str(DEFAULT_KNOWLEDGE_DB)
)

def _load_env():
    """Carrega variaveis do .env para os.environ se ainda nao definidas."""
    if not ENV_FILE.is_file():
        return
    with ENV_FILE.open() as f:
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

PG_HOST = os.environ.get("PGHOST") or os.environ.get("DB_HOST") or ""
PG_PORT = os.environ.get("PGPORT") or os.environ.get("DB_PORT") or "5432"
PG_NAME = os.environ.get("PGDATABASE") or os.environ.get("DB_NAME") or ""
PG_USER = os.environ.get("PGUSER") or os.environ.get("DB_USER") or ""
PG_PASS = os.environ.get("PGPASSWORD") or os.environ.get("DB_PASS") or ""
MIN_TRAINING_CARD_COUNT = int(os.environ.get("HERMES_MIN_TRAINING_CARD_COUNT", "90"))
USER_CREATED_SOURCE = "user_created"
SQLITE_BUSY_TIMEOUT_SECONDS = 30

# DCK-P0-06 (decisao D-30 do dono): deck na lixeira nao conta em aprendizado.
# So sai evento de deck vivo: o de deck na lixeira espera (volta a sair se o
# deck for restaurado) e o de deck apagado de vez nunca sai; a limpeza por
# prazo apaga os eventos do deck purgado.
PENDING_EVENTS_SQL = """
        SELECT e.id, e.deck_id, e.commander_name, e.format, e.card_count,
               e.source, e.event_data, e.created_at
        FROM deck_learning_events e
        JOIN decks d ON d.id = e.deck_id AND d.deleted_at IS NULL
        WHERE e.synced_to_hermes = FALSE
        ORDER BY e.created_at ASC
        LIMIT 500
    """


def main():
    print("=== Pull deck_learning_events from PG ===")

    missing_pg = [
        name
        for name, value in (
            ("PGHOST/DB_HOST", PG_HOST),
            ("PGDATABASE/DB_NAME", PG_NAME),
            ("PGUSER/DB_USER", PG_USER),
        )
        if not value
    ]
    if missing_pg:
        print(
            "PG connection skipped: missing required env "
            + ", ".join(missing_pg)
        )
        return 1

    try:
        import psycopg2
        import psycopg2.extras

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

    # Busca eventos nao sincronizados (ultimos 500), so de deck vivo.
    cur.execute(PENDING_EVENTS_SQL)
    events = cur.fetchall()

    sqlite = sqlite3.connect(SQLITE_DB, timeout=SQLITE_BUSY_TIMEOUT_SECONDS)
    _ensure_tables(sqlite)

    if not events:
        print("Nenhum evento novo.")
        sqlite.commit()
        sqlite.close()
        cur.close()
        conn.close()
        return 0

    imported, skipped_deleted, live_ids = _import_events(sqlite, cur, events)

    # Marca como sincronizado no PG (so os que ainda existem)
    if live_ids:
        placeholders = ",".join(["%s"] * len(live_ids))
        cur.execute(
            f"UPDATE deck_learning_events SET synced_to_hermes = TRUE, synced_at = NOW() WHERE id IN ({placeholders})",
            tuple(sorted(live_ids)),
        )

    totals = sqlite.execute(
        """
        SELECT
          COUNT(*) AS imported_total,
          SUM(CASE WHEN training_eligible = 1 THEN 1 ELSE 0 END) AS trainable,
          SUM(CASE WHEN learning_status = 'partial_telemetry' THEN 1 ELSE 0 END) AS partial,
          SUM(CASE WHEN learning_status = 'non_commander_telemetry' THEN 1 ELSE 0 END) AS non_commander,
          SUM(CASE WHEN learning_status = 'quarantined_source' THEN 1 ELSE 0 END) AS quarantined
        FROM user_learning_events
        """
    ).fetchone()

    print(
        "\nTOTALS "
        f"imported={imported} "
        f"skipped_deleted={skipped_deleted} "
        f"stored_total={totals[0] or 0} "
        f"trainable={totals[1] or 0} "
        f"partial={totals[2] or 0} "
        f"non_commander={totals[3] or 0} "
        f"quarantined={totals[4] or 0}"
    )
    sqlite.close()
    cur.close()
    conn.close()
    return 0


def _events_still_in_postgres(cur, event_ids):
    """Ids que ainda existem em deck_learning_events (a exclusao apaga os da conta)."""
    if not event_ids:
        return set()
    cur.execute(
        "SELECT id::text AS id FROM deck_learning_events WHERE id::text = ANY(%s)",
        (list(event_ids),),
    )
    return {str(row["id"]) for row in cur.fetchall()}


def _import_events(sqlite, cur, events):
    """Grava no SQLite so o que ainda existe no PG, conferido sob o lock.

    O lock de escrita (BEGIN IMMEDIATE) vem antes da conferencia. Assim, se a
    conta for excluida depois do SELECT, ou o evento ja foi gravado antes de o
    expurgo pegar o lock (e o expurgo apaga), ou a conferencia ja nao o acha.
    """
    sqlite.commit()
    sqlite.execute("BEGIN IMMEDIATE")
    try:
        live_ids = _events_still_in_postgres(cur, [str(ev["id"]) for ev in events])
        imported = 0
        skipped_deleted = 0
        for ev in events:
            if str(ev["id"]) not in live_ids:
                skipped_deleted += 1
                continue
            _import_event(sqlite, ev)
            imported += 1
        sqlite.commit()
    except BaseException:
        sqlite.rollback()
        raise
    return imported, skipped_deleted, live_ids


def _import_event(sqlite, ev):
    ev_id = ev["id"]
    commander = (ev["commander_name"] or "").strip()
    fmt = ev["format"]
    card_count = ev["card_count"]
    source = (ev["source"] or "").strip().lower()
    event_data = ev["event_data"] or {}
    created_at = ev["created_at"]

    classification = _classify_learning_event(
        fmt,
        card_count,
        commander,
        source,
    )

    print(
        "  event="
        f"{ev_id} commander={commander} format={fmt} cards={card_count} "
        f"status={classification['learning_status']}"
    )

    # Importa commander se tiver nome
    if (
        source == USER_CREATED_SOURCE
        and commander
        and (fmt or "").lower() == "commander"
    ):
        _import_commander(sqlite, commander)

    # Loga evento no SQLite
    sqlite.execute(
        """INSERT OR REPLACE INTO user_learning_events
           (
             event_id,
             deck_id,
             commander,
             format,
             card_count,
             source,
             event_data,
             created_at,
             imported_at,
             training_eligible,
             learning_status,
             learning_reason
           )
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
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
            1 if classification["training_eligible"] else 0,
            classification["learning_status"],
            classification["learning_reason"],
        ),
    )


def _ensure_tables(sqlite):
    sqlite.execute("""
        CREATE TABLE IF NOT EXISTS user_learning_events (
            event_id TEXT PRIMARY KEY,
            deck_id TEXT,
            commander TEXT,
            format TEXT,
            card_count INTEGER DEFAULT 0,
            source TEXT DEFAULT '',
            event_data TEXT DEFAULT '{}',
            created_at TEXT,
            imported_at TEXT,
            training_eligible INTEGER DEFAULT 0,
            learning_status TEXT DEFAULT 'unknown',
            learning_reason TEXT DEFAULT ''
        )
    """)
    _ensure_column(
        sqlite,
        "user_learning_events",
        "source",
        "TEXT DEFAULT ''",
    )
    _ensure_column(
        sqlite,
        "user_learning_events",
        "training_eligible",
        "INTEGER DEFAULT 0",
    )
    _ensure_column(
        sqlite,
        "user_learning_events",
        "learning_status",
        "TEXT DEFAULT 'unknown'",
    )
    _ensure_column(
        sqlite,
        "user_learning_events",
        "learning_reason",
        "TEXT DEFAULT ''",
    )
    _backfill_learning_classification(sqlite)
    sqlite.execute("""
        CREATE TABLE IF NOT EXISTS commanders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            color_identity TEXT DEFAULT '',
            first_analyzed TEXT,
            last_analyzed TEXT,
            deck_count INTEGER DEFAULT 0,
            insight_count INTEGER DEFAULT 0
        )
    """)


def _ensure_column(sqlite, table, column, definition):
    columns = {
        row[1]
        for row in sqlite.execute(f"PRAGMA table_info({table})").fetchall()
    }
    if column not in columns:
        sqlite.execute(f"ALTER TABLE {table} ADD COLUMN {column} {definition}")


def _classify_learning_event(fmt, card_count, commander, source):
    normalized_format = (fmt or "").strip().lower()
    normalized_commander = (commander or "").strip()
    normalized_source = (source or "").strip().lower()
    count = int(card_count or 0)

    if normalized_source != USER_CREATED_SOURCE:
        return {
            "training_eligible": False,
            "learning_status": "quarantined_source",
            "learning_reason": f"source={normalized_source or 'unknown'}",
        }

    if normalized_format != "commander":
        return {
            "training_eligible": False,
            "learning_status": "non_commander_telemetry",
            "learning_reason": f"format={normalized_format or 'unknown'}",
        }

    if not normalized_commander:
        return {
            "training_eligible": False,
            "learning_status": "partial_telemetry",
            "learning_reason": "missing_commander",
        }

    if count < MIN_TRAINING_CARD_COUNT:
        return {
            "training_eligible": False,
            "learning_status": "partial_telemetry",
            "learning_reason": f"card_count={count}<min={MIN_TRAINING_CARD_COUNT}",
        }

    return {
        "training_eligible": True,
        "learning_status": "trainable_commander_deck",
        "learning_reason": f"card_count={count}>=min={MIN_TRAINING_CARD_COUNT}",
    }


def _backfill_learning_classification(sqlite):
    rows = sqlite.execute(
        """
        SELECT event_id, format, card_count, commander, source
        FROM user_learning_events
        """
    ).fetchall()
    for event_id, fmt, card_count, commander, source in rows:
        classification = _classify_learning_event(
            fmt,
            card_count,
            commander,
            source,
        )
        sqlite.execute(
            """
            UPDATE user_learning_events
            SET training_eligible = ?,
                learning_status = ?,
                learning_reason = ?
            WHERE event_id = ?
            """,
            (
                1 if classification["training_eligible"] else 0,
                classification["learning_status"],
                classification["learning_reason"],
                event_id,
            ),
        )


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
