# PG729 Activated Draw Tap/Counter Costs Evidence - 2026-07-10

## Scope

PG729 closed the narrow XMage -> ManaLoom adapter subpattern for permanent
activated draw abilities whose activation cost requires either:

- tapping another matching controlled permanent, or
- removing a counter from a controlled permanent.

Promoted cards:

- Azami, Lady of Scrolls
- O'aka, Traveling Merchant
- Soul Diviner

Runtime scope:

- `xmage_permanent_simple_activated_draw_v1`

## Runtime And Parser Changes

- `xmage_authoritative_exact_scope_split.py` now maps:
  - `TapTargetCost` for untapped Wizard costs.
  - `RemoveCounterCost` with generic `any` counter costs.
  - nonland permanent and artifact/creature/land/planeswalker constraints.
- `battle_analyst_v9.py` now pays `activation_tap_cost` and
  `activation_remove_counter_cost` for simple activated draw permanents.
- `xmage_batch_pg_package_builder.py` now emits tap-cost and counter-cost
  fixtures for simple activated draw E2E scenarios.
- `battle_package_end_to_end_validation.py` now verifies tapped cost targets,
  removed counter targets, concrete counter type, and state mutation.

## PostgreSQL Apply

Target database:

- `127.0.0.1:15432/halder`

Precheck:

- target card rows: 1 for each promoted card
- existing rule rows: 0 for each promoted card
- expected rule rows before apply: 0
- shadow rows to deprecate: 0

Apply:

- deprecated shadow rows: 0
- upserted rows: 3

Postcheck:

| Card | Review | Execution | Oracle hash | Scope |
| --- | --- | --- | --- | --- |
| Azami, Lady of Scrolls | verified | auto | present | xmage_permanent_simple_activated_draw_v1 |
| O'aka, Traveling Merchant | verified | auto | present | xmage_permanent_simple_activated_draw_v1 |
| Soul Diviner | verified | auto | present | xmage_permanent_simple_activated_draw_v1 |

Trusted executable rules missing `oracle_hash` after PG729:

- 0

## Sync And E2E Evidence

PG -> SQLite sync for PG729:

- `pg_rows_loaded=3`
- `sqlite_inserted_or_updated=3`
- `canonical_snapshot_rows_exported=7332`
- selected cards: 3

Hermes metadata sync:

- requested unique names: 8088
- PostgreSQL cards matched: 8279
- SQLite cache alias rows: 8216
- deck_cards matched: 2699/2699
- card id updates: 96
- unresolved: 1

E2E package validation:

- status: `pass`
- stages: PostgreSQL source, SQLite cache, canonical snapshot fallback,
  runtime `get_card_effect`, and battle execution all passed.
- battle scenarios: 3
- Azami tapped an untapped Wizard cost target and drew 1 card.
- O'aka tapped source, removed one +1/+1 counter, and drew 1 card.
- Soul Diviner tapped source, removed one +1/+1 counter, and drew 1 card.

## Readiness After PG729

Global readiness:

- total cards: 34331
- snapshot has any rule: 7538
- snapshot has verified rule: 6362
- `battle_and_oracle_ready`: 6337
- `battle_family_mapper_required`: 27539

XMage authoritative queue:

- target identities: 24616
- XMage authoritative source count: 24303
- `xmage_authoritative_adapter_required_count`: 24303
- `xmage_authoritative_parser_gap_count`: 0
- missing XMage source exceptions: 313
- `draw_engine::xmage_draw_card_variant_review_v1`: 1569

Final exact-scope splitter recheck:

- proposals: 0
- safe package candidates: 0
- considered supported work unit rows: 7051
- `activated_draw_oracle_cost_not_supported` dropped from 7 to 4.

## Tests And Audits

Focused tests rerun on 2026-07-10:

- `python3 -m py_compile` for splitter, runtime, package builder, and E2E validator: pass
- `test_xmage_authoritative_exact_scope_split.py -k permanent_activated_draw`: 17 passed
- `test_xmage_batch_pg_package_builder.py -k simple_activated_draw`: 3 passed
- `test_battle_package_end_to_end_validation.py -k simple_activated_draw_runner`: 3 passed

Audits:

- `xmage_strategy_consistency_audit`: pass, 26/26
- `operational_surface_alignment_audit`: pass
- `legacy_contamination_audit`: pass
- `pg_hermes_sqlite_contract_audit`: pass, 51/51
- `./scripts/quality_gate.sh server-target`: pass

## Residual

The global goal remains active. PG729 only closes the simple activated-draw
tap-target/remove-counter subpattern. The remaining draw blocked cases are
heterogeneous and still include graveyard activation, reveal-from-hand, and
filtered discard costs.
