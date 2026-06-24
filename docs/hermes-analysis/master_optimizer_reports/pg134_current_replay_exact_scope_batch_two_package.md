# PG134 XMage Batch PostgreSQL Package

Status: `applied_postchecked_synced_validated`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T01:14:53+00:00`
- Selected cards: `["Archdruid's Charm", "Sink into Stupor", "Ruthless Technomancer", "Emperor of Bones", "Disciple of Freyalise", "Vibrance"]`
- Families: `{"manual_model": 5, "targeted_interaction": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg134_current_replay_exact_scope_batch_two_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg134_current_replay_exact_scope_batch_two_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg134_current_replay_exact_scope_batch_two_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg134_current_replay_exact_scope_batch_two_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg134_current_replay_exact_scope_batch_two_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg134_current_replay_exact_scope_batch_two_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
