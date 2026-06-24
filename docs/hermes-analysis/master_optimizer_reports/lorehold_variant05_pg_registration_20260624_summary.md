# Lorehold Variant 05 PG Registration

- Date: 2026-06-24
- Source decklist: `docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/2026-06-24-variant-05-user-decklist.md`
- Hermes cache deck id: `610`
- PostgreSQL deck id: `8aa57962-3a3e-5351-89fd-e4651456a3bd`
- PostgreSQL learned row id: `757f8ebd-10a4-5f33-82a1-749603afa7e1`
- Learned source tuple: `manual_user_deck_registration/lorehold_variant05_20260624_5154c88a8b0b`
- Deck hash: `5154c88a8b0bff4bff121c164b0aff180b4515e52d46a3fac8b972c4ee026836`

## PostgreSQL Evidence

- Precheck artifact: `lorehold_variant05_pg_registration_20260624_precheck.out`
  - `input_rows=95`
  - `input_qty=100`
  - `commander_qty=1`
  - `resolved_rows=95`
  - `missing_rows=0`
  - existing target before apply: `deck_rows=0`, `deck_qty=0`, `learned_rows=0`
- Apply artifact: `lorehold_variant05_pg_registration_20260624_apply.out`
  - `INSERT 0 1` into `decks`
  - `INSERT 0 95` into `deck_cards`
  - `INSERT 0 1` into `commander_learned_decks`
- Postcheck artifact: `lorehold_variant05_pg_registration_20260624_postcheck.out`
  - `decks`: one row, `format=commander`, `archetype=artifact-control-variant`, `not_deleted=true`
  - `deck_cards`: `rows=95`, `qty=100`, `commander_qty=1`, `distinct_cards=95`
  - `commander_learned_decks`: one inactive row, `card_count=100`, `legal_status=registered_pending_card_rule_validation`
  - `missing_card_rows=0`

## Scope

This registration did not modify the official Lorehold deck id `6`, did not apply a deck swap, and did not promote the learned row as active.

## Pending For Card Validator

The Hermes staging report is valid for deck/cardinality, but has `29` cards with `no_verified_executable_battle_rule`.
