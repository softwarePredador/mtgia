# PG751 Put Target Permanent On Library Evidence - 2026-07-11

## Scope

PG751 promotes the XMage `PutOnLibraryTargetEffect` family into executable
ManaLoom battle rules for battlefield permanents moved to the top or bottom of
their owner's library.

Battle model scope:

- `xmage_put_target_permanent_on_library_spell_v1`

Promoted cards: 19

- Banishment Decree
- Disempower
- Eternal Isolation
- Excommunicate
- Fallow Earth
- Forced Landing
- Forced Retreat
- Griptide
- Mystic Repeal
- Natural Obsolescence
- Plow Under
- Rebuking Ceremony
- Repel
- Run Aground
- Temporal Eddy
- Temporal Spring
- Time Ebb
- Totally Lost
- Uproot

## Source And Package Artifacts

- Split report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg751_put_target_on_library_candidate.json`
- Package manifest: `docs/hermes-analysis/master_optimizer_reports/pg751_put_target_on_library_new_server_package_manifest.json`
- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg751_put_target_on_library_new_server_package_precheck.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg751_put_target_on_library_new_server_package_apply.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg751_put_target_on_library_new_server_package_postcheck.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/pg751_put_target_on_library_new_server_package_rollback.sql`

## PostgreSQL Apply

Target: new server PostgreSQL through `./server/bin/with_new_server_pg.sh`.

Precheck:

- 19 target cards found.
- 0 existing promoted rule rows for this scope.
- 0 shadow rows to deprecate.

Apply:

- `upserted_rows=19`
- `deprecated_shadow_rows=0`
- Transaction committed.

Postcheck:

- 19 promoted rule rows.
- 19 `review_status='verified'` and `execution_status='auto'` rows.
- 19 promoted rows with `oracle_hash`.

## Runtime And E2E Evidence

Focused tests passed:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split test_xmage_exact_scope_runtime test_battle_package_end_to_end_validation`: 1492 tests, OK.
- Direct function tests: `test_battlefield_to_library_removal_execution_scenario_is_manifested` and `test_single_target_removal_runner_moves_target_to_library_top`, pass.
- `test_put_target_creature_on_library_top_maps_battlefield_to_library_scope`
- `test_put_target_artifact_on_library_bottom_maps_battlefield_to_library_scope`
- `test_put_two_target_lands_on_library_top_maps_multi_target_scope`
- `test_put_two_target_artifacts_accepts_custom_xmage_effect_text`
- `test_battlefield_to_library_removal_execution_scenario_is_manifested`
- `test_put_target_permanent_on_library_top_moves_from_battlefield_without_shuffle`
- `test_put_target_permanent_on_library_bottom_moves_from_battlefield_without_shuffle`
- `test_single_target_removal_runner_moves_target_to_library_top`

End-to-end package validation:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg751_put_target_on_library_new_server_e2e_validation.json`
- Status: `pass`
- PostgreSQL source of truth: 19/19 validated.
- SQLite Hermes cache: 19/19 validated.
- Canonical snapshot fallback: 19/19 validated.
- Runtime `get_card_effect`: 19/19 validated.
- Battle execution: 19 scenarios, 80 events, status `pass`.

## Sync And Alignment

- PostgreSQL to SQLite sync report: `docs/hermes-analysis/master_optimizer_reports/pg751_put_target_on_library_new_server_pg_to_sqlite_sync.json`
- Metadata sync report: `docs/hermes-analysis/master_optimizer_reports/pg751_put_target_on_library_new_server_metadata_sync.json`
- XMage strategy audit: `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260711_post_pg751_put_target_on_library_new_server_final.json`, status `pass`
- Operational surface audit: `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260711_post_pg751_put_target_on_library_new_server_final.json`, status `pass`
- Legacy contamination audit: `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260711_post_pg751_put_target_on_library_new_server_final.json`, status `pass`
- PostgreSQL/Hermes/SQLite contract audit: `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260711_post_pg751_put_target_on_library_new_server_final.json`, status `pass`, 51/51 checks.
- `./scripts/quality_gate.sh server-target`: pass.

## Current Readiness Delta

Readiness report:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_current_answer_post_pg751_count.json`

Current counts after PG751:

- `all_known_cards=34331`
- `snapshot_has_verified_rule=6481`
- `battle_and_oracle_ready=6456`
- `battle_family_mapper_required=27420`
- `generic_runtime_or_no_card_rule=359`
- `commander_illegal_block=2997`

Previous PG750C counts:

- `snapshot_has_verified_rule=6462`
- `battle_and_oracle_ready=6437`
- `battle_family_mapper_required=27439`

Delta:

- `snapshot_has_verified_rule +19`
- `battle_and_oracle_ready +19`
- `battle_family_mapper_required -19`

Updated XMage authoritative queue:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg751_put_target_on_library_new_server_commander_legal.json`
- `target_identity_count=24497`
- `xmage_authoritative_source_count=24184`
- `xmage_missing_source_exception_count=313`
- `xmage_authoritative_adapter_required_count=24184`
- `adapter_work_unit_count=11285`
