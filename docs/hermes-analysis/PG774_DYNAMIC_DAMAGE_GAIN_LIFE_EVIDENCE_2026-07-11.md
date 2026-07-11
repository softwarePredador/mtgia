# PG774 Dynamic Damage Gain Life Evidence - 2026-07-11

Status: `applied_and_validated`

Database target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`

## Scope

Implemented the XMage -> ManaLoom exact scope
`xmage_dynamic_damage_target_and_controller_gain_life_spell_v1` for spells that
deal dynamic damage to a target and make the controller gain the same dynamic
amount of life.

Promoted cards:

- `Consuming Corruption`
- `Death Grasp`
- `Harsh Sustenance`
- `Swallowing Plague`
- `Tendrils of Corruption`

Supported dynamic amount sources in this batch:

- `x_value`
- `battlefield_permanent_count` for creatures controlled by the controller
- `battlefield_permanent_count` for Swamps controlled by the controller

## Code Changes

- `xmage_authoritative_exact_scope_split.py`
  - Added `DYNAMIC_DAMAGE_GAIN_LIFE_SCOPE`.
  - Added source/oracle parser support for dynamic `DamageTargetEffect` +
    `GainLifeEffect` pairs where both effects share the same dynamic value.
  - Kept fixed damage/life gain in the existing fixed scope.
  - Improved XMage subtype count precision so all basic land subtypes, not only
    Mountain, retain `battlefield_count_card_types=["land"]`.
- `battle_analyst_v9.py`
  - Added runtime handling for `controller_gain_life_source=damage_amount`.
  - The life gain uses the source dynamic amount, preserving fixed independent
    gain behavior and avoiding lifelink semantics.
- `xmage_batch_pg_package_builder.py`
  - Preserved `controller_gain_life_source`, `gain_life_source`, and
    `damage_per_count` into package manifests.
  - Added E2E fixtures for X-value and controller battlefield count scenarios.
- `test_xmage_authoritative_exact_scope_split.py`
  - Added focused tests for `Death Grasp`, `Harsh Sustenance`, `Consuming
    Corruption`, and `Tendrils of Corruption`.

## Validation

Focused splitter test:

```bash
python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k damage_gain_life
```

Result: `Ran 9 tests ... OK`

Exact split:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg774_dynamic_damage_gain_life_new_server.json`
- `safe_for_batch_pg_package_count=5`
- `family_counts={"xmage_dynamic_damage_gain_life_spell":5,"xmage_simple_mana_source_with_unmodeled_auxiliary":3}`

Post-PG774 exact split:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_post_pg774_dynamic_damage_gain_life_new_server.json`
- `safe_for_batch_pg_package_count=0`

PostgreSQL package:

- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg774_dynamic_damage_gain_life_new_server_manifest.json`
- Precheck: 5 target rows, 0 expected active rows before apply, 0 shadow rows to deprecate.
- Apply: `upserted_rows=5`, `deprecated_shadow_rows=0`.
- Postcheck: every promoted card has `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

Hermes/SQLite sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg774_dynamic_damage_gain_life_new_server_sqlite_sync.json`
- `pg_rows_loaded=10112`
- `sqlite_inserted_or_updated=9890`
- `canonical_snapshot_rows_exported=7502`

E2E package validation:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg774_dynamic_damage_gain_life_new_server_e2e.json`
- Status: `pass`
- Stages: PostgreSQL, SQLite cache, canonical snapshot, runtime get-card-effect,
  and battle execution all passed.
- Battle execution: 5 scenarios, 15 events.

Readiness after PG774:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg774_dynamic_damage_gain_life_new_server.json`
- `battle_and_oracle_ready=6517`
- `snapshot_has_verified_rule=6542`
- `snapshot_has_any_rule=7708`
- `battle_family_mapper_required=27359`

XMage authoritative queue after PG774:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg774_dynamic_damage_gain_life_new_server.json`
- `xmage_authoritative_adapter_required_count=24123`
- `xmage_authoritative_parser_gap_count=0`
- `manual_semantic_decision_units_remaining=313`

Final audits:

- `xmage_strategy_consistency_audit_20260711_post_pg774_dynamic_damage_gain_life_new_server_final`: pass, 26/26.
- `pg_hermes_sqlite_contract_audit_20260711_post_pg774_dynamic_damage_gain_life_new_server_final`: pass, 51/51.
- `operational_surface_alignment_audit_20260711_post_pg774_dynamic_damage_gain_life_new_server_final`: pass.
- `legacy_contamination_audit_20260711_post_pg774_dynamic_damage_gain_life_new_server_final`: pass.

## Residual

The global goal remains active. After PG774 there are still:

- `24123` XMage-authoritative identities requiring adapters.
- `313` missing-source/manual semantic exceptions.
- `0` parser gaps.
