# PG702 Boost Keyword Multi-Target Apply Evidence

Status: `applied_synced_validated`

## PG702 behavior package

- Scope: `xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1`
- Cards promoted: `Coordinated Assault`, `Cutthroat Maneuver`, `Press the Advantage`
- PostgreSQL target: `127.0.0.1:15432/halder` through `server/bin/with_new_server_pg.sh`
- Precheck: `pg702_boost_keyword_multi_target_new_server_precheck.out`
  - `target_card_rows=1` for all 3 cards
  - `existing_rule_rows=0`
  - `would_deprecate_shadow_rows=0`
- Apply: `pg702_boost_keyword_multi_target_new_server_apply.out`
  - `upserted_rows=3`
  - `deprecated_shadow_rows=0`
- Postcheck: `pg702_boost_keyword_multi_target_new_server_postcheck.out`
  - `promoted_rule_rows=1` for all 3 cards
  - `promoted_verified_auto_rows=1` for all 3 cards
  - `promoted_oracle_hash_rows=1` for all 3 cards
- PG -> SQLite sync: `pg702_boost_keyword_multi_target_new_server_pg_to_sqlite_sync.json`
- Metadata sync: `pg702_boost_keyword_multi_target_new_server_metadata_sync.json`
- E2E: `pg702_boost_keyword_multi_target_new_server_e2e_validation.md`
  - `status=pass`
  - each scenario affected `target_count=2`

## PG702B integrity backfill

- Purpose: fill missing `oracle_hash` on existing trusted executable rules.
- Precheck: `pg702b_trusted_rule_oracle_hash_backfill_new_server_precheck.out`
  - `backfillable_rule_rows=55`
  - `affected_card_ids=54`
  - `unsafe_missing_hash_rows=0`
  - `source_counts={"curated": 55}`
- Apply: `pg702b_trusted_rule_oracle_hash_backfill_new_server_apply.out`
  - `oracle_hash_rows_backfilled=55`
- Postcheck: `pg702b_trusted_rule_oracle_hash_backfill_new_server_postcheck.out`
  - `remaining_trusted_executable_missing_hash_rows=0`
  - `backfilled_rows_with_expected_hash=55`
- PG -> SQLite sync: `pg702b_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
- Metadata sync: `pg702b_trusted_rule_oracle_hash_backfill_new_server_metadata_sync.json`

## Final validation

- Focused tests: `1115 passed, 206 subtests passed`
- Server target gate: `./scripts/quality_gate.sh server-target` passed.
- Readiness: `global_card_oracle_battle_readiness_20260709_post_pg702b_trusted_rule_oracle_hash_backfill_new_server.md`
  - `snapshot_has_verified_rule=6241`
  - `battle_and_oracle_ready=6216`
  - no `trusted_rule_oracle_hash_backfill` lane remains.
- Queue: `xmage_authoritative_adaptation_queue_20260709_post_pg702b_trusted_rule_oracle_hash_backfill_new_server_commander_legal.md`
  - `xmage_authoritative_adapter_required_count=24424`
  - `xmage_authoritative_parser_gap_count=0`
  - `xmage_missing_source_exception_count=313`
- Exact recheck: `xmage_authoritative_exact_scope_split_20260709_post_pg702b_trusted_rule_oracle_hash_backfill_new_server_recheck.md`
  - `proposal_count=0`
  - `safe_for_batch_pg_package_count=0`
- XMage strategy audit: `xmage_strategy_consistency_audit_20260709_post_pg702b_trusted_rule_oracle_hash_backfill_new_server_final.md` passed.
- Operational surface audit: `operational_surface_alignment_audit_20260709_post_pg702b_trusted_rule_oracle_hash_backfill_new_server_final.md` passed.
- PostgreSQL/Hermes/SQLite contract audit: `pg_hermes_sqlite_contract_audit_20260709_post_pg702b_trusted_rule_oracle_hash_backfill_new_server_final.md` passed `51/51`.
- Legacy contamination audit: `legacy_contamination_audit_20260709_post_pg702b_trusted_rule_oracle_hash_backfill_new_server_final.md` passed.
