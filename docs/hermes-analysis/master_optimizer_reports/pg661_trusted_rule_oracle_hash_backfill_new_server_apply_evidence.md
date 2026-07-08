# PG661 Trusted Rule Oracle Hash Backfill Evidence

- Database target: `127.0.0.1:15432/halder`
- Package: `pg661_trusted_rule_oracle_hash_backfill_new_server`
- Mutation type: metadata-only `oracle_hash` backfill for trusted executable `curated`/`manual` rules.

## Result

- Precheck found `44` missing trusted executable `oracle_hash` rows.
- All `44` groups were safe; `unsafe_groups=0`.
- Apply updated `44` rows and wrote backup table `manaloom_deploy_audit.pg661_trusted_rule_oracle_hash_backfill_new_server_20260708`.
- Postcheck found `trusted_executable_rules_missing_oracle_hash=0`.
- PG -> Hermes/SQLite sync loaded `5962` PostgreSQL rows, updated `5948` SQLite rows, and exported `5925` canonical snapshot rows.
- Final PG/Hermes/SQLite contract audit passed `51/51`.

## Evidence

- `docs/hermes-analysis/master_optimizer_reports/pg661_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg661_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg661_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg661_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg661_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260708_post_pg661_hash_backfill_new_server_final.md`
