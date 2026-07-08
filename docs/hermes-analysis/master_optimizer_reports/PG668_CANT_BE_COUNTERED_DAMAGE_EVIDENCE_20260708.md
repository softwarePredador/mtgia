# PG668 Cant-Be-Countered Damage Evidence - 2026-07-08

Status: applied and validated on the new server PostgreSQL target
`127.0.0.1:15432/halder`.

## Scope

XMage exact-scope adapter extension for fixed target damage spells with
`CantBeCounteredSourceEffect` plus `DamageTargetEffect`.

Promoted cards:

- `Heated Debate`
- `Rending Volley`

Explicitly blocked:

- `Combust`: `damage_cant_be_prevented_not_supported`, because
  `withCantBePrevented()` is not modeled by the current ManaLoom runtime.

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg668_cant_be_countered_damage_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg668_cant_be_countered_damage_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg668_cant_be_countered_damage_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg668_cant_be_countered_damage_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg668_cant_be_countered_damage_package_rollback.sql`

Precheck:

- `Heated Debate`: `target_card_rows=1`, `existing_rule_rows=0`,
  `expected_rule_rows_before=0`, `would_deprecate_shadow_rows=0`
- `Rending Volley`: `target_card_rows=1`, `existing_rule_rows=2`,
  `expected_rule_rows_before=0`, `would_deprecate_shadow_rows=2`
- The two old `Rending Volley` rows were `needs_review/review_only`, had no
  `oracle_hash`, and used `{"effect":"unknown","uncounterable":true}`.

Apply:

- `deprecated_shadow_rows=2`
- `upserted_rows=2`
- Backup table:
  `manaloom_deploy_audit.pg668_cant_be_countered_damage_20260708_185901`

Postcheck:

- `Heated Debate`: `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`
- `Rending Volley`: `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`

Direct PostgreSQL verification:

- `Heated Debate`: `review_status=verified`, `execution_status=auto`,
  `battle_model_scope=xmage_fixed_damage_target_spell_v1`,
  `cant_be_countered=true`,
  `target_constraints={"card_types":["creature","planeswalker"]}`
- `Rending Volley`: `review_status=verified`, `execution_status=auto`,
  `battle_model_scope=xmage_fixed_damage_target_spell_v1`,
  `cant_be_countered=true`,
  `target_constraints={"card_types":["creature"],"target_colors":["W","U"]}`

## Sync And E2E

PostgreSQL to Hermes/SQLite sync:

- `pg_rows_loaded=5985`
- `sqlite_inserted_or_updated=5971`
- `canonical_snapshot_rows_exported=5948`

E2E package validation:

- Status: `pass`
- PostgreSQL source of truth: `2` rows validated
- SQLite/Hermes cache: `2` rows validated
- Canonical snapshot fallback: `2` cards validated
- Runtime lookup: `2` cards validated
- Battle execution: `2` scenarios, `6` events
- `Heated Debate`: dealt `4` damage to the legal target and
  `cant_be_countered=true`
- `Rending Volley`: dealt `4` damage to the legal white/blue creature target,
  preserved the illegal black-creature decoy, and `cant_be_countered=true`

## Global Readiness Delta

Post-PG668 readiness:

- `battle_and_oracle_ready=6045` up from `6043`
- `battle_family_mapper_required=27831` down from `27833`
- `snapshot_has_verified_rule=6073` up from `6071`
- Commander-legal XMage queue `target_identity_count=24908` down from `24910`
- `direct_damage::targeted_damage_variant_v1=763` down from `765`
- Post-PG668 exact-scope split recheck: `proposal_count=0`

## Tests And Audits

Tests:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split test_xmage_exact_scope_runtime`
  passed: `1277` tests
- `python3 -m pytest test_xmage_batch_pg_package_builder.py test_battle_package_end_to_end_validation.py -q`
  passed: `142` tests

Audits:

- `xmage_strategy_consistency_audit_20260708_post_pg668_cant_be_countered_damage_new_server_final`: `pass`, `26/26`
- `pg_hermes_sqlite_contract_audit_20260708_post_pg668_cant_be_countered_damage_new_server_final`: `pass`, `51/51`
- `operational_surface_alignment_audit_20260708_post_pg668_cant_be_countered_damage_new_server_final`: `pass`
- `legacy_contamination_audit_20260708_post_pg668_cant_be_countered_damage_new_server_final`: `pass`
