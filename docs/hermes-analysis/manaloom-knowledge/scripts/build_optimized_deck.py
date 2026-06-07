#!/usr/bin/env python3
"""Build the optimal Lorehold deck from user collection."""
import sqlite3, json
from collections import Counter

DB = "scripts/knowledge.db"
conn = sqlite3.connect(DB)

print("=" * 60)
print("OPTIMAL LOREHOLD DECK BUILDER")
print("=" * 60)

# Step 1: Get Lorehold cards
lorehold = conn.execute("""
    SELECT dc.card_name, dc.quantity, dc.functional_tag, dc.cmc
    FROM deck_cards dc JOIN decks d ON d.id = dc.deck_id
    JOIN commanders c ON c.id = d.commander_id
    WHERE c.name LIKE '%Lorehold%'
""").fetchall()

# Step 2: Check collection
in_collection = set()
for r in lorehold:
    nl = r[0].strip().lower()
    if conn.execute("SELECT id FROM user_collection WHERE LOWER(card_en)=?", (nl,)).fetchone():
        in_collection.add(nl)

missing = [n for n in lorehold if n[0].strip().lower() not in in_collection]
kept = [n for n in lorehold if n[0].strip().lower() in in_collection]

print(f"\nLorehold deck: {len(lorehold)} entries")
print(f"  Kept (in collection): {len(kept)}")
print(f"  Missing: {len(missing)}")

# Group missing by tag
missing_by_tag = Counter()
for m in missing:
    missing_by_tag[m[2]] += 1
print(f"\n  Missing by tag: {dict(missing_by_tag)}")

# Step 3: Lands available in collection (not in current deck)
added_names = set(k[0].strip().lower() for k in kept)
added_names.add("lorehold, the historian")

collection_lands = conn.execute("""
    SELECT card_en, quantity FROM user_collection 
    WHERE (type_line LIKE '%Land%' OR color = 'L')
    AND quantity > 0
    ORDER BY 
        CASE 
            WHEN LOWER(card_en) LIKE '%mountain%' THEN 1
            WHEN LOWER(card_en) LIKE '%plains%' THEN 2
            ELSE 0
        END,
        LOWER(card_en)
""").fetchall()

# Separate basics from non-basics
basics = {'mountain': 0, 'plains': 0}
other_lands = []
for cl in collection_lands:
    nl = cl[0].strip().lower()
    if nl not in added_names:
        added_names.add(nl)
        # Check if basic
        found_basic = False
        for b in ['mountain', 'plains']:
            if nl.startswith(b) and any(c.isdigit() for c in nl):
                basics[b] = max(basics[b], cl[1])
                found_basic = True
                break
        if not found_basic:
            other_lands.append(cl)

print(f"\nLands from collection: {len(other_lands)} non-basic + basics")
print(f"  Basics found: {basics}")

# Step 4: Priority upgrades by deck need
# The deck needs more draw, recursion, and efficient ramp
priority_upgrades = [
    # MUST INCLUDES (auto-include power cards)
    ("The One Ring", "draw", 4, "MUST - best card draw engine in the game"),
    ("Akroma's Will", "protection", 5, "MUST - protection + finisher"),
    ("Flawless Maneuver", "protection", 2, "MUST - free protection with commander"),
    ("Trouble in Pairs", "draw", 4, "MUST - fixes deck's biggest weakness (draw)"),
    ("Ragavan, Nimble Pilferer", "ramp", 1, "TOP - turn 1 ramp + value"),
    ("Birgi, God of Storytelling", "ramp", 3, "TOP - ramp + spellslinger synergy"),
    ("Neheb, the Eternal", "ramp", 5, "TOP - post-combat mana burst"),
    ("Dualcaster Mage", "spellslinger", 3, "TOP - copy spell + body (Lorehold synergy)"),
    ("Arcane Bombardment", "engine", 6, "TOP - repeatable spell copy (Lorehold synergy)"),

    # HIGH VALUE upgrades
    ("Sunforger", "tutor", 3, "HIGH - instant speed tutor (Boros staple)"),
    ("Blasphemous Act", "board_wipe", 9, "HIGH - cheap wipe (costs 1-3 in practice)"),
    ("Chaos Warp", "removal", 3, "HIGH - versatile removal"),
    ("Gamble", "tutor", 1, "HIGH - red tutor (risky but strong)"),
    ("Solphim, Mayhem Dominus", "wincon", 5, "HIGH - doubles damage (wincon)"),
    ("Storm-Kiln Artist", "ramp", 3, "HIGH - treasures on spells cast"),
    ("Goldspan Dragon", "ramp", 5, "HIGH - treasures + threat"),
    ("Archivist of Oghma", "draw", 3, "HIGH - draw on your opponents' fetch/tutor"),
    ("Wandering Archaic", "engine", 5, "HIGH - copy opponent's spells"),
    ("Lotus Petal", "ramp", 0, "MED - free mana (cut if tight)"),
    ("Farewell", "board_wipe", 6, "MED - versatile exile wipe"),
    ("Boros Signet", "ramp", 2, "MED - solid ramp"),
    ("Mana Geyser", "ritual", 5, "MED - ritual (explosive plays)"),
    ("Chaos Warp", "removal", 3, "ALREADY LISTED"),
]

# Step 5: Build the final deck
final_deck = []

# Commander
final_deck.append(("Lorehold, the Historian", 1, "commander", 5, "COMMANDER"))

# Add all kept cards
for k in kept:
    final_deck.append((k[0], k[1], k[2], k[3], "KEPT - in collection"))

# Add available lands from collection (replace missing lands)
for cl in other_lands:
    # Check if this is a good enough replacement for a missing fetch
    final_deck.append((cl[0], cl[1], "land", 0, "LAND - from collection"))

# Add basics
# We need ~15 basics total. The original has 8 Mountain + 7 Plains = 15
# Use from collection or add generic basics
mountain_count = basics.get('mountain', 8)
plains_count = basics.get('plains', 7)
# Add basics — user has these, they're trivially available
# Original deck had 8 Mountain + 7 Plains = 15 basics
final_deck.append(("Mountain", 8, "land", 0, "BASIC - trivially available"))
final_deck.append(("Plains", 7, "land", 0, "BASIC - trivially available"))

# Count current cards
current_names = set()
current_total = 0
for c in final_deck:
    nl = c[0].strip().lower()
    if nl not in current_names:
        current_names.add(nl)
        current_total += c[1]

print(f"\nCurrent deck size: {current_total} cards ({len(current_names)} unique)")
print(f"Remaining slots for upgrades: {99 - current_total}")

# Step 6: Add priority upgrades until we hit 99 cards
slots_left = 99 - current_total
added_upgrades = []
for pu in priority_upgrades:
    if slots_left <= 0:
        break
    nl = pu[0].strip().lower()
    if nl not in current_names:
        current_names.add(nl)
        final_deck.append((pu[0], 1, pu[1], pu[2], pu[3]))
        added_upgrades.append(pu[0])
        slots_left -= 1

print(f"Added {len(added_upgrades)} upgrades:")
for u in added_upgrades:
    print(f"  + {u}")

# Step 7: Print final deck with analysis
print("\n" + "=" * 60)
print("FINAL DECK LIST")
print("=" * 60)

# Count by tag (excluding lands)
tag_counts = Counter()
land_count = 0
cmc_sum = 0
cmc_count = 0
nonland_count = 0

final_deck.sort(key=lambda c: ((c[2] or ''), (c[3] or 99)))

print(f"\n{'Card':45s} {'Qty':3s} {'Tag':15s} {'CMC':4s} {'Note'}")
print("-" * 90)

def safe(val, default=""):
    return val if val is not None else default

for c in final_deck:
    if c[2] == "land":
        land_count += c[1] if c[1] else 0
    else:
        safe_tag = safe(c[2], "unknown")
        tag_counts[safe_tag] += c[1] if c[1] else 0
        if c[3] is not None and c[3] > 0:
            cmc_sum += c[3] * (c[1] if c[1] else 1)
            cmc_count += c[1] if c[1] else 1
        nonland_count += c[1] if c[1] else 0
    
    cmc_str = f"{c[3]:4.1f}" if c[3] is not None else "  --"
    note = c[4] if len(c) > 4 else ""
    name = safe(c[0])
    tag = safe(c[2], "unknown")
    qty = c[1] if c[1] is not None else 1
    print(f"{name:45s} {qty:3d} {tag:15s} {cmc_str} {note[:40]}")

total = sum(c[1] for c in final_deck)
avg_cmc = round(cmc_sum / cmc_count, 2) if cmc_count > 0 else 0

print("\n" + "=" * 60)
print("DECK METRICS")
print("=" * 60)
print(f"Total cards: {total} (99 main + commander)")
print(f"Lands: {land_count}")
print(f"Non-lands: {nonland_count}")
print(f"Avg CMC (non-land): {avg_cmc}")
print(f"\nFunctional distribution:")
for tag, cnt in sorted(tag_counts.items(), key=lambda x: -x[1]):
    print(f"  {tag:20s}: {cnt:3d} ({round(cnt/nonland_count*100)}% of non-land)")

conn.close()