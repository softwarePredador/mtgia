# PG191 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T21:57:39+00:00`
- Selected cards: `["Invoke Calamity"]`
- Families: `{"free_cast": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg191_invoke_calamity_free_cast_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg191_invoke_calamity_free_cast_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg191_invoke_calamity_free_cast_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg191_invoke_calamity_free_cast_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg191_invoke_calamity_free_cast_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg191_invoke_calamity_free_cast_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
