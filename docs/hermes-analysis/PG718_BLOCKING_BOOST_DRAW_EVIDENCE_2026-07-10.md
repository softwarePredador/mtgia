# PG718 Blocking Boost Draw Evidence - 2026-07-10

Status: `applied_synced_validated`

Database target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`

## Scope

- Cards: `Aang's Defense`, `Gallantry`
- XMage source root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- XMage behavior:
  - `Aang's Defense`: target blocking creature you control gets `+2/+2` until end of turn, then draw `1`
  - `Gallantry`: target blocking creature gets `+4/+4` until end of turn, then draw `1`
- ManaLoom scope: `xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1`
- Runtime components:
  - `stat_modifier_until_eot` with `xmage_fixed_boost_target_creature_until_eot_spell_v1`
  - `draw_cards` with `xmage_fixed_source_controller_draw_spell_v1`

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg718_blocking_boost_draw_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg718_blocking_boost_draw_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg718_blocking_boost_draw_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg718_blocking_boost_draw_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg718_blocking_boost_draw_new_server_package_manifest.json`

Precheck:

- `target_card_rows=1` for each card
- `existing_rule_rows=0`
- `expected_rule_rows_before=0`
- `would_deprecate_shadow_rows=0`

Apply/postcheck:

- `deprecated_shadow_rows=0`
- `upserted_rows=2`
- `promoted_rule_rows=1` for each card
- `promoted_verified_auto_rows=1` for each card
- `promoted_oracle_hash_rows=1` for each card
- `backup_rows=0`

Promoted PostgreSQL rows:

- `Aang's Defense`: `battle_rule_v1:e7bf87a85c25e1f0b6d32db6efff30b5`, `oracle_hash=64cefc51cdab7c6274154d69adda89e2`
- `Gallantry`: `battle_rule_v1:73cba2a058674ea5d048304fb6b16cfb`, `oracle_hash=9858f271a2639fe3e21469a90f5aa4d1`
- Both rows: `review_status=verified`, `execution_status=auto`

## Sync And Runtime

PG -> SQLite sync:

- `pg_rows_loaded=6237`
- `sqlite_inserted_or_updated=6232`
- `canonical_snapshot_rows_exported=6188`

Metadata sync:

- `requested unique names=7146`
- `postgres cards matched=7329`
- `sqlite cache alias rows=7248`
- `deck_cards backfill matched=2699/2699`

E2E:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg718_blocking_boost_draw_new_server_e2e_validation.md`
- Status: `pass`
- Stages passed: PostgreSQL source of truth, SQLite Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, battle execution
- Battle result:
  - `Aang's Defense` changed the blocking target from `2/2` to `4/4` and drew `1`
  - `Gallantry` changed the blocking target from `2/2` to `6/6` and drew `1`

## Tests And Audits

Tests:

- `python3 -m py_compile ...` passed
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py`: `943` tests OK
- `python3 -m pytest test_xmage_batch_pg_package_builder.py test_battle_package_end_to_end_validation.py -q`: `240` passed

Audits:

- `pg_hermes_sqlite_contract_audit`: `pass`, `51/51`
- `xmage_strategy_consistency_audit`: `pass`, `26/26`
- `operational_surface_alignment_audit`: `pass`
- `legacy_contamination_audit`: `pass`
- `./scripts/quality_gate.sh server-target`: `pass`

## Queue Delta

Before PG718, post-PG717:

- `battle_and_oracle_ready=6284`
- `snapshot_has_verified_rule=6309`
- `xmage_authoritative_adapter_required_count=24356`

After PG718:

- `battle_and_oracle_ready=6286`
- `snapshot_has_verified_rule=6311`
- `xmage_authoritative_adapter_required_count=24354`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`

Post-PG718 exact recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `considered_supported_work_unit_rows=7102`
