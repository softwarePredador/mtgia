#!/usr/bin/env python3
"""Mana base validation: decks vs EDHREC profiles."""
import sqlite3, json, os, glob
from datetime import datetime, timezone
from collections import defaultdict

BASE = "/opt/data/workspace/mtgia"
DB_PATH = f"{BASE}/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
PROFILES_BASE = f"{BASE}/server/test/artifacts"

# Map commander names to profile files
COMMANDER_TO_PROFILE = {
    "Kinnan, Bonder Prodigy": "kinnan_bonder_prodigy.json",
    "Yuriko, the Tiger's Shadow": "yuriko_the_tigers_shadow.json",
    "Korvold, Fae-Cursed King": "korvold_fae_cursed_king.json",
    "Teysa Karlov": "teysa_karlov.json",
    "Aesi, Tyrant of Gyre Strait": "aesi_tyrant_of_gyre_strait.json",
    "Winota, Joiner of Forces": "winota_joiner_of_forces.json",
    "Atraxa, Praetors' Voice": "atraxa_praetors_voice.json",
}

def find_profile(commander_name):
    """Find profile JSON for a commander."""
    profile_fn = COMMANDER_TO_PROFILE.get(commander_name)
    if not profile_fn:
        return None
    for root, dirs, files in os.walk(PROFILES_BASE):
        for f in files:
            if f == profile_fn and root.endswith('profiles'):
                return os.path.join(root, f)
    return None

def load_profile(path):
    with open(path) as f:
        return json.load(f)

def validate():
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    cur = db.cursor()

    # Get all decks
    cur.execute('SELECT id, deck_name, commander_id, total_lands, avg_cmc, ramp_count, draw_count, total_cards, archetype, notes FROM decks ORDER BY id')
    decks = [dict(r) for r in cur.fetchall()]

    # Get commander names
    cur.execute('SELECT id, name FROM commanders')
    commanders = {r['id']: r['name'] for r in cur.fetchall()}

    results = []
    now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

    for deck in decks:
        did = deck['id']
        cid = deck['commander_id']
        cname = commanders.get(cid, f"Unknown commander {cid}")
        deck['commander_name'] = cname

        # Compute actual metrics from deck_cards
        cur.execute('SELECT COUNT(*) as card_count, SUM(CASE WHEN functional_tag="land" THEN 1 ELSE 0 END) as land_count FROM deck_cards WHERE deck_id=?', (did,))
        r = dict(cur.fetchone())
        actual_land_count = r['land_count'] or 0

        # Compute CMC excluding lands and NULL/0
        cur.execute('''
            SELECT AVG(cmc) as real_avg_cmc, COUNT(*) as counted
            FROM deck_cards
            WHERE deck_id=? AND cmc IS NOT NULL AND cmc > 0
              AND functional_tag != 'land'
        ''', (did,))
        cmc_r = dict(cur.fetchone())

        # Count by functional_tag
        cur.execute('''
            SELECT functional_tag, COUNT(*) as cnt
            FROM deck_cards
            WHERE deck_id=?
            GROUP BY functional_tag
        ''', (did,))
        tag_counts = {r['functional_tag']: r['cnt'] for r in cur.fetchall()}

        # Count CMC NULL/0
        cur.execute('SELECT COUNT(*) FROM deck_cards WHERE deck_id=? AND (cmc IS NULL OR cmc = 0.0)', (did,))
        cmc_null = dict(cur.fetchone())['COUNT(*)']

        # Get all card names with CMC NULL
        cur.execute('SELECT card_name, cmc, functional_tag FROM deck_cards WHERE deck_id=? AND (cmc IS NULL OR cmc = 0.0) LIMIT 10', (did,))
        cmc_null_cards = [(r['card_name'], r['cmc'], r['functional_tag']) for r in cur.fetchall()]

        # Get all card names with tag IS NULL or ''
        cur.execute('SELECT card_name, functional_tag FROM deck_cards WHERE deck_id=? AND (functional_tag IS NULL OR functional_tag = "" OR functional_tag = "unknown")', (did,))
        tag_null_cards = [(r['card_name'], r['functional_tag']) for r in cur.fetchall()]

        # Find profile
        profile = None
        profile_path = None
        for name_variant in [cname, deck['deck_name'].split('—')[0].strip()]:
            profile_path = find_profile(name_variant)
            if profile_path:
                profile = load_profile(profile_path)
                break

        # Extract profile targets
        profile_lands = None
        profile_cmc = None
        profile_ramp = None
        profile_draw = None
        if profile:
            rt = profile.get('role_targets', {})
            if 'lands' in rt:
                profile_lands = f"{rt['lands']['min']}-{rt['lands']['max']}"
            if 'avg_cmc' in rt:
                profile_cmc = f"{rt['avg_cmc']['min']}-{rt['avg_cmc']['max']}"
            if 'ramp' in rt:
                profile_ramp = f"{rt['ramp']['min']}-{rt['ramp']['max']}"
            if 'draw' in rt:
                profile_draw = f"{rt['draw']['min']}-{rt['draw']['max']}"
            # Some profiles use different keys for ramp/draw
            if not profile_ramp:
                ramp_sources = 0
                ramp_keys = ['mana_dorks', 'artifact_mana', 'nonland_mana_sources', 'ramp']
                for k in ramp_keys:
                    if k in rt:
                        ramp_sources += rt[k]['min']
                if ramp_sources > 0:
                    profile_ramp = f">{ramp_sources - 2}-{ramp_sources + 4}"

            if not profile_draw:
                draw_sources = 0
                draw_keys = ['draw', 'card_draw', 'card_advantage']
                for k in draw_keys:
                    if k in rt:
                        draw_sources += rt[k]['min']
                if draw_sources > 0:
                    profile_draw = f">{draw_sources - 2}-{draw_sources + 4}"

        # Build result
        result = {
            'deck_id': did,
            'deck_name': deck['deck_name'],
            'commander': cname,
            'total_cards': len(cur.execute('SELECT id FROM deck_cards WHERE deck_id=?', (did,)).fetchall()),
            'stored_lands': deck['total_lands'],
            'stored_avg_cmc': deck['avg_cmc'],
            'stored_ramp': deck['ramp_count'],
            'stored_draw': deck['draw_count'],
            'actual_lands': actual_land_count,
            'actual_avg_cmc': round(cmc_r['real_avg_cmc'], 2) if cmc_r['real_avg_cmc'] else None,
            'cmc_counted': cmc_r['counted'],
            'actual_ramp': tag_counts.get('ramp', 0),
            'actual_draw': tag_counts.get('draw', 0),
            'cmc_null_count': cmc_null,
            'cmc_null_cards': cmc_null_cards,
            'tag_null_count': len(tag_null_cards),
            'tag_null_cards': tag_null_cards,
            'tag_counts': tag_counts,
            'profile_name': profile.get('commander', 'N/A') if profile else 'N/A',
            'profile_lands': profile_lands,
            'profile_cmc': profile_cmc,
            'profile_ramp': profile_ramp,
            'profile_draw': profile_draw,
            'profile_role_targets': profile.get('role_targets', {}) if profile else {},
            'has_profile': profile is not None,
            'archetype': deck['archetype'],
            'notes': deck['notes'],
        }
        results.append(result)

    db.close()
    return results, now

if __name__ == '__main__':
    results, now = validate()
    print(json.dumps(results, indent=2, default=str))
    print("---NOW---")
    print(now)
