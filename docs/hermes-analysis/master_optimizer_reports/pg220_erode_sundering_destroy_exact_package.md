# PG220 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-26T03:00:46+00:00`
- Selected cards: `["Erode", "Sundering Eruption // Volcanic Fissure"]`
- Families: `{"targeted_interaction": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg220_erode_sundering_destroy_exact_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg220_erode_sundering_destroy_exact_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg220_erode_sundering_destroy_exact_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg220_erode_sundering_destroy_exact_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg220_erode_sundering_destroy_exact_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg220_erode_sundering_destroy_exact_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
