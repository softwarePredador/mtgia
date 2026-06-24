# Lorehold Variant 04 PG Registration

- Date: 2026-06-24
- Source decklist: `docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-04-user-decklist.md`
- Hermes cache deck id: `609`
- PostgreSQL deck id: `917674eb-6a3d-58de-acce-5a2a3ac9e497`
- PostgreSQL learned row id: `a4767730-e826-5c14-b716-c6906f3d44c3`
- Learned source tuple: `manual_user_deck_registration/lorehold_variant04_20260624_ba7d06f86f23`
- Deck hash: `ba7d06f86f2381388259c4926e684407284f70e313e83f80df922827a67d8f68`

## PostgreSQL Evidence

- Precheck artifact: `lorehold_variant04_pg_registration_20260624_precheck.out`
  - `input_rows=92`
  - `input_qty=100`
  - `commander_qty=1`
  - `resolved_rows=92`
  - `missing_rows=0`
  - existing target before apply: `deck_rows=0`, `deck_qty=0`, `learned_rows=0`
- Apply artifact: `lorehold_variant04_pg_registration_20260624_apply.out`
  - `INSERT 0 1` into `decks`
  - `INSERT 0 92` into `deck_cards`
  - `INSERT 0 1` into `commander_learned_decks`
- Postcheck artifact: `lorehold_variant04_pg_registration_20260624_postcheck.out`
  - `decks`: one row, `format=commander`, `archetype=battle-variant`, `not_deleted=true`
  - `deck_cards`: `rows=92`, `qty=100`, `commander_qty=1`, `distinct_cards=92`
  - `commander_learned_decks`: one inactive row, `card_count=100`, `legal_status=registered_pending_card_rule_validation`
  - `missing_card_rows=0`

## Scope

This registration did not modify the official Lorehold deck id `6`, did not apply a deck swap, and did not promote the learned row as active.

## Pending For Card Validator

The Hermes staging report remains the handoff for rule coverage. It is valid for deck/cardinality, but has `14` cards with `no_verified_executable_battle_rule`.
