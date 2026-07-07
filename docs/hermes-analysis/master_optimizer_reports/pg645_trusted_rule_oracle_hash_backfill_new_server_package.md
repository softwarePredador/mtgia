# PG645 Trusted Rule Oracle Hash Backfill

- Scope: trusted active `card_battle_rules` with missing `oracle_hash`.
- Method: fill `oracle_hash = md5(cards.oracle_text)` only when `card_id` joins to a card with non-empty Oracle text.
- Behavior impact: none. This does not alter `effect_json`, `deck_role_json`, `review_status`, `execution_status`, or `confidence`.
- Purpose: remove `trusted_rule_oracle_hash_backfill` readiness lane and make existing trusted rules identity-safe.

## Files

- Precheck: `pg645_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- Apply: `pg645_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- Postcheck: `pg645_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- Rollback: `pg645_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
