# PG344 XMage Static Graveyard Count P/T Wave - PostgreSQL Apply Evidence

Generated: 2026-07-02

Database target: `143.198.230.247:5433/halder`

## Scope

PG344 promoted the exact
`xmage_static_source_power_toughness_equal_graveyard_count_v1` adapter for
creatures whose source power and toughness are each equal to a direct graveyard
card-count expression in XMage and Oracle text.

Selected cards:

- `Boneyard Wurm`
- `Cantivore`
- `Cognivore`
- `Lord of Extinction`
- `Magnivore`
- `Revenant`
- `Slag Fiend`
- `Terravore`

## Precheck

- target card rows found: `8/8`
- existing promoted rule rows before apply: `0`
- expected rule rows before apply: `0`
- shadow rows scheduled for deprecation: `0`

## Apply

- transaction completed with `COMMIT`
- inserted or updated promoted rows: `8`
- deprecated shadow rows: `0`

## Postcheck

- promoted rule rows: `8/8`
- promoted verified/auto rows: `8/8`
- promoted rows with Oracle hash: `8/8`
- backup rows: `0`

## Follow-up Validation

- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_pg_to_sqlite_sync.json`
- E2E package validation:
  `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_e2e_validation.md`
- post-PG344 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg344_static_graveyard_count_pt_wave_recheck.md`
- post-PG344 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg344_static_graveyard_count_pt_wave_commander_legal.md`
