# Storm-Kiln Artist PG Sync Dry Run

- generated_at: `2026-06-30T17:04:13Z`
- command:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --skip-generated --only-card "Storm-Kiln Artist" --report docs/hermes-analysis/master_optimizer_reports/storm_kiln_pg_sync_dry_run_20260630.json`
- database_target: `unknown-host:5432/unknown-db`
- selected_cards: `Storm-Kiln Artist`
- selected_card_count: `1`
- input_rows: `1`
- curated_rows: `1`
- manual_rows: `0`
- generated_rows: `0`
- apply_pg: `false`
- apply_sqlite_from_pg: `false`
- pg_inserted_or_updated: `0`
- pg_rows_loaded: `0`
- sqlite_inserted_or_updated: `0`

## Decision

The sync planner selected the reviewed `Storm-Kiln Artist` runtime row exactly
once, but no durable write was executed because no PostgreSQL target was
configured in the local shell. Treat the runtime code and reviewed JSON as
validated local/package-gate evidence, not yet as globally synced PostgreSQL
truth.
