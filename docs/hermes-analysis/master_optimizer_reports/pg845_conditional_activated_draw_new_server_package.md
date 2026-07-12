# PG845 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-12T21:13:31+00:00`
- Selected cards: `["Endless Atlas", "Falkenrath Pit Fighter", "Fool's Tome", "Ragamuffyn", "Tapestry of the Ages"]`
- Families: `{"xmage_permanent_simple_activated_draw": 5}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg845_conditional_activated_draw_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg845_conditional_activated_draw_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg845_conditional_activated_draw_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg845_conditional_activated_draw_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg845_conditional_activated_draw_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg845_conditional_activated_draw_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
