# PG421 XMage Static Flying Block-Only-Flying Apply Evidence

Generated: 2026-07-04

Database target: `127.0.0.1:15432/halder`

Package: `pg421_xmage_static_flying_block_only_flying_new_server`

## Scope

- Family: `xmage_static_flying_can_block_only_flying_creature`
- Battle model scope: `xmage_static_flying_can_block_only_flying_creature_v1`
- Selected cards: `18`
- XMage unit:
  `xmage_signature::no_effect_class::CanBlockOnlyFlyingAbility,FlyingAbility::no_target_class::no_condition_class::no_signal`

## PostgreSQL Apply Result

- Precheck: `18` target rows, `0` existing rule rows, `0` expected rows before apply, `0` shadow rows to deprecate.
- Apply: `upserted_rows=18`, `deprecated_shadow_rows=0`.
- Postcheck: `18/18` promoted rows, `18/18` `verified` + `auto`, `18/18` with `oracle_hash`.

## Sync Result

- Metadata sync: PostgreSQL rows matched `6552`; SQLite cache alias rows `6479`; `deck_cards` matched `2699/2699`; `card_id_updates=105`; unresolved aliases `1`.
- PG to SQLite rule sync: `pg_rows_loaded=18`, `sqlite_inserted_or_updated=18`, canonical snapshot rows exported `5574`.

## Validation Result

- Focused unit tests: `690` tests passed.
- Package E2E: status `pass`; PostgreSQL, SQLite, canonical snapshot, and runtime `get_card_effect` validated `18/18`.
- XMage strategy audit: `26/26` pass.
- Operational surface audit: pass.
- Legacy contamination audit: pass.
- PG/Hermes/SQLite contract audit: `51/51` pass.
- Post-PG421 exact split recheck: `proposal_count=0`.
- Post-PG421 queue: `target_identity_count=26450`, `xmage_authoritative_adapter_required_count=26136`, `adapter_work_unit_count=11415`.
