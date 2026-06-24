# Lorehold Variant 08 PG Registration

- Date: 2026-06-24
- Source decklist: `docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-08-user-decklist.md`
- Hermes cache deck id: `613`
- PostgreSQL deck id: `6df74eb3-c4a7-5398-bcf5-febb38d80d7a`
- PostgreSQL learned row id: `fe7dc94a-b360-5108-a004-ee75bb11e76c`
- Learned source tuple: `manual_user_deck_registration/lorehold_variant08_20260624_1a76c69c236f`
- Deck hash: `1a76c69c236f182671a7d2069ecb48d9003261d1dd23ac144ae55c2c0a904367`

## Local Hermes Evidence

- Dry-run artifact: `lorehold_variant_staging_20260624_123429.json`
  - `valid=1`, `invalid=0`
  - `total=100`, `main=99`, `commander=1`
  - no oracle cache backfill was needed.
- Applied Hermes staging artifact: `lorehold_variant_staging_20260624_123450.json`
  - materialized target deck id `613`
  - backup id `variant_target_613_20260624T123450Z_dfdf49887699`
- Hermes local post-materialization check:
  - `deck_cards`: `rows=91`, `qty=100`, `commander_qty=1`, `distinct_cards=91`

## PostgreSQL Evidence

- Precheck artifact: `lorehold_variant08_pg_registration_20260624_precheck.out`
  - `input_rows=91`
  - `input_qty=100`
  - `commander_qty=1`
  - `resolved_rows=91`
  - `missing_rows=0`
  - existing target before apply: `deck_rows=0`, `deck_qty=0`, `learned_rows=0`
- Apply artifact: `lorehold_variant08_pg_registration_20260624_apply.out`
  - `INSERT 0 1` into `decks`
  - `INSERT 0 91` into `deck_cards`
  - `INSERT 0 1` into `commander_learned_decks`
- Postcheck artifact: `lorehold_variant08_pg_registration_20260624_postcheck.out`
  - `decks`: one row, `format=commander`, `archetype=spell-copy-control-variant`, `not_deleted=true`
  - `deck_cards`: `rows=91`, `qty=100`, `commander_qty=1`, `distinct_cards=91`
  - `commander_learned_decks`: one inactive row, `card_count=100`, `legal_status=registered_pending_card_rule_validation`
  - `missing_card_rows=0`

## Scope

This registration did not modify the official Lorehold deck id `6`, did not apply a deck swap, and did not promote the learned row as active.

## Pending For Card Validator

The Hermes staging report is valid for deck/cardinality, but has `11` cards with `no_verified_executable_battle_rule`.
