# pg444 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T22:42:10+00:00`
- Selected cards: `["Bloodfire Mentor", "Captain of Umbar", "Dragonborn Looter", "Emmessi Tome", "Erratic Visionary", "Facet Reader", "Hapless Researcher", "Jalum Tome", "Magus of the Bazaar", "Merfolk Looter", "Research Assistant", "Soothsayer Adept", "Teferi's Protege", "Thought Courier", "Unfulfilled Desires"]`
- Families: `{"xmage_permanent_simple_activated_draw_discard": 15}`

Files:

- precheck: `../../master_optimizer_reports/pg444_xmage_activated_draw_discard_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg444_xmage_activated_draw_discard_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg444_xmage_activated_draw_discard_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg444_xmage_activated_draw_discard_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg444_xmage_activated_draw_discard_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg444_xmage_activated_draw_discard_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
