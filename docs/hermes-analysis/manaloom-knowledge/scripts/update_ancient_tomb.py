#!/usr/bin/env python3
"""
Game Changer Research: Ancient Tomb
Sources: Scryfall (game_changer:true), EDHREC (rank 64, ~827k decks), ManaLoom edh_bracket_policy.dart
"""

import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), 'knowledge.db')

lines = []
lines.append("Ancient Tomb is a Game Changer because it provides 2 colorless mana from a single land drop without summoning sickness, for only 2 life per activation. This is a massive tempo advantage — it effectively gives any deck a free Sol Ring that costs a land slot instead of a spell slot.")
lines.append("")
lines.append("KEY STATS (fontes reais):")
lines.append("- Scryfall (api.scryfall.com): confirmed game_changer=true. Oracle: '{T}: Add {C}{C}. This land deals 2 damage to you.'")
lines.append("- EDHREC rank: 64 (top 64 cards out of all 33k+ cards in Commander — extremely popular)")
lines.append("- EDHREC: ~827,563 decks include Ancient Tomb (from edhrec.com meta description, 2026-05-26)")
lines.append("- Price: $125-126 USD (Scryfall, 2026-05-26)")
lines.append("- Legalities: Legal in Commander, Oathbreaker, Legacy, Vintage. Banned in Brawl, Duel Commander, Historic")
lines.append("")
lines.append("WHY IT'S A GAME CHANGER (analise baseada em fontes reais):")
lines.append("1. Tempo acceleration: A land that taps for {C}{C} on turn 1 enables plays that normally require 3+ mana. A deck with Ancient Tomb on turn 1 can play a 3-drop or two 1-drops while the opponent is on 1 land.")
lines.append("2. Slot efficiency: It accelerates mana without using a spell slot (it's a land). This is unique among fast mana sources — most accelerants (Sol Ring, Mana Crypt, Mana Vault) occupy non-land slots and are vulnerable to artifact removal.")
lines.append("3. Universal: Fits in any deck regardless of color identity. Colorless land means zero color-pie restriction.")
lines.append("4. Hard to interact with: As a land, it's substantially harder to remove than artifact ramp. Most decks run 3-5 land destruction effects (if any), while artifact removal is ubiquitous.")
lines.append("5. Life cost is negligible in Commander: 40 starting life means 2 life per activation is trivial. Even activating it 10 times only costs 20 life — half the starting total. In practice, the tempo gained far outweighs the life lost.")
lines.append("")
lines.append("cEDH CONTEXT:")
lines.append("Ancient Tomb is a staple in cEDH (bracket 4). It appears in virtually every optimized deck regardless of colors because the tempo gain is irreplaceable. The only decks that skip it are those with extremely tight color requirements (e.g., 5-color with heavy pip demands) or budget constraints. At ~$126, it's a significant investment but considered a 'must-have' for competitive play.")
lines.append("")
lines.append("ALTERNATIVAS:")
lines.append("- City of Traitors: Same function, but sacrifices the land after playing a spell. Worse in Commander where games last longer.")
lines.append("- Crystal Vein: Enters tapped and sacrifices. Much worse tempo.")
lines.append("- Sol Ring: Same mana output but costs a spell slot and is an artifact (easier to remove).")
lines.append("- Mana Vault: Costs {1} upfront and doesn't untap naturally. Worse without untap effects.")
lines.append("")
lines.append("BRACKET IMPACT:")
lines.append("Ancient Tomb is restricted by the Commander bracket system as a Game Changer. In ManaLoom's bracket policy (edh_bracket_policy.dart), it's classified as fastMana with limits: B1=1, B2=3, B3=6, B4=99. The official Game Changer limits are stricter: 0 in B1-2, 3 in B3, 99 in B4. ManaLoom's fastMana limits are more permissive than the official Game Changer restriction — this is a known discrepancy.")

why_gc_text = "\n".join(lines)

# Estimate inclusion rate: 827,563 / total EDHREC decks (assuming ~5M+ decks)
# EDHREC tracks millions of decks. With 827k+ mentions across all commanders,
# Ancient Tomb appears in roughly 10-15%+ of all Commander decks

notes_lines = []
notes_lines.append("Fonte: Scryfall api.scryfall.com — game_changer: true, oracle: '{T}: Add {C}{C}. This land deals 2 damage to you.'")
notes_lines.append("Fonte: EDHREC (edhrec.com/cards/ancient-tomb) — EDHREC rank 64, ~827,563 decks, ~$125 USD")
notes_lines.append("Fonte: ManaLoom edh_bracket_policy.dart — detected as fastMana via _fastManaNames + _fastManaLandNames")
notes_lines.append("Fonte: Scryfall api.scryfall.com — 53 official game changers, Ancient Tomb is #5 most popular (by EDHREC rank)")
notes_lines.append("Fonte: official Commander bracket system — restricted as Game Changer (0 B1-2, 3 B3, 99 B4)")
notes_lines.append("ManaLoom bracket category: fastMana. Limits: B1=1, B2=3, B3=6, B4=99")
notes_lines.append("Inclusion rate estimate: ~10-15%+ of all Commander decks (based on 827k / estimated total)")
notes_lines.append("Detected by ManaLoom: YES (in both _fastManaNames and _fastManaLandNames lists)")
notes_lines.append("Manaloom_detected note: Ancient Tomb is double-detected (both as generic fastMana and as fastManaLand), which is intentional but may cause double-counting in some analysis paths")

notes_text = "\n".join(notes_lines)

conn = sqlite3.connect(DB_PATH)
conn.execute('''UPDATE game_changers SET 
    why_game_changer = ?,
    impact_level = 8,
    notes = ?
    WHERE card_name = 'Ancient Tomb' ''',
    (why_gc_text, notes_text))
conn.commit()

# Verify
cursor = conn.execute("SELECT card_name, impact_level, why_game_changer IS NOT NULL as has_why, notes IS NOT NULL as has_notes FROM game_changers WHERE card_name = 'Ancient Tomb'")
row = cursor.fetchone()
print(f"Updated: {row[0]}")
print(f"Impact level: {row[1]}")
print(f"Has why_game_changer: {row[2]}")
print(f"Has notes: {row[3]}")

conn.close()
print("\nDone.")