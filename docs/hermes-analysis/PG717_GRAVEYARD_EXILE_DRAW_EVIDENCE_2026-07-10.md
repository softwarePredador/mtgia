# PG717 Graveyard Exile Draw Evidence - 2026-07-10

Status: `applied_synced_validated`

Database target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`

## Scope

- Card: `Cremate`
- XMage source: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/c/Cremate.java`
- XMage behavior: `ExileTargetEffect` targeting `TargetCardInGraveyard`, then `DrawCardSourceControllerEffect(1)`
- ManaLoom scope: `xmage_exile_target_and_draw_card_spell_v1`
- Runtime components:
  - `graveyard_exile` with `xmage_exile_target_graveyard_card_spell_v1`
  - `draw_cards` with `xmage_fixed_source_controller_draw_spell_v1`

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg717_graveyard_exile_draw_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg717_graveyard_exile_draw_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg717_graveyard_exile_draw_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg717_graveyard_exile_draw_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg717_graveyard_exile_draw_new_server_package_manifest.json`

Precheck:

- `target_card_rows=1`
- `existing_rule_rows=0`
- `expected_rule_rows_before=0`
- `would_deprecate_shadow_rows=0`

Apply/postcheck:

- `deprecated_shadow_rows=0`
- `upserted_rows=1`
- `promoted_rule_rows=1`
- `promoted_verified_auto_rows=1`
- `promoted_oracle_hash_rows=1`
- `backup_rows=0`

Promoted PostgreSQL row:

- `logical_rule_key=battle_rule_v1:c00a862b95d740110dab3702b7538b66`
- `review_status=verified`
- `execution_status=auto`
- `oracle_hash=bf045694be19a16c26c769b9538ae960`

## Sync And Runtime

PG -> SQLite sync:

- `pg_rows_loaded=6235`
- `sqlite_inserted_or_updated=6230`
- `canonical_snapshot_rows_exported=6186`

Metadata sync:

- `requested unique names=7145`
- `postgres cards matched=7328`
- `sqlite cache alias rows=7247`
- `deck_cards backfill matched=2699/2699`

E2E:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg717_graveyard_exile_draw_new_server_e2e_validation.md`
- Status: `pass`
- Stages passed: PostgreSQL source of truth, SQLite Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, battle execution
- Battle result: `Cremate` moved `E2E Legal Graveyard Target` from graveyard to exile and drew `1` card

## Tests And Audits

Tests:

- `python3 -m py_compile ...` passed
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py`: `942` tests OK
- `python3 -m pytest test_xmage_batch_pg_package_builder.py test_battle_package_end_to_end_validation.py -q`: `238` passed

Audits:

- `pg_hermes_sqlite_contract_audit`: `pass`, `51/51`
- `xmage_strategy_consistency_audit`: `pass`, `26/26`
- `operational_surface_alignment_audit`: `pass`
- `legacy_contamination_audit`: `pass`
- `./scripts/quality_gate.sh server-target`: `pass`

## Queue Delta

Before PG717, post-PG716b:

- `battle_and_oracle_ready=6283`
- `snapshot_has_verified_rule=6308`
- `xmage_authoritative_adapter_required_count=24357`

After PG717:

- `battle_and_oracle_ready=6284`
- `snapshot_has_verified_rule=6309`
- `xmage_authoritative_adapter_required_count=24356`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`

Post-PG717 exact recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `considered_supported_work_unit_rows=7104`
