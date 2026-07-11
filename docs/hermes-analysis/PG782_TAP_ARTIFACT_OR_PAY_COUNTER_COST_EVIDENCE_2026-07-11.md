# PG782 Tap Artifact Or Pay Counter Cost Evidence - 2026-07-11

Status: `applied_and_validated`

## Scope

PG782 promotes the XMage-authoritative counterspell additional-cost subpattern:

- `Disruption Protocol`: as an additional cost, tap an untapped artifact you
  control or pay `{1}`; counter target spell.

The related `Wild Unraveling` sample remains intentionally blocked. Its Oracle
text says `blight 2 or pay {1}`, while the local XMage source currently uses
`new GenericManaCost(2)` in the `OrCost`. This requires a separate
XMage/Oracle conflict decision before promotion.

## Runtime And Parser Changes

- `xmage_authoritative_exact_scope_split.py` now maps the exact
  `TapTargetCost(TargetControlledPermanent(FilterControlledArtifactPermanent
  + TappedPredicate.UNTAPPED)) OR GenericManaCost(N)` pattern only when Oracle
  agrees on `tap an untapped artifact you control or pay {N}`.
- The parser intentionally does not promote broader `OrCost + GenericManaCost`
  patterns for damage/destroy/discard/sacrifice yet, because normal spell-cast
  E2E coverage for `pay_generic` needs a separate package.
- `battle_analyst_v9.py` supports:
  - `requires_tap_untapped_artifact`
  - `requires_pay_generic`
  - combined castability checks for counterspells so `{base spell cost}` and
    `{additional generic}` are not checked independently.
- `xmage_batch_pg_package_builder.py` creates an untapped artifact fixture for
  counter E2E scenarios.
- `battle_package_end_to_end_validation.py` verifies `expected_tapped_name`.

## PostgreSQL Apply Evidence

Target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`.

Artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg782_tap_artifact_or_pay_counter_cost_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg782_tap_artifact_or_pay_counter_cost_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg782_tap_artifact_or_pay_counter_cost_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg782_tap_artifact_or_pay_counter_cost_new_server_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg782_tap_artifact_or_pay_counter_cost_new_server_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg782_tap_artifact_or_pay_counter_cost_new_server_package.md`

Precheck:

- `target_card_rows=1`
- `existing_rule_rows=0`
- `would_deprecate_shadow_rows=0`

Apply:

- `upserted_rows=1`
- `deprecated_shadow_rows=0`

Postcheck:

- `promoted_rule_rows=1`
- `promoted_verified_auto_rows=1`
- `promoted_oracle_hash_rows=1`

Direct PG verification:

- `Disruption Protocol`: `verified/auto`,
  `battle_rule_v1:acf4f50321629a08ea98812455ee840a`,
  `choose_tap_untapped_artifact_or_pay_generic`,
  oracle hash `f64d658403423ac3718b4195252ee163`.

## Sync And E2E Evidence

Sync reports:

- `pg782_sync_pg_card_metadata_to_hermes_report.json`
  - `matched=2699/2699`
  - `card_id_updates=96`
  - `unresolved=1`
- `pg782_sync_battle_card_rules_pg_report.json`
  - `pg_rows_loaded=6485`
  - `sqlite_inserted_or_updated=6480`
  - `canonical_snapshot_rows_exported=6436`

E2E package validation:

- Artifact:
  `docs/hermes-analysis/master_optimizer_reports/pg782_tap_artifact_or_pay_counter_cost_new_server_e2e_validation.json`
- Status: `pass`
- Stages passed:
  `postgres_source_of_truth`, `sqlite_hermes_cache`,
  `canonical_snapshot_fallback`, `runtime_get_card_effect`,
  `battle_execution`
- Battle scenario: `1`
- Result: `Disruption Protocol` paid `tap_untapped_artifact` and countered the
  legal stack spell.

## Global Backlog Movement

Readiness after PG782:

- Artifact:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg782_tap_artifact_or_pay_counter_cost_new_server.json`
- `battle_and_oracle_ready`: `6534`, up from `6533`.
- `battle_family_mapper_required`: `27342`, down from `27343`.

XMage adaptation queue after PG782:

- Artifact:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg782_tap_artifact_or_pay_counter_cost_new_server.json`
- `target_identity_count`: `24419`, down from `24420`.
- `xmage_authoritative_adapter_required_count`: `24106`, down from `24107`.
- `xmage_authoritative_parser_gap_count`: `0`.
- `xmage_missing_source_exception_count`: `313`.

## Validation Commands

- `python3 -m py_compile xmage_authoritative_exact_scope_split.py battle_analyst_v9.py xmage_batch_pg_package_builder.py battle_package_end_to_end_validation.py`
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_batch_pg_package_builder.py test_battle_runtime_surface_manifest.py test_runtime_pg_rule_fallback_for_promoted_hotfixes.py test_battle_package_end_to_end_validation.py`
  - `1066 tests OK, 3 skipped`
- `xmage_strategy_consistency_audit_20260711_post_pg782_tap_artifact_or_pay_counter_cost_new_server`
  - `pass`, `26/26`
- `pg_hermes_sqlite_contract_audit_20260711_post_pg782_tap_artifact_or_pay_counter_cost_new_server`
  - `pass`, `51/51`
- `operational_surface_alignment_audit_20260711_post_pg782_tap_artifact_or_pay_counter_cost_new_server`
  - `pass`
- `legacy_contamination_audit_20260711_post_pg782_tap_artifact_or_pay_counter_cost_new_server`
  - `pass`
- `./scripts/quality_gate.sh server-target`
  - `pass`
