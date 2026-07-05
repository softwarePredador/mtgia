# PG527 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T20:00:27+00:00`
- Selected cards: `["Army of Allah", "Eyeblight Massacre", "Festergloom", "Hazardous Conditions", "Hold the Line", "Holy Light", "Morale", "Nocturnal Raid", "Rally", "Stench of Decay", "Trumpet Blast", "Valorous Charge"]`
- Families: `{"xmage_boost_filtered_creatures_until_eot_spell": 12}`

Files:

- precheck: `../../master_optimizer_reports/pg527_boost_all_filtered_new_server_package_precheck.sql`
- apply: `../../master_optimizer_reports/pg527_boost_all_filtered_new_server_package_apply.sql`
- rollback: `../../master_optimizer_reports/pg527_boost_all_filtered_new_server_package_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg527_boost_all_filtered_new_server_package_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg527_boost_all_filtered_new_server_package_manifest.json`
- package: `../../master_optimizer_reports/pg527_boost_all_filtered_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
