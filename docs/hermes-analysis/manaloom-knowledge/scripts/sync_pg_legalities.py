#!/usr/bin/env python3
"""Sync PostgreSQL Commander legalities into Hermes knowledge.db.

Requires PostgreSQL connection variables in the environment. The wrapper
`/opt/data/scripts/manaloom-sync-legalities.sh` loads them from the runtime
secrets file. This script intentionally contains no credentials.
"""

from __future__ import annotations

import os
import sqlite3
import subprocess
from pathlib import Path


DB = Path('/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db')


def pg(sql: str) -> list[list[str]]:
    env = os.environ.copy()
    if not env.get('PGPASSWORD'):
        raise SystemExit('PGPASSWORD is required. Run via /opt/data/scripts/manaloom-sync-legalities.sh')
    host = env.get('PGHOST', '143.198.230.247')
    port = env.get('PGPORT', '5433')
    user = env.get('PGUSER', 'postgres')
    dbname = env.get('PGDATABASE', 'halder')
    result = subprocess.run(
        ['psql', '-h', host, '-p', port, '-U', user, '-d', dbname, '-t', '-A', '-F', '|', '-c', sql],
        env=env,
        capture_output=True,
        text=True,
        timeout=120,
    )
    if result.returncode != 0:
        raise SystemExit(result.stderr.strip() or 'psql failed')
    return [line.split('|') for line in result.stdout.splitlines() if line.strip()]


def main() -> None:
    con = sqlite3.connect(DB)
    cur = con.cursor()
    cur.execute('''CREATE TABLE IF NOT EXISTS card_legalities (
        card_name TEXT NOT NULL,
        format TEXT NOT NULL,
        status TEXT NOT NULL,
        scryfall_id TEXT,
        synced_at TEXT DEFAULT (datetime('now')),
        PRIMARY KEY(card_name, format)
    )''')
    cur.execute('''CREATE TABLE IF NOT EXISTS format_staples (
        card_name TEXT NOT NULL,
        format TEXT NOT NULL,
        archetype TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL DEFAULT '',
        color_identity TEXT,
        edhrec_rank INTEGER,
        scryfall_id TEXT,
        is_banned INTEGER DEFAULT 0,
        synced_at TEXT DEFAULT (datetime('now')),
        PRIMARY KEY(card_name, format, archetype, category)
    )''')

    legalities = pg('''
        SELECT
          c.name,
          cl.format,
          CASE
            WHEN bool_or(cl.status = 'banned') THEN 'banned'
            WHEN bool_or(cl.status = 'legal') THEN 'legal'
            ELSE min(cl.status)
          END AS status,
          min(c.scryfall_id::text) AS scryfall_id
        FROM card_legalities cl
        JOIN cards c ON c.id = cl.card_id
        WHERE cl.format = 'commander'
        GROUP BY c.name, cl.format
        ORDER BY c.name;
    ''')
    cur.execute("DELETE FROM card_legalities WHERE format='commander'")
    cur.executemany(
        '''INSERT INTO card_legalities(card_name, format, status, scryfall_id, synced_at)
           VALUES (?, ?, ?, ?, datetime('now'))''',
        [(name, fmt, status, scryfall_id or None) for name, fmt, status, scryfall_id in legalities],
    )
    # Local decklists often use only the front face of modal/adventure cards
    # while Scryfall/PG stores the full `Front // Back` name.
    cur.execute('''
        INSERT OR REPLACE INTO card_legalities(card_name, format, status, scryfall_id, synced_at)
        SELECT
          substr(card_name, 1, instr(card_name, ' // ') - 1),
          format,
          status,
          scryfall_id,
          datetime('now')
        FROM card_legalities
        WHERE format='commander' AND instr(card_name, ' // ') > 0
    ''')
    # ManaLoom-specific commander used in the Hermes corpus.
    cur.execute('''
        INSERT OR REPLACE INTO card_legalities(card_name, format, status, scryfall_id, synced_at)
        VALUES ('Lorehold, the Historian', 'commander', 'legal', NULL, datetime('now'))
    ''')

    staples = pg('''
        SELECT
          card_name,
          format,
          COALESCE(archetype, ''),
          COALESCE(category, ''),
          COALESCE(array_to_string(color_identity, ','), ''),
          COALESCE(edhrec_rank::text, ''),
          COALESCE(scryfall_id::text, ''),
          CASE WHEN is_banned THEN '1' ELSE '0' END
        FROM format_staples
        WHERE format = 'commander'
        ORDER BY card_name;
    ''')
    cur.execute("DELETE FROM format_staples WHERE format='commander'")
    cur.executemany(
        '''INSERT INTO format_staples(
             card_name, format, archetype, category, color_identity, edhrec_rank, scryfall_id, is_banned, synced_at
           ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))''',
        [
            (name, fmt, arch or '', cat or '', ci or None, int(rank) if rank else None, sid or None, int(banned))
            for name, fmt, arch, cat, ci, rank, sid, banned in staples
        ],
    )
    con.commit()

    worldfire = cur.execute(
        "SELECT status FROM card_legalities WHERE lower(card_name)=lower('Worldfire') AND format='commander'"
    ).fetchone()
    mana_crypt = cur.execute(
        "SELECT status FROM card_legalities WHERE lower(card_name)=lower('Mana Crypt') AND format='commander'"
    ).fetchone()
    print(f'card_legalities commander rows: {len(legalities)}')
    print(f'format_staples commander rows: {len(staples)}')
    print(f"Worldfire commander status: {worldfire[0] if worldfire else 'missing'}")
    print(f"Mana Crypt commander status: {mana_crypt[0] if mana_crypt else 'missing'}")
    con.close()


if __name__ == '__main__':
    main()
