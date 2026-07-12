# PG846 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-12T21:39:29+00:00`
- Selected cards: `["Clockwork Servant", "Orator of Ojutai", "Silkweaver Elite", "Skyship Buccaneer", "Storm Fleet Spy"]`
- Families: `{"xmage_creature_etb_conditional_draw_cards": 5}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg846_etb_context_draw_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
