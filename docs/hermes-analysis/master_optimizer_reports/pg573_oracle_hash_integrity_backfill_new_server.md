# PG573 Oracle Hash Integrity Backfill

- Date: `2026-07-06`
- Database target: `127.0.0.1:15432/halder`
- Purpose: unblock the PG/Hermes/SQLite contract after PG573 by filling old trusted executable PostgreSQL rows that still lacked `oracle_hash`.
- Scope: metadata-only integrity backfill. `effect_json`, `deck_role_json`, runtime behavior, and review status were not changed.

## Precheck

- Trusted executable PostgreSQL rules missing `oracle_hash` before: `44`.
- Safely resolved hash rows from current PostgreSQL `cards.oracle_text`: `44`.

## Apply

- Backup table: `manaloom_deploy_audit.pg573_oracle_hash_integrity_backfill_new_server_20260706_211900`.
- Backup rows: `44`.
- Updated rows: `44`.
- Mutation: filled `card_battle_rules.oracle_hash` from `md5(coalesce(cards.oracle_text, ''))` through `card_id -> cards.id`.

## Postcheck

- Trusted executable PostgreSQL rules missing `oracle_hash` after: `0`.

## Sync and Gate

- PG -> SQLite sync report: `pg573_oracle_hash_integrity_backfill_sync_report.json`.
- Selected cards: `43`; affected rules: `44` because `Valakut Awakening // Valakut Stoneforge` has two trusted executable rows.
- PostgreSQL rows loaded: `64`.
- SQLite rows inserted or updated: `64`.
- Canonical snapshot rows exported: `6617`.
- PG/Hermes/SQLite contract after sync: `pass` (`51/51`).
