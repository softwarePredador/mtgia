# PG843 Target Player Discard Mill Evidence - 2026-07-12

Status: `applied_synced_validated`.

## Scope

- Cards promoted:
  - `Horrifying Revelation`
- XMage source: local class with `DiscardTargetEffect + MillCardsTargetEffect`
- Runtime scope: `xmage_fixed_target_player_discard_mill_spell_v1`
- PostgreSQL target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`

## Runtime/Mapper Change

The exact-scope splitter now maps the narrow target-player discard-then-mill
spell shape when Oracle and local XMage agree that one target player discards a
fixed count and then mills a fixed count. The battle composite resolver stores
the target selected by the discard component and passes that same player into
the mill component, preventing the two effects from drifting to different
targets.

## PostgreSQL Apply

- Precheck:
  - target card rows: `1`
  - expected rule rows before: `0`
- Apply:
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
  - canonical snapshot rows exported locally: `6715`
- PG metadata -> Hermes sync:
  - requested unique names: `7661`
  - PostgreSQL cards matched: `7844`
  - SQLite cache alias rows: `7766`
  - deck card ids matched: `2699/2699`
- E2E validation:
  - status: `pass`
  - scenario count: `1`
  - battle result: `Horrifying Revelation` discarded `1`, milled `1`, target
    player `Opponent`, order `discard_then_mill`

## PG843b Hash Backfill

The post-PG843 contract audit exposed trusted executable rows without
`oracle_hash` in the new PostgreSQL target. PG843b is a metadata-only backfill:

- Precheck:
  - trusted executable rows missing `oracle_hash`: `55`
  - rows with computable `cards.oracle_text` hash: `55`
  - uncomputable rows: `0`
- Apply:
  - `oracle_hash` rows backfilled: `55`
- Postcheck:
  - trusted executable rows still missing `oracle_hash`: `0`
  - backup rows: `55`
  - backfilled rows matching `md5(cards.oracle_text)`: `55`

## Global Recheck

- `battle_and_oracle_ready`: `6733`
- `battle_family_mapper_required`: `27061`
- `snapshot_has_verified_rule`: `6840`
- Commander-legal XMage queue:
  - target identities: `24150`
  - XMage authoritative source count: `23837`
  - missing XMage source exceptions: `313`
  - parser gaps: `0`
- Exact-scope recheck after PG843b:
  - proposal count: `0`
  - safe package count: `0`

## Audits

- XMage strategy consistency: `pass` (`26/26`)
- Operational surface alignment: `pass`
- Legacy contamination: `pass`
- PG/Hermes/SQLite contract after PG843b: `pass` (`51/51`)

## Artifacts

- Package: `docs/hermes-analysis/master_optimizer_reports/pg843_target_player_discard_mill_new_server_package.md`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg843_target_player_discard_mill_new_server_manifest.json`
- E2E: `docs/hermes-analysis/master_optimizer_reports/pg843_target_player_discard_mill_new_server_e2e_validation_after_hash_backfill.json`
- Readiness: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg843b_hash_backfill_new_server.json`
- Queue JSON is intentionally local/ignored because it is large.
- Canonical snapshot JSON is intentionally local/ignored because it is large.
