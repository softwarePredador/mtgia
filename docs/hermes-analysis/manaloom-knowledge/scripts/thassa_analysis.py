#!/usr/bin/env python3
"""Analyze Thassa's Oracle decks from artifact data."""
import json
import re

with open('/opt/data/workspace/mtgia/server/test/artifacts/meta_deck_intelligence_2026-04-27/topdeck_edhtop16_expansion_dry_run_2026-04-27.json') as f:
    content = f.read()

# Parse card_list from JSON
data = json.loads(content)
entries = data.get('entries', [])

thassa_decks = []
for entry in entries:
    if 'Thassa' in str(entry.get('card_list', '')):
        thassa_decks.append(entry)
        
print(f"Found {len(thassa_decks)} decks with Thassa's Oracle in this file")
print()

for i, deck in enumerate(thassa_decks):
    print(f"=== Deck {i+1} ===")
    for k in ['commander_name', 'partner_name', 'deck_name', 'archetype', 'player_name', 'placement', 'standing', 'tournament_name', 'source']:
        if k in deck:
            print(f"  {k}: {deck[k]}")
    
    cl = deck.get('card_list', '')
    # Split by literal \n (stored in JSON as '\\n')
    cards = cl.split('\\n')
    print(f"  Total cards: {len(cards)}")
    
    # Show key combo pieces
    combo_indicators = ['Thassa', 'Consultation', 'Oracle', 'Tainted Pact', 'Underworld Breach', 
                       'Brain Freeze', 'Lion\'s Eye', 'Force of Will', 'Fierce', 'Ad Nauseam',
                       'Demonic Tutor', 'Vampiric Tutor', 'Mystic Remora']
    for card_str in cards:
        for ind in combo_indicators:
            if ind.lower() in card_str.lower():
                print(f"  -> {card_str.strip()}")
                break
    print()

# Now check ALL files for Thassa's Oracle distribution
import os
artifact_dir = '/opt/data/workspace/mtgia/server/test/artifacts/meta_deck_intelligence_2026-04-27'
print("=== ALL FILES ANALYSIS ===")
total_thassa_decks = 0
for fname in sorted(os.listdir(artifact_dir)):
    fpath = os.path.join(artifact_dir, fname)
    if fname.endswith('.json') and os.path.isfile(fpath):
        with open(fpath) as f:
            try:
                d = json.load(f)
                
                # Find decks list (could be under 'entries' or top-level arrays)
                decks_list = None
                if isinstance(d, list):
                    decks_list = d
                elif isinstance(d, dict):
                    for key in ['entries', 'decks', 'results', 'deck_records']:
                        if key in d and isinstance(d[key], list):
                            decks_list = d[key]
                            break
                    else:
                        decks_list = [d] if 'card_list' in d else []
                
                count_decks = len(decks_list) if decks_list else 0
                count_thassa = sum(1 for e in decks_list if 'Thassa' in str(e.get('card_list',''))) if decks_list else 0
                total_thassa_decks += count_thassa
                
                if count_thassa > 0:
                    commanders = set()
                    for e in decks_list:
                        if 'Thassa' in str(e.get('card_list','')):
                            cmd = e.get('commander_name', '?')
                            if cmd:
                                commanders.add(cmd)
                    print(f"  {fname}: {count_thassa}/{count_decks} decks | Commanders: {', '.join(sorted(commanders))[:100]}")
            except:
                pass

print(f"\nTotal Thassa's Oracle decks across all files: {total_thassa_decks}")