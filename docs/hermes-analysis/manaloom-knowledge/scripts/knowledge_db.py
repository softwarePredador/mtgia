#!/usr/bin/env python3
"""
ManaLoom Commander Knowledge Database — SQLite backend.
Gerencia o banco de conhecimento estruturado sobre Commander deckbuilding.

Uso:
  python3 knowledge_db.py --create
  python3 knowledge_db.py --insert-deck < deck.json
  python3 knowledge_db.py --query-commanders
  python3 knowledge_db.py --query-decks [commander]
  python3 knowledge_db.py --stats
"""

import sqlite3
import json
import sys
import os
from datetime import datetime, timezone

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'knowledge.db')

SCHEMA = """
CREATE TABLE IF NOT EXISTS commanders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    partner_name TEXT,
    color_identity TEXT,
    archetype TEXT,
    bracket INTEGER DEFAULT 4,
    primer_url TEXT,
    first_analyzed TEXT,
    last_analyzed TEXT,
    deck_count INTEGER DEFAULT 0,
    insight_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    base_url TEXT,
    type TEXT DEFAULT 'tournament'
);

CREATE TABLE IF NOT EXISTS decks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_deck_key TEXT UNIQUE,
    commander_id INTEGER REFERENCES commanders(id),
    source_id INTEGER REFERENCES sources(id),
    deck_name TEXT,
    player_name TEXT,
    placement TEXT,
    tournament_date TEXT,
    tournament_url TEXT,
    archetype TEXT,
    bracket INTEGER DEFAULT 4,
    total_lands INTEGER,
    avg_cmc REAL,
    ramp_count INTEGER,
    draw_count INTEGER,
    removal_count INTEGER,
    tutor_count INTEGER,
    board_wipe_count INTEGER,
    protection_count INTEGER,
    recursion_count INTEGER,
    wincon_count INTEGER,
    engine_count INTEGER,
    total_cards INTEGER DEFAULT 100,
    analysis_md_path TEXT,
    analysis_date TEXT,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS deck_cards (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    deck_id INTEGER REFERENCES decks(id),
    card_name TEXT NOT NULL,
    quantity INTEGER DEFAULT 1,
    functional_tag TEXT,
    tag_confidence REAL,
    is_commander INTEGER DEFAULT 0,
    is_partner INTEGER DEFAULT 0,
    cmc REAL,
    type_line TEXT,
    oracle_text TEXT,
    UNIQUE(deck_id, card_name)
);

CREATE TABLE IF NOT EXISTS card_analyses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    deck_card_id INTEGER REFERENCES deck_cards(id),
    mana_loom_tag TEXT,
    expected_tag TEXT,
    tag_match INTEGER DEFAULT 1,
    psychology_why TEXT,
    psychology_fear_resolves TEXT,
    psychology_opportunity TEXT,
    psychology_tradeoff TEXT,
    psychology_staple_or_personal INTEGER,
    synergy_with_commander TEXT,
    common_alternatives TEXT,
    game_timing TEXT,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    evidence TEXT,
    confidence REAL DEFAULT 0.5,
    first_discovered TEXT,
    last_confirmed TEXT,
    confirmation_count INTEGER DEFAULT 1,
    tags TEXT
);

CREATE TABLE IF NOT EXISTS insights (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    deck_id INTEGER REFERENCES decks(id),
    insight_text TEXT NOT NULL,
    category TEXT DEFAULT 'general',
    impact TEXT DEFAULT 'medium',
    is_new INTEGER DEFAULT 1
);

CREATE TABLE IF NOT EXISTS discrepancies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    deck_card_id INTEGER REFERENCES deck_cards(id),
    card_name TEXT NOT NULL,
    mana_loom_tag TEXT,
    expected_tag TEXT,
    difference_description TEXT,
    impact TEXT DEFAULT 'medium',
    resolved INTEGER DEFAULT 0,
    discovered_date TEXT
);

CREATE TABLE IF NOT EXISTS tag_accuracy (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tag_name TEXT NOT NULL,
    correct_count INTEGER DEFAULT 0,
    total_count INTEGER DEFAULT 0,
    false_positive INTEGER DEFAULT 0,
    false_negative INTEGER DEFAULT 0,
    last_updated TEXT,
    UNIQUE(tag_name)
);

CREATE TABLE IF NOT EXISTS synergies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    card_a TEXT NOT NULL,
    card_b TEXT NOT NULL,
    synergy_type TEXT,
    strength TEXT DEFAULT 'medium',
    commander_context TEXT,
    first_documented TEXT,
    UNIQUE(card_a, card_b, commander_context)
);

CREATE TABLE IF NOT EXISTS psychology_profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    deck_id INTEGER REFERENCES decks(id),
    player_style TEXT,
    risk_tolerance TEXT,
    budget_level TEXT,
    focus_primary TEXT,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS vocabulary (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    term TEXT UNIQUE NOT NULL,
    definition TEXT NOT NULL,
    category TEXT DEFAULT 'general',
    first_seen TEXT,
    source TEXT
);

CREATE TABLE IF NOT EXISTS game_changers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    card_name TEXT UNIQUE NOT NULL,
    cmc REAL,
    type_line TEXT,
    mana_cost TEXT,
    oracle_text TEXT,
    price_usd REAL,
    impact_level INTEGER DEFAULT 5,
    impact_category TEXT,
    why_game_changer TEXT,
    manaloom_bracket_category TEXT,
    manaloom_detected INTEGER DEFAULT 0,
    restricted_bracket INTEGER DEFAULT 3,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS deck_themes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    theme_name TEXT UNIQUE NOT NULL,
    category TEXT,
    description TEXT,
    bracket_min INTEGER DEFAULT 1,
    bracket_max INTEGER DEFAULT 4,
    difficulty TEXT DEFAULT 'medium',
    core_cards_json TEXT,
    enabler_count_min INTEGER,
    payoff_count_min INTEGER,
    role_targets_json TEXT,
    compatible_themes_json TEXT,
    conflicting_themes_json TEXT,
    signature_commanders_json TEXT,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS theme_detection_rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    theme_id INTEGER REFERENCES deck_themes(id),
    rule_type TEXT DEFAULT 'oracle',
    pattern TEXT NOT NULL,
    weight REAL DEFAULT 1.0,
    card_name TEXT,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS run_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_date TEXT NOT NULL,
    source_used TEXT,
    commander_analyzed TEXT,
    decks_analyzed INTEGER DEFAULT 0,
    insights_found INTEGER DEFAULT 0,
    discrepancies_found INTEGER DEFAULT 0,
    status TEXT DEFAULT 'ok',
    duration_seconds INTEGER,
    error_message TEXT
);
"""


def get_conn():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


def cmd_create():
    conn = get_conn()
    conn.executescript(SCHEMA)
    conn.commit()
    conn.close()
    tables = ["commanders", "sources", "decks", "deck_cards", "card_analyses",
              "patterns", "insights", "discrepancies", "tag_accuracy", "synergies",
              "psychology_profiles", "vocabulary", "run_log"]
    print(f"Database created: {DB_PATH}")
    print(f"Tables ({len(tables)}): {', '.join(tables)}")


def cmd_stats():
    conn = get_conn()
    stats = {}
    tables = ["commanders", "decks", "deck_cards", "card_analyses", "patterns",
              "insights", "discrepancies", "synergies", "psychology_profiles", "run_log"]
    for table in tables:
        try:
            row = conn.execute(f"SELECT COUNT(*) as c FROM {table}").fetchone()
            stats[table] = row["c"]
        except Exception:
            stats[table] = -1
    conn.close()
    print(json.dumps(stats, indent=2))


def cmd_query_commanders():
    conn = get_conn()
    rows = conn.execute("""
        SELECT c.name, c.archetype, c.deck_count, c.insight_count,
               c.last_analyzed, c.color_identity
        FROM commanders c
        ORDER BY c.deck_count DESC
    """).fetchall()
    conn.close()
    result = [dict(r) for r in rows]
    print(json.dumps(result, indent=2, default=str))


def cmd_query_decks(commander=None):
    conn = get_conn()
    if commander:
        rows = conn.execute("""
            SELECT d.deck_name, d.player_name, d.placement, d.tournament_date,
                   d.archetype, d.avg_cmc, d.analysis_date, s.name as source_name
            FROM decks d
            JOIN commanders c ON d.commander_id = c.id
            JOIN sources s ON d.source_id = s.id
            WHERE c.name = ?
            ORDER BY d.analysis_date DESC
        """, (commander,)).fetchall()
    else:
        rows = conn.execute("""
            SELECT d.deck_name, c.name as commander, d.placement, d.tournament_date,
                   d.archetype, d.avg_cmc, s.name as source_name
            FROM decks d
            JOIN commanders c ON d.commander_id = c.id
            JOIN sources s ON d.source_id = s.id
            ORDER BY d.analysis_date DESC
            LIMIT 20
        """).fetchall()
    conn.close()
    result = [dict(r) for r in rows]
    print(json.dumps(result, indent=2, default=str))


def cmd_insert_deck():
    data = json.load(sys.stdin)
    conn = get_conn()
    now = datetime.now(timezone.utc).isoformat()

    commander_name = data.get("commander", "Unknown")
    arch = data.get("archetype", "unknown")

    conn.execute("""
        INSERT INTO commanders (name, archetype, color_identity, first_analyzed,
                                last_analyzed, deck_count, insight_count)
        VALUES (?, ?, ?, ?, ?, 1, 0)
        ON CONFLICT(name) DO UPDATE SET
            last_analyzed = excluded.last_analyzed,
            deck_count = deck_count + 1,
            archetype = COALESCE(excluded.archetype, commanders.archetype)
    """, (commander_name, arch, data.get("color_identity"), now, now))
    commander_id = conn.execute("SELECT id FROM commanders WHERE name = ?",
                                (commander_name,)).fetchone()["id"]

    source_name = data.get("source_name", "unknown")
    conn.execute("""
        INSERT INTO sources (name, base_url, type) VALUES (?, ?, ?)
        ON CONFLICT(name) DO NOTHING
    """, (source_name, data.get("source_url"), data.get("source_type", "tournament")))
    source_id = conn.execute("SELECT id FROM sources WHERE name = ?",
                             (source_name,)).fetchone()["id"]

    conn.execute("""
        INSERT INTO decks (commander_id, source_id, deck_name, player_name, placement,
                          tournament_date, tournament_url, archetype, bracket,
                          total_lands, avg_cmc, ramp_count, draw_count, removal_count,
                          tutor_count, board_wipe_count, protection_count, recursion_count,
                          wincon_count, engine_count, total_cards, analysis_md_path,
                          analysis_date, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        commander_id, source_id, data.get("deck_name"), data.get("player_name"),
        data.get("placement"), data.get("tournament_date"), data.get("tournament_url"),
        data.get("archetype"), data.get("bracket", 4),
        data.get("total_lands"), data.get("avg_cmc"),
        data.get("ramp_count", 0), data.get("draw_count", 0), data.get("removal_count", 0),
        data.get("tutor_count", 0), data.get("board_wipe_count", 0),
        data.get("protection_count", 0), data.get("recursion_count", 0),
        data.get("wincon_count", 0), data.get("engine_count", 0),
        data.get("total_cards", 100), data.get("analysis_md_path"), now,
        data.get("notes")
    ))
    deck_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]

    insight_count = 0
    discrepancy_count = 0

    for card in data.get("cards", []):
        conn.execute("""
            INSERT INTO deck_cards (deck_id, card_name, quantity, functional_tag,
                                   tag_confidence, is_commander, is_partner, cmc,
                                   type_line, oracle_text)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            deck_id, card["name"], card.get("quantity", 1), card.get("functional_tag"),
            card.get("tag_confidence"), card.get("is_commander", 0),
            card.get("is_partner", 0), card.get("cmc"), card.get("type_line"),
            card.get("oracle_text")
        ))
        deck_card_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]

        analysis = card.get("analysis")
        if analysis:
            conn.execute("""
                INSERT INTO card_analyses (deck_card_id, mana_loom_tag, expected_tag,
                                          tag_match, psychology_why, psychology_fear_resolves,
                                          psychology_opportunity, psychology_tradeoff,
                                          psychology_staple_or_personal, synergy_with_commander,
                                          common_alternatives, game_timing, notes)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                deck_card_id,
                analysis.get("mana_loom_tag"),
                analysis.get("expected_tag"),
                analysis.get("tag_match", 1),
                analysis.get("psychology_why"),
                analysis.get("psychology_fear"),
                analysis.get("psychology_opportunity"),
                analysis.get("psychology_tradeoff"),
                analysis.get("staple_or_personal"),
                analysis.get("synergy"),
                analysis.get("alternatives"),
                analysis.get("game_timing"),
                analysis.get("notes")
            ))

            expected = analysis.get("expected_tag")
            if expected:
                tag_match = 1 if analysis.get("tag_match", 1) else 0
                conn.execute("""
                    INSERT INTO tag_accuracy (tag_name, correct_count, total_count, last_updated)
                    VALUES (?, ?, 1, ?)
                    ON CONFLICT(tag_name) DO UPDATE SET
                        correct_count = correct_count + ?,
                        total_count = total_count + 1,
                        last_updated = excluded.last_updated
                """, (expected, tag_match, now, tag_match))

    for insight in data.get("insights", []):
        conn.execute("""
            INSERT INTO insights (deck_id, insight_text, category, impact, is_new)
            VALUES (?, ?, ?, ?, 1)
        """, (deck_id, insight["text"], insight.get("category", "general"),
              insight.get("impact", "medium")))
        insight_count += 1

    for disc in data.get("discrepancies", []):
        conn.execute("""
            INSERT INTO discrepancies (card_name, mana_loom_tag, expected_tag,
                                      difference_description, impact, discovered_date)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (disc["card"], disc.get("mana_loom_tag"), disc.get("expected_tag"),
              disc.get("description"), disc.get("impact", "medium"), now))
        discrepancy_count += 1

    if insight_count > 0:
        conn.execute("UPDATE commanders SET insight_count = insight_count + ? WHERE id = ?",
                     (insight_count, commander_id))

    conn.execute("""
        INSERT INTO run_log (run_date, source_used, commander_analyzed, decks_analyzed,
                            insights_found, discrepancies_found, status)
        VALUES (?, ?, ?, 1, ?, ?, 'ok')
    """, (now, source_name, commander_name, insight_count, discrepancy_count))

    conn.commit()
    conn.close()
    deck_label = data.get("deck_name", "unknown")
    print(f"Deck '{deck_label}' ({commander_name}) inserted.")
    print(f"  Cards: {len(data.get('cards', []))}")
    print(f"  Insights: {insight_count}")
    print(f"  Discrepancies: {discrepancy_count}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "--create":
        cmd_create()
    elif cmd == "--stats":
        cmd_stats()
    elif cmd == "--query-commanders":
        cmd_query_commanders()
    elif cmd == "--query-decks":
        commander = sys.argv[2] if len(sys.argv) > 2 else None
        cmd_query_decks(commander)
    elif cmd == "--insert-deck":
        cmd_insert_deck()
    elif cmd == "--pipeline":
        if not os.path.exists(DB_PATH):
            cmd_create()
        cmd_stats()
        cmd_query_commanders()
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)