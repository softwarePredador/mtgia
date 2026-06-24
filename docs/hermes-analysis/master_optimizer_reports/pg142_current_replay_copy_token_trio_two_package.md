# PG142 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T04:21:57+00:00`
- Selected cards: `["Jaxis, the Troublemaker", "Rionya, Fire Dancer", "The Jolly Balloon Man"]`
- Families: `{"copy_creature_token": 3}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg142_current_replay_copy_token_trio_two_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg142_current_replay_copy_token_trio_two_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg142_current_replay_copy_token_trio_two_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg142_current_replay_copy_token_trio_two_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg142_current_replay_copy_token_trio_two_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg142_current_replay_copy_token_trio_two_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
