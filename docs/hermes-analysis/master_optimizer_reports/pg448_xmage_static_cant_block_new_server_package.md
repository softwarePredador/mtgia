# pg448 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T23:13:57+00:00`
- Selected cards: `["Ashenmoor Gouger", "Craven Giant", "Craven Knight", "Goblin Raider", "Hulking Cyclops", "Hulking Goblin", "Hulking Ogre", "Jungle Lion", "Ogre Taskmaster", "Scavenging Scarab", "Spineless Thug", "Yellow Scarves Troops", "Young Wei Recruits"]`
- Families: `{"xmage_static_self_cant_block_creature": 13}`

Files:

- precheck: `../../master_optimizer_reports/pg448_xmage_static_cant_block_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg448_xmage_static_cant_block_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg448_xmage_static_cant_block_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg448_xmage_static_cant_block_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg448_xmage_static_cant_block_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg448_xmage_static_cant_block_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
