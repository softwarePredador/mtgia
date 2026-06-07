#!/usr/bin/env python3
import json

with open('/opt/data/workspace/mtgia/server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_2026-04-27.json') as f:
    data = json.load(f)

decks = data.get('entries', []) or [data]

for deck in decks:
    if isinstance(deck, dict) and 'Thassa' in str(deck.get('card_list','')):
        cl = deck['card_list']
        print(f"Commander: {deck.get('commander_name', 'N/A')}")
        print(f"Place: {deck.get('placement', 'N/A')}")
        
        # Check if card_list is a single string with \n separators or JSON escapes
        if '\\\\n' in str(cl):
            cards = str(cl).split('\\\\n')
        elif '\\n' in str(cl):
            cards = str(cl).split('\\n')
        elif '\n' in str(cl):
            cards = str(cl).split('\n')
        else:
            cards = [str(cl)]
        
        print(f"Card count (split): {len(cards)}")
        print(f"Raw card_list[:200]: {str(cl)[:200]}")
        
        # Find Thassa and combo pieces
        for c in cards:
            c = c.strip()
            if 'Thassa' in c or 'Consultation' in c or 'Oracle' in c or 'Pact' in c or 'Force' in c:
                print(f"  -> {c}")
        print()
        break