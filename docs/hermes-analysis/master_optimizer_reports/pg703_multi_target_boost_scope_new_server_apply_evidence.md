# PG703 Multi-Target Boost Scope Apply Evidence

Status: `applied_synced_validated`

## PG703 behavior package

- Scope: `xmage_fixed_boost_target_creature_until_eot_spell_v1` and `xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1`
- Cards promoted: `Dauntless Onslaught`, `Hearts on Fire`, `Mischief and Mayhem`, `Nahiri's Stoneblades`, `Sick and Tired`, `Symbiosis`, `Windborne Charge`
- PostgreSQL target: `127.0.0.1:15432/halder` through `server/bin/with_new_server_pg.sh`
- Split: `xmage_authoritative_exact_scope_split_20260710_pg703_multi_target_boost_scope_new_server.md`
  - `proposal_count=7`
  - `safe_for_batch_pg_package_count=7`
- Precheck: `pg703_multi_target_boost_scope_new_server_package_precheck.sql`
  - `target_card_rows=1` for all 7 cards
  - `existing_rule_rows=0`
  - `would_deprecate_shadow_rows=0`
- Apply: `pg703_multi_target_boost_scope_new_server_package_apply.sql`
  - `upserted_rows=7`
  - `deprecated_shadow_rows=0`
- Postcheck: `pg703_multi_target_boost_scope_new_server_package_postcheck.sql`
  - `promoted_rule_rows=1` for all 7 cards
  - `promoted_verified_auto_rows=1` for all 7 cards
  - `promoted_oracle_hash_rows=1` for all 7 cards
- PG -> SQLite sync: `pg703_multi_target_boost_scope_new_server_pg_to_sqlite_sync.json`
- Metadata sync: `pg703_multi_target_boost_scope_new_server_metadata_sync.json`
- E2E: `pg703_multi_target_boost_scope_new_server_e2e_validation.md`
  - `status=pass`
  - all 7 scenarios executed through PostgreSQL, SQLite, canonical snapshot fallback, runtime `get_card_effect`, and battle execution

## PG703B integrity backfill

- Purpose: remove the reappeared `trusted_rule_oracle_hash_backfill` readiness lane by filling missing `oracle_hash` on already trusted executable rules.
- Precheck: `pg703b_trusted_rule_oracle_hash_backfill_new_server_precheck.out`
  - `backfillable_rule_rows=55`
  - `affected_card_ids=54`
  - `unsafe_missing_hash_rows=0`
  - `source_counts={"curated": 55}`
- Apply: `pg703b_trusted_rule_oracle_hash_backfill_new_server_apply.out`
  - `oracle_hash_rows_backfilled=55`
- Postcheck: `pg703b_trusted_rule_oracle_hash_backfill_new_server_postcheck.out`
  - `remaining_trusted_executable_missing_hash_rows=0`
  - `backfilled_rows_with_expected_hash=55`
- PG -> SQLite sync: `pg703b_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
- Metadata sync: `pg703b_trusted_rule_oracle_hash_backfill_new_server_metadata_sync.json`

## Final validation

- Focused tests:
  - `test_xmage_authoritative_exact_scope_split.py`: `913 passed, 206 subtests passed`
  - `test_xmage_batch_pg_package_builder.py`: `144 passed`
  - `test_battle_package_end_to_end_validation.py`: `63 passed`
- Server target gate: `./scripts/quality_gate.sh server-target` passed.
- Readiness: `global_card_oracle_battle_readiness_20260710_post_pg703b_trusted_rule_oracle_hash_backfill_new_server.md`
  - `snapshot_has_verified_rule=6248`
  - `battle_and_oracle_ready=6223`
  - `battle_family_mapper_required=27653`
  - no `trusted_rule_oracle_hash_backfill` lane remains.
- Queue: `xmage_authoritative_adaptation_queue_20260710_post_pg703b_trusted_rule_oracle_hash_backfill_new_server_commander_legal.md`
  - `xmage_authoritative_adapter_required_count=24417`
  - `xmage_authoritative_parser_gap_count=0`
  - `xmage_missing_source_exception_count=313`
- Exact recheck: `xmage_authoritative_exact_scope_split_20260710_post_pg703b_trusted_rule_oracle_hash_backfill_new_server_recheck.md`
  - `proposal_count=0`
  - `safe_for_batch_pg_package_count=0`
- XMage strategy audit: `xmage_strategy_consistency_audit_20260710_post_pg703b_trusted_rule_oracle_hash_backfill_new_server_final.md` passed `26/26`.
- Operational surface audit: `operational_surface_alignment_audit_20260710_post_pg703b_trusted_rule_oracle_hash_backfill_new_server_final.md` passed.
- PostgreSQL/Hermes/SQLite contract audit: `pg_hermes_sqlite_contract_audit_20260710_post_pg703b_trusted_rule_oracle_hash_backfill_new_server_final.md` passed `51/51`.
- Legacy contamination audit: `legacy_contamination_audit_20260710_post_pg703b_trusted_rule_oracle_hash_backfill_new_server_final.md` passed.
