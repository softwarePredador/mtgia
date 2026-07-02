# PG347 XMage Activated Graveyard To Owner Library Wave - PostgreSQL Apply Evidence

Generated: 2026-07-02

Database target: `143.198.230.247:5433/halder`

## Scope

PG347 promoted the exact
`xmage_permanent_simple_activated_graveyard_to_library_v1` adapter extension
for permanents whose local XMage source and Oracle text agree on this
activated ability:

`Put target card from a graveyard on the bottom of its owner's library.`

Selected cards:

- `Cogwork Archivist`
- `Jade-Cast Sentinel`
- `Junktroller`
- `Phyrexian Archivist`
- `Reito Lantern`

## Apply

- precheck found Oracle-hash-matched target rows: `5/5`
- precheck found existing expected rule rows before apply: `0/5`
- transaction completed with `COMMIT`
- inserted or updated promoted rows: `5`
- deprecated shadow rows: `0`
- backup rows created before apply: `0`

## Current PostgreSQL Evidence

Postcheck:

- promoted rule rows: `5/5`
- promoted verified/auto rows: `5/5`
- promoted rows with Oracle hash: `5/5`
- backup rows: `0`

Raw SQL outputs:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_precheck.out`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_apply.out`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_postcheck.out`

## Follow-up Validation

- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_pg_to_sqlite_sync.json`
- E2E package validation:
  `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_e2e_validation.md`
- post-PG347 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg347_activated_graveyard_to_owner_library_wave_recheck.md`
- post-PG347 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg347_activated_graveyard_to_owner_library_wave_commander_legal.md`

## Measured Queue Impact

- `target_identity_count`: `27185` -> `27180`
- `xmage_authoritative_source_count`: `26871` -> `26866`
- `xmage_authoritative_adapter_required_count`: `26871` -> `26866`
- `recursion::xmage_graveyard_return_variant_review_v1`: `1881` -> `1876`
- `battle_and_oracle_ready`: `2439` -> `2444`
- `battle_family_mapper_required`: `30108` -> `30103`
- `snapshot_has_verified_rule`: `3587` -> `3592`

## Runtime Evidence

- focused splitter suite: `215` tests passing
- focused runtime suite: `130` tests passing
- `python3 -m py_compile` passed for splitter, runtime, and focused tests
- E2E validation passed PostgreSQL source of truth, SQLite Hermes cache,
  canonical snapshot fallback, runtime `get_card_effect`, and battle execution
  no-override for all `5` cards.
