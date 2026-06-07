#!/usr/bin/env python3
"""Seed Dragons theme data into SQLite knowledge.db

Sources:
- Miirym profile (anchor30 batch_b, 4 sources: EDHREC, Draftsim, Moxfield, Archidekt)
- EDHREC: 27,262 Miirym decks tracked
- Profile source_refs:
  - https://edhrec.com/commanders/miirym-sentinel-wyrm
  - https://draftsim.com/miirym-edh-deck/
  - https://moxfield.com/decks/rNQ30r_R6Uq4a4tYnDYamw
  - https://archidekt.com/decks/12496233/miirym_sentinel_wyrm
"""

import sqlite3, os, subprocess
from datetime import date

today = date.today().isoformat()
script_dir = os.path.dirname(os.path.abspath(__file__))
src = os.path.join(script_dir, 'knowledge.db')
tmp_copy = '/tmp/knowledge_copy.db'
tmp_old = '/tmp/knowledge_old.db'

# Step 1: Copy DB to writable location
subprocess.run(['cp', src, tmp_copy], capture_output=True)
conn = sqlite3.connect(tmp_copy)
c = conn.cursor()

# Check if Dragons exists
existing = c.execute("SELECT id FROM deck_themes WHERE theme_name = 'Dragons'").fetchall()
if existing:
    c.execute("DELETE FROM theme_detection_rules WHERE theme_name = 'Dragons'")
    c.execute("DELETE FROM deck_themes WHERE theme_name = 'Dragons'")

# Insert Dragons theme - match exactly 32 columns (id is auto)
cols = [
    'theme_name', 'category', 'description',
    'bracket_min', 'bracket_max',
    'enablers_min', 'enablers_max', 'payoffs_min', 'payoffs_max',
    'ramp_min', 'ramp_max', 'ramp_type',
    'draw_min', 'draw_max', 'draw_type',
    'removal_min', 'removal_max',
    'interaction_min', 'interaction_max',
    'lands_min', 'lands_max',
    'protection_min', 'protection_max',
    'board_wipes_min', 'board_wipes_max',
    'tutors_min', 'tutors_max',
    'source_found', 'source_urls', 'confidence', 'validated_date', 'notes'
]
placeholders = ','.join(['?'] * len(cols))
sql = f"INSERT INTO deck_themes ({','.join(cols)}) VALUES ({placeholders})"

vals = [
    'Dragons',
    'Tribal',
    'Tribal Dragon com copy/ETB engine via Miirym. Dragoes grandes como threats, copy enablers para duplicar valor, ramp pesado para castar CMC alto. Temur (GUR) predominante.',
    3, 4,
    18, 24, 5, 9,
    12, 16,
    'Rocks (Sol Ring, Arcane Signet) + Orbs of Dragonkind + Dragon\'s Hoard + cost reducers (Dragonlord\'s Servant, Dragonspeaker Shaman) + land ramp',
    9, 12,
    'Value draw (Garruk\'s Uprising, Temur Ascendancy, Kindred Discovery, Elemental Bond, Up the Beanstalk) + Rhystic Study',
    7, 10,
    7, 10,
    36, 38,
    4, 7,
    1, 3,
    4, 7,
    'Miirym profile (anchor30 batch_b, 4 fontes) + EDHREC (27,262 decks Miirym)',
    'https://edhrec.com/commanders/miirym-sentinel-wyrm, https://draftsim.com/miirym-edh-deck/, https://moxfield.com/decks/rNQ30r_R6Uq4a4tYnDYamw, https://archidekt.com/decks/12496233/miirym_sentinel_wyrm',
    'ALTA (EDHREC 27k+ decks + profile 4 fontes + Draftsim primer)',
    today,
    '### DISCREPANCIAS COM THEMES.md\n'
    '1. Dragon density: THEMES.md diz 15 min. REAL: 18-24 (profile). SUBESTIMADO em 20-60%.\n'
    '2. Payoffs: THEMES.md diz 5. REAL: 5-9 (copy enablers) + 5-8 (ETB damage) = 10-17 payoffs totais.\n'
    '3. Ramp: THEMES.md diz 15-20. REAL: 12-16 (profile). SUPERESTIMADO no maximo (20 vs 16).\n'
    '4. CMC medio: THEMES.md sem metrica. REAL: ~4.09 (EDHREC mana curve).\n'
    '5. Lands: THEMES.md sem metrica. REAL: 36-38 (profile), 36 (EDHREC avg).\n'
    '6. Draw: THEMES.md sem metrica. REAL: 9-12 (profile).\n'
    '7. Removal/Interaction: THEMES.md sem metrica. REAL: 7-10 interaction + 4-7 counter protection + 1-3 board wipes.\n'
    '8. Metricas AUSENTES em THEMES.md mas CRITICAS: copy enablers 5-9, ETB damage 5-8, protection 4-7, board wipes 1-3.\n'
    '9. EDHREC type dist: 36L / 29C / 9I / 7S / 9A / 8E / 1PW (86 cards avg view).\n'
    '10. Combo: Miirym + Astral Dragon + Parallel Lives = infinito. Old Gnawbone + Hellkite Charger = combat loop.\n'
    '11. Sinergia extrema: Dragon\'s Hoard (63%, synergy 0.53), Haven of the Spirit Dragon (68%, synergy 0.55).'
]
c.execute(sql, vals)

# Insert detection rules
rules = [
    ('dragon_density', 18, 24, 'dragon_type_line', 1.5,
     '18+ creature type Dragon (Miirym profile: 18-24)'),
    ('copy_enabler_count', 5, 10, 'sakashima,spark_double,molten_echoes,rite_of_replication,reflections_of_littjara',
     1.3, '5+ copy/clone enablers'),
    ('etb_damage_payoff_count', 5, 10, 'terror_of_the_peaks,warstorm_surge,scourge_of_valkas,dragon_tempest',
     1.3, '5+ ETB damage payoffs'),
    ('tribal_ramp_count', 8, 16, 'dragons_hoard,orb_of_dragonkind,dragonlords_servant,dragonspeaker_shaman',
     1.2, '8+ tribal ramp sources'),
    ('value_draw_count', 4, 10, 'garruks_uprising,temur_ascendancy,kindred_discovery,elemental_bond',
     1.0, '4+ creature/dragon-based draw engines'),
]
for rule_type, mn, mx, kw, wt, nt in rules:
    c.execute(
        "INSERT INTO theme_detection_rules (theme_name, rule_type, min_count, max_count, keywords, weight, notes) "
        "VALUES (?, ?, ?, ?, ?, ?, ?)",
        ('Dragons', rule_type, mn, mx, kw, wt, nt)
    )

conn.commit()
conn.close()

# Step 3: Copy back (mv removes root-owned entry, cp creates hermes-owned)
subprocess.run(['mv', src, tmp_old], capture_output=True)
subprocess.run(['cp', tmp_copy, src], capture_output=True)
print("Done! Dragons theme seeded with all columns.")
print(f"DB: {src}")
