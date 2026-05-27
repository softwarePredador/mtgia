#!/usr/bin/env python3
"""Lorehold Deck Scout - analyze EDHREC corpus and compare with our deck."""
import json, pathlib, sqlite3
from collections import Counter

DB_PATH = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'
CORPUS_PATH = '/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json'

# ── 1. Load corpus ──
data = json.loads(pathlib.Path(CORPUS_PATH).read_text())
total_decks = len(data['decks'])
print(f'Corpus: {total_decks} decks, commander: {data["commander"]}')

card_deck_count = Counter()
card_quantities = Counter()

for di, deck in enumerate(data['decks']):
    main_cards = [c for c in deck['cards'] if c['board'] == 'main']
    print(f'  Deck {di+1}: {len(main_cards)} cards, {deck["source_url"]}')
    for c in main_cards:
        name = c['name']
        card_deck_count[name] += 1
        card_quantities[name] += c['quantity']

print(f'\nUnique cards: {len(card_deck_count)}')

# ── 2. Load our deck ──
conn = sqlite3.connect(DB_PATH)
our_rows = conn.execute("""
    SELECT card_name, quantity, functional_tag, is_commander, cmc, type_line
    FROM deck_cards WHERE deck_id = 6
    ORDER BY is_commander DESC, functional_tag, card_name
""").fetchall()

deck_meta = conn.execute("""
    SELECT total_lands, avg_cmc, ramp_count, draw_count, removal_count, board_wipe_count
    FROM decks WHERE id = 6
""").fetchone()

conn.close()

our_cards = {}
for r in our_rows:
    our_cards[r[0]] = {
        'tag': r[2], 'cmc': r[4], 'type': r[5], 'is_commander': r[3]
    }

our_names_lower = {n.lower().strip() for n in our_cards}
print(f'\nOur deck: {len(our_cards)} cards (deck_id=6)')
print(f'  Lands: {deck_meta[0]}, CMC: {deck_meta[1]}, Ramp: {deck_meta[2]}, Draw: {deck_meta[3]}, Removal: {deck_meta[4]}, Wipes: {deck_meta[5]}')

# ── 3. TOP cards ──
print('\n' + '='*60)
print('TOP 30 CARDS BY DECK FREQUENCY (EDHREC)')
print('='*60)
for i, (card, cnt) in enumerate(card_deck_count.most_common(30)):
    pct = cnt / total_decks * 100
    qty = card_quantities[card]
    in_ours = 'IN DECK' if card.lower().strip() in our_names_lower else 'MISSING'
    print(f'  {i+1:2d}. {card:42s} {cnt}/{total_decks} ({pct:.0f}%) qty={qty}  {in_ours}')

# ── 4. Missing high priority ──
print('\n' + '-'*60)
print('MISSING FROM OUR DECK (67%+ in external)')
print('-'*60)
high_priority = []
for card, cnt in card_deck_count.most_common():
    pct = cnt / total_decks * 100
    if pct >= 67 and card.lower().strip() not in our_names_lower:
        high_priority.append((card, cnt, pct, card_quantities[card]))
        print(f'  {card:42s} in {cnt}/{total_decks} ({pct:.0f}%) -- PRIORITY')

if not high_priority:
    print('  (none)')

# ── 5. Cut candidates ──
print('\n' + '-'*60)
print('OUR CARDS WITH 0% IN EXTERNAL DECKS')
print('-'*60)
cut_candidates = []
for name, info in our_cards.items():
    if info['is_commander']:
        continue
    if card_deck_count.get(name, 0) == 0:
        cut_candidates.append((name, info))
        print(f'  {name:42s} tag={info["tag"]} cmc={info["cmc"]}')

print(f'\nTotal cut candidates: {len(cut_candidates)}')

# ── 6. Shared ──
print('\n' + '-'*60)
print('CARDS IN BOTH (shared)')
print('-'*60)
shared = []
ext_names_lower = {c.lower().strip() for c in card_deck_count}
for name in our_cards:
    if name.lower().strip() in ext_names_lower:
        ext_cnt = card_deck_count.get(name, 0)
        shared.append((name, ext_cnt))
        pct = ext_cnt / total_decks * 100
        print(f'  {name:42s} ext={ext_cnt}/{total_decks} ({pct:.0f}%)')

print(f'\nShared cards: {len(shared)}/{len(our_cards)-1} non-commander cards')

# ── 7. Save ──
output = {
    'total_external_decks': total_decks,
    'unique_external_cards': len(card_deck_count),
    'our_cards_count': len(our_cards),
    'our_metrics': {
        'lands': deck_meta[0], 'avg_cmc': deck_meta[1],
        'ramp': deck_meta[2], 'draw': deck_meta[3],
        'removal': deck_meta[4], 'wipes': deck_meta[5]
    },
    'top30_external': [(c, cnt, cnt/total_decks*100) for c, cnt in card_deck_count.most_common(30)],
    'missing_high_priority': [(c, cnt, cnt/total_decks*100) for c, cnt in card_deck_count.most_common() if cnt/total_decks >= 0.67 and c.lower().strip() not in our_names_lower],
    'cut_candidates': [(name, info['tag']) for name, info in cut_candidates],
    'shared_cards': [(name, cnt) for name, cnt in shared],
    'external_card_freq': dict(card_deck_count.most_common()),
}
out_path = pathlib.Path('/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/scout_data.json')
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(json.dumps(output, indent=2, default=str))
print(f'\nFull analysis saved to {out_path}')