# Commander Legality Sync Report

Generated: 2026-06-03T12:46:08+00:00

## What Changed

- Added `scripts/sync_pg_legalities.py`.
- Added `scripts/validate_deck_legalities.py`.
- Added `/opt/data/scripts/manaloom-sync-legalities.sh` wrapper that loads `/opt/data/secrets/manaloom-postgres.env`.
- Synced PG `cards` + `card_legalities` into local SQLite `card_legalities`.
- Synced PG `format_staples` into local SQLite `format_staples`.
- Added first-face aliases for `Front // Back` cards.
- Added local legal alias for ManaLoom custom commander `Lorehold, the Historian`.
- Updated Hermes skills to use the new scripts and avoid banlist claims from model memory.

## Current Counts

- Commander legalities: `31369`
- Commander format staples: `748`

## Sanity Checks

- Worldfire: `legal`
- Mana Crypt: `banned`
- Active Lorehold deck banned cards: `0`
- Active Lorehold deck unknown legalities: `0`

## Required Cron Protocol

```bash
/opt/data/scripts/manaloom-sync-legalities.sh
python3 scripts/validate_deck_legalities.py --deck-id 6
```

If banned cards > 0, abort analysis and report a banlist violation. If unknown legalities > 0, sync/resolve aliases before making banlist claims.
