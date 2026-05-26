#!/usr/bin/env python3
import sqlite3, json

conn = sqlite3.connect("scripts/knowledge.db")
conn.row_factory = sqlite3.Row
row = conn.execute("""
    SELECT card_name, cmc, impact_level, impact_category, 
           CASE WHEN why_game_changer IS NOT NULL THEN 1 ELSE 0 END as has_analysis,
           LENGTH(COALESCE(why_game_changer, '')) as why_len,
           CASE WHEN notes IS NOT NULL THEN 1 ELSE 0 END as has_notes,
           LENGTH(COALESCE(notes, '')) as notes_len,
           manaloom_detected, manaloom_bracket_category 
    FROM game_changers WHERE card_name = 'Rhystic Study'
""").fetchone()
print("Rhystic Study:", json.dumps(dict(row), indent=2, default=str))

total = conn.execute("SELECT COUNT(*) FROM game_changers").fetchone()[0]
analyzed = conn.execute("SELECT COUNT(*) FROM game_changers WHERE why_game_changer IS NOT NULL AND why_game_changer != ''").fetchone()[0]
print(f"\nTotal GCs: {total}")
print(f"With analysis: {analyzed}")
print(f"Without analysis: {total - analyzed}")
conn.close()