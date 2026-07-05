# PG537 Conditional ETB Treasure Apply Evidence

- Applied at: `2026-07-05T23:55Z`
- Package: `pg537_etb_treasure_condition_new_server`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Precheck

The precheck found `1` target card with `1` existing executable row from the
first PG537 apply attempt and `0` shadow rows to deprecate.

Target card:

- `Ticket Tortoise`

## Apply

- Deprecated shadow rows: `0`
- Upserted rows: `1`

## Postcheck

The postcheck returned `1` promoted rule row for `Ticket Tortoise` with:

- `review_status=verified`
- `execution_status=auto`
- non-empty `oracle_hash`
- `battle_model_scope=xmage_creature_etb_create_treasure_v1`
- `etb_treasure_condition=opponent_controls_more_lands`
- `xmage_token_class=TreasureToken`

## Follow-Up Evidence

- PG -> SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg537_etb_treasure_condition_new_server_pg_to_sqlite_sync.json`
- Battle package E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg537_etb_treasure_condition_new_server_e2e_validation.md`
