# pg443 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T22:36:07+00:00`
- Selected cards: `["Abzan Banner", "Azorius Cluestone", "Boros Cluestone", "Dimir Cluestone", "Golgari Cluestone", "Gruul Cluestone", "Heart Warden", "Izzet Cluestone", "Jeskai Banner", "Letter of Acceptance", "Mardu Banner", "Orzhov Cluestone", "Rakdos Cluestone", "Selesnya Cluestone", "Simic Cluestone", "Sultai Banner", "Temur Banner"]`
- Families: `{"xmage_simple_mana_source_with_activated_draw": 17}`

Files:

- precheck: `../../master_optimizer_reports/pg443_xmage_mana_source_activated_draw_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg443_xmage_mana_source_activated_draw_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg443_xmage_mana_source_activated_draw_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg443_xmage_mana_source_activated_draw_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg443_xmage_mana_source_activated_draw_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg443_xmage_mana_source_activated_draw_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
