# PG790 Hand Cycling Evidence - 2026-07-11

Status: `applied_and_verified`

## Scope

PG790 promotes the exact XMage -> ManaLoom subpattern
`xmage_creature_hand_cycling`: creature cards whose XMage source has
`CyclingAbility`, no effect classes, and only optional static self keyword
abilities, with Oracle and XMage agreeing on the cycling cost.

Promoted cards: `24`

Runtime scope: `xmage_hand_cycling_only_v1`

## Package Evidence

- Split report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg790_hand_cycling_new_server_candidate.json`
- Package manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_package_manifest.json`
- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_package_precheck.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_package_apply.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_package_postcheck.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_package_rollback.sql`

Apply result:

- `deprecated_shadow_rows=0`
- `upserted_rows=24`
- Postcheck showed all 24 rows with promoted rule, verified/auto status, and
  Oracle hash.

## Runtime And E2E

Focused tests:

- Command:
  `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`
- Result: `1438 passed, 238 subtests passed`

Package E2E:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_e2e_validation.json`
- Status: `pass`
- Scenarios: `24`
- Events: `24`

## Sync Evidence

PostgreSQL -> SQLite/card snapshot:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_pg_to_sqlite_sync.json`
- Target: `127.0.0.1:15432/halder`
- PostgreSQL rows loaded: `10190`
- SQLite inserted/updated: `9968`
- Canonical snapshot rows exported: `7578`

Metadata sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg790_hand_cycling_new_server_metadata_sync.json`
- Target: `127.0.0.1:15432/halder`
- Requested unique names: `8328`
- PostgreSQL cards matched: `8519`
- SQLite cache alias rows: `8458`
- Deck card backfill: `2699/2699` matched, `88` card ids updated
- Residual unresolved sample: `Surgical Suite/Hospital Room`

## Final Gates

- XMage strategy consistency:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260711_post_pg790_hand_cycling_new_server_final.json`
  - Status: `pass`
  - Checks: `26/26`
- Operational surface alignment:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260711_post_pg790_hand_cycling_new_server_final.json`
  - Status: `pass`
  - Checks: `48/48`
- Legacy contamination:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260711_post_pg790_hand_cycling_new_server_final.json`
  - Status: `pass`
  - Checks: `32/32`
- PostgreSQL/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260711_post_pg790_hand_cycling_new_server_final.json`
  - Status: `pass`
  - Checks: `51/51`
- Server target quality gate:
  `./scripts/quality_gate.sh server-target`
  - Status: `pass`

## Post-PG790 Global State

Readiness report:
`docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg790_hand_cycling_new_server.json`

- All known cards: `34331`
- `battle_and_oracle_ready`: `6584`
- `snapshot_has_verified_rule`: `6620`
- `snapshot_has_any_rule`: `7784`
- `battle_family_mapper_required`: `27281`
- `generic_runtime_or_no_card_rule`: `359`
- `commander_illegal_block`: `2997`

Authoritative XMage queue:
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg790_hand_cycling_new_server.json`

- Target identities: `24369`
- XMage authoritative source count: `24056`
- XMage missing source exceptions: `313`
- XMage parser gaps: `0`
- XMage adapter required: `24056`

Exact split recheck:
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_post_pg790_hand_cycling_new_server_recheck.json`

- Safe for batch PostgreSQL package: `0`
- Remaining proposals: `3`
- Remaining proposal status: `runtime_partial_requires_family_runtime`
- Remaining family: `xmage_simple_mana_source_with_unmodeled_auxiliary`
