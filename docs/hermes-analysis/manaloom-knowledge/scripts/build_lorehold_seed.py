#!/usr/bin/env python3
"""Parse and insert the Lorehold deck into knowledge.db."""
import json, sqlite3, subprocess, re
from datetime import date
from collections import Counter

DECK_TEXT = """1x Ancient Copper Dragon (clb)
1x Ancient Tomb (eos)
1x Apex of Power (c21) [Pay-offs] 
1x Arcane Signet (mkc) [Ramp] 
1x Archaeomancer's Map (soc)
1x Arid Mesa (mh2)
1x Artist's Talent (blb)
1x Austere Command (m3c) [Pay-offs] 
1x Bender's Waterskin (tla) [Ramp] 
1x Bloodstained Mire (mh3)
1x Boros Charm (fdn) *F* 
1x Boseiju, Who Shelters All (chk)
1x Brass's Bounty (fdn)
1x Call Forth the Tempest (ltc) [Pay-offs] 
1x Cavern of Souls (plci)
1x Claim Jumper (soc)
1x Clifftop Retreat (soc)
1x Command Tower (tdc)
1x Deflecting Palm (mkc)
1x Deflecting Swat (c20) [Interaction] 
1x Desperate Ritual (uma)
1x Dormant Volcano (cm2)
1x Double Vision (ncc)
1x Emeria's Call // Emeria, Shattered Skyclave (znr)
1x Enlightened Tutor (mir) [Tutor] 
1x Fated Clash (fic)
1x Flooded Strand (mh3)
1x Furygale Flocking (soc)
1x Galadriel's Dismissal (ltc)
1x Galvanoth (ddj)
1x Goblin Engineer (h1r) *F* 
1x Goldspan Dragon (soc)
1x Grand Abolisher (big)
1x Hellkite Tyrant (fic)
1x Hexing Squelcher (ecl) [Protection] 
1x Inspiring Vantage (otj)
1x Insurrection (cmm)
1x Jeska's Will (mkc) [Ramp] 
1x Jokulhaups (6ed)
1x Karoo (plst)
1x Kor Haven (nem)
1x Land Tax (soc)
1x Library of Leng (spg) [Top Deck Manipulation] 
1x Lightning Greaves (soc)
1x Longshot, Rebel Bowman (tle)
1x Lorehold, the Historian (sos) *F*  [Commander{top}] 
1x Mizzix's Mastery (otc)
1x Monument to Endurance (dft) [Draw] 
1x Mother of Runes (clb)
8x Mountain (fic) 481 *F* 
1x Obliterate (plst)
1x Olórin's Searing Light (ltc)
1x Orim's Chant (mh3) [Interaction] 
1x Oswald Fiddlebender (afr)
1x Path to Exile (ecc) [Interaction] 
1x Pearl Medallion (mh3)
1x Penance (exo) [Top Deck Manipulation] 
1x Perch Protection (blc)
7x Plains (fic) 478 *F* 
1x Reforge the Soul (inr)
1x Restoration Seminar (sos)
1x Rise of the Eldrazi (cmm) [Pay-offs] 
1x Rite of the Dragoncaller (fdn)
1x Ruby Medallion (mh3) [Ramp] 
1x Sacred Foundry (eoe)
1x Scalding Tarn (zen)
1x Scroll Rack (cmr) [Top Deck Manipulation] 
1x Season of the Bold (blb)
1x Seething Song (arc) [Ramp] 
1x Sensei's Divining Top (ema) [Top Deck Manipulation] 
1x Smothering Tithe (prna) [Ramp] 
1x Sol Ring (ltc) [Ramp] 
1x Storm Herd (scd) [Pay-offs] 
1x Sunbird's Invocation (blc)
1x Sundown Pass (sos)
1x Surge to Victory (soc)
1x Swords to Plowshares (soc)
1x Talisman of Conviction (fic) [Ramp] 
1x Taunt from the Rampart (ltc)
1x Teferi's Protection (2x2)
1x Unexpected Windfall (plst) [Ramp] 
1x Urza's Saga (mh2) *F* 
1x Valakut Awakening // Valakut Stoneforge (plst)
1x Victory Chimes (c21) [Ramp] 
1x Volcanic Vision (dtk) [Pay-offs] 
1x Weathered Wayfarer (ltc)
1x Windswept Heath (mh3)"""

# Parse each line
cards_raw = []
for line in DECK_TEXT.strip().split('\n'):
    line = line.strip()
    if not line:
        continue
    # "Nx ..."
    qty = int(line.split('x')[0].strip())
    rest = line.split('x', 1)[1].strip()
    # Extract [Tag]
    tag = ''
    m = re.search(r'\[([^\]]*)\]', rest)
    if m:
        tag = m.group(1).strip()
        rest = rest.replace(m.group(0), '')
    # Remove *F*
    rest = re.sub(r'\*F\*', '', rest).strip()
    # Extract (set)
    set_code = ''
    m = re.search(r'\(([^)]*)\)', rest)
    if m:
        set_code = m.group(1).strip()
        rest = rest.replace(m.group(0), '')
    name = rest.strip()
    name_lower = name.lower().strip()
    # Normalize apostrophes for matching
    name_lower_clean = name_lower.replace("'", "").replace("\\u2019", "").replace("\\u2018", "")
    cards_raw.append({'name': name, 'qty': qty, 'set': set_code, 'tag': tag, 'name_lower': name_lower, 'name_clean': name_lower_clean})

print(f"Parsed {len(cards_raw)} card entries")

# Classify as commander, land, or nonland
LAND_NAMES = [
    'ancient tomb', 'arid mesa', 'bloodstained mire', 'boseiju, who shelters all',
    'cavern of souls', 'clifftop retreat', 'command tower', 'dormant volcano',
    "emerias call // emeria, shattered skyclave", 'flooded strand',
    'inspiring vantage', 'karoo', 'kor haven', 'sacred foundry',
    'scalding tarn', 'sundown pass', 'urzas saga',
    'valakut awakening // valakut stoneforge', 'windswept heath',
]

NON_LAND_LANDS = ['urzas saga']  # Saga-type lands (count as land but also have utility)

commander = None
lands_list = []
nonlands_list = []

for c in cards_raw:
    nl = c['name_lower']
    nl_clean = c['name_clean']
    if 'commander' in c['tag'].lower() or 'lorehold' in nl:
        commander = c
        nonlands_list.append(c)
    elif nl.startswith('mountain') or nl.startswith('plains') or nl_clean in LAND_NAMES:
        lands_list.append(c)
    else:
        nonlands_list.append(c)

total_lands = sum(c['qty'] for c in lands_list)
print(f"\nCommander: {commander['name'] if commander else 'NOT FOUND'}")
print(f"Lands: {total_lands} ({len(lands_list)} entries)")
print(f"Non-lands: {len(nonlands_list)} entries (incl commander)")
print(f"Total (with commander): {total_lands + len(nonlands_list)}")

# Functional tag assignment
def get_tag(c):
    t = c['tag'].lower()
    nl = c['name_clean']  # Use clean name (apostrophes removed)
    nl_orig = c['name_lower']
    
    # Priority: user-provided tags
    if 'commander' in t:
        return 'enabler'
    if 'ramp' in t:
        return 'ramp'
    if 'draw' in t or 'rummage' in t:
        return 'draw'
    if 'tutor' in t:
        return 'tutor'
    if 'interaction' in t or 'removal' in t:
        return 'removal'
    if 'protection' in t:
        return 'protection'
    if 'pay-offs' in t or 'payoff' in t or 'wincon' in t:
        # Check if it's actually a board wipe first
        board_wipes = {'austere command', 'obliterate', 'jokulhaups', 'fated clash', 'taunt from the rampart'}
        if nl in board_wipes:
            return 'board_wipe'
        return 'wincon'
    if 'top deck' in t or 'topdeck' in t or 'manipulation' in t:
        return 'engine'
    
    # Card name-based classification (using clean names without apostrophes)
    board_wipes = {'austere command', 'obliterate', 'jokulhaups', 'fated clash', 'taunt from the rampart'}
    removal = {'swords to plowshares', 'path to exile', 'deflecting palm', 'deflecting swat',
               'orims chant', 'galadriels dismissal', 'perch protection', 'longshot rebel bowman'}
    protection = {'teferis protection', 'hexing squelcher', 'mother of runes', 'grand abolisher', 'boros charm'}
    ramp_list = {'sol ring', 'arcane signet', 'talisman of conviction', 'pearl medallion',
            'ruby medallion', 'seething song', 'smothering tithe', 'victory chimes',
            'unexpected windfall', 'benders waterskin', 'desperate ritual', 'land tax',
            'archaeomancers map', 'claim jumper', 'weathered wayfarer'}
    draw_list = {'monument to endurance', 'furygale flocking', 'reforge the soul',
            'season of the bold'}
    engine_list = {'scroll rack', 'senseis divining top', 'penance', 'library of leng',
              'sunbirds invocation', 'double vision', 'galvanoth', 'mizzixs mastery',
              'restoration seminar', 'goldspan dragon', 'ancient copper dragon'}
    wincon_list = {'apex of power', 'call forth the tempest', 'rise of the eldrazi',
              'storm herd', 'volcanic vision', 'insurrection', 'brasss bounty',
              'rite of the dragoncaller', 'surge to victory', 'olrins searing light'}
    enabler_list = {'goblin engineer', 'oswald fiddlebender', 'lightning greaves'}
    tutor_list = {'enlightened tutor'}
    
    if nl in board_wipes:
        return 'board_wipe'
    if nl in removal:
        return 'removal'
    if nl in protection:
        return 'protection'
    if nl in ramp_list:
        return 'ramp'
    if nl in draw_list:
        return 'draw'
    if nl in engine_list:
        return 'engine'
    if nl in wincon_list:
        return 'wincon'
    if nl in enabler_list:
        return 'enabler'
    if nl in tutor_list:
        return 'tutor'
    
    # Special cases for names with apostrophes, special chars, or MDFCs
    eng_special = {'artists talent'}
    wincon_special = {'hellkite tyrant'}
    removal_special = {'longshot rebel bowman', 'olorins searing light'}
    dfc_land_tags = {'emerias call // emeria, shattered skyclave', 'valakut awakening // valakut stoneforge'}
    
    # Also check name without commas (for cards like "Longshot, Rebel Bowman")
    nl_nocomma = nl.replace(',', '').strip()
    # Also remove accented chars for matching
    nl_flat = nl_nocomma.replace('ó', 'o').replace('é', 'e').replace('í', 'i').replace('ú', 'u').replace('á', 'a').replace('â', 'a').replace('ê', 'e').replace('ô', 'o').replace('ü', 'u')
    
    if nl in eng_special:
        return 'engine'
    if nl_nocomma in wincon_special or nl in wincon_special:
        return 'wincon'
    if nl_nocomma in removal_special or nl in removal_special or nl_flat in removal_special:
        return 'removal'
    if nl in dfc_land_tags:
        return 'land'
    
    return 'other'

# Count up everything
cards_list = []
for c in cards_raw:
    is_l = c in lands_list or c['name_lower'] in ['mountain', 'plains']
    ftag = 'land' if (is_l and c != commander) else get_tag(c)
    if c == commander:
        ftag = 'enabler'
    
    cards_list.append({
        'name': c['name'],
        'quantity': c['qty'],
        'functional_tag': ftag,
        'is_commander': 1 if c == commander else 0,
        'cmc': 0,
    })

# Tag counts
tag_counts = Counter()
for c in cards_list:
    if c['functional_tag'] != 'land':
        tag_counts[c['functional_tag']] += c['quantity']

print("\n=== Functional Tag Distribution ===")
for tag, cnt in sorted(tag_counts.items()):
    print(f"  {tag}: {cnt}")
print(f"  lands: {total_lands}")

# Scryfall CMC lookup
print("\n=== Scryfall CMC Lookup ===")
cmc_total = 0
cmc_count = 0
special_cmc = {
    'boros charm': 2,
    'path to exile': 1,
    'swords to plowshares': 1,
    'sol ring': 1,
    'arcane signet': 2,
    'lightning greaves': 2,
    'teferis protection': 3,
    'enlightened tutor': 1,
    'scroll rack': 1,
    'senseis divining top': 1,
    'monument to endurance': 4,
    'reforge the soul': 5,
    'auste command': 6,
    'obliterate': 8,
    'jokulhaups': 6,
    'insurrection': 8,
    'sunbirds invocation': 6,
    'apex of power': 10,
    'call forth the tempest': 7,
    'rise of the eldrazi': 12,
    'storm herd': 10,
    'volcanic vision': 6,
    'goldspan dragon': 5,
    'ancient copper dragon': 7,
    'double vision': 4,
    'galvanoth': 5,
    'mizzixs mastery': 6,
    'ruby medallion': 2,
    'pearl medallion': 2,
    'smothering tithe': 4,
    'jeska will': 3,
    'talisman of conviction': 2,
    'seething song': 3,
    'land tax': 1,
    'archaeomancers map': 3,
    'weathered wayfarer': 1,
    'mother of runes': 1,
    'grand abolisher': 2,
    'deflecting swat': 3,
    'orims chant': 1,
    'galadriels dismissal': 2,
    'perch protection': 3,
    'deflecting palm': 2,
    'hexing squelcher': 3,
    'goblin engineer': 2,
    'oswald fiddlebender': 3,
    'furygale flocking': 3,
    'season of the bold': 2,
    'penance': 3,
    'library of leng': 1,
    'artists talent': 3,
    'benders waterskin': 1,
    'fated clash': 3,
    'taunt from the rampart': 4,
    'surge to victory': 6,
    'rite of the dragoncaller': 5,
    'olrins searing light': 4,
    'brasss bounty': 7,
    'unexpected windfall': 4,
    'victory chimes': 3,
    'restoration seminar': 3,
    'claim jumper': 2,
    'desperate ritual': 2,
    'longshot, rebel bowman': 3,
    'emerias call // emeria, shattered skyclave': 7,
    'valakut awakening // valakut stoneforge': 3,
}

for c in cards_list:
    if c['functional_tag'] == 'land' or c['is_commander']:
        continue
    nl = c['name'].lower().strip()
    
    # Look up in our known map first
    found = False
    for key, cmc in special_cmc.items():
        if key in nl.replace("'", "").replace(",", "").replace("ó", "o") or nl.replace("'", "").replace(",", "").replace("ó", "o") in key:
            c['cmc'] = cmc
            cmc_total += cmc * c['quantity']
            cmc_count += c['quantity']
            found = True
            break
    
    if not found:
        try:
            # URL-encode the name for curl
            import urllib.parse
            url_name = urllib.parse.quote(nl)
            r = subprocess.run(['curl', '-sL',
                f'https://api.scryfall.com/cards/named?exact={url_name}'],
                capture_output=True, text=True, timeout=10)
            data = json.loads(r.stdout)
            cmc = data.get('cmc', 0)
            c['cmc'] = cmc
            cmc_total += cmc * c['quantity']
            cmc_count += c['quantity']
            print(f"  Scryfall: {c['name']} = cmc {cmc}")
        except Exception as e:
            print(f"  ! {c['name']}: {e}")

avg_cmc = round(cmc_total / cmc_count, 2) if cmc_count > 0 else 0
print(f"\nAverage CMC (non-land): {avg_cmc} (from {cmc_count} cards)")

# Build the JSON for DB insertion
output = {
    'commander': 'Lorehold, the Historian',
    'archetype': 'spellslinger_big_spells',
    'color_identity': 'RW',
    'bracket': 3,
    'source_name': 'User provided decklist',
    'source_url': '',
    'source_type': 'user_decklist',
    'deck_name': 'Lorehold Spellslinger',
    'player_name': '',
    'placement': '',
    'tournament_date': '',
    'total_lands': total_lands,
    'avg_cmc': avg_cmc,
    'ramp_count': tag_counts.get('ramp', 0),
    'draw_count': tag_counts.get('draw', 0),
    'removal_count': tag_counts.get('removal', 0),
    'tutor_count': tag_counts.get('tutor', 0),
    'board_wipe_count': tag_counts.get('board_wipe', 0),
    'protection_count': tag_counts.get('protection', 0),
    'wincon_count': tag_counts.get('wincon', 0),
    'engine_count': tag_counts.get('engine', 0),
    'analysis_md_path': f'decks/lorehold-the-historian/{date.today().isoformat()}-user-decklist.md',
    'cards': cards_list,
    'insights': [
        {'text': 'Deck foca em copy spells + treasures para castar big spells e copia-los com Lorehold + Double Vision + Galvanoth', 'category': 'archetype', 'impact': 'high'},
        {'text': '4 board wipes (Austere Command, Obliterate, Jokulhaups, Fated Clash) - no topo do range do profile (3-5)', 'category': 'strategy', 'impact': 'medium'},
        {'text': 'Topdeck manipulation package: Scroll Rack, Sensei Top, Penance, Library of Leng, Land Tax - sinergia direta com Lorehold', 'category': 'engine', 'impact': 'high'},
        {'text': 'Hellkite Tyrant + Insurrection + Storm Herd como wincons alternativos ao dano de big spells', 'category': 'strategy', 'impact': 'medium'}
    ],
    'discrepancies': []
}

print("\n=== DECK SUMMARY ===")
s = {k: v for k, v in output.items() if k != 'cards'}
print(json.dumps(s, indent=2))
print(f"\nCard entries in JSON: {len(output['cards'])}")

# Write seed file
seed_path = 'scripts/seed_lorehold.json'
with open(seed_path, 'w') as f:
    json.dump(output, f, indent=2)
print(f"\nSeed JSON written to {seed_path}")
