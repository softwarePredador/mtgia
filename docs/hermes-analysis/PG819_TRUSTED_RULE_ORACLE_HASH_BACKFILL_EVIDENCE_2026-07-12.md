# PG819 Trusted Rule Oracle Hash Backfill Evidence - 2026-07-12

Status: applied on the new-server PostgreSQL target through
`server/bin/with_new_server_pg.sh`.

Database target reported by sync/E2E: `127.0.0.1:15432/halder`.

## Scope

PG819 backfilled `card_battle_rules.oracle_hash` for trusted executable rules
that were already `review_status='verified'` and `execution_status='auto'`,
but still had a blank `oracle_hash`.

This was metadata integrity only. It did not promote new battle behavior.

## SQL Package

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg819_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg819_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg819_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/pg819_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
- Backup table: `manaloom_deploy_audit.pg819_trusted_rule_oracle_hash_backfill_new_server_20260712`

## Apply Evidence

Precheck:

- `would_backfill_rows`: `32`
- `distinct_cards`: `31`
- `distinct_rule_keys`: `32`
- `null_hash_rows`: `32`
- `empty_oracle_hash_rows`: `0`
- `backup_table_already_exists`: `false`

Apply:

- `backup_rows`: `32`
- `updated_rows`: `32`

Postcheck:

- `trusted_verified_auto_rules_missing_oracle_hash`: `0`
- `backup_rows`: `32`
- `updated_rows_with_current_oracle_hash`: `32`

Direct PostgreSQL check after apply:

- `missing_hash_rule_rows`: `0`
- `missing_hash_card_ids`: `0`

## Sync And Readiness

Battle-rule sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg819_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
- `canonical_snapshot_rows_exported`: `7697`
- `sqlite_inserted_or_updated`: `10096`
- `pg_rows_loaded`: `10318`

Metadata sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg819_trusted_rule_oracle_hash_backfill_new_server_metadata_sync.json`
- PostgreSQL cards matched: `8636`
- SQLite cache alias rows: `8575`
- `deck_cards` backfill matched `2699/2699`

Readiness:

- Report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg819_hash_backfill_new_server.md`
- `battle_and_oracle_ready`: `6641`
- `trusted_rule_oracle_hash_backfill`: absent
- `battle_family_mapper_required`: `27153`
- `battle_rule_verification_required`: `70`

## Gates

- `xmage_strategy_consistency_audit_20260712_post_pg819_hash_backfill_new_server_final`: `pass`, `26/26`
- `operational_surface_alignment_audit_20260712_post_pg819_hash_backfill_new_server_final`: `pass`
- `legacy_contamination_audit_20260712_post_pg819_hash_backfill_new_server_final`: `pass`
- `pg_hermes_sqlite_contract_audit_20260712_post_pg819_hash_backfill_new_server_final`: `pass`, `51/51`
- `./scripts/quality_gate.sh server-target`: `pass`

PG818 E2E was rerun after PG819:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg818_moon_vigil_battlefield_graveyard_count_new_server_post_pg819_e2e.md`
- Status: `pass`
- Validated card: `Moon-Vigil Adherents`
- Battle execution: count `3`, power `3`, toughness `3`
