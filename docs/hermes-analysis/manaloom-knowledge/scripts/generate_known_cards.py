#!/usr/bin/env python3
"""
KNOWN_CARDS Auto-Generator for Lorehold Battle Simulator v8.3
Reads ALL Lorehold decks from SQLite → gets oracle text from PG → classifies → outputs JSON
Maps to VALID Battle effect identifiers using oracle text analysis.

Usage: python3 scripts/generate_known_cards.py
Output: scripts/known_cards_generated.json
"""
import sqlite3, subprocess, os, re, json

_BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)))
if not os.path.exists(os.path.join(_BASE, 'knowledge.db')):
    _BASE = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts'
DB = os.path.join(_BASE, 'knowledge.db')
OUT = os.path.join(_BASE, 'known_cards_generated.json')
PGPASSWORD = "c2abeef5e66f21b0ce86"
os.environ["PGPASSWORD"] = PGPASSWORD

# ── 1. PG batch query ──────────────────────────────────────────
def _safe_cmc(val):
    try: return float(val)
    except: return 3.0

def pg(query):
    r = subprocess.run(
        ["psql","-h","143.198.230.247","-p","5433","-U","postgres","-d","halder",
         "-t","-A","-F","\t","-c",query],
        capture_output=True, text=True, timeout=60
    )
    return [line.split("\t") for line in r.stdout.strip().split("\n") if line]

# ── 2. Collect all cards from ALL Lorehold decks ───────────────
conn = sqlite3.connect(DB)
all_cards = set()
deck_count = 0

for row in conn.execute(
    "SELECT card_list FROM learned_decks "
    "WHERE commander LIKE '%Lorehold%' AND card_list IS NOT NULL"
):
    deck_count += 1
    try:
        cards = json.loads(row[0])
        for card in cards:
            all_cards.add(card["name"])
    except:
        for line in row[0].strip().split("\n"):
            line = line.strip()
            if not line: continue
            parts = line.split(" ", 1)
            if len(parts) == 2 and parts[0].isdigit():
                all_cards.add(parts[1])

print(f"Lorehold decks: {deck_count}  Unique cards: {len(all_cards)}")

# ── 3. Known cards already in Battle ───────────────────────────
battle_path = os.path.join(_BASE, 'battle_analyst_v8.py')
with open(battle_path) as f:
    battle_text = f.read()

existing = set(re.findall(r'"([^"]+)"\s*:\s*\{', 
    battle_text[:battle_text.find("TAG_EFFECTS")]))
print(f"Already hand-typed in KNOWN_CARDS: {len(existing)}")

# ── 4. Missing cards → query PG ────────────────────────────────
missing = sorted(all_cards - existing)

# Filter: exclude basic lands (they don't need KNOWN_CARDS entries)
land_names = {"Plains", "Mountain", "Island", "Swamp", "Forest", "Wastes",
              "Snow-Covered Plains", "Snow-Covered Mountain", "Snow-Covered Island",
              "Snow-Covered Swamp", "Snow-Covered Forest"}
missing = [n for n in missing if n not in land_names and not n.startswith("Snow-Covered ")]
print(f"Missing (excluding basics): {len(missing)}")

if not missing:
    print("Nothing new to generate.")
    conn.close()
    exit(0)

# Batch query in chunks
oracle_map = {}
chunk_size = 300
for i in range(0, len(missing), chunk_size):
    chunk = missing[i:i+chunk_size]
    safe_names = ",\n".join("'" + n.replace("'", "''") + "'" for n in chunk)
    rows = pg(
        "SELECT name, oracle_text, cmc, type_line, "
        "COALESCE(edhrec_rank, 99999) as rank "
        "FROM cards WHERE name ILIKE ANY(ARRAY[\n" + safe_names + "\n]) "
        "ORDER BY name"
    )
    for r in rows:
        if len(r) >= 2 and r[1]:
            oracle_map[r[0]] = {
                "oracle_text": r[1],
                "cmc": _safe_cmc(r[2]) if len(r) > 2 else 3,
                "type_line": r[3] if len(r) > 3 else "",
                "edhrec_rank": _safe_cmc(r[4]) if len(r) > 4 else 99999,
            }
    print(f"  PG chunk {i//chunk_size+1}: {len(rows)} rows  (total: {len(oracle_map)})")

print(f"\nTotal oracle entries from PG: {len(oracle_map)}")

# ── 5. Classification → Battle effect mapping ──────────────────
# Maps oracle text patterns → (effect_name, extra_params, instant_check)
# Uses PRIORITY-ORDERED patterns — first match wins
RULES = [
    # ── Win conditions (high priority) ──
    (r"you win the game|win the game|cannot lose|opponent loses the game",
     "finisher", {}, False),
    # ── Approach of the Second Sun ──
    (r"second approach|you've cast another spell named Approach",
     "approach", {"gain_life": 7}, False),
    # ── Extra turns ──
    (r"take an extra turn|additional turn|after this main phase.*additional",
     "unknown", {}, False),  # no handler in Battle yet
    # ── Board wipes ──
    (r"destroy all creatures|destroy all.*creatures|deals.*damage to each creature",
     "board_wipe", {}, False),
    (r"exile all creatures|exile all permanents|exile all artifact|exile each.*permanent",
     "board_wipe", {}, False),
    # ── Steal all ──
    (r"gain control of all creatures|untap all creatures.*gain control",
     "steal_all_creatures", {}, False),
    # ── Pump all ──
    (r"creatures you control get \+|creatures.*gain.*flying.*indestructible.*double strike|creatures.*gain.*vigilance.*lifelink",
     "pump_all", {}, True),
    # ── Silence / counter protection ──
    (r"players can't cast|can't cast spells|can't cast.*this turn|spells you control can't be countered",
     "silence_opponents", {}, False),
    (r"counter target spell|counter.*unless.*pay|counter.*spell",
     "counter", {}, True),
    # ── Phase out / indestructible ──
    (r"phase out|phases out",
     "phase_out", {}, True),
    (r"hexproof|shroud|protection from|gain.*hexproof|gain.*protection|indestructible until|indestructible",
     "indestructible", {"duration": 1}, True),
    # ── Token makers ──
    (r"create.*treasure token|create.*Treasure",
     "ramp_engine", {}, False),
    (r"create.*\d+/|create.*X .*angel|create.*X .*dragon|create.*\d+ .*creature token",
     "token_maker", {"token_count": "oracle", "token_power": "oracle"}, False),
    (r"create a.*token|create.*\d+/\d+.*token",
     "token_maker", {"token_count": 1, "token_power": 1}, False),
    # ── Draw engines ──
    (r"whenever.*opponent.*draw|whenever.*player.*draw.*you may|whenever.*draw.*gain",
     "draw_engine", {"trigger": "opponent_draw"}, False),
    (r"whenever.*opponent.*cast|whenever.*player.*cast.*draw|whenever an opponent",
     "draw_engine", {"trigger": "opponent_spell"}, False),
    (r"at the beginning of.*upkeep.*draw|at the beginning of.*draw.*step.*draw",
     "draw_engine", {}, False),
    # ── Draw cards ──
    (r"draw.*seven cards|draw.*cards.*discard your hand|wheel effect",
     "draw_cards", {"count": 7}, False),
    (r"draw.*three cards|draw.*\d+ cards",
     "draw_cards", {"count": 3}, False),
    (r"draw.*cards?[^.]*$|draw a card",
     "draw_cards", {"count": 2}, False),
    # ── Scry / topdeck ──
    (r"scry|surveil|look at the top.*card.*library|reveal.*top.*put.*hand",
     "topdeck_manipulation", {}, False),
    # ── Rituals ──
    (r"add.*mana for each|add.*red.*for each|add.*white.*for each",
     "ramp_ritual", {"mana_produced": 7}, True),
    (r"add.*\{R\}.*\{R\}.*\{R\}|add.*three.*mana|add.*\{W\}.*\{W\}.*\{W\}",
     "ramp_ritual", {"mana_produced": 3}, True),
    (r"add.*\{R\}|add.*\{W\}|add one mana",
     "ramp_ritual", {"mana_produced": 1}, True),
    # ── Ramp permanents ──
    (r"\{T\}.*add.*two.*mana|add.*two.*mana.*\{T\}|add.*\{C\}\{C\}",
     "ramp_permanent", {"mana_produced": 2}, False),
    (r"\{T\}.*add.*mana|adds.*mana|for each tapped|tapped for mana",
     "ramp_permanent", {"mana_produced": 1}, False),
    (r"search.*library.*land.*put.*battlefield|search.*library.*land.*tapped",
     "ramp_permanent", {"mana_produced": 1}, False),
    # ── Copy spell engines ──
    (r"copy.*instant.*sorcery|whenever you cast.*copy|copied.*additional",
     "copy_spell", {}, False),
    (r"ripple|ripple 4",
     "ripple_engine", {}, False),
    # ── Tutors ──
    (r"search.*library.*put.*hand|search.*library.*reveal.*put|transmute",
     "tutor", {"target": "any"}, False),
    (r"search.*library.*artifact|search.*library.*enchantment",
     "tutor", {"target": "artifact_or_enchantment"}, False),
    # ── Recursion ──
    (r"return.*from.*graveyard.*battlefield|return.*from.*graveyard.*hand",
     "recursion", {"count": 2}, False),
    (r"flashback|escape|you may cast.*from your graveyard",
     "recursion", {"count": 1}, False),
    (r"cast.*graveyard.*without paying|overload|exile.*graveyard.*copy|exile.*graveyard.*you may cast",
     "overload_recursion", {}, False),
    # ── Removal ──
    (r"exile target.*creature|exile target.*permanent|destroy target.*creature|destroy target.*artifact|destroy target.*permanent",
     "remove_permanent", {}, True),
    (r"deals.*damage to target.*creature|deals.*damage to target.*player|deals.*\d+ damage to any target",
     "remove_creature", {}, True),
    # ── Damage multipliers ──
    (r"triple.*damage|damage.*tripled|if.*would deal.*damage.*triple",
     "finisher", {}, False),  # approximated as finisher
    (r"double.*damage|damage.*doubled|if.*would deal.*damage.*double",
     "finisher", {}, False),
    # ── Specific wincon spells ──  
    (r"worldfire|life total becomes 1|each player.*life.*1",
     "board_wipe", {}, False),  # approximated
    # ── Instant/Sorcery speed flags ──
    (r"can't be countered",
     "silence_opponents", {}, False),
    # ── Blue hate (Pyroblast, REB) ──
    (r"counter target.*if it's blue|destroy target.*if it's blue|choose one.*counter.*blue|red elemental blast",
     "remove_permanent", {}, True),
    # ── Storm / lifegain payoff ──
    (r"storm|whenever you cast.*gain.*life|whenever you cast.*lose.*life|whenever you cast.*deal.*damage to.*opponent",
     "finisher", {}, False),
    # ── Lifegain payoff ──
    (r"pay.*life.*deal.*damage|pay.*\d+ life.*destroy|pay.*\d+ life.*counter|pay.*life.*exile",
     "finisher", {}, True),
    # ── Kicker choose modes (Orim's Chant) ──
    (r"kicker.*can't cast spells|kicker.*creatures can't attack",
     "silence_opponents", {}, True),
]

def classify(cd):
    """Classify a card into a Battle effect + params."""
    ot = cd.get("oracle_text", "").lower()
    tl = cd.get("type_line", "")
    cmc = cd.get("cmc", 3)
    
    for pattern, effect, params, is_instant_default in RULES:
        if re.search(pattern, ot):
            result = {"effect": effect, **(params.copy())}
            
            # Determine instant flag
            is_instant = is_instant_default or "Instant" in tl
            if effect in ("remove_permanent", "remove_creature", "remove_artifact_or_3dmg", 
                         "indestructible", "phase_out", "ramp_ritual", "ramp_permanent",
                         "draw_cards", "tutor", "counter", "silence_opponents", "pump_all"):
                is_instant = is_instant or "Instant" in tl
            if "can't be countered" in ot:
                result["uncounterable"] = True
            if is_instant:
                result["instant"] = True
            
            # Parse token counts from oracle
            if effect == "token_maker" and params.get("token_count") == "oracle":
                # Extract token count and power
                tc_match = re.search(r'create\s+(?:a\s+)?(\d+|X)\s+(\d+)/(\d+)', ot)
                if tc_match:
                    result["token_power"] = int(tc_match.group(2))
                    if tc_match.group(1) == "X":
                        result["token_count"] = 4  # default
                    else:
                        result["token_count"] = int(tc_match.group(1))
                elif "for each" in ot or "equal to" in ot:
                    result["token_count"] = 5
            
            # Parse draw count
            if effect == "draw_cards":
                dm = re.search(r'draw\s+(\d+)\s+cards?', ot)
                if dm:
                    result["count"] = int(dm.group(1))
                elif "draw a card" in ot:
                    result["count"] = 1
            
            # Parse mana produced for ramp
            if effect in ("ramp_permanent", "ramp_ritual"):
                if re.search(r'add.*two.*mana|add.*\{C\}\{C\}|two colorless', ot):
                    result["mana_produced"] = 2
                elif re.search(r'add.*three.*mana|add.*\{R\}\{R\}\{R\}', ot):
                    result["mana_produced"] = 3
                elif re.search(r'add.*for each|add.*mana equal to', ot):
                    result["mana_produced"] = 7  # Jeska's Will scale
            
            # Miracle detection
            if "miracle" in ot:
                m = re.search(r'Miracle\s+\{?(\w+)\}?', ot, re.IGNORECASE)
                if m:
                    result["miracle"] = m.group(1)
            
            result["cmc"] = cmc
            return result
    
    # Fallback: classify by type line
    if "Instant" in tl:
        result = {"effect": "unknown", "instant": True, "cmc": cmc}
    elif "Sorcery" in tl:
        result = {"effect": "draw_cards", "count": 1, "cmc": cmc}  # generic sorcery = draw
    elif "Creature" in tl:
        result = {"effect": "creature", "power": max(1, int(cmc)), "cmc": cmc}
    elif "Artifact" in tl:
        result = {"effect": "ramp_permanent", "mana_produced": 1, "cmc": cmc}
    elif "Enchantment" in tl:
        result = {"effect": "draw_engine", "cmc": cmc}
    else:
        result = {"effect": "unknown", "cmc": cmc}
    
    return result

# ── 6. Generate entries ────────────────────────────────────────
new_entries = {}
stats = {}

for name in missing:
    cd = oracle_map.get(name)
    if not cd:
        # Try case-insensitive match
        for k in oracle_map:
            if k.lower() == name.lower():
                cd = oracle_map[k]
                name = k
                break
    if cd:
        entry = classify(cd)
        effect = entry["effect"]
        stats[effect] = stats.get(effect, 0) + 1
        new_entries[name] = entry

print(f"\nGenerated {len(new_entries)} entries. Effect distribution:")
for eff, cnt in sorted(stats.items(), key=lambda x: -x[1]):
    pct = 100 * cnt / len(new_entries)
    print(f"  {eff:<25s} {cnt:>3d}  ({pct:.1f}%)")

# ── 7. Save (only known effects) ─────────────────────────────────
filtered_entries = {k: v for k, v in new_entries.items() if v["effect"] != "unknown"}
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w") as f:
    json.dump(filtered_entries, f, indent=2, sort_keys=True, default=str)

print(f"\nSaved {len(filtered_entries)} entries (excluded {len(new_entries) - len(filtered_entries)} unknowns) → {OUT}")
print(f"Coverage: {len(existing) + len(filtered_entries)}/{len(all_cards) + len(existing)} cards total")

# ── 8. Quick validation ─────────────────────────────────────────
# Check for common critical cards
critical = {
    "Silence": "Should be silence_opponents",
    "Orim's Chant": "Should be silence_opponents",
    "Hexing Squelcher": "Should be silence_opponents (uncounterable)",
    "Fiery Emancipation": "Should be damage multiplier",
    "Worldfire": "Should be board_wipe or special",
    "Aetherflux Reservoir": "Should be storm finisher",
    "Drannith Magistrate": "Should be stax",
    "Lightning Greaves": "Should be protection",
    "Pyroblast": "Should be counter/removal",
    "Red Elemental Blast": "Should be counter/removal",
}
print("\nCritical card classification check:")
for card_name, expected in critical.items():
    if card_name in new_entries:
        eff = new_entries[card_name]["effect"]
        ok = " OK" if eff != "unknown" else " ???"
        print(f"  {card_name:<25s} → {eff:<20s}  {ok}")
    elif card_name in all_cards:
        print(f"  {card_name:<25s} → NOT FOUND IN PG (check name)")
    else:
        print(f"  {card_name:<25s} → NOT IN any deck")

conn.close()
