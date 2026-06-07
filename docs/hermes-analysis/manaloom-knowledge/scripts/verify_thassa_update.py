#!/usr/bin/env python3
"""Verify Thassa's Oracle update in the DB"""
import sqlite3

conn = sqlite3.connect("/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db")
conn.row_factory = sqlite3.Row

# Verify updated GC
row = conn.execute("SELECT card_name, why_game_changer IS NOT NULL as has_why, why_game_changer IS NOT NULL as has_notes, impact_level FROM game_changers WHERE card_name LIKE ?", ("%Thassa%",)).fetchone()
print("=== Thassa's Oracle Update ===")
print(f"  Card: {row['card_name']}")
print(f"  Has why_game_changer: {row['has_why']}")
print(f"  Impact level: {row['impact_level']}")

# Count updates
completed = conn.execute("SELECT COUNT(*) FROM game_changers WHERE why_game_changer IS NOT NULL").fetchone()[0]
missing = conn.execute("SELECT COUNT(*) FROM game_changers WHERE why_game_changer IS NULL").fetchone()[0]
total = conn.execute("SELECT COUNT(*) FROM game_changers").fetchone()[0]
print(f"\n  Total GCs: {total}")
print(f"  Completed: {completed}")
print(f"  Remaining: {missing}")

# Show remaining top 5
print("\n  Next 5 to analyze:")
remaining = conn.execute("SELECT card_name, impact_level FROM game_changers WHERE why_game_changer IS NULL ORDER BY impact_level DESC, card_name ASC").fetchall()
for r in remaining[:5]:
    print(f"    {r['card_name']} (impact: {r['impact_level']})")

# Check why_game_changer length
row2 = conn.execute("SELECT LENGTH(why_game_changer) as char_count FROM game_changers WHERE card_name LIKE ?", ("%Thassa%",)).fetchone()
print(f"\n  Why text length: {row2['char_count']} chars")

conn.close()