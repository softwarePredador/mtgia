#!/usr/bin/env python3
"""Research real sources for Commander Vampires theme.

Fetches EDHREC live data, local EDHREC/profile artifacts, Moxfield API, and
searches for primer pages without relying on internal MTG knowledge.
"""
import html
import json
import os
import re
import subprocess
import sys
import urllib.parse
from collections import Counter
from pathlib import Path

ROOT = Path('/opt/data/workspace/mtgia')
ART = ROOT / 'server/test/artifacts'
PROFILE = ART / 'commander_reference_profile_anchor30_batch_b_2026-05-12/profiles/edgar_markov.json'
CORPUS = ART / 'commander_reference_deck_corpus_edgar_2026-05-13/edgar_edhrec_average_corpus.json'
OUT = Path('/tmp/vampires_theme_research.json')
EDHREC_URL = 'https://edhrec.com/commanders/edgar-markov'
EDHREC_AUTHORIZATION_FLAG = 'MANALOOM_EDHREC_AUTOMATED_COLLECTION_AUTHORIZED'
AUTHORIZED_FLAG_VALUES = {'1', 'true', 'yes', 'on'}
MOXFIELD_ID = 'fpa2N8MU_UyU2tqrCXWdLg'
MOXFIELD_URL = f'https://www.moxfield.com/decks/{MOXFIELD_ID}'
MOXFIELD_API = f'https://api.moxfield.com/v2/decks/all/{MOXFIELD_ID}'


def edhrec_collection_authorized():
    return os.environ.get(EDHREC_AUTHORIZATION_FLAG, '').strip().lower() in AUTHORIZED_FLAG_VALUES


def is_edhrec_url(url):
    hostname = (urllib.parse.urlparse(url).hostname or '').lower()
    return hostname == 'edhrec.com' or hostname.endswith('.edhrec.com')


def curl(url, timeout=30):
    if is_edhrec_url(url) and not edhrec_collection_authorized():
        return {
            'url': url,
            'exit_code': 78,
            'stdout': '',
            'stderr': (
                f'EDHREC collection blocked (fail-closed): set '
                f'{EDHREC_AUTHORIZATION_FLAG} only after explicit authorization.'
            ),
        }
    r = subprocess.run(
        ['curl', '-sL', '--max-time', str(timeout), '-A', 'Mozilla/5.0 Hermes ManaLoom research', url],
        capture_output=True,
        text=True,
    )
    return {'url': url, 'exit_code': r.returncode, 'stdout': r.stdout, 'stderr': r.stderr}


def extract_next_data(html_text):
    m = re.search(r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>', html_text, re.S)
    if not m:
        return None
    return json.loads(html.unescape(m.group(1)))


def find_sections_text(html_text):
    # EDHREC sections are usually embedded in Next data; keep robust by walking JSON later.
    return None


def walk_find(obj, key, found):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == key:
                found.append(v)
            walk_find(v, key, found)
    elif isinstance(obj, list):
        for x in obj:
            walk_find(x, key, found)


def cardviews_from_next(next_data):
    vals = []
    walk_find(next_data, 'cardviews', vals)
    out = []
    for arr in vals:
        if isinstance(arr, list):
            for cv in arr:
                if isinstance(cv, dict) and cv.get('name'):
                    out.append(cv)
    # Deduplicate by name, keep first
    seen = set(); dedup=[]
    for cv in out:
        n=cv.get('name')
        if n not in seen:
            seen.add(n); dedup.append(cv)
    return dedup


def extract_edhrec():
    res = curl(EDHREC_URL, 40)
    info = {'url': EDHREC_URL, 'curl_exit': res['exit_code'], 'html_bytes': len(res['stdout'])}
    if res['exit_code'] != 0 or not res['stdout']:
        info['error'] = res['stderr']
        return info
    next_data = extract_next_data(res['stdout'])
    if not next_data:
        info['error'] = 'no __NEXT_DATA__ found'
        return info
    d = next_data.get('props', {}).get('pageProps', {}).get('data', {})
    info['raw_data_keys'] = sorted(list(d.keys()))[:80]
    for k in ['creature','instant','sorcery','artifact','enchantment','planeswalker','land','deck_size','total_card_count','num_decks_avg','avg_price']:
        if k in d:
            info[k] = d.get(k)
    panels = d.get('panels') or {}
    curve = panels.get('mana_curve') or {}
    info['mana_curve'] = curve
    try:
        total_cmc = sum(int(k) * int(v) for k, v in curve.items())
        total_cards = sum(int(v) for v in curve.values())
        info['avg_cmc_from_curve'] = round(total_cmc / total_cards, 2) if total_cards else None
        info['mana_curve_nonland_cards'] = total_cards
    except Exception as e:
        info['avg_cmc_error'] = str(e)
    taglinks = panels.get('taglinks') or []
    info['taglinks'] = taglinks[:20]
    info['similar'] = d.get('similar', [])[:10] if isinstance(d.get('similar'), list) else d.get('similar')
    cvs = cardviews_from_next(next_data)
    top = []
    for cv in cvs[:80]:
        n = cv.get('name')
        nd = cv.get('num_decks') or cv.get('inclusion')
        pot = cv.get('potential_decks') or cv.get('potentialDecks')
        pct = None
        try:
            if nd is not None and pot:
                pct = round(100*float(nd)/float(pot), 1)
        except Exception:
            pass
        top.append({'name': n, 'num_decks': nd, 'potential_decks': pot, 'pct': pct, 'synergy': cv.get('synergy'), 'label': cv.get('label'), 'type': cv.get('type')})
    info['top_cardviews'] = top
    return info


def classify_counts(cards):
    # Only name/type heuristics for local artifact composition; not used as oracle truth.
    names=[c.get('name','') for c in cards]
    lower=[n.lower() for n in names]
    vampire_terms = ['vampire']
    # We can count obvious vampires from names/types only if local corpus lacks type lines; document as corpus line names, not full type truth.
    counts = Counter()
    for n in lower:
        if 'blood' in n or 'vampire' in n or 'vito' in n or 'drana' in n or 'nirkana' in n or 'olivia' in n or 'edgar' in n or 'elenda' in n or 'markov' in n or 'strefan' in n or 'yahenni' in n or 'malakir' in n or 'legion' in n or 'dusk' in n or 'stromkirk' in n or 'cordial' in n or 'sanctum seeker' in n or 'captivating' in n or 'twilight prophet' in n or 'vicious conquistador' in n:
            counts['likely_vampire_name'] += 1
        if n in {'arcane signet','sol ring','boros signet','rakdos signet','orzhov signet','talisman of conviction','talisman of hierarchy','talisman of indulgence','fellwar stone','commanders sphere'}:
            counts['obvious_rock_ramp_names'] += 1
        if n in {'blood artist','cruel celebrant','zulaport cutthroat','bastion of remembrance','viscera seer','goblin bombardment','skullclamp','yahenni undying partisan'}:
            counts['obvious_aristocrats_names'] += 1
        if n in {'legion lieutenant','stromkirk captain','captivating vampire','shared animosity','sanctum seeker','drana liberator of malakir','vampire nocturnus','cordial vampire'}:
            counts['obvious_lord_drain_names'] += 1
    return dict(counts)


def extract_profile_corpus():
    profile=json.load(open(PROFILE))
    corpus=json.load(open(CORPUS))
    decks=[]
    for deck in corpus.get('decks', []):
        cards=deck.get('cards', [])
        decks.append({
            'source': deck.get('source'),
            'source_url': deck.get('source_url'),
            'power_lane': deck.get('power_lane'),
            'theme': deck.get('theme'),
            'unique_cards': len(cards),
            'total_qty': sum(c.get('quantity',1) for c in cards),
            'name_based_counts': classify_counts(cards),
            'top_cards': [c.get('name') for c in cards[:30]],
        })
    return {
        'profile_path': str(PROFILE),
        'corpus_path': str(CORPUS),
        'commander': profile.get('commander'),
        'confidence': profile.get('confidence'),
        'source_count': profile.get('source_count'),
        'source_refs': profile.get('source_refs'),
        'themes': profile.get('themes'),
        'role_targets': profile.get('role_targets'),
        'expected_packages': {k: {'count': len(v), 'cards': v} for k,v in profile.get('expected_packages', {}).items()},
        'corpus_decks': decks,
    }


def extract_moxfield():
    res = curl(MOXFIELD_API, 40)
    info = {'url': MOXFIELD_URL, 'api_url': MOXFIELD_API, 'curl_exit': res['exit_code'], 'bytes': len(res['stdout'])}
    if res['exit_code'] != 0 or not res['stdout']:
        info['error'] = res['stderr']
        return info
    try:
        d=json.loads(res['stdout'])
    except Exception as e:
        info['error'] = 'json parse failed: '+str(e)
        info['sample'] = res['stdout'][:500]
        return info
    info['name']=d.get('name')
    info['format']=d.get('format')
    info['visibility']=d.get('visibility')
    info['createdByUser']=(d.get('createdByUser') or {}).get('userName') if isinstance(d.get('createdByUser'), dict) else d.get('createdByUser')
    info['lastUpdatedAtUtc']=d.get('lastUpdatedAtUtc')
    info['description_length']=len(d.get('description') or '')
    boards={}
    for board_name in ['commanders','mainboard','sideboard','maybeboard']:
        board=d.get(board_name) or {}
        if isinstance(board, dict):
            qty=0; unique=0; cats=Counter(); names=[]
            for cid, entry in board.items():
                unique += 1
                q = entry.get('quantity', 1) if isinstance(entry, dict) else 1
                qty += q
                card = entry.get('card') if isinstance(entry, dict) else None
                name = (card or {}).get('name') or entry.get('cardName') if isinstance(entry, dict) else None
                if name: names.append(name)
                for cat in entry.get('categories', []) if isinstance(entry, dict) else []:
                    cats[cat]+=q
            boards[board_name]={'unique':unique,'quantity':qty,'categories':dict(cats),'first_names':names[:25]}
    info['boards']=boards
    return info


def ddg_search(query):
    url='https://html.duckduckgo.com/html/?q='+urllib.parse.quote(query)
    res=curl(url, 30)
    results=[]
    if res['exit_code']==0 and res['stdout']:
        # Parse result links in duckduckgo html
        for m in re.finditer(r'<a rel="nofollow" class="result__a" href="([^"]+)">(.*?)</a>', res['stdout'], re.S):
            href=html.unescape(m.group(1))
            title=re.sub('<.*?>','',m.group(2))
            title=html.unescape(title).strip()
            # unwrap duckduckgo redirect
            if 'uddg=' in href:
                qs=urllib.parse.parse_qs(urllib.parse.urlparse(href).query)
                if qs.get('uddg'):
                    href=qs['uddg'][0]
            results.append({'title':title,'url':href})
    return {'query': query, 'url': url, 'curl_exit': res['exit_code'], 'result_count': len(results), 'results': results[:10], 'html_bytes': len(res['stdout'])}


def fetch_primer_from_search(searches):
    candidates=[]
    for s in searches:
        for r in s.get('results', []):
            u=r['url'].lower()
            t=r['title'].lower()
            if any(domain in u for domain in ['edhrec.com/articles','draftsim.com','mtggoldfish.com','commandersherald.com','tolariancommunitycollege.com','cardkingdom.com','channelfireball.com','moxfield.com']):
                candidates.append(r)
    fetched=[]
    for r in candidates[:5]:
        res=curl(r['url'], 30)
        txt=re.sub('<script.*?</script>',' ',res['stdout'], flags=re.S|re.I)
        txt=re.sub('<style.*?</style>',' ',txt, flags=re.S|re.I)
        text=html.unescape(re.sub('<.*?>',' ',txt))
        text=re.sub(r'\s+',' ',text).strip()
        snippets=[]
        for kw in ['ramp','draw','vampire','payoff','land','removal','aristocrat','mana']:
            i=text.lower().find(kw)
            if i>=0:
                snippets.append(text[max(0,i-220):i+450])
        fetched.append({'title':r['title'],'url':r['url'],'curl_exit':res['exit_code'],'html_bytes':len(res['stdout']),'text_len':len(text),'snippets':snippets[:6]})
    return {'candidates': candidates[:10], 'fetched': fetched}


def main():
    profile_corpus=extract_profile_corpus()
    edhrec=extract_edhrec()
    mox=extract_moxfield()
    searches=[
        ddg_search('Edgar Markov Commander primer 2026 deckbuilding guide'),
        ddg_search('Vampires Commander primer Edgar Markov deckbuilding guide ramp draw'),
        ddg_search('Edgar Markov EDH primer vampires moxfield'),
    ]
    primer=fetch_primer_from_search(searches)
    out={
        'theme':'Vampires',
        'timestamp_source':'runtime',
        'edhrec_live': edhrec,
        'profile_corpus': profile_corpus,
        'moxfield': mox,
        'searches': searches,
        'primer_fetch': primer,
    }
    OUT.write_text(json.dumps(out, indent=2, ensure_ascii=False))
    print(f'Wrote {OUT}')
    print(json.dumps({
        'theme': out['theme'],
        'edhrec': {k: edhrec.get(k) for k in ['url','num_decks_avg','land','creature','artifact','instant','sorcery','enchantment','avg_cmc_from_curve','deck_size','html_bytes']},
        'profile_targets': profile_corpus['role_targets'],
        'moxfield': {k: mox.get(k) for k in ['url','name','format','createdByUser','lastUpdatedAtUtc','boards','error']},
        'primer_results': searches[0]['results'][:3],
        'primer_fetched': [{'title':f['title'],'url':f['url'],'text_len':f['text_len']} for f in primer.get('fetched', [])[:3]],
    }, indent=2, ensure_ascii=False))

if __name__ == '__main__':
    main()
