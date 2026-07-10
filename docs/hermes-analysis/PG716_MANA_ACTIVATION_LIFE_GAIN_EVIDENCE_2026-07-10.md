# PG716 Mana Activation Life Gain Evidence - 2026-07-10

Status: `applied_and_verified_new_server`

## Scope

- Primary package: `pg716_mana_activation_life_gain_new_server`
- Card promoted: `Pristine Talisman`
- Exact runtime scope: `xmage_simple_tap_mana_source_with_gain_life_v1`
- XMage source: `PristineTalisman` uses `ColorlessManaAbility` plus `GainLifeEffect(1)`.
- Oracle shape: `{T}: Add {C}. You gain 1 life.`

## Runtime And Tests

- Added exact split support for mana sources that gain life on mana activation.
- Added battle runtime resolution for `mana_activation_life_gain`.
- Added package/E2E validation that requires the life-gain event and final life total.
- Focused tests:
  - `python3 -m py_compile ...` passed.
  - `python3 -m unittest test_xmage_authoritative_exact_scope_split.py`: `942` tests passed.
  - `python3 -m pytest test_xmage_batch_pg_package_builder.py test_battle_package_end_to_end_validation.py -q`: `236` tests passed.

## PostgreSQL Apply

Precheck:

- `Pristine Talisman`: `target_card_rows=1`
- `expected_rule_rows_before=0`
- `would_deprecate_shadow_rows=2`

Apply:

- `deprecated_shadow_rows=2`
- `upserted_rows=1`

Postcheck:

- `promoted_rule_rows=1`
- `promoted_verified_auto_rows=1`
- `promoted_oracle_hash_rows=1`
- `backup_rows=2`

## Sync And E2E

- PG -> SQLite sync target: `127.0.0.1:15432/halder`
- `pg_rows_loaded=6234`
- `sqlite_inserted_or_updated=6229`
- `canonical_snapshot_rows_exported=6185`
- Metadata sync: `postgres cards matched=7328`, `sqlite cache alias rows=7247`
- E2E result: `pass`
- Battle execution evidence:
  - `available_mana=1`
  - `tapped=true`
  - `mana_activation_life_gain=1`
  - `life_after_refresh=41`

## PG716b Hash Alignment

The post-PG716 readiness report exposed old trusted executable rules without
Oracle hashes. PG716b was applied as metadata-only cleanup:

- Precheck: `trusted_auto_missing_hash_rows=55`, `safe_backfillable_rows=55`, `unsafe_distinct_hash_rows=0`, `unmatched_missing_hash_rows=0`
- Apply: `oracle_hash_rows_backfilled=55`
- Postcheck: `remaining_trusted_auto_missing_hash_rows=0`

## Final Queue

- `battle_and_oracle_ready=6283`
- `snapshot_has_verified_rule=6308`
- `battle_family_mapper_required=27593`
- `xmage_authoritative_adapter_required_count=24357`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`
- Exact split recheck after PG716: `proposal_count=0`, `safe_for_batch_pg_package_count=0`

## Final Audits

- `pg_hermes_sqlite_contract_audit`: `pass`, `51/51`
- `xmage_strategy_consistency_audit`: `pass`, `26/26`
- `operational_surface_alignment_audit`: `pass`
- `legacy_contamination_audit`: `pass`
- `./scripts/quality_gate.sh server-target`: `pass`
