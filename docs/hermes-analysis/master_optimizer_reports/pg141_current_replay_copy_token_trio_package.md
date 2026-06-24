# PG141 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T03:58:57+00:00`
- Selected cards: `["Flash Photography", "Astral Dragon", "Clone Legion"]`
- Families: `{"copy_creature_token": 2, "creature": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg141_current_replay_copy_token_trio_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg141_current_replay_copy_token_trio_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg141_current_replay_copy_token_trio_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg141_current_replay_copy_token_trio_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg141_current_replay_copy_token_trio_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg141_current_replay_copy_token_trio_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
