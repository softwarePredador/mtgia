# PG163 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T10:20:23+00:00`
- Selected cards: `["Final Fortune", "Last Chance"]`
- Families: `{"extra_turn_spell": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg163_extra_turn_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg163_extra_turn_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg163_extra_turn_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg163_extra_turn_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg163_extra_turn_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg163_extra_turn_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
