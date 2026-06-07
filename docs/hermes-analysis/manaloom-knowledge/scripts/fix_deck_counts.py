#!/usr/bin/env python3
"""Update deck counts excluding land cards from functional tag counts."""
import sqlite3

conn = sqlite3.connect('scripts/knowledge.db')

# Count non-land ramp: cards with ramp tag that DON'T also have land tag
NOLAND = [
    ('ramp_count', 'ramp'),
    ('draw_count', 'draw'),
    ('removal_count', 'removal'),
    ('protection_count', 'protection'),
    ('engine_count', 'engine'),
]
NOLAND_FILTER = "AND dc.id NOT IN (SELECT dc2.id FROM deck_cards dc2 JOIN card_tags ct2 ON ct2.deck_card_id = dc2.id WHERE dc2.deck_id = decks.id AND ct2.tag = 'land')"

for col, tag in NOLAND:
    sql = f'''
        UPDATE decks SET {col} = (
            SELECT COUNT(DISTINCT dc.id)
            FROM card_tags ct
            JOIN deck_cards dc ON ct.deck_card_id = dc.id
            WHERE dc.deck_id = decks.id AND ct.tag = '{tag}'
            {NOLAND_FILTER}
        )
    '''
    conn.execute(sql)

# Tags that don't need land exclusion
NOTAGS = [
    ('board_wipe_count', 'board_wipe'),
    ('recursion_count', 'recursion'),
    ('wincon_count', 'wincon'),
    ('tutor_count', 'tutor'),
]
for col, tag in NOTAGS:
    sql = f'''
        UPDATE decks SET {col} = (
            SELECT COUNT(DISTINCT dc.id)
            FROM card_tags ct
            JOIN deck_cards dc ON ct.deck_card_id = dc.id
            WHERE dc.deck_id = decks.id AND ct.tag = '{tag}'
        )
    '''
    conn.execute(sql)

conn.commit()

print('=' * 80)
print('RELATORIO FINAL — Multi-Tag Backfill (excluindo lands de ramp/draw/etc)')
print('=' * 80)
print()

cmdrs = conn.execute('''
    SELECT c.name, d.total_cards, d.total_lands,
           d.ramp_count, d.draw_count, d.removal_count, d.board_wipe_count,
           d.protection_count, d.recursion_count, d.wincon_count, d.engine_count, d.tutor_count
    FROM decks d JOIN commanders c ON d.commander_id = c.id
    ORDER BY c.id
''').fetchall()

print(f"{'Comandante':30s} {'Ld':3s} {'Rmp':3s} {'Drw':3s} {'Rmv':3s} {'Wip':3s} {'Prt':3s} {'Rec':3s} {'Wnc':3s} {'Eng':3s} {'Ttr':3s}")
print('-' * 70)
for r in cmdrs:
    print(f"{r[0]:30s} {r[2]:3d} {r[3]:3d} {r[4]:3d} {r[5]:3d} {r[6]:3d} {r[7]:3d} {r[8]:3d} {r[9]:3d} {r[10]:3d} {r[11]:3d}")

total_ct = conn.execute('SELECT COUNT(*) FROM card_tags').fetchone()[0]
total_dc = conn.execute('SELECT COUNT(*) FROM deck_cards').fetchone()[0]
print(f'\nTotal: {total_dc} deck_cards, {total_ct} card_tags ({total_ct/total_dc:.1f} tags/carta em media)')
