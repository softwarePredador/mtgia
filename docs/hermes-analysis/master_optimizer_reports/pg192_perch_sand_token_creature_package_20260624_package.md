# PG192 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T22:15:36+00:00`
- Selected cards: `["Perch Protection", "Sand Scout"]`
- Families: `{"creature": 1, "token_maker": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg192_perch_sand_token_creature_package_20260624_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg192_perch_sand_token_creature_package_20260624_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg192_perch_sand_token_creature_package_20260624_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg192_perch_sand_token_creature_package_20260624_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg192_perch_sand_token_creature_package_20260624_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg192_perch_sand_token_creature_package_20260624_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
