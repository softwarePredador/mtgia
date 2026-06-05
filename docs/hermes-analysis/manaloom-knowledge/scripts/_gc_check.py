import hashlib, sqlite3, json

db_path = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'
conn = sqlite3.connect(f'file:{db_path}?mode=ro', uri=True)
cur = conn.cursor()

# Summary
cur.execute("""
    SELECT COUNT(*), 
        SUM(CASE WHEN why_game_changer IS NOT NULL AND length(why_game_changer) > 0 THEN 1 ELSE 0 END),
        SUM(CASE WHEN manaloom_detected = 1 THEN 1 ELSE 0 END),
        SUM(CASE WHEN manaloom_detected = 0 THEN 1 ELSE 0 END)
    FROM game_changers
""")
r = cur.fetchone()
print(f'GCs: total={r[0]}, why_filled={r[1]}, detected={r[2]}, nondetected={r[3]}')

# Bracket category distribution
cur.execute("""
    SELECT manaloom_bracket_category, COUNT(*) 
    FROM game_changers GROUP BY manaloom_bracket_category ORDER BY COUNT(*) DESC
""")
print('BRACKET:', {r[0]: r[1] for r in cur.fetchall()})

# Impact category distribution
cur.execute("""
    SELECT impact_category, COUNT(*) 
    FROM game_changers GROUP BY impact_category ORDER BY COUNT(*) DESC
""")
print('IMPACT:', {r[0]: r[1] for r in cur.fetchall()})

# Detected with bracket_category='other'
cur.execute("""
    SELECT card_name, impact_category FROM game_changers 
    WHERE manaloom_detected = 1 AND manaloom_bracket_category = 'other' ORDER BY card_name
""")
other_det = cur.fetchall()
print(f'Detected+other={len(other_det)}:', [r[0] for r in other_det])

# Key cards
for name in ["Field of the Dead", "Fierce Guardianship", "Underworld Breach",
             "Gaea's Cradle", "Serra's Sanctum", "Mishra's Workshop"]:
    cur.execute("""
        SELECT card_name, manaloom_detected, manaloom_bracket_category, impact_category 
        FROM game_changers WHERE card_name = ?
    """, (name,))
    r = cur.fetchone()
    if r: print(f'{r[0]}: det={r[1]}, bracket={r[2]}, impact={r[3]}')

# Nulls
cur.execute("""
    SELECT card_name FROM game_changers 
    WHERE why_game_changer IS NULL OR impact_category IS NULL 
       OR manaloom_bracket_category IS NULL OR manaloom_detected IS NULL
""")
nulls = cur.fetchall()
print(f'Nulls: {len(nulls)}', [r[0] for r in nulls])

# Short why
cur.execute("""
    SELECT card_name, length(why_game_changer) FROM game_changers 
    WHERE why_game_changer IS NULL OR length(why_game_changer) < 20 
    ORDER BY length(why_game_changer)
""")
short = cur.fetchall()
print(f'Short why: {len(short)}', [(r[0],r[1]) for r in short])

# Impact category errors (known 5)
cur.execute("""
    SELECT card_name, impact_category FROM game_changers 
    WHERE card_name IN ('Opposition Agent','Smothering Tithe','Farewell','Force of Will','Field of the Dead')
""")
for r in cur.fetchall():
    print(f'  IMPACT_ERR: {r[0]} = {r[1]}')

# Hash for structural comparison
cur.execute("""
    SELECT card_name, manaloom_detected, manaloom_bracket_category, impact_category,
        length(coalesce(why_game_changer,'')) 
    FROM game_changers ORDER BY card_name
""")
hash_data = json.dumps([list(r) for r in cur.fetchall()], sort_keys=True)
struct_hash = hashlib.md5(hash_data.encode()).hexdigest()
print(f'Structural hash: {struct_hash}')
print(f'Previous:       47245ba9e317ccaa99486d53389f7bb8')
print(f'Changed: {struct_hash != "47245ba9e317ccaa99486d53389f7bb8"}')

# Full hash including why_game_changer text
cur.execute("""
    SELECT card_name, manaloom_detected, manaloom_bracket_category, impact_category, why_game_changer
    FROM game_changers ORDER BY card_name
""")
full_data = json.dumps([list(r) for r in cur.fetchall()], sort_keys=True)
full_hash = hashlib.md5(full_data.encode()).hexdigest()
print(f'Full content hash: {full_hash}')

conn.close()
