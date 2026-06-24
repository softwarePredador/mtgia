# Lorehold Variant 10 PG Registration

- Date: 2026-06-24
- Source decklist: `docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-10-user-decklist.md`
- Hermes cache deck id: `615`
- PostgreSQL deck id: `43c026ae-2d92-5049-90fc-1fdad4b04298`
- PostgreSQL learned row id: `a77eb26f-4cae-595c-bfd0-55be138a141b`
- Learned source tuple: `manual_user_deck_registration/lorehold_variant10_20260624_69fc2e8dfcb4`
- Deck hash: `69fc2e8dfcb40e24137a92b8823677e26538768b21602671f46158f3c303a42c`

## Local Hermes Evidence

- Dry-run artifact: `lorehold_variant_staging_20260624_124151.json`
  - `valid=1`, `invalid=0`
  - `total=100`, `main=99`, `commander=1`
  - no oracle cache backfill was needed.
- Applied Hermes staging artifact: `lorehold_variant_staging_20260624_124206.json`
  - materialized target deck id `615`
  - backup id `variant_target_615_20260624T124206Z_a1b04d90e33e`
- Hermes local post-materialization check:
  - `deck_cards`: `rows=84`, `qty=100`, `commander_qty=1`, `distinct_cards=84`

## PostgreSQL Evidence

- Precheck artifact: `lorehold_variant10_pg_registration_20260624_precheck.out`
  - `input_rows=84`
  - `input_qty=100`
  - `commander_qty=1`
  - `resolved_rows=84`
  - `missing_rows=0`
  - existing target before apply: `deck_rows=0`, `deck_qty=0`, `learned_rows=0`
- Apply artifact: `lorehold_variant10_pg_registration_20260624_apply.out`
  - `INSERT 0 1` into `decks`
  - `INSERT 0 84` into `deck_cards`
  - `INSERT 0 1` into `commander_learned_decks`
- Postcheck artifact: `lorehold_variant10_pg_registration_20260624_postcheck.out`
  - `decks`: one row, `format=commander`, `archetype=spell-copy-big-spells-variant`, `not_deleted=true`
  - `deck_cards`: `rows=84`, `qty=100`, `commander_qty=1`, `distinct_cards=84`
  - `commander_learned_decks`: one inactive row, `card_count=100`, `legal_status=registered_pending_card_rule_validation`
  - `missing_card_rows=0`

## Scope

This registration did not modify the official Lorehold deck id `6`, did not apply a deck swap, and did not promote the learned row as active.

## Pending For Card Validator

The Hermes staging report is valid for deck/cardinality, but has `14` cards with `no_verified_executable_battle_rule`.
