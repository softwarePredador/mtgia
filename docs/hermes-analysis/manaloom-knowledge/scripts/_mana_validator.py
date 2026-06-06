#!/usr/bin/env python3
"""Mana Base Validator — validates decks against EDHREC profiles in SQLite + filesystem"""
import sqlite3, json, os, sys, datetime
from pathlib import Path

DB = '/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'
PROFILE_BASE = '/opt/data/workspace/mtgia/server/test/artifacts'

# Commander -> (batch, filename) mapping
PROFILE_MAP = {
    'Kinnan, Bonder Prodigy': ('a', 'kinnan_bonder_prodigy'),
    "Yuriko, the Tiger's Shadow": ('a', 'yuriko_the_tigers_shadow'),
    'Korvold, Fae-Cursed King': ('a', 'korvold_fae_cursed_king'),
    'Teysa Karlov': ('b', 'teysa_karlov'),
    'Aesi, Tyrant of Gyre Strait': ('b', 'aesi_tyrant_of_gyre_strait'),
    'Lorehold, the Historian': None,  # No profile exists
    'Winota, Joiner of Forces': ('a', 'winota_joiner_of_forces'),
    "Atraxa, Praetors' Voice": ('a', 'atraxa_praetors_voice'),
}

# Profile role key -> tag_metrics key mapping (used to match commander-specific profile keys to standard functional tags)
PROFILE_ROLE_TO_TAG = {
    # Lands
    'lands': 'lands',
    # Ramp variants
    'ramp': 'ramp', 'ramp_fixing': 'ramp', 'ramp_extra_lands': 'ramp',
    'ramp_treasure': 'ramp', 'ramp_rocks': 'ramp', 'ramp_any': 'ramp',
    'mana_dorks': 'ramp', 'mana_creatures': 'ramp', 'nonland_mana_sources': 'ramp',
    'rituals': 'ramp', 'artifact_mana': 'ramp', 'treasure_generation': 'ramp',
    # Draw variants
    'draw': 'draw', 'supplemental_draw': 'draw', 'draw_value': 'draw',
    'card_advantage': 'draw',
    # Removal / Interaction
    'removal': 'removal', 'interaction': 'removal',
    'interaction_counter': 'removal', 'replayable_interaction': 'removal',
    'interaction_protection': 'protection',
    # Tutors
    'tutor': 'tutor', 'tutors': 'tutor',
    # Board wipes
    'board_wipe': 'board_wipe', 'wipe': 'board_wipe',
    'board_wipes_bounce': 'board_wipe',
    # Protection
    'protection': 'protection', 'graveyard_protection': 'protection',
    'stax_disruption': 'protection',
    # Wincons / Finishers
    'wincon': 'wincon', 'finishers': 'wincon',
    'combo_finishers': 'wincon', 'storm_combo': 'wincon',
    # Recursion
    'recursion': 'recursion', 'recursion_value': 'recursion',
    'land_recursion_bounce': 'recursion',
    # Engines / Payoffs (catch-all for commander-specific categories)
    'engine': 'engine', 'big_spell': 'engine',
    'counter_payoffs': 'engine', 'proliferate_engines': 'engine',
    'planeswalkers_superfriends': 'engine', 'landfall_payoffs': 'engine',
    'payoffs_outlets': 'engine', 'sacrifice_fodder': 'engine',
    'sacrifice_outlets': 'engine', 'aristocrat_payoffs': 'engine',
    'self_mill': 'engine', 'exile_casting': 'engine',
    'treasure_payoffs': 'engine', 'nonhuman_enablers': 'engine',
    'human_hits': 'engine', 'combat_payoffs': 'engine',
    'evasive_enablers': 'engine', 'ninjas': 'engine',
    'topdeck_manipulation': 'engine', 'high_mv_reveals': 'engine',
    'cheap_creature_density': 'engine', 'bounce_loop_pieces': 'engine',
    'infinite_mana_pieces': 'engine',
}
# Alias for backward compat
ROLE_COL_MAP = PROFILE_ROLE_TO_TAG

ROLE_DISPLAY = {
    'lands': 'Lands',
    'ramp': 'Ramp',
    'draw': 'Draw',
    'removal': 'Removal',
    'interaction': 'Interaction',
    'tutor': 'Tutor',
    'board_wipe': 'Board Wipe',
    'wipe': 'Board Wipe',
    'protection': 'Protection',
    'wincon': 'Wincon',
    'finishers': 'Finishers',
    'recursion': 'Recursion',
    'engine': 'Engine',
    'nonland_mana_sources': 'Nonland Mana',
}

def check_range(val, min_v, max_v):
    if val is None:
        return 'N/A', 0
    diff = max(min_v - val, 0) if val < min_v else max(val - max_v, 0)
    if diff == 0:
        return 'OK', 0
    elif diff == 1:
        return 'BLUE', 1
    elif diff <= 3:
        return 'WARN', diff
    else:
        return 'CRIT', diff

def load_profile(commander_name):
    info = PROFILE_MAP.get(commander_name)
    if info is None:
        return None
    batch, fname = info
    path = Path(PROFILE_BASE) / f'commander_reference_profile_anchor30_batch_{batch}_2026-05-12' / 'profiles' / f'{fname}.json'
    if path.exists():
        with open(path) as f:
            return json.load(f)
    return None

def main():
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    # Get commanders
    cur.execute("SELECT id, name FROM commanders ORDER BY id")
    commanders = {r['id']: r['name'] for r in cur.fetchall()}

    # Get decks with tag-based metrics
    cur.execute("""
    SELECT d.id, d.deck_name, d.commander_id, d.archetype, d.notes,
      COALESCE(SUM(dc.quantity), 0) as total_cards,
      COALESCE(SUM(CASE WHEN dc.functional_tag='land' THEN dc.quantity ELSE 0 END), 0) as lands_tag,
      COALESCE(SUM(CASE WHEN dc.functional_tag='ramp' THEN dc.quantity ELSE 0 END), 0) as ramp_tag,
      COALESCE(SUM(CASE WHEN dc.functional_tag='draw' THEN dc.quantity ELSE 0 END), 0) as draw_tag,
      COALESCE(SUM(CASE WHEN dc.functional_tag='removal' THEN dc.quantity ELSE 0 END), 0) as removal_tag,
      COALESCE(SUM(CASE WHEN dc.functional_tag='tutor' THEN dc.quantity ELSE 0 END), 0) as tutor_tag,
      COALESCE(SUM(CASE WHEN dc.functional_tag='board_wipe' THEN dc.quantity ELSE 0 END), 0) as board_wipe_tag,
      COALESCE(SUM(CASE WHEN dc.functional_tag='protection' THEN dc.quantity ELSE 0 END), 0) as protection_tag,
      COALESCE(SUM(CASE WHEN dc.functional_tag='recursion' THEN dc.quantity ELSE 0 END), 0) as recursion_tag,
      COALESCE(SUM(CASE WHEN dc.functional_tag='wincon' THEN dc.quantity ELSE 0 END), 0) as wincon_tag,
      COALESCE(SUM(CASE WHEN dc.functional_tag='engine' THEN dc.quantity ELSE 0 END), 0) as engine_tag,
      COALESCE(SUM(CASE WHEN dc.functional_tag='unknown' THEN dc.quantity ELSE 0 END), 0) as unknown_tag,
      ROUND(AVG(dc.cmc), 2) as avg_cmc
    FROM decks d
    LEFT JOIN deck_cards dc ON dc.deck_id = d.id
    GROUP BY d.id
    ORDER BY d.id
    """)

    results = []
    now = datetime.datetime.now(datetime.timezone.utc)

    for row in cur.fetchall():
        d = dict(row)
        deck_id = d['id']
        cmd_name = commanders.get(d['commander_id'], 'Unknown')

        tag_metrics = {
            'lands': d['lands_tag'],
            'ramp': d['ramp_tag'],
            'draw': d['draw_tag'],
            'removal': d['removal_tag'],
            'interaction': d['removal_tag'],
            'tutor': d['tutor_tag'],
            'board_wipe': d['board_wipe_tag'],
            'wipe': d['board_wipe_tag'],
            'protection': d['protection_tag'],
            'wincon': d['wincon_tag'],
            'finishers': d['wincon_tag'],
            'recursion': d['recursion_tag'],
            'engine': d['engine_tag'],
        }

        total_cards = d['total_cards']
        if total_cards < 50:
            results.append({
                'deck_id': deck_id,
                'deck_name': d['deck_name'],
                'commander': cmd_name,
                'total_cards': total_cards,
                'status': 'INCOMPLETE',
                'status_emoji': '⚪',
                'profile_loaded': False,
                'notes': [f'Apenas {int(total_cards)} cartas inseridas (seed parcial)'],
                'metrics': [],
                'archetype': d['archetype'],
            })
            continue

        profile = load_profile(cmd_name)
        profile_loaded = profile is not None

        archetype_mismatch = False
        if profile_loaded and d['archetype']:
            pthemes = [t['name'].lower() for t in profile.get('themes', [])]
            deck_archetype = (d['archetype'] or '').lower()
            spell_themes = any('spell' in t for t in pthemes)
            combo_archetypes = any(w in deck_archetype for w in ['combo', 'fast-mana', 'turbo'])
            if spell_themes and combo_archetypes:
                archetype_mismatch = True

        metrics = []
        if profile_loaded and not archetype_mismatch:
            role_targets = profile.get('role_targets', {})
            for role_key, role_target in role_targets.items():
                min_v = role_target.get('min', 0)
                max_v = role_target.get('max', 0)
                # Map profile role key to standard tag metric via ROLE_COL_MAP
                mapped_key = ROLE_COL_MAP.get(role_key, role_key)
                tag_val = tag_metrics.get(mapped_key)
                if tag_val is None:
                    # Try direct lookup as fallback (for profile keys that ARE standard)
                    tag_val = tag_metrics.get(role_key)
                if tag_val is None:
                    continue
                status, diff = check_range(tag_val, min_v, max_v)
                display = ROLE_DISPLAY.get(role_key, role_key)
                if status != 'OK' or role_key == 'lands':
                    metrics.append({
                        'role': display,
                        'role_key': role_key,
                        'value': tag_val,
                        'min': min_v,
                        'max': max_v,
                        'status': status,
                        'diff': diff,
                    })

        notes = []
        if profile_loaded and archetype_mismatch:
            notes.append(f'Archetype mismatch: profile built for spellslinger, deck is {d["archetype"]}')
        if not profile_loaded:
            notes.append(f'Sem perfil EDHREC para {cmd_name}')
        if d['unknown_tag'] > 0:
            notes.append(f'{int(d["unknown_tag"])} cartas com tag "unknown" (classificador corrompido)')

        has_crit = any(m['status'] == 'CRIT' for m in metrics)
        has_warn = any(m['status'] == 'WARN' for m in metrics)
        has_blue = any(m['status'] == 'BLUE' for m in metrics)

        if archetype_mismatch:
            status = 'MISMATCH'
            status_emoji = '⚠️'
        elif not profile_loaded:
            status = 'NO_PROFILE'
            status_emoji = '⚠️'
        elif has_crit:
            status = 'CRIT'
            status_emoji = '🔴'
        elif has_warn:
            status = 'WARN'
            status_emoji = '🟡'
        elif has_blue:
            status = 'BLUE'
            status_emoji = '🔵'
        else:
            status = 'OK'
            status_emoji = '✅'

        results.append({
            'deck_id': deck_id,
            'deck_name': d['deck_name'],
            'commander': cmd_name,
            'total_cards': total_cards,
            'status': status,
            'status_emoji': status_emoji,
            'profile_loaded': profile_loaded,
            'archetype_mismatch': archetype_mismatch,
            'profile_themes': [t['name'] for t in profile.get('themes', [])] if profile else [],
            'notes': notes,
            'metrics': metrics,
            'archetype': d['archetype'],
            'lands_tag': d['lands_tag'],
            'ramp_tag': d['ramp_tag'],
            'draw_tag': d['draw_tag'],
            'unknown_tag': d['unknown_tag'],
            'avg_cmc': d['avg_cmc'],
        })

    conn.close()

    # Output JSON for report generation
    print(json.dumps(results, indent=2, default=str))

if __name__ == '__main__':
    main()
