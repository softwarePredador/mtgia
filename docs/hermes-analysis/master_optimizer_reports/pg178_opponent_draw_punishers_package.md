# PG178 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T13:48:52+00:00`
- Selected cards: `["Fate Unraveler", "Underworld Dreams"]`
- Families: `{"creature": 1, "passive": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg178_opponent_draw_punishers_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg178_opponent_draw_punishers_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg178_opponent_draw_punishers_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg178_opponent_draw_punishers_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg178_opponent_draw_punishers_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg178_opponent_draw_punishers_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
