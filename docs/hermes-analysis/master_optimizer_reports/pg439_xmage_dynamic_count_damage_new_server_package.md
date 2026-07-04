# pg439 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T22:06:10+00:00`
- Selected cards: `["Armed Response", "Artillery Blast", "Divine Retribution", "Dogpile", "Earth Tremor", "Feedback Bolt", "Goblin War Strike", "Ground Assault", "Massive Raid", "Mob Justice", "Outflank", "Outnumber", "Rockslide Ambush", "Rumbling Rockslide", "Seismic Strike", "Spiraling Embers", "Spire Barrage", "Spitting Earth", "Stonefury", "Tribal Flames", "Welding Sparks"]`
- Families: `{"xmage_dynamic_count_damage_spell": 21}`

Files:

- precheck: `../../master_optimizer_reports/pg439_xmage_dynamic_count_damage_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg439_xmage_dynamic_count_damage_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg439_xmage_dynamic_count_damage_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg439_xmage_dynamic_count_damage_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg439_xmage_dynamic_count_damage_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg439_xmage_dynamic_count_damage_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
