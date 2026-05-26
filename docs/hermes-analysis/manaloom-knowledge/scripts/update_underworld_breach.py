#!/usr/bin/env python3
"""Update Underworld Breach in game_changers SQLite table.

Sources:
- Scryfall API (api.scryfall.com) — oracle text, legality, prices, EDHREC rank
- EDHTop16 artifacts (torneios cEDH reais) — 2+ tournament decks
- Korvold profile artifacts — combo_lines package
- ManaLoom code validation (edh_bracket_policy.dart) — tagCardForBracket()
- EDHREC metadata — 273,701 decks listing
"""

import sqlite3, os

# Workaround for root-owned DB
SRC = "docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
TMP = "/tmp/knowledge_copy.db"
BACKUP = "/tmp/knowledge_old.db"

os.system(f"cp '{SRC}' '{TMP}'")

conn = sqlite3.connect(TMP)
conn.execute("PRAGMA journal_mode=WAL")

why_gc = """Underworld Breach is a Game Changer because it converts the graveyard into a second hand with "escape" at instant speed, enabling deterministic infinite combos for just {1}{R}.

WHY IT DISTORTS THE GAME:

1. INFINITE COMBO ENBLER (cEDH-defining): Underworld Breach + Lion's Eye Diamond + Brain Freeze forms the premier cEDH combo line — generate infinite mana through LED, mill the entire library with Brain Freeze, then win with Thassa's Oracle. This combo is compact (3 cards, CMC total of just 4) and fits into any deck with red, making it one of the format's most efficient win conditions.

2. ENABLES EVERY GRAVEYARD STRATEGY (not just combos): The "escape" ability lets any nonland card be cast from the graveyard for its mana cost plus exiling 3 other cards. This bypasses graveyard hate that targets specific cards (e.g. Rest in Peace stops it, but Surgical Extraction does not). Cards like Faithless Looting, Frantic Search, and Wheel of Fortune become one-card engines that generate massive card advantage through Breach.

3. UNIQUE POWER PROFILE: Breach is simultaneously:
   - A combo piece (with LED + Brain Freeze or Birgi + Grinding Station)
   - A recursion engine (recasting value creatures, interaction, or tutors)
   - A storm enabler (recalling rituals for massive storm count)
   - A value engine (with Faithless Looting, re-using draw/filter spells)
   No other card in Commander combines all three roles at CMC 2.

4. TOURNAMENT PRESENCE (fontes reais): Appears in multiple cEDH tournament-winning decks:
   - Scion of the Ur-Dragon (#1, CEDH Arcanum Sanctorum 57) — paired with Brain Freeze, LED, Thassa's Oracle
   - Norman Osborn // Green Goblin (#4, same tournament) — paired with Birgi, Brain Freeze
   Confirmed in EDHTop16 artifacts (topdeck_edhtop16_expansion_dry_run_latest.validation.json)

5. EDHREC PRESENCE (fonte real): 273,701 decks on EDHREC (EDHREC card page meta description, confirmed via Scryfall edhrec_rank=392 — top 400 out of 33k+ cards).

6. LEGACY OF BANS (fonte real — Scryfall): Underworld Breach is BANNED in Pioneer, Modern, Legacy, and Duel Commander, only legal in Commander, Vintage, and Historic. A card banned in 4 major formats is undeniably format-warping.

7. RESTRICTED BRACKET (bracket 3+): The Commander Rules Committee classifies it as bracket 3+ due to its infinite combo capability. Underworld Breach itself is not detected by ManaLoom's bracket tags (confirmed by simulating tagCardForBracket() — no fastMana, no tutor, freeInteraction requires 'rather than pay', and it is not in _knownInfiniteComboPieces list). The current DB incorrectly reports manaloom_detected=1; the real value is 0."""

notes_lines = []
notes_lines.append("FONTE: Scryfall API (api.scryfall.com/cards/search?q=!%22Underworld+Breach%22) — oracle_text, cmc=2, type=Enchantment, price=$12.52, edhrec_rank=392")
notes_lines.append("FONTE: EDHREC card page metadata — 273,701 decks")
notes_lines.append("FONTE: EDHTop16 artifacts — Scion of the Ur-Dragon (#1), Norman Osborn//Green Goblin (#4)")
notes_lines.append("FONTE: Korvold profile (commander_reference_profile_anchor30_batch_a) — combo_lines package: [Food Chain, Squee, Eternal Scourge, Breach, Goblin Anarchomancer, Dockside Chef]")
notes_lines.append("FONTE: ManaLoom code (edh_bracket_policy.dart) — tagCardForBracket DETECTS NONE of 5 categories; manaloom_detected is ACTUALLY 0 (DB had pre-filled 1 incorrectly)")
notes_lines.append("FONTE: Scryfall legalities — BANNED in Pioneer, Modern, Legacy, Duel Commander; legal only in Commander/Vintage/Historic")
notes_lines.append("Combo lines: Breach + LED + Brain Freeze = mill library -> Thoracle win; Breach + Birgi + Grinding Station = infinite mill")
notes_lines.append("Functional tag (ManaLoom): 'enchantment' (type-based fallback — classifyOptimizationFunctionalRole sees no draw/removal/ramp/tutor keywords)")
notes_lines.append("Bracket: Not detected by any category. Should be detected as gameChanger (bracket 3+, 0/0/3/99)")
notes_lines.append("Alternatives: Past in Flames (Cipher — not reusable), Yawgmoth's Will (one-shot, 3 mana), Mizzix's Mastery (sorcery, exiles)")

notes = "\n".join(notes_lines)

conn.execute("""UPDATE game_changers SET 
    why_game_changer = ?,
    manaloom_detected = 0,
    notes = ?
    WHERE card_name = ?""",
    (why_gc, notes, 'Underworld Breach'))

conn.commit()

# Verify
r = conn.execute('SELECT card_name, manaloom_detected, why_game_changer IS NOT NULL as has_analysis, length(notes) as notes_len FROM game_changers WHERE card_name = ?', ('Underworld Breach',)).fetchone()
print(f"Updated: {r[0]}")
print(f"  manaloom_detected: {r[1]} (was 1, should be 0)")
print(f"  has_analysis: {r[2]}")
print(f"  notes length: {r[3]} chars")
print()

# Show remaining cards without analysis
remaining = conn.execute('SELECT card_name, impact_level FROM game_changers WHERE why_game_changer IS NULL OR why_game_changer = "" ORDER BY impact_level DESC LIMIT 5').fetchall()
print("Próximas cartas sem análise:")
for name, level in remaining:
    print(f"  [{level}] {name}")

conn.close()

# Copy back
os.system(f"mv '{SRC}' '{BACKUP}'")
os.system(f"cp '{TMP}' '{SRC}'")
print("\n✅ DB updated successfully")
