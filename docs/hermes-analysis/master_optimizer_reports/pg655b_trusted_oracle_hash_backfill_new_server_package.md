# PG655b Trusted Oracle Hash Backfill Package

Status: `applied_postchecked_synced_validated`.

This package repairs trusted executable `card_battle_rules` rows that still
have empty `oracle_hash`. It does not change `effect_json`, `review_status`, or
`execution_status`.

- Target source: `cards.oracle_text`
- Hash formula: `md5(coalesce(cards.oracle_text, ''))`
- Backup table: `manaloom_deploy_audit.pg655b_trusted_oracle_hash_backfill_20260708`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg655b_trusted_oracle_hash_backfill_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg655b_trusted_oracle_hash_backfill_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg655b_trusted_oracle_hash_backfill_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg655b_trusted_oracle_hash_backfill_new_server_postcheck.sql`

Apply evidence:

- Precheck found `44` backfillable trusted executable rule rows across `43`
  card ids and `44` normalized names, with `unsafe_missing_hash_rows=0`.
- Apply repaired `44` `oracle_hash` values and changed no executable rule
  payload.
- Postcheck confirmed `remaining_trusted_executable_missing_hash_rows=0` and
  `repaired_rows_with_expected_hash=44`.
- PG -> Hermes/SQLite sync loaded `5930` PostgreSQL rows, wrote `5916` SQLite
  rows, and exported `5893` canonical snapshot rows.
