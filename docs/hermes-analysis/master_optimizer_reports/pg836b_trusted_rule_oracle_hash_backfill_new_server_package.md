# PG836B trusted rule oracle_hash backfill

Status: `prepared_metadata_only_pending_apply`.

Purpose: remove the residual trusted executable `card_battle_rules` rows that
were missing `oracle_hash` after PG836, so readiness and PG/Hermes audits do
not route already-verified rules into `trusted_rule_oracle_hash_backfill`.

This package does not change `effect_json`, `deck_role_json`,
`review_status`, `execution_status`, or runtime behavior. It only backfills
`oracle_hash = md5(cards.oracle_text)` for trusted executable rows that already
join to a non-empty PostgreSQL `cards.oracle_text`.

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg836b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg836b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg836b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg836b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
