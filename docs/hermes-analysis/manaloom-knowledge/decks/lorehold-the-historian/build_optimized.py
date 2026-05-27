#!/usr/bin/env python3
"""
Lorehold, the Historian - Optimized Deck Builder v2
Builds an optimized RW Boros spellslinger deck.
Handles basics, lands properly, and does smart role-based selection.
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
        FROM deck_cards dc
        JOIN decks d ON d.id = dc.deck_id
        JOIN commanders c ON c.id = d.commander_id
        WHERE c.name LIKE '%Lorehold%'
        ORDER BY dc.cmc, dc.card_name
    """).fetchall()
    
    deck_cards_tags = {}
    for dc in deck:
        tags = conn.execute("""
            SELECT tag, confidence FROM card_tags WHERE deck_card_id = ?
        """, (dc['dc_id'],)).fetchall()
        deck_cards_tags[dc['card_name']] = [t['tag'] for t in tags]
    
    collection = conn.execute("""
        SELECT card_en, functional_tag, cmc, type_line, quantity, color
        FROM user_collection
        ORDER BY card_en
    """).fetchall()
    
    conn.close()
    return deck, deck_cards_tags, collection

def normalize(name):
    s = name.lower().strip()
    replacements = {'ó': 'o', 'é': 'e', 'í': 'i', 'á': 'a', 'ú': 'u',
                    'ã': 'a', 'õ': 'o', 'ç': 'c', 'ñ': 'n'}
    for a, b in replacements.items():
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
    # Handle MDFC double-faced cards
    key_parts = key.split(' // ')
    if len(key_parts) > 1:
        if key_parts[0] in lookup:
            return lookup[key_parts[0]]
    # Handle partial matches for reskins
    for k, v in lookup.items():
        if k in key or key in k:
            if abs(len(k) - len(key)) <= 10:
                return v
    return None

def score_upgrade(row):
    """Score collection card as upgrade for Lorehold"""
    name = normalize(row['card_en'])
    tag = row['functional_tag'] or ''
    cmc = row['cmc']
    tl = (row['type_line'] or '').lower()
    
    score = 0
    
    # Role scores
    role_scores = {
        'ramp': 8, 'draw': 8, 'spellslinger': 9, 'protection': 7,
        'removal': 7, 'board_wipe': 7, 'recursion': 7, 'tutor': 6,
        'wincon': 6, 'token_maker': 5, 'exile_value': 7, 'land': 2,
        'graveyard_synergy': 5, 'big_spell': 5, 'loot': 5, 'payoff': 5,
        'engine': 6
    }
    score += role_scores.get(tag, 1)
    
    # CMC efficiency for enablers
    if tag in ('ramp', 'draw', 'protection', 'removal'):
        if cmc <= 2: score += 5
        elif cmc <= 3: score += 3
    elif tag == 'spellslinger' and cmc <= 4:
        score += 3
    
    # Instant/sorcery synergy with Lorehold
    if 'instant' in tl or 'sorcery' in tl:
        score += 3
        if cmc <= 2: score += 3
    
    # Specific premium cards for Lorehold
    top_names = [
        'birgi', 'storm-kiln artist', 'jeska', 'reverberate', 'dualcaster',
        'guttersnipe', 'flare of duplication', 'monastery mentor',
        'the one ring', 'esper sentinel', 'smothering tithe',
        'trouble in pairs', 'ragavan', "akroma's will",
        'flawless maneuver', 'chaos warp', 'generous gift',
        'faithless looting', 'arcane bombardment', 'farewell',
        'blasphemous act', 'descent into avernus',
        'sunforger', 'gamble', 'lorehold charm', 'strike it rich',
        'big score', 'spiteful banditry', 'chain reaction',
        'mana geyser', 'neheb, the eternal', 'radiant scrollwielder',
        'invoke calamity', 'inti, seneschal of the sun'
    ]
    for t in top_names:
        if t in name:
            score += 5
            break
    
    # Penalty for very high CMC without payoff
    if cmc >= 7 and tag not in ('board_wipe', 'wincon', 'big_spell'):
        score -= 3
    if cmc >= 10:
        score -= 2
    
    return score

def main():
    deck, deck_tags, collection = get_data()
    lookup = build_lookup(collection)
    
    lines = []
    def p(text=""):
        lines.append(text)
        print(text)
    
    p("=" * 70)
    p("LOREHOLD, THE HISTORIAN - OPTIMIZED DECK BUILD v2")
    p("=" * 70)
    
    # Separate commander from rest
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
    
    p(f"\nCommander: {commander_card['card_name']}")
    print(f"Original deck cards (excl. commander): {len(deck)-1}")
    print(f"Cards in collection: {len(kept_cards)}")
    print(f"Cards missing: {len(missing_cards)}")
    
    # Build deck (start with commander)
    deck_cards = {}
    
    # 1. Commander
    deck_cards['Lorehold, the Historian'] = {
        'name': 'Lorehold, the Historian', 'qty': 1,
        'tag': 'commander', 'cmc': 5.0, 'source': 'commander'
    }
    
    # 2. Kept cards from original deck in collection
    for dc, coll_row, tags in kept_cards:
        final_name = coll_row['card_en']
        tag = dc['functional_tag'] or (tags[0] if tags else 'unknown')
        if tag == 'None' or tag is None:
            tag = tags[0] if tags else 'unknown'
        deck_cards[final_name] = {
            'name': final_name, 'qty': 1, 'tag': tag,
            'cmc': dc['cmc'],
            'source': 'original_deck_in_collection'
        }
    
    # 3. Auto-add basic lands (always available)
    # Original had 8 Mountain + 7 Plains = 15 basics
    # We need about 36-38 lands total. Let's count existing non-basic lands.
    existing_lands = [n for n, i in deck_cards.items() if i['tag'] == 'land']
    print(f"\nExisting non-basic lands in collection: {len(existing_lands)}")
    for l in existing_lands:
        print(f"  {l}")
    
    # Add basics to reach ~37 lands
    BASIC_MOUNTAINS = 8
    BASIC_PLAINS = 7
    deck_cards['Mountain'] = {'name': 'Mountain', 'qty': 8, 'tag': 'land', 'cmc': 0.0, 'source': 'basic'}
    deck_cards['Plains'] = {'name': 'Plains', 'qty': 7, 'tag': 'land', 'cmc': 0.0, 'source': 'basic'}
    
    # Get extra lands from collection to fill gaps
    deck_names_norm = set()
    for n in deck_cards:
        if deck_cards[n].get('qty', 1) == 1:
            deck_names_norm.add(normalize(n))
        # For basic lands with qty > 1, only add once to norm set
        base = normalize(n)
        if base not in deck_names_norm:
            deck_names_norm.add(base)
    
    # Find extra lands in collection NOT already in deck
    extra_lands = []
    for row in collection:
        norm = normalize(row['card_en'])
        tag = row['functional_tag'] or ''
        if tag == 'land' and norm not in deck_names_norm:
            extra_lands.append(row)
            deck_names_norm.add(norm)
    
    # Find other upgrades
    other_upgrades = [r for r in collection if normalize(r['card_en']) not in deck_names_norm]
    scored = [(score_upgrade(r), r) for r in other_upgrades]
    scored.sort(key=lambda x: -x[0])
    
    # Add extra lands first (up to 37 total lands)
    total_expected_lands = 37
    current_lands = len(existing_lands) + 15  # existing non-basics + basics (8+7)
    lands_to_add = total_expected_lands - current_lands
    
    print(f"\nCurrent land count: {current_lands} ({len(existing_lands)} non-basic + 15 basics)")
    print(f"Lands to add from collection: {lands_to_add}")
    
    added_lands = []
    for row in extra_lands[:lands_to_add]:
        deck_cards[row['card_en']] = {
            'name': row['card_en'], 'qty': 1, 'tag': 'land',
            'cmc': 0.0, 'source': 'collection_land'
        }
        deck_names_norm.add(normalize(row['card_en']))
        added_lands.append(row['card_en'])
    
    print(f"Added lands: {added_lands}")
    
    # Now fill the rest to reach 99 cards
    remaining = 99 - len(deck_cards)
    print(f"\nRemaining slots after lands: {remaining}")
    
    # Count current roles
    def count_roles():
        roles = {}
        for n, info in deck_cards.items():
            t = info['tag']
            qty = info.get('qty', 1)
            roles[t] = roles.get(t, 0) + qty
        return roles
    
    roles = count_roles()
    
    # Check role needs (removing basics from land count)
    land_count = sum(info.get('qty', 1) for n, info in deck_cards.items() if info['tag'] == 'land')
    print(f"Land count: {land_count}")
    print(f"Total deck so far: {len(deck_cards)}")
    
    # Target ranges
    TARGETS = {
        'ramp': (12, 16), 'draw': (8, 14), 'removal': (8, 12),
        'board_wipe': (4, 6), 'protection': (4, 6), 'recursion': (3, 6),
        'spellslinger': (3, 6), 'tutor': (2, 4), 'token_maker': (2, 4),
        'wincon': (2, 4), 'exile_value': (2, 4), 'graveyard_synergy': (2, 3),
        'big_spell': (1, 3), 'loot': (1, 2), 'payoff': (2, 4), 'engine': (2, 4)
    }
    
    # First pass: fill role needs
    role_needs = {}
    for role, (mn, mx) in TARGETS.items():
        cur = roles.get(role, 0)
        if cur < mn:
            role_needs[role] = mn - cur
    
    print(f"\nRole needs: {role_needs}")
    
    selected = []
    used_names = set(normalize(n) for n in deck_cards)
    
    # Fill role needs
    for role, need in sorted(role_needs.items(), key=lambda x: -x[1]):
        if need <= 0:
            continue
        found = 0
        for score, row in scored:
            if found >= need:
                break
            norm = normalize(row['card_en'])
            if norm in used_names:
                continue
            tag = row['functional_tag'] or ''
            if tag == role:
                selected.append(row)
                used_names.add(norm)
                found += 1
    
    # Fill remaining slots with best cards
    for score, row in scored:
        if len(deck_cards) + len(selected) >= 99:
            break
        norm = normalize(row['card_en'])
        if norm not in used_names:
            selected.append(row)
            used_names.add(norm)
    
    # Add selected cards to deck
    added_upgrades = []
    for row in selected:
        tag = row['functional_tag'] or 'synergy'
        deck_cards[row['card_en']] = {
            'name': row['card_en'], 'qty': 1, 'tag': tag,
            'cmc': row['cmc'],
            'source': 'collection_upgrade'
        }
        added_upgrades.append(row['card_en'])
    
    # If under 99, add more from scored list
    if len(deck_cards) < 99:
        for score, row in scored:
            if len(deck_cards) >= 99:
                break
            norm = normalize(row['card_en'])
            if norm not in used_names:
                tag = row['functional_tag'] or 'synergy'
                deck_cards[row['card_en']] = {
                    'name': row['card_en'], 'qty': 1, 'tag': tag,
                    'cmc': row['cmc'],
                    'source': 'collection_upgrade'
                }
                used_names.add(norm)
    
    print(f"\nAdded {len(selected)} upgrades")
    print(f"Final main deck: {len(deck_cards) - 1} (should be 99)")
    
    # Final counts
    final_roles = count_roles()
    final_land_count = final_roles.get('land', 0)
    total = len(deck_cards)
    
    # Update tag for basics
    if 'Mountain' in deck_cards:
        final_land_count += 7  # Plains already counted
    
    # Calculate avg CMC (non-land, non-commander)
    cmc_sum = 0
    nonland_count = 0
    for n, info in deck_cards.items():
        if info['tag'] in ('land', 'commander'):
            continue
        if n in ('Mountain', 'Plains'):
            # These are lands, skip the cmc calc but they're already tagged
            continue
        cmc_sum += info['cmc'] * info.get('qty', 1)
        nonland_count += info.get('qty', 1)
    avg_cmc = cmc_sum / max(nonland_count, 1)
    
    p("\n" + "=" * 70)
    p("FINAL DECK STATISTICS")
    p("=" * 70)
    p(f"Total cards: {total}")
    p(f"Main deck: {total - 1}")
    p(f"Lands: {final_land_count}")
    p(f"Non-lands: {total - final_land_count}")
    p(f"Average CMC (nonland): {avg_cmc:.2f}")
    p("")
    p("Role breakdown:")
    for role, count in sorted(final_roles.items(), key=lambda x: -x[1]):
        p(f"  {role:25s}: {count}")
    
    # Build markdown output
    md_lines = []
    md_lines.append("# Lorehold, the Historian - Optimized Deck (2026-05-27)")
    md_lines.append("")
    md_lines.append("## Commander")
    md_lines.append("1x Lorehold, the Historian (5cmc, RW)")
    md_lines.append("")
    md_lines.append("## Deck List (99 cards)")
    md_lines.append("")
    md_lines.append("| # | Card | CMC | Tag | Source |")
    md_lines.append("|---|---|---|---|---|")
    
    sorted_cards = sorted(
        [(n, i) for n, i in deck_cards.items() if i['tag'] != 'commander'],
        key=lambda x: (x[1]['tag'] != 'land', x[1]['cmc'], x[0])
    )
    
    for idx, (name, info) in enumerate(sorted_cards, 1):
        qty_str = f"x{info['qty']}" if info.get('qty', 1) > 1 else ""
        name_display = f"{name} {qty_str}" if qty_str else name
        md_lines.append(f"| {idx} | {name_display} | {info['cmc']} | {info['tag']} | {info['source']} |")
    
    md_lines.append("")
    md_lines.append("## Metrics")
    md_lines.append(f"- **Total cards:** {total} ({total - 1} main + 1 commander)")
    md_lines.append(f"- **Lands:** {final_land_count}")
    md_lines.append(f"- **Ramp:** {final_roles.get('ramp', 0)}")
    md_lines.append(f"- **Draw:** {final_roles.get('draw', 0)}")
    md_lines.append(f"- **Removal:** {final_roles.get('removal', 0)}")
    md_lines.append(f"- **Board Wipes:** {final_roles.get('board_wipe', 0)}")
    md_lines.append(f"- **Protection:** {final_roles.get('protection', 0)}")
    md_lines.append(f"- **Recursion:** {final_roles.get('recursion', 0)}")
    md_lines.append(f"- **Spellslingers:** {final_roles.get('spellslinger', 0)}")
    md_lines.append(f"- **Tutors:** {final_roles.get('tutor', 0)}")
    md_lines.append(f"- **Win Conditions:** {final_roles.get('wincon', 0)}")
    md_lines.append(f"- **Average CMC (nonland):** {avg_cmc:.2f}")
    md_lines.append("")
    md_lines.append("## Comparison with Original Deck")
    md_lines.append("")
    md_lines.append("| Metric | Original | Optimized | Change |")
    md_lines.append("|---|---|---|---|")
    
    orig_metrics = {
        'land': 34, 'ramp': 17, 'draw': 8, 'removal': 7,
        'board_wipe': 6, 'protection': 7, 'recursion': 5
    }
    for metric, orig_val in orig_metrics.items():
        new_val = final_roles.get(metric, 0)
        diff = new_val - orig_val
        sign = '+' if diff > 0 else ''
        md_lines.append(f"| {metric.replace('_', ' ').title()} | {orig_val} | {new_val} | {sign}{diff} |")
    md_lines.append(f"| Avg CMC | 3.98 | {avg_cmc:.2f} | {avg_cmc - 3.98:+.2f} |")
    md_lines.append(f"| Main Deck | 99 | {total - 1} | {'+' if total > 100 else ''}{total - 100} |")
    md_lines.append("")
    md_lines.append("## Upgrades Applied")
    md_lines.append("")
    md_lines.append("### Removed (not in collection, no equivalent)")
    for dc, tags in missing_cards:
        tag = dc['functional_tag'] or (tags[0] if tags else 'unknown')
        if tag == 'None':
            tag = tags[0] if tags else 'unknown'
        # Skip basics since they're auto-added
        if dc['card_name'] in ('Mountain', 'Plains'):
            continue
        # Check if an equivalent exists
        result = find_in_collection(dc['card_name'], lookup)
        if result:
            coll_name, _ = result
            md_lines.append(f"- **Replaced:** {dc['card_name']} -> **{coll_name}** ({tag}, CMC {dc['cmc']})")
        else:
            md_lines.append(f"- **Removed:** {dc['card_name']} ({tag}, CMC {dc['cmc']}) - not in collection")
    
    md_lines.append("")
    md_lines.append("### New Additions from Collection")
    md_lines.append("")
    
    # Show the best new additions first
    upgrade_cards = [(n, i) for n, i in deck_cards.items() 
                     if i['source'] in ('collection_upgrade', 'collection_land')]
    # Sort by score for display
    upgrade_scored = []
    for n, i in upgrade_cards:
        row_data = [r for r in collection if r['card_en'] == n]
        if row_data:
            s = score_upgrade(row_data[0])
            upgrade_scored.append((s, n, i))
        else:
            upgrade_scored.append((0, n, i))
    upgrade_scored.sort(key=lambda x: -x[0])
    
    for score, name, info in upgrade_scored:
        md_lines.append(f"- **{name}** ({info['tag']}, CMC {info['cmc']}) - score {score}")
    
    md_lines.append("")
    md_lines.append("## Mulligan Analysis")
    md_lines.append("")
    md_lines.append("**Lorehold, the Historian** is a 5cmc commander. Key mulligan decisions:")
    md_lines.append("")
    md_lines.append("**Keep if:**")
    md_lines.append("- 3-4 lands (at least 1 RW source)")
    md_lines.append("- 1-2 ramp spells (Sol Ring, Signet, Ritual)")
    md_lines.append("- 1 cheap interaction or draw spell")
    md_lines.append("- Curve caps at 3-4cmc without ramp")
    md_lines.append("")
    md_lines.append("**Mulligan if:**")
    md_lines.append("- 0-1 lands (cannot recover)")
    md_lines.append("- 6+ lands (risk of flooding)")
    md_lines.append("- All spells are 5+ cmc (too slow)")
    md_lines.append("- Single color only (can't cast RW spells)")
    md_lines.append("")
    md_lines.append("## Lorehold Strategy Guide")
    md_lines.append("")
    md_lines.append("1. **Chain Spells:** Cast a cheap spell (1-2cmc) first, then your")
    md_lines.append("   big payoff spell second to trigger Lorehold's copy ability.")
    md_lines.append("2. **Ritual Acceleration:** Desperate Ritual -> Seething Song ->")
    md_lines.append("   Jeska's Will lets you chain 3+ spells in one turn.")
    md_lines.append("3. **Topdeck Control:** Sensei's Divining Top + Scroll Rack + Land Tax")
    md_lines.append("   ensure you always have the right second spell ready.")
    md_lines.append("4. **Copy Synergy:** Lorehold copies your second instant/sorcery.")
    md_lines.append("   Double Vision, Reverberate, Dualcaster Mage, and Flare of")
    md_lines.append("   Duplication multiply your value further.")
    md_lines.append("5. **Treasure Engine:** Smothering Tithe + Goldspan Dragon +")
    md_lines.append("   Storm-Kiln Artist provide the mana to chain multiple spells.")
    md_lines.append("6. **Win Conditions:** Copied finishers (Insurrection, Board Wipes),")
    md_lines.append("   commander damage, Storm Herd tokens, or Approach of the Second Sun.")
    
    result = '\n'.join(md_lines)
    
    # Save
    out_dir = os.path.join(os.path.dirname(__file__), '..', '..', 'decks', 'lorehold-the-historian')
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, '2026-05-27-optimized.md')
    with open(out_path, 'w') as f:
        f.write(result)
    p(f"\nSaved to: {out_path}")
    
    return result

if __name__ == '__main__':
    main()