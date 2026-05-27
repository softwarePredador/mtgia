#!/usr/bin/env python3
"""Extract ALL cards from EDHREC and build full card database."""
import json, os

DB_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT = os.path.join(DB_DIR, "_edhrec_raw_lorehold.json")

with open(INPUT) as f:
    data = json.load(f)

props = data.get('props', {}).get('pageProps', {}).get('data', {})
container = props.get('container', {})
json_dict = container.get('json_dict', {})
cardlists = json_dict.get('cardlists', [])

# Collect all cards from all cardlists
all_cards = []
for cl in cardlists:
    cardviews = cl.get('cardviews', [])
    for cv in cardviews:
        card_info = {
            'name': cv.get('name'),
            'sanitized': cv.get('sanitized'),
            'inclusion': cv.get('inclusion', 0),
            'potential_decks': cv.get('potential_decks', 0),
            'synergy': cv.get('synergy', 0),
            'trend_zscore': cv.get('trend_zscore', 0),
        }
        # Calculate percentage
        if card_info['potential_decks'] > 0:
            card_info['pct'] = round(card_info['inclusion'] / card_info['potential_decks'] * 100, 1)
        else:
            card_info['pct'] = 0
        all_cards.append(card_info)

# Sort by inclusion percentage descending
all_cards.sort(key=lambda c: -c['pct'])

total_decks = all_cards[0]['potential_decks'] if all_cards else 0
print(f"Total cards tracked: {len(all_cards)}")
print(f"Total decks in sample: {total_decks}")
print()

print("=== TOP 80 CARDS BY INCLUSION % ===")
print(f"{'#':>3} {'Card Name':45s} {'Inclusion':>8s} {'%':>7s} {'Synergy':>8s} {'Trend':>8s}")
print("=" * 80)
for i, card in enumerate(all_cards[:80]):
    print(f"{i+1:3d} {card['name']:45s} {card['inclusion']:8d} {card['pct']:6.1f}% {card['synergy']:7.2f} {card['trend_zscore']:7.1f}")

# Save for analysis
output_path = os.path.join(DB_DIR, "_edhrec_card_data.json")
with open(output_path, 'w') as f:
    json.dump(all_cards, f, indent=2)
print(f"\nSaved all {len(all_cards)} cards to {output_path}")
