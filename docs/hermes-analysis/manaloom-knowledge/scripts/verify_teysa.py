#!/usr/bin/env python3
"""Verify the Teysa Karlov analysis in the knowledge DB"""
import sqlite3
conn = sqlite3.connect('/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db')
conn.row_factory = sqlite3.Row

# Check commanders
rows = conn.execute("SELECT name, deck_count, insight_count FROM commanders ORDER BY id").fetchall()
for r in rows:
    print(f"  Commander: {r['name']} - {r['deck_count']} decks, {r['insight_count']} insights")

# Check deck count
cnt = conn.execute("SELECT COUNT(*) as c FROM decks").fetchone()['c']
print(f"\nTotal decks: {cnt}")

# Check Teysa deck
row = conn.execute("""SELECT d.id, d.deck_name, d.total_lands, d.ramp_count, d.draw_count, d.avg_cmc, d.analysis_md_path
    FROM decks d JOIN commanders c ON d.commander_id = c.id
    WHERE c.name = 'Teysa Karlov'""").fetchone()
if row:
    print(f"\nTeysa deck: {dict(row)}")

# Check card count for Teysa
cnt = conn.execute("""SELECT COUNT(*) as c FROM deck_cards dc
    JOIN decks d ON dc.deck_id = d.id
    JOIN commanders c ON d.commander_id = c.id
    WHERE c.name = 'Teysa Karlov'""").fetchone()['c']
print(f"Teysa deck cards: {cnt}")

# Check card analyses count
cnt = conn.execute("""SELECT COUNT(*) as c FROM card_analyses ca
    JOIN deck_cards dc ON ca.deck_card_id = dc.id
    JOIN decks d ON dc.deck_id = d.id
    JOIN commanders c ON d.commander_id = c.id
    WHERE c.name = 'Teysa Karlov'""").fetchone()['c']
print(f"Teysa card analyses: {cnt}")

# Check insights
cnt = conn.execute("""SELECT COUNT(*) as c FROM insights i
    JOIN decks d ON i.deck_id = d.id
    JOIN commanders c ON d.commander_id = c.id
    WHERE c.name = 'Teysa Karlov'""").fetchone()['c']
print(f"Teysa insights: {cnt}")

# Check patterns
cnt = conn.execute("SELECT COUNT(*) as c FROM patterns").fetchone()['c']
print(f"Total patterns: {cnt}")

# Check vocabulary
cnt = conn.execute("SELECT COUNT(*) as c FROM vocabulary").fetchone()['c']
print(f"Total vocabulary: {cnt}")

conn.close()
print("\nVerification complete!")