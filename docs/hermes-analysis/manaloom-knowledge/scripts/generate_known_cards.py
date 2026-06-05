"""Comprehensive fix: reclassify ALL unknowns with better patterns + fix PG parsing."""
import sqlite3, subprocess, os, re, json

DB = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'
OUT = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_generated.json'

os.environ["PGPASSWORD"] = "c2abeef5e66f21b0ce86"

def pg(query):
    """PG query using RECORD=0x1e FIELD=0x1f (printable, no null bytes)."""
    r = subprocess.run(
        ["psql","-h","143.198.230.247","-p","5433","-U","postgres","-d","halder",
         "-t","-A","-F","\x1f","-R","\x1e","-c",query],
        capture_output=True, text=True, timeout=60
    )
    rows = []
    for line in r.stdout.strip().split("\x1e"):
        line = line.strip()
        if line:
            parts = line.split("\x1f")
            rows.append(parts)
    return rows

def _safe_cmc(val):
    try: return float(val)
    except: return 3.0

# 1. Collect all Lorehold cards
conn = sqlite3.connect(DB)
all_cards = set()
for row in conn.execute(
    "SELECT card_list FROM learned_decks "
    "WHERE commander LIKE '%Lorehold%' AND card_list IS NOT NULL"
):
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

print(f"Total Lorehold cards: {len(all_cards)}")

# 2. Existing handcrafted
battle_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'battle_analyst_v8.py')
with open(battle_path) as f:
    battle_text = f.read()
existing_hand = set(re.findall(r'"([^"]+)"\s*:\s*\{',
    battle_text[:battle_text.find("TAG_EFFECTS")]))
print(f"Handcrafted: {len(existing_hand)}")

# 3. Get PG data for ALL cards in one shot
missing = sorted(all_cards - existing_hand)
land_pattern = re.compile(r'^(?:Snow-Covered )?(?:Plains|Mountain|Island|Swamp|Forest|Wastes)$')
missing = [n for n in missing if not land_pattern.match(n)]
print(f"To classify: {len(missing)}")

oracle_map = {}
for i in range(0, len(missing), 300):
    chunk = missing[i:i+300]
    safe = ",\n".join("'" + n.replace("'","''") + "'" for n in chunk)
    rows = pg(
        "SELECT name, oracle_text, type_line, cmc FROM cards "
        "WHERE name ILIKE ANY(ARRAY[\n" + safe + "\n]) AND oracle_text IS NOT NULL"
    )
    for r in rows:
        if len(r) >= 2 and r[1]:
            oracle_map[r[0].strip()] = {
                "oracle_text": r[1],
                "type_line": r[2] if len(r) > 2 else "",
                "cmc": _safe_cmc(r[3]) if len(r) > 3 else 3,
            }
    print(f"  PG chunk {i//300+1}: {len(rows)} rows (total: {len(oracle_map)})")

# Match by case-insensitive
for name in list(missing):
    if name not in oracle_map:
        for k in oracle_map:
            if k.lower() == name.lower():
                oracle_map[name] = oracle_map[k]
                break

print(f"\nMatched: {len(oracle_map)}/{len(missing)}")

# 4. CLASSIFICATION RULES — comprehensive, priority-ordered
# All patterns tested against LOWERCASE oracle text
# Priority: finisher > lifegain-payoff > storm > specific-spells > removal
RULES = [
    # ── Silence / can't cast ──
    ("(?:players|opponents|target player) can't cast spells|can't cast.*spells.*this turn",
     "silence_opponents", {}, True),
    
    # ── Uncounterable ──
    ("can't be countered",
     "silence_opponents", {"uncounterable": True}, False),
    
    # ── Counter spells (high priority — catch before removal) ──
    ("counter target.*spell.*unless|counter target.*spell.*pay|counter target spell",
     "counter", {}, True),
    ("counter target.*blue|destroy target.*blue|choose one.*counter.*blue|red elemental blast",
     "counter", {}, True),
    
    # ── Win conditions (HIGH PRIORITY — before removal) ──
    ("you win the game|win the game|cannot lose|opponent loses the game",
     "finisher", {}, False),
    
    # ── Storm / spellslinger payoff (before removal) ──
    ("storm\b|whenever you cast.*instant.*sorcery.*deal.*damage|whenever.*cast.*noncreature.*deal.*damage",
     "finisher", {}, False),
    
    # ── Lifegain payoff (before removal — Aetherflux!) ──
    ("pay.*\\d+ life.*deal.*damage|pay.*\\d+ life.*destroy|pay.*life.*counter|pay.*life.*exile",
     "finisher", {}, False),
    ("whenever you gain life.*opponent loses|whenever.*gain.*life.*deal.*damage|whenever you cast.*you gain.*life.*for each",
     "finisher", {}, False),
    
    # ── Damage multipliers ──
    ("triple.*damage|damage.*tripled|if.*would deal.*damage.*triple",
     "finisher", {}, False),
    ("double.*damage|damage.*doubled|if.*would deal.*damage.*double",
     "finisher", {}, False),
    
    # ── Approach ──
    ("second approach|you've cast another spell named approach",
     "approach", {"gain_life": 7}, False),
    
    # ── Extra turn ──
    ("take an extra turn|additional turn|after this main phase.*additional",
     "extra_turn", {}, False),
    
    # ── Board wipes (mass removal) ──
    ("destroy all creatures|destroy all.*creatures|deals.*damage to each creature",
     "board_wipe", {}, False),
    ("exile all creatures|exile all permanents|exile all.*artifacts|exile all.*nonland",
     "board_wipe", {}, False),
    ("each player sacrifices.*all|sacrifices.*all.*creatures",
     "board_wipe", {}, False),
    ("destroy all lands|destroy all.*lands",
     "board_wipe", {}, False),
    
    # ── Steal all ──
    ("gain control of all creatures|untap all creatures.*gain control",
     "steal_all_creatures", {}, False),
    
    # ── Pump all ──
    ("creatures you control get \\+|creatures.*gain.*indestructible.*double strike|creatures you control gain.*flying.*vigilance.*lifelink",
     "pump_all", {}, True),
    
    # ── Phase out ──
    ("phase out|phases out",
     "phase_out", {}, True),
    
    # ── Indestructible / protection ──
    ("gain.*indestructible until|indestructible until end of turn|creatures.*gain indestructible",
     "indestructible", {"duration": 1}, True),
    ("prevent.*(?:all|that|the next).*damage.*(?:would be dealt|dealt to you|dealt.*this turn)",
     "indestructible", {"duration": 1}, True),
    ("prevent.*damage.*that would be dealt|prevent that damage.*deals",
     "indestructible", {"duration": 1}, True),
    ("hexproof|shroud|protection from|gain protection from",
     "indestructible", {"duration": 1}, False),
    
    # ── Targeted removal (LOWER priority than finisher) ──
    ("exile target.*creature|exile target.*permanent|destroy target.*creature|destroy target.*artifact|destroy target.*permanent",
     "remove_permanent", {}, True),
    ("deals.*damage to target.*creature|deals.*damage to target.*player",
     "remove_creature", {}, True),
    ("deals.*damage to any target|deals \\d+ damage to target",
     "remove_creature", {}, True),
    
    # ── Token makers ──
    ("create.*treasure token|create a treasure token",
     "ramp_engine", {}, False),
    ("create.*\\d+/|create x .*angel|create x .*dragon|create.*\\d+ .*creature token",
     "token_maker", {"token_count": "oracle", "token_power": "oracle"}, False),
    ("create a.*token|create.*token",
     "token_maker", {"token_count": 1, "token_power": 1}, False),
    
    # ── Draw engines ──
    ("whenever.*opponent.*draw.*card|whenever.*player.*draw.*you may|whenever an opponent.*draws",
     "draw_engine", {"trigger": "opponent_draw"}, False),
    ("whenever.*opponent.*cast.*spell.*draw|whenever an opponent.*casts.*draw",
     "draw_engine", {"trigger": "opponent_spell"}, False),
    ("at the beginning of.*upkeep.*draw a card|at the beginning of.*draw step.*draw",
     "draw_engine", {}, False),
    
    # ── Wheel effects ──
    ("discard.*hand.*draw.*cards|each player.*discard.*hand.*draw",
     "draw_cards", {"count": 7}, False),
    
    # ── Draw cards (one-shot) ──
    ("draw.*seven cards|draw.*cards.*discard your hand",
     "draw_cards", {"count": 7}, False),
    ("draw three cards|draw.*3 cards",
     "draw_cards", {"count": 3}, False),
    ("draw two cards|draw.*2 cards",
     "draw_cards", {"count": 2}, False),
    ("draw a card|draw cards",
     "draw_cards", {"count": 1}, False),
    
    # ── Scry / topdeck / surveil ──
    ("scry \\d|surveil \\d|look at the top.*card.*library|reveal.*top.*put.*hand",
     "topdeck_manipulation", {}, False),
    
     # ── Ramp permanents (mana rocks) — MUST come BEFORE rituals ──
    ("\\{t\\}: add.*mana.*any.*color|\\{t\\}: add.*one mana of any",
     "ramp_permanent", {"mana_produced": 1}, False),
    ("\\{t\\}: add.*\\{[cC]\\}\\{[cC]\\}\\{[cC]\\}|add.*\\{c\\}\\{c\\}\\{c\\}.*\\{t\\}",
     "ramp_permanent", {"mana_produced": 3}, False),
    ("\\{t\\}: add.*\\{[cC]\\}\\{[cC]\\}|add.*two.*colorless.*\\{t\\}|\\{t\\}.*add.*\\{[cC]\\}\\{[cC]\\}",
     "ramp_permanent", {"mana_produced": 2}, False),
    ("\\{t\\}: add|adds.*mana|for each tapped|tapped for mana",
     "ramp_permanent", {"mana_produced": 1}, False),
    # Fetch lands / land search
    ("search.*library.*land.*put.*battlefield|search.*library.*land.*tapped",
     "ramp_permanent", {"mana_produced": 1}, False),
    # Moxen (imprint/discard-based ramp) — catch BEFORE generic add-one-mana
    ("imprint.*exile.*card.*add.*mana|exile.*card.*\\{t\\}.*add.*mana",
     "ramp_permanent", {"mana_produced": 1}, False),
    ("discard a land.*add.*mana|discard.*land.*\\{t\\}.*add",
     "ramp_permanent", {"mana_produced": 1}, False),
    # Doesn't untap normally (Mana Vault, Grim Monolith): still a mana rock
    ("doesn't untap.*\\{t\\}: add|doesn't untap during.*untap.*\\{t\\}: add",
     "ramp_permanent", {"mana_produced": 2}, False),
    # Sacrifice-based mana
    ("sacrifice.*add.*mana|sacrifice.*\\{t\\}.*add",
     "ramp_ritual", {"mana_produced": 1}, False),
    
    # ── Rituals (big mana) — MUST come AFTER permanent ramp patterns ──
    # Only match NON-permanent mana sources (instants/sorceries)
    ("add.*mana for each|add.*red.*for each|add.*white.*for each",
     "ramp_ritual", {"mana_produced": 7}, True),
    # Seething Song: {R}{R}{R}{R}{R} — matches 5 consecutive reds
    ("add.*\\{[rR]\\}\\{[rR]\\}\\{[rR]\\}\\{[rR]\\}\\{[rR]\\}",
     "ramp_ritual", {"mana_produced": 5}, True),
    ("add.*\\{[rR]\\}\\{[rR]\\}\\{[rR]\\}\\{[rR]\\}|add.*four.*red|add.*\\{[cC]\\}\\{[cC]\\}\\{[cC]\\}",
     "ramp_ritual", {"mana_produced": 4}, True),
    ("add.*three.*mana|add.*\\{[cC]\\}\\{[cC]\\}|add.*\\{[rR]\\}\\{[rR]\\}\\{[rR]\\}",
     "ramp_ritual", {"mana_produced": 3}, True),
    ("add.*\\{[rR]\\}|add.*\\{[wW]\\}|add one.*mana",
     "ramp_ritual", {"mana_produced": 1}, True),
    
    # ── Copy spell engines ──
    ("copy.*instant.*sorcery|whenever you cast.*instant.*sorcery.*copy|copied.*additional",
     "copy_spell", {}, False),
    ("ripple|ripple 4",
     "ripple_engine", {}, False),
    # Buyback copy (Reiterate)
    ("buyback.*copy.*instant.*sorcery|buyback.*copy target",
     "copy_spell", {}, True),
    
    # ── Tutors ──
    ("search your library.*artifact|search your library.*enchantment",
     "tutor", {"target": "artifact_or_enchantment"}, False),
    ("search.*library.*put.*hand|search.*library.*reveal.*put|transmute",
     "tutor", {"target": "any"}, False),
    
    # ── Recursion / graveyard ──
    ("return.*from.*graveyard.*battlefield|return.*from.*graveyard.*hand",
     "recursion", {"count": 2}, False),
    ("flashback|escape|you may cast.*from your graveyard",
     "recursion", {"count": 1}, False),
    ("cast.*graveyard.*without paying|overload|exile.*graveyard.*copy|exile.*graveyard.*you may cast",
     "overload_recursion", {}, False),
    
    # ── Stax / tax ──
    ("can't cast.*from anywhere.*but.*hand|spells.*cost.*more to cast|can't activate.*abilities|can't untap|enters.*tapped.*unless",
     "silence_opponents", {}, False),
    
    # ── Life doubling / alternate win ──
    ("double.*life total|life total becomes",
     "finisher", {}, False),
    
    # ── Discard / hand attack ──
    ("target player.*discard.*card|each opponent.*discard.*card",
     "silence_opponents", {}, False),
]

EFFECT_DESC = {
    "silence_opponents": "Silence / anti-cast / uncounterable",
    "counter": "Counterspell",
    "extra_turn": "Extra turn",
    "finisher": "Win condition / finisher",
    "approach": "Approach of the Second Sun",
    "board_wipe": "Board wipe / mass removal",
    "steal_all_creatures": "Steal all creatures",
    "pump_all": "Mass pump (Akroma's Will style)",
    "phase_out": "Phase out (Teferi's Protection style)",
    "indestructible": "Protection / indestructible / prevent damage",
    "ramp_engine": "Ramp engine (treasures etc.)",
    "token_maker": "Token creation",
    "draw_engine": "Draw engine (repeatable)",
    "draw_cards": "Draw cards (one-shot)",
    "topdeck_manipulation": "Topdeck manipulation / scry",
    "ramp_ritual": "Mana ritual (one-shot)",
    "ramp_permanent": "Mana rock / permanent ramp",
    "copy_spell": "Spell copying",
    "ripple_engine": "Ripple engine",
    "tutor": "Tutor / search library",
    "recursion": "Graveyard recursion",
    "overload_recursion": "Overload / mass recursion",
    "remove_permanent": "Targeted permanent removal",
    "remove_creature": "Targeted creature removal",
}

def classify(cd):
    ot = (cd.get("oracle_text") or "").lower()
    tl = cd.get("type_line", "")
    cmc = cd.get("cmc", 3)
    
    for pattern, effect, params, is_inst in RULES:
        if re.search(pattern, ot):
            result = {"effect": effect, **params}
            
            # Determine instant speed
            if is_inst or "Instant" in tl:
                result["instant"] = True
            
            # Parse token details — ensure oracle placeholder never leaks
            if effect == "token_maker" and params.get("token_count") == "oracle":
                tc_match = re.search(r"create\s+(?:a\s+)?(\d+|X)\s+(\d+)/(\d+)", ot)
                if tc_match:
                    result["token_power"] = int(tc_match.group(2))
                    result["token_count"] = 4 if tc_match.group(1) == "X" else int(tc_match.group(1))
                elif "for each" in ot or "equal to" in ot:
                    result["token_power"] = 3
                    result["token_count"] = 5
                elif "life total" in ot:
                    result["token_count"] = "life_total"
                    result["token_power"] = 2
                else:
                    result["token_power"] = 1
                    result["token_count"] = 1
            
            # Parse draw count
            if effect == "draw_cards":
                dm = re.search(r"draw\s+(\d+)\s+cards?", ot)
                if dm:
                    result["count"] = int(dm.group(1))
                elif "draw cards equal" in ot or "for each" in ot:
                    result["count"] = 5
            
            # Parse mana produced
            if effect in ("ramp_permanent", "ramp_ritual"):
                if re.search(r"add.*five.*\{R\}|add.*\{R\}\{R\}\{R\}\{R\}\{R\}", ot):
                    result["mana_produced"] = 5
                elif re.search(r"add.*four.*\{R\}|add.*\{R\}\{R\}\{R\}\{R\}|add.*\{C\}\{C\}\{C\}", ot):
                    result["mana_produced"] = 4
                elif re.search(r"add.*three.*mana|add.*\{C\}\{C\}\{C\}|add.*\{R\}\{R\}\{R\}", ot):
                    result["mana_produced"] = 3
                elif re.search(r"add.*two.*mana|add.*\{C\}\{C\}|two colorless", ot):
                    result["mana_produced"] = 2
            
            # Miracle detection
            if "miracle" in ot:
                m = re.search(r"Miracle\s+\{?(\w+)\}?", ot, re.IGNORECASE)
                if m:
                    result["miracle"] = m.group(1)
            
            result["cmc"] = cmc
            return result
    
    # Fallback: classify by type
    if "Land" in tl:
        # Lands with mana abilities -> ramp type
        ot = cd.get("oracle_text", "").lower()
        if re.search(r"\\{t\\}: add.*\\{[cC]\\}\\{[cC]\\}", ot):
            return {"effect": "ramp_permanent", "mana_produced": 2, "cmc": 0}
        if re.search(r"\\{t\\}: add.*mana|adds.*mana", ot):
            return {"effect": "ramp_permanent", "mana_produced": 1, "cmc": 0}
        return {"effect": "land", "cmc": 0}
    if "Instant" in tl:
        return {"effect": "unknown", "instant": True, "cmc": cmc}
    if "Sorcery" in tl:
        return {"effect": "draw_cards", "count": 1, "cmc": cmc}
    if "Creature" in tl:
        return {"effect": "creature", "power": max(1, int(cmc)), "cmc": cmc}
    if "Artifact" in tl:
        return {"effect": "ramp_permanent", "mana_produced": 1, "cmc": cmc}
    if "Enchantment" in tl:
        return {"effect": "draw_engine", "cmc": cmc}
    if "Planeswalker" in tl:
        return {"effect": "finisher", "cmc": cmc}
    
    return {"effect": "unknown", "cmc": cmc}

# 5. Generate entries
new_entries = {}
stats = {}
for name in sorted(missing):
    cd = oracle_map.get(name)
    if cd:
        entry = classify(cd)
        effect = entry["effect"]
        stats[effect] = stats.get(effect, 0) + 1
        new_entries[name] = entry

# 6. Save only non-unknown
filtered = {k: v for k, v in new_entries.items() if v["effect"] != "unknown"}
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w") as f:
    json.dump(filtered, f, indent=2, sort_keys=True, default=str)

print(f"\nEffect distribution:")
for eff, cnt in sorted(stats.items(), key=lambda x: -x[1]):
    pct = 100 * cnt / len(new_entries) if new_entries else 0
    mark = " *" if eff == "unknown" else ""
    print(f"  {eff:<25s} {cnt:>3d}  ({pct:.1f}%){mark}")

print(f"\nSaved {len(filtered)} entries (excluded {stats.get('unknown', 0)} unknowns)")
print(f"Total KNOWN_CARDS: {len(existing_hand) + len(filtered)} ({len(existing_hand)} handcrafted + {len(filtered)} generated)")

# 7. Critical card check
critical = {
    "Silence": "silence_opponents",
    "Orim's Chant": "silence_opponents",
    "Hexing Squelcher": "silence_opponents",
    "Fiery Emancipation": "finisher",
    "Worldfire": "board_wipe",
    "Aetherflux Reservoir": "finisher",
    "Drannith Magistrate": "silence_opponents",
    "Lightning Greaves": "indestructible",
    "Pyroblast": "counter",
    "Red Elemental Blast": "counter",
    "Seething Song": "ramp_ritual",
    "Mana Crypt": "ramp_permanent",
    "Mana Vault": "ramp_permanent",
    "Chrome Mox": "ramp_permanent",
    "Mox Diamond": "ramp_permanent",
    "Lotus Petal": "ramp_ritual",
    "Ancient Tomb": "ramp_permanent",
    "Maze of Ith": "indestructible",
    "Deflecting Palm": "indestructible",
    "Chance for Glory": "extra_turn",  # primary effect is extra turn (indestructible is secondary)
}
print("\nCritical classification check:")
good = bad = 0
for name, expected in critical.items():
    if name in new_entries:
        eff = new_entries[name]["effect"]
        status = "OK" if eff == expected else f"MISMATCH (got {eff}, want {expected})"
    elif name in existing_hand:
        status = "OK (handcrafted)"
    elif name in all_cards:
        status = "NOT IN PG ORACLE"
    else:
        status = "NOT IN ANY DECK"
    if "OK" in status:
        good += 1
    else:
        bad += 1
    print(f"  {name:<25s} → {status}")
print(f"\n  {good}/{good+bad} correct, {bad} issues")

conn.close()
