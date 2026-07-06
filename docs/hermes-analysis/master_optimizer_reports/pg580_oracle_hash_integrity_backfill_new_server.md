# PG580 Oracle Hash Integrity Backfill New Server

- Database target: `127.0.0.1:15432/halder`
- Purpose: restore missing `oracle_hash` on old trusted executable
  `card_battle_rules` rows found by the post-PG579 PG/Hermes/SQLite contract
  audit.
- Scope: metadata-only integrity backfill. `effect_json`, `deck_role_json`,
  review status, execution status, and rule behavior were not changed.

## Precheck

- trusted executable rows missing `oracle_hash` before: `44`
- safely resolved rows from current PostgreSQL `cards.oracle_text`: `44`
- unresolved rows: `0`
- distinct rule keys: `44`

## Apply

- backup table:
  `manaloom_deploy_audit.pg580_oracle_hash_integrity_backfill_new_server_20260706`
- backup rows: `44`
- updated rows: `44`
- mutation: filled `card_battle_rules.oracle_hash` from
  `md5(coalesce(cards.oracle_text, ''))` through `card_id -> cards.id`.

## Postcheck

- trusted executable rows missing `oracle_hash` after: `0`
- restored rows matching expected Oracle hash: `44`

## Sync

- report:
  `docs/hermes-analysis/master_optimizer_reports/pg580_oracle_hash_integrity_backfill_sync_report.json`
- selected distinct card names: `43`
- PostgreSQL rows loaded by sync: `64`
- SQLite inserted or updated: `64`
- canonical snapshot rows exported: `6654`

PG580 was required because the PG/Hermes/SQLite contract also treats legacy
`source in ('curated', 'manual')`, `review_status in ('verified', 'active')`,
and `execution_status in ('auto', 'executable')` rows as trusted executable
rules. The earlier PG579 package used the newer exact package status fields and
was not the source of this failure.
