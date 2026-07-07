# PG596B Oracle Hash Backfill Apply Evidence

Generated UTC: 2026-07-07

## Scope

PG596B fixed a contract issue exposed by the final PG/Hermes/SQLite audit:
trusted executable curated/manual battle rules in PostgreSQL were missing
`oracle_hash`.

- Target: `127.0.0.1:15432/halder`
- Rules missing `oracle_hash` before apply: 44
- Safe candidates: 44
- Missing card matches: 0
- Ambiguous hashes: 0
- Hash source: `md5(coalesce(cards.oracle_text, ''))` using the rule's
  durable `card_id`.

## Package

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg596b_oracle_hash_backfill_new_server_precheck.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg596b_oracle_hash_backfill_new_server_apply.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg596b_oracle_hash_backfill_new_server_postcheck.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/pg596b_oracle_hash_backfill_new_server_rollback.sql`
- Backup table: `public.pg596b_oracle_hash_backfill_backup`

## Apply Result

- Backup rows inserted: 44
- Rows updated: 44
- Postcheck:
  - `trusted_executable_rules_missing_oracle_hash`: 0
  - `backup_rows`: 44
  - `checked_sample_rows`: 44
  - `checked_sample_rows_with_hash`: 44

## Sync And Audits

- PG -> SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg596b_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
  - `pg_rows_loaded`: 9359
  - `sqlite_inserted_or_updated`: 9123
  - `canonical_snapshot_rows_exported`: 6802
- PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260707_post_pg596b_oracle_hash_backfill_new_server_final.md`
  - Status: `pass`
  - Checks: 51/51 pass
- Final readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260707_post_pg596b_oracle_hash_backfill_new_server.md`
  - `battle_and_oracle_ready`: 5768
  - `battle_family_mapper_required`: 28105
  - The previous `trusted_rule_oracle_hash_backfill` lane is no longer present.
- `./scripts/quality_gate.sh server-target`: pass.

## Why This Was Needed

The PG596 card promotion itself was valid, but the final cross-surface audit
found older trusted executable rows without hashes. Leaving those rows in place
would keep the project contract red even though the new PG596 rows were clean.
PG596B is therefore a narrow integrity backfill, not a card-rule behavior
change.
