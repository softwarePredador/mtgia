# pg450 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T23:31:22+00:00`
- Selected cards: `["Altar's Reap", "Blood Divination", "Corrupted Conviction", "Costly Plunder", "Eviscerator's Insight", "Magmatic Insight", "Morbid Curiosity", "Skulltap", "Tormenting Voice", "Village Rites", "Vivisection", "Wild Guess"]`
- Families: `{"xmage_fixed_draw_spell": 12}`

Files:

- precheck: `../../master_optimizer_reports/pg450_xmage_fixed_draw_spell_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg450_xmage_fixed_draw_spell_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg450_xmage_fixed_draw_spell_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg450_xmage_fixed_draw_spell_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg450_xmage_fixed_draw_spell_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg450_xmage_fixed_draw_spell_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
