# PG845 Conditional Activated Draw Evidence - 2026-07-12

Status: applied on the new PostgreSQL target via `server/bin/with_new_server_pg.sh`.

## Scope

XMage exact subpattern:

- `draw_engine::xmage_draw_card_variant_review_v1`
- `DrawCardSourceControllerEffect`
- `ActivateIfConditionActivatedAbility`
- executable ManaLoom scope: `xmage_permanent_simple_activated_draw_v1`

Promoted cards:

- `Endless Atlas`
- `Falkenrath Pit Fighter`
- `Fool's Tome`
- `Ragamuffyn`
- `Tapestry of the Ages`

Runtime condition support added:

- `controller_has_no_cards_in_hand`
- `controller_controls_lands_same_name_gte`
- `controller_cast_noncreature_spell_this_turn`
- `opponent_lost_life_this_turn`
- `controller_turn_before_attackers_declared`

## PostgreSQL

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg845_conditional_activated_draw_new_server_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg845_conditional_activated_draw_new_server_manifest.json`
- precheck/apply/postcheck/rollback SQL under `pg845_conditional_activated_draw_new_server_*`

Apply result:

- precheck: 5 target card rows, 0 existing matching rows, 0 shadow rows
- apply: 5 upserted rows
- postcheck: 5 promoted verified/auto rows with `oracle_hash`

Follow-up integrity package:

- `PG845B` backfilled 55 older curated/manual trusted executable rows that were missing `oracle_hash`
- postcheck after PG845B: `trusted_executable_rules_missing_oracle_hash=0`, `backup_rows=55`, `updated_rows_with_current_oracle_hash=55`

## Sync And Validation

Final sync:

- `pg845_conditional_activated_draw_new_server_metadata_sync.json`
- `pg845b_trusted_rule_oracle_hash_backfill_new_server_sqlite_sync.json`
- `known_cards_canonical_snapshot.json` exported with 7,791 canonical snapshot rows

Final E2E:

- `pg845_conditional_activated_draw_new_server_e2e.json`
- status: `pass`
- stages passed: PostgreSQL source of truth, SQLite Hermes cache, canonical snapshot, runtime `get_card_effect`, battle execution
- battle execution: 5 scenarios, 5 events

Final audits:

- `xmage_strategy_consistency_audit_20260712_post_pg845_conditional_activated_draw_new_server.json`: `pass`, 26 checks
- `pg_hermes_sqlite_contract_audit_20260712_post_pg845b_hash_backfill_new_server.json`: `pass`, 51 checks

## Queue Impact

Readiness after PG845:

- `battle_and_oracle_ready`: 6,740
- `snapshot_has_verified_rule`: 6,847
- `battle_family_mapper_required`: 27,054

XMage authoritative queue after PG845:

- `xmage_authoritative_adapter_required_count`: 23,830
- `xmage_authoritative_parser_gap_count`: 0
- `xmage_missing_source_exception_count`: 313

Exact recheck:

- `xmage_authoritative_exact_scope_split_20260712_post_pg845_conditional_activated_draw_new_server_recheck.json`
- `safe_for_batch_pg_package_count`: 0 for this subpattern
- remaining proposal is `The Golden Throne` as `runtime_partial_requires_family_runtime`, not part of PG845
