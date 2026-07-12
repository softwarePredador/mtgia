# PG833B Trusted Rule Oracle Hash Backfill

Status: `prepared_for_apply`.

Purpose: remove the residual trusted executable `card_battle_rules` rows that were missing `oracle_hash` after PG833, so readiness and PG/Hermes audits do not route already-verified rules into `trusted_rule_oracle_hash_backfill`.

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg833b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg833b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg833b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg833b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

Scope:

- only `source IN ('curated', 'manual')`
- only `review_status IN ('verified', 'active')`
- only `execution_status IN ('auto', 'executable')`
- only rows with empty or null `oracle_hash`
- only rows with `card_id` resolving to nonblank `cards.oracle_text`
