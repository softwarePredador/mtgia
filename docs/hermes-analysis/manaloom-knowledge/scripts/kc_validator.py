#!/usr/bin/env python3
"""
KNOWN_CARDS Validator & Expander — Cron-safe
- Pulls new Boros/WR cards from PG (card_deck_analysis, edhrec_rank < 2000)
- Validates existing KNOWN_CARDS classifications against PG oracle text
- Auto-corrects clear misclassifications
- Expands card pool continuously
"""
import sqlite3, subprocess, os, json, re, sys, time
from pathlib import Path
from collections import defaultdict
from datetime import datetime, timezone

SCRIPT_DIR = Path(
    os.environ.get("MANALOOM_HERMES_SCRIPT_DIR", Path(__file__).resolve().parent)
).resolve()
DB = os.environ.get("MANALOOM_KNOWLEDGE_DB", str(SCRIPT_DIR / "knowledge.db"))
OUT = os.environ.get("MANALOOM_KNOWN_CARDS_OUT", str(SCRIPT_DIR / "known_cards_generated.json"))
LOCK = '/tmp/kc_validator.lock'
REPORT_DIR = os.environ.get(
    "KC_VALIDATOR_REPORT_DIR",
    str(SCRIPT_DIR.parents[1] / "kc_validator_reports"),
)

BASELINE_WR = 81.8

MANUAL_EFFECT_OVERRIDES = {
    # Lorehold/topdeck cards are source-backed in reviewed battle rules. Keep
    # this legacy generated fallback aligned so validator runs do not recreate
    # stale ramp/draw classifications for these engine pieces.
    "Approach of the Second Sun": {
        "effect": "approach",
        "gain_life": 7,
    },
    "Brainstone": {
        "effect": "topdeck_manipulation",
        "activation_cost_generic": 2,
        "hand_to_top_exchange": True,
        "battle_model_scope": "brainstone_draw_three_put_two_back_unexecuted_v1",
    },
    "Library of Leng": {
        "effect": "passive",
        "no_max_hand_size": True,
        "discard_effect_to_top_replacement": True,
        "battle_model_scope": "discard_replacement_to_top_v1",
    },
    "Lorehold, the Historian": {
        "effect": "passive",
        "is_commander": True,
        "haste": True,
        "grants_miracle_cost": 2,
        "opponent_upkeep_rummage": True,
        "battle_model_scope": "lorehold_opponent_upkeep_miracle_v1",
    },
    "Scroll Rack": {
        "effect": "topdeck_manipulation",
        "activation_cost_generic": 1,
        "hand_to_top_exchange": True,
        "battle_model_scope": "scroll_rack_upkeep_single_exchange_v1",
    },
    "Sensei's Divining Top": {
        "effect": "topdeck_manipulation",
        "activation_cost_generic": 1,
        "peek_top_count": 3,
        "reorder_top": True,
        "activated_draw_put_self_on_top": True,
        "battle_model_scope": "senseis_top_reorder_draw_v1",
    },
    # Large face-capable burn is treated as a closer in the simplified battle
    # engine; otherwise it wastes 7-damage spells as creature-only removal.
    "Cinder Storm": "finisher",
    # Spellslinger payoff. Offspring exists, but the deck role is repeatable
    # table damage from noncreature spells.
    "Coruscation Mage": "finisher",
    # Prevention/reflection is defensive protection in the current battle model.
    "Deflecting Palm": "indestructible",
    # Reveal/damage/draw hybrid. Keep the value/topdeck role until the battle
    # engine has a dedicated burn-plus-card effect.
    "Explosive Revelation": "topdeck_manipulation",
    "Firebrand Archer": "finisher",
    "Firesong and Sunspeaker": "finisher",
    # Storm finisher. Treating this as one-point removal makes the battle engine
    # undervalue storm kills.
    "Grapeshot": "finisher",
    "Kessig Flamebreather": "finisher",
    "Longshot, Rebel Bowman": "finisher",
    # One-shot mana burst, not a rock/permanent.
    "Mana Geyser": "ramp_ritual",
    # Stax lock. Generic enchantment fallback misreads it as draw engine.
    "Overwhelming Splendor": "silence_opponents",
    # Repeatable punish/removal trigger.
    "Scalelord Reckoner": "remove_permanent",
    # Modal sweeper. The creature-wipe mode is the safest simplified role.
    "Slagstorm": "board_wipe",
    # Ugin's relevant simplified role is permanent removal.
    "Ugin, the Ineffable": "remove_permanent",
    # Stax/mana denial, not a mana rock.
    "Winter Orb": "silence_opponents",
    # Mass reanimate. The generic classifier sees this as a finisher because it
    # can close games, but the simulator role is still recursion.
    "Storm of Souls": "recursion",
    # Recast engine for instants/sorceries. The generic fallback sees a creature,
    # but the relevant battle role is graveyard spell recursion.
    "Radiant Scrollwielder": "overload_recursion",
}

if os.path.exists(LOCK):
    age = time.time() - os.path.getmtime(LOCK)
    if age < 7200:
        print(f"LOCKED ({age:.0f}s). Exiting.")
        sys.exit(0)
    os.remove(LOCK)
open(LOCK, 'w').close()

def _pg_command():
    database_url = os.environ.get("DATABASE_URL")
    if database_url:
        return ["psql", database_url]

    host = os.environ.get("PGHOST") or os.environ.get("DB_HOST")
    port = os.environ.get("PGPORT") or os.environ.get("DB_PORT") or "5432"
    user = os.environ.get("PGUSER") or os.environ.get("DB_USER")
    database = os.environ.get("PGDATABASE") or os.environ.get("DB_NAME")
    password = os.environ.get("PGPASSWORD") or os.environ.get("DB_PASS")
    if password and not os.environ.get("PGPASSWORD"):
        os.environ["PGPASSWORD"] = password

    missing = [
        name
        for name, value in (
            ("PGHOST/DB_HOST", host),
            ("PGUSER/DB_USER", user),
            ("PGDATABASE/DB_NAME", database),
            ("PGPASSWORD/DB_PASS", os.environ.get("PGPASSWORD")),
        )
        if not value
    ]
    if missing:
        raise RuntimeError("Postgres environment missing: " + ", ".join(missing))
    return ["psql", "-h", host, "-p", port, "-U", user, "-d", database]


def pg(query):
    command = _pg_command() + ["-t", "-A", "-F", "\x1f", "-R", "\x1e", "-c", query]
    r = subprocess.run(command, capture_output=True, text=True, timeout=60)
    if r.returncode != 0:
        detail = (r.stderr or "psql failed").strip().splitlines()[-1]
        raise RuntimeError(detail[:300])
    rows = []
    for line in r.stdout.strip().split("\x1e"):
        line = line.strip()
        if line:
            rows.append(line.split("\x1f"))
    return rows


def write_validation_report(validated_count, new_entries, corrections, conflicts, stats, total_filtered):
    os.makedirs(REPORT_DIR, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    json_path = os.path.join(REPORT_DIR, f"kc_validator_conflicts_{stamp}.json")
    md_path = os.path.join(REPORT_DIR, f"kc_validator_conflicts_{stamp}.md")
    payload = {
        "created_at": datetime.now(timezone.utc).isoformat(),
        "validated_count": validated_count,
        "total_filtered": total_filtered,
        "new_entries_count": len(new_entries),
        "corrections_count": len(corrections),
        "conflicts_count": len(conflicts),
        "new_entries": sorted(new_entries.keys()),
        "corrections": corrections,
        "conflicts": conflicts,
        "effect_distribution": dict(sorted(stats.items(), key=lambda item: (-item[1], item[0]))),
    }
    with open(json_path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=True, sort_keys=True, default=str)

    lines = [
        "# KC Validator Conflict Report",
        "",
        f"- created_at: {payload['created_at']}",
        f"- validated_count: {validated_count}",
        f"- total_filtered: {total_filtered}",
        f"- new_entries: {len(new_entries)}",
        f"- corrections: {len(corrections)}",
        f"- conflicts: {len(conflicts)}",
        f"- json: `{json_path}`",
        "",
        "## Corrections",
        "",
        "| Card | From | To |",
        "| --- | --- | --- |",
    ]
    if corrections:
        for item in corrections[:100]:
            lines.append(f"| {item['name']} | {item['from']} | {item['to']} |")
    else:
        lines.append("| info | none | none |")

    lines.extend(
        [
            "",
            "## Conflicts Requiring Review",
            "",
            "| Card | Current | Reclassified | Oracle sample |",
            "| --- | --- | --- | --- |",
        ]
    )
    if conflicts:
        for item in conflicts[:100]:
            oracle = " ".join(str(item.get("oracle_sample") or "").split()).replace("|", "\\|")
            lines.append(
                f"| {item['name']} | {item['current']} | {item['reclassified']} | {oracle} |"
            )
    else:
        lines.append("| info | none | none | none |")

    lines.extend(
        [
            "",
            "## Next Action",
            "",
            "- Corrections are auto-applied only when the new effect is clearly more specific.",
            "- Conflicts are not auto-applied; review them before changing classification rules.",
            "- Use this report as the review queue for Hermes knowledge hardening.",
            "",
        ]
    )
    with open(md_path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
    print(f"  Conflict report: {md_path}")
    print(f"  Conflict JSON: {json_path}")
    return md_path, json_path

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
        return {"effect": "unknown", "cmc": cmc_val}
    if "Enchantment" in tl:
        return {"effect": "draw_engine", "cmc": cmc_val}
    return {"effect": "unknown", "cmc": cmc_val}


def apply_manual_override(name, entry):
    override = MANUAL_EFFECT_OVERRIDES.get(name)
    if not override:
        return entry
    if isinstance(override, dict):
        overridden = {"cmc": entry.get("cmc", override.get("cmc", 3))}
        overridden.update(override)
    else:
        overridden = dict(entry)
        overridden["effect"] = override
    overridden["manual_override"] = True
    return overridden

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
    entry = apply_manual_override(name, entry)
    if entry["effect"] != "unknown" and entry["effect"] != "creature":
        new_entries[name] = entry

print(f"  New cards classified: {len(new_entries)}")

# ══════════════════════════════════════════
# STEP 2: VALIDATE existing classifications
# ══════════════════════════════════════════
print(f"\nSTEP 2: VALIDATING EXISTING CLASSIFICATIONS")

# Re-classify existing cards from PG oracle
check_limit = int(os.environ.get("KC_VALIDATOR_CHECK_LIMIT", "500"))
names_to_check = sorted(existing_names)
if check_limit > 0:
    names_to_check = names_to_check[:check_limit]
corrections = 0
conflicts = 0
correction_records = []
conflict_records = []

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
        new_entry = apply_manual_override(name, new_entry)
        new_effect = new_entry.get("effect", "unknown")

        if name in MANUAL_EFFECT_OVERRIDES:
            if current_effect != new_effect:
                corrected = dict(current_entry)
                corrected.update(new_entry)
                corrected["manual_override"] = True
                existing[name] = corrected
                corrections += 1
                correction_records.append(
                    {
                        "name": name,
                        "from": current_effect,
                        "to": new_effect,
                    }
                )
                if corrections <= 10:
                    print(f"  OVERRIDE: {name}: {current_effect} → {new_effect}")
            continue
        
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
                correction_records.append(
                    {
                        "name": name,
                        "from": current_effect,
                        "to": new_effect,
                    }
                )
                if corrections <= 10:
                    print(f"  CORRECTED: {name}: {current_effect} → {new_effect}")
            elif current_effect in specific_effects and new_effect == "draw_cards":
                # Going from specific to generic is a regression — keep current
                pass
            else:
                # Both specific — conflict, log it
                conflicts += 1
                conflict_records.append(
                    {
                        "name": name,
                        "current": current_effect,
                        "reclassified": new_effect,
                        "oracle_sample": oracle[:240],
                        "type_line": tl,
                        "cmc": cmc_val,
                    }
                )
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
tmp_out = f"{OUT}.tmp.{os.getpid()}"
with open(tmp_out, "w", encoding="utf-8") as f:
    json.dump(filtered, f, indent=2, sort_keys=True, default=str)
    f.write("\n")
os.replace(tmp_out, OUT)
try:
    os.chmod(OUT, 0o664)
except OSError:
    pass

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

write_validation_report(
    len(names_to_check),
    new_entries,
    correction_records,
    conflict_records,
    stats,
    len(filtered),
)

os.remove(LOCK)
print(f"\nDone.")
