# PG841 Target Player Mill Neutral Auxiliary Evidence - 2026-07-12

Status: `applied_synced_validated`.

## Scope

- Cards promoted:
  - `Compelling Argument`
  - `Dream Twist`
- XMage source: local classes with `MillCardsTargetEffect`
- Runtime scope: `xmage_fixed_target_player_mill_spell_v1`
- Auxiliary abilities allowed in this batch:
  - `CyclingAbility`
  - `FlashbackAbility`
- PostgreSQL target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`

## Runtime/Mapper Change

The exact-scope splitter now treats globally neutral resolution abilities as
safe auxiliary classes for pure target-player mill spells. This reuses the
existing target-player mill runtime and E2E runner; it does not model cycling
or flashback activation as separate actions, only the normal spell resolution
when the spell is cast.

Blocked examples remain blocked:

- `Archive Trap`: `AlternativeCostSourceAbility`
- `Dampen Thought`: `SpliceAbility`
- `Memory Sluice`: `ConspireAbility`
- `Sweet Oblivion`: `EscapeAbility`
- Composite mill plus draw/life/discard/recursion effects

## PostgreSQL Apply

- Precheck:
  - target card rows: `2`
  - existing rule rows: `0`
  - expected rule rows before: `0`
  - shadow rows to deprecate: `0`
- Apply:
  - backup rows: `0`
  - deprecated shadow rows: `0`
  - upserted rows: `2`
- Postcheck:
  - promoted rule rows: `2`
  - promoted verified auto rows: `2`
  - promoted oracle hash rows: `2`

## Sync And E2E

- PG -> SQLite sync:
  - selected card count: `2`
  - PostgreSQL rows loaded: `2`
  - SQLite inserted/updated: `2`
  - canonical snapshot rows exported locally: `6710`
- PG metadata -> Hermes sync:
  - requested unique names: `7657`
  - PostgreSQL cards matched: `7840`
  - SQLite cache alias rows: `7762`
  - deck card ids matched: `2699/2699`
- E2E validation:
  - status: `pass`
  - stages passed: PostgreSQL, SQLite/Hermes cache, canonical snapshot,
    runtime lookup, battle execution
  - battle results:
    - `Compelling Argument`: opponent milled `5`
    - `Dream Twist`: opponent milled `3`

## Global Recheck

- `battle_and_oracle_ready`: `6728`
- `battle_family_mapper_required`: `27066`
- Commander-legal XMage queue:
  - target identities: `24155`
  - XMage authoritative source count: `23842`
  - missing XMage source exceptions: `313`
  - parser gaps: `0`
- Exact-scope recheck after PG841:
  - proposal count: `0`
  - safe package count: `0`

## Audits

- XMage strategy consistency: `pass` (`26/26`)
- Operational surface alignment: `pass`
- Legacy contamination: `pass`
- PG/Hermes/SQLite contract: `pass` (`51/51`)

## Artifacts

- Package: `docs/hermes-analysis/master_optimizer_reports/pg841_target_player_mill_neutral_aux_new_server_package.md`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg841_target_player_mill_neutral_aux_new_server_manifest.json`
- E2E: `docs/hermes-analysis/master_optimizer_reports/pg841_target_player_mill_neutral_aux_new_server_e2e_validation.json`
- Readiness: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg841_target_player_mill_neutral_aux_new_server.json`
- Queue JSON is intentionally local/ignored because it is about `38 MB`.
- Canonical snapshot JSON is intentionally local/ignored because it is about
  `6.3 MB`.
