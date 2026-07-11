# PG775 Dynamic Target Player Discard Evidence - 2026-07-11

Status: `applied_and_validated`

Database target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`

## Scope

Implemented exact XMage -> ManaLoom support for
`xmage_dynamic_target_player_discard_spell_v1`.

Promoted cards:

- `Mind Shatter`
- `Mind Twist`
- `Voices from the Void`

Supported dynamic discard sources in this batch:

- `x_value`
- `domain_basic_land_types`

Left blocked intentionally:

- `Arcane Omens`: `target_player_discard_spell_dynamic_oracle_mana_spent_colors_not_supported`
- `Cabal Conditioning`: `target_player_discard_spell_dynamic_oracle_greatest_mana_value_not_supported`

## Code Changes

- `xmage_authoritative_exact_scope_split.py`
  - Added `DYNAMIC_TARGET_PLAYER_DISCARD_SCOPE`.
  - Added Oracle/source parsing for `DiscardTargetEffect(GetXValue.instance, true)`.
  - Added Oracle/source parsing for `DiscardTargetEffect(DomainValue.REGULAR)`.
  - Kept fixed target-player discard behavior in the existing fixed scope.
- `battle_analyst_v9.py`
  - Added runtime support for `discard_count_source=x_value`.
  - Added runtime support for `discard_count_source=domain_basic_land_types`.
- `xmage_batch_pg_package_builder.py`
  - Preserved `discard_count_source` in package manifests.
  - Added E2E scenarios for dynamic target-player discard.
- `battle_package_end_to_end_validation.py`
  - Added `target_player_discard_spell` runner.
  - Validates target player, requested/discarded count, discard randomness,
    source field, hand size, and graveyard movement.
- `test_xmage_authoritative_exact_scope_split.py`
  - Added focused tests for X-random discard, Domain discard, and unsupported
    mana-spent-colors discard.

## Validation

Focused splitter tests:

```bash
python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k target_player_discard
python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k damage_gain_life
```

Results:

- `target_player_discard`: 11 tests passed.
- `damage_gain_life`: 9 tests passed.

Syntax validation:

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py
```

Result: pass.

Exact split:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg775_dynamic_target_player_discard_new_server.json`
- `safe_for_batch_pg_package_count=3`
- `family_counts={"xmage_dynamic_target_player_discard_spell":3,"xmage_simple_mana_source_with_unmodeled_auxiliary":3}`

Post-PG775 exact split:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_post_pg775_dynamic_target_player_discard_new_server.json`
- `safe_for_batch_pg_package_count=0`

PostgreSQL package:

- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg775_dynamic_target_player_discard_new_server_manifest.json`
- Precheck: 3 target rows, 0 expected active rows before apply, 0 shadow rows to deprecate.
- Apply: `upserted_rows=3`, `deprecated_shadow_rows=0`.
- Postcheck: every promoted card has `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

Hermes/SQLite sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg775_dynamic_target_player_discard_new_server_sqlite_sync.json`
- `pg_rows_loaded=10115`
- `sqlite_inserted_or_updated=9893`
- `canonical_snapshot_rows_exported=7505`

E2E package validation:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg775_dynamic_target_player_discard_new_server_e2e.json`
- Status: `pass`
- Stages: PostgreSQL, SQLite cache, canonical snapshot, runtime get-card-effect,
  and battle execution all passed.
- Battle execution: 3 scenarios, 6 events.

Readiness after PG775:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg775_dynamic_target_player_discard_new_server.json`
- `battle_and_oracle_ready=6520`
- `snapshot_has_verified_rule=6545`
- `snapshot_has_any_rule=7711`
- `battle_family_mapper_required=27356`

XMage authoritative queue after PG775:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg775_dynamic_target_player_discard_new_server.json`
- `xmage_authoritative_adapter_required_count=24120`
- `xmage_authoritative_parser_gap_count=0`
- `manual_semantic_decision_units_remaining=313`

Final audits:

- `xmage_strategy_consistency_audit_20260711_post_pg775_dynamic_target_player_discard_new_server_final`: pass, 26/26.
- `pg_hermes_sqlite_contract_audit_20260711_post_pg775_dynamic_target_player_discard_new_server_final`: pass, 51/51.
- `operational_surface_alignment_audit_20260711_post_pg775_dynamic_target_player_discard_new_server_final`: pass.
- `legacy_contamination_audit_20260711_post_pg775_dynamic_target_player_discard_new_server_final`: pass.

## Residual

The global goal remains active. After PG775 there are still:

- `24120` XMage-authoritative identities requiring adapters.
- `313` missing-source/manual semantic exceptions.
- `0` parser gaps.
