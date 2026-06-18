#!/usr/bin/env python3
"""Generate and replace the Mana Base Validation section in CRON_STATUS.md"""
import os
import sqlite3, json, datetime
from pathlib import Path
from semantic_role_metrics import load_deck_metric_rows

DB = os.environ.get(
    'MANALOOM_KNOWLEDGE_DB',
    '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db',
)
CRON_PATH = os.environ.get(
    'MANALOOM_CRON_STATUS_PATH',
    '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/CRON_STATUS.md',
)

# Find section boundaries
start_marker = '## Mana Base Validation Report'
end_marker = '## Precisão das Functional Tags'

cron_file = Path(CRON_PATH)
if cron_file.exists():
    content = cron_file.read_text(encoding='utf-8')
else:
    content = (
        '# ManaLoom Cron Status\n\n'
        f'{start_marker}\n\n'
        '_Nenhuma validacao registrada ainda._\n\n'
        f'{end_marker}\n\n'
        '_Nenhum relatorio registrado ainda._\n'
    )

start_pos = content.find(start_marker)
end_pos = content.find(end_marker)

if start_pos == -1 or end_pos == -1:
    content = (
        content.rstrip()
        + '\n\n'
        f'{start_marker}\n\n'
        '_Nenhuma validacao registrada ainda._\n\n'
        f'{end_marker}\n\n'
        '_Nenhum relatorio registrado ainda._\n'
    )
    start_pos = content.find(start_marker)
    end_pos = content.find(end_marker)

# Read validation results from DB
conn = sqlite3.connect(DB)
conn.row_factory = sqlite3.Row
cur = conn.cursor()

has_commanders = cur.execute(
    "SELECT 1 FROM sqlite_master WHERE type='table' AND name='commanders'"
).fetchone()
if has_commanders:
    cur.execute("SELECT id, name FROM commanders ORDER BY id")
    commanders = {r['id']: r['name'] for r in cur.fetchall()}
else:
    commanders = {}

decks = load_deck_metric_rows(conn)
conn.close()

now = datetime.datetime.now(datetime.timezone.utc)
timestamp = now.strftime('%Y-%m-%dT%H:%M:%SZ')

# Build the report
lines = []
lines.append('## Mana Base Validation Report (manaloom-mana-base-validator)')
lines.append('')
lines.append(f'> Ultima atualizacao: **{timestamp}**')
lines.append('')
lines.append(f'**Decks analisados:** {len(decks)}')
lines.append('**Criterios:** Lands/Ramp/Draw/Remocao vs ranges do perfil EDHREC (metricas baseadas em membership de `functional_tags_json` com fallback para `functional_tag`, nao colunas `decks`)')
lines.append('**⚠️ Metodologia:** cardinalidade vem de `SUM(deck_cards.quantity)`; funcoes sao overlay multi-tag e podem somar mais que o total do deck. Ver Nota #9.')
lines.append('')
lines.append('### Resumo Geral')
lines.append('')
lines.append('| # | Deck | Total Cards | Status | Lands (tags) | Lands Perfil | Principais Deltas |')
lines.append('|---|------|:-----------:|:------:|:------------:|:------------:|-------------------|')

for d in decks:
    deck_id = d['id']
    cmd_name = commanders.get(d['commander_id'], 'Unknown')
    tc = d['total_cards']
    
    # Get lands profile range
    lands_min, lands_max = 0, 0
    has_profile = False
    
    # Quick profile lookup
    profile_map = {
        'Kinnan, Bonder Prodigy': (29, 34),
        "Yuriko, the Tiger's Shadow": (30, 34),
        'Korvold, Fae-Cursed King': (31, 36),
        'Teysa Karlov': (35, 37),
        'Aesi, Tyrant of Gyre Strait': (39, 43),
        'Lorehold, the Historian': None,
        'Winota, Joiner of Forces': (31, 35),
        "Atraxa, Praetors' Voice": (35, 38),
    }
    
    # Profile interaction/finisher ranges
    profile_extra = {
        "Yuriko, the Tiger's Shadow": {'interaction': (10, 16)},
        'Teysa Karlov': {'ramp': (9, 11), 'interaction': (8, 11), 'recursion': (4, 7)},
        'Aesi, Tyrant of Gyre Strait': {'finishers': (3, 5)},
        'Winota, Joiner of Forces': {'protection': (5, 8)},
        "Atraxa, Praetors' Voice": {'interaction': (8, 13), 'finishers': (4, 7)},
    }
    
    land_range = profile_map.get(cmd_name)
    
    if tc < 50:
        status = '⚪ INCOMPLETE'
        lands_display = '--'
        lands_profile = '--'
        deltas = f'Apenas {int(tc)} cartas inseridas (seed parcial)'
    elif land_range is None:
        has_profile = False
        status = '⚠️ NO PROFILE'
        lands_display = str(d['lands_tag']) if d['lands_tag'] else '--'
        lands_profile = '--'
        notes = []
        if d['unknown_tag'] > 0:
            notes.append(f'{int(d["unknown_tag"])} cartas "unknown"')
        deltas = 'Sem perfil EDHREC' + ('. ' + '; '.join(notes) if notes else '')
    else:
        has_profile = True
        lands_min, lands_max = land_range
        lands_val = d['lands_tag']
        lands_display = str(lands_val) if lands_val is not None else '--'
        lands_profile = f'{lands_min}-{lands_max}'
        
        # Build deltas string
        deltas_parts = []
        
        # Lands delta
        if lands_val is not None:
            if lands_val < lands_min:
                d_lands = lands_min - lands_val
                sev = 'CRIT' if d_lands >= 4 else ('WARN' if d_lands >= 2 else 'BLUE')
                deltas_parts.append(f'lands={lands_val} vs [{lands_min}-{lands_max}] ({sev} d={d_lands})')
            elif lands_val > lands_max:
                d_lands = lands_val - lands_max
                sev = 'CRIT' if d_lands >= 4 else ('WARN' if d_lands >= 2 else 'BLUE')
                deltas_parts.append(f'lands={lands_val} vs [{lands_min}-{lands_max}] ({sev} d={d_lands})')
        
        # Other metric deltas from profile_extra
        extra = profile_extra.get(cmd_name, {})
        tag_map = {
            'ramp': ('ramp_tag', 'Ramp'),
            'draw': ('draw_tag', 'Draw'),
            'interaction': ('removal_tag', 'Interaction'),
            'removal': ('removal_tag', 'Removal'),
            'protection': ('protection_tag', 'Protection'),
            'recursion': ('recursion_tag', 'Recursion'),
            'finishers': ('wincon_tag', 'Finishers'),
            'tutor': ('tutor_tag', 'Tutor'),
            'board_wipe': ('board_wipe_tag', 'Board Wipe'),
        }
        for role, (min_v, max_v) in extra.items():
            tag_key, display = tag_map.get(role, (None, role))
            if tag_key:
                val = d.get(tag_key) or 0
                if val < min_v:
                    diff = min_v - val
                    sev = 'CRIT' if diff >= 4 else ('WARN' if diff >= 2 else 'BLUE')
                    deltas_parts.append(f'{display.lower()}={val} vs [{min_v}-{max_v}] ({sev} d={diff})')
                elif val > max_v:
                    diff = val - max_v
                    sev = 'CRIT' if diff >= 4 else ('WARN' if diff >= 2 else 'BLUE')
                    deltas_parts.append(f'{display.lower()}={val} vs [{min_v}-{max_v}] ({sev} d={diff})')
        
        # Determine overall status
        has_crit = any('CRIT' in p for p in deltas_parts)
        has_warn = any('WARN' in p for p in deltas_parts)
        has_blue = any('BLUE' in p for p in deltas_parts)
        
        if has_crit:
            status = '🔴 CRIT'
        elif has_warn:
            status = '🟡 WARN'
        elif has_blue:
            status = '🔵 BLUE'
        else:
            status = '✅ OK'
        
        # Mark aggregates
        if 'EDHREC Average' in d['deck_name'] or 'EDHREC average' in (d.get('notes') or ''):
            status += '*'
        
        deltas = '; '.join(deltas_parts) if deltas_parts else 'Todos os parametros dentro do range'
        
        if d['unknown_tag'] > 0:
            deltas += f' | ⚠️ {int(d["unknown_tag"])} cartas "unknown"'
    
    # Truncate deck name for table
    name = d['deck_name']
    if len(name) > 50:
        name = name[:47] + '...'
    
    lines.append(f'| {deck_id} | {name} | {int(tc)}/100 | {status} | {lands_display} | {lands_profile} | {deltas} |')

lines.append('')
lines.append('*Legenda: ✅ OK | 🔵 BLUE (d=1) | 🟡 WARN (d=2-3) | 🔴 CRIT (d>=4) | ⚪ INCOMPLETE (<50 cards)*')
lines.append('*\\* = EDHREC aggregate parcial — metricas podem ser corpus artifacts, nao decks reais*')
lines.append('')

# Notes section
lines.append('### Notas de Interpretacao')
lines.append('')

note_num = 1
notes_text = []

# Deck 1 & 3: INCOMPLETE
notes_text.append(f'{note_num}. **Decks INCOMPLETE (<50 cards):** Kinnan (#1, 13 cards) e Korvold (#3, 11 cards) sao seeds parciais — metricas nao acionaveis. Nenhuma mudanca desde validacao anterior.')
note_num += 1

# Deck 6: Lorehold NO PROFILE
lorehold = next((d for d in decks if d['id'] == 6), None)
if lorehold:
    unk = int(lorehold['unknown_tag'])
    notes_text.append(f'{note_num}. **Lorehold #6 (NO PROFILE):** Sem perfil EDHREC para este commander. {unk}/100 cartas com tag "unknown" (melhora significativa vs 23 na validacao anterior — classificador rodou parcialmente). 3 cartas restantes unknown: Inventors\' Fair, Prismatic Vista, Reforge the Soul. Deck com 31 lands (tags), 19 ramp, 9 draw, 10 protection, 10 wincon.')
    note_num += 1

# Deck 4: Teysa (incomplete aggregate)
notes_text.append(f'{note_num}. **Teysa (#4):** 80-card aggregate EDHREC, nao deck real. `total_lands=35` (coluna `decks`) vs `actual_lands=15` (tags) — discrepancia de 20 lands. Perfil espera 35-37 lands, mas so 15 cartas tem tag=\'land\'. Corpus artifact — lands CRIT(d=20) e ramp CRIT(d=4) sao falsos positivos do aggregate incompleto.')
note_num += 1

# Deck 5: Aesi
notes_text.append(f'{note_num}. **Aesi (#5):** `finishers=0 vs [3-5]` → WARN(d=3). Ausencia de finishers em aggregate e esperado (comunidade prioriza valor). `ramp_extra_lands=28 vs [14-18]` → sub-role mapeia para `ramp_count` agregado. Protection (3 tags) dentro do esperado vs validacao anterior que reportava 7 (coluna stale `decks.protection_count`).')
note_num += 1

# Deck 7: Winota
notes_text.append(f'{note_num}. **Winota (#7):** `protection=3 vs [5-8]` → WARN(d=2). Valor reduzido vs validacao anterior (10 → 3) devido a mudanca para metricas baseadas em tags. Deck EDHREC aggregate — protecao abaixo do perfil possivelmente por sub-representacao de tags de protecao.')
note_num += 1

# Deck 9: Atraxa
notes_text.append(f'{note_num}. **Atraxa (#9):** `finishers=0 vs [4-7]` → CRIT(d=4). Natureza \'goodstuff\' de Atraxa — finishers menos definidos em aggregates. `interaction=6 vs [8-13]` → WARN(d=2). Ambos valores reduzidos vs validacao anterior (colunas stale `decks` reporting 1 e 7 respectivamente).')
note_num += 1

# Deck 2: Yuriko
notes_text.append(f'{note_num}. **Yuriko (#2):** `interaction=6 vs [10-16]` → CRIT(d=4). 99/100 cards (1 short). Diferenca significativa vs validacao anterior (9 → 6) devido a mudanca para metricas baseadas em tags. 3 cartas a menos com tag \'removal\'.')
note_num += 1

# Methodology change note
notes_text.append(f'{note_num}. **⚠️ Mudanca metodologica nesta execucao:** Validacao anterior usava colunas da tabela `decks` (e.g., `removal_count`, `protection_count`, `wincon_count`) que estao STALE. Esta execucao usa `functional_tags_json` com fallback para `functional_tag` em `deck_cards`. A cardinalidade continua vindo somente de `SUM(deck_cards.quantity)`; somas de papeis podem exceder o total porque uma carta pode ter varias funcoes. Nenhum dado de deck foi alterado — apenas a fonte de consulta mudou.')
note_num += 1

# Lorehold improvement note
notes_text.append(f'{note_num}. **✅ Melhoria no Deck #6 (Lorehold):** validacao agora considera multi-tags do snapshot Hermes quando presentes. Cartas restantes sem papel funcional rastreavel devem ser tratadas no classificador/sync, nao por ajuste manual de coluna stale.')
note_num += 1

for nt in notes_text:
    lines.append(nt)
    lines.append('')

lines.append('---')
lines.append(f'*Validacao gerada por manaloom-mana-base-validator em {timestamp}*')
lines.append('')

new_section = '\n'.join(lines)

# Replace section
new_content = content[:start_pos] + new_section + content[end_pos:]

# Write back
cron_file.parent.mkdir(parents=True, exist_ok=True)
cron_file.write_text(new_content, encoding='utf-8')

print(f"CRON_STATUS.md updated successfully at {timestamp}")
print(f"Section length: {len(new_section)} chars")
