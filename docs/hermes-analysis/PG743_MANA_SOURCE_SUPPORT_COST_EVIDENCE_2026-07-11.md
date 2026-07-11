# PG743 Mana Source Support Cost Evidence - 2026-07-11

Status: `applied_to_new_server_and_validated`

Database target: `127.0.0.1:15432/halder` via
`server/bin/with_new_server_pg.sh`.

## Scope

PG743 promotes the exact XMage subpattern for activated creature mana sources
whose activation cost includes tapping another untapped support permanent.

Promoted cards:

- `Citanul Stalwart`: `{T}, Tap an untapped artifact or creature you control: Add one mana of any color.`
- `Jaspera Sentinel`: reach plus `{T}, Tap an untapped creature you control: Add one mana of any color.`
- `Loam Dryad`: `{T}, Tap an untapped creature you control: Add one mana of any color.`
- `Saruli Caretaker`: defender plus `{T}, Tap an untapped creature you control: Add one mana of any color.`

## Runtime Changes

- `battle_analyst_v9.py` now pays `mana_activation_tap_support_count/type`
  costs by tapping a valid untapped support permanent.
- `mana_source_support_can_include_source=false` prevents `{T}` sources from
  counting themselves as support.
- Existing no-`{T}` artifact-or-creature support sources remain compatible:
  if no explicit flag exists and the source does not require source tap, the
  source may count as support.
- Mana refresh now skips sources that became tapped after the source list was
  built.
- The self-add-counter activation fallback was repaired for legacy flat
  permanent fields while validating the runtime suite.

## PostgreSQL Package

Generated package:

- `docs/hermes-analysis/master_optimizer_reports/pg743_mana_source_support_cost_package_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg743_mana_source_support_cost_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg743_mana_source_support_cost_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg743_mana_source_support_cost_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg743_mana_source_support_cost_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg743_mana_source_support_cost_package_manifest.json`

Precheck:

- 4 target card rows found.
- 0 existing matching rule rows.
- 0 shadow rows to deprecate.

Apply:

- `upserted_rows=4`
- `deprecated_shadow_rows=0`

Postcheck:

- 4 promoted rule rows.
- 4 `verified`/`auto` rows.
- 4 rows with `oracle_hash`.

## Sync

- Battle rules sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg743_mana_source_support_cost_sync_battle_rules_report.json`
  - `database_target=127.0.0.1:15432/halder`
  - `pg_rows_loaded=6360`
  - `sqlite_inserted_or_updated=6355`
  - `canonical_snapshot_rows_exported=6309`
- Card metadata sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg743_mana_source_support_cost_sync_pg_card_metadata_report.json`
  - `requested unique names=7265`
  - `postgres cards matched=7448`
  - `sqlite cache alias rows=7370`

## E2E Validation

Report:
`docs/hermes-analysis/master_optimizer_reports/pg743_mana_source_support_cost_e2e_after_full_sync_report.md`

Status: `pass`

Stages:

- `postgres_source_of_truth`: 4 validated rows.
- `sqlite_hermes_cache`: 4 validated rows.
- `canonical_snapshot_fallback`: 4 validated cards.
- `runtime_get_card_effect`: 4 validated cards.
- `battle_execution`: 4 scenarios, 8 events.

Each promoted card produced `available_mana=1`, `conditional_mana=1`,
`tapped=true`, and `support_tapped_count=1`.

## Tests

- `python3 -m py_compile` for updated runtime/splitter/builder/E2E scripts: pass.
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py`: 1469 tests OK.
- `python3 -m pytest -q test_xmage_batch_pg_package_builder.py test_battle_package_end_to_end_validation.py`: 288 passed.

## Audits

- XMage strategy consistency:
  `docs/hermes-analysis/master_optimizer_reports/pg743_mana_source_support_cost_xmage_strategy_consistency_audit.md`
  - `26/26` pass.
- Operational surface alignment:
  `docs/hermes-analysis/master_optimizer_reports/pg743_mana_source_support_cost_operational_surface_alignment_audit.md`
  - pass.
- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg743_mana_source_support_cost_pg_hermes_sqlite_contract_audit.md`
  - `51/51` pass.
- Legacy contamination:
  `docs/hermes-analysis/master_optimizer_reports/pg743_mana_source_support_cost_legacy_contamination_audit.md`
  - pass.

## Readiness Delta

Post-PG742 baseline:

- `battle_and_oracle_ready=6405`
- `snapshot_has_verified_rule=6430`
- Commander-legal battle+Oracle ready direct PG count: `6337`
- Commander queue pending: `24548`
- XMage authoritative adapter required: `24235`

Post-PG743:

- `battle_and_oracle_ready=6409`
- `snapshot_has_verified_rule=6434`
- Commander-legal battle+Oracle ready direct PG count: `6341`
- Commander queue pending: `24544`
- XMage authoritative adapter required: `24231`
- Parser gaps: `0`
- Missing local XMage source exceptions: `313`

The global goal remains active: the queue still has `24231`
`xmage_authoritative_adapter_required` identities and `313` missing-source
exceptions.
