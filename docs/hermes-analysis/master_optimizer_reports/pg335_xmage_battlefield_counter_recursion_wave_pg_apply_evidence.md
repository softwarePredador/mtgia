# PG335 XMage Battlefield Counter Recursion Wave - PostgreSQL Apply Evidence

Status: `applied_synced_e2e_passed`.

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg335_xmage_battlefield_counter_recursion_wave_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg335_xmage_battlefield_counter_recursion_wave_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg335_xmage_battlefield_counter_recursion_wave_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg335_xmage_battlefield_counter_recursion_wave_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg335_xmage_battlefield_counter_recursion_wave_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg335_xmage_battlefield_counter_recursion_wave_rollback.sql`

## Scope

Promoted exact `ReturnFromGraveyardToBattlefieldWithCounterTargetEffect`
recursion spells:

- `Aberrant Return`
- `Evil Reawakened`
- `Unbreakable Bond`

Runtime scope:

- `xmage_return_target_graveyard_creature_to_battlefield_with_counter_spell_v1`

## PostgreSQL Precheck

Database target: `143.198.230.247:5433/halder`.

Precheck result:

- `Aberrant Return`: target rows `1`, existing expected rows `0`, stale shadow rows `0`
- `Evil Reawakened`: target rows `1`, existing expected rows `0`, stale shadow rows `0`
- `Unbreakable Bond`: target rows `1`, existing expected rows `0`, stale shadow rows `0`

## PostgreSQL Apply And Postcheck

Apply result:

- `deprecated_shadow_rows=0`
- `upserted_rows=3`

Postcheck result:

- promoted rule rows: `3/3`
- promoted verified/auto rows: `3/3`
- promoted Oracle-hash rows: `3/3`
- backup rows: `0`

## PG To Hermes/SQLite Sync

Sync report:

- `docs/hermes-analysis/master_optimizer_reports/pg335_xmage_battlefield_counter_recursion_wave_pg_to_sqlite_sync.json`

Result:

- `pg_rows_loaded=7246`
- `sqlite_inserted_or_updated=7040`
- `canonical_snapshot_rows_exported=4835`
- `pg_inserted_or_updated=0`

## E2E Validation

E2E report:

- `docs/hermes-analysis/master_optimizer_reports/pg335_xmage_battlefield_counter_recursion_wave_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/pg335_xmage_battlefield_counter_recursion_wave_e2e_validation.json`

Result:

- status: `pass`
- PostgreSQL source of truth: `3/3`
- SQLite Hermes cache: `3/3`
- canonical snapshot fallback: `3/3`
- runtime `get_card_effect`: `3/3`
- battle execution no-override gate: `pass`

## Post-PG335 Supported Splitter Recheck

Recheck report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg335_supported_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg335_supported_recheck.json`

Result:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `considered_supported_work_unit_rows=7952`

The current exact splitter has no remaining package-ready candidates after
PG335. The next useful cycle must add another exact subpattern/runtime adapter
instead of rerunning the same splitter unchanged.

## Final Alignment Audits

Audit reports:

- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg335_battlefield_counter_recursion_wave_final_docs.md`
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg335_battlefield_counter_recursion_wave_final_docs.md`
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg335_battlefield_counter_recursion_wave_final_docs.md`
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg335_battlefield_counter_recursion_wave_final_docs.md`

Result:

- XMage strategy consistency: `pass`, `26/26`
- operational surface alignment: `pass`
- PG/Hermes/SQLite contract: `pass`, `48` pass and `1` inherited warning
- legacy contamination: `pass`

## Queue Impact

Post-PG335 readiness:

- `battle_and_oracle_ready=2379`
- `battle_family_mapper_required=30168`
- `snapshot_has_verified_rule=3527`

Post-PG335 authoritative queue:

- `target_identity_count=27245`
- `xmage_authoritative_source_count=26931`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=26931`

The global goal remains open because `26931` XMage-authoritative identities
still require exact ManaLoom adapter/runtime translation and `314` identities
remain in the missing-source exception lane.
