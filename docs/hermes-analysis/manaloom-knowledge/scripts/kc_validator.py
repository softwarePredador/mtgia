#!/usr/bin/env python3
"""
KNOWN_CARDS Validator & Expander — Cron-safe
- Pulls new Boros/WR cards from PG (card_deck_analysis, edhrec_rank < 2000)
- Validates existing KNOWN_CARDS classifications against PG oracle text
- Auto-corrects clear misclassifications
- Expands card pool continuously
"""
import sqlite3, subprocess, os, json, re, sys, time
from collections import defaultdict

DB = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'
OUT = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_generated.json'
LOCK = '/tmp/kc_validator.lock'

os.environ["PGPASSWORD"] = "c2abeef5e66f21b0ce86"
BASELINE_WR = 81.8

if os.path.exists(LOCK):
    age = time.time() - os.path.getmtime(LOCK)
    if age < 7200:
        print(f"LOCKED ({age:.0f}s). Exiting.")
        sys.exit(0)
    os.remove(LOCK)
open(LOCK, 'w').close()

def pg(query):
    r = subprocess.run(["psql","-h","143.198.230.247","-p","5433","-U","postgres","-d","halder",
        "-t","-A","-F","\x1f","-R","\x1e","-c",query],
        capture_output=True, text=True, timeout=60)
    rows = []
    for line in r.stdout.strip().split("\x1e"):
        line = line.strip()
        if line:
            rows.append(line.split("\x1f"))
    return rows

# ══════════════════════════════════════════
# STEP 1: EXPAND — Pull new Boros/WR cards from PG
# ══════════════════════════════════════════
print("=" * 60)
print("STEP 1: EXPANDING CARD POOL")

# Load existing KNOWN_CARDS
with open(OUT) as f:
    existing = json.load(f)
existing_names = set(existing.keys())

# Get cards from card_deck_analysis that are NOT in our KNOWN_CARDS yet
# Filter: WR color identity (or colorless), top EDHREC cards, non-land
print("Querying PG for new Boros/WR cards...")
rows = pg("""
    SELECT c.name, c.oracle_text, c.type_line, c.cmc,
           e.edhrec_rank
    FROM cards c
    JOIN card_extended e ON c.name = e.card_name
    WHERE c.oracle_text IS NOT NULL
      AND c.type_line NOT LIKE '%Land%'
      AND c.cmc < 9
      AND e.edhrec_rank IS NOT NULL
    ORDER BY e.edhrec_rank ASC
    LIMIT 2000
""")

print(f"  PG returned {len(rows)} cards")

# Also pull from ALL Lorehold decks (what generator does)
conn = sqlite3.connect(DB)
all_lorehold = set()
for row in conn.execute("SELECT card_list FROM learned_decks WHERE commander LIKE '%Lorehold%' AND card_list IS NOT NULL"):
    try:
        for card in json.loads(row[0]):
            all_lorehold.add(card["name"])
    except:
        for line in row[0].strip().split("\n"):
            parts = line.strip().split(" ", 1)
            if len(parts) == 2 and parts[0].isdigit():
                all_lorehold.add(parts[1])
conn.close()

print(f"  Lorehold unique cards: {len(all_lorehold)}")

# Merge: get PG data for Lorehold cards not already covered
lorehold_missing = sorted(all_lorehold - existing_names)
if lorehold_missing:
    lore_chunks = [lorehold_missing[i:i+300] for i in range(0, len(lorehold_missing), 300)]
    lore_rows = []
    for chunk in lore_chunks:
        safe = ",\n".join("'" + n.replace("'","''") + "'" for n in chunk)
        lore_rows += pg(
            "SELECT name, oracle_text, type_line, cmc FROM cards "
            "WHERE name ILIKE ANY(ARRAY[\n" + safe + "\n]) AND oracle_text IS NOT NULL"
        )
    print(f"  Lorehold PG matches: {len(lore_rows)}")
    # Add to rows for classification
    for r in lore_rows:
        if len(r) >= 2 and r[1]:
            rows.append([r[0].strip(), r[1], r[2] if len(r) > 2 else "", 
                        str(float(r[3])) if len(r) > 3 and r[3] else "3",
                        "99999"])  # high edhrec_rank for Lorehold-specific cards

# Classify using same rules as generate_known_cards.py
# (simplified inline version)
def classify(ot, tl, cmc_val):
    ot = ot.lower() if ot else ""
    # Priority-ordered patterns (same as generate_known_cards.py)
    patterns = [
        # Silence / can't cast
        (r"(?:players|opponents|target player) can't cast spells|can't cast.*spells.*this turn", "silence_opponents"),
        (r"can't be countered", "silence_opponents"),
        # Counter
        (r"counter target.*spell.*unless|counter target.*spell.*pay|counter target spell", "counter"),
        (r"counter target.*blue|destroy target.*blue|red elemental blast", "counter"),
        # Win conditions
        (r"you win the game|win the game|cannot lose", "finisher"),
        # Storm/spellslinger
        (r"storm\b|whenever you cast.*instant.*sorcery.*deal.*damage", "finisher"),
        # Lifegain payoff
        (r"pay.*\d+ life.*deal.*damage|pay.*\d+ life.*destroy", "finisher"),
        (r"whenever you cast.*you gain.*life.*for each", "finisher"),
        # Damage multiplier
        (r"triple.*damage|damage.*tripled|double.*damage|damage.*doubled", "finisher"),
        # Approach
        (r"second approach|you've cast another spell named approach", "approach"),
        # Extra turn
        (r"take an extra turn|additional turn|after this main phase", "extra_turn"),
        # Board wipes
        (r"destroy all creatures|destroy all.*creatures|deals.*damage to each creature", "board_wipe"),
        (r"exile all creatures|exile all permanents|exile all.*artifacts|exile all.*nonland", "board_wipe"),
        (r"each player sacrifices.*all|sacrifices.*all.*creatures", "board_wipe"),
        (r"destroy all lands|destroy all.*lands", "board_wipe"),
        # Steal all
        (r"gain control of all creatures|untap all creatures.*gain control", "steal_all_creatures"),
        # Pump all
        (r"creatures you control get \+|creatures.*gain.*indestructible.*double strike", "pump_all"),
        # Phase out
        (r"phase out|phases out", "phase_out"),
        # Indestructible/protection
        (r"gain.*indestructible until|creatures.*gain indestructible", "indestructible"),
        (r"prevent.*(?:all|that|the next).*damage.*(?:would be dealt|dealt to you)", "indestructible"),
        (r"hexproof|shroud|protection from", "indestructible"),
        # Targeted removal
        (r"exile target.*creature|exile target.*permanent|destroy target.*creature|destroy target.*artifact", "remove_permanent"),
        (r"deals.*damage to target.*creature|deals.*damage to target.*player", "remove_creature"),
        (r"deals.*damage to any target|deals \d+ damage to target", "remove_creature"),
        # Token makers
        (r"create.*treasure token", "ramp_engine"),
        (r"create.*\d+/.*token|create.*\d+ .*creature token", "token_maker"),
        (r"create a.*token|create.*token", "token_maker"),
        # Draw engines
        (r"whenever.*opponent.*draw.*card|whenever.*player.*draw.*you may", "draw_engine"),
        (r"whenever.*opponent.*cast.*spell.*draw|whenever an opponent.*casts.*draw", "draw_engine"),
        (r"at the beginning of.*upkeep.*draw a card|at the beginning of.*draw step.*draw", "draw_engine"),
        # Wheel / big draw
        (r"discard.*hand.*draw.*cards|each player.*discard.*hand.*draw", "draw_cards"),
        (r"draw.*seven cards|draw.*cards.*discard your hand", "draw_cards"),
        (r"draw three cards|draw.*3 cards", "draw_cards"),
        (r"draw two cards|draw.*2 cards", "draw_cards"),
        (r"draw a card|draw cards", "draw_cards"),
        # Scry/topdeck
        (r"scry \d|surveil \d|look at the top.*card.*library", "topdeck_manipulation"),
        # Ramp permanents (rocks)
        (r"\{t\}: add.*mana.*any.*color|\{t\}: add.*one mana of any", "ramp_permanent"),
        (r"\{t\}: add.*\{[cC]\}\{[cC]\}\{[cC]\}", "ramp_permanent"),
        (r"\{t\}: add.*\{[cC]\}\{[cC]\}", "ramp_permanent"),
        (r"\{t\}: add", "ramp_permanent"),
        # Fetch/search land
        (r"search.*library.*land.*put.*battlefield|search.*library.*land.*tapped", "ramp_permanent"),
        # Moxen
        (r"imprint.*exile.*card.*add.*mana", "ramp_permanent"),
        (r"discard a land.*add.*mana|discard.*land.*\{t\}", "ramp_permanent"),
        (r"doesn't untap.*\{t\}: add", "ramp_permanent"),
        # Rituals
        (r"add.*mana for each|add.*red.*for each|add.*white.*for each", "ramp_ritual"),
        (r"add.*\{[rR]\}\{[rR]\}\{[rR]\}\{[rR]\}\{[rR]\}", "ramp_ritual"),
        (r"add.*\{[rR]\}\{[rR]\}\{[rR]\}\{[rR]\}|add.*four.*red", "ramp_ritual"),
        (r"add.*three.*mana|add.*\{[cC]\}\{[cC]\}", "ramp_ritual"),
        (r"add.*\{[rR]\}|add.*\{[wW]\}|add one.*mana", "ramp_ritual"),
        (r"sacrifice.*add.*mana", "ramp_ritual"),
        # Copy engines
        (r"copy.*instant.*sorcery|whenever you cast.*instant.*sorcery.*copy", "copy_spell"),
        (r"ripple", "ripple_engine"),
        (r"buyback.*copy.*instant.*sorcery|buyback.*copy target", "copy_spell"),
        # Tutors
        (r"search your library.*artifact|search your library.*enchantment", "tutor"),
        (r"search.*library.*put.*hand|search.*library.*reveal.*put|transmute", "tutor"),
        # Recursion
        (r"return.*from.*graveyard.*battlefield|return.*from.*graveyard.*hand", "recursion"),
        (r"flashback|escape|you may cast.*from your graveyard", "recursion"),
        (r"cast.*graveyard.*without paying|overload|exile.*graveyard.*copy", "overload_recursion"),
        # Stax
        (r"can't cast.*from anywhere.*but.*hand|spells.*cost.*more to cast", "silence_opponents"),
        # Life
        (r"double.*life total|life total becomes", "finisher"),
    ]
    
    for pattern, effect in patterns:
        try:
            if re.search(pattern, ot):
                result = {"effect": effect, "cmc": cmc_val}
                if "Instant" in tl:
                    result["instant"] = True
                return result
        except:
            continue
    
    # Fallback by type
    if "Land" in tl:
        return {"effect": "land", "cmc": 0}
    if "Instant" in tl:
        return {"effect": "draw_cards", "count": 1, "instant": True, "cmc": cmc_val}
    if "Sorcery" in tl:
        return {"effect": "draw_cards", "count": 1, "cmc": cmc_val}
    if "Creature" in tl:
        return {"effect": "creature", "power": max(1, int(float(cmc_val))), "cmc": cmc_val}
    if "Artifact" in tl:
        return {"effect": "ramp_permanent", "mana_produced": 1, "cmc": cmc_val}
    if "Enchantment" in tl:
        return {"effect": "draw_engine", "cmc": cmc_val}
    return {"effect": "unknown", "cmc": cmc_val}

# Classify and add new cards
new_entries = {}
for r in rows:
    if len(r) < 2:
        continue
    name = r[0].strip()
    oracle = r[1] if len(r) > 1 else ""
    tl = r[2] if len(r) > 2 else ""
    cmc_val = float(r[3]) if len(r) > 3 and r[3] else 3
    
    if name in existing_names:
        continue
    if not oracle:
        continue
    
    entry = classify(oracle, tl, cmc_val)
    if entry["effect"] != "unknown" and entry["effect"] != "creature":
        new_entries[name] = entry

print(f"  New cards classified: {len(new_entries)}")

# ══════════════════════════════════════════
# STEP 2: VALIDATE existing classifications
# ══════════════════════════════════════════
print(f"\nSTEP 2: VALIDATING EXISTING CLASSIFICATIONS")

# Re-classify existing cards from PG oracle
names_to_check = list(existing_names)[:500]  # Check 500 per run (limit PG load)
corrections = 0
conflicts = 0

for chunk_start in range(0, len(names_to_check), 100):
    chunk = names_to_check[chunk_start:chunk_start+100]
    safe = ",\n".join("'" + n.replace("'","''") + "'" for n in chunk)
    oracle_rows = pg(
        "SELECT name, oracle_text, type_line, cmc FROM cards "
        "WHERE name ILIKE ANY(ARRAY[\n" + safe + "\n]) AND oracle_text IS NOT NULL"
    )
    
    for r in oracle_rows:
        if len(r) < 2:
            continue
        name = r[0].strip()
        oracle = r[1] if len(r) > 1 else ""
        tl = r[2] if len(r) > 2 else ""
        cmc_val = float(r[3]) if len(r) > 3 and r[3] else 3
        
        if name not in existing:
            continue
        
        current_entry = existing[name]
        current_effect = current_entry.get("effect", "unknown")
        
        # Skip handcrafted cards (they have special effects)
        if current_effect in ("approach", "commander", "modal_boros_charm", "redirect_removal",
                               "dragons_approach", "exile_value", "damage_wipe", "selective"):
            continue
        
        # Re-classify
        new_entry = classify(oracle, tl, cmc_val)
        new_effect = new_entry.get("effect", "unknown")
        
        if new_effect == "unknown":
            continue
        
        # Check for clear corrections
        if current_effect != new_effect:
            # Determine if the correction is clearly better
            # Rule 1: If current is a generic fallback (draw_cards, ramp_permanent) and new is specific → correct
            generic_effects = {"draw_cards", "ramp_permanent", "ramp_ritual", "indestructible", "creature"}
            specific_effects = {"silence_opponents", "counter", "board_wipe", "token_maker", 
                              "finisher", "pump_all", "phase_out", "extra_turn", 
                              "overload_recursion", "copy_spell", "tutor", "recursion",
                              "remove_permanent", "remove_creature"}
            
            if current_effect in generic_effects and new_effect in specific_effects:
                # Auto-correct: specific effect is more accurate
                existing[name] = new_entry
                corrections += 1
                if corrections <= 10:
                    print(f"  CORRECTED: {name}: {current_effect} → {new_effect}")
            elif current_effect in specific_effects and new_effect == "draw_cards":
                # Going from specific to generic is a regression — keep current
                pass
            else:
                # Both specific — conflict, log it
                conflicts += 1
                if conflicts <= 10:
                    print(f"  CONFLICT: {name}: {current_effect} vs {new_effect} (oracle: {oracle[:80]}...)")

print(f"\n  Validated: {len(names_to_check)} cards")
print(f"  Corrections: {corrections}")
print(f"  Conflicts flagged: {conflicts}")

# ══════════════════════════════════════════
# STEP 3: SAVE
# ══════════════════════════════════════════
# Merge new entries
for name, entry in new_entries.items():
    if name not in existing:
        existing[name] = entry

# Remove "unknown" and "creature" entries
filtered = {k: v for k, v in existing.items() if v.get("effect") not in ("unknown", "creature")}

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w") as f:
    json.dump(filtered, f, indent=2, sort_keys=True, default=str)

print(f"\nSTEP 3: SAVED")
print(f"  Total entries: {len(existing)} (filtered: {len(filtered)})")
print(f"  New this run: {len(new_entries)}")
print(f"  Corrected this run: {corrections}")

# Effect distribution
stats = defaultdict(int)
for v in filtered.values():
    stats[v.get("effect", "unknown")] += 1
print(f"\n  Effect distribution:")
for eff, cnt in sorted(stats.items(), key=lambda x: -x[1])[:15]:
    print(f"    {eff:<25s} {cnt}")

os.remove(LOCK)
print(f"\nDone.")
