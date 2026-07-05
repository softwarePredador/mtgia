# PG530 Equipment Static PT New Server Apply Evidence

- deploy_id: `PG530`
- runtime_scope: `xmage_equipment_static_power_toughness_attachment_v1`
- database_target: `143.198.230.247:5433/halder`
- package_manifest: `docs/hermes-analysis/master_optimizer_reports/pg530_equipment_static_pt_new_server_package_manifest.json`
- precheck_rows: `47`
- deprecated_shadow_rows: `4`
- upserted_rows: `47`
- postcheck_rows: `47`
- postcheck_promoted_rule_rows: `47/47`
- postcheck_verified_auto_rows: `47/47`
- postcheck_oracle_hash_rows: `47/47`
- pg_rows_loaded_for_sqlite_sync: `47`
- sqlite_inserted_or_updated: `51`
- canonical_snapshot_rows_exported: `6128`
- e2e_status: `pass`
- post_apply_target_identity_count: `25882`
- post_apply_xmage_authoritative_source_count: `25568`
- post_apply_xmage_missing_source_exception_count: `314`
- post_apply_adapter_required_count: `25568`
- final_exact_scope_recheck_proposal_count: `0`
- final_exact_scope_recheck_safe_for_batch_pg_package_count: `0`

Validation:

- `python3 -m py_compile` passed for the exact-scope splitter, battle runtime,
  and registry changes.
- Focused unit suites passed for exact split and runtime coverage.
- PostgreSQL precheck/apply/postcheck completed without SQL errors.
- PostgreSQL -> Hermes/SQLite sync completed from PostgreSQL truth.
- Battle package end-to-end validation passed across PostgreSQL, SQLite,
  canonical snapshot fallback, runtime effect loading, and no-override battle
  execution checks.
- Strategy consistency, PostgreSQL/Hermes/SQLite contract, operational surface,
  and legacy contamination audits passed after sync.

Residual boundary:

PG530 authorizes only exact fixed Equipment attachment rows with supported static
power/toughness and keyword grants. Dynamic Equipment rows, unsupported granted
abilities, triggered/activated riders, reconfigure variants, and source/Oracle
mismatches remain blocked for later family work.
