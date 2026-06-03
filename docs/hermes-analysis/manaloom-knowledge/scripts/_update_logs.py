"""Update root-level MULLIGAN_LOG.md and insert run_log"""
import os

# 1. Update root MULLIGAN_LOG
root_path = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/MULLIGAN_LOG.md'
with open(root_path, 'r') as f:
    content = f.read()

new_entry = """## Execucao #15 -- 2026-06-03T21:47:00+00:00 (Lorehold cEDH Storm -- T3=1.6%, -7.3pp, DB Classifier Corrigido)

**Card hash:** `8b9c643c84825a4436d33b7f1616fa5f` — diferente do Exec#14 (f2241d99...).
**Deck:** 100 cartas, 33 lands (31 tagged), cEDH Storm/Combo. DB ramp classification corrigido de 6 para 19 cartas.
**Metricas (N=1000, seed=42):** T3=1.6%, Mulligan nao-free=15.3%, Playable=97.9%, Ramp T1 (Sol Ring)=7.0%, Ramp T1 (fast mana)=49.7%.

---

"""

new_content = new_entry + content
with open(root_path, 'w') as f:
    f.write(new_content)
print(f"Root MULLIGAN_LOG updated: {len(new_content)} bytes")

# 2. Insert run_log
import sqlite3, datetime
DB = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'
conn = sqlite3.connect(DB)
cur = conn.cursor()
now = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%S+00:00')
cur.execute('''
    INSERT INTO run_log
        (run_date, source_used, commander_analyzed, decks_analyzed,
         insights_found, discrepancies_found, status, duration_seconds)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''', (now, 'mulligan-simulation-1000-exec15',
      'Lorehold, the Historian', 1,
      5, 1, 'ok', 2))
conn.commit()
print(f"run_log inserted: id={cur.lastrowid}")
conn.close()
