# PG855 Mana Battery Source Counter Partial Evidence

Status: `applied_and_validated_new_server`.

Scope:

- Primary package: `PG855` promoted the five Mana Battery artifacts:
  `Black Mana Battery`, `Blue Mana Battery`, `Green Mana Battery`,
  `Red Mana Battery`, and `White Mana Battery`.
- Follow-up package: `PG855B` backfilled `oracle_hash` for older trusted
  executable curated rules that already had PostgreSQL Oracle text.

Runtime/model changes:

- Added dynamic mana amount source
  `source_named_counter_count_plus_base`.
- Added mana-source activation counter cost event
  `mana_source_activation_counter_cost_paid`.
- Modeled the XMage `DynamicManaAbility` portion of the Mana Batteries as
  `mana_source_only`; the separate `{2}, {T}: Put a charge counter...`
  auxiliary ability remains explicitly unmodeled in the promoted rule.

PostgreSQL apply:

- `PG855` precheck found `5` target rows, `0` existing rule rows, and `0`
  shadow rows to deprecate.
- `PG855` apply result: `upserted_rows=5`,
  `deprecated_shadow_rows=0`.
- `PG855` postcheck: all `5` rows promoted with `review_status=verified`,
  `execution_status=auto`, `rule_version=2`, and non-empty `oracle_hash`.
- `PG855B` precheck found `32` trusted executable curated rows missing
  `oracle_hash`, covering `31` cards.
- `PG855B` apply result: `oracle_hash_rows_backfilled=32`.
- `PG855B` postcheck: `rows_still_missing_oracle_hash=0`,
  `cards_still_missing_oracle_hash=0`, `backup_rows=32`.

Sync:

- PG855 PG -> SQLite:
  `pg_rows_loaded=5`, `sqlite_inserted_or_updated=5`,
  `canonical_snapshot_rows_exported=7849`.
- PG855 metadata sync:
  `requested_unique_names=8595`, `postgres_cards_matched=8786`,
  `sqlite_cache_alias_rows=8725`.
- PG855B PG -> SQLite:
  `pg_rows_loaded=6832`, `sqlite_inserted_or_updated=9902`,
  `canonical_snapshot_rows_exported=6781`.
- PG855B metadata sync:
  `requested_unique_names=8595`, `postgres_cards_matched=8786`,
  `sqlite_cache_alias_rows=8725`.

E2E:

- Current-state E2E after PG855B:
  `pg855_mana_battery_source_counter_partial_new_server_e2e_validation_after_pg855b`.
- Status: `pass`.
- Stages passed: PostgreSQL source of truth, SQLite Hermes cache, canonical
  snapshot fallback, runtime `get_card_effect`, and battle execution.
- Battle execution: `5` scenarios, `10` events.
- Each Mana Battery produced `3` mana from `1 + 2` charge counters and tapped
  as expected.

Global readiness after PG855B:

- `all_known_cards=34331`.
- `battle_and_oracle_ready=6799`.
- `battle_family_mapper_required=26995`.
- `battle_rule_verification_required=70`.
- `snapshot_has_any_rule=8055`.
- `snapshot_has_verified_rule=6906`.
- `trusted_rule_oracle_hash_backfill` no longer appears in lane counts.

Queue after PG855:

- `target_identity_count=24084`.
- `xmage_authoritative_source_count=23771`.
- `xmage_authoritative_adapter_required_count=23771`.
- `xmage_authoritative_parser_gap_count=0`.
- `xmage_missing_source_exception_count=313`.
- `ramp_permanent::xmage_artifact_mana_source_variant_review_v1` decreased
  from `106` to `101`.
- Exact-scope recheck after PG855 returned `proposal_count=0` and
  `safe_for_batch_pg_package_count=0` for the newly supported subpattern.

Audits:

- `xmage_strategy_consistency_audit_20260713_post_pg855_mana_battery_source_counter_partial_new_server_final`:
  `pass`, `26/26`.
- `operational_surface_alignment_audit_20260713_post_pg855_mana_battery_source_counter_partial_new_server_final`:
  `pass`, `48/48`.
- `legacy_contamination_audit_20260713_post_pg855_mana_battery_source_counter_partial_new_server_final`:
  `pass`, `32/32`.
- `pg_hermes_sqlite_contract_audit_20260713_post_pg855_mana_battery_source_counter_partial_new_server_final_new_server`:
  `pass`, `51/51`.

Tracked SQL package files:

- `pg855_mana_battery_source_counter_partial_new_server_package_precheck.sql`
- `pg855_mana_battery_source_counter_partial_new_server_package_apply.sql`
- `pg855_mana_battery_source_counter_partial_new_server_package_postcheck.sql`
- `pg855_mana_battery_source_counter_partial_new_server_package_rollback.sql`
- `pg855b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `pg855b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `pg855b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `pg855b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
