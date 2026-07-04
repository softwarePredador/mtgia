# PG411 Oracle Hash Integrity Backfill

- Database target: `127.0.0.1:15432/halder`
- Purpose: fill missing `oracle_hash` on old trusted executable PostgreSQL `card_battle_rules` rows found by the post-PG411 PG/Hermes/SQLite contract audit.
- Scope: metadata-only integrity backfill. `effect_json`, `deck_role_json`, statuses, identities, and executable behavior were not changed.

## Precheck

- Trusted executable rules missing `oracle_hash` before: `44`
- Safely resolved unique hash rows from current PostgreSQL `cards.oracle_text`: `44`
- Unresolved rows: `0`
- Duplicate key rows: `0`
- Distinct affected cards: `44`

## Apply

- Backup table: `manaloom_deploy_audit.pg411_oracle_hash_integrity_backfill_new_server_20260704_152449`
- Backup rows: `44`
- Updated rows: `44`
- Mutation: filled `card_battle_rules.oracle_hash` from `md5(coalesce(cards.oracle_text, ''))` through the primary rule key `(normalized_name, logical_rule_key)` and source join `card_id -> cards.id` on the new server.

## Postcheck

- Trusted executable rules missing `oracle_hash` after: `0`
- Backup rows checked: `44`
- Restored hash matches: `44`

## Sync

- Report: `docs/hermes-analysis/master_optimizer_reports/pg411_oracle_hash_integrity_backfill_new_server_pg_to_sqlite_sync.json`
- PG rows loaded: `4243`
- SQLite inserted or updated: `4238`
- Canonical snapshot rows exported: `5377`

## Final Gate

- PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg411_triggered_recursion_to_hand_new_server_after_hash_backfill_final.md`
- Result: `pass`, `51/51` checks.
