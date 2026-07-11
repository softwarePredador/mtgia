# PG746 ETB Dynamic Draw Death Count Evidence - 2026-07-11

Status: `promoted_synced_validated`

## Scope

PG746 promotes the exact XMage-derived subpattern for creature ETB dynamic draw
where the draw count equals the number of creatures that died under the
controller's control this turn.

Promoted card:

- `Liliana's Standard Bearer`

Exact battle scope:

- `xmage_creature_etb_dynamic_draw_cards_v1`

Required effect fields:

- `effect=creature`
- `ability_kind=triggered`
- `trigger=enters_battlefield`
- `trigger_effect=dynamic_draw_cards`
- `etb_dynamic_draw=true`
- `etb_draw_count_source=creatures_you_control_died_this_turn`
- `draw_count_source=creatures_you_control_died_this_turn`
- `flash=true`

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg746_etb_dynamic_draw_death_count_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg746_etb_dynamic_draw_death_count_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg746_etb_dynamic_draw_death_count_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg746_etb_dynamic_draw_death_count_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg746_etb_dynamic_draw_death_count_package_manifest.json`

Apply result:

- target card rows: `1`
- existing rule rows before apply: `0`
- deprecated shadow rows: `0`
- upserted rows: `1`
- promoted rule rows after apply: `1`
- promoted `verified` + `auto` rows after apply: `1`
- promoted rows with oracle hash after apply: `1`

## Sync

Battle rules sync:

- command target: `127.0.0.1:15432/halder`
- PostgreSQL rows loaded: `6369`
- SQLite inserted or updated: `6364`
- canonical snapshot rows exported: `6318`
- report: `docs/hermes-analysis/master_optimizer_reports/pg746_etb_dynamic_draw_death_count_sync_battle_rules_report.json`

PostgreSQL metadata to Hermes sync:

- command target: `127.0.0.1:15432/halder`
- PostgreSQL cards matched: `7460`
- SQLite cache alias rows: `7382`
- deck card backfill present: `true`
- report: `docs/hermes-analysis/master_optimizer_reports/pg746_etb_dynamic_draw_death_count_sync_pg_card_metadata_report.json`

## End-To-End Validation

Report:

- `docs/hermes-analysis/master_optimizer_reports/pg746_etb_dynamic_draw_death_count_e2e_after_sync_report.json`
- `docs/hermes-analysis/master_optimizer_reports/pg746_etb_dynamic_draw_death_count_e2e_after_sync_report.md`

Result: `pass`

Validated stages:

- PostgreSQL source of truth: `pass`
- SQLite/Hermes cache: `pass`
- canonical snapshot fallback: `pass`
- runtime `get_card_effect`: `pass`
- battle execution: `pass`

Execution proof:

- scenario: `Liliana's Standard Bearer draws on ETB`
- creatures that died under controller control this turn: `3`
- cards drawn: `3`
- hand after trigger: `3`
- validated keyword: `flash`

## Regression Tests

Commands passed:

```bash
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py
```

Result: `1477 tests OK`

```bash
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m pytest -q \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py
```

Result: `293 passed`

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py
```

Result: `pass`

## Global Queue Impact

Readiness report:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg746_etb_dynamic_draw_death_count_new_server.json`

Post-PG746 counts:

- `battle_and_oracle_ready`: `6418`
- `snapshot_has_verified_rule`: `6443`
- `battle_family_mapper_required`: `27458`
- `generic_runtime_or_no_card_rule`: `359`

Commander-legal XMage queue:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg746_etb_dynamic_draw_death_count_commander_legal.json`

Post-PG746 queue counts:

- target identities: `24535`
- XMage authoritative adapter required: `24222`
- XMage parser gaps: `0`
- missing XMage source exceptions: `313`

## Audits

Passed audits:

- XMage strategy consistency: `26/26 pass`
- operational surface alignment: `48/48 pass`
- PostgreSQL/Hermes/SQLite contract: `51/51 pass`
- legacy contamination: `32/32 pass`

Audit reports:

- `docs/hermes-analysis/master_optimizer_reports/pg746_etb_dynamic_draw_death_count_xmage_strategy_consistency_audit.json`
- `docs/hermes-analysis/master_optimizer_reports/pg746_etb_dynamic_draw_death_count_operational_surface_alignment_audit.json`
- `docs/hermes-analysis/master_optimizer_reports/pg746_etb_dynamic_draw_death_count_pg_hermes_sqlite_contract_audit.json`
- `docs/hermes-analysis/master_optimizer_reports/pg746_etb_dynamic_draw_death_count_legacy_contamination_audit.json`

## Next Queue

The next largest unresolved exact-family source remains
`draw_engine::xmage_draw_card_variant_review_v1`, now with `1553` identities in
the Commander-legal queue. The next step is to split another exact runtime-safe
subpattern from that review lane or move to the next high-volume lane where the
splitter can produce a batch larger than one without weakening the runtime gate.
