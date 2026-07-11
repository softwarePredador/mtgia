# PG735 Land Color Mana Evidence - 2026-07-11

## Scope

PG735 adds the exact XMage to ManaLoom adapter for tap mana sources whose
available mana depends on colors or types that lands controlled by the source
controller or an opponent could produce.

- Family: `xmage_land_color_dependent_mana_source`
- Scope: `xmage_simple_tap_land_color_dependent_mana_source_permanent_v1`
- Runtime effect: `ramp_permanent`
- XMage ability class: `AnyColorLandsProduceManaAbility`
- Supported dependency controllers:
  - `self`
  - `opponent`
- Supported colorless behavior:
  - "any color" excludes colorless.
  - "any type" includes colorless.

Unsupported compound mana-source abilities remain blocked by the splitter
instead of being promoted as executable PostgreSQL truth.

## Cards Promoted

1. Harvester Druid
2. Naga Vitalist
3. Quirion Explorer
4. Sylvok Explorer

## Implementation

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
  parses exact Oracle/XMage `AnyColorLandsProduceManaAbility` signatures and
  emits structured land-dependency fields.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  resolves conditional mana modes from controller or opponent lands at mana
  refresh time and filters colorless when the Oracle text says "any color".
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py`
  preserves land-dependency fields in the package manifest and generates E2E
  scenarios with fixture lands.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`
  seeds controller/opponent lands and validates the expected conditional colors.

## PostgreSQL Package

Package artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg735_land_color_mana_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg735_land_color_mana_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg735_land_color_mana_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg735_land_color_mana_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg735_land_color_mana_new_server_package_manifest.json`

Apply result:

- Selected cards: 4
- Deprecated shadow rows: 0
- Upserted executable rows: 4
- Promoted rows with `review_status='verified'`: 4
- Promoted rows with `execution_status='auto'`: 4
- Promoted rows with `oracle_hash`: 4

## Sync And Runtime Validation

Metadata sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg735_land_color_mana_new_server_sync_report.json`
- PostgreSQL cards matched: 7416
- SQLite cache alias rows: 7338
- `deck_cards` matched: 2699/2699
- `card_id_updates`: 93
- Unresolved: 1

Battle rule sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg735_land_color_mana_new_server_battle_rule_sync_report.json`
- Database target: `127.0.0.1:15432/halder`
- PostgreSQL rows loaded: 6327
- SQLite rows inserted or updated: 6322
- Canonical snapshot rows exported: 6278

End-to-end validation:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg735_land_color_mana_new_server_e2e.json`
- Status: `pass`
- PostgreSQL source-of-truth rows: 4
- SQLite cache rows: 4
- Canonical snapshot cards: 4
- Runtime `get_card_effect` cards: 4
- Battle execution scenarios/events: 4/4

## Tests And Gates

Focused tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k land_color`
  from `docs/hermes-analysis/manaloom-knowledge/scripts`: passed.
- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py -k land_color`: 2 tests passed.
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py -k land_color`: 1 passed.
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -k land_color`: 1 passed.

Operational gates:

- `pg_hermes_sqlite_contract_audit_20260711_post_pg735_land_color_mana_new_server`: `pass`, 51/51.
- `xmage_strategy_consistency_audit_20260711_post_pg735_land_color_mana_new_server_after_docs`: `pass`, 26/26.
- `operational_surface_alignment_audit_20260711_post_pg735_land_color_mana_new_server_after_docs`: `pass`.
- `legacy_contamination_audit_20260711_post_pg735_land_color_mana_new_server_after_docs`: `pass`.
- `./scripts/quality_gate.sh server-target`: `pass`.
- `git diff --check`: pass.

## Global Queue After PG735

Readiness report:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg735_land_color_mana_new_server.json`
- `snapshot_has_verified_rule`: 6401
- `battle_and_oracle_ready`: 6376
- `battle_family_mapper_required`: 27500
- `generic_runtime_or_no_card_rule`: 359
- `commander_illegal_block`: 2997
- `digital_non_commander_rule_exception`: 3
- `official_oracle_identity_unavailable`: 3

XMage authoritative queue:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg735_land_color_mana_new_server_commander_legal.json`
- `target_identity_count`: 24577
- `xmage_authoritative_source_count`: 24264
- `xmage_authoritative_adapter_required_count`: 24264
- `xmage_authoritative_parser_gap_count`: 0
- `xmage_missing_source_exception_count`: 313
- `adapter_work_unit_count`: 11295
- `ramp_permanent::xmage_creature_mana_source_variant_review_v1`: 256

Net PG735 movement:

- `battle_and_oracle_ready`: 6372 -> 6376
- Commander-legal XMage adapter queue: 24268 -> 24264
- `ramp_permanent::xmage_creature_mana_source_variant_review_v1`: 260 -> 256
