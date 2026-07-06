# PG577b Oracle Hash Integrity Backfill

- Date: `2026-07-06`
- Database target: `127.0.0.1:15432/halder`
- Purpose: unblock the PG/Hermes/SQLite contract after PG577 by filling old
  trusted executable PostgreSQL rows that still lacked `oracle_hash`.
- Scope: metadata-only integrity backfill. `effect_json`, `deck_role_json`,
  runtime behavior, source, review status, execution status, and card identity
  were not changed.

## Precheck

- Trusted executable PostgreSQL rules missing `oracle_hash` before: `44`.
- Safely resolved hash rows from current PostgreSQL `cards.oracle_text`: `44`.
- Missing Oracle text rows: `0`.

Filter:

```sql
source IN ('curated', 'manual')
AND review_status IN ('verified', 'active')
AND execution_status IN ('auto', 'executable')
AND COALESCE(oracle_hash, '') = ''
```

## Apply

- Backup table:
  `manaloom_deploy_audit.pg577b_oracle_hash_integrity_backfill_new_server_20260706_22320`
- Backup rows: `44`
- Updated rows: `44`
- Mutation: filled `public.card_battle_rules.oracle_hash` from
  `md5(public.cards.oracle_text)` through `card_id -> cards.id`.

## Postcheck

- Trusted executable PostgreSQL rules missing `oracle_hash` after: `0`.

## Sync and Gate

- PG -> SQLite sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg577b_oracle_hash_integrity_backfill_sync_report.json`
- Selected cards: `44`
- PostgreSQL rows loaded: `65`
- SQLite rows inserted or updated: `66`
- Canonical snapshot rows exported: `6647`
- PG/Hermes/SQLite contract after sync: `pass` (`51/51`)

This backfill does not change the PG577 card-rule package count or queue
impact. The post-backfill authoritative queue remains:

- `target_identity_count=25343`
- `xmage_authoritative_source_count=25029`
- `manual_semantic_decision_units_remaining=314`
- `tutor::xmage_library_search_variant_review_v1=567`
