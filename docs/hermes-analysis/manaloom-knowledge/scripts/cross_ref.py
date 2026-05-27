#!/usr/bin/env python3
"""Complete cross-reference: what we have vs what the meta plays, missing cards.
Also corrects name mismatches detected in previous analysis."""
import json, os, difflib, sqlite3

DB_DIR = os.path.dirname(os.path.abspath(__file__))
KNOWLEDGE_DB = os.path.join(DB_DIR, "knowledge.db")

with open(os.path.join(DB_DIR, "_edhrec_card_data.json")) as f:
    edhrec_cards = json.load(f)

edhrec_lookup = {}
for c in edhrec_cards:
    name = c['name'].lower().strip()
    edhrec_lookup[name] = c

conn = sqlite3.connect(KNOWLEDGE_DB)
cur = conn.cursor()
cur.execute("SELECT card_name, cmc, functional_tag FROM deck_cards WHERE deck_id=6")
our_cards = cur.fetchall()
conn.close()

# Our card names (normalized)
our_names_lower = set()
our_card_map = {}
for name, cmc, tag in our_cards:
    key = name.lower().strip()
    our_names_lower.add(key)
    our_card_map[key] = {'name': name, 'cmc': cmc, 'tag': tag}

# Manual corrections for known mismatches
manual_matches = {
    'valakut awakening // valakut stoneforge': 'valakut awakening',
    'emeria\'s call // emeria, shattered skyclave': 'emeria\'s call',
}

# Correct name lookup
def get_meta_pct(card_name):
    key = card_name.lower().strip()
    
    # Direct match
    if key in edhrec_lookup:
        return edhrec_lookup[key]['pct'], edhrec_lookup[key]['synergy'], edhrec_lookup[key]['trend_zscore']
    
    # Manual correction
    if key in manual_matches:
        alias = manual_matches[key]
        if alias in edhrec_lookup:
            return edhrec_lookup[alias]['pct'], edhrec_lookup[alias]['synergy'], edhrec_lookup[alias]['trend_zscore']
    
    return 0, 0, 0

print("=== CARDS TO KEEP (meta > 50% and already in deck) ===")
keepers = []
for name, cmc, tag in sorted(our_cards, key=lambda x: x[0].lower()):
    pct, syn, trend = get_meta_pct(name)
    if pct >= 50:
        keepers.append((name, pct, cmc, tag))
        print(f"  ✅ {name:50s} {pct:5.1f}% CMC {cmc:3.1f} [{tag or 'unset'}]")

print()
print("=== CARDS MISSING FROM OUR DECK (EDHREC > 50% that we don't have) ===")
our_deck_set = set()
for name, _, _ in our_cards:
    # Handle // names
    n = name.lower().strip()
    our_deck_set.add(n)
    if n in manual_matches:
        our_deck_set.add(manual_matches[n])

missed = []
for ec in edhrec_cards:
    name_key = ec['name'].lower().strip()
    pct = ec['pct']
    if pct >= 50 and name_key not in our_deck_set:
        # Exclude basic lands
        if ec['name'] in ['Mountain', 'Plains', 'Forest', 'Island', 'Swamp']:
            continue
        missed.append((ec['name'], pct, ec['synergy'], ec['trend_zscore']))
        print(f"  ❌ {ec['name']:50s} {pct:5.1f}% syn={ec['synergy']:.2f} trend={ec['trend_zscore']:+.1f}")

print()

# Also show cards 40-50%
print("=== CARDS MISSING (40-50% EDHREC) ===")
for ec in sorted(edhrec_cards, key=lambda x: -x['pct']):
    name_key = ec['name'].lower().strip()
    pct = ec['pct']
    if 40 <= pct < 50 and name_key not in our_deck_set:
        if ec['name'] in ['Mountain', 'Plains', 'Forest', 'Island', 'Swamp']:
            continue
        print(f"  ⚠️  {ec['name']:50s} {pct:5.1f}% syn={ec['synergy']:.2f} trend={ec['trend_zscore']:+.1f}")

print()
print(f"Total cards in deck: {len(keepers)} at >=50% meta")
print(f"Total missing >=50%: {len(missed)}")
