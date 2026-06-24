# Kaalia Variant 01 PG Registration

- Date: 2026-06-24
- Source decklist: `docs/hermes-analysis/manaloom-knowledge/decks/kaalia-of-the-vast/2026-06-24-variant-01-user-decklist.md`
- Hermes cache deck id: `619`
- PostgreSQL deck id: `b629f227-b2b2-5e71-9854-99d345a8e01c`
- PostgreSQL learned row id: `cb2e2acf-933c-5a01-8fab-5bad84122211`
- Learned source tuple:
  `manual_user_deck_registration/kaalia_variant01_20260624_b895928feb6f`
- Deck hash:
  `b895928feb6f33ab62223690fff760f8eebe0a5c2c12c013be4e9ffe02d96656`

## Catalog Backfill Dependency

- Initial PostgreSQL resolution found one missing card:
  `Alicia Masters, Skilled Sculptor`.
- Backfill summary:
  `kaalia_variant01_alicia_masters_card_backfill_20260624_summary.md`
- After backfill, deck resolution closed with no missing cards.

## Resolution Evidence

- Resolution artifact: `kaalia_variant01_resolution_20260624.json`
  - `input_rows=89`
  - `input_qty=100`
  - `resolved_rows=89`
  - `missing_rows=0`
- Commander input `Kaalia of the Vast` resolved to PostgreSQL card
  `Kaalia of the Vast`.

## PostgreSQL Evidence

- Precheck artifact: `kaalia_variant01_pg_registration_20260624_precheck.out`
  - `input_rows=89`
  - `input_qty=100`
  - `commander_qty=1`
  - `resolved_rows=89`
  - `missing_rows=0`
  - existing target before apply: `deck_rows=0`, `deck_qty=0`, `learned_rows=0`
- Apply artifact: `kaalia_variant01_pg_registration_20260624_apply.out`
  - `INSERT 0 1` into `decks`
  - `INSERT 0 89` into `deck_cards`
  - `INSERT 0 1` into `commander_learned_decks`
  - `COMMIT`
- Postcheck artifact: `kaalia_variant01_pg_registration_20260624_postcheck.out`
  - `deck_cards`: `rows=89`, `qty=100`, `commander_qty=1`
  - `commander_learned_decks`: one inactive row, `card_count=100`,
    `legal_status=registered_pending_card_rule_validation`
  - `missing_deck_cards=0`
- Rollback SQL is available at
  `kaalia_variant01_pg_registration_20260624_rollback.sql`.

## Local Hermes Evidence

- Cache artifact: `kaalia_variant01_hermes_cache_20260624.json`
  - before: `deck_rows=0`, `deck_card_rows=0`
  - after: `deck_id=619`, `rows=89`, `qty=100`, `commanders=1`

## Scope

This registration did not modify any Lorehold deck id, did not apply a deck
swap, and did not promote the learned row as active.

## Pending For Card Validator

This intake validates catalog resolution and deck cardinality only. Executable
card-rule behavior, strategy coherence, and battle simulation for this Kaalia
deck remain pending for the card validator.
