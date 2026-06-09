import re, json as _json, sys, sqlite3
from datetime import datetime, timezone

db = sqlite3.connect("/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db")

# Register missing commanders
learned_cmds = db.execute("""
    SELECT DISTINCT ld.commander FROM learned_decks ld 
    WHERE ld.commander != '' 
    AND NOT EXISTS (SELECT 1 FROM commanders c WHERE LOWER(c.name) = LOWER(ld.commander))
""").fetchall()

for (cmd,) in learned_cmds:
    db.execute("""
        INSERT INTO commanders (name, color_identity, first_analyzed, last_analyzed, deck_count, insight_count)
        VALUES (?, '', ?, ?, 1, 0)
    """, (cmd, datetime.now(timezone.utc).isoformat(), datetime.now(timezone.utc).isoformat()))
    print("REGISTERED:", cmd)

db.commit()

# Also register decks for commanders without target decks
for (cmd,) in learned_cmds:
    # Create a deck entry if commander has no deck
    has_deck = db.execute(
        "SELECT id FROM decks WHERE commander_id = (SELECT id FROM commanders WHERE LOWER(name) = LOWER(?))", (cmd,)
    ).fetchone()
    if not has_deck:
        db.execute("""
            INSERT INTO decks (commander_id, deck_name, total_cards, total_lands, archetype)
            SELECT id, ? || ' Battle Simulator Deck', 100, 0, 'battle-simulator'
            FROM commanders WHERE LOWER(name) = LOWER(?)
        """, (cmd, cmd))
        print("DECK CREATED:", cmd)

db.commit()
db.close()
print("DONE")
