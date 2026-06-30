# PG279 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-30T12:20:43+00:00`
- Selected cards: `["Possibility Storm"]`
- Families: `{"free_cast": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg279_possibility_storm_shared_type_free_cast_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg279_possibility_storm_shared_type_free_cast_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg279_possibility_storm_shared_type_free_cast_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg279_possibility_storm_shared_type_free_cast_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg279_possibility_storm_shared_type_free_cast_20260630_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg279_possibility_storm_shared_type_free_cast_20260630_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
