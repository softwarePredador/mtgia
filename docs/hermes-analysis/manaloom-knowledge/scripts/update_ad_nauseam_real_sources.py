#!/usr/bin/env python3
"""Update Ad Nauseam Game Changer analysis using only cited real sources."""
import os
import sqlite3
from datetime import date

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "knowledge.db")
CARD = "Ad Nauseam"
TODAY = date.today().isoformat()

why_lines = []
why_lines.append("Ad Nauseam is a Game Changer because its official oracle text converts life total directly into an arbitrarily large number of cards at instant speed: 'Reveal the top card of your library and put that card into your hand. You lose life equal to its mana value. You may repeat this process any number of times.' Source: Scryfall API search q=!\"Ad Nauseam\" (2026-05-27).")
why_lines.append("")
why_lines.append("Scryfall confirms the card is legal in Commander, has mana cost {3}{B}{B}, mana value 5, type Instant, EDHREC rank 1312, USD price 16.21, and game_changer=true. That official Game Changer flag is the hard evidence that it belongs in the Commander Game Changer bucket; no internal MTG knowledge is used for that classification.")
why_lines.append("")
why_lines.append("EDHREC's live card page reports 'Top commanders and EDH deck recommendations based on 105,733 Ad Nauseam decks.' The same page shows extremely high inclusion in specific partner shells: Kraum, Ludevic's Opus // Tymna the Weaver at 77.99% of 11,217 decks (8,748 decks), and Rograkh, Son of Rohgahh // Silas Renn, Seeker Adept at 88.12% of 8,107 decks (7,144 decks). This is real usage evidence that Ad Nauseam is not a generic black draw spell; it concentrates in optimized commander shells that can exploit a large hand immediately.")
why_lines.append("")
why_lines.append("EDHREC also lists Ad Nauseam's 'High Lift Cards' as Summoner's Pact, Rain of Filth, Grinding Station, City of Traitors, and Dark Sphere, and its Game Changer co-occurrences include Demonic Tutor, Underworld Breach, Rhystic Study, Thassa's Oracle, and Force of Will. Those EDHREC co-occurrence panels show the surrounding ecosystem: fast mana, tutors, breach/combo, and free interaction. The card's impact is therefore structural: it rewards low-curve shells that can turn one resolved instant into enough cards to assemble a protected win.")
why_lines.append("")
why_lines.append("cEDH Decklist Database provides independent cEDH context: its Rograkh Silas Turbo Naus entry is explicitly titled 'Rograkh Silas Turbo Naus' and links to Moxfield lists. The linked Moxfield API data confirms Ad Nauseam is present in multiple public cEDH Rograkh/Silas lists, including '[Primer] cEDH Rog Grixis Turbo' (135,239 views; autoBracket 4) and '[cEDH] Rograkh Silas Storm Combo' (177,057 views; autoBracket 4). This verifies the cEDH role with real deck artifacts rather than assumptions.")
why_gc = "\n".join(why_lines)

notes_lines = []
notes_lines.append(f"Research date: {TODAY}")
notes_lines.append("Primary source: Scryfall API https://api.scryfall.com/cards/search?q=!%22Ad%20Nauseam%22&unique=cards")
notes_lines.append("Scryfall facts: game_changer=true; type_line=Instant; mana_cost={3}{B}{B}; cmc=5.0; Commander legality=legal; edhrec_rank=1312; price_usd=16.21; oracle text copied into why_game_changer.")
notes_lines.append("EDHREC source: https://edhrec.com/cards/ad-nauseam")
notes_lines.append("EDHREC facts: page meta description says recommendations are based on 105,733 Ad Nauseam decks; Top Commanders panel shows Kraum/Tymna 77.99% of 11,217 decks (8,748) and Rograkh/Silas 88.12% of 8,107 decks (7,144).")
notes_lines.append("EDHREC co-occurrence facts: High Lift Cards panel includes Summoner's Pact, Rain of Filth, Grinding Station, City of Traitors, Dark Sphere; Game Changers panel includes Rhystic Study, Thassa's Oracle, Underworld Breach, Demonic Tutor, Force of Will.")
notes_lines.append("Official bracket evidence: Scryfall search page for is:gamechanger !\"Ad Nauseam\" says the card is on the Commander Game Changer list; the Scryfall API also exposes game_changer=true. The requested mtgcommander.net/index.php/brackets/ URL returned a WordPress 'Page not found' page in this cron environment, so specific bracket-page text is NAO VERIFICADO from that URL.")
notes_lines.append("cEDH source: https://cedh-decklist-database.com/ page contains a Rograkh Silas Turbo Naus entry with text 'Turbo Ad Nauseam Rograkh Silas Storm Combo'.")
notes_lines.append("Moxfield API verification from cEDH DDB links: https://moxfield.com/decks/yRsS18tYsE-jVgqmK7_Z0w '[Primer] cEDH Rog Grixis Turbo' includes Ad Nauseam, 135,239 views, autoBracket 4; https://moxfield.com/decks/79hYZQUBdUaA9xD8zLX4vQ '[cEDH] Rograkh Silas Storm Combo' includes Ad Nauseam, 177,057 views, autoBracket 4.")
notes_lines.append("ManaLoom code verification: running tagCardForBracket() from server/lib/edh_bracket_policy.dart with Ad Nauseam's Scryfall oracle text returned no categories (NO_CATEGORIES). Therefore manaloom_detected=0 and manaloom_bracket_category=card_advantage_gap.")
notes_lines.append("Impact level set to 9/10: justified by Scryfall official game_changer=true, EDHREC 105,733-deck usage corpus, high inclusion in Kraum/Tymna and Rograkh/Silas shells, and verified cEDH DDB/Moxfield Turbo Naus deck artifacts.")
notes = "\n".join(notes_lines)

conn = sqlite3.connect(DB_PATH)
conn.execute(
    """
    UPDATE game_changers
    SET why_game_changer = ?,
        impact_level = ?,
        impact_category = ?,
        manaloom_bracket_category = ?,
        manaloom_detected = ?,
        restricted_bracket = ?,
        notes = ?
    WHERE card_name = ?
    """,
    (why_gc, 9, "card_advantage", "card_advantage_gap", 0, 3, notes, CARD),
)
conn.commit()
row = conn.execute(
    "SELECT card_name, impact_level, impact_category, manaloom_bracket_category, manaloom_detected, why_game_changer IS NOT NULL, notes IS NOT NULL FROM game_changers WHERE card_name = ?",
    (CARD,),
).fetchone()
remaining = conn.execute(
    "SELECT COUNT(*) FROM game_changers WHERE why_game_changer IS NULL OR why_game_changer = ''"
).fetchone()[0]
conn.close()
print(f"Updated {row[0]} | impact={row[1]} | category={row[2]} | bracket_cat={row[3]} | detected={row[4]} | has_why={row[5]} | has_notes={row[6]}")
print(f"Remaining unanalyzed: {remaining}")
