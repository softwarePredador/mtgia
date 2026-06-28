# pg_boros_reckoner_runtime_20260628 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-28T11:47:31+00:00`
- Selected cards: `["Boros Reckoner"]`
- Families: `{"targeted_interaction": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg_boros_reckoner_runtime_20260628_boros_reckoner_runtime_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg_boros_reckoner_runtime_20260628_boros_reckoner_runtime_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg_boros_reckoner_runtime_20260628_boros_reckoner_runtime_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg_boros_reckoner_runtime_20260628_boros_reckoner_runtime_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg_boros_reckoner_runtime_20260628_boros_reckoner_runtime_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg_boros_reckoner_runtime_20260628_boros_reckoner_runtime_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
