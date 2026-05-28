#!/usr/bin/env python3
"""Importa card_deck_profiles dos arquivos de análise de deck para o PostgreSQL."""
import os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from db_helper import run_sql, DB_PARAMS

DB = {'host': DB_PARAMS['host'], 'port': DB_PARAMS['port'], 'dbname': DB_PARAMS['dbname'],
      'user': DB_PARAMS['user'], 'password': DB_PARAMS['password']}

def esc(s):
    return s.replace("'", "''") if s else ''

def insert_profile(card, commander, tag, func, importance, reason, source):
    sql = (f"INSERT INTO card_deck_profiles (card_name, commander_name, "
           f"generic_tag, contextual_function, importance, reason, source) VALUES "
           f"('{esc(card)}', '{esc(commander)}', '{esc(tag)}', '{esc(func)}', "
           f"'{importance}', '{esc(reason)[:500]}', '{source}')")
    return run_sql(sql)

def extract_from_file(filepath, commander_name):
    """Extrai perfis de carta de um arquivo markdown de análise."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except:
        return 0
    
    inserted = 0
    
    # Padrão 1: Tabelas markdown | Card | Tag | ...
    for table_m in re.finditer(r'(\|.+\|\n\|[-|:\s]+\|\n(?:\|.+\|\n?)+)', content):
        lines = [l.strip() for l in table_m.group(1).split('\n') if l.strip()]
        if len(lines) < 3: continue
        headers = [h.strip().lower() for h in lines[0].split('|')[1:-1]]
        for line in lines[2:]:
            cells = [c.strip() for c in line.split('|')[1:-1]]
            if len(cells) != len(headers): continue
            row = dict(zip(headers, cells))
            card = row.get('card', row.get('carta', '')).strip()
            if not card or len(card) > 50: continue
            tag = row.get('tag', row.get('type', row.get('tipo', ''))).strip()
            func = row.get('function', row.get('função', tag)).strip()
            imp = 'medium'
            val = row.get('status', row.get('importance', '')).lower()
            if '✅' in val or 'essential' in val: imp = 'essential'
            elif '🟡' in val or 'high' in val: imp = 'high'
            elif '🔴' in val or 'remov' in val: imp = 'removable'
            r = insert_profile(card, commander_name, tag, func, imp, 
                             f"De: {os.path.basename(filepath)}", 'analysis_table')
            if r: inserted += 1
    
    # Padrão 2: Linhas com **Carta (X%)** do scout
    for m in re.finditer(r'\*\*([^*]+)\*\*\s*\((\d+)%\)', content):
        card = m.group(1).strip()
        pct = int(m.group(2))
        if len(card) > 50: continue
        imp = 'essential' if pct >= 70 else 'high' if pct >= 50 else 'medium' if pct >= 30 else 'low'
        r = insert_profile(card, commander_name, None, f'EDHREC {pct}%', imp,
                         f'Inclusão EDHREC: {pct}%', 'edhrec_inclusion')
        if r: inserted += 1
    
    return inserted

def main():
    print("=== Importando card_deck_profiles ===\n")
    decks_dir = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/decks'
    total = 0
    if not os.path.exists(decks_dir):
        print(f"Nao encontrado: {decks_dir}"); return
    
    for cmd_dir in sorted(os.listdir(decks_dir)):
        cmd_path = os.path.join(decks_dir, cmd_dir)
        if not os.path.isdir(cmd_path): continue
        commander = cmd_dir.replace('-', ' ').replace('_', ' ').title()
        for fname in sorted(os.listdir(cmd_path)):
            if not fname.endswith('.md'): continue
            n = extract_from_file(os.path.join(cmd_path, fname), commander)
            if n:
                print(f"  {commander}/{fname}: {n} perfis")
                total += n
    
    result = run_sql("SELECT COUNT(*) FROM card_deck_profiles")
    print(f"\nTotal em card_deck_profiles: {result}")

if __name__ == '__main__':
    main()
