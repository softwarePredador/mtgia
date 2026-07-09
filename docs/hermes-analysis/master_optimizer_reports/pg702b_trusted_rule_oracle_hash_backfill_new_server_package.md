# PG702B Trusted Rule Oracle Hash Backfill

Status: `prepared_pending_apply`

Purpose: remove the active `trusted_rule_oracle_hash_backfill` readiness lane by filling missing `oracle_hash` on already trusted executable rules. This package does not change rule behavior, review status, execution status, or effect JSON.

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg702b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg702b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg702b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/pg702b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
- Backup table: `manaloom_deploy_audit.pg702b_trusted_rule_oracle_hash_backfill_20260709_081819`
