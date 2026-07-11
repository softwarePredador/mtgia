# PG761 Tap Target + Draw Evidence - 2026-07-11

Status: `applied_synced_validated`

## Scope

Promoted the exact XMage subpattern `TapTargetEffect` +
`DrawCardSourceControllerEffect` for simple one-shot spells whose Oracle text
is exactly tap target permanent(s), then draw a card.

Cards promoted:

- `Pressure Point`
- `Repel the Darkness`

Battle model scope:

- `xmage_tap_target_and_draw_card_spell_v1`

## Implementation

- Added exact-scope split support in
  `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`.
- Reused existing battle runtime composite resolution for `tap_target` and
  `draw_cards`.
- Extended package/E2E scenario generation so the tap-target runner validates
  both target tapping and card draw.

Focused tests:

```text
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py

python3 -m pytest -q \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_tap_target_creature_draw_spell_maps_to_composite_scope \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_tap_up_to_two_target_creatures_draw_spell_maps_to_composite_scope \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_tap_draw_spell_blocks_permanent_with_extra_ability \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_tap_up_to_three_target_creatures_spell_maps_to_tap_target_scope \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py::test_manifest_builds_tap_target_draw_spell_execution_scenario \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py::test_manifest_builds_tap_target_spell_execution_scenario \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py::test_tap_target_spell_runner_executes_composite_draw \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py::test_tap_target_spell_runner_executes_multi_target_spell
```

Result: `8 passed`.

## PostgreSQL Package

Split report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg761_tap_target_draw_new_server.json`
- `safe_for_batch_pg_package_count=2`

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg761_tap_target_draw_new_server_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg761_tap_target_draw_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg761_tap_target_draw_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg761_tap_target_draw_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg761_tap_target_draw_new_server_rollback.sql`

Precheck:

- `target_card_rows=1` for each card
- `existing_rule_rows=0`
- `would_deprecate_shadow_rows=0`

Apply/postcheck:

- `upserted_rows=2`
- `deprecated_shadow_rows=0`
- `promoted_verified_auto_rows=1` for each card
- `promoted_oracle_hash_rows=1` for each card

Direct PostgreSQL verification:

```text
Pressure Point     verified auto 2 xmage_tap_target_and_draw_card_spell_v1 draw_count=1 target_count=1 up_to=false
Repel the Darkness verified auto 2 xmage_tap_target_and_draw_card_spell_v1 draw_count=1 target_count=2 up_to=true
```

## Sync And E2E

SQLite/Hermes sync:

- `docs/hermes-analysis/master_optimizer_reports/pg761_tap_target_draw_new_server_sqlite_sync.json`
- `pg_rows_loaded=10082`
- `sqlite_inserted_or_updated=9860`
- `canonical_snapshot_rows_exported=7474`

E2E:

- `docs/hermes-analysis/master_optimizer_reports/pg761_tap_target_draw_new_server_e2e.json`
- `status=pass`
- `scenario_count=2`
- `event_count=10`

Runtime results:

- `Pressure Point`: tapped 1 target and drew 1 card.
- `Repel the Darkness`: tapped 2 targets and drew 1 card.

## Global Delta

Readiness:

- `battle_and_oracle_ready`: `6485 -> 6487`
- `battle_family_mapper_required`: `27391 -> 27389`
- `snapshot_has_verified_rule`: `6510 -> 6512`
- `snapshot_has_any_rule`: `7678 -> 7680`

Queue:

- `target_identity_count`: `24468 -> 24466`
- `xmage_authoritative_adapter_required_count`: `24155 -> 24153`
- `xmage_authoritative_parser_gap_count`: `0 -> 0`
- `xmage_missing_source_exception_count`: `313 -> 313`
- `draw_cards::xmage_draw_card_variant_review_v1`: `538 -> 536`

## Audits

All post-PG761 audits passed:

- `pg_hermes_sqlite_contract_audit_20260711_post_pg761_tap_target_draw_new_server`: `pass`, `51/51`
- `xmage_strategy_consistency_audit_20260711_post_pg761_tap_target_draw_new_server`: `pass`, `26/26`
- `operational_surface_alignment_audit_20260711_post_pg761_tap_target_draw_new_server`: `pass`
- `legacy_contamination_audit_20260711_post_pg761_tap_target_draw_new_server`: `pass`
