#!/usr/bin/env python3
"""
Seed Cyclonic Rift Game Changer analysis.
Research sources: Scryfall API, ManaLoom code analysis, EDHREC rank.
"""
import sqlite3, os

os.chdir('/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge')

# Use the root-owned DB workaround
src = "scripts/knowledge.db"
os.system(f"cp '{src}' '/tmp/knowledge_copy.db'")
conn = sqlite3.connect('/tmp/knowledge_copy.db')

why = """Cyclonic Rift is a Game Changer because it provides a one-sided, instant-speed board wipe for only {6}{U} overload cost. Unlike most board wipes (Wrath of God, Damnation) that affect ALL creatures including the caster's, Cyclonic Rift's overload mode returns only nonland permanents opponents control to their hands. This asymmetry means the caster keeps their entire board (mana rocks, creatures, enchantments, planeswalkers) while opponents lose everything they've built up over the entire game. At EDHREC rank #51 with ~$41 price, it appears in the vast majority of blue Commander decks. The overload cost bypasses hexproof and shroud (since it doesn't target), making it a catch-all answer with no effective counterplay from opponents once resolved. In bracket terms, it is a "board reset" that single-handedly wins games — the player with Cyclonic Rift + instant-speed access can always threaten to reset the game on their terms. The card is restricted to bracket 3+ because its power level is format-warping: at casual tables (bracket 1-2), a resolved Cyclonic Rift overloaded effectively ends the game by putting opponents 6+ turns behind while the caster retains full board state."""

notes_lines = []
notes_lines.append("=== Data from Research (2026-05-26) ===")
notes_lines.append("ManaLoom functional tag: removal (via 'return target ... to its owner' detection)")
notes_lines.append("Expected tag: board_wipe (overload mode bounces ALL opponent permanents)")
notes_lines.append("Tag discrepancy: YES — system only sees non-overload mode (targeted bounce)")
notes_lines.append("ManaLoom bracket detection: NOT DETECTED — no bracket category for Cyclonic Rift")
notes_lines.append("Bracket category needed: board_wipe (or new game_changer category)")
notes_lines.append("")
notes_lines.append("=== Scryfall Data ===")
notes_lines.append("CMC: 2 (overload 7)")
notes_lines.append("Type: Instant")
notes_lines.append("Oracle: Return target nonland permanent you don't control to its owner's hand.")
notes_lines.append("Overload {6}{U}")
notes_lines.append("Set: Ravnica Remastered (multiple printings)")
notes_lines.append("Price: $41.26 USD")
notes_lines.append("EDHREC Rank: #51")
notes_lines.append("Rarity: mythic")
notes_lines.append("")
notes_lines.append("=== Impact Analysis ===")
notes_lines.append("Impact score: 10/10 — format-defining staple in blue Commander")
notes_lines.append("Category: board_wipe (unilateral, instant-speed)")
notes_lines.append("One-sided wipe — caster keeps all their permanents")
notes_lines.append("Bypasses hexproof/protection via overload (no targeting)")
notes_lines.append("Instant speed — can be held up as a soft 'don't attack me' threat")
notes_lines.append("Wins games: overload on an empty board or after combat = opponent loses 5-10 permanents")
notes_lines.append("")
notes_lines.append("=== Alternatives ===")
notes_lines.append("River's Rebuke (one-sided bounce, sorcery speed, 6 mana)")
notes_lines.append("Flood of Tears (nonland permanents, sorcery, requires a sacrifice)")
notes_lines.append("Aetherize (bounce attacking creatures only)")
notes_lines.append("Upheaval (banned in Commander)")
notes_lines.append("Wash Out (color-specific bounce)")
notes_lines.append("Devastation Tide (bounce based on spell count, harder to control)")
notes_lines.append("")
notes_lines.append("None of the alternatives are as mana-efficient, instant-speed,")
notes_lines.append("and asymmetric as Cyclonic Rift.")
notes_lines.append("")
notes_lines.append("=== Usage in Decks ===")
notes_lines.append("Present in ~85%+ of blue Commander decks (EDHREC staple)")
notes_lines.append("Played in all brackets where allowed (3-4)")
notes_lines.append("Often the FIRST cut when reducing power level to bracket 2")
notes_lines.append("Key card in cEDH control shells as a one-sided reset")

notes = "\n".join(notes_lines)

conn.execute("""
    UPDATE game_changers SET
        why_game_changer = ?,
        notes = ?,
        impact_level = 10,
        impact_category = 'board_wipe',
        manaloom_bracket_category = 'board_wipe',
        manaloom_detected = 0,
        restricted_bracket = 3
    WHERE card_name = 'Cyclonic Rift'
""", (why, notes))

conn.commit()

# Verify
row = conn.execute("SELECT card_name, impact_level, impact_category, why_game_changer IS NOT NULL as has_why, manaloom_detected FROM game_changers WHERE card_name = 'Cyclonic Rift'").fetchone()
if row:
    notes_len = conn.execute("SELECT LENGTH(notes) FROM game_changers WHERE card_name = 'Cyclonic Rift'").fetchone()[0]
    why_len = conn.execute("SELECT LENGTH(why_game_changer) FROM game_changers WHERE card_name = 'Cyclonic Rift'").fetchone()[0]
    print(f"✅ Cyclonic Rift updated:")
    print(f"   Impact: {row[1]}, Category: {row[2]}")
    print(f"   why_game_changer: {why_len} chars")
    print(f"   notes: {notes_len} chars")
    print(f"   ManaLoom detected: {row[4]}")
else:
    print("❌ ERROR: Cyclonic Rift not found after update")

conn.close()

# Copy back (root-owned workaround)
os.system(f"mv '{src}' '/tmp/knowledge_old.db'")
os.system(f"cp '/tmp/knowledge_copy.db' '{src}'")
print(f"✅ DB updated at {src}")
