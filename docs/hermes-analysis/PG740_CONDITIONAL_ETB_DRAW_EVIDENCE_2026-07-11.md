# PG740 Conditional ETB Draw Evidence - 2026-07-11

Status: `applied_and_validated`

Database target: `127.0.0.1:15432/halder` through
`server/bin/with_new_server_pg.sh`.

## Scope

PG740 promotes the exact XMage-backed conditional creature ETB draw subpattern
inside `xmage_creature_etb_draw_cards_v1`.

Promoted cards:

- `Donatello, Turtle Techie`
- `Opal Lake Gatekeepers`
- `Resistance Squad`
- `Rhox Meditant`
- `Scholar of Stars`
- `Settlement Blacksmith`

The supported condition is
`controller_controls_matching_permanent` with runtime-executable filters for
card type, subtype, color, minimum count, and source exclusion. Unsupported ETB
draw conditions remain blocked.

## Runtime And Mapper Changes

- `xmage_authoritative_exact_scope_split.py`
  - selects conditional ETB draw only when Oracle and XMage source both match a
    supported controlled-permanent condition;
  - emits condition metadata under `etb_draw_condition_*`;
  - blocks unsupported conditions such as raid/attacked-this-turn.
- `battle_analyst_v9.py`
  - resolves the ETB draw only when the condition is satisfied;
  - emits `trigger_skipped` with `etb_draw_condition_not_met` when it is not;
  - preserves the existing `trigger_resolved` draw event when satisfied.
- `xmage_batch_pg_package_builder.py`
  - includes condition fields in required effect validation;
  - generates focused `creature_etb_draw` scenarios with fixture permanents.
- `battle_package_end_to_end_validation.py`
  - executes `creature_etb_draw` scenarios through the runtime.

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg740_conditional_etb_draw_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg740_conditional_etb_draw_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg740_conditional_etb_draw_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg740_conditional_etb_draw_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg740_conditional_etb_draw_new_server_package_manifest.json`

Package evidence:

- split report selected `6` exact proposals in
  `xmage_creature_etb_conditional_draw_cards`;
- precheck found `6` target rows, `0` existing promoted rows, and `0` shadow
  rows to deprecate;
- apply upserted `6` rows;
- postcheck confirmed `6/6` verified/auto promoted rows with matching
  `oracle_hash`.

## PG740B Hash Backfill

The first post-PG740 contract audit found a pre-existing global integrity gap:
`55` trusted executable curated rules had blank `oracle_hash`. PG740B backfilled
only rows where `cards.oracle_text` was present, using `md5(cards.oracle_text)`.
This is metadata integrity only; it does not change rule behavior.

Backfill files:

- `docs/hermes-analysis/master_optimizer_reports/pg740b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg740b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg740b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg740b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

Backfill evidence:

- precheck: `55` missing trusted executable hashes, `55` computable,
  `0` without Oracle text;
- apply: `55` rows backfilled;
- postcheck: `trusted_executable_rules_missing_oracle_hash=0`,
  `backup_rows=55`, `backfilled_rows_matching_card_oracle_hash=55`.

## Sync And E2E

PG -> SQLite sync:

- report:
  `docs/hermes-analysis/master_optimizer_reports/pg740b_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
- `pg_rows_loaded=6345`
- `sqlite_inserted_or_updated=6340`
- `canonical_snapshot_rows_exported=6294`

Package E2E:

- report:
  `docs/hermes-analysis/master_optimizer_reports/pg740_conditional_etb_draw_new_server_post_pg740b_e2e.md`
- PostgreSQL source of truth: `6/6`
- SQLite/Hermes cache: `6/6`
- canonical snapshot fallback: `6/6`
- runtime `get_card_effect`: `6/6`
- battle execution: `6` scenarios and `6` draw events

## Final Post-PG740B State

Global readiness:

- `total_cards=34331`
- `function_tagged=25380`
- `verified_battle_rule=6419`
- `function_plus_verified_rule=4899`
- `battle_and_oracle_ready=6394`
- `battle_family_mapper_required=27482`
- `snapshot_has_any_rule=7590`
- `snapshot_has_verified_rule=6419`

Authoritative queue:

- `target_identity_count=24559`
- `xmage_authoritative_source_count=24246`
- `xmage_missing_source_exception_count=313`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=24246`
- `adapter_work_unit_count=11295`
- top draw-engine work unit:
  `draw_engine::xmage_draw_card_variant_review_v1=1561`

Validation gates:

- `pg_hermes_sqlite_contract_audit_20260711_post_pg740b_conditional_etb_draw_hash_backfill_new_server_final`: `pass`, `51/51`
- `global_card_oracle_battle_readiness_20260711_post_pg740b_conditional_etb_draw_hash_backfill_new_server`: `action_required` for remaining global families, not PG740 failure
- `xmage_authoritative_adaptation_queue_20260711_post_pg740b_conditional_etb_draw_hash_backfill_new_server_commander_legal`: `action_required` for remaining global adapter work, parser gap `0`
