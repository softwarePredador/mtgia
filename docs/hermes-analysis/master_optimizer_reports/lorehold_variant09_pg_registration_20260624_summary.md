# Lorehold Variant 09 PG Registration

- Date: 2026-06-24
- Source decklist: `docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-09-user-decklist.md`
- Hermes cache deck id: `614`
- PostgreSQL deck id: `b51c8f24-fa8b-50ee-8200-d78fe9908ffa`
- PostgreSQL learned row id: `806238bd-c707-5a9f-befc-56e00e93bb9c`
- Learned source tuple: `manual_user_deck_registration/lorehold_variant09_20260624_9370b6170e00`
- Deck hash: `9370b6170e00bc9fdcb33358ed7653f0c06a2d454871361dbef4fdc75560e6ee`

## Local Hermes Evidence

- Dry-run artifact: `lorehold_variant_staging_20260624_123824.json`
  - `valid=1`, `invalid=0`
  - `total=100`, `main=99`, `commander=1`
  - no oracle cache backfill was needed.
- Applied Hermes staging artifact: `lorehold_variant_staging_20260624_123839.json`
  - materialized target deck id `614`
  - backup id `variant_target_614_20260624T123839Z_820a6531f96f`
- Hermes local post-materialization check:
  - `deck_cards`: `rows=91`, `qty=100`, `commander_qty=1`, `distinct_cards=91`

## PostgreSQL Evidence

- Precheck artifact: `lorehold_variant09_pg_registration_20260624_precheck.out`
  - `input_rows=91`
  - `input_qty=100`
  - `commander_qty=1`
  - `resolved_rows=91`
  - `missing_rows=0`
  - existing target before apply: `deck_rows=0`, `deck_qty=0`, `learned_rows=0`
- Apply artifact: `lorehold_variant09_pg_registration_20260624_apply.out`
  - `INSERT 0 1` into `decks`
  - `INSERT 0 91` into `deck_cards`
  - `INSERT 0 1` into `commander_learned_decks`
- Postcheck artifact: `lorehold_variant09_pg_registration_20260624_postcheck.out`
  - `decks`: one row, `format=commander`, `archetype=lifegain-storm-variant`, `not_deleted=true`
  - `deck_cards`: `rows=91`, `qty=100`, `commander_qty=1`, `distinct_cards=91`
  - `commander_learned_decks`: one inactive row, `card_count=100`, `legal_status=registered_pending_card_rule_validation`
  - `missing_card_rows=0`

## Scope

This registration did not modify the official Lorehold deck id `6`, did not apply a deck swap, and did not promote the learned row as active.

## Pending For Card Validator

The Hermes staging report is valid for deck/cardinality, but has `17` cards with `no_verified_executable_battle_rule`.
