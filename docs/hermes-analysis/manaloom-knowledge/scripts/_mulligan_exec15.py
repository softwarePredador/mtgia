#!/usr/bin/env python3
"""Mulligan Simulation — Execucao #15 (2026-06-03)"""
import sqlite3, random, hashlib, json, datetime, sys, os

DB = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'
SEED = 42
N = 1000

random.seed(SEED)

conn = sqlite3.connect(DB)
conn.row_factory = sqlite3.Row
cur = conn.cursor()

cur.execute("SELECT card_name, quantity, cmc, functional_tag, type_line FROM deck_cards WHERE deck_id=6")
rows = cur.fetchall()

library = []
for r in rows:
    tag = r['functional_tag'] or 'unknown'
    if tag == 'commander':
        continue
    for _ in range(int(r['quantity'])):
        library.append({
            'name': r['card_name'],
            'cmc': float(r['cmc'] or 0),
            'tag': tag,
            'type_line': r['type_line'] or '',
        })

card_names = sorted(r['card_name'] for r in rows)
card_hash = hashlib.md5('|'.join(card_names).encode()).hexdigest()

lands = [c for c in library if c['tag'] == 'land']
db_ramp_names = set(c['name'] for c in library if c['tag'] == 'ramp')

FAST_MANA_NAMES = {
    'Sol Ring', 'Mana Vault', 'Mana Crypt', 'Chrome Mox',
    'Mox Diamond', 'Mox Opal', 'Mox Amber', 'Lotus Petal',
    'Rite of Flame',
}

def is_ramp(card):
    if card['name'] in FAST_MANA_NAMES:
        return True
    if card['tag'] == 'ramp':
        return True
    return False

results = {
    'playable': 0, 'mulligan': 0, 'sem_play_t3': 0,
    'ramp_t1_strict': 0, 'ramp_t1_expanded': 0,
    'hands_to_0': 0, 'hands_to_1': 0, 'hands_to_2': 0,
    'mull_dist': {}, 'hand_dist': {}, 'total_mulls': 0,
}

for _ in range(N):
    deck = library.copy()
    random.shuffle(deck)
    hs = 7
    mc = 0
    final = []

    while True:
        if hs == 0:
            break
        
        hand = deck[:hs]
        hl = sum(1 for c in hand if c['tag'] == 'land')
        hr = sum(1 for c in hand if is_ramp(c) and c['cmc'] <= hl)
        bc = max(0, mc - 1)

        if 2 <= hl <= 4 and (hr >= 1 or hl >= 3):
            final = hand
            break
        elif hl >= 5:
            final = hand
            break
        else:
            mc += 1
            hs = max(0, 7 - bc)
            random.shuffle(deck)

    results['mull_dist'][mc] = results['mull_dist'].get(mc, 0) + 1
    results['total_mulls'] += mc
    results['hand_dist'][len(final)] = results['hand_dist'].get(len(final), 0) + 1

    if mc > 0:
        results['mulligan'] += 1
    if len(final) == 0:
        results['hands_to_0'] += 1
    if len(final) <= 1:
        results['hands_to_1'] += 1
    if len(final) <= 2:
        results['hands_to_2'] += 1

    fl = sum(1 for c in final if c['tag'] == 'land')
    fr = sum(1 for c in final if is_ramp(c) and c['cmc'] <= fl)
    if fl >= 2 and (fr >= 1 or fl >= 3):
        results['playable'] += 1

    lt3 = min(fl, 3)
    ft3 = sum(1 for c in final if c['name'] in FAST_MANA_NAMES and c['cmc'] <= 1)
    eff = lt3 + ft3
    can_cast = any(c['tag'] != 'land' and 0 < c['cmc'] <= eff for c in final)
    if not can_cast and len(final) > 0:
        results['sem_play_t3'] += 1

    if fl >= 1 and any(c['name'] == 'Sol Ring' for c in final):
        results['ramp_t1_strict'] += 1
    if fl >= 1 and any(c['name'] in FAST_MANA_NAMES and c['cmc'] <= 1 for c in final):
        results['ramp_t1_expanded'] += 1

p = lambda n: round(n / N * 100, 1)

out = {
    'execucao': 15,
    'seed': SEED, 'N': N,
    'card_hash': card_hash,
    'total_cards': len(library),
    'lands_tagged': len(lands),
    'db_ramp_tagged': len(db_ramp_names),
    'fast_mana_count': sum(1 for c in library if c['name'] in FAST_MANA_NAMES),
    'playable_pct': p(results['playable']),
    'mulligan_pct': p(results['mulligan']),
    'sem_play_t3_pct': p(results['sem_play_t3']),
    'ramp_t1_strict_pct': p(results['ramp_t1_strict']),
    'ramp_t1_expanded_pct': p(results['ramp_t1_expanded']),
    'hands_to_0_pct': p(results['hands_to_0']),
    'avg_mulligans': round(results['total_mulls'] / N, 2),
    'mull_dist': dict(sorted(results['mull_dist'].items())),
    'hand_dist': dict(sorted(results['hand_dist'].items())),
    'timestamp': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%S+00:00'),
}
print(json.dumps(out, indent=2))
conn.close()
