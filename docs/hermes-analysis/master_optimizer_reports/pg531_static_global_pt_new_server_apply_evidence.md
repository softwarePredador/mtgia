# PG531 Static Global P/T Apply Evidence

- Deploy ID: `PG531`
- Slug: `static_global_pt_new_server`
- PostgreSQL target: `143.198.230.247:5433/halder`
- Applied rows: `18`
- Deprecated shadow rows: `0`
- Postcheck: `18/18` promoted rows verified with matching oracle hash.
- PostgreSQL -> SQLite sync: `18` PG rows loaded, `18` SQLite rows inserted/updated.
- Canonical snapshot rows after sync: `6146`
- E2E package validation: `pass`
- E2E battle execution: `18` scenarios, `19` events.
- Final exact-scope recheck: `proposal_count=0`, `safe_for_batch_pg_package_count=0`.

Applied cards:

- `Anaba Spirit Crafter`
- `Bad Moon`
- `Blade Sliver`
- `Bonesplitter Sliver`
- `Dampening Pulse`
- `Dread of Night`
- `Earth Surge`
- `Illness in the Ranks`
- `Kaervek, the Spiteful`
- `Might Sliver`
- `Muscle Sliver`
- `Night of Souls' Betrayal`
- `Plated Sliver`
- `Sinew Sliver`
- `Stronghold Taskmaster`
- `Urborg Shambler`
- `Virulent Plague`
- `Watcher Sliver`

Validation artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg531_static_global_pt_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg531_static_global_pt_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg531_static_global_pt_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg531_static_global_pt_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg531_static_global_pt_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg531_static_global_pt_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg531_static_global_pt_new_server_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg531_static_global_pt_new_server_recheck.md`
