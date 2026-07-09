# PG685 Exile Target And Draw Evidence

Status: applied and validated on the new PostgreSQL target
`127.0.0.1:15432/halder`.

## Scope

- Family: `xmage_exile_target_draw_card_spell`
- Runtime scope: `xmage_exile_target_and_draw_card_spell_v1`
- Cards promoted: `Second Thoughts`, `True Love's Kiss`
- Explicitly not promoted: graveyard-target variants such as `Cremate`

## Runtime Changes

- Added exact split support for `ExileTargetEffect + DrawCardSourceControllerEffect`
  only when Oracle and XMage source agree on fixed battlefield exile plus draw 1.
- Added package E2E scenario type `single_target_removal_and_draw`.
- Added battle package runner coverage that verifies target movement, illegal
  target preservation, draw count, library decrement, and component events.

## PostgreSQL Evidence

- Precheck: 2 Oracle-hash-matched cards, 0 existing rows, 0 shadow rows.
- Apply: 2 upserted rows, 0 deprecated rows.
- Postcheck: 2 promoted rows, both `verified` and `auto`, both with matching
  Oracle hash.
- PG -> SQLite sync:
  - `pg_rows_loaded`: 6086
  - `sqlite_inserted_or_updated`: 6071
  - `canonical_snapshot_rows_exported`: 6048

## E2E Evidence

`docs/hermes-analysis/master_optimizer_reports/pg685_exile_draw_new_server_e2e_validation.md`

- Status: `pass`
- PostgreSQL source of truth: 2 rows validated
- SQLite/Hermes cache: 2 rows validated
- Canonical snapshot fallback: 2 cards validated
- Runtime `get_card_effect`: 2 cards validated
- Battle execution: 2 scenarios, 10 events
- Both cards exiled the legal target, preserved the illegal target, and drew 1
  card from the controller library.

## Post-Apply Global Metrics

`docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260709_post_pg685_exile_draw_new_server.md`

- All known cards: 34331
- `snapshot_has_any_rule`: 7364
- `snapshot_has_verified_rule`: 6174
- `battle_and_oracle_ready`: 6146
- `battle_family_mapper_required`: 27730

`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260709_post_pg685_exile_draw_new_server_commander_legal.md`

- Target identities: 24807
- XMage authoritative source: 24494
- Missing-source exceptions: 313
- Parser gaps: 0
- Adapter required: 24494

`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260709_post_pg685_exile_draw_new_server_recheck.md`

- `proposal_count`: 0
- `safe_for_batch_pg_package_count`: 0

## Verification

- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`
  - `1513 passed, 230 subtests passed`
- `./scripts/quality_gate.sh server-target`
  - pass
- `xmage_strategy_consistency_audit_20260709_post_pg685_exile_draw_new_server_final`
  - pass, 26 checks
- `operational_surface_alignment_audit_20260709_post_pg685_exile_draw_new_server_final`
  - pass
- `legacy_contamination_audit_20260709_post_pg685_exile_draw_new_server_final`
  - pass
- `pg_hermes_sqlite_contract_audit_20260709_post_pg685_exile_draw_new_server_final`
  - pass, 51 checks
