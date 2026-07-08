# PG664 Counter Oracle Auxiliary/X/Modal Apply Evidence

- Package: `pg664_counter_oracle_auxiliary_x_modal_new_server`
- Database target: `127.0.0.1:15432/halder`
- Cards: `Broken Concentration`, `Change the Equation`, `Fervent Denial`,
  `Neutralize`, `Overwhelming Denial`, `Spell Blast`

## Apply Sequence

1. Precheck:
   - target rows: `6`
   - existing expected rule rows before apply: `0`
   - stale generated shadow rows to deprecate: `0`
2. Apply:
   - upserted promoted rows: `6`
   - deprecated shadow rows: `0`
3. Postcheck:
   - promoted rule rows: `6/6`
   - promoted `verified/auto` rows: `6/6`
   - promoted rows with `oracle_hash`: `6/6`
   - backup rows: `0`

## Runtime/Sync Validation

- Focused unit tests:
  - `test_xmage_authoritative_exact_scope_split`
  - `test_xmage_exact_scope_runtime`
  - `test_xmage_batch_pg_package_builder`
- First package sync inserted/updated `6` SQLite rows from PostgreSQL.
- Post-hash-backfill full sync loaded `9629` PostgreSQL rows, inserted/updated
  `9392` SQLite rows, and exported `7063` canonical snapshot rows.
- Package E2E status: `pass`, with `6` battle-execution scenarios.

## Final Gates

- `xmage_strategy_consistency_audit`: `26/26` pass
- `pg_hermes_sqlite_contract_audit`: `51/51` pass
- `operational_surface_alignment_audit`: `pass`
- `legacy_contamination_audit`: `pass`
