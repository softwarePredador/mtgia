# PG505 XMage Batch PostgreSQL Package

Status: `applied_postcheck_synced_validated`.

This package was generated from XMage batch proposals. SQL execution was applied
after explicit authorization and validated by precheck, postcheck, PG -> SQLite
sync, focused runtime tests, battle suite, and contract audits.

- Generated at: `2026-07-05T12:23:44+00:00`
- Selected cards: `["Chandler", "Dwarven Demolition Team", "Dwarven Miner", "Fulminator Mage", "Goblin Replica", "Intrepid Hero", "Trench Wurm"]`
- Families: `{"xmage_permanent_simple_activated_destroy_target": 7}`

Files:

- precheck: `../../master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_manifest.json`
- package: `../../master_optimizer_reports/xmage_pg505_activated_destroy_target_parser_new_server_package.md`

Apply gate:

- Precheck: all 7 target cards had Oracle-hash matched rows and no existing
  same-scope rules.
- Apply: `deprecated_shadow_rows=0`, `upserted_rows=7`, `COMMIT`.
- Postcheck: all 7 rows have promoted rule, verified-auto, and Oracle hash
  match.
- PG -> SQLite sync:
  `xmage_pg505_activated_destroy_target_parser_new_server_pg_to_sqlite_sync.json`;
  `pg_rows_loaded=7`, `sqlite_inserted_or_updated=7`,
  `canonical_snapshot_rows_exported=5979`.
