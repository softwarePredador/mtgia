# PG762 Look At Hand + Draw Evidence - 2026-07-11

Status: `applied_synced_validated`

## Scope

Promoted the exact XMage subpattern `LookAtTargetPlayerHandEffect` +
`DrawCardSourceControllerEffect` for simple one-shot spells whose Oracle text
is exactly look at target player's or opponent's hand, then draw a card.

Cards promoted:

- `Peek`
- `Sorcerous Sight`

Battle model scope:

- `xmage_look_at_target_player_hand_draw_card_spell_v1`

## Implementation

- Added exact-scope split support in
  `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`.
- Added battle runtime component `look_at_target_player_hand` inside
  composite resolution.
- Extended package/E2E scenario generation and validation so the runner proves
  the target hand was observed, the target hand was not mutated, and the
  controller drew the expected card.

Focused tests:

```text
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py

python3 -m pytest -q \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_look_at_target_player_hand_draw_maps_peek_scope \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_look_at_target_opponent_hand_draw_maps_sorcerous_sight_scope \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_look_at_hand_draw_blocks_source_oracle_target_mismatch \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py::test_manifest_builds_look_at_hand_draw_spell_execution_scenario \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py::test_look_at_hand_draw_runner_reveals_opponent_hand_and_draws
```

Result: `5 passed`.

## PostgreSQL Package

Split report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg762_look_at_hand_draw_new_server.json`
- `safe_for_batch_pg_package_count=2`

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg762_look_at_hand_draw_new_server_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg762_look_at_hand_draw_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg762_look_at_hand_draw_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg762_look_at_hand_draw_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg762_look_at_hand_draw_new_server_rollback.sql`

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
Peek            verified auto 2 xmage_look_at_target_player_hand_draw_card_spell_v1 target_player_scope=any draw_count=1
Sorcerous Sight verified auto 2 xmage_look_at_target_player_hand_draw_card_spell_v1 target_player_scope=opponent draw_count=1
```

## Sync And E2E

SQLite/Hermes sync:

- `docs/hermes-analysis/master_optimizer_reports/pg762_look_at_hand_draw_new_server_sqlite_sync.json`
- `pg_rows_loaded=10084`
- `sqlite_inserted_or_updated=9862`
- `canonical_snapshot_rows_exported=7476`

E2E:

- `docs/hermes-analysis/master_optimizer_reports/pg762_look_at_hand_draw_new_server_e2e.json`
- `status=pass`
- `scenario_count=2`
- `event_count=10`

Runtime results:

- `Peek`: looked at opponent hand with `target_player_scope=any` and drew 1 card.
- `Sorcerous Sight`: looked at opponent hand with `target_player_scope=opponent` and drew 1 card.

## Global Delta

Readiness:

- `battle_and_oracle_ready`: `6487 -> 6489`
- `battle_family_mapper_required`: `27389 -> 27387`
- `snapshot_has_verified_rule`: `6512 -> 6514`
- `snapshot_has_any_rule`: `7680 -> 7682`

Queue:

- `target_identity_count`: `24466 -> 24464`
- `xmage_authoritative_adapter_required_count`: `24153 -> 24151`
- `xmage_authoritative_parser_gap_count`: `0 -> 0`
- `xmage_missing_source_exception_count`: `313 -> 313`
- `draw_cards::xmage_draw_card_variant_review_v1`: `536 -> 534`

## Audits

All post-PG762 audits passed:

- `pg_hermes_sqlite_contract_audit_20260711_post_pg762_look_at_hand_draw_new_server`: `pass`, `51/51`
- `xmage_strategy_consistency_audit_20260711_post_pg762_look_at_hand_draw_new_server`: `pass`, `26/26`
- `operational_surface_alignment_audit_20260711_post_pg762_look_at_hand_draw_new_server`: `pass`
- `legacy_contamination_audit_20260711_post_pg762_look_at_hand_draw_new_server`: `pass`
