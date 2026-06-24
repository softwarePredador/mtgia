# PG146 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T06:16:20+00:00`
- Selected cards: `["Patrol Signaler"]`
- Families: `{"creature": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg146_patrol_signaler_package_20260624_061615_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg146_patrol_signaler_package_20260624_061615_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg146_patrol_signaler_package_20260624_061615_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg146_patrol_signaler_package_20260624_061615_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg146_patrol_signaler_package_20260624_061615_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg146_patrol_signaler_package_20260624_061615_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
