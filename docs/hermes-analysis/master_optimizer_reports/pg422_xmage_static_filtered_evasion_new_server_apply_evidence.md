# PG422 XMage Static Filtered Evasion Apply Evidence

Generated: 2026-07-04

Database target: `127.0.0.1:15432/halder`

Package: `pg422_xmage_static_filtered_evasion_new_server`

## Scope

- Family: `xmage_static_filtered_evasion_creature`
- Battle model scope: `xmage_static_filtered_evasion_creature_v1`
- Selected cards: `21`
- XMage unit:
  `xmage_signature::CantBeBlockedByCreaturesSourceEffect::SimpleEvasionAbility::no_target_class::no_condition_class::no_signal`

## PostgreSQL Apply Result

- Precheck: `21` target rows, `0` existing rule rows, `0` expected rows before apply, `0` shadow rows to deprecate.
- Apply: `upserted_rows=21`, `deprecated_shadow_rows=0`.
- Postcheck: `21/21` promoted rows, `21/21` `verified` + `auto`, `21/21` with `oracle_hash`.

## Sync Result

- Metadata sync: PostgreSQL rows matched `6570`; SQLite cache alias rows `6497`; `deck_cards` matched `2699/2699`; `card_id_updates=108`; unresolved aliases `1`.
- PG to SQLite rule sync: `pg_rows_loaded=21`, `sqlite_inserted_or_updated=21`, canonical snapshot rows exported `5595`.

## Validation Result

- Focused unit tests: `698` tests passed.
- Package E2E: status `pass`; PostgreSQL, SQLite, canonical snapshot, and runtime `get_card_effect` validated `21/21`.
- XMage strategy audit: `26/26` pass.
- Operational surface audit: pass.
- Legacy contamination audit: pass.
- PG/Hermes/SQLite contract audit: `51/51` pass.
- Post-PG422 exact split recheck: `proposal_count=0`.
- Post-PG422 queue: `target_identity_count=26429`, `xmage_authoritative_adapter_required_count=26115`, `adapter_work_unit_count=11414`.
