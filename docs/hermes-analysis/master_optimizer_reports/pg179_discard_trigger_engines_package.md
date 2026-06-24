# PG179 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T14:04:19+00:00`
- Selected cards: `["Feast of Sanity", "Geth's Grimoire", "Megrim"]`
- Families: `{"draw_engine": 1, "passive": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg179_discard_trigger_engines_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg179_discard_trigger_engines_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg179_discard_trigger_engines_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg179_discard_trigger_engines_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg179_discard_trigger_engines_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg179_discard_trigger_engines_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
