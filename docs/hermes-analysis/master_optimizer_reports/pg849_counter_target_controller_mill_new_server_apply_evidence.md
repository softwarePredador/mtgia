# PG849 Counter Target Controller Mill Evidence

- Generated at: `2026-07-12T22:57:36Z`
- Database target: `127.0.0.1:15432/halder`
- Package: `pg849_counter_target_controller_mill_new_server_package`
- Scope: `xmage_counter_target_and_target_controller_mill_spell_v1`
- Cards: `Countermand`, `Didn't Say Please`, `Psychic Strike`, `Thought Collapse`

## PostgreSQL

- Precheck: 4 target rows, 0 existing matching rule rows, 0 shadow rows to deprecate.
- Apply: `upserted_rows=4`, `deprecated_shadow_rows=0`, transaction committed.
- Postcheck: each target has `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

## Sync

- Metadata sync report: `pg849_counter_target_controller_mill_new_server_metadata_sync.json`
  - requested unique names: `8548`
  - PostgreSQL cards matched: `8739`
  - SQLite cache alias rows: `8678`
  - deck_cards matched: `2699/2699`
- PG -> SQLite battle-rule sync report: `pg849_counter_target_controller_mill_new_server_pg_sqlite_sync.json`
  - PG rows loaded: `10538`
  - SQLite inserted/updated: `10316`
  - canonical snapshot rows exported: `7802`

## Validation

- Package E2E: `pg849_counter_target_controller_mill_new_server_e2e.md`
  - status: `pass`
  - PostgreSQL source of truth: `pass`
  - SQLite/Hermes cache: `pass`
  - canonical snapshot fallback: `pass`
  - runtime lookup: `pass`
  - battle execution: `pass`
- Battle execution proved target-controller mill counts:
  - `Countermand`: `4`
  - `Didn't Say Please`: `3`
  - `Psychic Strike`: `2`
  - `Thought Collapse`: `3`
- Focused tests:
  - `test_xmage_authoritative_exact_scope_split.py -k counter_target_controller_mill`: passed
  - `test_xmage_batch_pg_package_builder.py -k counter_target_controller_mill`: passed
  - `test_battle_package_end_to_end_validation.py -k counter_target_response_runner_mills_target_controller`: passed
  - `py_compile` for modified runtime/package/splitter scripts: passed

## Post-PG849 Global Counts

- `battle_and_oracle_ready`: `6751` (`+4` from PG848)
- `snapshot_has_verified_rule`: `6858`
- `battle_family_mapper_required`: `27043`
- `xmage_authoritative_adapter_required_count`: `23819`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_missing_source_exception_count`: `313`
- Post-PG849 exact split recheck: `proposal_count=0`, `safe_for_batch_pg_package_count=0`

## Governance Audits

- `xmage_strategy_consistency_audit_20260712_post_pg849_counter_target_controller_mill_new_server`: `pass` (`26/26`)
- `pg_hermes_sqlite_contract_audit_20260712_post_pg849_counter_target_controller_mill_new_server`: `pass` (`51/51`)
- `operational_surface_alignment_audit_20260712_post_pg849_counter_target_controller_mill_new_server`: `pass`
