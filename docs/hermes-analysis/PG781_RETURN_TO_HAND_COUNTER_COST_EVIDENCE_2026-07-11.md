# PG781 Return-To-Hand Counter Cost Evidence - 2026-07-11

Status: `applied_and_validated`

## Scope

PG781 promotes the XMage-authoritative counterspell additional-cost subpattern
where casting the spell requires returning a controlled permanent or creature
to its owner's hand.

Promoted cards:

- `Disappearing Act`: `return_permanent_to_hand`
- `Familiar's Ruse`: `return_creature_to_hand`

The remaining `counter_additional_cost_not_supported` samples after this batch
are still intentionally blocked because they use choice/alternate additional
cost forms that need a separate runtime model: `Disruption Protocol` and
`Wild Unraveling`.

## Runtime And Parser Changes

- `xmage_authoritative_exact_scope_split.py` maps
  `ReturnToHandChosenControlledPermanentCost` for land, permanent, and
  creature targets only when the Oracle text exactly matches the additional
  cost.
- `battle_analyst_v9.py` validates and pays
  `requires_return_permanent_to_hand` and
  `requires_return_creature_to_hand`, moving the selected battlefield permanent
  to hand and emitting `additional_cost_paid`.
- `xmage_batch_pg_package_builder.py` includes the new fields in required E2E
  rule checks and creates responder battlefield fixtures.
- `battle_package_end_to_end_validation.py` accepts generic
  `expected_returned_name`, while preserving the older
  `expected_returned_land_name` compatibility field.

## PostgreSQL Apply Evidence

Target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`.

Artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg781_return_to_hand_counter_cost_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg781_return_to_hand_counter_cost_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg781_return_to_hand_counter_cost_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg781_return_to_hand_counter_cost_new_server_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg781_return_to_hand_counter_cost_new_server_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg781_return_to_hand_counter_cost_new_server_package.md`

Precheck:

- `target_card_rows=1` for each card.
- `existing_rule_rows=0` for each card.
- `would_deprecate_shadow_rows=0`.

Apply:

- `upserted_rows=2`.
- `deprecated_shadow_rows=0`.

Postcheck:

- `promoted_rule_rows=1` for each card.
- `promoted_verified_auto_rows=1` for each card.
- `promoted_oracle_hash_rows=1` for each card.

Direct PG verification:

- `Disappearing Act`: `verified/auto`,
  `battle_rule_v1:b1330263e10324f1741407f76506444c`,
  `return_permanent_to_hand`, target `permanent`,
  oracle hash `11613ba95535b2eb5554fe9d3b903cab`.
- `Familiar's Ruse`: `verified/auto`,
  `battle_rule_v1:1e3bb8d40fbb80cc70f0744009a34411`,
  `return_creature_to_hand`, target `creature`,
  oracle hash `4b49642c177d3aa48cdd87e97d74ef60`.

## Sync And E2E Evidence

Sync reports:

- `pg781_sync_pg_card_metadata_to_hermes_report.json`
  - `matched=2699/2699`
  - `card_id_updates=96`
  - `unresolved=1`
- `pg781_sync_battle_card_rules_pg_report.json`
  - `pg_rows_loaded=6484`
  - `sqlite_inserted_or_updated=6479`
  - `canonical_snapshot_rows_exported=6435`

E2E package validation:

- Artifact:
  `docs/hermes-analysis/master_optimizer_reports/pg781_return_to_hand_counter_cost_new_server_e2e_validation.json`
- Status: `pass`
- Stages passed:
  `postgres_source_of_truth`, `sqlite_hermes_cache`,
  `canonical_snapshot_fallback`, `runtime_get_card_effect`,
  `battle_execution`
- Battle scenarios: `2`
- Results:
  - `Disappearing Act` paid `return_permanent_to_hand` and countered the legal
    stack spell.
  - `Familiar's Ruse` paid `return_creature_to_hand` and countered the legal
    stack spell.

## Global Backlog Movement

Readiness after PG781:

- Artifact:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg781_return_to_hand_counter_cost_new_server.json`
- `battle_and_oracle_ready`: `6533` after PG781, up from `6531`.
- `battle_family_mapper_required`: `27343` after PG781, down from `27345`.

XMage adaptation queue after PG781:

- Artifact:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg781_return_to_hand_counter_cost_new_server.json`
- `target_identity_count`: `24420`, down from `24422`.
- `xmage_authoritative_adapter_required_count`: `24107`, down from `24109`.
- `xmage_authoritative_parser_gap_count`: `0`.
- `xmage_missing_source_exception_count`: `313`.

## Validation Commands

- `python3 -m py_compile xmage_authoritative_exact_scope_split.py battle_analyst_v9.py xmage_batch_pg_package_builder.py battle_package_end_to_end_validation.py`
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_batch_pg_package_builder.py test_battle_runtime_surface_manifest.py test_runtime_pg_rule_fallback_for_promoted_hotfixes.py test_battle_package_end_to_end_validation.py`
  - `1064 tests OK, 3 skipped`
- `xmage_strategy_consistency_audit_20260711_post_pg781_return_to_hand_counter_cost_new_server`
  - `pass`, `26/26`
- `pg_hermes_sqlite_contract_audit_20260711_post_pg781_return_to_hand_counter_cost_new_server`
  - `pass`, `51/51`
- `operational_surface_alignment_audit_20260711_post_pg781_return_to_hand_counter_cost_new_server`
  - `pass`
- `legacy_contamination_audit_20260711_post_pg781_return_to_hand_counter_cost_new_server`
  - `pass`
- `./scripts/quality_gate.sh server-target`
  - `pass`
