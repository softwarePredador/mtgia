# PG842 Target Player Mill Draw Evidence - 2026-07-12

Status: `applied_synced_validated`.

## Scope

- Cards promoted:
  - `Pilfered Plans`
  - `Thassa's Bounty`
  - `Thought Scour`
  - `Weight of Memory`
- XMage source: local classes with `MillCardsTargetEffect + DrawCardSourceControllerEffect`
- Runtime scope: `xmage_fixed_target_player_mill_draw_spell_v1`
- PostgreSQL target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`

## Runtime/Mapper Change

The exact-scope splitter now maps fixed target-player mill plus controller draw
spells when Oracle and local XMage agree on target scope, mill count, draw
count, and resolution order. The battle composite resolver now supports
`mill_cards` components by reusing the existing target-player mill executor,
so the same `mill_resolved` event shape is used in simple and composite
runtime paths.

Preserved resolution orders:

- `Pilfered Plans`: `mill_then_draw`
- `Thought Scour`: `mill_then_draw`
- `Thassa's Bounty`: `draw_then_mill`
- `Weight of Memory`: `draw_then_mill`

## PostgreSQL Apply

- Precheck:
  - target card rows: `4`
  - expected rule rows before: `0`
  - shadow rows to deprecate: `2`
- Apply:
  - deprecated shadow rows: `2`
  - upserted rows: `4`
- Postcheck:
  - promoted rule rows: `4`
  - promoted verified auto rows: `4`
  - promoted oracle hash rows: `4`

## Sync And E2E

- PG -> SQLite sync:
  - selected card count: `4`
  - PostgreSQL rows loaded: `4`
  - SQLite inserted/updated: `4`
  - canonical snapshot rows exported locally: `6714`
- PG metadata -> Hermes sync:
  - requested unique names: `7660`
  - PostgreSQL cards matched: `7843`
  - SQLite cache alias rows: `7765`
  - deck card ids matched: `2699/2699`
- E2E validation:
  - status: `pass`
  - scenario count: `4`
  - battle results:
    - `Pilfered Plans`: milled `2`, drew `2`, order `mill_then_draw`
    - `Thassa's Bounty`: drew `3`, milled `3`, order `draw_then_mill`
    - `Thought Scour`: milled `2`, drew `1`, order `mill_then_draw`
    - `Weight of Memory`: drew `3`, milled `3`, order `draw_then_mill`

## Global Recheck

- `battle_and_oracle_ready`: `6732`
- `battle_family_mapper_required`: `27062`
- Commander-legal XMage queue:
  - target identities: `24151`
  - XMage authoritative source count: `23838`
  - missing XMage source exceptions: `313`
  - parser gaps: `0`
- Exact-scope recheck after PG842:
  - proposal count: `0`
  - safe package count: `0`

## Audits

- XMage strategy consistency: `pass` (`26/26`)
- Operational surface alignment: `pass`
- Legacy contamination: `pass`
- PG/Hermes/SQLite contract: `pass` (`51/51`)

## Artifacts

- Package: `docs/hermes-analysis/master_optimizer_reports/pg842_target_player_mill_draw_new_server_package.md`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg842_target_player_mill_draw_new_server_manifest.json`
- E2E: `docs/hermes-analysis/master_optimizer_reports/pg842_target_player_mill_draw_new_server_e2e_validation.json`
- Readiness: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg842_target_player_mill_draw_new_server.json`
- Queue JSON is intentionally local/ignored because it is about `38 MB`.
- Canonical snapshot JSON is intentionally local/ignored because it is about
  `6.3 MB`.
