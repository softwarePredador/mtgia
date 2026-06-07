#!/usr/bin/env python3
"""Deep card-by-card analysis: every card in our deck vs EDHREC meta."""
import json, os

DB_DIR = os.path.dirname(os.path.abspath(__file__))
KNOWLEDGE_DB = os.path.join(DB_DIR, "knowledge.db")

# Read EDHREC card data
with open(os.path.join(DB_DIR, "_edhrec_card_data.json")) as f:
    edhrec_cards = json.load(f)

# Build lookup
edhrec_lookup = {}
for c in edhrec_cards:
    name = c['name'].lower()
    edhrec_lookup[name] = c

# Get our deck from DB
import sqlite3
conn = sqlite3.connect(KNOWLEDGE_DB)
cur = conn.cursor()

cur.execute("""
    SELECT dc.card_name, dc.cmc, dc.functional_tag, dc.quantity, dc.type_line, dc.oracle_text
    FROM deck_cards dc
    WHERE dc.deck_id = 6
    ORDER BY dc.cmc, dc.card_name
""")
our_cards = cur.fetchall()
conn.close()

print(f"Our deck: {len(our_cards)} cards")
print()

# Analyze each card
results = []
for card_name, cmc, tag, qty, type_line, oracle_text in our_cards:
    key = card_name.lower().strip()
    edhrec = edhrec_lookup.get(key, None)
    
    in_meta = edhrec is not None
    pct = edhrec['pct'] if edhrec else 0
    synergy = edhrec['synergy'] if edhrec else 0
    trend = edhrec['trend_zscore'] if edhrec else 0
    
    results.append({
        'card_name': card_name,
        'cmc': cmc,
        'tag': tag or 'unset',
        'in_meta': in_meta,
        'edhrec_pct': pct,
        'edhrec_synergy': synergy,
        'trend': trend,
        'type_line': type_line or '',
        'oracle': oracle_text or ''
    })

# Categorize
missing_from_meta = [r for r in results if not r['in_meta']]
low_pct = [r for r in results if r['in_meta'] and r['edhrec_pct'] < 20]
medium_pct = [r for r in results if r['in_meta'] and 20 <= r['edhrec_pct'] < 50]
high_pct = [r for r in results if r['in_meta'] and 50 <= r['edhrec_pct'] < 80]
staple = [r for r in results if r['in_meta'] and r['edhrec_pct'] >= 80]
trending_up = sorted([r for r in results if r['in_meta'] and r['trend'] > 3], key=lambda x: -x['trend'])

# Also find cards NOT in our deck that are >50%
print("=" * 80)
print("MISSING FROM META (0% EDHREC) — cards in our deck that no one else plays")
print("=" * 80)
for r in missing_from_meta:
    print(f"  {r['card_name']:45s} CMC {r['cmc']:3.1f} tag={r['tag']}")
print()

print("=" * 80)
print("LOW META (<20% EDHREC) — cards in our deck that most players skip")
print("=" * 80)
for r in sorted(low_pct, key=lambda x: x['edhrec_pct']):
    print(f"  {r['edhrec_pct']:5.1f}% {r['card_name']:45s} CMC {r['cmc']:3.1f} tag={r['tag']}")
print()

print("=" * 80)
print("MEDIUM META (20-50% EDHREC)")
print("=" * 80)
for r in sorted(medium_pct, key=lambda x: x['edhrec_pct']):
    print(f"  {r['edhrec_pct']:5.1f}% {r['card_name']:45s} CMC {r['cmc']:3.1f} tag={r['tag']}")
print()

print("=" * 80)
print("HIGH META (50-80% EDHREC)")
print("=" * 80)
for r in sorted(high_pct, key=lambda x: -x['edhrec_pct']):
    print(f"  {r['edhrec_pct']:5.1f}% {r['card_name']:45s} CMC {r['cmc']:3.1f} tag={r['tag']}")
print()

print("=" * 80)
print("STAPLE (80%+ EDHREC)")
print("=" * 80)
for r in sorted(staple, key=lambda x: -x['edhrec_pct']):
    print(f"  {r['edhrec_pct']:5.1f}% {r['card_name']:45s} CMC {r['cmc']:3.1f} tag={r['tag']}")
print()

print("=" * 80)
print("TRENDING UP (trend > 3)")
print("=" * 80)
for r in trending_up:
    print(f"  {r['card_name']:45s} {r['edhrec_pct']:5.1f}% trend={r['trend']:+.1f} synergy={r['edhrec_synergy']:3.2f}")

print()
print(f"Summary: {len(staple)} staples, {len(high_pct)} high, {len(medium_pct)} medium, {len(low_pct)} low, {len(missing_from_meta)} missing")
print(f"Tracking: {len(results)} cards analyzed vs {len(edhrec_cards)} EDHREC cards")
