#!/usr/bin/env python3
"""
Lorehold, the Historian - Optimized Deck Builder FINAL
Fixes card counting and produces a proper 100-card deck (1 commander + 99 main).
"""

import sqlite3, os

DB = os.path.join(os.path.dirname(__file__), '..', '..', 'scripts', 'knowledge.db')

def get_data():
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    deck = conn.execute("""
        SELECT dc.id as dc_id, dc.card_name, dc.quantity, dc.functional_tag,
               dc.cmc, dc.type_line, dc.oracle_text, dc.is_commander
        FROM deck_cards dc JOIN decks d ON d.id = dc.deck_id
        JOIN commanders c ON c.id = d.commander_id
        WHERE c.name LIKE '%Lorehold%'
        ORDER BY dc.is_commander DESC, dc.card_name
    """).fetchall()
    deck_tags = {}
    for dc in deck:
        tags = conn.execute("SELECT tag FROM card_tags WHERE deck_card_id = ?", (dc['dc_id'],)).fetchall()
        deck_tags[dc['card_name']] = [t['tag'] for t in tags]
    collection = conn.execute("SELECT * FROM user_collection ORDER BY card_en").fetchall()
    conn.close()
    return deck, deck_tags, collection

def norm(s):
    s = s.lower().strip()
    for a, b in {'ó':'o','é':'e','í':'i','á':'a','ú':'u','ã':'a','õ':'o','ç':'c','ñ':'n'}.items():
        s = s.replace(a, b)
    return s

# Build: normalized -> (original_name, row)
def coll_lookup(collection):
    lu = {}
    for r in collection:
        k = norm(r['card_en'])
        if k not in lu or len(r['card_en']) < len(lu[k][0]):
            lu[k] = (r['card_en'], r)
    return lu

def find(deck_name, lu):
    k = norm(deck_name)
    if k in lu: return lu[k]
    parts = k.split(' // ')
    if len(parts) > 1 and parts[0] in lu: return lu[parts[0]]
    for ck, cv in lu.items():
        if ck in k or k in ck:
            if abs(len(ck)-len(k)) <= 12: return cv
    return None

def score_upgrade(row, tag_override=None):
    name = norm(row['card_en'])
    tag = tag_override or row['functional_tag'] or ''
    cmc = row['cmc']
    tl = (row['type_line'] or '').lower()
    score = 0
    rs = {'ramp':8,'draw':8,'spellslinger':9,'protection':7,'removal':7,
          'board_wipe':7,'recursion':7,'tutor':6,'wincon':7,'token_maker':5,
          'exile_value':7,'engine':6,'big_spell':5,'payoff':5,'loot':5,
          'graveyard_synergy':5,'unknown':2,'land':1}
    score += rs.get(tag, 2)
    if tag in ('ramp','draw','protection','removal') and cmc <= 2: score += 5
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
           'mana geyser','neheb','radiant scrollwielder',
           'invoke calamity','inti, seneschal of the sun','demand answers']
    for t in top:
        if t in name: score += 5; break
    if cmc >= 7 and tag not in ('board_wipe','wincon','big_spell'): score -= 3
    if cmc >= 10: score -= 2
    return score

def main():
    deck, deck_tags, collection = get_data()
    lu = coll_lookup(collection)
    
    out = []; p = lambda s="": (out.append(s), print(s))
    
    p("="*70)
    p("LOREHOLD, THE HISTORIAN - OPTIMIZED DECK BUILD")
    p("="*70)
    
    # Organize original deck
    commander = None
    kept = []       # (dc, coll_row, tags) - cards in collection
    missing = []    # (dc, tags) - cards NOT in collection
    
    for dc in deck:
        tags = deck_tags.get(dc['card_name'], [])
        if dc['is_commander']:
            commander = dc; continue
        result = find(dc['card_name'], lu)
        if result:
            kept.append((dc, result[1], tags))
        else:
            missing.append((dc, tags))
    
    p(f"Commander: {commander['card_name']}")
    p(f"Original entries (excl cmdr): {len(deck)-1}")
    p(f"In collection: {len(kept)}")
    p(f"Missing: {len(missing)}")
    
    # ===== BUILD DECK (tracking actual card count) =====
    TARGET_MAIN = 99  # target main deck cards
    TARGET_LANDS = 37  # target land count
    
    deck_cards = []      # list of (name, info_dict)
    card_count = 0       # actual card count
    
    def add(name, tag, cmc, source, qty=1):
        nonlocal card_count
        deck_cards.append({'name': name, 'tag': tag, 'cmc': cmc, 'source': source, 'qty': qty})
        card_count += qty
        return True
    
    # 1. Commander (not part of main 99)
    add('Lorehold, the Historian', 'commander', 5.0, 'commander')
    card_count -= 1  # commander excluded from main deck count
    
    # 2. Basics (always available)
    add('Mountain', 'land', 0.0, 'basic', 8)
    add('Plains', 'land', 0.0, 'basic', 7)
    
    # 3. Kept original cards
    already_in_deck = set()
    already_in_deck.add(norm('Mountain'))
    already_in_deck.add(norm('Plains'))
    already_in_deck.add(norm('Lorehold, the Historian'))
    
    for dc, coll_row, tags in kept:
        final_name = coll_row['card_en']
        tag = dc['functional_tag'] or (tags[0] if tags else 'unknown')
        if tag in ('None', None): tag = tags[0] if tags else 'unknown'
        add(final_name, tag, dc['cmc'], 'original_in_collection')
        already_in_deck.add(norm(final_name))
    
    current_land_count = sum(c['qty'] for c in deck_cards if c['tag'] == 'land')
    p(f"\nAfter basics + kept originals:")
    p(f"  Card count: {card_count}/{TARGET_MAIN}")
    p(f"  Lands: {current_land_count}")
    
    # 4. Add extra lands from collection to hit TARGET_LANDS
    land_rows = []
    for r in collection:
        tag = r['functional_tag'] or ''
        n = norm(r['card_en'])
        if tag == 'land' and n not in already_in_deck:
            land_rows.append(r)
    
    def score_land(r):
        n = norm(r['card_en'])
        s = 0
        for t in ['exotic orchard','inspiring vantage','sundown pass','clifftop retreat',
                  'sun-blessed peak','path of ancestry','abraded bluffs','wind-scarred crag',
                  'temple of triumph']:
            if t in n: s += 2
        if 'reliquary' in n: s += 1
        if 'command tower' in n or 'croft manor' in n: s += 5
        if 'boseiju' in n or 'isengard' in n: s += 3
        if 'kor haven' in n or 'osgiliath' in n: s += 2
        return s
    
    land_rows.sort(key=lambda r: -score_land(r))
    
    lands_to_add = TARGET_LANDS - current_land_count
    if lands_to_add < 0:
        # Too many lands already, need to cut (but basics are fixed)
        lands_to_add = 0
    
    lands_added = 0
    for r in land_rows:
        if lands_added >= lands_to_add: break
        if card_count >= TARGET_MAIN: break
        add(r['card_en'], 'land', 0.0, 'collection_land')
        already_in_deck.add(norm(r['card_en']))
        lands_added += 1
    
    p(f"  Added {lands_added} extra lands")
    current_land_count = sum(c['qty'] for c in deck_cards if c['tag'] == 'land')
    p(f"  Lands now: {current_land_count}")
    p(f"  Cards now: {card_count}/{TARGET_MAIN}")
    
    # 5. Fill remaining slots with non-land upgrades
    remaining = TARGET_MAIN - card_count
    if remaining < 0:
        # Too many cards! Need to trim.
        p(f"\n  WARNING: Over by {-remaining} cards! Trimming...")
        # Remove non-land, non-basic cards from the end of kept list until we fit
        # Actually, remove the lowest-scored kept cards
        kept_scores = []
        for c in deck_cards:
            if c['source'] == 'original_in_collection' and c['tag'] not in ('land', 'commander'):
                row_data = [r for r in collection if r['card_en'] == c['name']]
                s = score_upgrade(row_data[0]) if row_data else 0
                kept_scores.append((s, c))
        kept_scores.sort(key=lambda x: x[0])  # lowest first
        
        to_remove = -remaining
        removed = 0
        for s, c in kept_scores:
            if removed >= to_remove: break
            deck_cards.remove(c)
            card_count -= c['qty']
            removed += 1
        remaining = TARGET_MAIN - card_count
        p(f"  Removed {removed} low-value original cards")
        p(f"  Remaining: {card_count}/{TARGET_MAIN}")
    
    # Get non-land, non-land-tagged cards from collection not yet in deck
    other_rows = []
    for r in collection:
        tag = r['functional_tag'] or ''
        n = norm(r['card_en'])
        if tag != 'land' and n not in already_in_deck:
            other_rows.append(r)
    
    scored = [(score_upgrade(r), r) for r in other_rows]
    scored.sort(key=lambda x: -x[0])
    
    # Calculate role needs
    def role_counts():
        rc = {}
        for c in deck_cards:
            t = c['tag']
            q = c['qty']
            rc[t] = rc.get(t, 0) + q
        return rc
    
    roles = role_counts()
    TARGETS = {'ramp':(12,16),'draw':(8,14),'removal':(8,12),
               'board_wipe':(4,6),'protection':(4,6),'recursion':(3,6),
               'spellslinger':(3,6),'tutor':(2,4),'token_maker':(2,4),
               'wincon':(2,4),'exile_value':(1,3)}
    needs = {}
    for role, (mn,mx) in TARGETS.items():
        cur = roles.get(role, 0)
        if cur < mn: needs[role] = mn - cur
    
    p(f"\nRole needs for remaining {remaining} slots: {needs}")
    
    # First pass: fill roles
    selected = []
    selected_norms = set()
    
    for role, need in sorted(needs.items(), key=lambda x: -x[1]):
        if need <= 0: continue
        found = 0
        for s, r in scored:
            if found >= need: break
            n = norm(r['card_en'])
            tag = r['functional_tag'] or ''
            if tag == role and n not in selected_norms:
                selected.append(r)
                selected_norms.add(n)
                found += 1
    
    # Second pass: fill remaining with best scored
    for s, r in scored:
        if len(selected) >= remaining: break
        n = norm(r['card_en'])
        if n not in selected_norms:
            selected.append(r)
            selected_norms.add(n)
    
    # Add selected upgrades
    for r in selected:
        if card_count >= TARGET_MAIN: break
        tag = r['functional_tag'] or 'synergy'
        add(r['card_en'], tag, r['cmc'], 'collection_upgrade')
    
    p(f"\n  Added {len(selected)} upgrades")
    p(f"  Final count: {card_count}/{TARGET_MAIN} (+ commander = {card_count+1}/100)")
    
    # Final stats
    final_roles = role_counts()
    final_land = sum(c['qty'] for c in deck_cards if c['tag'] == 'land')
    nonland = card_count - final_land
    
    cmc_sum = sum(c['cmc'] for c in deck_cards if c['tag'] not in ('land','commander'))
    cmc_cnt = sum(1 for c in deck_cards if c['tag'] not in ('land','commander'))
    avg_cmc = cmc_sum / max(cmc_cnt, 1)
    
    p("\n" + "="*70)
    p("FINAL DECK STATISTICS")
    p("="*70)
    p(f"Total: {card_count + 1} cards ({card_count} main + 1 commander)")
    p(f"Lands: {final_land} (8 Mountain + 7 Plains + {final_land - 15} non-basic)")
    p(f"Non-lands: {nonland}")
    p(f"Avg CMC (nonland): {avg_cmc:.2f}")
    p("")
    for role, count in sorted(final_roles.items(), key=lambda x: -x[1]):
        if count > 0: p(f"  {role:20s}: {count}")
    
    # ===== MARKDOWN OUTPUT =====
    md = []
    md.append("# Lorehold, the Historian - Optimized Deck (2026-05-27)")
    md.append("")
    md.append("## Commander")
    md.append("1x Lorehold, the Historian (5cmc, RW)")
    md.append("")
    md.append(f"## Deck List ({card_count} main deck cards)")
    md.append("")
    md.append(f"### Lands ({final_land} cards)")
    md.append("")
    md.append("| # | Card | CMC | Source |")
    md.append("|---|---|---|---|")
    
    basics_cards = [c for c in deck_cards if c['name'] in ('Mountain','Plains')]
    nonb_lands = [c for c in deck_cards if c['tag'] == 'land' and c['name'] not in ('Mountain','Plains')]
    for c in basics_cards:
        md.append(f"| - | {c['name']} x{c['qty']} | 0 | {c['source']} |")
    for i, c in enumerate(nonb_lands, 1):
        md.append(f"| {i} | {c['name']} | 0 | {c['source']} |")
    
    md.append("")
    md.append(f"### Non-lands ({nonland} cards)")
    md.append("")
    md.append("| # | Card | CMC | Tag | Source |")
    md.append("|---|---|---|---|---|")
    
    nonland_cards = [c for c in deck_cards if c['tag'] not in ('land','commander')]
    nonland_cards.sort(key=lambda x: (x['cmc'], x['name']))
    for i, c in enumerate(nonland_cards, 1):
        md.append(f"| {i} | {c['name']} | {c['cmc']} | {c['tag']} | {c['source']} |")
    
    # Metrics
    md.append("")
    md.append("## Metrics")
    md.append(f"- **Total cards:** {card_count + 1} ({card_count} main + 1 commander)")
    md.append(f"- **Lands:** {final_land}")
    md.append(f"- **Ramp:** {final_roles.get('ramp', 0)}")
    md.append(f"- **Draw:** {final_roles.get('draw', 0)}")
    md.append(f"- **Removal:** {final_roles.get('removal', 0)}")
    md.append(f"- **Board Wipes:** {final_roles.get('board_wipe', 0)}")
    md.append(f"- **Protection:** {final_roles.get('protection', 0)}")
    md.append(f"- **Recursion:** {final_roles.get('recursion', 0)}")
    md.append(f"- **Spellslingers:** {final_roles.get('spellslinger', 0)}")
    md.append(f"- **Tutors:** {final_roles.get('tutor', 0)}")
    md.append(f"- **Win Conditions:** {final_roles.get('wincon', 0)}")
    md.append(f"- **Average CMC (nonland):** {avg_cmc:.2f}")
    md.append("")
    md.append("## Comparison with Original Deck")
    md.append("")
    md.append("| Metric | Original | Optimized | Change |")
    md.append("|---|---|---|---|")
    orig = {'Land':34,'Ramp':17,'Draw':8,'Removal':7,'Board Wipe':6,'Protection':7,'Recursion':5}
    for m, ov in orig.items():
        k = m.lower().replace(' ', '_')
        nv = final_roles.get(k, 0)
        d = nv - ov
        md.append(f"| {m} | {ov} | {nv} | {'+' if d > 0 else ''}{d} |")
    md.append(f"| Avg CMC | 3.98 | {avg_cmc:.2f} | {avg_cmc - 3.98:+.2f} |")
    md.append("")
    
    # Changes
    md.append("## Changes from Original Deck")
    md.append("")
    
    # Missing cards and their replacements
    md.append("### Cards Replaced (not available in collection)")
    for dc, tags in missing:
        tag = dc['functional_tag'] or (tags[0] if tags else 'unknown')
        if tag == 'None': tag = tags[0] if tags else 'unknown'
        if dc['card_name'] not in ('Mountain','Plains'):
            result = find(dc['card_name'], lu)
            if result:
                coll_name, _ = result
                if coll_name != dc['card_name']:
                    md.append(f"- {dc['card_name']} -> **{coll_name}** (equivalent reskin/DFC)")
            else:
                md.append(f"- {dc['card_name']} ({tag}, cmc {dc['cmc']})")
    
    md.append("")
    md.append("### New Additions from Collection (upgrades)")
    md.append("")
    
    upgrade_cards = [c for c in deck_cards if c['source'] in ('collection_land','collection_upgrade')]
    upgrade_scored = []
    for c in upgrade_cards:
        row_data = [r for r in collection if r['card_en'] == c['name']]
        s = score_upgrade(row_data[0]) if row_data else 0
        upgrade_scored.append((s, c))
    upgrade_scored.sort(key=lambda x: -x[0])
    for s, c in upgrade_scored:
        md.append(f"- **{c['name']}** ({c['tag']}, CMC {c['cmc']}) - synergy {s}")
    
    md.append("")
    md.append("## Mulligan & Strategy")
    md.append("")
    md.append("**Lorehold, the Historian** (5cmc RW)")
    md.append("")
    md.append("**Keep:** 3-4 lands + ramp + cheap spell")
    md.append("**Mulligan:** 0-1 lands, 6+ lands, all expensive")
    md.append("")
    md.append("**Strategy:** Cast cheap spell -> big spell (gets copied).")
    md.append("Rituals, Top/Scroll Rack for setup. Win via copied finishers.")
    
    result = '\n'.join(md)
    out_path = os.path.join(os.path.dirname(__file__), '..', '..', 'decks', 'lorehold-the-historian', '2026-05-27-optimized.md')
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'w') as f:
        f.write(result)
    p(f"\nSaved: {out_path}")
    p(f"\nDone! Deck has {card_count + 1}/100 cards ({card_count} main + commander)")

if __name__ == '__main__':
    main()