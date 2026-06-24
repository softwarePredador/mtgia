# Lorehold Variant 06 PG Registration

- Date: 2026-06-24
- Source decklist: `docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-06-user-decklist.md`
- Hermes cache deck id: `611`
- PostgreSQL deck id: `0936dae3-32c4-5fb8-9c6f-d986670de794`
- PostgreSQL learned row id: `90b0fbe9-683b-53cf-9fc1-75699196f4aa`
- Learned source tuple: `manual_user_deck_registration/lorehold_variant06_20260624_a073b0fdc0db`
- Deck hash: `a073b0fdc0db03c432651caa8f41d275faa6d67e5efb3865daee7ff4ca543298`

## PostgreSQL Evidence

- Precheck artifact: `lorehold_variant06_pg_registration_20260624_precheck.out`
  - `input_rows=90`
  - `input_qty=100`
  - `commander_qty=1`
  - `resolved_rows=90`
  - `missing_rows=0`
  - existing target before apply: `deck_rows=0`, `deck_qty=0`, `learned_rows=0`
- Apply artifact: `lorehold_variant06_pg_registration_20260624_apply.out`
  - `INSERT 0 1` into `decks`
  - `INSERT 0 90` into `deck_cards`
  - `INSERT 0 1` into `commander_learned_decks`
- Postcheck artifact: `lorehold_variant06_pg_registration_20260624_postcheck.out`
  - `decks`: one row, `format=commander`, `archetype=big-spells-variant`, `not_deleted=true`
  - `deck_cards`: `rows=90`, `qty=100`, `commander_qty=1`, `distinct_cards=90`
  - `commander_learned_decks`: one inactive row, `card_count=100`, `legal_status=registered_pending_card_rule_validation`
  - `missing_card_rows=0`

## Scope

This registration did not modify the official Lorehold deck id `6`, did not apply a deck swap, and did not promote the learned row as active.

## Pending For Card Validator

The Hermes staging report is valid for deck/cardinality, but has `14` cards with `no_verified_executable_battle_rule`.
