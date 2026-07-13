# PG853B Trusted Rule Oracle Hash Backfill New Server

Status: `prepared_and_applied_after_pg853_contract_audit`.

Purpose: remove residual verified executable `card_battle_rules` rows missing
`oracle_hash` after PG853 so PostgreSQL/Hermes audits keep the current rule
drift contract.

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg853b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg853b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg853b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg853b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
