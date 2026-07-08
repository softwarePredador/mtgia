# PG665B Trusted Rule Oracle Hash Backfill Evidence

- Applied UTC: `2026-07-08`
- PostgreSQL target: `127.0.0.1:15432/halder`
- Source SQL: existing metadata-only
  `pg661_trusted_rule_oracle_hash_backfill_new_server_*` package

## Purpose

The final PG/Hermes/SQLite contract audit after PG665 found `44` older trusted
executable PostgreSQL rules still missing `oracle_hash`. This was unrelated to
the new PG665 ETB mana rows: it was the same legacy curated/manual metadata
gap already handled by the narrow trusted-rule hash backfill in earlier waves.

## Precheck

- Missing trusted executable PostgreSQL rule hashes: `44`
- Safe groups: `44`
- Unsafe groups: `0`

## Apply

- Updated rows: `44`
- Backup rows: `44`

## Postcheck

- Trusted executable PostgreSQL rules missing `oracle_hash`: `0`
- Backup rows: `44`
- Annotated rows: `44`

## Sync And Gate

- PG -> SQLite sync report:
  `pg665b_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
- Final PG/Hermes/SQLite contract audit:
  `pg_hermes_sqlite_contract_audit_20260708_post_pg665b_trusted_rule_oracle_hash_backfill_new_server_final.md`
- Contract result: `51/51` checks passed.
