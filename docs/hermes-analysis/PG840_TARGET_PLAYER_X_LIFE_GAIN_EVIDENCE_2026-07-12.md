# PG840 Target Player X Life Gain Evidence - 2026-07-12

Status: `applied_synced_validated`.

## Scope

- Card promoted: `Stream of Life`
- XMage source: local `StreamOfLife` class
- Runtime scope: `xmage_fixed_target_player_gain_life_spell_v1`
- Dynamic field: `life_gain_amount_source = x_value`
- PostgreSQL target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`

## Runtime Changes

- `xmage_authoritative_exact_scope_split.py` now accepts exact
  `Target player gains X life.` when XMage source has
  `GainLifeTargetEffect(GetXValue.instance)` or
  `GainLifeTargetEffect(ManacostVariableValue.instance)`.
- The package builder now creates a focused E2E scenario with `x_value = 5`.
- The E2E runner now passes `x_value` into the effect and verifies
  `life_gain_amount_source = x_value` in the replay event.

## PostgreSQL Apply

- Precheck:
  - target card rows: `1`
  - existing rule rows: `0`
  - expected rule rows before: `0`
  - shadow rows to deprecate: `0`
- Apply:
  - backup rows: `0`
  - deprecated shadow rows: `0`
  - upserted rows: `1`
- Postcheck:
  - promoted rule rows: `1`
  - promoted verified auto rows: `1`
  - promoted oracle hash rows: `1`

## Sync And E2E

- PG -> SQLite sync:
  - selected card count: `1`
  - PostgreSQL rows loaded: `1`
  - SQLite inserted/updated: `1`
  - canonical snapshot rows exported locally: `6708`
- PG metadata -> Hermes sync:
  - requested unique names: `7655`
  - PostgreSQL cards matched: `7838`
  - SQLite cache alias rows: `7760`
  - deck card ids matched: `2699/2699`
- E2E validation:
  - status: `pass`
  - stages passed: PostgreSQL, SQLite/Hermes cache, canonical snapshot,
    runtime lookup, battle execution
  - battle result: `Stream of Life` gained `5` life with `x_value = 5`

## Global Recheck

- `battle_and_oracle_ready`: `6726`
- `battle_family_mapper_required`: `27068`
- Commander-legal XMage queue:
  - target identities: `24157`
  - XMage authoritative source count: `23844`
  - missing XMage source exceptions: `313`
  - parser gaps: `0`
- Exact-scope recheck after PG840:
  - proposal count: `0`
  - safe package count: `0`

## Audits

- XMage strategy consistency: `pass` (`26/26`)
- Operational surface alignment: `pass`
- Legacy contamination: `pass`
- PG/Hermes/SQLite contract: `pass` (`51/51`)

## Artifacts

- Package: `docs/hermes-analysis/master_optimizer_reports/pg840_target_player_x_life_gain_new_server_package.md`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg840_target_player_x_life_gain_new_server_manifest.json`
- E2E: `docs/hermes-analysis/master_optimizer_reports/pg840_target_player_x_life_gain_new_server_e2e_validation.json`
- Readiness: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg840_target_player_x_life_gain_new_server.json`
- Queue JSON is intentionally local/ignored because it is about `38 MB`.
- Canonical snapshot JSON is intentionally local/ignored because it is about
  `6.3 MB`.
