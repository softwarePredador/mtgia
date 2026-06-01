#!/usr/bin/env python3
"""Deterministic Lorehold wincon pipeline for Hermes cron jobs.

The agent prompts were producing reports that did not match knowledge.db. This
script keeps the cron outputs tied to actual SQLite writes and schema checks.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "scripts" / "knowledge.db"
DECK_ID = 6
COMMANDER = "Lorehold, the Historian"


SEED_WINCONS = [
    {
        "wincon_name": "Approach + Topdeck",
        "wincon_type": "alternate",
        "cards_required": ["Approach of the Second Sun", "Scroll Rack", "Penance"],
        "speed_score": 6,
        "resilience_score": 5,
        "stealth_score": 1,
        "consistency_score": 8,
        "mana_required": 14,
        "turns_to_win": 8,
        "how_it_wins": "Cast Approach once, manipulate topdeck, cast it again.",
        "weaknesses": "Telegraphed after first cast; vulnerable to counters and exile.",
        "protection_needed": "Grand Abolisher, Silence, Boros Charm",
    },
    {
        "wincon_name": "Storm Herd + Akroma's Will",
        "wincon_type": "token",
        "cards_required": ["Storm Herd", "Akroma's Will"],
        "speed_score": 3,
        "resilience_score": 6,
        "stealth_score": 3,
        "consistency_score": 7,
        "mana_required": 14,
        "turns_to_win": 10,
        "how_it_wins": "Create Pegasus army, then give evasion/protection for lethal combat.",
        "weaknesses": "High mana requirement; weak without life total and combat step.",
        "protection_needed": "Akroma's Will, Teferi's Protection, anti-wipe effects",
    },
    {
        "wincon_name": "Mizzix's Mastery Overload",
        "wincon_type": "spellslinger",
        "cards_required": ["Mizzix's Mastery", "Faithless Looting"],
        "speed_score": 4,
        "resilience_score": 6,
        "stealth_score": 6,
        "consistency_score": 6,
        "mana_required": 8,
        "turns_to_win": 9,
        "how_it_wins": "Overload Mastery with a stocked graveyard to recast payoff spells.",
        "weaknesses": "Graveyard hate and counterspells stop the line.",
        "protection_needed": "Grand Abolisher, Silence, graveyard protection",
    },
    {
        "wincon_name": "Worldfire + Floating Mana",
        "wincon_type": "reset",
        "cards_required": ["Worldfire"],
        "speed_score": 2,
        "resilience_score": 7,
        "stealth_score": 5,
        "consistency_score": 5,
        "mana_required": 9,
        "turns_to_win": 11,
        "how_it_wins": "Resolve Worldfire with floating mana or delayed damage source.",
        "weaknesses": "Extremely expensive; table-hostile; requires precise sequencing.",
        "protection_needed": "Counter protection and mana burst",
    },
    {
        "wincon_name": "Rite of Dragoncaller",
        "wincon_type": "spellslinger",
        "cards_required": ["Rite of the Dragoncaller"],
        "speed_score": 5,
        "resilience_score": 4,
        "stealth_score": 6,
        "consistency_score": 7,
        "mana_required": 5,
        "turns_to_win": 8,
        "how_it_wins": "Turn repeated spells into Dragon tokens and pressure the table.",
        "weaknesses": "Permanent-based engine; folds to removal before payoff turn.",
        "protection_needed": "Lightning Greaves, Swiftfoot Boots, Boros Charm",
    },
    {
        "wincon_name": "Rise of the Eldrazi",
        "wincon_type": "big_mana",
        "cards_required": ["Rise of the Eldrazi"],
        "speed_score": 2,
        "resilience_score": 9,
        "stealth_score": 4,
        "consistency_score": 9,
        "mana_required": 12,
        "turns_to_win": 11,
        "how_it_wins": "Resolve a hard-to-answer haymaker and chain the extra turn/card draw swing.",
        "weaknesses": "Requires large mana burst and can be stranded in hand.",
        "protection_needed": "Ramp density and counter protection",
    },
    {
        "wincon_name": "Fiery Emancipation + Damage",
        "wincon_type": "big_mana",
        "cards_required": ["Fiery Emancipation", "Guttersnipe"],
        "speed_score": 3,
        "resilience_score": 6,
        "stealth_score": 7,
        "consistency_score": 6,
        "mana_required": 9,
        "turns_to_win": 9,
        "how_it_wins": "Multiply incidental spell damage into lethal table damage.",
        "weaknesses": "Expensive enchantment plus fragile damage source.",
        "protection_needed": "Creature protection and enchantment protection",
    },
    {
        "wincon_name": "Underworld Breach Combo",
        "wincon_type": "combo",
        "cards_required": ["Underworld Breach", "Lion's Eye Diamond", "Brain Freeze"],
        "speed_score": 8,
        "resilience_score": 8,
        "stealth_score": 7,
        "consistency_score": 4,
        "mana_required": 3,
        "turns_to_win": 3,
        "how_it_wins": "Loop Breach resources into deterministic storm/mill lethal.",
        "weaknesses": "Requires off-plan cEDH pieces and loses to graveyard hate.",
        "protection_needed": "Silence effects and graveyard protection",
    },
]


def connect() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


def ensure_schema(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS wincon_catalog (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            wincon_name TEXT,
            wincon_type TEXT,
            cards_required TEXT,
            speed_score INTEGER,
            resilience_score INTEGER,
            stealth_score INTEGER,
            consistency_score INTEGER,
            total_score INTEGER,
            mana_required INTEGER,
            turns_to_win INTEGER,
            how_it_wins TEXT,
            weaknesses TEXT,
            protection_needed TEXT,
            tested INTEGER DEFAULT 0,
            available REAL DEFAULT 0,
            win_rate REAL,
            discovered_at TEXT DEFAULT (datetime('now'))
        )
        """
    )
    cols = {row[1] for row in conn.execute("PRAGMA table_info(wincon_catalog)")}
    required = {
        "wincon_name",
        "wincon_type",
        "cards_required",
        "speed_score",
        "resilience_score",
        "stealth_score",
        "consistency_score",
        "total_score",
        "mana_required",
        "turns_to_win",
        "how_it_wins",
        "weaknesses",
        "protection_needed",
        "tested",
        "available",
    }
    missing = sorted(required - cols)
    if missing:
        raise RuntimeError(f"wincon_catalog missing required columns: {', '.join(missing)}")
    conn.execute(
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_wincon_catalog_name ON wincon_catalog(wincon_name)"
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS run_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            run_date TEXT,
            source_used TEXT,
            commander_analyzed TEXT,
            decks_analyzed INTEGER,
            insights_found INTEGER,
            discrepancies_found INTEGER,
            status TEXT,
            duration_seconds INTEGER,
            error_message TEXT
        )
        """
    )


def card_names(conn: sqlite3.Connection, table: str, column: str, where: str = "") -> set[str]:
    try:
        sql = f"SELECT {column} FROM {table} {where}"
        return {row[0].strip().lower() for row in conn.execute(sql) if row[0]}
    except sqlite3.Error:
        return set()


def availability(cards: list[str], collection: set[str], deck: set[str]) -> float:
    if not cards:
        return 0.0
    owned = sum(1 for card in cards if card.lower() in collection or card.lower() in deck)
    if owned == len(cards):
        return 1.0
    if owned:
        return 0.5
    return 0.0


def log_run(conn: sqlite3.Connection, source: str, status: str, insights: int, discrepancies: int = 0, error: str | None = None) -> None:
    conn.execute(
        """
        INSERT INTO run_log (
            run_date, source_used, commander_analyzed, decks_analyzed,
            insights_found, discrepancies_found, status, duration_seconds, error_message
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            datetime.now(timezone.utc).isoformat(),
            source,
            COMMANDER,
            1,
            insights,
            discrepancies,
            status,
            0,
            error,
        ),
    )


def run_hunter(conn: sqlite3.Connection) -> None:
    ensure_schema(conn)
    before = conn.execute("SELECT COUNT(*) FROM wincon_catalog").fetchone()[0]
    inserted = 0
    updated = 0
    for seed in SEED_WINCONS:
        total = seed["speed_score"] + seed["resilience_score"] + seed["stealth_score"] + seed["consistency_score"]
        cards_json = json.dumps(seed["cards_required"], ensure_ascii=True)
        existing = conn.execute(
            "SELECT id FROM wincon_catalog WHERE wincon_name = ?", (seed["wincon_name"],)
        ).fetchone()
        params = (
            seed["wincon_name"],
            seed["wincon_type"],
            cards_json,
            seed["speed_score"],
            seed["resilience_score"],
            seed["stealth_score"],
            seed["consistency_score"],
            total,
            seed["mana_required"],
            seed["turns_to_win"],
            seed["how_it_wins"],
            seed["weaknesses"],
            seed["protection_needed"],
        )
        if existing:
            conn.execute(
                """
                UPDATE wincon_catalog
                SET wincon_type=?, cards_required=?, speed_score=?, resilience_score=?,
                    stealth_score=?, consistency_score=?, total_score=?, mana_required=?,
                    turns_to_win=?, how_it_wins=?, weaknesses=?, protection_needed=?
                WHERE wincon_name=?
                """,
                params[1:] + (seed["wincon_name"],),
            )
            updated += 1
        else:
            conn.execute(
                """
                INSERT INTO wincon_catalog (
                    wincon_name, wincon_type, cards_required, speed_score,
                    resilience_score, stealth_score, consistency_score, total_score,
                    mana_required, turns_to_win, how_it_wins, weaknesses, protection_needed
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                params,
            )
            inserted += 1
    after = conn.execute("SELECT COUNT(*) FROM wincon_catalog").fetchone()[0]
    log_run(conn, "wincon-hunter-script", "ok", inserted + updated)
    conn.commit()
    print("# Wincon Hunter Script")
    print(f"before={before} after={after} inserted={inserted} updated={updated}")
    print("source=deterministic seed + current SQLite schema")


def run_tester(conn: sqlite3.Connection) -> None:
    ensure_schema(conn)
    collection = card_names(conn, "user_collection", "card_en", "WHERE quantity > 0")
    deck = card_names(conn, "deck_cards", "card_name", f"WHERE deck_id={DECK_ID}")
    rows = list(conn.execute("SELECT * FROM wincon_catalog ORDER BY total_score DESC, id ASC"))
    changed = 0
    for row in rows:
        try:
            cards = json.loads(row["cards_required"] or "[]")
        except json.JSONDecodeError:
            cards = []
        avail = availability(cards, collection, deck)
        if row["tested"] != 1 or row["available"] != avail:
            conn.execute(
                "UPDATE wincon_catalog SET tested=1, available=? WHERE id=?",
                (avail, row["id"]),
            )
            changed += 1
    log_run(conn, "wincon-tester-script", "ok", changed)
    conn.commit()
    print("# Wincon Tester Script")
    print(f"tested={len(rows)} changed={changed}")
    print("availability: 1=owned/deck, 0.5=partial, 0=missing")
    for row in conn.execute(
        "SELECT wincon_name, total_score, tested, available FROM wincon_catalog ORDER BY total_score DESC, id ASC LIMIT 8"
    ):
        print(f"- {row['wincon_name']}: score={row['total_score']} tested={row['tested']} available={row['available']}")


def run_builder(conn: sqlite3.Connection) -> None:
    ensure_schema(conn)
    rows = list(
        conn.execute(
            """
            SELECT wincon_name, wincon_type, total_score, speed_score, resilience_score,
                   stealth_score, available, cards_required
            FROM wincon_catalog
            WHERE tested = 1
            ORDER BY available DESC, total_score DESC, resilience_score DESC, id ASC
            LIMIT 5
            """
        )
    )
    if not rows:
        log_run(conn, "wincon-builder-script", "silent", 0, error="No tested wincons")
        conn.commit()
        print("[SILENT]")
        return
    best_speed = max(rows, key=lambda row: (row["speed_score"], row["available"], row["total_score"]))
    best_resilience = max(rows, key=lambda row: (row["resilience_score"], row["available"], row["total_score"]))
    best_stealth = max(rows, key=lambda row: (row["stealth_score"], row["available"], row["total_score"]))
    selected = []
    seen = set()
    for row in [best_speed, best_resilience, best_stealth]:
        if row["wincon_name"] not in seen:
            selected.append(row)
            seen.add(row["wincon_name"])
    log_run(conn, "wincon-builder-script", "ok", len(selected))
    conn.commit()
    print("# Wincon Builder Script")
    print("Selected package candidates:")
    for row in selected:
        print(
            f"- {row['wincon_name']} ({row['wincon_type']}): total={row['total_score']} "
            f"speed={row['speed_score']} resilience={row['resilience_score']} "
            f"stealth={row['stealth_score']} available={row['available']}"
        )
    print("No decklist is modified by this cron; it only emits candidates for Oracle review.")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["hunter", "tester", "builder"])
    args = parser.parse_args()
    with connect() as conn:
        if args.mode == "hunter":
            run_hunter(conn)
        elif args.mode == "tester":
            run_tester(conn)
        else:
            run_builder(conn)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
