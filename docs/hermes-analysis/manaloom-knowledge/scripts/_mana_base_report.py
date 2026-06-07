#!/usr/bin/env python3
"""Generate the Mana Base Validation Report in markdown."""
import sqlite3, json, os, glob
from datetime import datetime, timezone

BASE = "/opt/data/workspace/mtgia"
DB_PATH = f"{BASE}/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"

db = sqlite3.connect(DB_PATH)
db.row_factory = sqlite3.Row
cur = db.cursor()

# Get decks
cur.execute('SELECT id, deck_name, commander_id, total_lands, avg_cmc, ramp_count, draw_count, total_cards, archetype, notes FROM decks ORDER BY id')
decks = [dict(r) for r in cur.fetchall()]

# Get commanders
cur.execute('SELECT id, name FROM commanders')
commanders = {r['id']: r['name'] for r in cur.fetchall()}

# For each deck, count total lands = land-tagged + CMC=0 nonland artifacts/lands
lines = []
now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
lines.append(f"## Mana Base Validation Report (manaloom-mana-base-validator)")
lines.append("")
lines.append(f"> **Data:** {now}")
lines.append(f"> **Cron:** manaloom-mana-base-validator")
lines.append(f"> **Decks analisados:** {len(decks)}")
lines.append(f"> **Profiles:** 24 profiles (3 batch dirs: anchor30 A/B/C)")
lines.append("")

# Profile mapping (from the earlier script)
PROFILES_BASE = f"{BASE}/server/test/artifacts"
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

# --- Summary Table ---
lines.append("### Resumo Geral — Validação vs Perfis EDHREC")
lines.append("")
lines.append("| # | Deck | Cards | Status | Lands (stored) | Perfil Lands | CMC (stored/computed) | Ramp (stored/perfil) | Draw (stored/perfil) | Dados Corrompidos |")
lines.append("|---|------|:---:|:------:|:---:|:------------:|:---:|:---:|:---:|:---|")

for deck in decks:
    did = deck['id']
    cname = commanders.get(deck['commander_id'], f"Unknown")

    # Profile
    profile = None
    for name_variant in [cname, deck['deck_name'].split('—')[0].strip()]:
        pp = find_profile(name_variant)
        if pp:
            profile = load_profile(pp)
            break

    profile_lands = None
    profile_ramp = None
    profile_draw = None
    if profile:
        rt = profile.get('role_targets', {})
        if 'lands' in rt:
            profile_lands = f"{rt['lands']['min']}-{rt['lands']['max']}"
        if 'ramp' in rt:
            profile_ramp = f"{rt['ramp']['min']}-{rt['ramp']['max']}"
        if 'ramp_fixing' in rt:
            profile_ramp = f"{rt['ramp_fixing']['min']}-{rt['ramp_fixing']['max']}"
        if 'ramp_extra_lands' in rt:
            profile_ramp = f"{rt['ramp_extra_lands']['min']}-{rt['ramp_extra_lands']['max']}"
        if 'draw_value' in rt:
            profile_draw = f"{rt['draw_value']['min']}-{rt['draw_value']['max']}"
        if 'card_advantage' in rt:
            profile_draw = f"{rt['card_advantage']['min']}-{rt['card_advantage']['max']}"
        if 'supplemental_draw' in rt:
            profile_draw = f"{rt['supplemental_draw']['min']}-{rt['supplemental_draw']['max']}"

    # Query deck_cards
    cur.execute('SELECT COUNT(*) as ct FROM deck_cards WHERE deck_id=?', (did,))
    card_count = dict(cur.fetchone())['ct']

    cur.execute('''SELECT AVG(cmc) as real_avg_cmc, COUNT(*) as counted
        FROM deck_cards WHERE deck_id=? AND cmc IS NOT NULL AND cmc > 0 AND functional_tag != "land"''', (did,))
    cmc_r = dict(cur.fetchone())
    real_cmc = round(cmc_r['real_avg_cmc'], 2) if cmc_r['real_avg_cmc'] else None

    cur.execute('SELECT COUNT(*) FROM deck_cards WHERE deck_id=? AND (cmc IS NULL OR cmc = 0.0)', (did,))
    cmc_null = dict(cur.fetchone())['COUNT(*)']

    cur.execute('SELECT COUNT(*) FROM deck_cards WHERE deck_id=? AND (functional_tag IS NULL OR functional_tag = "" OR functional_tag = "unknown")', (did,))
    tag_null = dict(cur.fetchone())['COUNT(*)']

    # Status
    status = "OK"
    if card_count < 50:
        status = "INCOMPLETE"
    if not profile:
        status = "NO PROFILE"
    if cmc_null > card_count * 0.25:
        if status == "OK":
            status = "CMC CORRUPT"

    # CMC display
    cmc_disp = f"{deck['avg_cmc']}/{real_cmc}" if real_cmc and abs(deck['avg_cmc'] - real_cmc) > 0.1 else f"{deck['avg_cmc']}/{real_cmc} ⚠️" if real_cmc and abs(deck['avg_cmc'] - real_cmc) > 0.05 else f"{deck['avg_cmc']}"

    # Profile display
    prof_lands_disp = profile_lands or "—"
    prof_ramp_disp = profile_ramp or "—"
    prof_draw_disp = profile_draw or "—"

    # Ramp display
    ramp_disp = f"{deck['ramp_count']}/{prof_ramp_disp}"
    draw_disp = f"{deck['draw_count']}/{prof_draw_disp}"

    # Corruption flags
    corr = []
    if cmc_null > 0:
        corr.append(f"CMC NULL/0: {cmc_null}/{card_count} ({round(100*cmc_null/card_count)}%)")
    if tag_null > 0:
        corr.append(f"tag NULL: {tag_null}/{card_count} ({round(100*tag_null/card_count)}%)")
    if abs(deck['avg_cmc'] - real_cmc) > 0.3 and real_cmc:
        corr.append(f"CMC delta: {round(deck['avg_cmc'] - real_cmc, 2)}")
    corr_str = "; ".join(corr) if corr else "✅"

    short_name = deck['deck_name'][:45] + ('...' if len(deck['deck_name']) > 45 else '')

    lines.append(f"| {did} | {short_name} | {card_count} | {status} | {deck['total_lands']} | {prof_lands_disp} | {cmc_disp} | {ramp_disp} | {draw_disp} | {corr_str} |")

lines.append("")
lines.append("*Legenda: OK | INCOMPLETE (<50 cards) | NO PROFILE | CMC CORRUPT (>25% NULL)*")
lines.append("")

# --- Detailed Analysis ---
lines.append("### Diagnóstico Detalhado")
lines.append("")

for deck in decks:
    did = deck['id']
    cname = commanders.get(deck['commander_id'], "Unknown")

    # Count lands in deck_cards
    cur.execute('SELECT COUNT(*) FROM deck_cards WHERE deck_id=? AND functional_tag="land"', (did,))
    land_tagged = dict(cur.fetchone())['COUNT(*)']

    # Count actual land cards (type_line like '%Land%' or functional_tag = 'land')
    cur.execute('SELECT COUNT(*) FROM deck_cards WHERE deck_id=? AND (functional_tag="land" OR type_line LIKE "%Land%")', (did,))
    land_actual = dict(cur.fetchone())['COUNT(*)']

    # Profile
    profile = None
    for name_variant in [cname, deck['deck_name'].split('—')[0].strip()]:
        pp = find_profile(name_variant)
        if pp:
            profile = load_profile(pp)
            break

    lines.append(f"#### Deck #{did}: {deck['deck_name']}")
    lines.append(f"- **Commander:** {cname} | **Archetype:** {deck['archetype']}")
    lines.append(f"- **Cards in DB:** {land_actual} (tagged as land: {land_tagged}) | **Stored total_lands:** {deck['total_lands']}")

    if profile:
        rt = profile.get('role_targets', {})
        lands_range = rt.get('lands', {})
        lines.append(f"- **Profile lands range:** {lands_range.get('min')}-{lands_range.get('max')} | Status: {'✅ IN RANGE' if lands_range.get('min', 0) <= deck['total_lands'] <= lands_range.get('max', 99) else '⚠️ OUT OF RANGE'}")

        # Check ramp
        for rk in ['ramp', 'ramp_fixing', 'ramp_extra_lands', 'ramp_treasure']:
            if rk in rt:
                ramp_range = rt[rk]
                in_range = ramp_range['min'] <= deck['ramp_count'] <= ramp_range['max']
                lines.append(f"- **Profile ramp ({rk}):** {ramp_range['min']}-{ramp_range['max']} | Stored: {deck['ramp_count']} | {'✅' if in_range else '⚠️'}")

        # Check draw
        for dk in ['draw_value', 'card_advantage', 'supplemental_draw', 'draw']:
            if dk in rt:
                draw_range = rt[dk]
                in_range = draw_range['min'] <= deck['draw_count'] <= draw_range['max']
                lines.append(f"- **Profile draw ({dk}):** {draw_range['min']}-{draw_range['max']} | Stored: {deck['draw_count']} | {'✅' if in_range else '⚠️'}")
    else:
        lines.append(f"- **Profile:** NÃO ENCONTRADO — {cname} não está nos 24 profiles anchor30")
        lines.append(f"- **Stored ramp:** {deck['ramp_count']} | **Stored draw:** {deck['draw_count']}")

    lines.append("")

lines.append("---")
lines.append("### CMC Corruption — Análise Sistêmica 🔴")
lines.append("")
lines.append("| Deck | Stored CMC | Computed CMC (nonland, >0) | Delta | CMC NULL/0 | % NULL |")
lines.append("|------|:----------:|:--------------------------:|:-----:|:----------:|:-----:|")

for deck in decks:
    did = deck['id']
    cur.execute('''SELECT AVG(cmc) as real_avg_cmc, COUNT(*) as counted
        FROM deck_cards WHERE deck_id=? AND cmc IS NOT NULL AND cmc > 0 AND functional_tag != "land"''', (did,))
    cmc_r = dict(cur.fetchone())
    real_cmc = round(cmc_r['real_avg_cmc'], 2) if cmc_r['real_avg_cmc'] else 0
    cur.execute('SELECT COUNT(*) FROM deck_cards WHERE deck_id=? AND (cmc IS NULL OR cmc = 0.0)', (did,))
    cmc_null = dict(cur.fetchone())['COUNT(*)']

    delta = round(deck['avg_cmc'] - real_cmc, 2)
    flag = "🔴" if abs(delta) > 0.5 else "⚠️" if abs(delta) > 0.2 else "✅"

    cur.execute('SELECT COUNT(*) FROM deck_cards WHERE deck_id=?', (did,))
    total = dict(cur.fetchone())['COUNT(*)']
    pct = round(100*cmc_null/total) if total > 0 else 0

    lines.append(f"| {did} | {deck['avg_cmc']} | {real_cmc} | {delta:+} {flag} | {cmc_null} | {pct}% |")

lines.append("")
lines.append(f"**Hipótese:** CMC=0 é usado para lands (correto) mas também para Chrome Mox, Everflowing Chalice, Astral Cornucopia, etc. (incorreto — deveria ter CMC 0, mas estes são artifact ramp, não land). A exclusão de CMC=0 distorce a média para cima. O cálculo stored provavelmente inclui CMC=0.")
lines.append("")

lines.append("---")
lines.append(f"*Validação gerada por manaloom-mana-base-validator em {now}*")

db.close()

print('\n'.join(lines))
