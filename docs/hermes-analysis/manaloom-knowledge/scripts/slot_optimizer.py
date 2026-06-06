#!/usr/bin/env python3
"""
Lorehold Deck Optimizer v3 — Category-based, isolated testing.
Phase 1: Best-in-Slot (which card is best for each slot)
Phase 2: Structure Tuning (optimal distribution between categories)
Phase 3: Synergy Check (card combinations)

CRITICAL RULES:
- NEVER modify the deck permanently during testing
- Each test: swap -> Battle -> restore (always!)
- Baseline stays fixed throughout
- Only apply changes manually after all testing is done
"""
import sqlite3, subprocess, os, json, re, time, sys, random
from collections import defaultdict

DB = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'
BATTLE = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py'
KC_JSON = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_generated.json'
LOCK_FILE = '/tmp/optimizer_v3.lock'

GAMES_QUICK = 25   # Phase 1: per-candidate tests
GAMES_FULL = 50    # Phase 2 & 3: confirmation tests

# ── Lock ──
if os.path.exists(LOCK_FILE):
    age = time.time() - os.path.getmtime(LOCK_FILE)
    if age < 43200:
        print(f"LOCKED ({age:.0f}s ago). Exiting.")
        sys.exit(0)
    os.remove(LOCK_FILE)
open(LOCK_FILE, 'w').close()

try:
    conn = sqlite3.connect(DB)
    
    # ── Load deck ──
    deck = conn.execute("SELECT card_name, quantity, cmc, functional_tag, type_line, is_commander FROM deck_cards WHERE deck_id=6 AND is_commander=0").fetchall()
    cmdr = conn.execute("SELECT card_name, quantity, cmc, functional_tag, type_line, is_commander FROM deck_cards WHERE deck_id=6 AND is_commander=1").fetchone()
    deck_names = set(c[0] for c in deck)
    
    # ── Load KNOWN_CARDS ──
    with open(KC_JSON) as f:
        kc = json.load(f)
    
    # ── Load all Lorehold candidates ──
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
    
    basics = {'Plains','Mountain','Island','Swamp','Forest','Wastes'}
    
    # ── EFFECT → CATEGORY MAPPING ──
    EFFECT_TO_CATEGORY = {
        # Ramp
        'ramp_permanent': 'ramp', 'ramp_ritual': 'ramp', 'ramp_engine': 'ramp',
        # Protection
        'silence_opponents': 'protection', 'indestructible': 'protection',
        'phase_out': 'protection', 'counter': 'protection',
        # Draw
        'draw_cards': 'draw', 'draw_engine': 'draw', 'topdeck_manipulation': 'draw',
        # Tutor
        'tutor': 'tutor',
        # Wincon
        'finisher': 'wincon', 'approach': 'wincon', 'token_maker': 'wincon',
        'overload_recursion': 'wincon', 'steal_all_creatures': 'wincon',
        'pump_all': 'wincon', 'extra_turn': 'wincon',
        # Board Wipe
        'board_wipe': 'wipe',
        # Removal
        'remove_creature': 'removal', 'remove_permanent': 'removal',
        'remove_artifact_or_3dmg': 'removal',
        # Engine
        'copy_spell': 'engine', 'recursion': 'engine',
        'ripple_engine': 'engine',
        # Combo
        'dragons_approach': 'combo',
        # Land
        'land': 'land',
        # Stax
    }
    
    # ── CATEGORIZE CURRENT DECK ──
    print("=" * 60)
    print("CURRENT DECK COMPOSITION")
    deck_categories = defaultdict(list)
    for c in deck:
        name, qty, cmc, tag, tl, is_cmd = c
        cmc = float(cmc or 0)
        # Determine category from KNOWN_CARDS
        cat = 'unknown'
        if name in kc:
            eff = kc[name].get('effect', 'unknown')
            cat = EFFECT_TO_CATEGORY.get(eff, 'unknown')
        if 'Land' in (tl or ''):
            cat = 'land'
        if cat == 'unknown':
            # Fallback by tag
            tag_map = {'ramp': 'ramp', 'draw': 'draw', 'tutor': 'tutor', 'removal': 'removal',
                       'board_wipe': 'wipe', 'wincon': 'wincon', 'combo': 'combo',
                       'protection': 'protection', 'stax': 'stax', 'engine': 'engine'}
            cat = tag_map.get(tag, 'unknown')
        deck_categories[cat].append((name, cmc))
    
    for cat, cards in sorted(deck_categories.items()):
        names = [n for n, _ in cards]
        count = len(cards)
        avg_cmc = sum(c for _, c in cards) / count if count else 0
        print(f"  {cat:<15s} x{count:<3d} avg CMC={avg_cmc:.1f}  {', '.join(names[:4])}{'...' if len(names) > 4 else ''}")
    
    # ── FIND CANDIDATES PER CATEGORY ──
    print(f"\n{'='*60}")
    print("PHASE 1: BEST-IN-SLOT (25 games/candidate, ISOLATED)")
    
    # Get all candidates with KNOWN_CARDS, not in deck
    candidates_by_cat = defaultdict(list)
    for name in sorted(all_lorehold):
        if name in deck_names or name in basics or name not in kc:
            continue
        entry = kc[name]
        eff = entry.get('effect', 'unknown')
        cat = EFFECT_TO_CATEGORY.get(eff, 'unknown')
        if cat == 'unknown':
            continue
        cmc = entry.get('cmc', 3)
        # Filter unplayable: CMC > 8, or land-like but too slow
        if cmc > 8 and cat not in ('wincon',):
            continue
        candidates_by_cat[cat].append((name, cmc, entry))
    
    for cat, cands in sorted(candidates_by_cat.items()):
        if cat == 'land':
            continue  # skip lands for Phase 1
        print(f"  {cat:<15s} {len(cands)} candidates (deck has {len(deck_categories[cat])})")
    
    total_cands = sum(len(c) for cat, c in candidates_by_cat.items() if cat != 'land')
    print(f"\n  TOTAL: {total_cands} candidates to test (~{total_cands * 1.5:.0f} min)")
    
    # ── PICK SWAP TARGETS ──
    # For each category, pick the card to swap out (highest CMC non-critical)
    swap_targets = {}
    for cat, cards in deck_categories.items():
        if not cards:
            swap_targets[cat] = None
            continue
        # Never cut these
        protected = {'Spiteful Banditry', 'Increasing Vengeance', 'Approach of the Second Sun',
                     'Teferi\'s Protection', 'Grand Abolisher', 'Silence'}
        cuttable = [(n, c) for n, c in cards if n not in protected]
        if not cuttable:
            cuttable = list(cards)
        # Pick highest CMC
        cuttable.sort(key=lambda x: -x[1])
        swap_targets[cat] = cuttable[0][0]
    
    print(f"\n  Swap targets per category:")
    for cat, target in sorted(swap_targets.items()):
        if target:
            print(f"    {cat:<15s} -> cut '{target}'")
    
    # ── RUN PHASE 1 TESTS ──
    # Patch Battle
    battle_orig = open(BATTLE).read()
    battle_patched = battle_orig.replace("GAMES = 50", f"GAMES = {GAMES_QUICK}")
    with open(BATTLE, 'w') as f:
        f.write(battle_patched)
    
    # Create results table
    conn.execute("""
        CREATE TABLE IF NOT EXISTS slot_benchmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            card_added TEXT NOT NULL,
            card_removed TEXT NOT NULL,
            add_cmc REAL, add_effect TEXT,
            wr REAL, wins INTEGER, losses INTEGER, draws INTEGER,
            games INTEGER, delta_pp REAL,
            phase TEXT,
            tested_at TEXT DEFAULT (datetime('now'))
        )
    """)
    conn.commit()
    
    # Skip already tested
    already_tested = set()
    for row in conn.execute("SELECT card_added, card_removed FROM slot_benchmarks WHERE phase='best-in-slot'"):
        already_tested.add((row[0], row[1]))
    
    os.chdir(os.path.dirname(BATTLE))
    tested = applied = 0
    
    for cat, candidates in sorted(candidates_by_cat.items()):
        if cat == 'land':
            continue
        if cat not in swap_targets or not swap_targets[cat]:
            print(f"\n  [{cat}] SKIP — no swap target")
            continue
        
        remove_card = swap_targets[cat]
        untested = [(n, c, e) for n, c, e in candidates if (n, remove_card) not in already_tested]
        
        if not untested:
            print(f"\n  [{cat}] All {len(candidates)} already tested. Showing top 3:")
            for row in conn.execute("SELECT card_added, wr, delta_pp FROM slot_benchmarks WHERE category=? AND phase='best-in-slot' ORDER BY wr DESC LIMIT 3", (cat,)):
                print(f"    +{row[0]:<35s} WR={row[1]:.1f}% {row[2]:+.1f}pp")
            continue
        
        print(f"\n  [{cat}] {len(untested)} remaining of {len(candidates)} candidates (target: cut {remove_card})")
        
        for name, cmc, entry in untested:
            add_effect = entry.get('effect', 'unknown')
            
            # Apply swap
            conn.execute("DELETE FROM deck_cards WHERE deck_id=6 AND card_name=?", (remove_card,))
            conn.execute("INSERT OR REPLACE INTO deck_cards (deck_id,card_name,quantity,cmc,functional_tag,type_line,is_commander) VALUES (6,?,1,?,?,?,0)",
                (name, cmc, add_effect, 'Spell'))
            conn.commit()
            
            # Run Battle
            r = subprocess.run(["python3", BATTLE], capture_output=True, text=True, timeout=180)
            
            # Parse result
            wr = wins = losses = draws = 0
            for line in r.stdout.split("\n"):
                if "OVERALL" in line:
                    mw = re.search(r'WR=([\d.]+)%', line)
                    mc = re.search(r'(\d+)W/(\d+)L/(\d+)S', line)
                    if mw: wr = float(mw.group(1))
                    if mc: wins, losses, draws = int(mc.group(1)), int(mc.group(2)), int(mc.group(3))
                    break
            
            delta = wr - 81.8  # fixed baseline
            total_g = GAMES_QUICK * 12
            
            # Save
            conn.execute("""INSERT INTO slot_benchmarks (category, card_added, card_removed, add_cmc, add_effect, wr, wins, losses, draws, games, delta_pp, phase)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?)""",
                (cat, name, remove_card, cmc, add_effect, wr, wins, losses, draws, total_g, delta, 'best-in-slot'))
            conn.commit()
            
            sym = "UP" if delta > 1 else "DOWN" if delta < -1 else "-"
            print(f"    +{name:<35s} WR={wr:.1f}% {sym} {delta:+.1f}pp", end="")
            if delta > 0.5:
                print(" ★", end="")
            print()
            
            # RESTORE — always!
            conn.execute("DELETE FROM deck_cards WHERE deck_id=6 AND card_name=?", (name,))
            # Re-insert removed card from original deck data
            restore = [(n, q, c, t, tl, ic) for n, q, c, t, tl, ic in deck + [cmdr] if n == remove_card]
            if restore:
                rn, rq, rc, rt, rtl, ric = restore[0]
                conn.execute("INSERT OR REPLACE INTO deck_cards (deck_id,card_name,quantity,cmc,functional_tag,type_line,is_commander) VALUES (6,?,?,?,?,?,?)",
                    (rn, rq, rc, rt, rtl, ric))
            conn.commit()
            
            tested += 1
    
    # ── Restore Battle ──
    with open(BATTLE, 'w') as f:
        f.write(battle_orig)
    
    # ── PHASE 1 SUMMARY ──
    print(f"\n{'='*60}")
    print("PHASE 1 SUMMARY: Top candidate per category")
    
    phase1_results = {}
    for cat in sorted(candidates_by_cat.keys()):
        if cat == 'land':
            continue
        rows = conn.execute("SELECT card_added, card_removed, wr, delta_pp FROM slot_benchmarks WHERE category=? AND phase='best-in-slot' ORDER BY wr DESC LIMIT 5", (cat,)).fetchall()
        if rows:
            phase1_results[cat] = rows
            print(f"\n  [{cat}] (deck has {len(deck_categories[cat])} cards)")
            for i, row in enumerate(rows):
                marker = " ← BEST" if i == 0 else ""
                print(f"    {i+1}. +{row[0]:<35s} (cut {row[1]:<20s}) WR={row[2]:.1f}%  {row[3]:+.1f}pp{marker}")
    
    conn.close()

finally:
    # SAFE restore: read FIRST, then write
    with open(BATTLE, 'r') as f:
        current = f.read()
    restored = current.replace(f"GAMES = {GAMES_QUICK}", "GAMES = 50")
    if restored != current:
        with open(BATTLE, 'w') as f:
            f.write(restored)
    if os.path.exists(LOCK_FILE):
        os.remove(LOCK_FILE)
    print(f"\nDone. Results in slot_benchmarks table.")
