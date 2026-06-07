#!/usr/bin/env python3
"""Ciclo #4 — Evolution Oracle Swaps
Strategy: DEFENSIVE (Sem Play T3 ~16%, need CMC reduction)
Target: Reduce Sem Play T3 from ~16% to ~8-10% via net ΔCMC ≈ -15
"""
import sqlite3
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scryfall_classifier import infer_functional_card_tags, fetch_cards, classify_card

DB = 'scripts/knowledge.db'
DECK_ID = 6

# ─────────────────────────────────────────────────────────
# SWAPS: (card_out, card_in)
# Each swap: remove card_out, insert card_in from collection
# ─────────────────────────────────────────────────────────
SWAPS = [
    # Swap 1: Rise of the Eldrazi (CMC 12, removal) → Faithless Looting (CMC 1, draw)
    # Massive CMC reduction, adds draw to fix gap
    ("Rise of the Eldrazi", "Faithless Looting"),

    # Swap 2: Season of the Bold (CMC 5, 9.9% EDHREC) → Dragon's Rage Channeler (CMC 1, 39.6% EDHREC)
    # Topdeck enabler, cheap, draws extra cards
    ("Season of the Bold", "Dragon's Rage Channeler"),

    # Swap 3: Goblin Engineer (CMC 2, 0% EDHREC) → Thrill of Possibility (CMC 2, draw)
    # Replaces dead card with draw; neutral CMC but fixes a true gap
    ("Goblin Engineer", "Thrill of Possibility"),
]

# ─────────────────────────────────────────────────────────
# Tag-to-column mapping for deck metadata update
# ─────────────────────────────────────────────────────────
TAG_TO_COL = {
    'ramp': 'ramp_count', 'draw': 'draw_count', 'removal': 'removal_count',
    'tutor': 'tutor_count', 'board_wipe': 'board_wipe_count',
    'protection': 'protection_count', 'wincon': 'wincon_count',
    'recursion': 'recursion_count', 'big_spell': 'engine_count',
}

def fetch_card_data(name):
    """Fetch card data from Scryfall."""
    cards = fetch_cards([name])
    key = name.lower()
    if key in cards:
        return cards[key]
    # Try fuzzy
    for k, v in cards.items():
        if v and v.get('name', '').lower() == key:
            return v
    return None

def tag_to_column(tag):
    return TAG_TO_COL.get(tag)

def perform_swap(c, old_id, old_name, new_name, new_card_data):
    """Perform a single swap: delete old, insert new, re-sync tags."""
    # Fetch Scryfall data for new card
    if new_card_data is None:
        new_card_data = fetch_card_data(new_name)
    if new_card_data is None:
        print(f"  ⚠️ Could not fetch data for {new_name}, using defaults")
        new_card_data = {'name': new_name, 'type_line': '', 'oracle_text': '', 'cmc': 0}

    oracle_text = new_card_data.get('oracle_text', '')
    type_line = new_card_data.get('type_line', '')
    cmc = new_card_data.get('cmc', 0)
    if oracle_text:
        oracle_text = oracle_text[:500]  # Truncate

    # 1. DELETE old card_tags
    c.execute("DELETE FROM card_tags WHERE deck_card_id = ?", (old_id,))

    # 2. DELETE old deck_card
    c.execute("DELETE FROM deck_cards WHERE id = ?", (old_id,))

    # 3. INSERT new card

    c.execute("""
        INSERT INTO deck_cards (deck_id, card_name, quantity, functional_tag,
                                cmc, type_line, oracle_text, is_commander, is_partner)
        VALUES (?, ?, 1, ?, ?, ?, ?, 0, 0)
    """, (DECK_ID, new_name, None, cmc, type_line, oracle_text))
    new_id = c.lastrowid

    # 4. Re-sync multi-tags
    if oracle_text:
        tags = infer_functional_card_tags(
            name=new_name, type_line=type_line,
            oracle_text=oracle_text, cmc=cmc
        )
        for t in tags:
            c.execute("""
                INSERT INTO card_tags (deck_card_id, card_name, tag, confidence, evidence)
                VALUES (?, ?, ?, ?, ?)
            """, (new_id, new_name, t['tag'], t['confidence'], t['evidence']))
        best_tag = tags[0]['tag'] if tags else None
        best_conf = tags[0]['confidence'] if tags else 0.0
    else:
        # Use single-tag classifier
        single = classify_card(new_card_data)
        best_tag = single if single and single != 'NULL' else None
        best_conf = 0.5
        tags = []

    # Update functional_tag on deck_cards
    if best_tag:
        c.execute("UPDATE deck_cards SET functional_tag = ?, tag_confidence = ? WHERE id = ?",
                  (best_tag, best_conf, new_id))

    return new_id, best_tag

def recalc_deck_meta(c, deck_id):
    """Recalculate and update deck metadata columns from current deck_cards."""
    c.execute("""
        SELECT functional_tag, SUM(quantity) as total
        FROM deck_cards WHERE deck_id = ? AND (type_line NOT LIKE '%land%' OR type_line IS NULL)
        GROUP BY functional_tag
    """, (deck_id,))
    update_fields = {}
    for row in c.fetchall():
        col = tag_to_column(row[0]) if row[0] else None
        if col and row[1]:
            update_fields[col] = row[1]
    if update_fields:
        set_clause = ', '.join(f"{k} = ?" for k in update_fields)
        values = list(update_fields.values()) + [deck_id]
        c.execute(f"UPDATE decks SET {set_clause} WHERE id = ?", values)
    return update_fields

def verify_deck(c, deck_id):
    """Verify deck integrity."""
    c.execute("SELECT SUM(quantity) FROM deck_cards WHERE deck_id = ?", (deck_id,))
    total = c.fetchone()[0]
    assert total == 100, f"Deck must have exactly 100 cards! Has {total}"

    c.execute("SELECT COUNT(*) FROM deck_cards WHERE deck_id = ? AND is_commander = 1", (deck_id,))
    cmdr = c.fetchone()[0]
    assert cmdr == 1, f"Must have exactly 1 commander! Has {cmdr}"

    c.execute("SELECT SUM(quantity) FROM deck_cards WHERE deck_id = ? AND type_line LIKE '%land%'", (deck_id,))
    lands = c.fetchone()[0]
    assert lands >= 34, f"Must have at least 34 lands! Has {lands}"

    return True

def main():
    conn = sqlite3.connect(DB)
    c = conn.cursor()

    # Verify deck state before swaps
    c.execute("SELECT deck_name, total_lands, ramp_count, draw_count, removal_count, board_wipe_count, protection_count, wincon_count, engine_count FROM decks WHERE id = ?", (DECK_ID,))
    before = c.fetchone()
    print(f"Ciclo #4 — Evolution Oracle")
    print(f"Deck: {before[0]} (ID={DECK_ID})")
    print(f"Before: lands={before[1]}, ramp={before[2]}, draw={before[3]}, removal={before[4]}, wipe={before[5]}, prot={before[6]}, wincon={before[7]}, engine={before[8]}")
    print()

    # Pre-fetch Scryfall data for new cards
    new_names = [s[1] for s in SWAPS]
    scryfall_data = {}
    for name in new_names:
        data = fetch_card_data(name)
        if data:
            scryfall_data[name] = data
            print(f"  Fetched: {name} (CMC {data.get('cmc')}, {data.get('type_line','')[:40]})")
        else:
            print(f"  ⚠️ Failed to fetch {name}")
    print()

    results = []
    for old_name, new_name in SWAPS:
        # Find old card
        c.execute("SELECT id, functional_tag, cmc FROM deck_cards WHERE deck_id = ? AND card_name = ?", (DECK_ID, old_name))
        row = c.fetchone()
        if row is None:
            print(f"  ⚠️ Card '{old_name}' not found in deck, skipping")
            continue
        old_id, old_tag, old_cmc = row

        old_tag_disp = old_tag or 'NULL'
        new_cmc = scryfall_data.get(new_name, {}).get('cmc', 0) if new_name in scryfall_data else 0

        print(f"  Processing: {old_name} (CMC {old_cmc}, tag={old_tag_disp}) → {new_name} (CMC {new_cmc})")

        new_id, new_tag = perform_swap(c, old_id, old_name, new_name, scryfall_data.get(new_name))
        print(f"    New card ID={new_id}, tag={new_tag}")
        results.append((old_name, new_name, old_cmc, new_cmc, old_tag_disp, new_tag))

    # Recalculate deck metadata
    print("\nRecalculating deck metadata...")
    meta = recalc_deck_meta(c, DECK_ID)
    print(f"  Updated: {meta}")

    # Verify deck integrity
    print("\nVerifying deck...")
    try:
        verify_deck(c, DECK_ID)
        print("  ✅ Deck integrity OK (100 cards, 1 commander, 34+ lands)")
    except AssertionError as e:
        print(f"  ❌ Deck integrity FAILED: {e}")
        conn.rollback()
        conn.close()
        return False

    # Show after state
    c.execute("SELECT total_lands, ramp_count, draw_count, removal_count, board_wipe_count, protection_count, wincon_count, engine_count FROM decks WHERE id = ?", (DECK_ID,))
    after = c.fetchone()
    print(f"\nAfter: lands={after[0]}, ramp={after[1]}, draw={after[2]}, removal={after[3]}, wipe={after[4]}, prot={after[5]}, wincon={after[6]}, engine={after[7]}")

    # Δ summary
    print(f"\nΔ: ramp={after[1]-before[2]}, draw={after[2]-before[3]}, removal={after[3]-before[4]}, wipe={after[4]-before[5]}, prot={after[5]-before[6]}, wincon={after[6]-before[7]}, engine={after[7]-before[8]}")

    net_dmc = sum(r[3]-r[2] for r in results)
    print(f"Net ΔCMC: {net_dmc}")

    conn.commit()
    conn.close()

    print("\n✅ Ciclo #4 swaps applied successfully!")
    return True

if __name__ == '__main__':
    main()
