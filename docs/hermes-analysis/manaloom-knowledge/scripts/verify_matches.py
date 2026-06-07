#!/usr/bin/env python3
"""Double-check name mismatches between our deck and EDHREC data."""
import json, os, difflib

DB_DIR = os.path.dirname(os.path.abspath(__file__))
KNOWLEDGE_DB = os.path.join(DB_DIR, "knowledge.db")

with open(os.path.join(DB_DIR, "_edhrec_card_data.json")) as f:
    edhrec_cards = json.load(f)

# Build lookup
edhrec_lookup = {}
for c in edhrec_cards:
    name = c['name'].lower().strip()
    edhrec_lookup[name] = c

import sqlite3
conn = sqlite3.connect(KNOWLEDGE_DB)
cur = conn.cursor()
cur.execute("""
    SELECT dc.card_name, dc.cmc, dc.functional_tag
    FROM deck_cards dc
    WHERE dc.deck_id = 6
    ORDER BY dc.card_name
""")
our_cards = cur.fetchall()
conn.close()

print("=== VERIFYING CARD NAME MATCHES ===")
print(f"{'#':>3} {'Our Card Name':55s} {'Match?':10s} {'EDHREC Name':55s} {'%':>7s}")
print("=" * 130)

unmatched = []
for idx, (card_name, cmc, tag) in enumerate(our_cards):
    key = card_name.lower().strip()
    
    # Direct match first
    match = edhrec_lookup.get(key)
    
    if match:
        print(f"{idx+1:3d} {card_name:55s} {'✅':10s} {match['name']:55s} {match['pct']:6.1f}%")
    else:
        # Try fuzzy match
        best_ratio = 0
        best_match = None
        for e_name, e_card in edhrec_lookup.items():
            ratio = difflib.SequenceMatcher(None, key, e_name).ratio()
            if ratio > best_ratio:
                best_ratio = ratio
                best_match = e_card
        unmatched.append((card_name, key, best_match, best_ratio))

print("\n=== UNMATCHED CARDS (fuzzy search results) ===")
for card_name, key, best_match, ratio in sorted(unmatched, key=lambda x: -x[3]):
    if best_match:
        print(f"  '{card_name}' ({key}) -> '{best_match['name']}' ({best_match['name'].lower()}) ratio={ratio:.3f} pct={best_match['pct']:.1f}%")
    else:
        print(f"  '{card_name}' ({key}) -> NO MATCH")
