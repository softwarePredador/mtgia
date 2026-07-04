# PG408 Mana ETB Draw New Server Apply Evidence

- Generated UTC: `2026-07-04T14:05:43Z`
- Database target: `127.0.0.1:15432/halder`
- Package: `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_package_package.md`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_package_precheck.sql`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_package_apply.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_package_postcheck.sql`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_package_rollback.sql`

## Apply Result

- Deprecated shadow rows: `0`
- Upserted rows: `13`
- Postcheck rows: `13/13` promoted rule rows, `13/13` promoted verified/auto rows, `13/13` promoted Oracle-hash rows.
- Backup rows: `0`

## Selected Cards

- `Agent of Stromgald`
- `Arcum's Astrolabe`
- `Bog Initiate`
- `Energy Refractor`
- `Helionaut`
- `Llanowar Envoy`
- `Llanowar Visionary`
- `Nomadic Elf`
- `Orochi Leafcaller`
- `Prismite`
- `Prophetic Prism`
- `Signpost Scarecrow`
- `Viridian Acolyte`

## Post-Apply Validation

- PG -> SQLite sync: `pg_rows_loaded=13`, `sqlite_inserted_or_updated=13`, `canonical_snapshot_rows_exported=5358`.
- E2E: `pass` across PostgreSQL, SQLite, canonical snapshot, and runtime `get_card_effect` for all `13` selected cards.
- Focused tests: `test_xmage_authoritative_exact_scope_split.py` ran `402` tests OK; `test_xmage_exact_scope_runtime.py` ran `232` tests OK.
- Final audits after documentation update: XMage strategy `26/26`, operational surface `39/39`, legacy contamination `32/32`, PG/Hermes/SQLite contract `51/51`.
