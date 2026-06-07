#!/usr/bin/env python3
"""Update Thassa's Oracle entry in game_changers table with full analysis."""
import sqlite3
import json

DB = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"

why_game_changer = """
Thassa's Oracle is the defining win condition of cEDH — a 2-mana creature that, when combined with Demonic Consultation or Tainted Pact, wins the game on the spot at instant speed for a combined 4 mana and 2 cards. It is the most compact, efficient, and resilient combo wincon in the format's history.

WHY IT IS A GAME CHANGER:

1. UNCONDITIONAL ONE-CARD WINCON (with Consult/Pact): Unlike most combos that require 2-3 permanents on board, Thassa's Oracle + Demonic Consultation wins from an empty board state at instant speed for UUBB + 2 life. The opponent has no opportunity to interact with the combo except via counterspells or Stifle effects — no creature removal, board wipes, or graveyard hate helps once Thoracle resolves. The only window is when Consultation/Pact is on the stack but Oracle hasn't resolved yet.

2. FORMAT-WARPING PRESSURE: The existence of Thoracle forces every competitive deck to run 4-8 counterspells minimum just to answer the combo. It singlehandedly defines the cEDH interaction ceiling: any deck that cannot interact at instant speed on turns 2-3 is nonviable. Daze, Force of Will, Pact of Negation, Flusterstorm — these are mandatory not because they are generically good, but because Thoracle exists. The card has more influence on the cEDH metagame shape than any other single card.

3. DEVOTION AS ANTI-HATE: The "devotion to blue" clause means that in a format where most interaction is blue (counterspells, cantrips, Rhystic), Thoracle often wins even when the opponent has 30+ cards in their library. It's effectively blindspot-proof. The player does not need to count cards or track library size — if devotion is high enough (which it almost always is in a blue build), the combo simply wins.

4. RESILIENCE VIA PLAY PATTERNS: The combo works through multiple lines:
   - Demonic Consultation naming a card not in the library → exile entire library → Thoracle ETB wins
   - Tainted Pact → same effect, but can be stopped by opponents who also run the combo
   - Underworld Breach + Lion's Eye Diamond + Brain Freeze → mill self → Thoracle wins
   - Hermit Druid → fill the graveyard → Thoracle (in the uncommon UG shell)
   - Inverter of Truth + Thoracle (pioneer-style, less common in Commander)
   Each line has different vulnerabilities, making Thoracle the most flexible cEDH wincon ever printed.

5. IMPACT ON DECKBUILDING: The combo demands only 2-3 slots (Oracle + 1-2 tutors) in a 99-card deck. This means every UB/x deck can effortlessly include a 2-card "I win" button without compromising its primary gameplan. The opportunity cost is essentially zero — a 1/3 for UU that incidentally scries is not dead even if drawn without the combo. This zero-opportunity-cost inclusion is unprecedented in Commander and is the defining characteristic of a Game Changer.

6. COMMANDER-SPECIFIC SYNERGIES: Thassa's Oracle has natural synergy with commanders that play from the graveyard (Muldrotha, Tasigur, Gitrog) or generate card advantage (Kess, Malcolm, Rograkh/Silas). The most dominant cEDH shells (Blue Farm, RogSi) are built around finding and protecting Thoracle as the primary wincon, with secondary wincons (Breach lines) as backup.

7. BRACKET RESTRICTION: Restricted to bracket 3+ (max 3 per deck in bracket 3, unlimited in bracket 4). This restricts it to high-power casual and competitive tables, precisely where the threat density of interaction is high enough to police it. In bracket 1-2 (no Game Changers), the card is banned because casual tables lack the interaction density to answer a 4-mana instant win.

EDHREC DATA (from tournament artifacts at meta_deck_intelligence_2026-04-27):
- Present in 16 out of 35+ tournament decks across 7 separate artifact files
- Appears in diverse commanders: Scion of the Ur-Dragon, Norman Osborn, and others across multiple tournaments
- Always paired with Demonic Consultation, Tainted Pact, or Underworld Breach lines
- Average price: $23.03 (Scryfall, 2026-05-26)
""".strip()

notes = """
MANA_LOOM DETECTION STATUS (validated against code):
- Detected: Yes (manaloom_detected=1)
- Bracket category: infiniteCombo
- Tagged via: _infiniteCombo card list in edh_bracket_policy.dart (Thassa's Oracle is in the curated list)
- Functional role (classifyOptimizationFunctionalRole): Unfortunately falls to "other" or "scry" — the system does not have a wincon tag, so Thoracle is NOT classified as a wincon. It may show as "other" in the functional deck analysis, meaning the AI optimizer sees it as a dead card unless it's in the infiniteCombo bracket list.
- Bracket system: Detected correctly as infiniteCombo (bracket 1-2 = 0 allowed, bracket 3 = 2, bracket 4 = 99)
- GAP: While bracket detection works, the card analysis layer does not identify Thassa's Oracle as a wincon. This means optimization suggestions might flag it for removal — a critical user-facing risk.

ALTERNATIVES:
- Laboratory Maniac (CMC 3, 1UU, 2/2): The original "win if you draw from empty library" effect. Requires actually drawing a card, which is harder to achieve reliably. Vulnerable to instant-speed removal on draw trigger.
- Jace, Wielder of Mysteries (CMC 4, 1UUU, 4 loyalty): Like Lab Man but with self-mill ability and higher loyalty. CMC 4 is much slower.
- Inverter of Truth (CMC 4, 1UUBB, 6/6 flyer): Inverts library and graveyard. Combos with Oracle but costs 4 more mana total.

None of these alternatives approach Thoracle's efficiency. Lab Man sees cEDH play as backup, but the Thoracle line is strictly superior in speed and mana efficiency.

EDHREC rank: 411 (high for a 2-drop — most cEDH-only cards rank lower due to lower casual inclusion)
Prices: $23.03 USD (Scryfall, 2026-05-26)
Legal: Commander (legal in bracket 3+), banned in Standard/Historic
""".strip()

conn = sqlite3.connect(DB)
conn.execute("""
UPDATE game_changers 
SET why_game_changer = ?, notes = ? 
WHERE card_name = ?
""", (why_game_changer, notes, "Thassa's Oracle"))
conn.commit()

# Verify
row = conn.execute("SELECT card_name, why_game_changer IS NOT NULL as has_why, notes IS NOT NULL as has_notes FROM game_changers WHERE card_name = ?", ("Thassa's Oracle",)).fetchone()
print(f"Update result: {row['card_name']} | why_game_changer: {row['has_why']} | notes: {row['has_notes']}")

# Show remaining gaps
remaining = conn.execute("SELECT card_name, impact_level FROM game_changers WHERE why_game_changer IS NULL ORDER BY impact_level DESC").fetchall()
print(f"\nStill missing why_game_changer: {len(remaining)} cards")
for r in remaining[:5]:
    print(f"  Next: {r['card_name']} (impact: {r['impact_level']})")

conn.close()