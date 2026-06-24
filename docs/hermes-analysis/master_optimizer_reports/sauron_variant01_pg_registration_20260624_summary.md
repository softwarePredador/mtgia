# Sauron Variant 01 PG Registration

- Date: 2026-06-24
- Source decklist: `docs/hermes-analysis/manaloom-knowledge/decks/sauron-the-dark-lord/2026-06-24-variant-01-user-decklist.md`
- Hermes cache deck id: `620`
- PostgreSQL deck id: `c2230827-7963-52e4-a6ba-298d7be3478a`
- PostgreSQL learned row id: `28600f83-7925-5ce8-99ed-833d7c00febc`
- Learned source tuple: `manual_user_deck_registration/sauron_variant01_20260624_6aa4f012e11d`
- Deck hash: `6aa4f012e11d7122d4652beead17c02c7e06e5e872de9932ab914f3b5556cadc`

## Resolution Evidence

- Resolution artifact: `sauron_variant01_resolution_20260624.json`
  - `input_rows=89`
  - `input_qty=100`
  - `resolved_rows=89`
  - `missing_rows=0`
- Commander input `Sauron, the Dark Lord` resolved to PostgreSQL card
  `Sauron, the Dark Lord`.
- Multi-quantity rows were preserved as pasted:
  - `Island=2`
  - `Mountain=2`
  - `Nazgûl=9`
  - `Swamp=2`

## PostgreSQL Evidence

- Precheck artifact: `sauron_variant01_pg_registration_20260624_precheck.out`
  - `input_rows=89`
  - `input_qty=100`
  - `commander_qty=1`
  - `resolved_rows=89`
  - `missing_rows=0`
  - existing target before apply: `deck_rows=0`, `deck_qty=0`,
    `learned_rows=0`
- Apply artifact: `sauron_variant01_pg_registration_20260624_apply.out`
  - `INSERT 0 1` into `decks`
  - `INSERT 0 89` into `deck_cards`
  - `INSERT 0 1` into `commander_learned_decks`
  - `COMMIT`
- Postcheck artifact: `sauron_variant01_pg_registration_20260624_postcheck.out`
  - `deck_cards`: `rows=89`, `qty=100`, `commander_qty=1`
  - `commander_learned_decks`: one inactive row, `card_count=100`,
    `legal_status=registered_pending_card_rule_validation`
  - `missing_deck_cards=0`
- Rollback SQL is available at
  `sauron_variant01_pg_registration_20260624_rollback.sql`.

## Local Hermes Evidence

- Cache artifact: `sauron_variant01_hermes_cache_20260624.json`
  - before: `deck_rows=0`, `deck_card_rows=0`
  - after: `deck_id=620`, `rows=89`, `qty=100`, `commanders=1`

## Scope

This registration did not modify any Lorehold deck id, did not apply a deck swap,
and did not promote the learned row as active.

## Pending For Card Validator

This intake validates catalog resolution and deck cardinality only. Executable
card-rule behavior, strategy coherence, and battle simulation for this Sauron
deck remain pending for the card validator.
