# PG641 Trusted Rule Oracle Hash Backfill

- Target: `127.0.0.1:15432/halder`
- Scope: metadata-only integrity backfill for trusted executable `card_battle_rules` rows.
- Rule: fill missing `oracle_hash` from `md5(cards.oracle_text)` only when the card has non-empty Oracle text.
- Runtime effect: none. This restores lineage/contract metadata for already executable rules.
- Backup table: `manaloom_deploy_audit.pg641_trusted_rule_oracle_hash_backfill_new_server_20260707`

## Files

- `pg641_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `pg641_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `pg641_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `pg641_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
