# PG690 Equipment Attachment Marker Evidence - 2026-07-09

Status: `closed`.

Database target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`.

## Scope

PG690 promoted the equipment static P/T rows where the local XMage class is an
Equipment card, but the keyword grant is encoded with
`GainAbilityAttachedEffect(..., AttachmentType.AURA)`.

This marker is safe only inside the equipment static parser, after the source
class and Oracle text prove the object is equipment and the target text is
`Equipped creature gets ...`.

Family: `xmage_equipment_static_power_toughness_attachment`.

Cards:

- `Boots of Speed`: target ends `3/2`, grants `haste`.
- `Ranger's Longbow`: target ends `4/3`, grants `reach`.

## Implementation

- `xmage_authoritative_exact_scope_split.py` now accepts
  `AttachmentType.EQUIPMENT` or `AttachmentType.AURA` for keyword grants inside
  equipment static attachment source parsing.
- `test_xmage_authoritative_exact_scope_split.py` covers the Boots of Speed
  source shape and asserts exact scope, P/T, and `attached_keywords`.
- Existing PG689 runtime/builder work remains the executor path:
  `equipment_static_power_toughness_attachment` scenarios call
  `apply_equipment_static_attachment`, validate P/T, validate granted keywords,
  and require `equipment_attached` replay evidence.

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg690_equipment_attachment_marker_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg690_equipment_attachment_marker_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg690_equipment_attachment_marker_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg690_equipment_attachment_marker_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg690_equipment_attachment_marker_new_server_package_manifest.json`

Package result:

- selected rows: `2`
- apply result: `2` promoted rows
- postcheck: `2/2` rows have promoted rule, `verified` review status,
  `auto` execution status, and `oracle_hash`
- backup rows: `0`

## Hash Integrity Backfill

The first post-PG690 contract audit found trusted executable rules missing
`oracle_hash`, which is not a behavior failure but does break the current
PostgreSQL/Hermes/SQLite contract.

PG690b is a metadata-only backfill:

- precheck: `44` safe rows, `0` unsafe rows
- apply: `44` rows backfilled
- postcheck: `0` trusted executable rows still missing hash
- method: `oracle_hash = md5(coalesce(cards.oracle_text, ''))`
- package files:
  - `docs/hermes-analysis/master_optimizer_reports/pg690b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
  - `docs/hermes-analysis/master_optimizer_reports/pg690b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
  - `docs/hermes-analysis/master_optimizer_reports/pg690b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
  - `docs/hermes-analysis/master_optimizer_reports/pg690b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

## Sync And E2E

Final PG690 PG -> SQLite/snapshot sync:

- report: `docs/hermes-analysis/master_optimizer_reports/pg690_equipment_attachment_marker_new_server_pg_to_sqlite_sync_runtime_only.json`
- PostgreSQL rows loaded: `6114`
- SQLite rows inserted/updated: `6099`
- canonical snapshot rows exported: `6076`

Final PG690b PG -> SQLite/snapshot sync:

- report: `docs/hermes-analysis/master_optimizer_reports/pg690b_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync_runtime_only.json`
- PostgreSQL rows loaded: `6114`
- SQLite rows inserted/updated: `6099`
- canonical snapshot rows exported: `6076`

Final package E2E after PG690b:

- report: `docs/hermes-analysis/master_optimizer_reports/pg690_equipment_attachment_marker_new_server_e2e_validation_post_pg690b_hash_backfill.md`
- status: `pass`
- PostgreSQL source rows validated: `2`
- SQLite/Hermes rows validated: `2`
- canonical snapshot cards validated: `2`
- runtime lookup cards validated: `2`
- battle execution scenarios: `2`
- battle replay events: `2`

## Tests And Audits

Focused tests:

- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`
- result: `1075 passed, 206 subtests passed`

Final audits after PG690b:

- `./scripts/quality_gate.sh server-target`: pass
- `xmage_strategy_consistency_audit_20260709_post_pg690b_hash_backfill_new_server_final`: pass `26/26`
- `operational_surface_alignment_audit_20260709_post_pg690b_hash_backfill_new_server_final`: pass `48/48`
- `legacy_contamination_audit_20260709_post_pg690b_hash_backfill_new_server_final`: pass `32/32`
- `pg_hermes_sqlite_contract_audit_20260709_post_pg690b_hash_backfill_new_server_final`: pass `51/51`

## Queue Impact

Readiness after PG690b:

- `battle_and_oracle_ready`: `6174`
- `battle_family_mapper_required`: `27702`
- `snapshot_has_verified_rule`: `6202`
- `snapshot_has_any_rule`: `7392`

Authoritative queue after PG690:

- `target_identity_count`: `24779`
- `xmage_authoritative_source_count`: `24466`
- `xmage_missing_source_exception_count`: `313`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `24466`
- `adapter_work_unit_count`: `11306`

Exact split recheck:

- report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260709_post_pg690_equipment_attachment_marker_new_server_recheck.md`
- `proposal_count`: `0`
- `safe_for_batch_pg_package_count`: `0`

The remaining equipment rows are not safe under this marker fix; they remain
blocked as separate modeling work.
