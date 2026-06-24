# Y'shtola Variant 01 PG Registration

- Date: 2026-06-24
- Source decklist: `docs/hermes-analysis/manaloom-knowledge/decks/yshtola-nights-blessed/2026-06-24-variant-01-user-decklist.md`
- Hermes cache deck id: `621`
- PostgreSQL deck id: `982cf6a6-c84a-5c3e-b9fc-e79127598b89`
- PostgreSQL learned row id: `3ee6a17e-c72f-540e-90fe-e05dc37ed5e9`
- Learned source tuple: `manual_user_deck_registration/yshtola_variant01_20260624_2165c4d41e85`
- Deck hash: `2165c4d41e8526ce5b0deae48422dba71d5a585747cdde5c9d6fdca0d34406fd`

## Resolution Evidence

- Resolution artifact: `yshtola_variant01_resolution_20260624.json`
  - `input_rows=93`
  - `input_qty=100`
  - `resolved_rows=93`
  - `missing_rows=0`
- Commander input `Y'shtola, Night's Blessed` resolved to PostgreSQL card
  `Y'shtola, Night's Blessed`.
- Multi-quantity rows were preserved as pasted:
  - `Island=3`
  - `Plains=3`
  - `Swamp=4`

## PostgreSQL Evidence

- Precheck artifact: `yshtola_variant01_pg_registration_20260624_precheck.out`
  - `input_rows=93`
  - `input_qty=100`
  - `commander_qty=1`
  - `resolved_rows=93`
  - `missing_rows=0`
  - existing target before apply: `deck_rows=0`, `deck_qty=0`,
    `learned_rows=0`
- Apply artifact: `yshtola_variant01_pg_registration_20260624_apply.out`
  - `INSERT 0 1` into `decks`
  - `INSERT 0 93` into `deck_cards`
  - `INSERT 0 1` into `commander_learned_decks`
  - `COMMIT`
- Postcheck artifact: `yshtola_variant01_pg_registration_20260624_postcheck.out`
  - `deck_cards`: `rows=93`, `qty=100`, `commander_qty=1`
  - `commander_learned_decks`: one inactive row, `card_count=100`,
    `legal_status=registered_pending_card_rule_validation`
  - `missing_deck_cards=0`
- Rollback SQL is available at
  `yshtola_variant01_pg_registration_20260624_rollback.sql`.

## Local Hermes Evidence

- Cache artifact: `yshtola_variant01_hermes_cache_20260624.json`
  - before: `deck_rows=0`, `deck_card_rows=0`
  - after: `deck_id=621`, `rows=93`, `qty=100`, `commanders=1`

## Scope

This registration did not modify any Lorehold deck id, did not apply a deck swap,
and did not promote the learned row as active.

## Pending For Card Validator

This intake validates catalog resolution and deck cardinality only. Executable
card-rule behavior, strategy coherence, and battle simulation for this
Y'shtola deck remain pending for the card validator.
