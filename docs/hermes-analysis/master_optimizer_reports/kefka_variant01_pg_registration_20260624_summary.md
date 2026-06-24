# Kefka Variant 01 PG Registration

- Date: 2026-06-24
- Source decklist: `docs/hermes-analysis/manaloom-knowledge/decks/kefka-court-mage/2026-06-24-variant-01-user-decklist.md`
- Hermes cache deck id: `617`
- PostgreSQL deck id: `34508aae-e393-577a-97d8-6259353664af`
- PostgreSQL learned row id: `a019fb43-6586-5040-b49a-5e0fe6943abb`
- Learned source tuple: `manual_user_deck_registration/kefka_variant01_20260624_ec4ca73a3063`
- Deck hash: `ec4ca73a3063b8af06bd443b5dfb3d2578ae8df8970446a9b7fc8dbc52eeb1ea`

## Resolution Evidence

- Resolution artifact: `kefka_variant01_resolution_20260624.json`
  - `input_rows=97`
  - `input_qty=100`
  - `resolved_rows=97`
  - `missing_rows=0`
- Commander input `Kefka, Court Mage` resolved to PostgreSQL card
  `Kefka, Court Mage // Kefka, Ruler of Ruin`.

## PostgreSQL Evidence

- Precheck artifact: `kefka_variant01_pg_registration_20260624_precheck.out`
  - `input_rows=97`
  - `input_qty=100`
  - `commander_qty=1`
  - `resolved_rows=97`
  - `missing_rows=0`
  - existing target before apply: `deck_rows=0`, `deck_qty=0`, `learned_rows=0`
- Apply artifact: `kefka_variant01_pg_registration_20260624_apply.out`
  - `INSERT 0 1` into `decks`
  - `INSERT 0 97` into `deck_cards`
  - `INSERT 0 1` into `commander_learned_decks`
  - `COMMIT`
- Postcheck artifact: `kefka_variant01_pg_registration_20260624_postcheck.out`
  - `deck_cards`: `rows=97`, `qty=100`, `commander_qty=1`
  - `commander_learned_decks`: one inactive row, `card_count=100`,
    `legal_status=registered_pending_card_rule_validation`
  - `missing_deck_cards=0`
- Rollback SQL is available at
  `kefka_variant01_pg_registration_20260624_rollback.sql`.

## Local Hermes Evidence

- Cache artifact: `kefka_variant01_hermes_cache_20260624.json`
  - before: `deck_rows=0`, `deck_card_rows=0`
  - after: `deck_id=617`, `rows=97`, `qty=100`, `commanders=1`

## Scope

This registration did not modify any Lorehold deck id, did not apply a deck swap,
and did not promote the learned row as active.

## Pending For Card Validator

This intake validates catalog resolution and deck cardinality only. Executable
card-rule behavior, strategy coherence, and battle simulation for this Kefka deck
remain pending for the card validator.
