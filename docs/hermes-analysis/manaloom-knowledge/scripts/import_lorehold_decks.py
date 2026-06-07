#!/usr/bin/env python3
import os
"""Import pasted Lorehold decklists into knowledge.db.

Default mode is dry-run. Use --apply to write.

Supported deck block format:

=== Deck Name ===
Source: EDHREC / MTGTop8 / MTGGoldfish / Archidekt / app / manual
Archetype: spellslinger
1 Sol Ring
1 Mountain
Lorehold, the Historian

Multiple blocks are allowed. If no explicit block header exists, the whole file
is imported as one deck.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import re
import sqlite3
from dataclasses import dataclass
from pathlib import Path


DB = Path('/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db')
COMMANDER = os.environ.get("HERMES_IMPORT_COMMANDER", "Lorehold, the Historian")


@dataclass
class CardRow:
    quantity: int
    name: str


@dataclass
class DeckBlock:
    name: str
    source: str
    source_url: str
    archetype: str
    cards: list[CardRow]


SECTION_HEADERS = {
    'commander', 'deck', 'decklist', 'mainboard', 'maybeboard', 'sideboard',
    'creatures', 'instants', 'sorceries', 'artifacts', 'enchantments', 'lands',
    'planeswalkers', 'commanders', 'spells', 'ramp', 'draw', 'removal', 'wincons',
}

ROLE_KEYWORDS = {
    'tutor': ['search your library', 'tutor'],
    'draw': ['draw a card', 'draw cards', 'draw two', 'draw three', 'impulse', 'exile the top', 'play that card'],
    'ramp': ['add one mana', 'add two mana', 'add mana', 'treasure token', 'treasures', 'costs less', 'mana rock'],
    'removal': ['destroy target', 'exile target', 'deals damage', 'damage to any target', 'counter target'],
    'protection': ['indestructible', 'hexproof', 'protection from', 'prevent all damage', "can't be countered", 'silence'],
    'recursion': ['return target card from your graveyard', 'return from your graveyard', 'escape', 'flashback', 'reanimate'],
    'token_maker': ['create a token', 'create two', 'create x', 'create that many'],
    'stax': ["opponents can't", "players can't", 'each player can', 'spells cost', 'unless its controller pays'],
    'combo': ['copy target', 'copy that spell', 'storm', 'whenever you cast or copy'],
    'wincon': ['win the game', 'target player loses', 'double damage', 'triple damage', 'extra combat', 'extra turn'],
}

WINCON_NAMES = {
    'approach of the second sun', 'rise of the eldrazi', "mizzix's mastery",
    'storm herd', 'worldfire', 'rite of the dragoncaller', 'fiery emancipation',
    'guttersnipe', 'aetherflux reservoir', 'underworld breach', 'grapeshot',
    'twinflame', 'dualcaster mage', 'flame of anor', 'akroma\'s will',
}


def normalize_card_name(raw: str) -> str:
    s = raw.strip()
    s = re.sub(r'^\*+|\*+$', '', s).strip()
    s = re.sub(r'\s+\([^)]*\)\s*$', '', s).strip()
    s = re.sub(r'\s+\[[^]]*\]\s*$', '', s).strip()
    s = re.sub(r'\s+#\d+\s*$', '', s).strip()
    s = re.sub(r'\s+', ' ', s)
    return s


def parse_card_line(line: str) -> CardRow | None:
    clean = line.strip().lstrip('-•').strip()
    if not clean or clean.startswith('#'):
        return None
    if clean.lower().rstrip(':') in SECTION_HEADERS:
        return None
    if ':' in clean and clean.split(':', 1)[0].strip().lower() in {'source', 'url', 'archetype', 'name', 'deck', 'commander'}:
        # A Commander: line may contain the card name, but we do not need to
        # import the commander as a normal card unless it is also in the list.
        return None
    m = re.match(r'^(?P<qty>\d+)\s*x?\s+(?P<name>.+)$', clean, re.I)
    if m:
        qty = int(m.group('qty'))
        name = normalize_card_name(m.group('name'))
    else:
        qty = 1
        name = normalize_card_name(clean)
    if not name or name.lower() in SECTION_HEADERS:
        return None
    return CardRow(quantity=max(1, qty), name=name)


def parse_blocks(text: str, default_name: str, default_source: str, default_archetype: str) -> list[DeckBlock]:
    blocks: list[dict] = []
    current = {'name': default_name, 'source': default_source, 'source_url': '', 'archetype': default_archetype, 'lines': []}
    saw_header = False

    for raw in text.splitlines():
        line = raw.strip()
        header = re.match(r'^(?:={2,}|#{2,})\s*(.+?)\s*(?:={2,})?$', line)
        if header:
            if current['lines'] or saw_header:
                blocks.append(current)
            saw_header = True
            current = {'name': header.group(1).strip(), 'source': default_source, 'source_url': '', 'archetype': default_archetype, 'lines': []}
            continue
        meta = re.match(r'^(Source|Fonte|URL|Archetype|Arqu[eé]tipo|Name|Deck)\s*:\s*(.+)$', line, re.I)
        if meta:
            key = meta.group(1).lower()
            val = meta.group(2).strip()
            if key in {'source', 'fonte'}:
                current['source'] = val
            elif key == 'url':
                current['source_url'] = val
            elif key in {'archetype', 'arquétipo', 'arquetipo'}:
                current['archetype'] = val
            elif key in {'name', 'deck'}:
                current['name'] = val
            continue
        current['lines'].append(raw)

    if current['lines'] or not blocks:
        blocks.append(current)

    parsed: list[DeckBlock] = []
    for i, b in enumerate(blocks, start=1):
        cards: dict[str, int] = {}
        for line in b['lines']:
            row = parse_card_line(line)
            if not row:
                continue
            cards[row.name] = cards.get(row.name, 0) + row.quantity
        if cards:
            name = b['name'] if b['name'] != default_name or len(blocks) == 1 else f'{default_name} #{i}'
            parsed.append(DeckBlock(
                name=name,
                source=b['source'],
                source_url=b['source_url'],
                archetype=b['archetype'],
                cards=[CardRow(q, n) for n, q in sorted(cards.items())],
            ))
    return parsed


def oracle_for(cur: sqlite3.Cursor, name: str) -> dict:
    row = cur.execute(
        'SELECT oracle_text, cmc, type_line, functional_tag FROM card_oracle_data WHERE lower(card_name)=lower(?)',
        (name,),
    ).fetchone()
    if not row:
        return {'oracle_text': '', 'cmc': None, 'type_line': '', 'functional_tag': ''}
    return {'oracle_text': row[0] or '', 'cmc': row[1], 'type_line': row[2] or '', 'functional_tag': row[3] or ''}


def infer_role(name: str, oracle: dict) -> str:
    n = name.lower()
    text = f"{oracle.get('type_line','')} {oracle.get('oracle_text','')} {oracle.get('functional_tag','')}".lower()
    if n == COMMANDER.lower():
        return 'commander'
    if 'land' in (oracle.get('type_line') or '').lower():
        return 'land'
    if n in WINCON_NAMES:
        return 'wincon'
    tag = (oracle.get('functional_tag') or '').lower()
    for role in ['wincon', 'ramp', 'draw', 'removal', 'protection', 'tutor', 'recursion', 'stax', 'combo']:
        if role in tag:
            return role
    for role, words in ROLE_KEYWORDS.items():
        if any(w in text for w in words):
            return role
    if 'creature' in (oracle.get('type_line') or '').lower():
        return 'creature'
    if any(t in (oracle.get('type_line') or '').lower() for t in ['instant', 'sorcery']):
        return 'spell'
    return 'unknown'


def wincon_scores(name: str, oracle: dict, role: str) -> tuple[int, int, int, int]:
    if role != 'wincon':
        return (5, 5, 5, 0)
    cmc = oracle.get('cmc')
    try:
        cmc_val = float(cmc) if cmc is not None else 5.0
    except Exception:
        cmc_val = 5.0
    text = (oracle.get('oracle_text') or '').lower()
    speed = 7 if cmc_val <= 3 else 6 if cmc_val <= 5 else 4 if cmc_val <= 7 else 2
    resilience = 7 if any(w in text for w in ['escape', 'flashback', 'from your graveyard', 'indestructible']) else 5
    stealth = 7 if 'whenever you cast' in text or 'damage' in text else 4
    if name.lower() == 'approach of the second sun':
        speed, resilience, stealth = 6, 5, 1
    return (speed, resilience, stealth, speed + resilience + stealth)


def deck_hash(deck: DeckBlock) -> str:
    payload = '\n'.join(f'{c.quantity} {c.name.lower()}' for c in deck.cards)
    return hashlib.sha256(payload.encode()).hexdigest()[:16]


def import_decks(decks: list[DeckBlock], apply: bool) -> None:
    con = sqlite3.connect(DB)
    cur = con.cursor()
    cur.execute('''CREATE TABLE IF NOT EXISTS lorehold_import_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_hash TEXT UNIQUE,
        deck_name TEXT,
        source TEXT,
        card_count INTEGER,
        learned_deck_id INTEGER,
        imported_at TEXT DEFAULT (datetime('now'))
    )''')
    now = dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat().replace('+00:00', 'Z')

    total_new = 0
    for deck in decks:
        h = deck_hash(deck)
        source_url = deck.source_url or f'manual-import:{h}'
        card_list = '\n'.join(f'{c.quantity} {c.name}' for c in deck.cards)
        card_count = sum(c.quantity for c in deck.cards)
        existing = cur.execute('SELECT learned_deck_id FROM lorehold_import_runs WHERE deck_hash=?', (h,)).fetchone()
        if not existing:
            existing = cur.execute('SELECT id FROM learned_decks WHERE source_url=?', (source_url,)).fetchone()
        print(f"Deck: {deck.name} | cards={card_count} | unique={len(deck.cards)} | hash={h}")
        if existing:
            print(f"  SKIP duplicate (learned_deck_id={existing[0]})")
            continue

        roles = []
        for card in deck.cards:
            oracle = oracle_for(cur, card.name)
            role = infer_role(card.name, oracle)
            roles.append((card, oracle, role))
        counts = {}
        for _, _, role in roles:
            counts[role] = counts.get(role, 0) + 1
        print('  roles:', ', '.join(f'{k}={v}' for k, v in sorted(counts.items())))

        if not apply:
            continue

        cur.execute('''INSERT INTO learned_decks
            (source, source_url, commander, deck_name, archetype, card_list, card_count, notes, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
            (deck.source, source_url, COMMANDER, deck.name, deck.archetype, card_list, card_count,
             f'import_lorehold_decks.py hash={h}', now))
        deck_id = cur.lastrowid
        for card, oracle, role in roles:
            speed, resilience, stealth, total = wincon_scores(card.name, oracle, role)
            notes = 'Imported from pasted Lorehold decklist'
            why = f'Appears in imported Lorehold deck: {deck.name}'
            for _ in range(card.quantity):
                cur.execute('''INSERT INTO card_deck_analysis
                    (deck_id, card_name, oracle_text, cmc, type_line, role_in_deck, synergy_notes, why_included,
                     enriched, pg_roles, pg_confidence, speed_score, resilience_score, stealth_score, wincon_total_score)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?)''',
                    (deck_id, card.name, oracle['oracle_text'], oracle['cmc'], oracle['type_line'], role, notes, why,
                     json.dumps([role]), 0.70, speed, resilience, stealth, total))
        cur.execute('''INSERT INTO lorehold_import_runs
            (deck_hash, deck_name, source, card_count, learned_deck_id)
            VALUES (?, ?, ?, ?, ?)''', (h, deck.name, deck.source, card_count, deck_id))
        total_new += 1
        print(f"  INSERTED learned_deck_id={deck_id}")

    if apply:
        con.commit()
    else:
        con.rollback()
    con.close()
    print(f"Done. apply={apply} new_decks={total_new if apply else 'dry-run'}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument('input', help='Text file containing one or more Lorehold decklists')
    p.add_argument('--apply', action='store_true', help='Write to knowledge.db')
    p.add_argument('--name', default='Lorehold Imported Deck', help='Default deck name')
    p.add_argument('--source', default='manual-import', help='Default source label')
    p.add_argument('--archetype', default='spellslinger', help='Default archetype')
    args = p.parse_args()

    text = Path(args.input).read_text(errors='replace')
    decks = parse_blocks(text, args.name, args.source, args.archetype)
    if not decks:
        raise SystemExit('No deck cards parsed. Use lines like: 1 Sol Ring')
    import_decks(decks, args.apply)


if __name__ == '__main__':
    main()
