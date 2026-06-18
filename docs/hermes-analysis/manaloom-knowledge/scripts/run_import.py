#!/usr/bin/env python3
"""
Runner: import_knowledge + import_card_profiles via psycopg2 (no psql needed).
Reuses parsing functions from the original scripts but replaces run_sql().
"""
import sys
import os
import re
import json
import hashlib
from pathlib import Path

# Agregar scripts/ al path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)

import psycopg2
import psycopg2.extras

from db_helper import connect, sanitized_database_target

DRY_RUN = os.environ.get("MANALOOM_IMPORT_APPLY") != "1"


def _resolve_repo_root() -> Path:
    for key in ("MANALOOM_REPO", "MANALOOM_WORKSPACE", "HERMES_REPO_DIR"):
        value = os.environ.get(key)
        if value:
            candidate = Path(value).resolve()
            if candidate.exists():
                return candidate
    return Path(__file__).resolve().parents[4]


REPO_ROOT = _resolve_repo_root()
KNOWLEDGE_ROOT = Path(
    os.environ.get(
        "MANALOOM_KNOWLEDGE_ROOT",
        str(REPO_ROOT / "docs" / "hermes-analysis" / "manaloom-knowledge"),
    )
).resolve()
THEMES_PATH = Path(
    os.environ.get("MANALOOM_THEMES_MD", str(KNOWLEDGE_ROOT / "THEMES.md"))
).resolve()
DECKS_DIR = Path(
    os.environ.get("MANALOOM_KNOWLEDGE_DECKS_DIR", str(KNOWLEDGE_ROOT / "decks"))
).resolve()

def get_conn():
    return connect()

def run_sql(conn, sql, params=None, fetch=False):
    if DRY_RUN and not fetch and not sql.lstrip().upper().startswith("SELECT"):
        return 0
    with conn.cursor() as cur:
        cur.execute(sql, params)
        if fetch:
            return cur.fetchall()
        conn.commit()
        return cur.rowcount

# ── Parsing helpers (from import_knowledge.py) ──────────────────────────

def parse_markdown_table(table_text):
    rows = []
    lines = [l.strip() for l in table_text.split('\n') if l.strip()]
    if len(lines) < 3:
        return rows
    header = [h.strip() for h in lines[0].split('|')[1:-1]]
    for line in lines[2:]:
        line = line.strip()
        if not line or not line.startswith('|'):
            continue
        cells = [c.strip() for c in line.split('|')[1:-1]]
        cells = [re.sub(r'\*+', '', c).strip() for c in cells]
        if len(cells) == len(header):
            rows.append(dict(zip(header, cells)))
    return rows

def parse_themes_md(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    rules = []
    sections = [
        ('### Ramp por Tema', 'ramp'),
        ('### Draw por Tema', 'draw'),
        ('### Removal por Tema', 'removal'),
    ]
    for section_header, function_name in sections:
        idx = content.find(section_header)
        if idx == -1:
            continue
        end_idx = content.find('\n### ', idx + len(section_header))
        if end_idx == -1:
            end_idx = len(content)
        section_text = content[idx:end_idx]
        table_match = re.search(r'(\|.+\|\n\|[-|: :]+\|\n(?:\|.+\|\n?)+)', section_text)
        if not table_match:
            continue
        rows = parse_markdown_table(table_match.group(1))
        for row in rows:
            theme = list(row.values())[0].strip() if row else ''
            if not theme or theme == 'Tema':
                continue
            value_col = list(row.values())[1].strip() if len(row) > 1 else ''
            nums = re.findall(r'(\d+)', value_col)
            if not nums:
                continue
            min_count = int(nums[0])
            max_count = int(nums[1]) if len(nums) > 1 else min_count
            ideal = max_count
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
    metrics = {}
    patterns = {
        'lands': [r'[Ll]ands?\s*[:=]\s*(\d+)', r'Total\s+lands\s*[=:]\s*(\d+)'],
        'ramp': [r'[Rr]amp\s*(?:total)?\s*[:=]\s*(\d+)', r'[Rr]amp\s*/s*non-terreo\s*[:=]\s*(\d+)'],
        'draw': [r'[Dd]raw\s*(?:total|Rummage)?\s*[:=]\s*(\d+)', r'[Dd]raw\s*/s*loot\s*[:=]\s*(\d+)'],
        'removal': [r'[Rr]emoval\s*(?:total|spot)?\s*[:=]\s*(\d+)', r'[Ss]pot\s+interaction?\s*[:=]\s*(\d+)'],
        'board_wipes': [r'[Bb]oard\s*[Ww]ipe\s*[=:]\s*(\d+)', r'[Ww]ipe[s]?\s*[=:]\s*(\d+)'],
        'protection': [r'[Pp]rotection\s*[=:]\s*(\d+)'],
        'avg_cmc': [r'CMC\s*(?:medio|average|mdio)\s*[:=]\s*([\d.]+)', r'[Aa]vg\.?\s*CMC\s*[:=]\s*([\d.]+)'],
    }
    for key, patterns_list in patterns.items():
        for pattern in patterns_list:
            match = re.search(pattern, content, re.MULTILINE)
            if match:
                val = float(match.group(1))
                metrics[key] = int(val) if val == int(val) else val
                break
    return metrics

# ── Importers ────────────────────────────────────────────────────────────

def import_themes(conn, rules):
    inserted = 0
    for rule in rules:
        sql = """
        INSERT INTO theme_contextual_rules (theme, function, min_count, max_count, ideal_count, priority, conditions, description, source)
        VALUES (%s, %s, %s, %s, %s, %s, %s::jsonb, %s, 'themes_md')
        ON CONFLICT (theme, function) DO UPDATE SET
            min_count = EXCLUDED.min_count, max_count = EXCLUDED.max_count,
            ideal_count = EXCLUDED.ideal_count, priority = EXCLUDED.priority,
            conditions = EXCLUDED.conditions, description = EXCLUDED.description,
            updated_at = now()
        """
        params = (rule['theme'], rule['function'], rule['min'], rule['max'],
                  rule['ideal'], rule['priority'], rule['conditions'], rule['description'])
        run_sql(conn, sql, params)
        inserted += 1
        print(f"  ✅ {rule['theme']}/{rule['function']}: {rule['min']}-{rule['max']}")
    return inserted

def import_commander_profiles(conn, profiles):
    inserted = 0
    for p in profiles:
        cmdr = p['commander_name']
        profile_json = json.dumps(p['metrics'])
        source_file = p['source_file']
        content_hash = p['content_hash']
        total_cards = sum(p['metrics'].values()) if p['metrics'] else 0

        sql = """
        INSERT INTO commander_reference_profiles (commander_name, source, deck_count, profile_json, updated_at)
        VALUES (%s, 'hermes_analysis', %s, %s::jsonb, now())
        ON CONFLICT (commander_name) DO UPDATE SET
            deck_count = EXCLUDED.deck_count,
            profile_json = EXCLUDED.profile_json,
            updated_at = now()
        """
        run_sql(conn, sql, (cmdr, total_cards, profile_json))

        sql_src = """
        INSERT INTO analysis_sources (source_file, source_type, commander_name, hash)
        VALUES (%s, 'scout', %s, %s)
        ON CONFLICT (source_file) DO UPDATE SET hash = EXCLUDED.hash, imported_at = now()
        """
        run_sql(conn, sql_src, (source_file, cmdr, content_hash))
        inserted += 1
        print(f"  ✅ {cmdr}: {p['metrics']}")
    return inserted

def import_card_profiles(conn, decks_dir):
    total = 0
    if not os.path.exists(decks_dir):
        print(f"  Nao encontrado: {decks_dir}")
        return 0

    for cmd_dir in sorted(os.listdir(decks_dir)):
        cmd_path = os.path.join(decks_dir, cmd_dir)
        if not os.path.isdir(cmd_path):
            continue
        commander = cmd_dir.replace('-', ' ').replace('_', ' ').title()
        for fname in sorted(os.listdir(cmd_path)):
            if not fname.endswith('.md'):
                continue
            filepath = os.path.join(cmd_path, fname)
            n = _extract_card_profiles(conn, filepath, commander)
            if n:
                print(f"  {commander}/{fname}: {n} perfis")
                total += n
    return total

def _extract_card_profiles(conn, filepath, commander_name):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return 0

    inserted = 0

    # Padrão 1: Tabelas markdown
    for table_m in re.finditer(r'(\|.+\|\n\|[-|: :]+\|\n(?:\|.+\|\n?)+)', content):
        lines = [l.strip() for l in table_m.group(1).split('\n') if l.strip()]
        if len(lines) < 3:
            continue
        headers = [h.strip().lower() for h in lines[0].split('|')[1:-1]]
        for line in lines[2:]:
            cells = [c.strip() for c in line.split('|')[1:-1]]
            if len(cells) != len(headers):
                continue
            row = dict(zip(headers, cells))
            card = row.get('card', row.get('carta', '')).strip()
            if not card or len(card) > 50:
                continue
            tag = row.get('tag', row.get('type', row.get('tipo', ''))).strip()
            func = row.get('function', row.get('funo', tag)).strip()
            imp = 'medium'
            val = row.get('status', row.get('importance', '')).lower()
            if '✅' in val or 'essential' in val:
                imp = 'essential'
            elif '🟡' in val or 'high' in val:
                imp = 'high'
            elif '🔴' in val or 'remov' in val:
                imp = 'removable'
            if _insert_card(conn, card, commander_name, tag, func, imp,
                           f"De: {os.path.basename(filepath)}", 'analysis_table'):
                inserted += 1

    # Padrão 2: Linhas com **Carta (X%)** do scout
    for m in re.finditer(r'\*\*([^*]+)\*\*\s*\((\d+)%\)', content):
        card = m.group(1).strip()
        pct = int(m.group(2))
        if len(card) > 50:
            continue
        imp = 'essential' if pct >= 70 else 'high' if pct >= 50 else 'medium' if pct >= 30 else 'low'
        if _insert_card(conn, card, commander_name, None, f'EDHREC {pct}%', imp,
                        f'Inclusão EDHREC: {pct}%', 'edhrec_inclusion'):
            inserted += 1

    return inserted

def _insert_card(conn, card, commander, tag, func, importance, reason, source):
    sql = """INSERT INTO card_deck_profiles (card_name, commander_name,
             generic_tag, contextual_function, importance, reason, source)
             VALUES (%s, %s, %s, %s, %s, %s, %s)"""
    run_sql(conn, sql, (card, commander, tag, func, importance, reason[:500], source))
    return True

# ── Main ─────────────────────────────────────────────────────────────────

def main():
    print("=== Importando conhecimento Hermes → PostgreSQL ===\n")
    print(f"Target PostgreSQL: {sanitized_database_target()}")
    print(f"Repo root: {REPO_ROOT}")
    print(f"Knowledge root: {KNOWLEDGE_ROOT}")
    if DRY_RUN:
        print("Mode: DRY RUN - write statements are skipped")
    conn = get_conn()
    conn.autocommit = True

    # ── Count before ──
    print("--- Contagens ANTES ---")
    before = {}
    for table in ['theme_contextual_rules', 'card_deck_profiles', 'analysis_sources', 'commander_reference_profiles']:
        rows = run_sql(conn, f"SELECT COUNT(*) FROM {table}", fetch=True)
        before[table] = rows[0][0]
        print(f"  {table}: {before[table]}")

    # 1. Importar THEMES.md
    if THEMES_PATH.exists():
        print(f"\nParseando THEMES.md...")
        rules = parse_themes_md(str(THEMES_PATH))
        print(f"  {len(rules)} regras extraídas")
        if rules:
            n = import_themes(conn, rules)
            print(f"  {n} regras importadas/atualizadas\n")
    else:
        print(f"  Nao encontrado: {THEMES_PATH}\n")

    # 2. Importar perfis de commander
    print("Parseando perfis de comandante...")
    profiles = []
    if DECKS_DIR.exists():
        for commander_dir in os.listdir(DECKS_DIR):
            cmd_path = os.path.join(DECKS_DIR, commander_dir)
            if not os.path.isdir(cmd_path):
                continue
            for fname in os.listdir(cmd_path):
                if any(kw in fname for kw in ['edhrec-avg', 'edhrec-default', 'user-decklist', 'optimized']):
                    fp = os.path.join(cmd_path, fname)
                    try:
                        with open(fp, 'r', encoding='utf-8') as f:
                            content = f.read()
                        cmdr_match = re.search(r'Comandante:\s*(.+)', content)
                        commander_name = cmdr_match.group(1).strip() if cmdr_match else commander_dir.replace('-', ' ').title()
                        metrics = extract_metrics_from_content(content)
                        if metrics:
                            profiles.append({
                                'commander_name': commander_name,
                                'metrics': metrics,
                                'source_file': fp,
                                'content_hash': hashlib.md5(content.encode()).hexdigest()
                            })
                    except Exception as e:
                        print(f"  Erro em {fp}: {e}")
    print(f"  {len(profiles)} perfis encontrados")
    if profiles:
        n = import_commander_profiles(conn, profiles)
        print(f"  {n} perfis atualizados\n")

    # 3. Importar card_deck_profiles
    print("Importando card_deck_profiles...")
    n = import_card_profiles(conn, str(DECKS_DIR))
    print(f"  {n} perfis de carta importados\n")

    # ── Count after ──
    print("--- Contagens DEPOIS ---")
    after = {}
    any_change = False
    for table in ['theme_contextual_rules', 'card_deck_profiles', 'analysis_sources', 'commander_reference_profiles']:
        rows = run_sql(conn, f"SELECT COUNT(*) FROM {table}", fetch=True)
        after[table] = rows[0][0]
        changed = " ← MUDOU!" if after[table] != before.get(table, 0) else ""
        if changed:
            any_change = True
        print(f"  {table}: {after[table]}{changed}")

    conn.close()

    if any_change:
        print("\n✔ Houve mudanças nos dados.")
    else:
        print("\n✔ Sem mudanças nos dados.")

    return any_change

if __name__ == '__main__':
    changed = main()
    sys.exit(0)  # always success; caller checks output
