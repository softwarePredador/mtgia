# PG190 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T21:39:39+00:00`
- Selected cards: `["Cool but Rude"]`
- Families: `{"draw_engine": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg190_cool_but_rude_class_rummage_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg190_cool_but_rude_class_rummage_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg190_cool_but_rude_class_rummage_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg190_cool_but_rude_class_rummage_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg190_cool_but_rude_class_rummage_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg190_cool_but_rude_class_rummage_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
