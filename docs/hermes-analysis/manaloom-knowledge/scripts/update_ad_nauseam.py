#!/usr/bin/env python3
"""Update Ad Nauseam Game Changer analysis in SQLite."""
import sqlite3, os

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'knowledge.db')
conn = sqlite3.connect(DB_PATH)

why_gc_lines = []
why_gc_lines.append("Ad Nauseam is the defining card advantage engine of cEDH, converting life total into raw cards at instant speed.")
why_gc_lines.append("For 5 mana (3BB), it reveals cards from the top of the library one by one, putting each into the hand")
why_gc_lines.append("while the player loses life equal to the card's mana value -- repeatable any number of times.")
why_gc_lines.append("")
why_gc_lines.append("WHY IT DISTORTS THE GAME:")
why_gc_lines.append("1. Instant-speed card advantage: Unlike Necropotence (sorcery speed, exiled draw, skip draw step),")
why_gc_lines.append("   Ad Nauseam happens instantly and can be played at the end of an opponent's turn or in response to")
why_gc_lines.append("   threats. The cards go directly to hand with no restrictions.")
why_gc_lines.append("")
why_gc_lines.append("2. Prizes low-CMC decks: In cEDH, decks built with average CMC 1.5-2.0 can draw 25-40 cards off a single")
why_gc_lines.append("   Ad Nauseam, losing only 30-50 life -- trivial when the same deck can win that turn or the next.")
why_gc_lines.append("   This actively WARPS the format by punishing any deck that includes higher-CMC cards.")
why_gc_lines.append("")
why_gc_lines.append("3. Enables the Ad Nauseam + Thassa's Oracle line: The standard cEDH gameplan is:")
why_gc_lines.append("   cast Ad Nauseam -> draw into Thassa's Oracle + Demonic Consultation -> win.")
why_gc_lines.append("   This is the most resilient combo line because Ad Nauseam finds both pieces AND")
why_gc_lines.append("   the protection (Force of Will, Pact of Negation) in one shot.")
why_gc_lines.append("")
why_gc_lines.append("4. Bypasses traditional card advantage metrics: While a typical Commander deck considers")
why_gc_lines.append("   8-12 draw sources healthy, Ad Nauseam alone provides more card advantage than any")
why_gc_lines.append("   other 10 draw spells combined. A single resolved Ad Nauseam ends the game.")
why_gc_lines.append("")
why_gc_lines.append("5. Creates a who resolves Ad Nauseam first meta: Many cEDH games revolve around who can")
why_gc_lines.append("   resolve and protect their Ad Nauseam. This creates a warped game state where opponents")
why_gc_lines.append("   must hold up countermagic specifically for this one card from turn 4 onward.")
why_gc = "\n".join(why_gc_lines)

notes_lines = []
notes_lines.append("Ad Nauseam is a quintessential cEDH (bracket 4) card. Rarely played below bracket 4")
notes_lines.append("due to the life loss punishing higher-CMC casual decks.")
notes_lines.append("")
notes_lines.append("CLASSIFICATION: card_advantage (not detected by current ManaLoom bracket system)")
notes_lines.append("")
notes_lines.append("MANALOOM DETECTION: The current bracket system (fastMana, tutor, freeInteraction,")
notes_lines.append("extraTurns, infiniteCombo categories) does NOT detect Ad Nauseam. It needs a")
notes_lines.append("dedicated card_advantage category or a curated game_changer category.")
notes_lines.append("")
notes_lines.append("DECK TYPES:")
notes_lines.append("- Primary: cEDH turbo/combo decks aiming to win on turns 2-4")
notes_lines.append("- Archetypes: Razakats, Thoracle Consult, Dargo/Tevesh, Tymna/Kraum, Grixis combo")
notes_lines.append("- Does NOT fit: casual decks (too much life loss), stax (no synergy)")
notes_lines.append("")
notes_lines.append("ALTERNATIVES:")
notes_lines.append("- Necropotence (slower, sorcery speed, but also insane card advantage)")
notes_lines.append("- Peer into the Abyss (13 mana vs 5, but less life loss per card)")
notes_lines.append("- Midnight Clock (slow, cumulative)")
notes_lines.append("- Secret Rendezvous (opponent draws too)")
notes_lines.append("")
notes_lines.append("KEY INTERACTIONS:")
notes_lines.append("- Angel's Grace (prevents life loss = draw entire deck)")
notes_lines.append("- Sickening Dreams (discard black cards for damage after drawing)")
notes_lines.append("- Each opponent draws a significant number of cards")
notes_lines.append("- Ad Nauseam into Sickening Dreams is a known cEDH kill")
notes_lines.append("")
notes_lines.append("BRACKETS:")
notes_lines.append("- Bracket 1-2: BANNED (Game Changer)")
notes_lines.append("- Bracket 3: Max 3 Game Changers (Ad Nauseam consumes one slot)")
notes_lines.append("- Bracket 4: Unlimited")
notes_lines.append("- In bracket 3, Ad Nauseam is generally bad (higher-CMC decks lose too much life)")
notes_lines.append("")
notes_lines.append("PRICE: $16 non-foil, $75 foil")
notes_lines.append("")
notes_lines.append("REAL DECK EXAMPLES (from project artifacts):")
notes_lines.append("- Scion of the Ur-Dragon (1st place, cedh-arcanum-sanctorum-57) - 5c combo")
notes_lines.append("- Norman Osborn // Green Goblin (4th place, same tournament) - Grixis combo")
notes_lines.append("- Malcolm, Keen-Eyed Navigator + Vial Smasher (5th place) - Temur pirates")
notes_lines.append("- Kraum + Tymna (8th place) - 4c control/combo")
notes_lines.append("")
notes_lines.append("All four decks share: Thassa's Oracle, Demonic Consultation, Necropotence,")
notes_lines.append("underworld breach, low-CMC curve, heavy ritual package. Ad Nauseam is the")
notes_lines.append("primary card advantage engine that ties the combo together.")
notes = "\n".join(notes_lines)

conn.execute('''
    UPDATE game_changers SET 
        why_game_changer = ?,
        impact_level = 9,
        manaloom_bracket_category = 'card_advantage',
        manaloom_detected = 0,
        notes = ?
    WHERE card_name = 'Ad Nauseam'
''', (why_gc, notes))

conn.commit()

row = conn.execute('SELECT card_name, impact_level, manaloom_detected FROM game_changers WHERE card_name = "Ad Nauseam"').fetchone()
print(f"Updated: {row[0]} | impact={row[1]} | detected={row[2]}")

remaining = conn.execute('SELECT COUNT(*) FROM game_changers WHERE why_game_changer IS NULL OR why_game_changer = ""').fetchone()[0]
print(f"Remaining unanalyzed: {remaining}")

conn.close()
print("Done!")