# PG657b Trusted Oracle Hash Backfill

Status: `prepared_pending_apply`.

Purpose: repair trusted executable `card_battle_rules` rows that are missing
`oracle_hash` by copying `md5(cards.oracle_text)` from the same `card_id`.
This is metadata-only; it does not change `effect_json`, status, scope, or
runtime behavior.

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg657b_trusted_oracle_hash_backfill_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg657b_trusted_oracle_hash_backfill_new_server_apply.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg657b_trusted_oracle_hash_backfill_new_server_postcheck.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg657b_trusted_oracle_hash_backfill_new_server_rollback.sql`

Backup table:

- `manaloom_deploy_audit.pg657b_trusted_oracle_hash_backfill_20260708`
