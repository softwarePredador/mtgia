# PG121 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-23T22:59:53+00:00`
- Selected cards: `["Training Grounds", "Biomancer's Familiar"]`
- Families: `{"static_cost_reducer": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg121_activated_creature_cost_reducer_restore_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg121_activated_creature_cost_reducer_restore_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg121_activated_creature_cost_reducer_restore_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg121_activated_creature_cost_reducer_restore_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg121_activated_creature_cost_reducer_restore_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg121_activated_creature_cost_reducer_restore_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
