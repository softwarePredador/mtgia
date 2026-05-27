#!/usr/bin/env python3
"""Update run_log in knowledge.db for this scout execution."""
import sqlite3, os, json, datetime

DB_DIR = os.path.dirname(os.path.abspath(__file__))
conn = sqlite3.connect(os.path.join(DB_DIR, "knowledge.db"))
cur = conn.cursor()

# Check run_log schema
cur.execute("PRAGMA table_info(run_log)")
cols = cur.fetchall()
print("=== run_log schema ===")
for c in cols:
    print(f"  {c}")

# Check what's in run_log
cur.execute("SELECT * FROM run_log ORDER BY id DESC LIMIT 5")
rows = cur.fetchall()
print("\n=== Recent run_log entries ===")
for r in rows:
    print(f"  {r}")

conn.close()
