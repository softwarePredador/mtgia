#!/usr/bin/env python3
"""Insert run_log entry for this scout execution."""
import sqlite3, os, datetime

DB_DIR = os.path.dirname(os.path.abspath(__file__))
conn = sqlite3.connect(os.path.join(DB_DIR, "knowledge.db"))
cur = conn.cursor()

now = datetime.datetime.utcnow().isoformat() + "+00:00"

cur.execute("""
    INSERT INTO run_log (run_date, source_used, commander_analyzed, decks_analyzed, insights_found, discrepancies_found, status, duration_seconds)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
""", (
    now,
    "EDHREC Live (7,651 decks) + deep card-by-card compare",
    "Lorehold, the Historian",
    7651,
    4,  # insights: Rise correction, Emeria correction, Improvisation Capstone, Restoration Seminar trend
    3,  # discrepancies: Rise 0%→55%, Emeria 0%→43.5%, Valakut 0%→26.9%
    "ok",
    180
))

conn.commit()
print("Run log entry inserted successfully")
conn.close()
