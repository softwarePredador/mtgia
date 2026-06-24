# Lorehold Variant 07 PG Registration

- Date: 2026-06-24
- Source decklist: `docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-07-user-decklist.md`
- Hermes cache deck id: `612`
- PostgreSQL deck id: `231281c3-e6a2-579b-93fe-21ddfdd13bda`
- PostgreSQL learned row id: `493ebe46-6458-54b3-871c-93bf4863e1e8`
- Learned source tuple: `manual_user_deck_registration/lorehold_variant07_20260624_5570c465c492`
- Deck hash: `5570c465c492f07ba93dc89bfcb97bf3e08ae7e38bab6c7de0b24c77535a8648`

## Local Hermes Evidence

- Initial dry-run artifact: `lorehold_variant_staging_20260624_122547.json`
  - `total=100`, `main=99`, `commander=1`
  - invalid only because local Hermes oracle cache missed 7 cards already present in PostgreSQL.
- Oracle cache backfill artifact: `lorehold_variant07_oracle_cache_backfill_20260624.json`
  - `pg_records=7`
  - `cache_rows_written=8`
  - extra alias row is for `Toralf, God of Fury // Toralf's Hammer`.
- Valid dry-run artifact: `lorehold_variant_staging_20260624_122754.json`
  - `valid=1`, `invalid=0`
- Applied Hermes staging artifact: `lorehold_variant_staging_20260624_122804.json`
  - materialized target deck id `612`
  - backup id `variant_target_612_20260624T122804Z_33b735c449a6`
- Hermes local post-materialization check:
  - `deck_cards`: `rows=100`, `qty=100`, `commander_qty=1`, `distinct_cards=100`

## PostgreSQL Evidence

- Precheck artifact: `lorehold_variant07_pg_registration_20260624_precheck.out`
  - `input_rows=100`
  - `input_qty=100`
  - `commander_qty=1`
  - `resolved_rows=100`
  - `missing_rows=0`
  - existing target before apply: `deck_rows=0`, `deck_qty=0`, `learned_rows=0`
- Apply artifact: `lorehold_variant07_pg_registration_20260624_apply.out`
  - `INSERT 0 1` into `decks`
  - `INSERT 0 100` into `deck_cards`
  - `INSERT 0 1` into `commander_learned_decks`
- Postcheck artifact: `lorehold_variant07_pg_registration_20260624_postcheck.out`
  - `decks`: one row, `format=commander`, `archetype=spell-copy-combo-variant`, `not_deleted=true`
  - `deck_cards`: `rows=100`, `qty=100`, `commander_qty=1`, `distinct_cards=100`
  - `commander_learned_decks`: one inactive row, `card_count=100`, `legal_status=registered_pending_card_rule_validation`
  - `missing_card_rows=0`

## Scope

This registration did not modify the official Lorehold deck id `6`, did not apply a deck swap, and did not promote the learned row as active.

## Pending For Card Validator

The Hermes staging report is valid for deck/cardinality, but has `23` cards with `no_verified_executable_battle_rule`.
