# pg474 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T02:37:56+00:00`
- Selected cards: `["Arcum's Astrolabe", "Energy Refractor", "Llanowar Visionary", "Prophetic Prism"]`
- Families: `{"xmage_simple_mana_source_with_etb_draw": 4}`

Files:

- precheck: `../../master_optimizer_reports/pg474_xmage_simple_mana_source_with_etb_draw_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg474_xmage_simple_mana_source_with_etb_draw_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg474_xmage_simple_mana_source_with_etb_draw_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg474_xmage_simple_mana_source_with_etb_draw_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg474_xmage_simple_mana_source_with_etb_draw_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg474_xmage_simple_mana_source_with_etb_draw_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
