# Valgavoth Variant 01 PG Registration

- Date: 2026-06-24
- Source decklist: `docs/hermes-analysis/manaloom-knowledge/decks/valgavoth-harrower-of-souls/2026-06-24-variant-01-user-decklist.md`
- Hermes cache deck id: `618`
- PostgreSQL deck id: `c77cb83c-dd28-5d66-a0d8-799079a848bb`
- PostgreSQL learned row id: `acdbd53f-f1a9-5c78-823e-3127d92c8b02`
- Learned source tuple: `manual_user_deck_registration/valgavoth_variant01_20260624_b037751a69fa`
- Deck hash: `b037751a69fa297355b67d7d3efac90cbeb3117303e9d9af1cbe2945e53b205f`

## Resolution Evidence

- Resolution artifact: `valgavoth_variant01_resolution_20260624.json`
  - `input_rows=87`
  - `input_qty=100`
  - `resolved_rows=87`
  - `missing_rows=0`
- Commander input `Valgavoth, Harrower of Souls` resolved to PostgreSQL card
  `Valgavoth, Harrower of Souls`.

## PostgreSQL Evidence

- Precheck artifact: `valgavoth_variant01_pg_registration_20260624_precheck.out`
  - `input_rows=87`
  - `input_qty=100`
  - `commander_qty=1`
  - `resolved_rows=87`
  - `missing_rows=0`
  - existing target before apply: `deck_rows=0`, `deck_qty=0`, `learned_rows=0`
- Apply artifact: `valgavoth_variant01_pg_registration_20260624_apply.out`
  - `INSERT 0 1` into `decks`
  - `INSERT 0 87` into `deck_cards`
  - `INSERT 0 1` into `commander_learned_decks`
  - `COMMIT`
- Postcheck artifact: `valgavoth_variant01_pg_registration_20260624_postcheck.out`
  - `deck_cards`: `rows=87`, `qty=100`, `commander_qty=1`
  - `commander_learned_decks`: one inactive row, `card_count=100`,
    `legal_status=registered_pending_card_rule_validation`
  - `missing_deck_cards=0`
- Rollback SQL is available at
  `valgavoth_variant01_pg_registration_20260624_rollback.sql`.

## Local Hermes Evidence

- Cache artifact: `valgavoth_variant01_hermes_cache_20260624.json`
  - before: `deck_rows=0`, `deck_card_rows=0`
  - after: `deck_id=618`, `rows=87`, `qty=100`, `commanders=1`

## Scope

This registration did not modify any Lorehold deck id, did not apply a deck swap,
and did not promote the learned row as active.

## Pending For Card Validator

This intake validates catalog resolution and deck cardinality only. Executable
card-rule behavior, strategy coherence, and battle simulation for this Valgavoth
deck remain pending for the card validator.
