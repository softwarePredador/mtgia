# PG597 Pay-Life Mana Source New Server Apply Evidence

Generated at: `2026-07-07T06:05:29Z`

## Scope

- Package: `PG597`
- Pattern: XMage authoritative simple mana sources with `PayLifeCost(1)`.
- Cards promoted: `Blightsoil Druid`, `Blood Celebrant`, `Phyrexian Lens`, `Standing Stones`, `Vesper Ghoul`.
- Explicitly blocked: `Haunted Screen`, because its mana modes have different life costs and the current ManaLoom model stores one activation life cost per source.
- PostgreSQL target: `127.0.0.1:15432/halder` via `./server/bin/with_new_server_pg.sh`.

## PostgreSQL Apply

- Precheck: 5/5 cards matched by `normalized_name + oracle_hash`.
- Existing expected rule rows before apply: 0/5.
- Shadow rows deprecated: 0.
- Apply result: 5 upserted rows.
- Postcheck: each promoted card has 1 rule row, 1 `verified/auto` row, and 1 matching `oracle_hash` row.
- Backup audit rows: 0, because no previous rows existed for these five names.

## Sync

- `sync_battle_card_rules_pg.py`: `sqlite_inserted_or_updated=9128`, `pg_rows_loaded=9364`, `database_target=127.0.0.1:15432/halder`.
- `sync_pg_card_metadata_to_hermes.py`: `postgres cards matched=7771`, `sqlite cache alias rows=7707`, `deck_cards backfill matched=2699/2699`.

## Runtime And E2E

- Splitter tests: `733` tests passed.
- Package builder tests: passed.
- Exact-scope runtime tests: `370` tests passed.
- E2E package validation: status `pass`.
- E2E battle scenarios: 5/5.
- E2E life payment evidence: all five scenarios paid `1` life and ended at life `39`.
- E2E stages passed: PostgreSQL source of truth, SQLite Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, battle execution.

## Post-PG597 Queue

- `target_identity_count`: `25177`.
- `xmage_authoritative_source_count`: `24863`.
- `xmage_missing_source_exception_count`: `314`.
- `xmage_authoritative_parser_gap_count`: `0`.
- `xmage_authoritative_adapter_required_count`: `24863`.
- `adapter_work_unit_count`: `11337`.
- Readiness `battle_and_oracle_ready`: `5773`.
- Post-split probe after PG597: `proposal_count=0`, `safe_for_batch_pg_package_count=0`.

## Governance Gates

- `xmage_strategy_consistency_audit`: pass, 26/26.
- `operational_surface_alignment_audit`: pass.
- `legacy_contamination_audit`: pass.
- `pg_hermes_sqlite_contract_audit`: pass, 51/51.
- `./scripts/quality_gate.sh server-target`: pass.
