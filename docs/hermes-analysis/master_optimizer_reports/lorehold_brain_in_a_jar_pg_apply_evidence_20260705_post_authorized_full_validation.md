# Lorehold Brain in a Jar PG Apply Evidence

- Generated at: `2026-07-05T11:36:51Z`
- Scope: `Brain in a Jar`
- User authorization: total authorization received in current Codex thread
- PostgreSQL target: remote server, sanitized in command output; no credentials stored here
- Deck 607 mutated: `false`
- Deck materialized: `false`
- Natural battle run: `false`

## Precheck

- target_card_rows: `1`
- existing_rule_rows: `0`
- expected_rule_rows_before: `0`
- active_same_scope_rows_before: `0`
- logical_rule_key: `battle_rule_v1:aedfa4929249f55c1d607effe109f3f3`
- battle_model_scope: `xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1`
- oracle_hash: `41468898bf6400763de517269fdeb456`

## Apply

- SQL file: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_package_preflight_20260705_post_authorized_full_validation_apply.sql`
- transaction: `COMMIT`
- upserted_rows: `1`
- backup_rows_before_apply: `0`
- PostgreSQL identifier note: backup table name was truncated by PostgreSQL to `lorehold_brain_in_a_jar_pg_package_20260705_post_authorized_ful`

## Postcheck

- promoted_rule_rows: `1`
- promoted_verified_auto_rows: `1`
- promoted_oracle_hash_rows: `1`
- promoted_scope_rows: `1`
- promoted_brain_free_cast_rows: `1`
- promoted_rule_version_rows: `1`
- backup_rows: `0`

## SQLite Sync

- Sync report: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_to_sqlite_sync_20260705_post_authorized_full_validation.json`
- selected_cards: `Brain in a Jar`
- pg_rows_loaded: `1`
- sqlite_inserted_or_updated: `1`
- canonical_snapshot_rows_exported: `5957`

## Post-Apply Deckbuilding State

- Brain active rule count: `1`
- Brain safe cut count: `0`
- Candidate scoreable row count: `0`
- Planner status: `miracle_next_route_planner_selected_brain_seed_cut_mining_keep_607`
- Recommended next action: `mine_named_brain_same_lane_seed_safe_cut_no_deck_action`
- Protected baseline: `deck_607`
