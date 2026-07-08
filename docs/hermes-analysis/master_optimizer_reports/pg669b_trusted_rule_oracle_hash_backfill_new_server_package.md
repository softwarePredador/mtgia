# PG669B trusted rule oracle hash backfill

Status: package prepared for the new-server PostgreSQL target via
`server/bin/with_new_server_pg.sh`.

Purpose:

- Restore the all-card readiness contract after PG669 by filling
  `card_battle_rules.oracle_hash` for pre-existing trusted executable rows.
- Scope is intentionally metadata-only: `review_status in ('verified',
  'active')`, `execution_status = 'auto'`, missing/blank `oracle_hash`, valid
  `card_id`, and non-empty `cards.oracle_text`.
- This package does not create or change battle behavior. It only aligns trusted
  rows with the Oracle hash contract used by readiness/snapshot gates.

Files:

- `pg669b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `pg669b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `pg669b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `pg669b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

Expected precheck:

- `backfillable_rule_rows = 44`
- `affected_card_ids = 43`
- `unsafe_missing_hash_rows = 0`

Expected apply:

- `oracle_hash_rows_backfilled = 44`

Expected postcheck:

- `remaining_trusted_executable_missing_hash_rows = 0`
- `backfilled_rows_with_expected_hash = 44`

Actual result:

- Precheck returned `backfillable_rule_rows = 44`,
  `affected_card_ids = 43`, and `unsafe_missing_hash_rows = 0`.
- Apply returned `oracle_hash_rows_backfilled = 44`.
- Postcheck returned `remaining_trusted_executable_missing_hash_rows = 0`
  and `backfilled_rows_with_expected_hash = 44`.
- PG-to-SQLite sync wrote
  `pg669b_trusted_rule_oracle_hash_backfill_pg_to_sqlite_sync.json` with
  `pg_rows_loaded = 5991`, `sqlite_inserted_or_updated = 5977`, and
  `canonical_snapshot_rows_exported = 5954`.
