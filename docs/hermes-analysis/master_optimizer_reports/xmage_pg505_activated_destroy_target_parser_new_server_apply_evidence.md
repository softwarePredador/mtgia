# PG505 Activated Destroy Target Parser Apply Evidence

- Deploy id: `xmage_pg505_activated_destroy_target_parser_new_server`
- Applied at: `2026-07-05T12:23:44Z`
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_package.md`
- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_precheck.out`
- Apply output:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_apply.out`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_postcheck.out`
- Effect-field postcheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_effect_field_postcheck.out`
- PG -> SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_pg_to_sqlite_sync.json`
- Runtime lookup:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_runtime_get_card_effect.out`
- Post-sync battle suite:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_full_battle_suite_post_sync.out`
- Post-sync readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260705_post_pg505_activated_destroy_target_parser_new_server.md`
- Post-sync authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg505_activated_destroy_target_parser_new_server_commander_legal.md`
- Final exact-scope recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg505_activated_destroy_target_parser_new_server_final_recheck.md`

## Apply Result

- `deprecated_shadow_rows=0`
- `upserted_rows=7`
- `COMMIT`

## Promoted Cards

- `Chandler`
- `Dwarven Demolition Team`
- `Dwarven Miner`
- `Fulminator Mage`
- `Goblin Replica`
- `Intrepid Hero`
- `Trench Wurm`

## Postcheck Summary

All 7 promoted rows have:

- `promoted_rule_rows=1`
- `promoted_verified_auto_rows=1`
- `promoted_oracle_hash_rows=1`

Field postcheck confirms the expected activated destroy targets:

- `artifact_creature`
- `wall_creature`
- `nonbasic_land`
- `artifact`
- `creature_power_4_or_greater`

## Cache And Runtime Validation

- PG -> SQLite sync loaded `7` PostgreSQL rows and wrote `7` SQLite rows.
- Canonical fallback snapshot export rows: `5979`.
- Local runtime lookup resolves all 7 cards to
  `xmage_permanent_simple_activated_destroy_target_v1`.

## Runtime And Queue Validation

- Post-sync battle suite: `632` PASS lines and no `Traceback`, `FAILED`,
  `ERROR`, or `SkipTest`.
- Post-sync Commander-legal queue:
  - `target_identity_count=26038`
  - `xmage_authoritative_source_count=25724`
  - `xmage_missing_source_exception_count=314`
  - `xmage_authoritative_parser_gap_count=0`
  - `xmage_authoritative_adapter_required_count=25724`
- Post-sync global readiness:
  - `battle_and_oracle_ready=4912`
  - `battle_family_mapper_required=28961`
  - `generic_runtime_or_no_card_rule=360`
  - `oracle_data_sync=4`
  - `commander_legality_sync=3`
  - `oracle_identity_rule_link_or_copy=2`
- Final exact-scope splitter recheck:
  `proposal_count=0` and `safe_for_batch_pg_package_count=0`.
- Alignment audits passed:
  - PG/Hermes/SQLite contract: `51/51`
  - XMage strategy: `26/26`
  - Deckbuilding contract: `pass`
  - Operational surface: `39/39`
  - Legacy contamination: `pass`
