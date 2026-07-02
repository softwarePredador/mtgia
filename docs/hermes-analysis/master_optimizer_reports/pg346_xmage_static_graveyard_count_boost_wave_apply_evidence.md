# PG346 XMage Static Graveyard Count Boost Wave - PostgreSQL Apply Evidence

Generated: 2026-07-02

Database target: `143.198.230.247:5433/halder`

## Scope

PG346 promoted the exact
`xmage_static_source_boost_equal_graveyard_count_v1` adapter for creatures
whose local XMage source and Oracle text agree on a static source
power/toughness boost equal to a graveyard card count.

Selected cards:

- `Liliana's Elite`
- `Salvage Slasher`
- `Wight of Precinct Six`

## Apply

- transaction completed with `COMMIT`
- inserted or updated promoted rows: `3`
- deprecated shadow rows: `0`
- backup rows created before apply: `0`

## Current PostgreSQL Evidence

The generated precheck and postcheck SQL were re-run after apply against
PostgreSQL. Because this is a post-apply rerun, the precheck now reports the
expected rules as already present.

Post-apply precheck rerun:

- target card rows found: `3/3`
- existing rule rows now present: `3/3`
- expected rule rows now present: `3/3`
- shadow rows currently scheduled for deprecation: `0`

Postcheck:

- promoted rule rows: `3/3`
- promoted verified/auto rows: `3/3`
- promoted rows with Oracle hash: `3/3`
- backup rows: `0`

## Follow-up Validation

- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg346_xmage_static_graveyard_count_boost_wave_pg_to_sqlite_sync.json`
- E2E package validation:
  `docs/hermes-analysis/master_optimizer_reports/pg346_xmage_static_graveyard_count_boost_wave_e2e_validation.md`
- post-PG346 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg346_static_graveyard_count_boost_wave_recheck.md`
- post-PG346 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg346_static_graveyard_count_boost_wave_commander_legal.md`
