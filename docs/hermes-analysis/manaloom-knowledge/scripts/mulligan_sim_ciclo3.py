import sqlite3
import random
from collections import defaultdict

DB = 'scripts/knowledge.db'
conn = sqlite3.connect(DB)
c = conn.cursor()

c.execute('''
    SELECT card_name, quantity, cmc, type_line, functional_tag
    FROM deck_cards
    WHERE deck_id = 6 AND is_commander = 0
''')
rows = c.fetchall()
conn.close()

deck_list = []
for name, qty, cmc, type_line, tag in rows:
    for _ in range(qty):
        is_land = type_line and 'Land' in type_line
        deck_list.append({
            'name': name,
            'cmc': cmc or 0,
            'is_land': is_land,
            'tag': tag
        })

print(f"Deck size: {len(deck_list)} cards")

# Strict T1 ramp: only cards that produce mana on turn 1
# Per skill doc: Sol Ring, Land Tax, Weathered Wayfarer, Desperate Ritual
# Desperate Ritual was swapped OUT in Ciclo #3, so only 3 remain
T1_RAMP_STRICT = {'Sol Ring', 'Land Tax', 'Weathered Wayfarer'}

CICLO3_NEW = {'Storm-Kiln Artist', 'Boros Signet', 'Generous Gift', 'Blasphemous Act', 'Improvisation Capstone'}

random.seed(42)
N = 1000
playable = 0
mulligan = 0
ramp_t1 = 0
sem_play_t3 = 0
land_dist = defaultdict(int)
new_cards_freq = defaultdict(int)

for _ in range(N):
    hand = random.sample(deck_list, 7)
    lands = sum(1 for c in hand if c['is_land'])
    land_dist[lands] += 1

    has_t1_ramp = any(c['name'] in T1_RAMP_STRICT for c in hand)
    if has_t1_ramp:
        ramp_t1 += 1

    for c in hand:
        if c['name'] in CICLO3_NEW:
            new_cards_freq[c['name']] += 1

    has_ramp = any(c['tag'] == 'ramp' for c in hand)

    if lands >= 2 and lands <= 4 and (has_ramp or lands >= 3):
        playable += 1
    elif lands <= 1 or (lands == 2 and not has_ramp) or lands >= 6:
        mulligan += 1

    min_cmc_cap = min(lands, 3)
    has_castable = any(not c['is_land'] and c['cmc'] <= min_cmc_cap for c in hand)
    if not has_castable:
        sem_play_t3 += 1

print(f"\n=== RESULTS (N={N}, seed=42) ===")
print(f"Playable: {playable/N*100:.1f}%")
print(f"Mulligan: {mulligan/N*100:.1f}%")
print(f"Ramp T1:  {ramp_t1/N*100:.1f}%")
print(f"Sem play T3: {sem_play_t3/N*100:.1f}%")

print(f"\nLand distribution:")
for lands in sorted(land_dist):
    pct = land_dist[lands]/N*100
    print(f"  {lands} lands: {land_dist[lands]} ({pct:.1f}%)")

print(f"\nCiclo #3 new cards in opening hand:")
for card, freq in sorted(new_cards_freq.items(), key=lambda x: -x[1]):
    pct_val = freq/N*100
    inv = N/freq if freq > 0 else 0
    print(f"  {card}: {pct_val:.1f}% (1 in {inv:.0f} hands)")

print(f"\n--- STRUCTURED OUTPUT ---")
print(f"playable={playable/N*100:.1f}")
print(f"mulligan={mulligan/N*100:.1f}")
print(f"ramp_t1={ramp_t1/N*100:.1f}")
print(f"sem_play_t3={sem_play_t3/N*100:.1f}")
