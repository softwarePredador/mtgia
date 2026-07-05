# pg476 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T02:59:48+00:00`
- Selected cards: `["Blaze", "Heat Ray", "Volcanic Geyser"]`
- Families: `{"xmage_x_damage_spell": 3}`

Files:

- precheck: `../../master_optimizer_reports/pg476_xmage_x_damage_spell_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg476_xmage_x_damage_spell_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg476_xmage_x_damage_spell_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg476_xmage_x_damage_spell_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg476_xmage_x_damage_spell_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg476_xmage_x_damage_spell_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
