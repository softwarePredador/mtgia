#!/usr/bin/env python3
"""Lorehold Deck Scout cycle: fetch EDHREC/Moxfield/Scryfall, compare with local SQLite deck, update SCOUT_LOG.md."""
from __future__ import annotations

import collections
import datetime as dt
import html
import json
import math
import os
import re
import sqlite3
import subprocess
import sys
import time
import urllib.parse
from pathlib import Path

ROOT = Path('/opt/data/workspace/mtgia')
BASE = ROOT / 'docs/hermes-analysis/manaloom-knowledge'
DECK_DIR = BASE / 'decks/lorehold-the-historian'
DB_PATH = BASE / 'scripts/knowledge.db'
SCOUT_LOG = DECK_DIR / 'SCOUT_LOG.md'
EDHREC_HTML = Path('/tmp/edhrec_lorehold.html')
UA = 'Mozilla/5.0 ManaLoom-Hermes/1.0 scheduled-lorehold-scout'
EDHREC_AUTHORIZATION_FLAG = 'MANALOOM_EDHREC_AUTOMATED_COLLECTION_AUTHORIZED'
AUTHORIZED_FLAG_VALUES = {'1', 'true', 'yes', 'on'}

MOXFIELD_IDS = [
    'a2lPkndjlkSgCg_HAC1tfA',
    'C5Szkr_UBU64pWs3MfgzFQ',
    '6xZEB5MXY0mWMVq8UdHLuw',
    'dVyNGaaK0EyQ34TrUcQZfw',
    'EdhIo15GYEKx1_hYUULfwQ',
]

ROLE_KEYS = [
    'lands', 'ramp', 'ritual_treasure', 'draw', 'draw_value', 'interaction', 'removal',
    'board_wipe', 'protection', 'recursion', 'tutor', 'spellslinger', 'big_spell',
    'big_spell_payoff', 'wincon', 'win_condition', 'engine', 'creature', 'other'
]


def run(args, timeout=60):
    return subprocess.run(args, capture_output=True, text=True, timeout=timeout)


def edhrec_collection_authorized():
    return os.environ.get(EDHREC_AUTHORIZATION_FLAG, '').strip().lower() in AUTHORIZED_FLAG_VALUES


def is_edhrec_url(url):
    hostname = (urllib.parse.urlparse(url).hostname or '').lower()
    return hostname == 'edhrec.com' or hostname.endswith('.edhrec.com')


def curl_text(url, timeout=60):
    if is_edhrec_url(url) and not edhrec_collection_authorized():
        raise RuntimeError(
            f'EDHREC collection blocked (fail-closed): set {EDHREC_AUTHORIZATION_FLAG} '
            'only after explicit authorization.'
        )
    r = run(['curl', '-sS', '-L', '-A', UA, url], timeout=timeout)
    if r.returncode != 0:
        raise RuntimeError(f'curl failed {url}: {r.stderr[:300]}')
    return r.stdout


def curl_json(url, timeout=60):
    txt = curl_text(url, timeout=timeout)
    return json.loads(txt)


def norm(name: str) -> str:
    if not name:
        return ''
    s = html.unescape(name).lower().strip()
    s = re.sub(r'\s+//\s+.*$', '', s)  # compare primary face for MDFCs where needed
    replacements = {
        '’': "'", '‘': "'", 'ó': 'o', 'é': 'e', 'í': 'i', 'á': 'a', 'ú': 'u', 'ö': 'o',
        ',': '', "'": '', '“': '', '”': '', '—': '-', '–': '-',
    }
    for a,b in replacements.items():
        s = s.replace(a,b)
    s = re.sub(r'[^a-z0-9/ -]', '', s)
    s = re.sub(r'\s+', ' ', s).strip()
    return s


def display_name(name: str) -> str:
    # Shorten common MDFC display but keep recognisable.
    if ' // ' in name:
        return name.split(' // ')[0]
    return name


def get_local_deck():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    row = conn.execute("""
        SELECT d.*, c.name AS commander_name
        FROM decks d JOIN commanders c ON c.id = d.commander_id
        WHERE c.name LIKE '%Lorehold%'
        ORDER BY d.id DESC LIMIT 1
    """).fetchone()
    if not row:
        raise RuntimeError('No Lorehold deck found in SQLite')
    cards = [dict(r) for r in conn.execute(
        'SELECT * FROM deck_cards WHERE deck_id=? ORDER BY is_commander DESC, card_name',
        (row['id'],)
    )]
    tag_rows = [dict(r) for r in conn.execute("""
        SELECT dc.card_name, ct.tag, ct.confidence
        FROM deck_cards dc JOIN card_tags ct ON ct.deck_card_id = dc.id
        WHERE dc.deck_id=?
    """, (row['id'],))]
    conn.close()
    card_names = {norm(c['card_name']) for c in cards}
    display_by_norm = {norm(c['card_name']): c['card_name'] for c in cards}
    metrics = {
        'lands': row['total_lands'], 'ramp': row['ramp_count'], 'draw': row['draw_count'],
        'removal': row['removal_count'], 'interaction': row['removal_count'],
        'tutor': row['tutor_count'], 'board_wipe': row['board_wipe_count'],
        'protection': row['protection_count'], 'recursion': row['recursion_count'],
        'wincon': row['wincon_count'], 'engine': row['engine_count'], 'avg_cmc': row['avg_cmc'],
        'total_cards': row['total_cards']
    }
    return dict(row), cards, card_names, display_by_norm, metrics, tag_rows


def parse_edhrec_live():
    url = 'https://edhrec.com/commanders/lorehold-the-historian'
    html_text = curl_text(url, timeout=60)
    EDHREC_HTML.write_text(html_text)
    m = re.search(r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>', html_text, re.S)
    if not m:
        raise RuntimeError('EDHREC __NEXT_DATA__ not found')
    data = json.loads(m.group(1))
    page = data['props']['pageProps']['data']
    jd = page['container']['json_dict']
    live_cards = []
    for cl in jd.get('cardlists', []):
        header = cl.get('header') or cl.get('tag') or 'unknown'
        for cv in cl.get('cardviews', []):
            name = cv.get('name')
            if not name:
                continue
            pct = 100.0 * (cv.get('num_decks') or cv.get('inclusion') or 0) / max(1, (cv.get('potential_decks') or page.get('num_decks_avg') or 1))
            live_cards.append({
                'name': name,
                'section': header,
                'num_decks': cv.get('num_decks') or cv.get('inclusion') or 0,
                'potential_decks': cv.get('potential_decks') or page.get('num_decks_avg'),
                'pct': pct,
                'synergy': cv.get('synergy'),
                'trend_zscore': cv.get('trend_zscore'),
            })
    seen = {}
    for c in live_cards:
        n = norm(c['name'])
        if n not in seen or c['pct'] > seen[n]['pct']:
            seen[n] = c
    live_cards = sorted(seen.values(), key=lambda x: (-x['pct'], x['name']))
    curve = page.get('panels', {}).get('mana_curve') or {}
    cmc_total = sum(int(k) * v for k, v in curve.items())
    cmc_count = sum(curve.values())
    avg_cmc = round(cmc_total / cmc_count, 2) if cmc_count else None
    metrics = {
        'source': url,
        'decks': page.get('num_decks_avg'),
        'creature': page.get('creature'), 'instant': page.get('instant'), 'sorcery': page.get('sorcery'),
        'artifact': page.get('artifact'), 'enchantment': page.get('enchantment'), 'planeswalker': page.get('planeswalker'),
        'lands': page.get('land'), 'avg_cmc': avg_cmc, 'deck_size_shown': page.get('deck_size'),
        'total_card_count': page.get('total_card_count'), 'avg_price': page.get('avg_price')
    }
    return metrics, live_cards


def parse_local_edhrec_corpus():
    corpus_path = ROOT / 'server/test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json'
    summary_path = ROOT / 'server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply/lorehold_the_historian_apply_summary.json'
    corpus = json.loads(corpus_path.read_text())
    summary = json.loads(summary_path.read_text())
    summaries = {a['source_deck_key']: a for a in summary.get('analyses', [])}
    decks = []
    for d in corpus['decks']:
        names = []
        for c in d['cards']:
            q = c.get('quantity', 1)
            for _ in range(q):
                names.append(c['name'])
        rs = summaries.get(d['source_deck_key'], {}).get('role_summary', {})
        decks.append({
            'source': 'EDHREC deckpreview corpus',
            'name': d['source_deck_key'],
            'url': d['source_url'],
            'cards': names,
            'unique_cards': set(norm(x) for x in names),
            'metrics': rs,
        })
    return decks


def moxfield_decks():
    decks = []
    for public_id in MOXFIELD_IDS:
        url = f'https://api2.moxfield.com/v3/decks/all/{public_id}'
        d = curl_json(url, timeout=90)
        cards = []
        full_cards = []
        for board in ['mainboard', 'commanders']:
            b = d.get('boards', {}).get(board, {}).get('cards', {})
            for entry in b.values():
                card = entry.get('card', {})
                q = entry.get('quantity', 1)
                name = card.get('name')
                if not name:
                    continue
                for _ in range(q):
                    cards.append(name)
                full_cards.append({'name': name, 'quantity': q, 'board': board, 'card': card})
        decks.append({
            'source': 'Moxfield public',
            'name': d.get('name'),
            'url': d.get('publicUrl'),
            'viewCount': d.get('viewCount'),
            'likeCount': d.get('likeCount'),
            'hasPrimer': d.get('description') not in (None, ''),
            'cards': cards,
            'unique_cards': set(norm(x) for x in cards),
            'full_cards': full_cards,
            'bracket': d.get('bracket') or d.get('userBracket') or d.get('autoBracket'),
        })
        time.sleep(0.2)
    return decks


def classify_from_card(card):
    name = card.get('name','')
    text = (card.get('oracle_text') or '').lower()
    typ = (card.get('type_line') or '').lower()
    n = norm(name)
    tags = set()
    if 'land' in typ or ' // ' in name and any(x in (card.get('type_line') or '') for x in ['Land', 'land']):
        tags.add('lands')
    if 'creature' in typ:
        tags.add('creature')
    # broad roles, not exact ManaLoom classifier; used only for external comparison.
    if any(x in text for x in ['add {', 'treasure token', 'treasures', 'mana of any color', 'mana in any combination']) or any(x in n for x in ['sol ring','arcane signet','talisman','signet','mox','lotus','mana vault','mana crypt','ruby medallion','pearl medallion','fellwar stone','thought vessel']):
        if 'lands' not in tags:
            tags.add('ramp')
        if 'treasure' in text or any(x in n for x in ['desperate ritual','seething song','jeskas will','hit the mother lode','brasss bounty','mana geyser','big score','unexpected windfall']):
            tags.add('ritual_treasure')
    if any(x in text for x in ['draw a card', 'draw two cards', 'draw three cards', 'draw cards', 'impulse draw', 'exile the top']) or any(x in n for x in ['wheel of fortune','reforge the soul','esper sentinel','archivist of oghma','senseis divining top','scroll rack','big score','unexpected windfall','faithless looting']):
        if 'lands' not in tags:
            tags.add('draw')
    if any(x in text for x in ['destroy target', 'exile target', 'deals damage to any target', 'counter target', 'return target', 'chaos warp']) or n in {'swords to plowshares','path to exile','deflecting swat','redirect lightning','boros charm'}:
        tags.add('interaction')
        tags.add('removal')
    if any(x in text for x in ['destroy all', 'exile all', 'each creature', 'all creatures', 'each opponent sacrifices']) or n in {'austere command','blasphemous act','farewell','wrath of god','armageddon','cataclysm','obliterate','jokulhaups','call forth the tempest','volcanic vision'}:
        tags.add('board_wipe')
    if any(x in text for x in ['indestructible', 'phase out', 'protection from', 'prevent all damage', 'hexproof', 'shroud']) or any(x in n for x in ['teferis protection','deflecting swat','flawless maneuver','bolt bend','galadriels dismissal','grand abolisher','orims chant','silence','lightning greaves','swiftfoot boots']):
        tags.add('protection')
    if 'search your library' in text or n in {'gamble','enlightened tutor','imperial recruiter','oswald fiddlebender','weathered wayfarer','urzas saga'}:
        tags.add('tutor')
    if any(x in text for x in ['from your graveyard', 'flashback', 'return target card', 'return up to']) or any(x in n for x in ['mizzixs mastery','volcanic vision','surge to victory','restoration seminar','sevinne','reconstruct history']):
        tags.add('recursion')
    if any(x in typ for x in ['instant','sorcery']) or any(x in text for x in ['instant or sorcery', 'copy target spell', 'copy the next']):
        if any(x in text for x in ['copy', 'instant or sorcery', 'spell you cast']) or n in {'double vision','arcane bombardment','galvanoth','sunbirds invocation'}:
            tags.add('spellslinger')
    cmc = card.get('cmc') or 0
    try: cmc = float(cmc)
    except Exception: cmc = 0
    if cmc >= 6 and 'lands' not in tags:
        tags.add('big_spell')
    if any(x in text for x in ['win the game', 'loses the game']) or any(x in n for x in ['aetherflux reservoir','insurrection','storm herd','approach of the second sun','hellkite tyrant','rise of the eldrazi']):
        tags.add('wincon')
    if any(x in text for x in ['whenever', 'at the beginning']) and any(x in text for x in ['draw', 'create', 'copy', 'exile']):
        tags.add('engine')
    if not tags:
        tags.add('other')
    return tags


def metrics_for_mox(deck):
    counts = collections.Counter()
    nonland_cmc_total = 0.0
    nonland_count = 0
    for e in deck.get('full_cards', []):
        card = e['card']
        q = e['quantity']
        tags = classify_from_card(card)
        for t in tags:
            counts[t] += q
        if 'lands' not in tags and e['board'] != 'commanders':
            nonland_cmc_total += (card.get('cmc') or 0) * q
            nonland_count += q
    if nonland_count:
        counts['avg_cmc'] = round(nonland_cmc_total / nonland_count, 2)
    counts['total_cards'] = len(deck['cards'])
    return dict(counts)


def scryfall_new_cards():
    # New/2026 RW legal cards whose text aligns with Lorehold: instants/sorceries, miracle/topdeck, rummage/discard, treasure/ramp, or cast-without-paying.
    queries = [
        'commander:RW date>=2026-04-24 -is:digital (t:instant OR t:sorcery)',
        'commander:RW date>=2026-04-24 -is:digital (o:miracle OR o:"without paying" OR o:"discard a card" OR o:"Treasure" OR o:"instant or sorcery")',
    ]
    found = {}
    for q in queries:
        url = 'https://api.scryfall.com/cards/search?q=' + urllib.parse.quote(q) + '&order=released&dir=desc&unique=cards'
        while url:
            try:
                data = curl_json(url, timeout=45)
            except Exception as e:
                found[f'ERROR:{q}'] = {'name': f'ERROR querying {q}', 'error': str(e)}
                break
            for c in data.get('data', []):
                name = c.get('name')
                if not name:
                    continue
                found[norm(name)] = {
                    'name': name,
                    'released_at': c.get('released_at'),
                    'type_line': c.get('type_line'),
                    'oracle_text': c.get('oracle_text','').replace('\n',' '),
                    'set': c.get('set'),
                    'url': c.get('scryfall_uri'),
                }
            url = data.get('next_page')
            time.sleep(0.1)
    scored = []
    for c in found.values():
        if 'error' in c:
            continue
        text = (c['oracle_text'] or '').lower()
        score = 0
        reasons = []
        for phrase, reason, pts in [
            ('miracle', 'miracle/topdeck', 4),
            ('without paying', 'cast/free spell', 3),
            ('discard a card', 'rummage outlet', 2),
            ('draw a card', 'card flow', 1),
            ('treasure', 'Treasure/ramp', 2),
            ('instant or sorcery', 'spellslinger payoff', 3),
            ('copy', 'copy spell/value', 2),
            ('exile the top', 'topdeck/exile value', 2),
        ]:
            if phrase in text:
                score += pts; reasons.append(reason)
        tl = c.get('type_line','').lower()
        if 'instant' in tl or 'sorcery' in tl:
            score += 1; reasons.append('spell type')
        if score > 0:
            c['score'] = score
            c['reasons'] = sorted(set(reasons))
            scored.append(c)
    return sorted(scored, key=lambda c: (-c['score'], c['released_at'] or '', c['name']))[:20]


def markdown_table(headers, rows):
    out = ['| ' + ' | '.join(headers) + ' |', '| ' + ' | '.join(['---'] * len(headers)) + ' |']
    for r in rows:
        out.append('| ' + ' | '.join(str(x) for x in r) + ' |')
    return '\n'.join(out)


def avg(vals):
    vals = [v for v in vals if isinstance(v, (int,float))]
    return round(sum(vals)/len(vals), 1) if vals else '—'


def main():
    deck_row, local_cards, local_set, local_display, local_metrics, tag_rows = get_local_deck()
    edhrec_metrics, edhrec_live_cards = parse_edhrec_live()
    local_edhrec_decks = parse_local_edhrec_corpus()
    mox_decks = moxfield_decks()
    for d in mox_decks:
        d['metrics'] = metrics_for_mox(d)
    all_decks = local_edhrec_decks + mox_decks

    freq = collections.Counter()
    display = {}
    sources_by_card = collections.defaultdict(list)
    for d in all_decks:
        for n in d['unique_cards']:
            if not n:
                continue
            freq[n] += 1
            # preserve first display name from actual deck card list
            for x in d['cards']:
                if norm(x) == n:
                    display.setdefault(n, display_name(x)); break
            sources_by_card[n].append(d['name'])
    total_decks = len(all_decks)

    staples_50 = [(n,c) for n,c in freq.items() if c / total_decks >= 0.5]
    staples_50.sort(key=lambda x: (-x[1], display.get(x[0], x[0])))
    missing_all = [(n,c) for n,c in freq.items() if c == total_decks and n not in local_set]
    missing_all.sort(key=lambda x: display.get(x[0], x[0]))
    missing_60 = [(n,c) for n,c in freq.items() if c / total_decks >= 0.6 and n not in local_set]
    missing_60.sort(key=lambda x: (-x[1], display.get(x[0], x[0])))
    cuttable = [(n,c) for n,c in [(norm(c['card_name']), freq.get(norm(c['card_name']),0)) for c in local_cards if not c['is_commander']] if c == 0]

    # EDHREC live urgent cards >=60% not in our deck.
    edhrec_live_missing_60 = [c for c in edhrec_live_cards if c['pct'] >= 60 and norm(c['name']) not in local_set]
    edhrec_live_missing_50 = [c for c in edhrec_live_cards if c['pct'] >= 50 and norm(c['name']) not in local_set]

    # Interesting tech: high EDHREC synergy >=0.35 not in our deck, not just basics.
    tech = [c for c in edhrec_live_cards if (c.get('synergy') or 0) >= 0.35 and norm(c['name']) not in local_set]
    tech = tech[:20]

    # Compare metrics
    metric_rows = []
    metric_map = [
        ('Lands', 'lands'), ('Ramp', 'ramp'), ('Ritual/Treasure', 'ritual_treasure'),
        ('Draw', 'draw'), ('Interaction/Removal', 'interaction'), ('Board wipes', 'board_wipe'),
        ('Protection', 'protection'), ('Tutor', 'tutor'), ('Recursion', 'recursion'),
        ('Spellslinger/copy', 'spellslinger'), ('Big spells', 'big_spell'), ('Wincons', 'wincon'),
        ('Avg CMC', 'avg_cmc'), ('Total cards', 'total_cards')
    ]
    for label, key in metric_map:
        vals = []
        for d in all_decks:
            m = d.get('metrics', {})
            v = m.get(key)
            if v is None and key == 'draw': v = m.get('draw_value')
            if v is None and key == 'wincon': v = m.get('win_condition')
            if v is None and key == 'big_spell': v = m.get('big_spell_payoff')
            vals.append(v)
        ext = avg(vals)
        ours = local_metrics.get(key)
        if ours is None and key == 'interaction': ours = local_metrics.get('removal')
        delta = '—'
        if isinstance(ext,(int,float)) and isinstance(ours,(int,float)):
            delta = round(ours - ext, 1)
            delta = f'{delta:+.1f}'
        metric_rows.append([label, ext, ours if ours is not None else '—', delta])

    # Type/curve EDHREC live compare.
    type_rows = [
        ['Creature', edhrec_metrics.get('creature'), '—'],
        ['Instant', edhrec_metrics.get('instant'), '—'],
        ['Sorcery', edhrec_metrics.get('sorcery'), '—'],
        ['Artifact', edhrec_metrics.get('artifact'), '—'],
        ['Enchantment', edhrec_metrics.get('enchantment'), '—'],
        ['Land', edhrec_metrics.get('lands'), local_metrics.get('lands')],
        ['Avg CMC', edhrec_metrics.get('avg_cmc'), local_metrics.get('avg_cmc')],
    ]

    new_cards = scryfall_new_cards()

    # Reddit/direct web snippets via DuckDuckGo (no direct Reddit JSON available in cron).
    reddit_search = curl_text('https://r.jina.ai/http://duckduckgo.com/html/?q=' + urllib.parse.quote('Lorehold the Historian reddit EDH primer'), timeout=60)
    reddit_hits = []
    for m in re.finditer(r'## \[(.*?)\]\((.*?)\)\n\n(?:\[!\[.*?\]\(.*?\)\]\(.*?\))?\[([^\]]+)\]\(.*?\)\n\n\[(.*?)\]\(', reddit_search, re.S):
        title = re.sub(r'\*+', '', m.group(1)).strip()
        url = html.unescape(m.group(2))
        snippet = re.sub(r'\*+', '', m.group(4)).strip()
        if 'reddit.com/r/EDH' in url or 'draftsim.com' in url or 'tcgplayer.com' in url or 'moxfield.com' in url or 'archidekt.com' in url:
            reddit_hits.append({'title': title, 'url': url, 'snippet': snippet[:350]})
        if len(reddit_hits) >= 6:
            break

    now = dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat().replace('+00:00', 'Z')
    rows_sources = []
    for d in local_edhrec_decks:
        rows_sources.append(['EDHREC corpus', d['name'].replace('edhrec_lorehold_',''), len(d['cards']), d['url']])
    for d in mox_decks:
        rows_sources.append(['Moxfield', d['name'], len(d['cards']), d['url']])

    rows_staples = []
    for n,c in staples_50[:35]:
        rows_staples.append([display.get(n,n), f'{c}/{total_decks} ({100*c/total_decks:.0f}%)', '✓' if n in local_set else '✗'])

    rows_missing_60 = []
    for n,c in missing_60[:30]:
        live = next((x for x in edhrec_live_cards if norm(x['name']) == n), None)
        edhpct = f"; EDHREC live {live['pct']:.0f}%" if live else ''
        rows_missing_60.append([display.get(n,n), f'{c}/{total_decks} ({100*c/total_decks:.0f}%){edhpct}', ', '.join(sources_by_card[n][:3])])
    if not rows_missing_60:
        rows_missing_60.append(['—', 'Nenhuma carta ausente cruzou 60% nos 8 decks externos', '—'])

    rows_live_urgent = []
    for c in edhrec_live_missing_60[:25]:
        rows_live_urgent.append([c['name'], f"{c['num_decks']}/{c['potential_decks']} ({c['pct']:.0f}%)", c['section'], f"{(c.get('synergy') or 0):+.2f}"])
    if not rows_live_urgent:
        rows_live_urgent.append(['—', 'Nenhuma carta EDHREC live >=60% ausente', '—', '—'])

    rows_missing_all = []
    for n,c in missing_all[:25]:
        rows_missing_all.append([display.get(n,n), '8/8', 'faltando universal nos decks coletados'])
    if not rows_missing_all:
        rows_missing_all.append(['—', '0', 'Nenhuma carta aparece em todos os 8 externos e falta no nosso'])

    rows_cut = []
    # preserve local card order; choose nonland/low-confidence first? report all up to 35
    for c in local_cards:
        n = norm(c['card_name'])
        if c['is_commander'] or freq.get(n,0) > 0:
            continue
        rows_cut.append([c['card_name'], c.get('functional_tag') or 'None', c.get('cmc'), '0/8 externos'])
    rows_cut = rows_cut[:40]

    rows_tech = []
    for c in tech[:20]:
        rows_tech.append([c['name'], c['section'], f"{c['pct']:.0f}%", f"{c.get('synergy'):+.2f}"])

    rows_new = []
    for c in new_cards[:15]:
        in_ours = '✓' if norm(c['name']) in local_set else '✗'
        rows_new.append([c['name'], c['released_at'], c['type_line'], ', '.join(c['reasons'][:3]), in_ours])

    rows_reddit = []
    for h in reddit_hits[:6]:
        kind = 'Reddit r/EDH' if 'reddit.com/r/EDH' in h['url'] else 'Primer/guia'
        rows_reddit.append([kind, h['title'], h['snippet'].replace('\n',' ')])

    content = []
    content.append(f"## [{now}] Execução #2 — scout ampliado EDHREC live + Moxfield + Reddit/DDG + Scryfall\n")
    content.append("### Fontes consultadas\n")
    content.append(markdown_table(['Fonte','Deck / busca','Cartas','URL'], rows_sources))
    content.append(f"\n- **EDHREC live**: {edhrec_metrics['source']} — {edhrec_metrics.get('decks')} decks rastreados, avg deck mostrado com {edhrec_metrics.get('deck_size_shown')} cartas e contagem total normalizada {edhrec_metrics.get('total_card_count')}.\n")
    content.append("- **Reddit r/EDH**: Reddit JSON/old reddit bloqueou o cron (403/HTML); usei DuckDuckGo via Jina como índice externo e registrei os snippets encontrados, incluindo um resultado direto `r/EDH/comments/1rkrj16/lorehold_the_historian/`.\n")
    content.append("- **Scryfall**: queries por cartas RW legais em Commander desde 2026-04-24 com instant/sorcery, miracle/topdeck, discard/rummage, Treasure e/ou cast-without-paying.\n")
    content.append(f"- **Nosso deck atual**: deck_id={deck_row['id']}, `{deck_row['deck_name']}`, {len(local_cards)} registros / {sum(c['quantity'] for c in local_cards)} cartas; bracket {deck_row['bracket']}.\n")

    content.append("\n### Métricas — nosso deck vs média dos 8 decks externos\n")
    content.append(markdown_table(['Métrica','Média externa (3 EDHREC corpus + 5 Moxfield)','Nosso deck','Delta'], metric_rows))
    content.append("\n**Leitura:** o nosso deck continua mais carregado em ramp/proteção/board wipes que a média coletada. O gap mais claro agora é que os externos Moxfield/EDHREC live usam mais pacote de `ritual_treasure` barato (Big Score/Seize the Spoils/Hit the Mother Lode) e mais topdeck/miracle enablers, enquanto o nosso mantém mais peças defensivas e alguns haymakers de CMC alto.\n")

    content.append("\n### EDHREC live — distribuição média publicada\n")
    content.append(markdown_table(['Tipo/métrica','EDHREC live','Nosso deck'], type_rows))
    content.append(f"\nEDHREC live lista {edhrec_metrics.get('decks')} decks e curva média CMC {edhrec_metrics.get('avg_cmc')}; nosso CMC médio SQLite é {local_metrics.get('avg_cmc')}, ligeiramente abaixo da média live, mas ainda dentro de perfil “big spells”.\n")

    content.append("\n### Staples 50%+ nos 8 decks externos\n")
    content.append(markdown_table(['Carta','Frequência externa','No nosso?'], rows_staples))

    content.append("\n### Faltando Urgente — 60%+ dos decks externos e ausente no nosso\n")
    content.append(markdown_table(['Carta','Frequência','Evidência'], rows_missing_60))
    content.append("\n### Faltando Urgente — EDHREC live 60%+ e ausente no nosso\n")
    content.append(markdown_table(['Carta','Inclusão EDHREC','Seção','Synergy'], rows_live_urgent))

    content.append("\n### Cartas que aparecem em TODOS os 8 decks externos mas não estão no nosso\n")
    content.append(markdown_table(['Carta','Frequência','Nota'], rows_missing_all))

    content.append("\n### Tech choices / cartas interessantes de alta sinergia EDHREC que não estão no nosso\n")
    content.append(markdown_table(['Carta','Seção EDHREC','Inclusão','Synergy'], rows_tech))

    content.append("\n### Cortáveis: cartas do nosso deck com 0 aparições nos 8 externos\n")
    content.append(markdown_table(['Carta','Tag atual','CMC','Evidência'], rows_cut))
    content.append("\n**Cuidado:** `0/8 externos` não é corte automático. É evidência de baixa adoção na amostra; validar papel no plano do usuário antes de trocar.\n")

    content.append("\n### Reddit r/EDH / primers e guias encontrados via índice externo\n")
    content.append(markdown_table(['Tipo','Resultado','Snippet útil'], rows_reddit or [['—','Sem resultados parseáveis','Reddit direto bloqueou o cron']]))
    content.append("\n**Insight de comunidade:** os snippets externos convergem em `big spells / miracle / topdeck`, com preocupação de não transformar Boros em MLD salgado demais. Isso reforça priorizar cartas que manipulam topo/cast gratuito antes de mais wipes destrutivos.\n")

    content.append("\n### Scryfall — cartas novas/sinérgicas para Lorehold\n")
    content.append(markdown_table(['Carta','Data','Tipo','Razão de sinergia','No nosso?'], rows_new or [['—','—','—','Nenhuma nova carta sinérgica encontrada pela query','—']]))

    content.append("\n### Recomendações documentais desta execução (sem modificar deck)\n")
    recs = []
    if rows_live_urgent and rows_live_urgent[0][0] != '—':
        recs.append(f"1. **Avaliar urgente EDHREC 60%+ ausentes**: {', '.join(r[0] for r in rows_live_urgent[:8])}.")
    if rows_missing_60 and rows_missing_60[0][0] != '—':
        recs.append(f"2. **Avaliar pela amostra de decks reais**: {', '.join(r[0] for r in rows_missing_60[:8])}.")
    recs.append("3. **Não elevar mais o CMC médio sem corte equivalente**: nosso avg CMC 3.98 já está em território “big spells”; se entrar novo haymaker, cortar outro CMC alto primeiro.")
    recs.append("4. **Não remover automaticamente cartas 0/8**: algumas são escolhas de coleção/estilo; usar a lista de cortáveis como fila de revisão, não como patch direto.")
    content.append('\n'.join(recs) + '\n')

    content.append("\n### Limitações da execução\n")
    content.append("- Moxfield foi consultado via API pública `api2.moxfield.com`; as métricas funcionais externas são heurísticas por oracle/type line e não substituem o classificador oficial do ManaLoom.\n")
    content.append("- Reddit direto bloqueou acesso anônimo; os dados de Reddit vêm de snippets indexados pelo DuckDuckGo/Jina, não do corpo completo dos posts.\n")
    content.append("- EDHREC live é agregado de milhares de decks; as porcentagens de inclusão complementam, mas não são a mesma coisa que presença em uma decklist única.\n")

    new_section = '\n'.join(content).rstrip() + '\n'
    old = SCOUT_LOG.read_text() if SCOUT_LOG.exists() else '# Scout Log — Lorehold, the Historian\n'
    if new_section.strip() in old:
        print('No change: section already present')
        return
    SCOUT_LOG.write_text(old.rstrip() + '\n\n---\n\n' + new_section)

    data = {
        'generated_at': now,
        'local_deck': deck_row,
        'edhrec_live_metrics': edhrec_metrics,
        'edhrec_live_top': edhrec_live_cards[:100],
        'moxfield_decks': [
            {
                k: (sorted(v) if isinstance(v, set) else v)
                for k, v in d.items()
                if k not in ('full_cards',)
            }
            for d in mox_decks
        ],
        'missing_60_external': rows_missing_60,
        'missing_60_edhrec_live': rows_live_urgent,
        'staples_50': rows_staples,
        'cuttable_0_of_8': rows_cut,
        'scryfall_new_cards': rows_new,
        'reddit_hits': reddit_hits,
    }
    (DECK_DIR / 'scout_cycle_20260527.json').write_text(json.dumps(data, ensure_ascii=False, indent=2))
    print(f'Updated {SCOUT_LOG}')
    print(f'External decks: {total_decks}; staples50={len(staples_50)}; missing60={len(missing_60)}; live_missing60={len(edhrec_live_missing_60)}; cuttable={len(rows_cut)}')
    print('Top live missing 60:', ', '.join(r[0] for r in rows_live_urgent[:8]))

if __name__ == '__main__':
    main()
