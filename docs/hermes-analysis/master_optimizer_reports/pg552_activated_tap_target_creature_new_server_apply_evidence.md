# PG552 Activated Tap Target Creature New Server Apply Evidence

- Generated at: `2026-07-06T05:28:30+00:00`
- PostgreSQL target: `143.198.230.247:5433/halder`
- Deploy id: `pg552_activated_tap_target_creature_new_server`
- Family: `xmage_permanent_simple_activated_tap_target`
- Runtime scope: `xmage_permanent_simple_activated_tap_target_v1`

## Scope

PG552 promotes the narrow XMage pattern:

- `TapTargetEffect`
- `SimpleActivatedAbility`
- `TargetCreaturePermanent`
- optional mana cost plus `TapSourceCost`
- Oracle shape: `{cost}, {T}: Tap target creature.`

Selected cards:

- `Akroan Jailer`
- `Akroan Mastiff`
- `Blinding Mage`
- `Checkpoint Officer`
- `Elite Arrester`
- `Fan Bearer`
- `Frostbridge Guard`
- `Gavony Trapper`
- `Goldmeadow Harrier`
- `Nebelgast Beguiler`
- `Rathi Trapper`
- `Trip Noose`
- `Tyrant's Machine`

Blocked neighbors remain outside this package:

- `activated_tap_target_source_oracle_mismatch`: `5`
- `activated_tap_target_oracle_cost_not_supported`: `2`
- `activated_tap_target_oracle_not_simple`: `1`

## Source Files

- Exact split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_pg552_activated_tap_target_creature_candidate.md`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_package_package.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_package_manifest.json`
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_package_precheck.sql`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_package_apply.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_package_rollback.sql`
- Postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_package_postcheck.sql`

## Runtime And Test Changes

- `battle_analyst_v9.py` now supports
  `xmage_permanent_simple_activated_tap_target_v1` through
  `activate_generic_tap_target_permanent` and
  `activate_best_generic_tap_target_permanent`.
- Runtime activates only when an untapped opponent creature target is available,
  pays the activation cost, taps the source when required, and emits
  `activated_ability` plus `tap_target_resolved`.
- `battle_package_end_to_end_validation.py` now has
  `simple_activated_tap_target` package execution coverage.
- Focused tests passed:
  - `python3 -m py_compile ...`
  - `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`
    -> `616` tests OK
  - `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py`
    -> `52` passed

## PostgreSQL Precheck

Evidence file:
`docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_precheck_output.txt`

- target cards resolved: `13/13`
- each target card row count: `1`
- existing expected rows before apply: `0`
- shadow rows scheduled for deprecation: `0`

## PostgreSQL Apply

Evidence file:
`docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_apply_output.txt`

- `deprecated_shadow_rows`: `0`
- `upserted_rows`: `13`
- transaction result: `COMMIT`

## PostgreSQL Postcheck

Evidence file:
`docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_postcheck_output.txt`

- each card has `promoted_rule_rows = 1`
- each card has `promoted_verified_auto_rows = 1`
- each card has `promoted_oracle_hash_rows = 1`
- backup rows: `0`

## PostgreSQL To Hermes/SQLite Sync

Evidence files:

- `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_sync_report.json`
- `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_sync_output.txt`

Final sync was run with `include_needs_review=true`.

- `pg_rows_loaded`: `8900`
- `sqlite_inserted_or_updated`: `8664`
- `canonical_snapshot_rows_exported`: `6403`

## Package E2E

Evidence files:

- `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_e2e.json`
- `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_e2e.md`
- `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_e2e_output.txt`

Validated stages:

- PostgreSQL source of truth: `13` rows
- SQLite Hermes cache: `13` rows
- canonical snapshot fallback: `13` cards
- runtime `get_card_effect`: `13` cards
- battle execution: `13` scenarios, `26` events

Each promoted card tapped its source and tapped a real E2E creature target.

## Post-Apply Queue And Readiness

Post-sync queue:
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260706_post_pg552_activated_tap_target_creature_new_server.md`

- `target_identity_count`: `25591`
- `xmage_authoritative_source_count`: `25277`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `25277`

Final exact-scope recheck:
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_post_pg552_activated_tap_target_creature_new_server_final.md`

- `proposal_count`: `0`
- `safe_for_batch_pg_package_count`: `0`

Global readiness:
`docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260706_post_pg552_activated_tap_target_creature_new_server.md`

- `snapshot_has_any_rule`: `6406`
- `snapshot_has_verified_rule`: `5181`
- `battle_and_oracle_ready`: `5359`
- `battle_family_mapper_required`: `28514`

## Final Audits

- XMage strategy:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260706_post_pg552_activated_tap_target_creature_new_server_final.md`
  -> `pass`, `26/26`
- Operational surface:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260706_post_pg552_activated_tap_target_creature_new_server_final.md`
  -> `pass`
- Legacy contamination:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260706_post_pg552_activated_tap_target_creature_new_server_final.md`
  -> `pass`
- PG/Hermes/SQLite:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260706_post_pg552_activated_tap_target_creature_new_server_final.md`
  -> `pass`, `51/51`

## Residual Boundary

PG552 does not authorize:

- tap target permanent variants such as artifact/creature/land filters;
- hybrid/life/special activation costs;
- extra Oracle clauses such as "it does not untap";
- source/Oracle mismatches;
- activated target untap or stun-counter effects.

Those remain separate family/subpattern work units.
