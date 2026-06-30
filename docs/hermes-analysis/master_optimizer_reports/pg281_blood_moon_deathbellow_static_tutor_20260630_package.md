# PG281 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-30T13:40:29+00:00`
- Selected cards: `["Blood Moon", "Deathbellow War Cry"]`
- Families: `{"passive": 1, "tutor": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg281_blood_moon_deathbellow_static_tutor_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg281_blood_moon_deathbellow_static_tutor_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg281_blood_moon_deathbellow_static_tutor_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg281_blood_moon_deathbellow_static_tutor_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg281_blood_moon_deathbellow_static_tutor_20260630_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg281_blood_moon_deathbellow_static_tutor_20260630_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
