# Lorehold Variant 11 PG Registration

- Date: 2026-06-24
- Source decklist: `docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-11-user-decklist.md`
- Hermes cache deck id: `616`
- PostgreSQL deck id: `9df6ac2e-6620-5265-8008-1f57c8963d66`
- PostgreSQL learned row id: `5f0082b0-00bb-5b6d-9518-839401e4225e`
- Learned source tuple: `manual_user_deck_registration/lorehold_variant11_20260624_4f48eee5a34d`
- Deck hash: `4f48eee5a34dcf561e4d45f88ced34b9052ccb4f13697d69ce69f06aa2dbb99b`

## Local Hermes Evidence

- Initial dry-run artifact: `lorehold_variant_staging_20260624_124531.json`
  - `total=100`, `main=99`, `commander=1`
  - invalid only because local Hermes oracle cache missed 14 cards already present in PostgreSQL.
- Oracle cache backfill artifact: `lorehold_variant11_oracle_cache_backfill_20260624.json`
  - `pg_records=14`
  - `cache_rows_written=15`
  - extra alias row is for `Rune-Tail, Kitsune Ascendant // Rune-Tail's Essence`.
- Valid dry-run artifact: `lorehold_variant_staging_20260624_124647.json`
  - `valid=1`, `invalid=0`
- Applied Hermes staging artifact: `lorehold_variant_staging_20260624_124701.json`
  - materialized target deck id `616`
  - backup id `variant_target_616_20260624T124701Z_dd46bd7c2dd5`
- Hermes local post-materialization check:
  - `deck_cards`: `rows=84`, `qty=100`, `commander_qty=1`, `distinct_cards=84`

## PostgreSQL Evidence

- Precheck artifact: `lorehold_variant11_pg_registration_20260624_precheck.out`
  - `input_rows=84`
  - `input_qty=100`
  - `commander_qty=1`
  - `resolved_rows=84`
  - `missing_rows=0`
  - existing target before apply: `deck_rows=0`, `deck_qty=0`, `learned_rows=0`
- Apply artifact: `lorehold_variant11_pg_registration_20260624_apply.out`
  - `INSERT 0 1` into `decks`
  - `INSERT 0 84` into `deck_cards`
  - `INSERT 0 1` into `commander_learned_decks`
- Postcheck artifact: `lorehold_variant11_pg_registration_20260624_postcheck.out`
  - `decks`: one row, `format=commander`, `archetype=burn-dragon-control-variant`, `not_deleted=true`
  - `deck_cards`: `rows=84`, `qty=100`, `commander_qty=1`, `distinct_cards=84`
  - `commander_learned_decks`: one inactive row, `card_count=100`, `legal_status=registered_pending_card_rule_validation`
  - `missing_card_rows=0`

## Scope

This registration did not modify the official Lorehold deck id `6`, did not apply a deck swap, and did not promote the learned row as active.

## Pending For Card Validator

The Hermes staging report is valid for deck/cardinality, but has `36` cards with `no_verified_executable_battle_rule`.
