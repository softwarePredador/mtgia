# PG666/PG667 Bounce Controller Scope Apply Evidence

- Date: `2026-07-08`
- PostgreSQL target: `127.0.0.1:15432/halder`
- Packages:
  - `PG666`: `pg666_bounce_controller_scope_package`
  - `PG667`: `pg667_trusted_rule_oracle_hash_backfill_new_server`

## PG666 Scope

PG666 promoted exact XMage return-to-hand spells where the target controller
matters:

| Card | Scope | Target controller | Target constraints |
| --- | --- | --- | --- |
| `Rescue` | `xmage_return_target_to_hand_spell_v1` | `self` | `{"card_types":["permanent"],"controller_scope":"self"}` |
| `Stern Dismissal` | `xmage_return_target_to_hand_spell_v1` | `opponent` | `{"card_types":["creature","enchantment"],"controller_scope":"opponent"}` |

## PG666 PostgreSQL Evidence

- Precheck: target rows found for both cards; existing expected rule rows were
  `0`; shadow rows to deprecate were `0`.
- Apply: `upserted_rows=2`; `deprecated_shadow_rows=0`.
- Postcheck: each card had `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.
- Direct PG verification after apply:
  - `rescue`: `verified`, `auto`, `oracle_hash=true`, `target_controller=self`.
  - `stern dismissal`: `verified`, `auto`, `oracle_hash=true`,
    `target_controller=opponent`.

## PG666 Runtime And Sync Evidence

- PG -> SQLite sync:
  - `database_target=127.0.0.1:15432/halder`
  - `pg_rows_loaded=5983`
  - `sqlite_inserted_or_updated=8472`
  - `canonical_snapshot_rows_exported=5946`
- E2E package validation:
  - status: `pass`
  - scenarios: `2`
  - stages: PostgreSQL source, SQLite/Hermes cache, canonical snapshot,
    runtime lookup, and battle execution all `pass`.
  - `Rescue` moved the legal target to the active player's hand.
  - `Stern Dismissal` moved the legal target to the opponent's hand.

## PG667 Integrity Backfill

PG667 was required because the post-PG666 PG/Hermes/SQLite contract audit found
trusted executable rules missing `oracle_hash`.

- Precheck:
  - `backfillable_rule_rows=44`
  - `affected_card_ids=43`
  - `unsafe_missing_hash_rows=0`
- Apply:
  - backup table:
    `manaloom_deploy_audit.pg667_trusted_rule_oracle_hash_backfill_20260708`
  - `oracle_hash_rows_backfilled=44`
- Postcheck:
  - `remaining_trusted_executable_missing_hash_rows=0`
  - `backfilled_rows_with_expected_hash=44`
- PG -> SQLite sync:
  - `database_target=127.0.0.1:15432/halder`
  - `pg_rows_loaded=5983`
  - `sqlite_inserted_or_updated=5969`
  - `canonical_snapshot_rows_exported=5946`

## Final Gates

- `test_xmage_authoritative_exact_scope_split` +
  `test_xmage_exact_scope_runtime`: `1273` tests passed.
- `test_xmage_batch_pg_package_builder.py`: `106` tests passed.
- `test_battle_package_end_to_end_validation.py`: `34` tests passed.
- `pg_hermes_sqlite_contract_audit_20260708_post_pg667_trusted_rule_oracle_hash_backfill_new_server_final`: `pass`, `51/51`.
- `xmage_strategy_consistency_audit_20260708_post_pg667_trusted_rule_oracle_hash_backfill_new_server_final`: `pass`, `26/26`.
- `operational_surface_alignment_audit_20260708_post_pg667_trusted_rule_oracle_hash_backfill_new_server_final`: `pass`.
- `legacy_contamination_audit_20260708_post_pg667_trusted_rule_oracle_hash_backfill_new_server_final`: `pass`.

## Final Queue

- Global `battle_and_oracle_ready`: `6043`
- Global `trusted_rule_oracle_hash_backfill`: `0`
- Commander-legal target identities in the XMage queue: `24910`
- XMage authoritative source resolved: `24597`
- XMage missing-source exceptions: `313`
- XMage parser gaps: `0`
- XMage adapter required: `24597`
- Exact split recheck safe candidates: `0`
