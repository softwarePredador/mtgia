# PG730 Graveyard Self-Exile Draw Evidence - 2026-07-11

Status: `applied_validated_synced`.

Target database: `127.0.0.1:15432/halder` via
`./server/bin/with_new_server_pg.sh`.

## Scope

PG730 promotes the narrow XMage subpattern where a permanent card in the
graveyard has a simple activated draw or draw-discard ability whose activation
cost exiles the source card from the graveyard.

Promoted cards:

- `Cobbled Lancer`: `xmage_permanent_simple_activated_draw_v1`
- `Maestros Initiate`: `xmage_permanent_simple_activated_draw_discard_v1`

Runtime support added:

- Parser/splitter recognizes `SimpleActivatedAbility(Zone.GRAVEYARD, ...)`
  with `ExileSourceFromGraveCost`.
- Runtime can activate the source from `player.graveyard`, pay mana, exile the
  source as activation cost, and emit replay evidence with
  `source_zone=graveyard` and `exiled_source_from_graveyard=true`.
- Package builder and E2E validator now generate/validate graveyard source
  scenarios for both draw and draw-discard activations.

## PostgreSQL Apply

PG730 package files:

- `docs/hermes-analysis/master_optimizer_reports/pg730_graveyard_self_exile_draw_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg730_graveyard_self_exile_draw_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg730_graveyard_self_exile_draw_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg730_graveyard_self_exile_draw_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg730_graveyard_self_exile_draw_new_server_package_manifest.json`

Precheck:

- `Cobbled Lancer`: `target_card_rows=1`, `existing_rule_rows=0`,
  `expected_rule_rows_before=0`, `would_deprecate_shadow_rows=0`.
- `Maestros Initiate`: `target_card_rows=1`, `existing_rule_rows=0`,
  `expected_rule_rows_before=0`, `would_deprecate_shadow_rows=0`.

Apply:

- `deprecated_shadow_rows=0`
- `upserted_rows=2`

Postcheck:

- Both promoted rows have `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

PG730B safe oracle hash integrity backfill:

- Precheck: `trusted_auto_missing_hash_rows=55`,
  `safe_backfillable_rows=55`, `unsafe_distinct_hash_rows=0`,
  `unmatched_missing_hash_rows=0`.
- Apply: `oracle_hash_rows_backfilled=55`.
- Postcheck: `backfilled_rows=55`, `rows_with_oracle_hash=55`,
  `rows_matching_current_oracle_hash=55`,
  `remaining_trusted_auto_missing_hash_rows=0`.

PG730B files:

- `docs/hermes-analysis/master_optimizer_reports/pg730b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg730b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg730b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg730b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

## Sync

Battle rule PG -> SQLite sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg730_graveyard_self_exile_draw_pg730b_hash_backfill_pg_to_sqlite_sync.json`
- `database_target=127.0.0.1:15432/halder`
- `pg_rows_loaded=9934`
- `sqlite_inserted_or_updated=9712`
- `canonical_snapshot_rows_exported=7334`

Metadata sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg730_graveyard_self_exile_draw_pg730b_hash_backfill_metadata_sync.json`
- `requested_unique_names=8088`
- `postgres_cards_matched=8279`
- `sqlite_cache_alias_rows=8216`
- `deck_cards card_id_rows_updated=108`
- `unresolved_count=1`

## E2E

Report:
`docs/hermes-analysis/master_optimizer_reports/pg730_graveyard_self_exile_draw_new_server_e2e_validation.md`

Status: `pass`.

Validated stages:

- `postgres_source_of_truth`: `2` rows
- `sqlite_hermes_cache`: `2` rows
- `canonical_snapshot_fallback`: `2` cards
- `runtime_get_card_effect`: `2` cards
- `battle_execution`: `2` scenarios / `2` events

Battle execution evidence:

- `Cobbled Lancer`: drew `1`, `source_zone=graveyard`,
  `exiled_source_from_graveyard=true`.
- `Maestros Initiate`: drew `2`, discarded `1`, `source_zone=graveyard`,
  `exiled_source_from_graveyard=true`.

## Final Readiness

Report:
`docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg730b_graveyard_self_exile_draw_new_server.md`

- `all_known_cards=34331`
- `battle_and_oracle_ready=6339`
- `snapshot_has_verified_rule=6364`
- `snapshot_has_any_rule=7540`
- `battle_family_mapper_required=27537`
- `trusted_rule_oracle_hash_backfill` is absent after PG730B.

XMage authoritative queue:

Report:
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg730b_graveyard_self_exile_draw_commander_legal.md`

- `target_identity_count=24614`
- `xmage_authoritative_source_count=24301`
- `xmage_authoritative_adapter_required_count=24301`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`
- `adapter_work_unit_count=11298`

Exact split recheck:

Report:
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_post_pg730b_graveyard_self_exile_draw_recheck.md`

- `safe_for_batch_pg_package_count=0`
- `proposal_count=0`
- `family_counts={}`

## Gates

Code checks:

- `python3 -m py_compile` for splitter, runtime, package builder, and E2E
  validator: pass.
- `test_xmage_authoritative_exact_scope_split.py -k "graveyard_self_exile_cost or permanent_activated_draw"`:
  `19 passed`.
- `test_xmage_batch_pg_package_builder.py -k "graveyard_self_exile_scenario or simple_activated_draw"`:
  `5 passed`.
- `test_battle_package_end_to_end_validation.py -k "simple_activated_draw_runner or draw_discard_runner_executes_graveyard_self_exile_cost"`:
  `5 passed`.

Alignment audits:

- `xmage_strategy_consistency_audit`: pass, `26/26`.
- `operational_surface_alignment_audit`: pass.
- `pg_hermes_sqlite_contract_audit`: pass, `51/51`.
- `legacy_contamination_audit`: pass.
- `./scripts/quality_gate.sh server-target`: pass.

## Residual Queue

This lote does not complete the global objective. It removes the PG730 exact
subpattern from the queue and leaves the global Commander-legal queue at:

- `24301` XMage-authoritative identities still requiring ManaLoom adapter work.
- `313` local-XMage missing-source exceptions requiring separate decision.
- `0` parser gaps.
