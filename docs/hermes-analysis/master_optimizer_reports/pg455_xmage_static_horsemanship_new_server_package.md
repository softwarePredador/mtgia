# pg455 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T00:06:33+00:00`
- Selected cards: `["Barbarian General", "Lady Zhurong, Warrior Queen", "Lu Meng, Wu General", "Shu Cavalry", "Shu Elite Companions", "Wei Elite Companions", "Wei Scout", "Wei Strike Force", "Wu Elite Cavalry", "Wu Light Cavalry"]`
- Families: `{"xmage_static_self_horsemanship_creature": 10}`

Files:

- precheck: `../../master_optimizer_reports/pg455_xmage_static_horsemanship_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg455_xmage_static_horsemanship_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg455_xmage_static_horsemanship_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg455_xmage_static_horsemanship_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg455_xmage_static_horsemanship_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg455_xmage_static_horsemanship_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
