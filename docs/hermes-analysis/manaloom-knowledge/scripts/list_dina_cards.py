import json

# Load Dina corpus - all 5 decks
with open('/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/dina_edhrec_average_corpus.json') as f:
    data = json.load(f)

# Print the detailed view of all 5 decks
for deck_idx in range(len(data['decks'])):
    deck = data['decks'][deck_idx]
    cards = deck.get('cards', [])
    print(f"=== Deck {deck_idx+1}: {deck.get('theme')} ===")
    print(f"Power Lane: {deck.get('power_lane')}")
    print(f"Source URL: {deck.get('source_url')}")
    print(f"Cards: {len(cards)}")
    
    # Separate commanders, mainboard
    mainboard = [c for c in cards if c.get('board') == 'main']
    commanders_c = [c for c in cards if c.get('board') == 'commander']
    
    print(f"Commanders: {[c['name'] for c in commanders_c]}")
    print(f"Mainboard: {len(mainboard)} cards")
    
    # Print all card names grouped by type estimate
    print("Cards:")
    for c in cards:
        board = c.get('board', '')
        qty = c.get('quantity', 1)
        marker = "(C)" if board == 'commander' else ""
        print(f"  [{qty}x] {c['name']} {marker}")
    print()
    print("---")
    print()
