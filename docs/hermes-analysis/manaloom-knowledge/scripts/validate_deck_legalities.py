#!/usr/bin/env python3
"""Validate Commander legality of a local Hermes deck against synced PG data."""

from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path


DB = Path('/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db')


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--deck-id', type=int, default=6)
    parser.add_argument('--format', default='commander')
    args = parser.parse_args()

    con = sqlite3.connect(DB)
    con.row_factory = sqlite3.Row
    exists = con.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='card_legalities'").fetchone()
    if not exists:
        raise SystemExit('card_legalities not found. Run /opt/data/scripts/manaloom-sync-legalities.sh first.')

    deck = con.execute('SELECT id, deck_name FROM decks WHERE id=?', (args.deck_id,)).fetchone()
    if not deck:
        raise SystemExit(f'deck_id={args.deck_id} not found')

    banned = con.execute('''
        SELECT dc.card_name, dc.quantity, cl.status
        FROM deck_cards dc
        JOIN card_legalities cl ON lower(cl.card_name) = lower(dc.card_name)
        WHERE dc.deck_id = ? AND cl.format = ? AND cl.status = 'banned'
        ORDER BY dc.card_name
    ''', (args.deck_id, args.format)).fetchall()
    unknown = con.execute('''
        SELECT dc.card_name, dc.quantity
        FROM deck_cards dc
        LEFT JOIN card_legalities cl ON lower(cl.card_name) = lower(dc.card_name) AND cl.format = ?
        WHERE dc.deck_id = ? AND cl.card_name IS NULL
        ORDER BY dc.card_name
    ''', (args.format, args.deck_id)).fetchall()

    print(f"Deck: {deck['deck_name']} (id={args.deck_id})")
    print(f'Format: {args.format}')
    print(f'Banned cards: {len(banned)}')
    for row in banned:
        print(f"- {row['quantity']} {row['card_name']} ({row['status']})")
    print(f'Unknown legality cards: {len(unknown)}')
    for row in unknown[:30]:
        print(f"? {row['quantity']} {row['card_name']}")
    if len(unknown) > 30:
        print(f'... {len(unknown) - 30} more')

    worldfire = con.execute(
        "SELECT status FROM card_legalities WHERE lower(card_name)=lower('Worldfire') AND format=?",
        (args.format,),
    ).fetchone()
    mana_crypt = con.execute(
        "SELECT status FROM card_legalities WHERE lower(card_name)=lower('Mana Crypt') AND format=?",
        (args.format,),
    ).fetchone()
    print(f"Worldfire status: {worldfire['status'] if worldfire else 'missing'}")
    print(f"Mana Crypt status: {mana_crypt['status'] if mana_crypt else 'missing'}")
    con.close()

    if banned:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
