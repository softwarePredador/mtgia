# PG839 Trusted Rule Oracle Hash Backfill Evidence - 2026-07-12

Scope: metadata-only PostgreSQL backfill for trusted battle rules that were
already `review_status='verified'` and `execution_status='auto'`, but still had
empty `card_battle_rules.oracle_hash`.

Database target: `server/bin/with_new_server_pg.sh`
sanitized target `127.0.0.1:15432/halder`.

## Precheck

File:
`docs/hermes-analysis/master_optimizer_reports/pg839_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`

Result:

- `would_backfill_rows`: `32`
- `distinct_cards`: `31`
- `distinct_rule_keys`: `32`
- `null_hash_rows`: `32`
- `empty_hash_rows`: `0`
- `empty_oracle_hash_rows`: `0`
- `backup_table_already_exists`: `false`

The 32 rows are curated, verified, auto-executable rules with non-empty
`cards.oracle_text`. The extra row versus card count is the second verified rule
on `Valakut Awakening // Valakut Stoneforge`.

## Apply

File:
`docs/hermes-analysis/master_optimizer_reports/pg839_trusted_rule_oracle_hash_backfill_new_server_apply.sql`

Result:

- `backup_rows`: `32`
- `updated_rows`: `32`
- Backup table:
  `manaloom_deploy_audit.pg839_trusted_rule_oracle_hash_backfill_new_server_20260712`

## Postcheck

File:
`docs/hermes-analysis/master_optimizer_reports/pg839_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`

Result:

- `trusted_verified_auto_rules_missing_oracle_hash`: `0`
- `backup_rows`: `32`
- `updated_rows_with_current_oracle_hash`: `32`
- Remaining detail rows: `0`

## Sync

Battle rule PG -> SQLite:
`docs/hermes-analysis/master_optimizer_reports/pg839_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`

- `pg_rows_loaded`: `52`
- `sqlite_inserted_or_updated`: `57`
- `canonical_snapshot_rows_exported`: `6707`

Metadata PG -> Hermes:
`docs/hermes-analysis/master_optimizer_reports/pg839_trusted_rule_oracle_hash_backfill_new_server_pg_metadata_to_hermes_sync.json`

- `requested_unique_names`: `7654`
- `postgres_cards_matched`: `7837`
- `sqlite_cache_alias_rows`: `7759`
- `deck_cards_backfill.card_id_rows_updated`: `94`
- `deck_cards_backfill.rows_total`: `2699`
- `deck_cards_backfill.matched_cache_rows`: `2699`
- `unresolved_count`: `1`

## Readiness

File:
`docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg839_hash_backfill_new_server.json`

Post-PG839 lane counts:

- `battle_and_oracle_ready`: `6725`
- `battle_family_mapper_required`: `27069`
- `battle_rule_verification_required`: `70`
- `generic_runtime_or_no_card_rule`: `359`
- `commander_illegal_block`: `2997`
- `digital_non_commander_rule_exception`: `3`
- `official_oracle_identity_unavailable`: `3`

The previous transient `trusted_rule_oracle_hash_backfill` lane is gone.

## Audits

- XMage strategy consistency:
  `xmage_strategy_consistency_audit_20260712_post_pg839_hash_backfill_new_server`
  -> `pass`, `26/26`.
- Operational surface alignment:
  `operational_surface_alignment_audit_20260712_post_pg839_hash_backfill_new_server`
  -> `pass`, `48/48`.
- Legacy contamination:
  `legacy_contamination_audit_20260712_post_pg839_hash_backfill_new_server`
  -> `pass`, `32/32`.
- PG/Hermes/SQLite contract:
  `pg_hermes_sqlite_contract_audit_20260712_post_pg839_hash_backfill_new_server`
  -> `pass`, `51/51`.

No battle E2E was required for PG839 because no executable effect model,
runtime adapter, or `effect_json` behavior changed; this package only attached
current Oracle hashes to already verified/auto rules and then synced the cache.
