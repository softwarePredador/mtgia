# PG851B Trusted Rule Oracle Hash Backfill

Purpose: clear residual trusted executable `card_battle_rules` rows missing
`oracle_hash` after PG851, using current `cards.oracle_text` md5 for rows with
unique card resolution.

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg851b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg851b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg851b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/pg851b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

The apply script aborts if any target row lacks a unique card/Oracle match.
