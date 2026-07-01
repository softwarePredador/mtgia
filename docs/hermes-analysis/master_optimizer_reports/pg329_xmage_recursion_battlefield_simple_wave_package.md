# PG329 XMage Batch PostgreSQL Package

Status: `applied_synced_validated`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T20:33:05+00:00`
- Selected cards: `["Ashen Powder", "Helping Hand", "Hymn of Rebirth"]`
- Families: `{"xmage_graveyard_to_battlefield_spell": 3}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_package.md`
- apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_pg_apply_evidence.md`
- PG -> Hermes/SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_pg_to_sqlite_sync.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_e2e_validation.md`

Apply result:

- Precheck: `3/3` target card rows, `0` existing matching rule rows, `0` shadow rows.
- Apply: `upserted_rows=3`, `deprecated_shadow_rows=0`, transaction `COMMIT`.
- Postcheck: `3/3` promoted rows, `3/3` verified/auto, `3/3` matching Oracle hash.
- Sync: `pg_rows_loaded=7217`, `sqlite_inserted_or_updated=7011`, canonical snapshot rows `4808`.
- E2E: `pass` for PostgreSQL, SQLite, canonical snapshot, and runtime `get_card_effect`.
