# PG119 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-23T22:29:42+00:00`
- Selected cards: `["Fierce Guardianship", "Force of Will", "Mindbreak Trap", "Sevinne's Reclamation", "Abrupt Decay", "Counterspell", "Deadly Rollick", "Force of Vigor", "Laughing Mad", "Lightning Bolt", "Negate", "Snapback", "Thrill of Possibility", "Calamity of Cinders", "Gut Shot"]`
- Families: `{"board_wipe_choice": 1, "targeted_interaction": 14}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg119_current_replay_simple_runtime_batch_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg119_current_replay_simple_runtime_batch_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg119_current_replay_simple_runtime_batch_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg119_current_replay_simple_runtime_batch_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg119_current_replay_simple_runtime_batch_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg119_current_replay_simple_runtime_batch_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
