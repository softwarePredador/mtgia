#!/usr/bin/env python3
"""
Importa conhecimento dos markdowns do Hermes para o PostgreSQL.
- THEMES.md → theme_contextual_rules
- Perfis de comandante → commander_reference_profiles
"""
import re
import json
import hashlib
import os
import sys

# Ensure we can import from the scripts directory
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from db_helper import run_sql

def parse_markdown_table(table_text):
    """Parse uma tabela markdown e retorna lista de dicts"""
    rows = []
    lines = [l.strip() for l in table_text.split('\n') if l.strip()]
    
    if len(lines) < 3:
        return rows
    
    # Header
    header = [h.strip() for h in lines[0].split('|')[1:-1]]
    # Separator (skip)
    # Data lines
    for line in lines[2:]:
        line = line.strip()
        if not line or not line.startswith('|'):
            continue
        cells = [c.strip() for c in line.split('|')[1:-1]]
        # Limpar markdown bold/italic
        cells = [re.sub(r'\*+', '', c).strip() for c in cells]
        if len(cells) == len(header):
            rows.append(dict(zip(header, cells)))
    
    return rows

def parse_themes_md(filepath):
    """Parse THEMES.md e extrai regras contextuais"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    rules = []
    
    # Encontrar todas as seções de tabela
    sections = [
        ('### Ramp por Tema', 'ramp'),
        ('### Draw por Tema', 'draw'),
        ('### Removal por Tema', 'removal'),
    ]
    
    for section_header, function_name in sections:
        # Encontrar a seção
        idx = content.find(section_header)
        if idx == -1:
            continue
        
        # Pegar até a próxima ### ou fim
        end_idx = content.find('\n### ', idx + len(section_header))
        if end_idx == -1:
            end_idx = len(content)
        
        section_text = content[idx:end_idx]
        
        # Encontrar a tabela (primeira linha com |)
        table_match = re.search(r'(\|.+\|\n\|[-|:\s]+\|\n(?:\|.+\|\n?)+)', section_text)
        if not table_match:
            continue
        
        table_text = table_match.group(1)
        rows = parse_markdown_table(table_text)
        
        for row in rows:
            # Extrair o nome do tema (primeira coluna)
            theme = list(row.values())[0].strip() if row else ''
            if not theme or theme == 'Tema':
                continue
            
            # Coluna de valor (segunda coluna)
            value_col = list(row.values())[1].strip() if len(row) > 1 else ''
            
            nums = re.findall(r'(\d+)', value_col)
            if not nums:
                continue
            
            min_count = int(nums[0])
            max_count = int(nums[1]) if len(nums) > 1 else min_count
            ideal = max_count
            
            # Notas (ultima coluna)
            notes = list(row.values())[-1].strip() if row else ''
            
            theme_slug = theme.lower().replace(' ', '_').replace('-', '_').replace("'", '')
            
            rules.append({
                'theme': theme_slug,
                'function': function_name,
                'min': min_count,
                'max': max_count,
                'ideal': ideal,
                'priority': 'essential' if function_name in ['ramp', 'draw'] and min_count >= 10 else 'high',
                'conditions': json.dumps({'theme_label': theme, 'notes': notes}),
                'description': f"{function_name.upper()} para {theme}: {min_count}-{max_count}. {notes}"
            })
    
    return rules

def extract_metrics_from_content(content):
    """Extrai métricas de um arquivo markdown de análise de deck"""
    metrics = {}
    
    patterns = {
        'lands': [r'[Ll]ands?\s*[:=]\s*(\d+)', r'Total\s+lands\s*[=:]\s*(\d+)'],
        'ramp': [r'[Rr]amp\s*(?:total)?\s*[:=]\s*(\d+)', r'[Rr]amp\s+/s*non-terreno\s*[:=]\s*(\d+)'],
        'draw': [r'[Dd]raw\s*(?:total|Rummage)?\s*[:=]\s*(\d+)', r'[Dd]raw\s+/s*loot\s*[:=]\s*(\d+)'],
        'removal': [r'[Rr]emoval\s*(?:total|spot)?\s*[:=]\s*(\d+)', r'[Ss]pot\s+interaction?\s*[:=]\s*(\d+)'],
        'board_wipes': [r'[Bb]oard\s*[Ww]ipe\s*[=:]\s*(\d+)', r'[Ww]ipe[s]?\s*[=:]\s*(\d+)'],
        'protection': [r'[Pp]rotection\s*[=:]\s*(\d+)'],
        'avg_cmc': [r'CMC\s*(?:medio|average|médio)\s*[:=]\s*([\d.]+)', r'[Aa]vg\.?\s*CMC\s*[:=]\s*([\d.]+)'],
    }
    
    for key, patterns_list in patterns.items():
        for pattern in patterns_list:
            match = re.search(pattern, content, re.MULTILINE)
            if match:
                val = float(match.group(1))
                metrics[key] = int(val) if val == int(val) else val
                break
    
    return metrics

def import_themes_to_db(rules):
    """Importa regras de tema para o PostgreSQL"""
    inserted = 0
    for rule in rules:
        # Escape single quotes
        theme = rule['theme'].replace("'", "''")
        func = rule['function']
        desc = rule['description'].replace("'", "''")
        cond = json.dumps(rule['conditions']).replace("'", "''")
        
        sql = f"""
        INSERT INTO theme_contextual_rules (theme, function, min_count, max_count, ideal_count, priority, conditions, description, source)
        VALUES ('{theme}', '{func}', {rule['min']}, {rule['max']}, {rule['ideal']}, '{rule['priority']}', '{cond}'::jsonb, '{desc}', 'themes_md')
        ON CONFLICT (theme, function) DO UPDATE SET
            min_count = EXCLUDED.min_count, max_count = EXCLUDED.max_count,
            ideal_count = EXCLUDED.ideal_count, priority = EXCLUDED.priority,
            conditions = EXCLUDED.conditions, description = EXCLUDED.description,
            updated_at = now()
        """
        result = run_sql(sql)
        if result and ('INSERT' in result or 'UPDATE' in result or (result.isdigit() and int(result) >= 0)):
            inserted += 1
            print(f"  ✅ {theme}/{func}: {rule['min']}-{rule['max']}")
    
    return inserted

def import_commander_profiles(profiles):
    """Importa perfis de comandante para o PostgreSQL"""
    inserted = 0
    for p in profiles:
        cmdr = p['commander_name'].replace("'", "''")
        profile_json = json.dumps(p['metrics']).replace("'", "''")
        source_file = p['source_file'].replace("'", "''")
        content_hash = p['content_hash']
        
        total_cards = sum(p['metrics'].values()) if p['metrics'] else 0
        
        # UPSERT
        sql = f"""
        INSERT INTO commander_reference_profiles (commander_name, source, deck_count, profile_json, updated_at)
        VALUES ('{cmdr}', 'hermes_analysis', {total_cards}, '{profile_json}'::jsonb, now())
        ON CONFLICT (commander_name) DO UPDATE SET
            deck_count = EXCLUDED.deck_count,
            profile_json = EXCLUDED.profile_json,
            updated_at = now()
        """
        result = run_sql(sql)
        if result and result.isdigit() and int(result) > 0:
            inserted += 1
            print(f"  ✅ {cmdr}: {p['metrics']}")
        
        # Registrar source
        sql_src = f"""
        INSERT INTO analysis_sources (source_file, source_type, commander_name, hash)
        VALUES ('{source_file}', 'scout', '{cmdr}', '{content_hash}')
        ON CONFLICT (source_file) DO UPDATE SET hash = EXCLUDED.hash, imported_at = now()
        """
        run_sql(sql_src)
    
    return inserted

def main():
    print("=== Importando conhecimento Hermes → PostgreSQL ===\n")
    
    # 1. Importar THEMES.md
    themes_path = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/THEMES.md'
    if os.path.exists(themes_path):
        print(f"Parseando THEMES.md...")
        rules = parse_themes_md(themes_path)
        print(f"  {len(rules)} regras extraídas")
        
        if rules:
            inserted = import_themes_to_db(rules)
            print(f"  {inserted} regras importadas/atualizadas\n")
    else:
        print(f"  Nao encontrado: {themes_path}\n")
    
    # 2. Importar perfis de comandante
    print("Parseando perfis de comandante...")
    profiles = []
    decks_dir = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/decks'
    
    if os.path.exists(decks_dir):
        for commander_dir in os.listdir(decks_dir):
            cmd_path = os.path.join(decks_dir, commander_dir)
            if not os.path.isdir(cmd_path):
                continue
            
            for fname in os.listdir(cmd_path):
                if any(kw in fname for kw in ['edhrec-avg', 'edhrec-default', 'user-decklist', 'optimized']):
                    filepath = os.path.join(cmd_path, fname)
                    try:
                        with open(filepath, 'r', encoding='utf-8') as f:
                            content = f.read()
                        
                        # Extrair nome do comandante
                        cmdr_match = re.search(r'Comandante:\s*(.+)', content)
                        commander_name = cmdr_match.group(1).strip() if cmdr_match else commander_dir.replace('-', ' ').title()
                        
                        metrics = extract_metrics_from_content(content)
                        
                        if metrics:
                            profiles.append({
                                'commander_name': commander_name,
                                'metrics': metrics,
                                'source_file': filepath,
                                'content_hash': hashlib.md5(content.encode()).hexdigest()
                            })
                    except Exception as e:
                        print(f"  Erro em {filepath}: {e}")
    
    print(f"  {len(profiles)} perfis encontrados")
    if profiles:
        inserted = import_commander_profiles(profiles)
        print(f"  {inserted} perfis atualizados\n")
    
    # 3. Verificar estado final
    print("=== Estado Final ===")
    for table in ['theme_contextual_rules', 'card_deck_profiles', 'analysis_sources', 'commander_reference_profiles']:
        result = run_sql(f"SELECT COUNT(*) FROM {table}")
        print(f"  {table}: {result}")

    # Quantos profiles tem JSON nao-vazio
    result = run_sql("SELECT COUNT(*) FROM commander_reference_profiles WHERE profile_json IS NOT NULL AND profile_json != '{}'")
    print(f"  commander_reference_profiles (preenchidos): {result}")

if __name__ == '__main__':
    print()
    main()
    print()
