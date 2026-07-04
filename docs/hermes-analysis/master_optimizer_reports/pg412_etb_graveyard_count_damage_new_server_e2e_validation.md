# PG412 E2E Validation

Status: `pass`.

Focused tests:

- `test_xmage_authoritative_exact_scope_split.py`: 415 tests passed.
- `test_xmage_exact_scope_runtime.py`: 240 tests passed.
- `test_xmage_batch_pg_package_builder.py` + `test_sync_battle_card_rules_pg_selection.py`: 19 tests passed. Existing SQLite `ResourceWarning` messages appeared, but no failures.

Audits:

- XMage strategy consistency: 26/26 pass.
- Operational surface alignment: pass.
- PG/Hermes/SQLite contract: 51/51 pass.
- Legacy contamination: pass.
- Global card Oracle/battle readiness: `action_required`, expected because the all-card queue remains open after this 4-card package.

Direct validation:

- PostgreSQL and SQLite both contain the 4 PG412 rows as `verified` / `auto`.
- All 4 rows use `battle_model_scope=xmage_creature_etb_dynamic_graveyard_count_damage_v1`.
- All 4 rows set `etb_dynamic_damage=true` and `damage_amount_source=graveyard_card_count`.
