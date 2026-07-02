# PG345 XMage Static Graveyard Threshold Boost Wave - PostgreSQL Apply Evidence

Generated: 2026-07-02

Database target: `143.198.230.247:5433/halder`

## Scope

PG345 promoted the exact
`xmage_static_source_boost_if_graveyard_threshold_v1` adapter for creatures
whose XMage source and Oracle text agree on a static source power/toughness
boost gated by controller graveyard card count.

Selected cards:

- `Anurid Barkripper`
- `Basking Capybara`
- `Frilled Cave-Wurm`
- `Krosan Beast`
- `Metamorphic Wurm`
- `Seton's Scout`
- `Springing Tiger`

## Precheck

- target card rows found: `7/7`
- existing promoted rule rows before apply: `0`
- expected rule rows before apply: `0`
- shadow rows scheduled for deprecation: `0`

## Apply

- transaction completed with `COMMIT`
- inserted or updated promoted rows: `7`
- deprecated shadow rows: `0`
- backup rows created before apply: `0`

## Postcheck

- promoted rule rows: `7/7`
- promoted verified/auto rows: `7/7`
- promoted rows with Oracle hash: `7/7`
- backup rows: `0`

## Follow-up Validation

- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_pg_to_sqlite_sync.json`
- E2E package validation:
  `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_e2e_validation.md`
- post-PG345 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg345_static_graveyard_threshold_boost_wave_recheck.md`
- post-PG345 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg345_static_graveyard_threshold_boost_wave_commander_legal.md`
