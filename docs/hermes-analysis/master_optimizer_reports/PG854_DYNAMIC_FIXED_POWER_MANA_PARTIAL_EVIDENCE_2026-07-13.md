# PG854 Dynamic Fixed Power Mana Partial Evidence - 2026-07-13

Status: applied to the new PostgreSQL server and validated.

Database target: `127.0.0.1:15432/halder` via
`server/bin/with_new_server_pg.sh`.

## Scope

PG854 promotes the fixed-color dynamic mana source-power subpattern from XMage
to ManaLoom as a partial, batch-safe mana-only runtime model.

Promoted cards:

- Cradle Clearcutter
- Marwyn, the Nurturer
- Rainveil Rejuvenator
- Topiary Lecturer

Runtime scope:

- `battle_model_scope`: `xmage_fixed_color_dynamic_mana_source_permanent_v1`
- `dynamic_mana_amount_source`: `source_power`
- `modeled_ability_subset`: `mana_source_only`
- Auxiliary non-mana abilities remain explicitly unmodeled in the rule
  metadata.

## Implementation

Changed:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`

Adapter improvement:

- isolates the exact `new DynamicManaAbility(...)` source window before
  deciding fixed-color dynamic mana support;
- allows auxiliary XMage abilities/effects to remain explicitly unmodeled when
  the executable subset is only the mana ability;
- marks the partial rule as batch-safe only when the modeled subset is
  `mana_source_only`, the rule is a mana source, and the runtime scope is one
  of the supported mana scopes.

Focused test added:

- `test_fixed_color_dynamic_mana_source_with_auxiliary_maps_partial_safe_mana`

## Package Evidence

Generated candidate report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260713_pg854_dynamic_fixed_power_mana_partial_new_server_candidate.json`
- `proposal_count`: `4`
- `safe_for_batch_pg_package_count`: `4`
- `family_counts`: `xmage_fixed_color_dynamic_mana_source=4`
- `proposal_status_counts`:
  `runtime_partial_batch_pg_candidate_after_precheck=4`

Generated package:

- `docs/hermes-analysis/master_optimizer_reports/pg854_dynamic_fixed_power_mana_partial_new_server_package_manifest.json`
- `selected_count`: `4`

Committed SQL package files:

- `docs/hermes-analysis/master_optimizer_reports/pg854_dynamic_fixed_power_mana_partial_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg854_dynamic_fixed_power_mana_partial_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg854_dynamic_fixed_power_mana_partial_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg854_dynamic_fixed_power_mana_partial_new_server_package_rollback.sql`

## PostgreSQL Apply Evidence

Precheck:

- all four target card rows resolved;
- expected promoted rule rows before apply: `0`;
- existing shadow rows detected for Marwyn: `2`.

Apply:

- backup table:
  `manaloom_deploy_audit.pg854_dynamic_fixed_power_mana_partial_n_20260713_005518`
- `deprecated_shadow_rows`: `2`
- `upserted_rows`: `4`

Postcheck:

- `promoted_rule_rows`: `1` per promoted card;
- `promoted_verified_auto_rows`: `1` per promoted card;
- `promoted_oracle_hash_rows`: `1` per promoted card;
- `backup_rows`: `2`.

## Sync Evidence

PostgreSQL to Hermes/SQLite sync:

- report:
  `docs/hermes-analysis/master_optimizer_reports/pg854_dynamic_fixed_power_mana_partial_new_server_pg_to_sqlite_sync.json`
- `pg_rows_loaded`: `4`
- `selected_card_count`: `4`
- `sqlite_inserted_or_updated`: `6`
- `canonical_snapshot_rows_exported`: `7844`

Metadata sync:

- report:
  `docs/hermes-analysis/master_optimizer_reports/pg854_dynamic_fixed_power_mana_partial_new_server_metadata_sync.json`
- `requested_unique_names`: `8590`
- `postgres_cards_matched`: `8781`
- `sqlite_cache_alias_rows`: `8720`
- `dry_run`: `false`

## E2E Evidence

Validation report:

- `docs/hermes-analysis/master_optimizer_reports/pg854_dynamic_fixed_power_mana_partial_new_server_e2e_validation.json`
- status: `pass`

Stages passed:

- `postgres_source_of_truth`: `4` rows
- `sqlite_hermes_cache`: `4` rows
- `canonical_snapshot_fallback`: `4` cards
- `runtime_get_card_effect`: `4` cards
- `battle_execution`: `4` scenarios, `4` events

Battle execution exercised the fixed source-power mana behavior for each
promoted card.

## Global Queue After PG854

Readiness report:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260713_post_pg854_dynamic_fixed_power_mana_partial_new_server.json`
- `all_known_cards`: `34331`
- `snapshot_has_verified_rule`: `6901`
- `battle_and_oracle_ready`: `6794`
- `battle_family_mapper_required`: `27000`
- `battle_rule_verification_required`: `70`
- `generic_runtime_or_no_card_rule`: `359`

Authoritative XMage queue:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260713_post_pg854_dynamic_fixed_power_mana_partial_new_server_commander_legal.json`
- `target_identity_count`: `24089`
- `xmage_authoritative_source_count`: `23776`
- `xmage_missing_source_exception_count`: `313`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `23776`
- `manual_semantic_decision_units_remaining`: `313`
- `adapter_work_unit_count`: `11218`

Post-apply exact-scope split:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260713_post_pg854_dynamic_fixed_power_mana_partial_new_server_next_batch.json`
- `proposal_count`: `0`
- `safe_for_batch_pg_package_count`: `0`
- `considered_supported_work_unit_rows`: `6915`

Interpretation: PG854 exhausted the current safe exact-scope proposals for this
dynamic fixed source-power mana subpattern. The global goal remains active.

## Surface Audits

All final audits passed:

- `xmage_strategy_consistency_audit_20260713_post_pg854_dynamic_fixed_power_mana_partial_new_server_final.json`:
  `26/26` pass
- `operational_surface_alignment_audit_20260713_post_pg854_dynamic_fixed_power_mana_partial_new_server_final.json`:
  `48/48` pass
- `legacy_contamination_audit_20260713_post_pg854_dynamic_fixed_power_mana_partial_new_server_final.json`:
  `32/32` pass
- `pg_hermes_sqlite_contract_audit_20260713_post_pg854_dynamic_fixed_power_mana_partial_new_server_final.json`:
  `51/51` pass
