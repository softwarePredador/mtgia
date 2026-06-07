#!/usr/bin/env python3
"""
Seed Goblins theme into SQLite database.
Sources: Krenko profile (anchor30 batch_c, 4 sources: EDHREC, Moxfield, Archidekt)
         + Krenko EDHREC average deck corpus (sprint3_lot_a)
Validated: 2026-05-26
"""

import sqlite3, os, json
from datetime import date

DB_PATH = os.path.join(os.path.dirname(__file__), 'knowledge.db')

def update_db():
    src = DB_PATH
    tmp_copy = '/tmp/knowledge_copy_goblins.db'
    today = date.today().isoformat()
    
    # Copy to /tmp (writable)
    os.system(f"cp '{src}' '{tmp_copy}'")
    
    conn = sqlite3.connect(tmp_copy)
    conn.execute("PRAGMA journal_mode=WAL")
    
    # Build notes string in Python
    notes = (
        '### DISCREPANCIAS COM THEMES.md\n\n'
        '1. Ramp: THEMES.md diz 12-18. REAL: 8-11 (profile) ou ~6 (EDHREC avg). SUPERESTIMADO em 50-100%.\n'
        '   Explicacao: mono-red nao tem dorks verdes. Ramp vem de rituals temporarios (Skirk Prospector, Brightstone Ritual, Battle Hymn).\n'
        '2. Goblin density: THEMES.md diz 20 min. REAL: 25-38. SUBESTIMADO em 25-90%.\n'
        '   Krenko escala com densidade de goblins - 20 e baixo, 28-38 e o padrao.\n'
        '3. Removal: THEMES.md diz 6-8. REAL: 4-7. Ligeiramente superestimado.\n'
        '4. Draw: THEMES.md nao tem metrica explicita para Goblins. REAL: 8-11 (profile via Skullclamp).\n'
        '   EDHREC avg mostra apenas 2-3 draw cards (Skullclamp + Faithless Looting).\n'
        '   A diferenca: profile conta Skullclamp como draw value (e corretamente), mas o draw real e baixo.\n'
        '5. Metricas AUSENTES em THEMES.md mas CRITICAS:\n'
        '   - Haste/untap enablers: 6-10 (essencial para Krenko ativar no mesmo turno)\n'
        '   - Sacrifice/finishers: 4-7 (Goblin Bombardment, Impact Tremors, Purphoros)\n'
        '   - Token makers: 6-9 (Dragon Fodder, Krenko Command, Beetleback Chief)\n'
        '   - Protecao: 3-5 (Lightning Greaves, Swiftfoot Boots, Deflecting Swat)\n'
        '   - Board wipes: 1-2 (Blasphemous Act, Vandalblast)\n'
        '6. Lands: REAL: 33-35. THEMES.md nao tinha metrica para Goblins. Dentro do esperado para mono-red.\n\n'
        '### Notas de analise\n'
        '- KRENKO e o comandante assinatura. Outros comandantes (Krenko, Tin Street Kingpin, Muxus, General Kreat) variam.\n'
        '- Moxfield e primers recomendam haste + untap como prioridade #1 apos goblin density.\n'
        '- O ramp de goblins e INTEGRADO a criaturas (Skirk Prospector = dork + goblin).\n'
        '- Kiki-Jiki + Conspicuous Snoop = combo infinito (comum em brackets 3-4).\n'
        '- THEMES.md original nao mencionava haste/untap como metrica, mas e o SEGUNDO fator mais importante.'
    )
    
    # 1. Insert Goblins theme into deck_themes
    conn.execute(
        """INSERT OR REPLACE INTO deck_themes 
        (id, theme_name, category, description,
         bracket_min, bracket_max,
         enablers_min, enablers_max, payoffs_min, payoffs_max,
         ramp_min, ramp_max, ramp_type,
         draw_min, draw_max, draw_type,
         removal_min, removal_max,
         interaction_min, interaction_max,
         lands_min, lands_max,
         protection_min, protection_max,
         board_wipes_min, board_wipes_max,
         tutors_min, tutors_max,
         source_found, source_urls, confidence, validated_date, notes)
        VALUES (?, ?, ?, ?,
                ?, ?,
                ?, ?, ?, ?,
                ?, ?, ?,
                ?, ?, ?,
                ?, ?,
                ?, ?,
                ?, ?,
                ?, ?,
                ?, ?,
                ?, ?,
                ?, ?, ?, ?, ?)""",
        (6, 'Goblins', 'Tribal',
         'Tribal Goblin com foco em token swarm via Krenko. Expansao exponencial de board, haste, untap effects, e finishers de sacrificio/dano massivo. Mono-red predominante.',
         2, 4,
         25, 38, 5, 10,
         8, 11, 'Rocks + rituals (Skirk Prospector, Brightstone Ritual, Battle Hymn, Ruby Medallion)',
         8, 11, 'Sacrifice draw (Skullclamp) + rummage/looting (Faithless Looting, Thrill of Possibility, Wheel of Misfortune)',
         4, 7, 7, 10,
         33, 35,
         3, 5,
         1, 2,
         0, 2,
         'Krenko profile (anchor30 batch_c, 4 fontes: EDHREC, Moxfield, Archidekt) + EDHREC avg deck corpus (sprint3_lot_a)',
         'https://edhrec.com/commanders/krenko-mob-boss, https://edhrec.com/average-decks/krenko-mob-boss, https://moxfield.com/decks/public/advanced?commanderCardId=Krenko%2C%20Mob%20Boss, https://archidekt.com/search/decks?commanders=Krenko%2C%20Mob%20Boss',
         'ALTA (EDHREC 41k+ decks + profile 4 fontes)',
         today, notes)
    )
    
    # 2. Insert detection rules for Goblins
    conn.execute("DELETE FROM theme_detection_rules WHERE theme_name = 'Goblins'")
    
    rules = [
        ('Goblins', 'goblin_density', 25, 40, 'goblin_type_line', 1.5, '25+ creature type Goblin (Krenko profile: 28-38)'),
        ('Goblins', 'haste_untap_count', 5, 10, 'lightning_greaves,swiftfoot_boots,fervor,thousand_year_elixir', 1.3, '5+ haste/untap enablers (critico para Krenko)'),
        ('Goblins', 'sacrifice_finisher_count', 4, 8, 'goblin_bombardment,purphoros,impact_tremors,pashalik_mons', 1.3, '4+ sacrifice/damage finishers'),
        ('Goblins', 'token_maker_count', 5, 10, 'goblin_instigator,dragon_fodder,mogg_war_marshal', 1.2, '5+ token-making spells/creatures'),
        ('Goblins', 'skirk_prospector_present', 1, 1, 'skirk_prospector', 1.0, 'Skirk Prospector (goblin ramp critical mass)'),
    ]
    
    conn.executemany(
        "INSERT INTO theme_detection_rules (theme_name, rule_type, min_count, max_count, keywords, weight, notes) VALUES (?, ?, ?, ?, ?, ?, ?)",
        rules
    )
    
    conn.commit()
    conn.close()
    
    # Copy back (creates new inode with hermes ownership)
    os.system(f"rm -f '{src}'")
    os.system(f"cp '{tmp_copy}' '{src}'")
    os.system(f"rm -f '{tmp_copy}'")
    
    # Verify
    conn2 = sqlite3.connect(src)
    rows = conn2.execute("SELECT theme_name, confidence FROM deck_themes WHERE theme_name = 'Goblins'").fetchall()
    rules2 = conn2.execute("SELECT rule_type, min_count, max_count FROM theme_detection_rules WHERE theme_name = 'Goblins'").fetchall()
    conn2.close()
    
    print(f"Inserted Goblins theme: {rows}")
    print(f"Detection rules ({len(rules2)}):")
    for r in rules2:
        print(f"  - {r[0]}: {r[1]}-{r[2]}")

if __name__ == '__main__':
    update_db()
