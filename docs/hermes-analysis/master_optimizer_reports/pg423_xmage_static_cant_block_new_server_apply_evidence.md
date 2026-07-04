# PG423 XMage Static Cant-Block Apply Evidence

Generated: 2026-07-04

Database target: `127.0.0.1:15432/halder`

Package: `pg423_xmage_static_cant_block_new_server`

## Scope

- Family: `xmage_static_self_cant_block_creature`
- Battle model scope: `xmage_static_self_cant_block_creature_v1`
- Selected cards: `13`
- XMage unit:
  `xmage_signature::no_effect_class::CantBlockAbility::no_target_class::no_condition_class::no_signal`

## PostgreSQL Apply Result

- Precheck: `13` target rows, `0` existing rule rows, `0` expected rows before apply, `0` shadow rows to deprecate.
- Apply: `upserted_rows=13`, `deprecated_shadow_rows=0`.
- Postcheck: `13/13` promoted rows, `13/13` `verified` + `auto`, `13/13` with `oracle_hash`.

## Sync Result

- Metadata sync: PostgreSQL rows matched `6591`; SQLite cache alias rows `6518`; `deck_cards` matched `2699/2699`; `card_id_updates=96`; unresolved aliases `1`.
- PG to SQLite rule sync: `pg_rows_loaded=13`, `sqlite_inserted_or_updated=13`, canonical snapshot rows exported `5608`.

## Validation Result

- Focused unit tests: `701` tests passed.
- Package E2E: status `pass`; PostgreSQL, SQLite, canonical snapshot, and runtime `get_card_effect` validated `13/13`.
- XMage strategy audit: `26/26` pass.
- Operational surface audit: pass.
- Legacy contamination audit: pass.
- PG/Hermes/SQLite contract audit: `51/51` pass.
- Post-PG423 exact split recheck: `proposal_count=0`.
- Post-PG423 queue: `target_identity_count=26416`, `xmage_authoritative_adapter_required_count=26102`, `adapter_work_unit_count=11413`.
