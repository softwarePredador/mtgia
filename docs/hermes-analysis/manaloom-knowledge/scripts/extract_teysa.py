#!/usr/bin/env python3
"""Extract Teysa Karlov EDHREC default deck metrics from corpus.json"""
import json

with open('/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/teysa_karlov/corpus.json') as f:
    data = json.load(f)

# Default deck (first one - edhrec_average_default)
deck = data['decks'][0]
print(f"Source: {deck['source']}")
print(f"URL: {deck['source_url']}")
print(f"Theme: {deck['theme']}")
print(f"Source proof: {json.dumps(deck['source_proof'], indent=2)}")
print(f"Total cards entries: {len(deck['cards'])}")

# Separate commander and main
commander_cards = [c for c in deck['cards'] if c['board'] == 'commander']
main_cards = [c for c in deck['cards'] if c['board'] == 'main']

print(f"\nCommander cards: {len(commander_cards)}")
print(f"Main deck cards: {len(main_cards)}")

# Count lands
lands = [c['name'] for c in main_cards if c['name'] in [
    'Plains', 'Swamp', 'Command Tower', 'Godless Shrine', 'Isolated Chapel',
    'Bojuka Bog', 'Caves of Koilos', 'Fetid Heath', 'Marsh Flats',
    'Orzhov Basilica', 'Shattered Sanctum', 'Shineshadow Snarl',
    'Tainted Field', 'Temple of Silence', 'Vault of Champions',
    'High Market', 'Phyrexian Tower'
]]
print(f"\nLands ({len(lands)}):")
print(', '.join(sorted(lands)))

# Count basic lands
basics = [c for c in main_cards if c['name'] in ['Plains', 'Swamp']]
for b in basics:
    print(f"  {b['name']} x{b['quantity']}")

# Total lands count with quantities
total_lands = sum(c['quantity'] for c in main_cards if c['name'] in lands)
print(f"Total lands (with quantities): {total_lands}")

# List all non-land cards
non_lands = [c for c in main_cards if c['name'] not in lands and c['name'] != 'Teysa Karlov']
print(f"\nNon-land cards ({len(non_lands)}):")
for c in sorted(non_lands, key=lambda x: x['name']):
    print(f"  {c['name']} x{c['quantity']}")

print(f"\nTotal main cards: {sum(c['quantity'] for c in main_cards)}")

# Now also look at the aristocrats deck for comparison
deck2 = data['decks'][1]
print(f"\n\n--- Aristocrats deck ---")
print(f"URL: {deck2['source_url']}")
print(f"Source proof: {json.dumps(deck2['source_proof'], indent=2)}")

# Get aristocrats-specific cards not in default
default_names = set(c['name'] for c in main_cards)
arist_cards = [c for c in deck2['cards'] if c['board'] == 'main']
arist_names = set(c['name'] for c in arist_cards)
unique_to_arist = arist_names - default_names
print(f"\nCards in Aristocrats but NOT in Default:")
for name in sorted(unique_to_arist):
    print(f"  {name}")