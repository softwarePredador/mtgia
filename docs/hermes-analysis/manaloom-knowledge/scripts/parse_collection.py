#!/usr/bin/env python3
"""
parse_collection.py — Parse user card collection, store in knowledge.db,
cross-reference with Lorehold deck, and build optimal build.
"""
import csv, json, sqlite3, sys, os, time, re
from datetime import date
from collections import Counter

sys.path.insert(0, "scripts")
from scryfall_classifier import _fetch_single, fetch_cards, infer_functional_card_tags, classify_card

DB = "scripts/knowledge.db"
CSV_FILE = "scripts/user_collection.csv"
conn = sqlite3.connect(DB)

# ─── Step 1: Create collection table ───
conn.execute("""
    CREATE TABLE IF NOT EXISTS user_collection (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_en TEXT NOT NULL,
        card_pt TEXT,
        set_code TEXT,
        set_en TEXT,
        quantity INTEGER DEFAULT 1,
        quality TEXT,
        language TEXT,
        rarity TEXT,
        color TEXT,
        extras TEXT,
        card_number TEXT,
        oracle_text TEXT,
        type_line TEXT,
        cmc REAL,
        functional_tag TEXT,
        notes TEXT,
        UNIQUE(card_en, set_code)
    )
""")
conn.execute("CREATE INDEX IF NOT EXISTS idx_collection_name ON user_collection(card_en)")
conn.commit()

# ─── Step 2: Parse CSV ───
print("=" * 60)
print("PARSING USER COLLECTION")
print("=" * 60)

parsed = []
with open(CSV_FILE, "r", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        card_en = (row.get("Card (EN)") or "").strip()
        card_pt = (row.get("Card (PT)") or "").strip()
        set_code = (row.get("Edicao (Sigla)") or "").strip().lower()
        set_en = (row.get("Edicao (EN)") or "").strip()
        qty = int(row.get("Quantidade") or 1)
        quality = (row.get("Qualidade") or "").strip()
        lang = (row.get("Idioma") or "").strip()
        rarity = (row.get("Raridade") or "").strip()
        color = (row.get("Cor") or "").strip()
        extras = (row.get("Extras") or "").strip()
        card_num = (row.get("Card #") or "").strip()
        
        if not card_en and not card_pt:
            continue
        if not card_en and card_pt:
            card_en = card_pt
        
        parsed.append({
            "card_en": card_en,
            "card_pt": card_pt,
            "set_code": set_code,
            "set_en": set_en,
            "quantity": qty,
            "quality": quality,
            "language": lang,
            "rarity": rarity,
            "color": color,
            "extras": extras,
            "card_number": card_num,
        })

print(f"Parsed {len(parsed)} card entries from CSV")
print(f"Unique cards: {len(set(p['card_en'] for p in parsed))}")

# ─── Step 3: Fetch Scryfall data for UNIQUE cards ───
unique_names = list(set(p["card_en"] for p in parsed))
print(f"\nFetching {len(unique_names)} unique cards from Scryfall...")

# Check which already have oracle text in DB
existing = set(r[0].strip().lower() for r in conn.execute("SELECT card_en FROM user_collection").fetchall())
to_fetch = [n for n in unique_names if n.strip().lower() not in existing]
print(f"Already in DB: {len(unique_names) - len(to_fetch)}, to fetch: {len(to_fetch)}")

fetched = fetch_cards(to_fetch)

# ─── Step 4: Insert into DB ───
new_count = 0
for p in parsed:
    name = p["card_en"]
    nl = name.strip().lower()
    data = fetched.get(nl, {})
    
    oracle = data.get("oracle_text", "") if data.get("object") == "card" else ""
    tline = data.get("type_line", "") if data.get("object") == "card" else ""
    cmc_val = data.get("cmc", 0) if data.get("object") == "card" else 0
    
    tags = []
    if oracle:
        tags = infer_functional_card_tags(name, tline, oracle, cmc=cmc_val)
    
    primary_tag = tags[0]["tag"] if tags else "unknown"
    
    try:
        conn.execute("""
            INSERT OR REPLACE INTO user_collection 
            (card_en, card_pt, set_code, set_en, quantity, quality, language, rarity, color, extras, card_number,
             oracle_text, type_line, cmc, functional_tag)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            name, p["card_pt"], p["set_code"], p["set_en"], p["quantity"],
            p["quality"], p["language"], p["rarity"], p["color"],
            p["extras"], p["card_number"], oracle, tline, cmc_val, primary_tag
        ))
        new_count += 1
    except Exception as e:
        print(f"  ! Error inserting {name}: {e}")

conn.commit()
print(f"\nInserted/updated {new_count} cards in user_collection")

# ─── Step 5: Cross-reference with Lorehold deck ───
print("\n" + "=" * 60)
print("CROSS-REFERENCE WITH LOREHOLD DECK")
print("=" * 60)

# Get Lorehold deck cards
lorehold_cards = conn.execute("""
    SELECT dc.card_name, dc.quantity, dc.functional_tag
    FROM deck_cards dc
    JOIN decks d ON d.id = dc.deck_id
    JOIN commanders c ON c.id = d.commander_id
    WHERE c.name LIKE '%Lorehold%'
""").fetchall()

print(f"Current Lorehold deck has {len(lorehold_cards)} card entries")

# Find overlaps: cards in both Lorehold AND collection
lorehold_names = set(r[0].strip().lower() for r in lorehold_cards)
collection_names = set(r[0].strip().lower() for r in conn.execute("SELECT card_en FROM user_collection").fetchall())

overlap = lorehold_names & collection_names
missing_from_collection = lorehold_names - collection_names
collection_only = collection_names - lorehold_names

print(f"\nCards in Lorehold AND in your collection: {len(overlap)}")
print(f"Cards in Lorehold but NOT in your collection: {len(missing_from_collection)}")
print(f"Cards in your collection (not in Lorehold): {len(collection_only)}")

# Print missing cards
print(f"\n--- MISSING FROM COLLECTION ({len(missing_from_collection)}) ---")
for r in lorehold_cards:
    nl = r[0].strip().lower()
    if nl in missing_from_collection:
        print(f"  ❌ {r[0]:45s} qty={r[1]} tag={r[2]}")

# ─── Step 6: Identify upgrades from collection ───
print(f"\n--- UPGRADE CANDIDATES FROM COLLECTION ---")
# Get collection cards that are RW, colorless, or lands (legal for Lorehold)
upgrades = conn.execute("""
    SELECT card_en, functional_tag, cmc, type_line, quantity
    FROM user_collection 
    WHERE color IN ('R', 'W', 'M', 'C', 'L', '') OR color IS NULL
    ORDER BY functional_tag, card_en
""").fetchall()

# Filter out cards already in Lorehold
new_upgrades = [u for u in upgrades if u[0].strip().lower() not in lorehold_names]
print(f"Potential upgrades (RW-compatible, not in Lorehold): {len(new_upgrades)}")

# Group by tag
tag_groups = Counter()
for u in new_upgrades:
    tag_groups[u[1]] += 1

print("\nBy functional tag:")
for tag, cnt in tag_groups.most_common():
    examples = [u[0] for u in new_upgrades if u[1] == tag][:3]
    print(f"  {tag:20s} {cnt:3d} cards  ex: {', '.join(examples)}")

conn.close()
print("\nDone!")