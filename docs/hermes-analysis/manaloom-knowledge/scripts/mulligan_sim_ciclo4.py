#!/usr/bin/env python3
"""Quick mulligan simulation for Ciclo #4 validation"""
import sqlite3
import random

DB = 'scripts/knowledge.db'
DECK_ID = 6

conn = sqlite3.connect(DB)
c = conn.cursor()

# Build deck list (99 cards, excluding commander)
c.execute("""
    SELECT card_name, quantity, cmc, type_line
    FROM deck_cards
    WHERE deck_id = ? AND is_commander = 0
""", (DECK_ID,))
rows = c.fetchall()
conn.close()

# Build deck list (expanded by quantity)
deck = []
for name, qty, cmc, type_line in rows:
    for _ in range(qty):
        deck.append({
            'name': name,
            'cmc': cmc if cmc else 0,
            'type_line': type_line or ''
        })

print(f"Deck size: {len(deck)} cards")
assert len(deck) == 99, f"Expected 99 cards, got {len(deck)}"

# Ramp T1 cards
RAMP_T1 = {'Sol Ring', 'Land Tax', 'Weathered Wayfarer'}

def is_land(card):
    return 'Land' in card['type_line']

def simulate(deck, seed=42, n=1000):
    rng = random.Random(seed)

    playable = 0
    mulligan = 0
    ramp_t1 = 0
    sem_play_t3 = 0

    lands_dist = {i: 0 for i in range(8)}

    for _ in range(n):
        hand = rng.sample(deck, 7)

        lands = [c for c in hand if is_land(c)]
        n_lands = len(lands)
        lands_dist[min(n_lands, 7)] += 1

        # Ramp T1
        has_ramp_t1 = any(c['name'] in RAMP_T1 for c in hand)
        if has_ramp_t1:
            ramp_t1 += 1

        # Non-land cards and their CMC
        nonlands = [c for c in hand if not is_land(c)]
        min_nonland_cmc = min((c['cmc'] for c in nonlands), default=99)

        # Rigorous playable: 2-4 lands AND (ramp >= 1 OR lands >= 3)
        has_ramp = has_ramp_t1  # Simplified: only T1 ramp
        is_playable = (2 <= n_lands <= 4) and (has_ramp or n_lands >= 3)
        if is_playable:
            playable += 1

        # Rigorous mulligan: 0-1 lands OR (2 lands AND no ramp) OR 6+ lands
        needs_mulligan = (n_lands <= 1) or (n_lands == 2 and not has_ramp) or (n_lands >= 6)
        if needs_mulligan:
            mulligan += 1

        # Sem Play T3: no castable card with CMC <= min(lands, 3)
        cap = min(n_lands, 3)
        has_play_t3 = any(c['cmc'] <= cap for c in hand)  # includes lands themselves? No - only playable spells
        has_play_t3 = any(not is_land(c) and c['cmc'] <= cap for c in hand)
        if not has_play_t3:
            sem_play_t3 += 1

    print(f"\n{'='*50}")
    print(f"Simulacao Ciclo #4 (seed={seed}, N={n})")
    print(f"{'='*50}")
    print(f"Jogaveis (rigorous): {playable/n*100:.1f}%")
    print(f"Mulligatorio:       {mulligan/n*100:.1f}%")
    print(f"Ramp T1:            {ramp_t1/n*100:.1f}%")
    print(f"Sem Play T3:        {sem_play_t3/n*100:.1f}%")

    print(f"\nDistribuicao de Lands:")
    for i in range(8):
        if lands_dist[i] > 0:
            print(f"  {i} lands: {lands_dist[i]} ({lands_dist[i]/n*100:.1f}%)")

simulate(deck)
