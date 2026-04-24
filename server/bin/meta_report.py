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
SELECT format, archetype, placement, source_url, created_at
FROM meta_decks
ORDER BY created_at DESC
LIMIT 12
''')
latest = cur.fetchall()

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
        'placement': row['placement'],
        'source_url': row['source_url'],
        'created_at': row['created_at'],
    })

print(json.dumps({
    'total_meta_decks': total,
    'by_format': normalized_by_format,
    'by_commander_subformat': by_commander_subformat,
    'mtgtop8_count': mtgtop8_count,
    'latest_samples': normalized_latest,
}, ensure_ascii=False, default=str, indent=2))

cur.close()
conn.close()
