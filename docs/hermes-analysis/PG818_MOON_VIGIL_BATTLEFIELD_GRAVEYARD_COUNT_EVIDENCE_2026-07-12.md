# PG818 Moon-Vigil Battlefield Plus Graveyard Count Evidence - 2026-07-12

Status: applied on the new-server PostgreSQL target through
`server/bin/with_new_server_pg.sh`.

Database target reported by sync/E2E: `127.0.0.1:15432/halder`.

## Scope

PG818 adds a runtime-backed exact-scope adapter for the XMage pattern used by
`Moon-Vigil Adherents`:

- XMage source class: `MoonVigilAdherents`
- XMage behavior: `BoostSourceEffect(xValue, xValue, Duration.WhileOnBattlefield)`
- Count source: creatures controlled plus creature cards in controller
  graveyard
- ManaLoom scope: `xmage_static_source_power_toughness_equal_count_v1`
- ManaLoom amount source: `battlefield_plus_graveyard_card_count`

This is not a generic review promotion. It is an exact source/runtime adapter
with focused parser, runtime, builder, PostgreSQL, SQLite, snapshot, and battle
execution validation.

## Implementation

- Runtime: `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- Splitter: `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
- Package builder: `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py`
- Tests:
  - `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`

## SQL Package

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg818_moon_vigil_battlefield_graveyard_count_new_server_precheck.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg818_moon_vigil_battlefield_graveyard_count_new_server_apply.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg818_moon_vigil_battlefield_graveyard_count_new_server_postcheck.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/pg818_moon_vigil_battlefield_graveyard_count_new_server_rollback.sql`
- Backup table: `manaloom_deploy_audit.pg818_moon_vigil_battlefield_graveyard_c_20260712_081746`

## PostgreSQL State

Current verified row:

- Card: `Moon-Vigil Adherents`
- Rule: `battle_rule_v1:6977607d38bfd0e099168453a2429947`
- Review/execution: `verified` / `auto`
- Oracle hash: `9cee561f4c31037d7e00016470bc710f`
- Battle model scope: `xmage_static_source_power_toughness_equal_count_v1`
- Amount source: `battlefield_plus_graveyard_card_count`
- Battlefield count card types: `["creature"]`
- Graveyard count card types: `["creature"]`

## Validation

Focused tests:

- `python3 -m py_compile ...`: `pass`
- `test_xmage_authoritative_exact_scope_split.py -k static_graveyard_count_boost_zero_base`: `pass`
- `test_xmage_exact_scope_runtime.py -k static_count_power_toughness_extended_dynamic_sources`: `pass`
- `pytest test_xmage_batch_pg_package_builder.py -k battlefield_plus_graveyard_card_count`: `1 passed`

Post-PG819 E2E:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg818_moon_vigil_battlefield_graveyard_count_new_server_post_pg819_e2e.md`
- Status: `pass`
- PostgreSQL source of truth: `pass`
- SQLite Hermes cache: `pass`
- Canonical snapshot fallback: `pass`
- Runtime `get_card_effect`: `pass`
- Battle execution: `pass`
- Battle event: count `3`, power `3`, toughness `3`

Global readiness after PG818 + PG819:

- Report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg819_hash_backfill_new_server.md`
- `battle_and_oracle_ready`: `6641`
- `battle_family_mapper_required`: `27153`
- `battle_rule_verification_required`: `70`
