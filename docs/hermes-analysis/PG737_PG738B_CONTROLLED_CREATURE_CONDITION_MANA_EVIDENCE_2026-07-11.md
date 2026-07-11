# PG737/PG738B Controlled Creature Condition Mana Evidence - 2026-07-11

Status: `applied_synced_validated`.

Database target: `127.0.0.1:15432/halder` through
`server/bin/with_new_server_pg.sh`.

## PG737 Runtime Scope

PG737 promoted the exact XMage controlled-creature condition mana source family:

- Family: `xmage_controlled_creature_condition_conditional_mana_source`
- Scope: `xmage_controlled_creature_condition_conditional_mana_source_permanent_v1`
- Cards: `Ilysian Caryatid`, `Leafkin Druid`, `Raucous Audience`
- XMage signature: `ConditionalManaEffect` on one `SimpleManaAbility`
- Supported conditions:
  - controller controls a creature with power 4 or greater
  - controller controls four or more creatures
- Runtime behavior:
  - refreshes boosted mana production from current battlefield state
  - supports fixed green boosted production
  - enforces same-color choice for "two mana of any one color"

## PG737 Evidence

Package artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg737_controlled_creature_condition_mana_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg737_controlled_creature_condition_mana_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg737_controlled_creature_condition_mana_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg737_controlled_creature_condition_mana_new_server_package_rollback.sql`

Validation:

- Splitter selected `3` proposals: `Ilysian Caryatid`, `Leafkin Druid`,
  `Raucous Audience`.
- PostgreSQL apply promoted `3` verified executable rows and deprecated `2`
  previous shadow rows.
- E2E status: `pass`.
- E2E battle execution covered `3` scenarios and emitted `3` refresh events.
- Ilysian Caryatid refreshed to `available_mana=2` and `conditional_mana=2`.
- Leafkin Druid and Raucous Audience refreshed to `available_mana=2`.

Focused local tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k controlled_creature_condition`
- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py -k controlled_creature_condition`
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py -k controlled_creature_condition`
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -k controlled_creature_condition`

All focused tests passed after aligning the family-id expectation with the final
condition-based scope.

## PG738B Integrity Backfill

PG738B closed the residual trusted executable `oracle_hash` gap after PG737:

- Precheck: `55` backfillable rows, `54` affected card ids, `0` unsafe rows.
- Apply: `55` rows backfilled from `md5(cards.oracle_text)`.
- Postcheck: `0` remaining trusted executable missing-hash rows.
- Postcheck: `55` backfilled rows retained the expected hash.

Rollback artifact:

- `docs/hermes-analysis/master_optimizer_reports/pg738b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

## Sync And Audit Evidence

Metadata sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg738b_trusted_rule_oracle_hash_backfill_new_server_metadata_sync.json`
- PostgreSQL cards matched: `7426`
- SQLite cache alias rows: `7348`
- `deck_cards`: `2699/2699` matched, `105` card-id updates

Battle-rule sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg738b_trusted_rule_oracle_hash_backfill_new_server_battle_rule_sync_report.json`
- `pg_rows_loaded=6334`
- `sqlite_inserted_or_updated=6329`
- `canonical_snapshot_rows_exported=6285`

Audits after PG738B:

- `pg_hermes_sqlite_contract_audit_20260711_post_pg738b_hash_backfill_new_server`: `pass`, `51/51`
- `xmage_strategy_consistency_audit_20260711_post_pg738b_hash_backfill_new_server`: `pass`, `26/26`
- `operational_surface_alignment_audit_20260711_post_pg738b_hash_backfill_new_server`: `pass`, `48/48`
- `legacy_contamination_audit_20260711_post_pg738b_hash_backfill_new_server`: `pass`, `32/32`
- `./scripts/quality_gate.sh server-target`: `pass`
- `git diff --check`: `pass`

## Current Global Queue After PG738B

Readiness:

- `battle_and_oracle_ready=6383`
- `battle_family_mapper_required=27493`
- `generic_runtime_or_no_card_rule=359`
- `commander_illegal_block=2997`
- `official_oracle_identity_unavailable=3`
- `trusted_rule_oracle_hash_backfill=0` after PG738B

XMage authoritative queue:

- `target_identity_count=24570`
- `xmage_authoritative_source_count=24257`
- `xmage_authoritative_adapter_required_count=24257`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`
- `adapter_work_unit_count=11295`

Top remaining adapter work units:

- `recursion::xmage_graveyard_return_variant_review_v1=1792`
- `draw_engine::xmage_draw_card_variant_review_v1=1567`
- `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1=1064`
- `add_counters::source_add_counters_variant_v1=768`
- `direct_damage::targeted_damage_variant_v1=750`
