# PG604B Trusted Rule Oracle Hash Backfill Evidence

Status: `applied_synced_validated`.

Scope:

- Target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`.
- Rows: trusted executable `card_battle_rules` with `source in ('curated', 'manual')`, `review_status in ('verified', 'active')`, `execution_status in ('auto', 'executable')`, and missing `oracle_hash`.
- Backup table:
  `manaloom_deploy_audit.pg604b_trusted_rule_oracle_hash_backfill_new_server_backup`.

Evidence:

- Precheck:
  `missing_hash_rules=44`, `candidate_rules=44`, `safe_candidate_rules=44`,
  `no_card_match_rules=0`, `ambiguous_hash_rules=0`.
- Apply:
  `safe_candidates=44`, `backup_rows_inserted=44`, `rows_updated=44`.
- Postcheck:
  `trusted_executable_rules_missing_oracle_hash=0`, `backup_rows=44`,
  `checked_sample_rows=44`, `checked_sample_rows_with_hash=44`.
- PG -> SQLite/snapshot sync:
  `pg_rows_loaded=9411`, `sqlite_inserted_or_updated=9175`,
  `canonical_snapshot_rows_exported=6854`.
- Metadata sync:
  `postgres cards matched=7822`, `deck_cards matched=2699/2699`.
- Final PG/Hermes/SQLite contract audit:
  `status=pass`, `check_count=51`, `pass=51`.

Files:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg604b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg604b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg604b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg604b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
- Sync:
  `docs/hermes-analysis/master_optimizer_reports/pg604b_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
- Metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg604b_trusted_rule_oracle_hash_backfill_new_server_metadata_sync.json`
- Final audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260707_pg604_destroy_surveil_new_server_final.md`
