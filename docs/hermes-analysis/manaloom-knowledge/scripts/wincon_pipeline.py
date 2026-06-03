#!/usr/bin/env python3
"""Lorehold wincon pipeline.

Modes:
  hunter  - discover/catalog wincons from approved local/PG sources
  tester  - validate availability against current Lorehold deck + collection
  builder - emit candidate wincon packages; never changes decklists
  oracle  - review-only deterministic priority report

No mode modifies a decklist. PostgreSQL is optional and must be configured via
environment variables; no credentials are stored in this script.
"""

from __future__ import annotations

import os
import sqlite3
import subprocess
import sys
from pathlib import Path


DB = Path('/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db')
LOREHOLD_DECK_ID = 6


def connect() -> sqlite3.Connection:
    con = sqlite3.connect(DB)
    con.row_factory = sqlite3.Row
    return con


def pg(sql_q: str) -> list[list[str]]:
    password = os.environ.get('PGPASSWORD')
    if not password:
        return []
    host = os.environ.get('PGHOST', '143.198.230.247')
    port = os.environ.get('PGPORT', '5433')
    user = os.environ.get('PGUSER', 'postgres')
    dbname = os.environ.get('PGDATABASE', 'halder')
    try:
        r = subprocess.run(
            ['psql', '-h', host, '-p', port, '-U', user, '-d', dbname, '-t', '-A', '-F', '|', '-c', sql_q],
            capture_output=True,
            text=True,
            timeout=30,
            env=os.environ.copy(),
        )
        if r.returncode != 0:
            print('PG source skipped: psql returned non-zero status')
            return []
        return [line.split('|') for line in r.stdout.strip().split('\n') if line.strip()]
    except Exception as e:
        print(f'PG source skipped: {e}')
        return []


def ensure_table(con: sqlite3.Connection) -> None:
    con.execute('''CREATE TABLE IF NOT EXISTS wincon_catalog (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        wincon_name TEXT,
        wincon_type TEXT,
        cards_required TEXT,
        speed_score INTEGER DEFAULT 5,
        resilience_score INTEGER DEFAULT 5,
        stealth_score INTEGER DEFAULT 5,
        consistency_score INTEGER DEFAULT 5,
        total_score INTEGER DEFAULT 0,
        mana_required INTEGER,
        turns_to_win INTEGER,
        how_it_wins TEXT,
        weaknesses TEXT,
        protection_needed TEXT,
        tested INTEGER DEFAULT 0,
        available INTEGER DEFAULT 0,
        win_rate REAL,
        discovered_at TEXT DEFAULT (datetime('now'))
    )''')


def lorehold_enriched_deck_count(con: sqlite3.Connection) -> int:
    return con.execute('''
        SELECT COUNT(DISTINCT ld.id)
        FROM learned_decks ld
        JOIN card_deck_analysis cda ON cda.deck_id = ld.id
        WHERE lower(ld.commander) LIKE '%lorehold%'
          AND cda.enriched = 1
    ''').fetchone()[0]


def score_for_card(con: sqlite3.Connection, name: str) -> tuple[int, int, int, int]:
    row = con.execute('''
        SELECT AVG(speed_score), AVG(resilience_score), AVG(stealth_score), AVG(wincon_total_score)
        FROM card_deck_analysis cda
        JOIN learned_decks ld ON ld.id = cda.deck_id
        WHERE lower(ld.commander) LIKE '%lorehold%'
          AND cda.enriched = 1
          AND cda.role_in_deck = 'wincon'
          AND lower(cda.card_name) = lower(?)
    ''', (name,)).fetchone()
    speed = int(round(row[0] or 5))
    resilience = int(round(row[1] or 5))
    stealth = int(round(row[2] or 5))
    total = int(round(row[3] or (speed + resilience + stealth)))
    if total <= 0:
        total = speed + resilience + stealth
    return speed, resilience, stealth, total


def upsert_wincon(con: sqlite3.Connection, name: str, wincon_type: str, cards_required: str, how_it_wins: str,
                  speed: int = 5, resilience: int = 5, stealth: int = 5, total: int = 15) -> bool:
    existing = con.execute('SELECT id FROM wincon_catalog WHERE lower(wincon_name)=lower(?)', (name,)).fetchone()
    if existing:
        con.execute('''UPDATE wincon_catalog
            SET wincon_type=?, cards_required=?, how_it_wins=?, speed_score=?, resilience_score=?,
                stealth_score=?, consistency_score=?, total_score=?
            WHERE id=?''',
            (wincon_type, cards_required, how_it_wins, speed, resilience, stealth, 5, total, existing['id']))
        return False
    con.execute('''INSERT INTO wincon_catalog
        (wincon_name, wincon_type, cards_required, how_it_wins, speed_score, resilience_score,
         stealth_score, consistency_score, total_score)
        VALUES (?, ?, ?, ?, ?, ?, ?, 5, ?)''',
        (name, wincon_type, cards_required, how_it_wins, speed, resilience, stealth, total))
    return True


def hunter() -> None:
    con = connect()
    ensure_table(con)
    print('# Wincon Hunter Script')
    before = con.execute('SELECT COUNT(*) FROM wincon_catalog').fetchone()[0]
    inserted = 0
    updated = 0

    pg_rows = pg("SELECT card_name, score FROM card_role_scores WHERE role='wincon' AND bracket_scope='any' ORDER BY score DESC LIMIT 100")
    for row in pg_rows[:50]:
        if len(row) < 2:
            continue
        name = row[0].strip()
        try:
            total = max(1, int(float(row[1]) * 3))
        except Exception:
            total = 15
        if upsert_wincon(con, name, 'wincon', name, f'PG wincon score={row[1]}', 5, 5, 5, total):
            inserted += 1
        else:
            updated += 1

    deck_count = lorehold_enriched_deck_count(con)
    threshold = 3 if deck_count >= 10 else 2
    rows = con.execute('''
        SELECT cda.card_name, COUNT(DISTINCT cda.deck_id) AS cnt
        FROM card_deck_analysis cda
        JOIN learned_decks ld ON ld.id = cda.deck_id
        WHERE cda.role_in_deck = 'wincon'
          AND cda.enriched = 1
          AND lower(ld.commander) LIKE '%lorehold%'
        GROUP BY cda.card_name
        HAVING cnt >= ?
        ORDER BY cnt DESC, cda.card_name
        LIMIT 50
    ''', (threshold,)).fetchall()
    for row in rows:
        name = row['card_name']
        cnt = row['cnt']
        speed, resilience, stealth, total = score_for_card(con, name)
        msg = f'Used in {cnt}/{deck_count} enriched Lorehold decks'
        if upsert_wincon(con, name, 'spellslinger', name, msg, speed, resilience, stealth, total):
            inserted += 1
        else:
            updated += 1

    con.commit()
    after = con.execute('SELECT COUNT(*) FROM wincon_catalog').fetchone()[0]
    print(f'before={before} after={after} inserted={inserted} updated={updated} lorehold_enriched_decks={deck_count} threshold={threshold}')
    con.close()


def parse_cards_required(cards_req: str) -> list[str]:
    return [cn.strip().strip('[]"\' ') for cn in (cards_req or '').split(',') if cn.strip().strip('[]"\' ')]


def tester() -> None:
    con = connect()
    ensure_table(con)
    rows = con.execute('SELECT id, wincon_name, cards_required, total_score FROM wincon_catalog').fetchall()
    tested = 0
    changed = 0
    for row in rows:
        missing = []
        for cn in parse_cards_required(row['cards_required']):
            col = con.execute('SELECT quantity FROM user_collection WHERE lower(card_en)=lower(?)', (cn,)).fetchone()
            in_deck = con.execute('SELECT COUNT(*) FROM deck_cards WHERE deck_id=? AND lower(card_name)=lower(?)', (LOREHOLD_DECK_ID, cn)).fetchone()[0]
            if not ((col and col['quantity'] > 0) or in_deck > 0):
                missing.append(cn)
        card_count = max(1, len(parse_cards_required(row['cards_required'])))
        avail = 1 if not missing else (0.5 if len(missing) < card_count else 0)
        old = con.execute('SELECT tested, available, weaknesses FROM wincon_catalog WHERE id=?', (row['id'],)).fetchone()
        weaknesses = f'Missing: {", ".join(missing)}' if missing else None
        if old['tested'] != 1 or old['available'] != avail or old['weaknesses'] != weaknesses:
            changed += 1
        con.execute('UPDATE wincon_catalog SET tested=1, available=?, weaknesses=? WHERE id=?', (avail, weaknesses, row['id']))
        tested += 1
    con.commit()
    print('# Wincon Tester Script')
    print(f'tested={tested} changed={changed} availability: 1=owned/deck, 0.5=partial, 0=missing')
    for row in con.execute('SELECT wincon_name,total_score,tested,available FROM wincon_catalog ORDER BY total_score DESC, wincon_name LIMIT 12'):
        print(f"- {row['wincon_name']}: score={row['total_score']} tested={row['tested']} available={row['available']}")
    con.close()


def selected_packages(con: sqlite3.Connection) -> list[sqlite3.Row]:
    fast = con.execute('''SELECT * FROM wincon_catalog WHERE available >= 1 AND speed_score >= 5 AND total_score > 0
        ORDER BY total_score DESC LIMIT 3''').fetchall()
    resilient = con.execute('''SELECT * FROM wincon_catalog WHERE available >= 1 AND resilience_score >= 6 AND total_score > 0
        ORDER BY total_score DESC LIMIT 3''').fetchall()
    stealth = con.execute('''SELECT * FROM wincon_catalog WHERE available >= 0.5 AND stealth_score >= 5 AND total_score > 0
        ORDER BY total_score DESC LIMIT 3''').fetchall()
    selected = []
    seen = set()
    for group in [fast, resilient, stealth]:
        for row in group:
            if row['wincon_name'] not in seen:
                selected.append(row)
                seen.add(row['wincon_name'])
                break
    return selected


def builder() -> None:
    con = connect()
    ensure_table(con)
    selected = selected_packages(con)
    print('# Wincon Builder Script')
    print('Selected package candidates:')
    for row in selected:
        print(f"- {row['wincon_name']} ({row['wincon_type']}): total={row['total_score']} speed={row['speed_score']} resilience={row['resilience_score']} stealth={row['stealth_score']} available={row['available']}")
    if not selected:
        print('- none: run hunter/tester first or add imported Lorehold decks with enriched wincon roles')
    print('No decklist is modified by this cron; it only emits candidates for Oracle review.')
    con.close()


def oracle() -> None:
    con = connect()
    ensure_table(con)
    selected = selected_packages(con)
    total = con.execute('SELECT COUNT(*) FROM wincon_catalog').fetchone()[0]
    available = con.execute('SELECT COUNT(*) FROM wincon_catalog WHERE available >= 1').fetchone()[0]
    print('# Wincon Oracle Script')
    print('Decision: keep current decklist; emit deterministic wincon priorities for review.')
    print(f'available_wincons={available} total_wincons={total}')
    print('Selected priorities:')
    labels = ['fastest', 'most_resilient', 'stealthiest']
    for label, row in zip(labels, selected):
        print(f"- {label}: {row['wincon_name']} ({row['wincon_type']}) total={row['total_score']} speed={row['speed_score']} resilience={row['resilience_score']} stealth={row['stealth_score']}")
        print(f"  cards={row['cards_required']}")
        if row['protection_needed']:
            print(f"  protection={row['protection_needed']}")
    unavailable = con.execute('''SELECT wincon_name,total_score,available FROM wincon_catalog
        WHERE available < 1 AND total_score > 0 ORDER BY total_score DESC LIMIT 5''').fetchall()
    if unavailable:
        print('Unavailable high-score packages to avoid recommending as immediate swaps:')
        for row in unavailable:
            print(f"- {row['wincon_name']}: total={row['total_score']} available={row['available']}")
    con.close()


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else 'all'
    if mode == 'hunter':
        hunter()
    elif mode == 'tester':
        tester()
    elif mode == 'builder':
        builder()
    elif mode == 'oracle':
        oracle()
    elif mode == 'all':
        hunter()
        tester()
        builder()
    else:
        raise SystemExit('Usage: wincon_pipeline.py [hunter|tester|builder|oracle|all]')


if __name__ == '__main__':
    main()
