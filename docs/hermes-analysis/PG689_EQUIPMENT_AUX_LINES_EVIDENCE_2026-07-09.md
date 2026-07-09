# PG689 Equipment Auxiliary Lines Evidence - 2026-07-09

Status: `closed`.

Database target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`.

## Scope

PG689 promoted the remaining safe equipment static P/T rows whose Oracle text
contains neutral auxiliary equipment lines such as equip cost, equipment
self-keywords, or ETB auto-attach text.

Family: `xmage_equipment_static_power_toughness_attachment`.

Cards:

- `Bramble Armor`: target ends `4/3`, no granted keywords.
- `Darksteel Axe`: target ends `4/2`, no granted keywords.
- `Maul of the Skyclaves`: target ends `4/4`, grants `first_strike` and `flying`.
- `Meltstrider's Gear`: target ends `4/3`, grants `reach`.
- `Piston Sledge`: target ends `5/3`, no granted keywords.
- `Scavenged Blade`: target ends `4/2`, no granted keywords.
- `Shredder's Armor`: target ends `4/3`, no granted keywords.
- `Utility Knife`: target ends `3/3`, no granted keywords.

## Implementation

- `xmage_authoritative_exact_scope_split.py` now ignores safe equipment
  auxiliary Oracle lines before matching `Equipped creature gets ...`.
- `xmage_batch_pg_package_builder.py` now preserves `attached_keywords` and
  grant flags in package manifests and emits
  `equipment_static_power_toughness_attachment` execution scenarios.
- `battle_package_end_to_end_validation.py` now executes equipment attachment
  through `apply_equipment_static_attachment`, validates P/T, validates granted
  keywords, and requires the `equipment_attached` replay event.

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg689_equipment_aux_lines_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg689_equipment_aux_lines_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg689_equipment_aux_lines_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg689_equipment_aux_lines_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg689_equipment_aux_lines_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg689_equipment_aux_lines_new_server_package_package.md`

Package result:

- selected rows: `8`
- apply result: `8` promoted rows
- postcheck: `8/8` rows have promoted rule, `verified` review status,
  `auto` execution status, and `oracle_hash`
- backup rows: `0`

## Sync And E2E

Final PG -> SQLite/snapshot sync:

- report: `docs/hermes-analysis/master_optimizer_reports/pg689_equipment_aux_lines_new_server_pg_to_sqlite_sync_runtime_only_final.json`
- PostgreSQL rows loaded: `6112`
- SQLite rows inserted/updated: `6097`
- canonical snapshot rows exported: `6074`

Final package E2E:

- report: `docs/hermes-analysis/master_optimizer_reports/pg689_equipment_aux_lines_new_server_e2e_validation_final.md`
- status: `pass`
- PostgreSQL source rows validated: `8`
- SQLite/Hermes rows validated: `8`
- canonical snapshot cards validated: `8`
- runtime lookup cards validated: `8`
- battle execution scenarios: `8`
- battle replay events: `8`

## Tests And Audits

Focused tests:

- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`
- result: `1074 passed, 206 subtests passed`

Final audits:

- `./scripts/quality_gate.sh server-target`: pass
- `xmage_strategy_consistency_audit_20260709_post_pg689_equipment_aux_lines_new_server_final`: pass `26/26`
- `operational_surface_alignment_audit_20260709_post_pg689_equipment_aux_lines_new_server_final`: pass
- `legacy_contamination_audit_20260709_post_pg689_equipment_aux_lines_new_server_final`: pass
- `pg_hermes_sqlite_contract_audit_20260709_post_pg689_equipment_aux_lines_new_server_final`: pass `51/51`

## Queue Impact

Readiness after PG689:

- `battle_and_oracle_ready`: `6172`
- `battle_family_mapper_required`: `27704`
- `snapshot_has_verified_rule`: `6200`
- `snapshot_has_any_rule`: `7390`

Authoritative queue after PG689:

- `target_identity_count`: `24781`
- `xmage_authoritative_source_count`: `24468`
- `xmage_missing_source_exception_count`: `313`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `24468`
- `adapter_work_unit_count`: `11308`

Exact split recheck:

- report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260709_post_pg689_equipment_aux_lines_new_server_recheck.md`
- `proposal_count`: `0`
- `safe_for_batch_pg_package_count`: `0`
- residual `equipment_static_oracle_not_exact_fixed`: `15`

The residual equipment rows are intentionally still blocked because they need
separate modeling, not the safe auxiliary-line parser path closed by PG689.
