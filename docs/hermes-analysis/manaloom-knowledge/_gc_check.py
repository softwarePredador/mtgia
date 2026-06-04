import sqlite3, hashlib, json, os

DB = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'
print(f"DB exists: {os.path.exists(DB)}, size: {os.path.getsize(DB)}")

conn = sqlite3.connect(DB)
conn.row_factory = sqlite3.Row
cur = conn.cursor()

cur.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
tables = [r[0] for r in cur.fetchall()]
print("Tables:", tables)

if 'game_changers' not in tables:
    print("NO game_changers table")
    conn.close()
    exit()

cur.execute("SELECT COUNT(*) FROM game_changers")
count = cur.fetchone()[0]
print(f"GC count: {count}")

cur.execute('''SELECT card_name, why_game_changer, manaloom_detected,
    manaloom_bracket_category, impact_category FROM game_changers ORDER BY card_name''')
rows = cur.fetchall()

hash_input = json.dumps(sorted([
    (r['card_name'], r['why_game_changer'] or '', r['manaloom_detected'] or 0,
     r['manaloom_bracket_category'] or '', r['impact_category'] or '')
    for r in rows
]))
hash_val = hashlib.md5(hash_input.encode()).hexdigest()
print(f"Hash: {hash_val}")

cur.execute("SELECT manaloom_detected, COUNT(*) FROM game_changers GROUP BY manaloom_detected")
det_counts = {r[0]: r[1] for r in cur.fetchall()}
print(f"Det: {det_counts}")

cur.execute("SELECT manaloom_bracket_category, COUNT(*) FROM game_changers GROUP BY manaloom_bracket_category")
cat_counts = {r[0]: r[1] for r in cur.fetchall()}
print(f"Cat: {cat_counts}")

cur.execute("SELECT COUNT(*) FROM game_changers WHERE why_game_changer IS NULL OR LENGTH(why_game_changer) < 20")
short = cur.fetchone()[0]
print(f"Short why: {short}")

cur.execute("SELECT card_name, why_game_changer, manaloom_detected FROM game_changers WHERE why_game_changer IS NULL OR LENGTH(why_game_changer) < 20 ORDER BY card_name")
for r in cur.fetchall():
    print(f"SHORT: {r['card_name']} | why={r['why_game_changer']} | det={r['manaloom_detected']}")

conn.close()
