# PG856 Static Ward Creature Evidence - 2026-07-13

Status: `applied_and_validated`.

Scope: exact XMage `WardAbility` static creature rows where local XMage and
Oracle agree on a fixed generic mana Ward cost, optionally with safe self
combat keywords already supported by ManaLoom runtime.

## Cards Promoted

| Card | Ward | Keywords | Scope |
| --- | --- | --- | --- |
| Punk Frogs | `{3}` | none | `xmage_static_self_combat_keyword_creature_v1` |
| Rimeshield Frost Giant | `{3}` | none | `xmage_static_self_combat_keyword_creature_v1` |
| Spider-Rex, Daring Dino | `{2}` | reach, trample | `xmage_static_self_combat_keyword_creature_v1` |
| Tomakul Honor Guard | `{2}` | none | `xmage_static_self_combat_keyword_creature_v1` |
| Waterfall Aerialist | `{2}` | flying | `xmage_static_self_combat_keyword_creature_v1` |

## Code Changes

- `xmage_authoritative_exact_scope_split.py`
  - Added exact split support for no-effect/no-signal `WardAbility` static
    creature rows.
  - Requires fixed `{N}` Ward in Oracle text and exactly one XMage
    `new WardAbility(new ManaCostsImpl<>("{N}"))`.
  - Blocks non-mana Ward costs, multiple/ambiguous Ward costs, additional spell
    costs, non-creatures, and source/Oracle mismatches.
- `xmage_batch_pg_package_builder.py`
  - Added manifest whitelist fields for `ward`, `ward_cost`,
    `ward_cost_status`, and `ward_mana_value`.
  - Added `static_ward_counter` execution scenario generation.
- `battle_package_end_to_end_validation.py`
  - Added `static_ward_counter` E2E runner that verifies unpaid target spells
    are countered by Ward and that expected self keywords remain active.
- Tests:
  - Added split tests for fixed-mana Ward selection and non-mana Ward blocking.
  - Added package-builder regression coverage so Ward fields remain present in
    manifest `required_effect_fields` and generate `static_ward_counter`
    scenarios.
  - Added runtime test for unpaid Ward counter behavior.

## PostgreSQL Apply Evidence

Package:

- `pg856_static_ward_creature_new_server_package_manifest.json`
- `pg856_static_ward_creature_new_server_package_precheck.sql`
- `pg856_static_ward_creature_new_server_package_apply.sql`
- `pg856_static_ward_creature_new_server_package_postcheck.sql`
- `pg856_static_ward_creature_new_server_package_rollback.sql`

Precheck on new PostgreSQL target `127.0.0.1:15432/halder`:

- `target_card_rows=1` for all 5 cards.
- `existing_rule_rows=0` for all 5 cards.
- `would_deprecate_shadow_rows=0` for all 5 cards.

Apply:

- `upserted_rows=5`
- `deprecated_shadow_rows=0`

Postcheck:

- `promoted_rule_rows=1` for all 5 cards.
- `promoted_verified_auto_rows=1` for all 5 cards.
- `promoted_oracle_hash_rows=1` for all 5 cards.

Direct PostgreSQL field check:

- Punk Frogs: `ward_cost={3}`, `ward_cost_status=runtime_executor_v1`
- Rimeshield Frost Giant: `ward_cost={3}`,
  `ward_cost_status=runtime_executor_v1`
- Spider-Rex, Daring Dino: `ward_cost={2}`,
  `keywords=["reach","trample"]`, `ward_cost_status=runtime_executor_v1`
- Tomakul Honor Guard: `ward_cost={2}`,
  `ward_cost_status=runtime_executor_v1`
- Waterfall Aerialist: `ward_cost={2}`, `keywords=["flying"]`,
  `ward_cost_status=runtime_executor_v1`

## Sync Evidence

Battle PG -> SQLite:

- Report: `pg856_static_ward_creature_new_server_pg_to_sqlite_sync.json`
- `selected_card_count=5`
- `pg_rows_loaded=5`
- `sqlite_inserted_or_updated=5`
- `canonical_snapshot_rows_exported=6786`

Metadata PG -> Hermes:

- Report: `pg856_static_ward_creature_new_server_metadata_sync.json`
- `postgres_cards_matched=8791`
- `sqlite_cache_alias_rows=8730`
- `unresolved_count=1`

## E2E Evidence

Report:

- `pg856_static_ward_creature_new_server_e2e_validation.json`
- `pg856_static_ward_creature_new_server_e2e_validation.md`

Status: `pass`.

Stages passed:

- `postgres_source_of_truth`: 5 rows
- `sqlite_hermes_cache`: 5 rows
- `canonical_snapshot_fallback`: 5 cards
- `runtime_get_card_effect`: 5 cards
- `battle_execution`: 5 scenarios, 5 events

Battle execution results:

- Punk Frogs countered unpaid target spell with Ward `{3}`.
- Rimeshield Frost Giant countered unpaid target spell with Ward `{3}`.
- Spider-Rex, Daring Dino countered unpaid target spell with Ward `{2}` and
  retained reach/trample.
- Tomakul Honor Guard countered unpaid target spell with Ward `{2}`.
- Waterfall Aerialist countered unpaid target spell with Ward `{2}` and
  retained flying.

## Focused Test Evidence

Passed locally:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.XMageAuthoritativeExactScopeSplitTest.test_static_ward_creature_maps_fixed_mana_ward_and_keywords test_xmage_authoritative_exact_scope_split.XMageAuthoritativeExactScopeSplitTest.test_static_ward_creature_blocks_non_mana_ward_costs`
  - 2 tests passed.
- `python3 -m unittest test_xmage_exact_scope_runtime.XMageExactScopeRuntimeTest.test_static_ward_creature_counters_spell_when_ward_is_unpaid`
  - 1 test passed.
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py -q`
  - 260 tests passed.

## Post-PG856 Global State

Readiness report:

- `global_card_oracle_battle_readiness_20260713_post_pg856_static_ward_creature_new_server.json`
- `all_known_cards=34331`
- `battle_and_oracle_ready=6804`
- `battle_family_mapper_required=26990`
- `battle_rule_verification_required=70`
- `generic_runtime_or_no_card_rule=359`
- `official_oracle_identity_unavailable=3`
- `card_intelligence_snapshot.snapshot_has_verified_rule=6911`

Direct snapshot SQL:

- `total_cards=34331`
- `cards_with_verified_battle_rule=6911`
- `oracle_plus_verified_battle_rule=6911`

XMage authoritative queue:

- `xmage_authoritative_adaptation_queue_20260713_post_pg856_static_ward_creature_new_server_commander_legal.json`
- `target_identity_count=24079`
- `xmage_authoritative_source_count=23766`
- `xmage_missing_source_exception_count=313`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=23766`
- `adapter_work_unit_count=11217`

Exact split recheck:

- `xmage_authoritative_exact_scope_split_20260713_post_pg856_static_ward_creature_new_server_recheck.json`
- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `considered_supported_work_unit_rows=6914`

## Governance Audits

All passed:

- `xmage_strategy_consistency_audit_20260713_post_pg856_static_ward_creature_new_server_final.json`
  - `26/26` checks pass.
- `operational_surface_alignment_audit_20260713_post_pg856_static_ward_creature_new_server_final.json`
  - status `pass`.
- `legacy_contamination_audit_20260713_post_pg856_static_ward_creature_new_server_final.json`
  - status `pass`.
- `pg_hermes_sqlite_contract_audit_20260713_post_pg856_static_ward_creature_new_server_final_new_server.json`
  - `51/51` checks pass.

## Residual Scope

The global objective is not complete. After PG856, the current Commander-legal
XMage queue still has:

- `xmage_authoritative_adapter_required_count=23766`
- `xmage_missing_source_exception_count=313`
- `xmage_authoritative_parser_gap_count=0`

Next work should choose the next exact subpattern from the highest-volume
blocked families, implement the matching runtime/test/manifest support, and
repeat the same PostgreSQL package, sync, E2E, queue, and audit sequence.
