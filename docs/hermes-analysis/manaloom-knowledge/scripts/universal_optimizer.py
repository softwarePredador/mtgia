#!/usr/bin/env python3
"""
Universal Card Optimizer v2 — Two-phase batch tester.
Phase 1 (QUICK): 10 games/archetype → all candidates → ~3h
Phase 2 (FULL):  25 games/archetype → promising candidates (WR >= baseline - 2pp)
Auto-applies winning swaps. Cron-safe: skip already-tested, lock file prevents concurrency.
"""
import json
import os
import re
import sqlite3
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import battle_rule_registry
from known_cards_fallback_snapshot import load_layered_known_cards
from master_optimizer_common import battle_gate_cli_lines

DB = os.environ.get('MANALOOM_KNOWLEDGE_DB', '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db')
BATTLE = os.environ.get('MANALOOM_BATTLE_SCRIPT', '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py')
LOCK_FILE = '/tmp/optimizer.lock'

GAMES_QUICK = 10
GAMES_FULL = 25
BASELINE_WR = 81.8

REAL_CATEGORY_PRIORITY = [
    "wincon",
    "protection",
    "removal",
    "wipe",
    "ramp",
    "draw",
    "tutor",
    "engine",
    "land",
]


def print_legacy_battle_gate_banner() -> None:
    print("universal_optimizer_status=legacy_deprecated_not_authorized_for_handoff")
    print("universal_optimizer_auto_apply_warning=use_master_optimizer_apply_pipeline_instead")
    for line in battle_gate_cli_lines():
        print(line)


def choose_primary_category(categories: list[str]) -> str | None:
    present = set(categories)
    for category in REAL_CATEGORY_PRIORITY:
        if category in present:
            return category
    return categories[0] if categories else None


def load_known_cards(db_path: str) -> dict[str, dict[str, object]]:
    known_cards, _canonical_names, _generated_only_names = load_layered_known_cards()

    rule_lists = battle_rule_registry.load_active_battle_card_rule_lists(db_path)
    for rules in rule_lists.values():
        if not rules:
            continue
        rule = rules[0]
        name = str(rule.get("card_name") or "")
        effect = dict(rule.get("effect_json") or {})
        if not name or not effect:
            continue
        categories = [
            str(role.get("category"))
            for role in (dict(item.get("deck_role_json") or {}) for item in rules)
            if role.get("category")
        ]
        merged = dict(known_cards.get(name, {}))
        merged.update(effect)
        primary_category = choose_primary_category(categories)
        if primary_category:
            merged["deck_category"] = primary_category
        merged["battle_rules"] = [dict(item.get("effect_json") or {}) for item in rules]
        merged["battle_rule_categories"] = sorted(set(categories))
        merged["battle_rule_source"] = rule.get("source")
        merged["battle_rule_review_status"] = rule.get("review_status")
        merged["battle_rule_execution_status"] = rule.get("execution_status")
        known_cards[name] = merged
    return known_cards

# ── Concurrency lock ──
print_legacy_battle_gate_banner()
if os.path.exists(LOCK_FILE):
    age = time.time() - os.path.getmtime(LOCK_FILE)
    if age < 36000:  # 10h max runtime
        print(f"LOCKED: another optimizer running ({age:.0f}s ago). Exiting.")
        sys.exit(0)
    else:
        os.remove(LOCK_FILE)
        print("Stale lock removed.")
open(LOCK_FILE, 'w').close()

try:
    conn = sqlite3.connect(DB)
    
    conn.execute("""
        CREATE TABLE IF NOT EXISTS swap_benchmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            card_added TEXT NOT NULL,
            card_removed TEXT NOT NULL,
            add_cmc REAL, add_effect TEXT, add_tag TEXT,
            wr REAL, wins INTEGER, losses INTEGER, draws INTEGER,
            games INTEGER DEFAULT 300, phase TEXT DEFAULT 'quick',
            delta_pp REAL, applied INTEGER DEFAULT 0,
            tested_at TEXT DEFAULT (datetime('now'))
        )
    """)
    conn.commit()
    
    # Load deck
    current = conn.execute("SELECT card_name, quantity, cmc, functional_tag, type_line, is_commander FROM deck_cards WHERE deck_id=6").fetchall()
    current_names = set(c[0] for c in current)
    
    # Load known cards from canonical snapshot with SQLite battle rules overlay.
    kc = load_known_cards(DB)
    
    # Load candidates
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
    candidates = []
    for name in sorted(all_lorehold):
        if name in current_names or name in basics or name not in kc:
            continue
        entry = kc[name]
        if entry.get("effect") in ("creature", "unknown"):
            continue
        candidates.append((name, entry))
    
    # ── Phase determination ──
    tested_quick = conn.execute("SELECT card_added FROM swap_benchmarks WHERE phase='quick'").fetchall()
    tested_quick_names = set(r[0] for r in tested_quick)
    
    quick_candidates = [(n, e) for n, e in candidates if n not in tested_quick_names]
    
    # Phase 2 candidates: tested in quick with WR >= baseline - 2pp, not yet full-tested
    full_already = set(r[0] for r in conn.execute("SELECT card_added FROM swap_benchmarks WHERE phase='full'"))
    promising = []
    for row in conn.execute("SELECT card_added, wr FROM swap_benchmarks WHERE phase='quick' AND wr >= ?", (BASELINE_WR - 2.0,)):
        if row[0] not in full_already:
            promising.append((row[0], row[1]))
    promising.sort(key=lambda x: -x[1])
    
    print(f"Total candidates: {len(candidates)}")
    print(f"Quick-tested: {len(tested_quick_names)}, Remaining: {len(quick_candidates)}")
    print(f"Promising for full test: {len(promising)}")
    
    if quick_candidates:
        phase = "quick"
        test_list = quick_candidates
        games = GAMES_QUICK
        print(f"\n>>> PHASE 1 (QUICK): {len(test_list)} cards, {games} games/archetype (~{len(test_list)*0.7:.0f} min)")
    elif promising:
        phase = "full"
        # Need to re-fetch entry data for promising cards
        test_list = []
        for name, quick_wr in promising:
            if name in kc:
                test_list.append((name, kc[name]))
        games = GAMES_FULL
        print(f"\n>>> PHASE 2 (FULL): {len(test_list)} cards, {games} games/archetype (~{len(test_list)*1.5:.0f} min)")
    else:
        print("\nAll candidates fully tested! Top results:")
        for row in conn.execute("SELECT card_added, card_removed, wr, delta_pp, phase FROM swap_benchmarks WHERE phase='full' ORDER BY delta_pp DESC LIMIT 15"):
            print(f"  +{row[0]:<35s} (cut {row[1]:<25s}) WR={row[2]:.1f}%  {row[3]:+.1f}pp [{row[4]}]")
        conn.close()
        os.remove(LOCK_FILE)
        sys.exit(0)
    
    # ── Smart cut target ──
    def find_cut_target(add_cmc):
        nonessential = []
        prot_count = sum(1 for c in current if c[3] == 'protection')
        for c in current:
            name, qty, cmc, tag, tl, is_cmd = c
            if is_cmd or 'Land' in (tl or ''):
                continue
            cmc_val = float(cmc or 0)
            tag = tag or 'unknown'
            if tag in ('wincon', 'board_wipe', 'combo', 'stax'):
                continue
            if tag == 'protection' and prot_count <= 10:
                continue
            nonessential.append((name, cmc_val, tag))
        
        if not nonessential:
            return current[1][0]
        
        high_cmc = [(n, c, t) for n, c, t in nonessential if c >= add_cmc]
        target_list = high_cmc if high_cmc else nonessential
        
        priority = ['unknown', 'draw', 'ramp', 'removal', 'tutor', 'engine', 'spellslinger', 'protection']
        for tag in priority:
            matches = [(n, c) for n, c, t in target_list if t == tag]
            if matches:
                matches.sort(key=lambda x: -x[1])  # highest CMC first
                return matches[0][0]
        target_list.sort(key=lambda x: -x[1])
        return target_list[0][0]
    
    # ── Patch Battle ──
    battle_content = open(BATTLE).read()
    battle_backup = battle_content
    battle_content = battle_content.replace("GAMES = 50", f"GAMES = {games}")
    battle_content = battle_content.replace("50 games vs each", f"{games} games vs each")
    with open(BATTLE, 'w') as f:
        f.write(battle_content)
    
    # ── Run tests ──
    os.chdir(os.path.dirname(BATTLE))
    tested = applied = 0
    baseline_backup = list(current)
    
    for name, entry in test_list:
        add_cmc = entry.get("cmc", 3)
        add_effect = entry.get("effect", "unknown")
        remove_card = find_cut_target(add_cmc)
        
        pct = (tested + 1) / len(test_list) * 100
        print(f"[{tested+1}/{len(test_list)} {pct:.0f}%] +{name} (CMC={add_cmc:.0f}) cut {remove_card}...", end=" ", flush=True)
        
        # Apply swap
        conn.execute("DELETE FROM deck_cards WHERE deck_id=6 AND card_name=?", (remove_card,))
        conn.execute("INSERT OR REPLACE INTO deck_cards (deck_id,card_name,quantity,cmc,functional_tag,type_line,is_commander) VALUES (6,?,1,?,?,?,0)",
            (name, add_cmc, add_effect, 'Spell'))
        conn.commit()
        
        # Run Battle
        r = subprocess.run(["python3", BATTLE], capture_output=True, text=True, timeout=180)
        
        # Parse
        wr = wins = losses = draws = 0
        for line in r.stdout.split("\n"):
            if "OVERALL" in line:
                mw = re.search(r'WR=([\d.]+)%', line)
                mc = re.search(r'(\d+)W/(\d+)L/(\d+)S', line)
                if mw: wr = float(mw.group(1))
                if mc: wins, losses, draws = int(mc.group(1)), int(mc.group(2)), int(mc.group(3))
                break
        
        delta = wr - BASELINE_WR
        total = games * 12
        
        conn.execute("""INSERT INTO swap_benchmarks (card_added, card_removed, add_cmc, add_effect, add_tag, wr, wins, losses, draws, games, phase, delta_pp)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?)""",
            (name, remove_card, add_cmc, add_effect, add_effect, wr, wins, losses, draws, total, phase, delta))
        conn.commit()
        
        sym = "UP" if delta > 0.5 else "DOWN" if delta < -0.5 else "-"
        print(f"WR={wr:.1f}% {sym} {delta:+.1f}pp")
        
        if phase == "full" and delta >= 0.5:
            print(f"  >>> APPLYING: +{name} = {wr:.1f}% (+{delta:.1f}pp)")
            conn.execute("UPDATE swap_benchmarks SET applied=1 WHERE card_added=? AND card_removed=?", (name, remove_card))
            BASELINE_WR = wr
            current = conn.execute("SELECT card_name, quantity, cmc, functional_tag, type_line, is_commander FROM deck_cards WHERE deck_id=6").fetchall()
            current_names = set(c[0] for c in current)
            applied += 1
        else:
            # Restore
            conn.execute("DELETE FROM deck_cards WHERE deck_id=6 AND card_name=?", (name,))
            restore_row = [c for c in baseline_backup if c[0] == remove_card]
            if restore_row:
                c = restore_row[0]
                conn.execute("INSERT OR REPLACE INTO deck_cards (deck_id,card_name,quantity,cmc,functional_tag,type_line,is_commander) VALUES (6,?,?,?,?,?,?)",
                    (c[0], c[1], c[2], c[3], c[4], c[5]))
            conn.commit()
        
        tested += 1
    
    # ── Restore Battle ──
    with open(BATTLE, 'w') as f:
        f.write(battle_backup)
    
    print(f"\n{'='*60}")
    print(f"PHASE: {phase} | Tested: {tested} | Applied: {applied}")
    print(f"Baseline WR now: {BASELINE_WR:.1f}%")
    
    # Top results
    print(f"\nTop 15 full-test results:")
    for row in conn.execute("SELECT card_added, card_removed, wr, delta_pp, phase FROM swap_benchmarks WHERE phase='full' AND wr > 0 ORDER BY delta_pp DESC LIMIT 15"):
        print(f"  +{row[0]:<35s} (cut {row[1]:<25s}) WR={row[2]:.1f}%  {row[3]:+.1f}pp [{row[4]}]")
    
    conn.close()
finally:
    if os.path.exists(LOCK_FILE):
        os.remove(LOCK_FILE)
