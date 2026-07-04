# PG405 Oracle Hash Integrity Backfill

- Database target: `127.0.0.1:15432/halder`
- Purpose: fill missing `oracle_hash` on old trusted executable PostgreSQL `card_battle_rules` rows after the post-PG405 contract audit found `trusted_executable_rules_missing_oracle_hash=44`.
- Scope: metadata-only integrity backfill. `effect_json` and `deck_role_json` were not changed.

## Precheck

- Trusted executable rules missing `oracle_hash` before: `44`
- Safely resolved unique hash rows from current PostgreSQL `cards.oracle_text`: `44`
- Ambiguous hash rows: `0`
- Unresolved rows: `0`

## Apply

- Backup table: `pg405_oracle_hash_integrity_backfill_backup`
- Backup rows: `44`
- Updated rows: `44`
- Mutation: filled `card_battle_rules.oracle_hash` from `md5(coalesce(cards.oracle_text, ''))` using normalized-name and split-face name matching on the new server.

## Postcheck

- Trusted executable rules missing `oracle_hash` after: `0`
- Backfilled rows now hash-backed: `44`

## Sync

- Report: `docs/hermes-analysis/master_optimizer_reports/pg405_oracle_hash_integrity_backfill_new_server_pg_to_sqlite_sync.json`
- Selected cards: `44`
- SQLite inserted or updated: `66`
- Canonical snapshot rows exported: `5314`
