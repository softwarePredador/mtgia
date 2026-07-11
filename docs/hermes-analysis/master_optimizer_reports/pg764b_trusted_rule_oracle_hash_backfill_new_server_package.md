# PG764B Trusted Rule Oracle Hash Backfill

- Scope: metadata-only `oracle_hash` backfill for trusted executable `curated` battle rules that already have a resolved `card_id` and non-empty `cards.oracle_text`.
- Reason: PG764 post-apply contract audit found old trusted executable rows without `oracle_hash`; new PG764 Jade Orb rule was not the source of the drift.
- Precheck: `pg764b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- Apply: `pg764b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- Postcheck: `pg764b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- Rollback: `pg764b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

Expected outcome:

- `oracle_hash_rows_backfilled = 55`
- `trusted_executable_rules_missing_oracle_hash = 0`
