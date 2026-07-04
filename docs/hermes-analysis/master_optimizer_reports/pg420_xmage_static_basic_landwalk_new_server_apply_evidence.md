# PG420 XMage Static Basic Landwalk Apply Evidence

Generated: 2026-07-04

Database target: `127.0.0.1:15432/halder`

Package: `pg420_xmage_static_basic_landwalk_new_server`

## Scope

- Family: `xmage_static_self_basic_landwalk_creature`
- Battle model scope: `xmage_static_self_basic_landwalk_creature_v1`
- Selected cards: `61`
- Breakdown:
  - `SwampwalkAbility`: `21`
  - `ForestwalkAbility`: `17`
  - `MountainwalkAbility`: `12`
  - `IslandwalkAbility`: `9`
  - `PlainswalkAbility`: `2`

## PostgreSQL Apply Result

- Precheck: `61` target rows, `0` existing rule rows, `0` expected rows before apply, `0` shadow rows to deprecate.
- Apply: `upserted_rows=61`, `deprecated_shadow_rows=0`.
- Postcheck: `61/61` promoted rows, `61/61` `verified` + `auto`, `61/61` with `oracle_hash`.

## Sync Result

- Metadata sync: PostgreSQL rows matched `6492`; SQLite cache alias rows `6419`; `deck_cards` matched `2699/2699`; unresolved aliases `1`.
- PG to SQLite rule sync: `pg_rows_loaded=61`, `sqlite_inserted_or_updated=61`, canonical snapshot rows exported `5556`.

## Validation Result

- Focused unit tests: `686` tests passed.
- Package E2E: status `pass`; PostgreSQL, SQLite, canonical snapshot, and runtime `get_card_effect` validated `61/61`.
- XMage strategy audit: `26/26` pass.
- Operational surface audit: pass.
- Legacy contamination audit: pass.
- PG/Hermes/SQLite contract audit after PG420b hash cleanup: `51/51` pass.
- Post-PG420 exact split recheck: `proposal_count=0`.
- Post-PG420 queue: `target_identity_count=26468`, `xmage_authoritative_adapter_required_count=26154`, `adapter_work_unit_count=11416`.

## PG420b Integrity Cleanup

- Trigger: PG/Hermes/SQLite contract audit found `44` trusted executable PostgreSQL rules missing `oracle_hash`.
- Precheck: `44` candidate rows, `44` computable hashes, `44` distinct rule keys.
- Apply: `updated_rows=44`.
- Postcheck: `backup_rows=44`, `restored_rows=44`, `remaining_missing_hash_rows=0`.
- PG to SQLite sync for affected cards: `selected_card_count=44`, `pg_rows_loaded=131`, `sqlite_inserted_or_updated=114`, canonical snapshot rows exported `5556`.
