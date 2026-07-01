# PG327 XMage Batch PostgreSQL Package

Status: `applied_synced_validated`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T20:08:12+00:00`
- Selected cards: `["Aid the Fallen", "Fortuitous Find", "Grim Discovery", "Remember the Fallen", "Reviving Melody", "Season of Renewal", "Survivors' Bond"]`
- Families: `{"xmage_graveyard_to_hand_choose_one_or_both_spell": 7}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_package.md`

Apply result:

- PostgreSQL precheck: `7/7` target rows found, `0` expected rows already present, `0` stale shadow rows.
- PostgreSQL apply: `upserted_rows=7`, `deprecated_shadow_rows=0`, `COMMIT`.
- PostgreSQL postcheck: `7/7` promoted rows, `7/7` verified/auto rows, `7/7` matching Oracle hash rows, `0` backup rows.
- PG -> Hermes/SQLite sync: `pg_rows_loaded=7209`, `sqlite_inserted_or_updated=7003`, `canonical_snapshot_rows_exported=4800`.
- E2E validation: PostgreSQL, SQLite, canonical snapshot, runtime `get_card_effect`, and no-override package gate all pass.

Evidence:

- Apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_pg_apply_evidence.md`
- PG -> Hermes/SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_pg_to_sqlite_sync.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_e2e_validation.md`
