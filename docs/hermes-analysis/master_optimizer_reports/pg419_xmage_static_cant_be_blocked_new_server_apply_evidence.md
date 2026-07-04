# PG419 XMage Static Can't-Be-Blocked Apply Evidence

Generated: 2026-07-04

Database target: `127.0.0.1:15432/halder`

Package: `pg419_xmage_static_cant_be_blocked_new_server`

## Scope

- Family: `xmage_static_self_cant_be_blocked_creature`
- Battle model scope: `xmage_static_self_cant_be_blocked_creature_v1`
- Selected cards: `11`
- Cards:
  - `Covert Operative`
  - `Jhessian Infiltrator`
  - `Latch Seeker`
  - `Metathran Soldier`
  - `Mist-Cloaked Herald`
  - `Phantom Ninja`
  - `Phantom Warrior`
  - `Slither Blade`
  - `Talas Warrior`
  - `Tidal Kraken`
  - `Triton Shorestalker`

## PostgreSQL Apply Result

- Precheck: `11` target rows, `0` existing rule rows, `0` expected rows before apply, `0` shadow rows to deprecate.
- Apply: `upserted_rows=11`, `deprecated_shadow_rows=0`.
- Postcheck: `11/11` promoted rows, `11/11` `verified` + `auto`, `11/11` with `oracle_hash`.

## Sync Result

- Metadata sync: PostgreSQL rows matched `6482`; SQLite cache alias rows `6409`; `deck_cards` matched `2699/2699`; unresolved aliases `1`.
- PG to SQLite rule sync: `pg_rows_loaded=11`, `sqlite_inserted_or_updated=11`, canonical snapshot rows exported `5495`.

## Validation Result

- Focused unit tests: `682` tests passed.
- Package E2E: status `pass`; PostgreSQL, SQLite, canonical snapshot, and runtime `get_card_effect` validated `11/11`.
- XMage strategy audit: `26/26` pass.
- Operational surface audit: pass.
- Legacy contamination audit: pass.
- PG/Hermes/SQLite contract audit: `51/51` pass.
- Post-PG419 exact split recheck: `proposal_count=0`.
- Post-PG419 queue: `target_identity_count=26529`, `xmage_authoritative_adapter_required_count=26215`, `adapter_work_unit_count=11421`.
