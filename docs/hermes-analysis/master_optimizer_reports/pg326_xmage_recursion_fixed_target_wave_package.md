# PG326 XMage Batch PostgreSQL Package

Status: `applied_synced_validated`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T19:56:45+00:00`
- Selected cards: `["Boggart Birth Rite", "Death's Duet", "Reborn Hope", "Revive"]`
- Families: `{"xmage_graveyard_to_hand_spell": 4}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_package.md`

Apply result:

- PostgreSQL precheck: `4/4` target rows found, `0` expected rows already present, `0` stale shadow rows.
- PostgreSQL apply: `upserted_rows=4`, `deprecated_shadow_rows=0`, `COMMIT`.
- PostgreSQL postcheck: `4/4` promoted rows, `4/4` verified/auto rows, `4/4` matching Oracle hash rows, `0` backup rows.
- PG -> Hermes/SQLite sync: `pg_rows_loaded=7202`, `sqlite_inserted_or_updated=6996`, `canonical_snapshot_rows_exported=4793`.
- E2E validation: PostgreSQL, SQLite, canonical snapshot, runtime `get_card_effect`, and no-override package gate all pass.

Evidence:

- Apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_pg_apply_evidence.md`
- PG -> Hermes/SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_pg_to_sqlite_sync.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_e2e_validation.md`
