# PG536 ETB Treasure Apply Evidence

- Applied at: `2026-07-05T23:26Z`
- Package: `pg536_etb_treasure_new_server`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Precheck

The precheck found all `6` target cards, with `0` existing executable rows and
`0` shadow rows to deprecate.

Target cards:

- `Brazen Freebooter`
- `Plundering Pirate`
- `Prosperous Pirates`
- `Redcap Thief`
- `Sailor of Means`
- `Wily Goblin`

## Apply

- Deprecated shadow rows: `0`
- Upserted rows: `6`

## Postcheck

The postcheck returned `1` promoted rule row for each target card, all with:

- `review_status=verified`
- `execution_status=auto`
- non-empty `oracle_hash`
- `battle_model_scope=xmage_creature_etb_create_treasure_v1`

## Follow-Up Evidence

- PG -> SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg536_etb_treasure_new_server_pg_to_sqlite_sync.json`
- Battle package E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg536_etb_treasure_new_server_e2e_validation.md`
