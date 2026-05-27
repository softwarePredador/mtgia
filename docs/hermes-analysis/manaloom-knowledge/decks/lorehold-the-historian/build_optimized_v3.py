#!/usr/bin/env python3
"""
Lorehold, the Historian - Optimized Deck Builder v3
Builds an optimized RW Boros spellslinger deck.
Properly handles basic land quantities and deck size limits.
"""

import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), '..', '..', 'scripts', 'knowledge.db')

def get_data():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    deck = conn.execute("""
        SELECT dc.id as dc_id, dc.card_name, dc.quantity, dc.functional_tag,
               dc.cmc, dc.type_line, dc.oracle_text, dc.is_commander
        FROM deck_cards dc JOIN decks d ON d.id = dc.deck_id
        JOIN commanders c ON c.id = d.commander_id
        WHERE c.name LIKE '%Lorehold%' ORDER BY dc.cmc, dc.card_name
    """).fetchall()
    deck_tags = {}
    for dc in deck:
        tags = conn.execute("SELECT tag, confidence FROM card_tags WHERE deck_card_id = ?", (dc['dc_id'],)).fetchall()
        deck_tags[dc['card_name']] = [t['tag'] for t in tags]
    collection = conn.execute("""SELECT card_en, functional_tag, cmc, type_line, quantity, color FROM user_collection ORDER BY card_en""").fetchall()
    conn.close()
    return deck, deck_tags, collection

def normalize(name):
    s = name.lower().strip()
    for a, b in {'ó':'o','é':'e','í':'i','á':'a','ú':'u','ã':'a','õ':'o','ç':'c','ñ':'n'}.items():
        s = s.replace(a, b)
    return s

def build_lookup(collection):
    lookup = {}
    for row in collection:
        key = normalize(row['card_en'])
        if key not in lookup or len(row['card_en']) < len(lookup[key][0]):
            lookup[key] = (row['card_en'], row)
    return lookup

def find_in_collection(name, lookup):
    key = normalize(name)
    if key in lookup:
        return lookup[key]
    parts = key.split(' // ')
    if len(parts) > 1 and parts[0] in lookup:
        return lookup[parts[0]]
    for k, v in lookup.items():
        if k in key or key in k:
            if abs(len(k) - len(key)) <= 12:
                return v
    return None

def score_upgrade(row):
    name = normalize(row['card_en'])
    tag = row['functional_tag'] or ''
    cmc = row['cmc']
    tl = (row['type_line'] or '').lower()
    score = 0
    role_scores = {
        'ramp': 8, 'draw': 8, 'spellslinger': 9, 'protection': 7,
        'removal': 7, 'board_wipe': 7, 'recursion': 7, 'tutor': 6,
        'wincon': 7, 'token_maker': 5, 'exile_value': 7, 'land': 1,
        'graveyard_synergy': 5, 'big_spell': 5, 'loot': 5, 'payoff': 5,
        'engine': 6, 'unknown': 2
    }
    score += role_scores.get(tag, 2)
    if tag in ('ramp', 'draw', 'protection', 'removal') and cmc <= 2:
        score += 5
    elif tag == 'spellslinger' and cmc <= 4:
        score += 3
    if 'instant' in tl or 'sorcery' in tl:
        score += 3
        if cmc <= 2: score += 3
    top = ['birgi','storm-kiln artist','jeska','reverberate','dualcaster',
           'guttersnipe','flare of duplication','monastery mentor',
           'the one ring','esper sentinel','smothering tithe',
           'trouble in pairs','ragavan',"akroma's will",
           'flawless maneuver','chaos warp','generous gift',
           'faithless looting','arcane bombardment','farewell',
           'blasphemous act','descent into avernus',
           'sunforger','gamble','lorehold charm','strike it rich',
           'big score','spiteful banditry','chain reaction',
           'mana geyser','neheb, the eternal','radiant scrollwielder',
           'invoke calamity','inti, seneschal of the sun','demand answers']
    for t in top:
        if t in name: score += 5; break
    if cmc >= 7 and tag not in ('board_wipe', 'wincon', 'big_spell'): score -= 3
    if cmc >= 10: score -= 2
    return score

def main():
    deck, deck_tags, collection = get_data()
    lookup = build_lookup(collection)
    
    lines = []
    def p(text=""):
        lines.append(text)
        print(text)
    
    p("=" * 70)
    p("LOREHOLD, THE HISTORIAN - OPTIMIZED DECK BUILD v3")
    p("=" * 70)
    
    # Separate commander
    commander_card = None
    kept_cards = []
    missing_cards = []
    
    for dc in deck:
        tags = deck_tags.get(dc['card_name'], [])
        if dc['is_commander']:
            commander_card = dc
            continue
        result = find_in_collection(dc['card_name'], lookup)
        if result:
            kept_cards.append((dc, result[1], tags))
        else:
            missing_cards.append((dc, tags))
    
    p(f"\nCommander: {commander_card['card_name'] if commander_card else 'N/A'}")
    p(f"Original deck cards (excl commander): {len(deck)-1}")
    p(f"Cards in collection: {len(kept_cards)}")
    p(f"Cards missing: {len(missing_cards)}")
    
    # Track card count (actual card count, not unique entries)
    # Target: 99 main deck + 1 commander = 100 total
    MAIN_DECK_TARGET = 99
    LAND_TARGET = 37  # 37 lands in 99-card deck
    
    deck_entries = {}  # name -> info (each unique name is 1 entry, but basics have qty)
    actual_count = 0   # actual card count
    
    def add_card(name, tag, cmc, source, qty=1):
        nonlocal actual_count
        name_key = name
        if name_key in deck_entries:
            # Already exists (shouldn't happen for non-basics)
            return False
        deck_entries[name_key] = {
            'name': name, 'qty': qty, 'tag': tag,
            'cmc': cmc, 'source': source
        }
        actual_count += qty
        return True
    
    # 1. Commander (not part of main deck count)
    add_card('Lorehold, the Historian', 'commander', 5.0, 'commander')
    actual_count -= 1  # Commander doesn't count toward 99
    
    # 2. Basic lands (auto-include, always available)
    add_card('Mountain', 'land', 0.0, 'basic', qty=8)
    add_card('Plains', 'land', 0.0, 'basic', qty=7)
    
    # 3. Kept cards from original deck in collection
    for dc, coll_row, tags in kept_cards:
        final_name = coll_row['card_en']
        tag = dc['functional_tag'] or (tags[0] if tags else 'unknown')
        if tag == 'None' or tag is None:
            tag = tags[0] if tags else 'unknown'
        add_card(final_name, tag, dc['cmc'], 'original_in_collection')
    
    # Report current state
    deck_names_norm = set()
    for n, info in deck_entries.items():
        deck_names_norm.add(normalize(n))
    
    current_nonbasic_lands = [n for n, i in deck_entries.items() if i['tag'] == 'land' and n not in ('Mountain', 'Plains')]
    
    # 4. Add extra lands from collection to reach LAND_TARGET
    current_land_count = sum(i['qty'] for n, i in deck_entries.items() if i['tag'] == 'land')
    lands_needed = LAND_TARGET - current_land_count
    
    p(f"\nCurrent basics: 8 Mountain + 7 Plains = 15")
    p(f"Non-basic lands in collection: {len(current_nonbasic_lands)}")
    for l in current_nonbasic_lands:
        p(f"  {l}")
    p(f"Current total lands: {current_land_count}")
    p(f"Lands needed: {lands_needed}")
    
    # Get extra lands from collection
    extra_land_rows = []
    for row in collection:
        tag = row['functional_tag'] or ''
        norm = normalize(row['card_en'])
        if tag == 'land' and norm not in deck_names_norm:
            extra_land_rows.append(row)
            deck_names_norm.add(norm)
    
    # Score lands by quality
    def score_land(row):
        name = normalize(row['card_en'])
        score = 0
        # ETB untapped lands are better
        etb_untapped = ['exotic orchard', 'sacred foundry', 'inspiring vantage', 
                       'sundown pass', 'temple of triumph', 'clifftop retreat',
                       'sun-blessed peak', 'path of ancestry', 'abraded bluffs',
                       'wind-scarred crag']
        utility = ['reliquary tower', 'temple of the false god']
        for t in etb_untapped:
            if t in name: score += 3; break
        for t in utility:
            if t in name: score += 1
        # Command Tower reskin
        if 'command tower' in name or 'croft manor' in name:
            score += 5
        if 'boseiju' in name or 'isengard' in name:
            score += 3
        if 'kor haven' in name or 'osgiliath' in name:
            score += 2
        return score
    
    extra_land_rows.sort(key=lambda r: -score_land(r))
    
    lands_added = 0
    for row in extra_land_rows:
        if lands_added >= lands_needed:
            break
        add_card(row['card_en'], 'land', 0.0, 'collection_land')
        lands_added += 1
    
    p(f"Added {lands_added} lands from collection")
    
    # Recalculate
    current_land_count = sum(i['qty'] for n, i in deck_entries.items() if i['tag'] == 'land')
    current_nonland = actual_count - current_land_count
    slots_remaining = MAIN_DECK_TARGET - actual_count
    
    p(f"Lands after addition: {current_land_count}")
    p(f"Non-land cards: {current_nonland}")
    p(f"Slots remaining: {slots_remaining}")
    
    # 5. Now add non-land upgrades from collection
    other_rows = [r for r in collection if normalize(r['card_en']) not in deck_names_norm]
    scored = [(score_upgrade(r), r) for r in other_rows]
    scored.sort(key=lambda x: -x[0])
    
    # Count current roles
    def get_role_counts():
        counts = {}
        for n, info in deck_entries.items():
            t = info['tag']
            qty = info.get('qty', 1)
            if n in ('Mountain', 'Plains'):
                counts[t] = counts.get(t, 0) + qty
            else:
                counts[t] = counts.get(t, 0) + 1
        return counts
    
    roles = get_role_counts()
    
    # Role targets
    TARGETS = {
        'ramp': (12, 16), 'draw': (8, 14), 'removal': (8, 12),
        'board_wipe': (4, 6), 'protection': (4, 6), 'recursion': (3, 6),
        'spellslinger': (3, 6), 'tutor': (2, 4), 'token_maker': (2, 4),
        'wincon': (2, 4), 'exile_value': (1, 3)
    }
    
    # Calculate needs
    needs = {}
    for role, (mn, mx) in TARGETS.items():
        cur = roles.get(role, 0)
        if cur < mn:
            needs[role] = mn - cur
    
    p(f"\nRole needs: {needs}")
    
    # First pass: fill role needs
    selected = []
    used = set(deck_names_norm)
    
    for role, need in sorted(needs.items(), key=lambda x: -x[1]):
        if need <= 0: continue
        found = 0
        for score, row in scored:
            if found >= need: break
            norm = normalize(row['card_en'])
            if norm in used: continue
            tag = row['functional_tag'] or ''
            if tag == role:
                selected.append(row)
                used.add(norm)
                found += 1
    
    # Fill remaining slots
    for score, row in scored:
        if len(selected) >= slots_remaining:
            break
        norm = normalize(row['card_en'])
        if norm not in used:
            selected.append(row)
            used.add(norm)
    
    # Add selected cards
    for row in selected:
        tag = row['functional_tag'] or 'synergy'
        add_card(row['card_en'], tag, row['cmc'], 'collection_upgrade')
    
    p(f"\nAdded {len(selected)} upgrade cards")
    p(f"Actual card count: {actual_count}/{MAIN_DECK_TARGET} (main deck)")
    p(f"Total with commander: {actual_count + 1}/100")
    
    # ============= Final stats =============
    final_role_counts = get_role_counts()
    final_land_count = sum(i['qty'] for n, i in deck_entries.items() if i['tag'] == 'land')
    nonland_count = actual_count - final_land_count
    
    # Avg CMC (non-land, non-commander)
    cmc_total = 0
    cmc_count = 0
    for n, info in deck_entries.items():
        if info['tag'] in ('land', 'commander'): continue
        cmc_total += info['cmc']
        cmc_count += 1
    avg_cmc = cmc_total / max(cmc_count, 1)
    
    p("\n" + "=" * 70)
    p("FINAL DECK STATISTICS")
    p("=" * 70)
    p(f"Total cards (incl commander): {actual_count + 1}")
    p(f"Main deck: {actual_count}")
    p(f"Lands: {final_land_count}")
    p(f"Non-lands: {nonland_count}")
    p(f"Average CMC (nonland): {avg_cmc:.2f}")
    p("")
    p("Role counts:")
    for role, count in sorted(final_role_counts.items(), key=lambda x: -x[1]):
        p(f"  {role:20s}: {count}")
    
    # ============= Build markdown =============
    md = []
    md.append("# Lorehold, the Historian - Optimized Deck (2026-05-27)")
    md.append("")
    md.append("## Commander")
    md.append("1x Lorehold, the Historian (5cmc, RW)")
    md.append("")
    md.append("## Deck List (99 main deck cards)")
    md.append("")
    md.append("### Lands ({} cards)".format(final_land_count))
    md.append("")
    md.append("| # | Card | Tag | Source |")
    md.append("|---|---|---|---|")
    
    land_cards = [(n, i) for n, i in deck_entries.items() if i['tag'] == 'land']
    # Basics first, then sorted by name
    basics = [(n, i) for n, i in land_cards if n in ('Mountain', 'Plains')]
    others = sorted([(n, i) for n, i in land_cards if n not in ('Mountain', 'Plains')], key=lambda x: x[0])
    
    idx = 0
    for n, i in basics:
        idx += 1
        md.append(f"| {idx} | {n} x{i['qty']} | {i['tag']} | {i['source']} |")
    for n, i in others:
        idx += 1
        md.append(f"| {idx} | {n} | {i['tag']} | {i['source']} |")
    
    md.append("")
    md.append("### Non-lands ({} cards)".format(nonland_count))
    md.append("")
    md.append("| # | Card | CMC | Tag | Source |")
    md.append("|---|---|---|---|---|")
    
    nonland_cards = sorted(
        [(n, i) for n, i in deck_entries.items() if i['tag'] not in ('land', 'commander')],
        key=lambda x: (x[1]['cmc'], x[0])
    )
    for idx, (n, info) in enumerate(nonland_cards, 1):
        md.append(f"| {idx} | {n} | {info['cmc']} | {info['tag']} | {info['source']} |")
    
    # Metrics table
    md.append("")
    md.append("## Metrics")
    md.append(f"- **Total cards:** {actual_count + 1} ({actual_count} main + 1 commander)")
    md.append(f"- **Lands:** {final_land_count} (8 Mountain + 7 Plains + {final_land_count - 15} non-basic)")
    md.append(f"- **Ramp:** {final_role_counts.get('ramp', 0)}")
    md.append(f"- **Draw:** {final_role_counts.get('draw', 0)}")
    md.append(f"- **Removal:** {final_role_counts.get('removal', 0)}")
    md.append(f"- **Board Wipes:** {final_role_counts.get('board_wipe', 0)}")
    md.append(f"- **Protection:** {final_role_counts.get('protection', 0)}")
    md.append(f"- **Recursion:** {final_role_counts.get('recursion', 0)}")
    md.append(f"- **Spellslingers:** {final_role_counts.get('spellslinger', 0)}")
    md.append(f"- **Tutors:** {final_role_counts.get('tutor', 0)}")
    md.append(f"- **Win Conditions:** {final_role_counts.get('wincon', 0)}")
    md.append(f"- **Average CMC (nonland):** {avg_cmc:.2f}")
    md.append("")
    md.append("## Comparison with Original Deck")
    md.append("")
    md.append("| Metric | Original | Optimized | Change |")
    md.append("|---|---|---|---|")
    orig_data = {'Land': 34, 'Ramp': 17, 'Draw': 8, 'Removal': 7, 
                 'Board Wipe': 6, 'Protection': 7, 'Recursion': 5}
    for metric, orig_val in orig_data.items():
        key = metric.lower().replace(' ', '_')
        new_val = final_role_counts.get(key, 0)
        diff = new_val - orig_val
        sign = '+' if diff > 0 else ''
        md.append(f"| {metric} | {orig_val} | {new_val} | {sign}{diff} |")
    md.append(f"| Avg CMC | 3.98 | {avg_cmc:.2f} | {avg_cmc - 3.98:+.2f} |")
    
    md.append("")
    md.append("## Changes from Original Deck")
    md.append("")
    md.append("### Replaced Cards (not in collection)")
    for dc, tags in missing_cards:
        tag = dc['functional_tag'] or (tags[0] if tags else 'unknown')
        if tag == 'None': tag = tags[0] if tags else 'unknown'
        result = find_in_collection(dc['card_name'], lookup)
        if result:
            coll_name, _ = result
            md.append(f"- {dc['card_name']} -> {coll_name} (equivalent in collection)")
        elif dc['card_name'] not in ('Mountain', 'Plains'):
            md.append(f"- {dc['card_name']} ({tag}, cmc {dc['cmc']}) - replaced by collection upgrade")
    
    md.append("")
    md.append("### New Additions from Collection")
    md.append("")
    upgrade_list = [(n, i) for n, i in deck_entries.items() 
                    if i['source'] in ('collection_land', 'collection_upgrade')]
    # Sort by score
    upgrade_scored = []
    for n, info in upgrade_list:
        row_data = [r for r in collection if r['card_en'] == n]
        s = score_upgrade(row_data[0]) if row_data else 0
        upgrade_scored.append((s, n, info))
    upgrade_scored.sort(key=lambda x: -x[0])
    for s, n, info in upgrade_scored:
        md.append(f"- **{n}** ({info['tag']}, CMC {info['cmc']}) - synergy score {s}")
    
    md.append("")
    md.append("## Mulligan & Strategy Notes")
    md.append("")
    md.append("**Ideal hand:** 3-4 lands, 1 ramp spell, 1-2 cheap spells, curve under 4cmc")
    md.append("**Keep:** 3 lands + signet/top + interaction")
    md.append("**Keep:** 3 lands + Land Tax + any 2-drop")
    md.append("**Mulligan:** 0-1 lands, 6+ lands, all expensive spells, no red/white source")
    md.append("")
    md.append("**Game plan:**")
    md.append("1. T1-3: Ramp, draw, set up topdeck control (Top, Scroll Rack)")
    md.append("2. T4-5: Cast Lorehold, protect with greaves/interaction")
    md.append("3. T6+: Chain cheap spell -> big spell to copy, generate value")
    md.append("4. Win via: copied big spells, Insurrection, Storm Herd, Approach, creature beatdown")
    md.append("")
    md.append("*Deck optimized for Lorehold, the Historian spellslinger strategy*")
    
    result = '\n'.join(md)
    
    # Save
    out_path = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-05-27-optimized.md'
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'w') as f:
        f.write(result)
    p(f"\nSaved to: {out_path}")
    
    return result

if __name__ == '__main__':
    main()