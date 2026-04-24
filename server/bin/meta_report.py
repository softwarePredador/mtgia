import json
import os
import psycopg2
from psycopg2.extras import RealDictCursor

FORMAT_LABELS = {
    'ST': 'Standard',
    'PI': 'Pioneer',
    'MO': 'Modern',
    'LE': 'Legacy',
    'VI': 'Vintage',
    'EDH': 'Duel Commander (MTGTop8 EDH)',
    'cEDH': 'Competitive Commander (MTGTop8 cEDH)',
    'PAU': 'Pauper',
    'PREM': 'Premodern',
}


def format_descriptor(format_code):
    code = (format_code or '').strip() or 'unknown'
    if code == 'EDH':
        return {
            'format': code,
            'format_family': 'commander',
            'format_label': FORMAT_LABELS[code],
            'subformat': 'duel_commander',
        }
    if code == 'cEDH':
        return {
            'format': code,
            'format_family': 'commander',
            'format_label': FORMAT_LABELS[code],
            'subformat': 'competitive_commander',
        }
    return {
        'format': code,
        'format_family': code.lower(),
        'format_label': FORMAT_LABELS.get(code, code),
        'subformat': None,
    }

conn = psycopg2.connect(
    host=os.getenv('DB_HOST', '143.198.230.247'),
    port=int(os.getenv('DB_PORT', '5433')),
    dbname=os.getenv('DB_NAME', 'halder'),
    user=os.getenv('DB_USER', 'postgres'),
    password=os.getenv('DB_PASSWORD', 'postgres'),
)
cur = conn.cursor(cursor_factory=RealDictCursor)

cur.execute('SELECT COUNT(*)::int AS c FROM meta_decks')
total = cur.fetchone()['c']

cur.execute('SELECT format, COUNT(*)::int AS c FROM meta_decks GROUP BY format ORDER BY c DESC')
by_format = cur.fetchall()

cur.execute("SELECT COUNT(*)::int AS c FROM meta_decks WHERE source_url ILIKE 'https://www.mtgtop8.com/%'")
mtgtop8_count = cur.fetchone()['c']

cur.execute('''
SELECT
  format,
  archetype,
  commander_name,
  partner_commander_name,
  shell_label,
  strategy_archetype,
  placement,
  source_url,
  created_at
FROM meta_decks
ORDER BY created_at DESC
LIMIT 12
''')
latest = cur.fetchall()

cur.execute('''
SELECT
  format,
  COUNT(*)::int AS deck_count,
  COUNT(*) FILTER (WHERE COALESCE(TRIM(commander_name), '') <> '')::int AS with_commander_name,
  COUNT(*) FILTER (WHERE COALESCE(TRIM(partner_commander_name), '') <> '')::int AS with_partner_commander_name,
  COUNT(*) FILTER (WHERE COALESCE(TRIM(shell_label), '') <> '')::int AS with_shell_label,
  COUNT(*) FILTER (WHERE COALESCE(TRIM(strategy_archetype), '') <> '')::int AS with_strategy_archetype
FROM meta_decks
WHERE format IN ('EDH', 'cEDH')
GROUP BY format
ORDER BY deck_count DESC
''')
commander_shell_strategy = cur.fetchall()

by_commander_subformat = {}
normalized_by_format = []
for row in by_format:
    descriptor = format_descriptor(row['format'])
    normalized_by_format.append({
        **descriptor,
        'count': row['c'],
    })
    if descriptor['subformat']:
        by_commander_subformat[descriptor['subformat']] = row['c']

normalized_latest = []
for row in latest:
    descriptor = format_descriptor(row['format'])
    normalized_latest.append({
        **descriptor,
        'archetype': row['archetype'],
        'commander_name': row['commander_name'],
        'partner_commander_name': row['partner_commander_name'],
        'shell_label': row['shell_label'],
        'strategy_archetype': row['strategy_archetype'],
        'placement': row['placement'],
        'source_url': row['source_url'],
        'created_at': row['created_at'],
    })

normalized_shell_strategy = []
for row in commander_shell_strategy:
    descriptor = format_descriptor(row['format'])
    normalized_shell_strategy.append({
        **descriptor,
        'deck_count': row['deck_count'],
        'with_commander_name': row['with_commander_name'],
        'with_partner_commander_name': row['with_partner_commander_name'],
        'with_shell_label': row['with_shell_label'],
        'with_strategy_archetype': row['with_strategy_archetype'],
    })

print(json.dumps({
    'total_meta_decks': total,
    'by_format': normalized_by_format,
    'by_commander_subformat': by_commander_subformat,
    'commander_shell_strategy_coverage': normalized_shell_strategy,
    'mtgtop8_count': mtgtop8_count,
    'latest_samples': normalized_latest,
}, ensure_ascii=False, default=str, indent=2))

cur.close()
conn.close()
