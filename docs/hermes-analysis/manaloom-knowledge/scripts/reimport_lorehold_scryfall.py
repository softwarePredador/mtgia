#!/usr/bin/env python3
"""
Re-import the Lorehold deck using the Scryfall-based classifier.
This replaces the hardcoded build_lorehold_seed.py with proper oracle text classification.
"""
import json, sqlite3, subprocess, sys, os
from datetime import date
from collections import Counter

sys.path.insert(0, "scripts")
from scryfall_classifier import (
    _merge_user_override_tag,
    _ordered_tag_names,
    build_deck_json,
    classify_card,
    fetch_cards,
    infer_functional_card_tags,
    parse_decklist,
)

DECK_TEXT = """
1x Ancient Copper Dragon (clb)
1x Ancient Tomb (eos)
1x Apex of Power (c21) [Pay-offs] 
1x Arcane Signet (mkc) [Ramp] 
1x Archaeomancer's Map (soc)
1x Arid Mesa (mh2)
1x Artist's Talent (blb)
1x Austere Command (m3c) [Pay-offs] 
1x Bender's Waterskin (tla) [Ramp] 
1x Bloodstained Mire (mh3)
1x Boros Charm (fdn) *F* 
1x Boseiju, Who Shelters All (chk)
1x Brass's Bounty (fdn)
1x Call Forth the Tempest (ltc) [Pay-offs] 
1x Cavern of Souls (plci)
1x Claim Jumper (soc)
1x Clifftop Retreat (soc)
1x Command Tower (tdc)
1x Deflecting Palm (mkc)
1x Deflecting Swat (c20) [Interaction] 
1x Desperate Ritual (uma)
1x Dormant Volcano (cm2)
1x Double Vision (ncc)
1x Emeria's Call // Emeria, Shattered Skyclave (znr)
1x Enlightened Tutor (mir) [Tutor] 
1x Fated Clash (fic)
1x Flooded Strand (mh3)
1x Furygale Flocking (soc)
1x Galadriel's Dismissal (ltc)
1x Galvanoth (ddj)
1x Goblin Engineer (h1r) *F* 
1x Goldspan Dragon (soc)
1x Grand Abolisher (big)
1x Hellkite Tyrant (fic)
1x Hexing Squelcher (ecl) [Protection] 
1x Inspiring Vantage (otj)
1x Insurrection (cmm)
1x Jeska's Will (mkc) [Ramp] 
1x Jokulhaups (6ed)
1x Karoo (plst)
1x Kor Haven (nem)
1x Land Tax (soc)
1x Library of Leng (spg) [Top Deck Manipulation] 
1x Lightning Greaves (soc)
1x Longshot, Rebel Bowman (tle)
1x Lorehold, the Historian (sos) *F*  [Commander{top}] 
1x Mizzix's Mastery (otc)
1x Monument to Endurance (dft) [Draw] 
1x Mother of Runes (clb)
8x Mountain (fic) 481 *F* 
1x Obliterate (plst)
1x Olórin's Searing Light (ltc)
1x Orim's Chant (mh3) [Interaction] 
1x Oswald Fiddlebender (afr)
1x Path to Exile (ecc) [Interaction] 
1x Pearl Medallion (mh3)
1x Penance (exo) [Top Deck Manipulation] 
1x Perch Protection (blc)
7x Plains (fic) 478 *F* 
1x Reforge the Soul (inr)
1x Restoration Seminar (sos)
1x Rise of the Eldrazi (cmm) [Pay-offs] 
1x Rite of the Dragoncaller (fdn)
1x Ruby Medallion (mh3) [Ramp] 
1x Sacred Foundry (eoe)
1x Scalding Tarn (zen)
1x Scroll Rack (cmr) [Top Deck Manipulation] 
1x Season of the Bold (blb)
1x Seething Song (arc) [Ramp] 
1x Sensei's Divining Top (ema) [Top Deck Manipulation] 
1x Smothering Tithe (prna) [Ramp] 
1x Sol Ring (ltc) [Ramp] 
1x Storm Herd (scd) [Pay-offs] 
1x Sunbird's Invocation (blc)
1x Sundown Pass (sos)
1x Surge to Victory (soc)
1x Swords to Plowshares (soc)
1x Talisman of Conviction (fic) [Ramp] 
1x Taunt from the Rampart (ltc)
1x Teferi's Protection (2x2)
1x Unexpected Windfall (plst) [Ramp] 
1x Urza's Saga (mh2) *F* 
1x Valakut Awakening // Valakut Stoneforge (plst)
1x Victory Chimes (c21) [Ramp] 
1x Volcanic Vision (dtk) [Pay-offs] 
1x Weathered Wayfarer (ltc)
1x Windswept Heath (mh3)
"""

print("=" * 60)
print("LOREHOLD DECK RE-IMPORT (Scryfall-based classification)")
print("=" * 60)

# Step 1: Parse decklist
print("\n[1/5] Parsing decklist...")
parsed = parse_decklist(DECK_TEXT)
print(f"  Parsed {len(parsed)} card entries")
total_qty = sum(c['qty'] for c in parsed)
total_distinct = len(parsed)
print(f"  Total quantity: {total_qty}, distinct cards: {total_distinct}")

# Step 2: Fetch from Scryfall and classify
print("\n[2/5] Fetching cards from Scryfall and classifying...")
# Use original names (with apostrophes, accents, etc.) for Scryfall
names = [c['name'] for c in parsed]
fetched = fetch_cards(names)
classified = 0
not_classified = 0

for c in parsed:
    nl = c['name'].lower().strip()
    card_data = fetched.get(nl, {})
    if not card_data or card_data.get('object') != 'card':
        # Try without apostrophe
        clean = nl.replace("'", "").replace("ó", "o").replace(",", "")
        card_data = fetched.get(clean, {})
    if card_data and card_data.get('object') == 'card':
        c['_scryfall'] = card_data
        c['_tags'] = infer_functional_card_tags(
            name=card_data.get('name', c['name']),
            type_line=card_data.get('type_line', ''),
            oracle_text=card_data.get('oracle_text', ''),
            cmc=card_data.get('cmc', 0),
        )
        c['_functional_tags_json'] = _ordered_tag_names(c['_tags'])
        c['_tag'] = classify_card(card_data)
        c['_cmc'] = card_data.get('cmc', 0)
        c['_type_line'] = card_data.get('type_line', '')
        classified += 1
    else:
        c['_scryfall'] = {}
        c['_tags'] = []
        c['_functional_tags_json'] = []
        c['_tag'] = 'unknown'
        c['_cmc'] = 0
        c['_type_line'] = ''
        not_classified += 1
        print(f"  ? Not found: {c['name']}")

print(f"  Classified: {classified}, Not found: {not_classified}")

# Step 3: Apply user tag overrides
print("\n[3/5] Applying user tag overrides...")
user_tag_map = {
    'ramp': 'ramp',
    'draw': 'draw',
    'tutor': 'tutor',
    'interaction': 'removal',
    'removal': 'removal',
    'protection': 'protection',
    'pay-offs': 'wincon',
    'payoff': 'wincon',
    'wincon': 'wincon',
    'top deck manipulation': 'engine',
    'topdeck': 'engine',
    'top deck': 'engine',
}
for c in parsed:
    tag_lower = c.get('tag_comment', '').lower()
    override = user_tag_map.get(tag_lower)
    if override:
        old_tag = c.get('_tag', '?')
        if old_tag != override:
            print(f"  Override: {c['name']:35s} {old_tag:15s} -> {override}")
        c['_tag'] = override
        c['_tags'] = _merge_user_override_tag(c.get('_tags', []), override)
        c['_functional_tags_json'] = _ordered_tag_names(c['_tags'])

# Step 4: Build deck JSON
print("\n[4/5] Building deck JSON...")
# Identify commander
commander_name = "Lorehold, the Historian"
commander_card = None
for c in parsed:
    if 'lorehold' in c['name'].lower() and 'historian' in c['name'].lower():
        commander_card = c
        commander_card['_tag'] = 'enabler'
        commander_card['_tags'] = _merge_user_override_tag(
            commander_card.get('_tags', []),
            'enabler',
        )
        commander_card['_functional_tags_json'] = _ordered_tag_names(
            commander_card['_tags'],
        )
        c['_tag'] = 'enabler'
        break

# Build enriched cards
enriched = []
for c in parsed:
    enriched.append({
        'name': c['name'],
        'qty': c['qty'],
        'set_code': c.get('set_code', ''),
        'tag_comment': c.get('tag_comment', ''),
        'functional_tag': c.get('_tag', 'unknown'),
        'functional_tags_json': c.get('_functional_tags_json', []),
        'tags': c.get('_tags', []),
        'cmc': c.get('_cmc', 0),
        'type_line': c.get('_type_line', ''),
        'is_commander': 1 if c == commander_card else 0,
    })

deck = build_deck_json(
    commander_name=commander_name,
    enriched_cards=enriched,
    archetype='spellslinger_big_spells',
    bracket=3,
    deck_name='Lorehold Spellslinger',
    source_name='User provided decklist (Scryfall classified)',
)

# Add insights
deck['insights'] = [
    {'text': 'Deck foca em copy spells + treasures para castar big spells e copia-los com Lorehold + Double Vision + Galvanoth', 'category': 'archetype', 'impact': 'high'},
    {'text': '5 board wipes (Austere Command, Obliterate, Jokulhaups, Fated Clash, Call Forth the Tempest) - no topo do range do profile (3-5)', 'category': 'strategy', 'impact': 'medium'},
    {'text': 'Topdeck manipulation package: Scroll Rack, Sensei Top, Penance, Library of Leng, Land Tax', 'category': 'engine', 'impact': 'high'},
    {'text': 'Classificado via Scryfall oracle text - 29 tags funcionais do ManaLoom', 'category': 'methodology', 'impact': 'info'},
]

print(f"\n  Lands: {deck['total_lands']}")
print(f"  CMC Avg: {deck['avg_cmc']}")
print(f"  Ramp: {deck['ramp_count']}")
print(f"  Draw: {deck['draw_count']}")
print(f"  Removal: {deck['removal_count']}")
print(f"  Board Wipes: {deck['board_wipe_count']}")
print(f"  Protection: {deck['protection_count']}")
print(f"  Wincons: {deck['wincon_count']}")
print(f"  Engine: {deck['engine_count']}")
print(f"  Tutor: {deck['tutor_count']}")
print(f"  Total cards (incl commander): {sum(c['quantity'] for c in deck['cards'])}")

# Step 5: Write seed and insert into DB
print("\n[5/5] Writing seed and inserting into knowledge.db...")
seed_path = 'scripts/seed_lorehold_scryfall.json'
with open(seed_path, 'w') as f:
    json.dump(deck, f, indent=2)
print(f"  Seed written to {seed_path}")

# Insert into knowledge.db
db_path = 'scripts/knowledge.db'
result = subprocess.run(
    ['python3', 'scripts/knowledge_db.py', '--insert-deck'],
    input=json.dumps(deck),
    capture_output=True, text=True, timeout=30
)
print(f"  DB insert: {result.stdout.strip()}")
if result.stderr:
    print(f"  STDERR: {result.stderr}")

# Verify
conn = sqlite3.connect(db_path)
rows = conn.execute("SELECT id, name, deck_count FROM commanders WHERE name LIKE '%Lorehold%'").fetchall()
print(f"  Verified in DB: {rows}")
conn.close()

print("\n" + "=" * 60)
print("DONE! Deck re-imported using Scryfall-based classification.")
print("=" * 60)
