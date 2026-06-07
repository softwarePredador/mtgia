# Lorehold Legality Validation

Generated: 2026-06-03T12:50:46+00:00

## Deck

- `deck_id`: `6`
- Name: `Lorehold Best-of Learned No Premium Mox 2026-06-02`
- Archetype: `fast-mana-copy-combo-big-spells-no-premium-mox`
- Cards: `100`
- Lands: `33`

## Commander Legality Result

- Banned cards: `0`
- Unknown legality cards: `0`
- Verdict: `LEGAL`

## Sanity Checks

- `Worldfire`: commander=`legal`, in_deck=`1`
- `Mana Crypt`: commander=`banned`, in_deck=`0`
- `Chrome Mox`: commander=`legal`, in_deck=`0`
- `Mox Diamond`: commander=`legal`, in_deck=`0`
- `Mox Opal`: commander=`legal`, in_deck=`0`
- `Mox Amber`: commander=`legal`, in_deck=`1`
- `Fellwar Stone`: commander=`legal`, in_deck=`1`
- `Lightning Greaves`: commander=`legal`, in_deck=`1`
- `Victory Chimes`: commander=`legal`, in_deck=`1`

## Role Snapshot

- `land`: 33
- `unknown`: 20
- `wincon`: 11
- `tutor`: 6
- `spell`: 6
- `ramp`: 6
- `draw`: 6
- `protection`: 4
- `stax`: 3
- `removal`: 3
- `token_maker`: 1
- `commander`: 1

## Source Of Truth

Legalities were synchronized from PostgreSQL `cards` + `card_legalities` into local SQLite `card_legalities` using `/opt/data/scripts/manaloom-sync-legalities.sh`.
Do not use model memory for banlist claims. Worldfire is legal according to the synced PG/Scryfall legality data.
