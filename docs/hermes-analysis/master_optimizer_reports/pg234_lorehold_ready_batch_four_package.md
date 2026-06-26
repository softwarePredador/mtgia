# PG234 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-26T08:22:57+00:00`
- Selected cards: `["Galvanoth", "Velomachus Lorehold", "Palant\u00edr of Orthanc", "Scholar of New Horizons"]`
- Families: `{"creature": 3, "draw_engine": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg234_lorehold_ready_batch_four_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg234_lorehold_ready_batch_four_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg234_lorehold_ready_batch_four_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg234_lorehold_ready_batch_four_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg234_lorehold_ready_batch_four_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg234_lorehold_ready_batch_four_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
