# PG759 Damage Optional Discard Draw Evidence - 2026-07-11

Status: `applied_passed_synced`.

## Scope

- Deploy id: `pg759_damage_optional_discard_draw_new_server`
- Family: `xmage_fixed_damage_draw_card_spell`
- Cards promoted: `2`
- Cards:
  - `Incinerating Blast`
  - `Tweeze`

## Runtime Change

`xmage_fixed_damage_target_and_draw_card_spell_v1` now supports a
`draw_cards` composite component with:

- `optional_cost = discard_card`
- `optional_cost_count = 1`
- `discard_count = 1`

If the optional discard cost cannot be paid, only the draw component is skipped;
the earlier damage component remains resolved. If paid, the discarded card is
moved through the normal discard resolver and then the controller draws.

## XMage Source Contract

The exact-scope splitter now accepts only the narrow XMage shape:

- one fixed `DamageTargetEffect`
- one `DoIfCostPaid(new DrawCardSourceControllerEffect(...), new DiscardCardCost())`
- no additional spell cost
- no target pointer override
- Oracle text matching fixed damage plus: `You may discard a card. If you do, draw a card.`

## PostgreSQL Package

Generated package:

- `docs/hermes-analysis/master_optimizer_reports/pg759_damage_optional_discard_draw_new_server_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg759_damage_optional_discard_draw_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg759_damage_optional_discard_draw_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg759_damage_optional_discard_draw_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg759_damage_optional_discard_draw_new_server_rollback.sql`

Precheck:

- `Incinerating Blast`: target card rows `1`, existing rule rows `0`
- `Tweeze`: target card rows `1`, existing rule rows `0`

Apply:

- `upserted_rows = 2`
- `deprecated_shadow_rows = 0`

Postcheck:

- `promoted_rule_rows = 1` for each card
- `promoted_verified_auto_rows = 1` for each card
- `promoted_oracle_hash_rows = 1` for each card

Direct SQL verification:

- `Incinerating Blast`: `verified/auto`, rule version `2`,
  `xmage_fixed_damage_target_and_draw_card_spell_v1`,
  `optional_discard_draw=true`, discard count `1`, draw count `1`
- `Tweeze`: `verified/auto`, rule version `2`,
  `xmage_fixed_damage_target_and_draw_card_spell_v1`,
  `optional_discard_draw=true`, discard count `1`, draw count `1`

## Sync And E2E

PostgreSQL to SQLite/snapshot sync:

- database target: `127.0.0.1:15432/halder`
- `pg_rows_loaded = 10075`
- `sqlite_inserted_or_updated = 9853`
- `canonical_snapshot_rows_exported = 7467`

Package E2E:

- Status: `pass`
- PostgreSQL source of truth: `2` rows validated
- SQLite/Hermes cache: `2` rows validated
- canonical snapshot fallback: `2` cards validated
- runtime lookup: `2` cards validated
- battle execution: `2` scenarios, `12` events
- `Incinerating Blast`: damage `6`, discarded `1`, drew `1`
- `Tweeze`: damage `3`, discarded `1`, drew `1`

## Focused Tests

Command:

```bash
python3 -m pytest -q \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_fixed_damage_draw_spell_maps_to_composite_runtime \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_fixed_damage_optional_discard_draw_spell_maps_to_composite_runtime \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_fixed_damage_optional_discard_draw_blocks_source_without_paid_cost \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py::XMageExactScopeRuntimeTest::test_composite_damage_draw_spell_damages_player_then_draws_once \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py::XMageExactScopeRuntimeTest::test_composite_damage_optional_discard_draw_spell_pays_cost_then_draws_once \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py::test_manifest_expected_rule_preserves_composite_damage_draw_components \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py::test_damage_optional_discard_draw_execution_scenario_is_manifested \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py::test_damage_draw_spell_runner_pays_optional_discard_and_draws
```

Result: `8 passed`.

## Audits

- `pg_hermes_sqlite_contract_audit_20260711_post_pg759_damage_optional_discard_draw_new_server`: `pass`, 51/51
- `xmage_strategy_consistency_audit_20260711_post_pg759_damage_optional_discard_draw_new_server`: `pass`, 26/26

## Queue Delta

Compared with post-PG758B:

- `battle_and_oracle_ready`: `6478 -> 6480`
- `snapshot_has_verified_rule`: `6503 -> 6505`
- `battle_family_mapper_required`: `27398 -> 27396`
- `target_identity_count`: `24475 -> 24473`
- `xmage_authoritative_adapter_required_count`: `24162 -> 24160`
- `xmage_authoritative_parser_gap_count`: `0 -> 0`
- `xmage_missing_source_exception_count`: `313 -> 313`
- `draw_cards::xmage_draw_card_variant_review_v1`: `540 -> 538`

Residual queue remains active; this file does not claim global completion.
