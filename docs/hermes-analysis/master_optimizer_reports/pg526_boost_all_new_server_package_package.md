# PG526 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T19:40:24+00:00`
- Selected cards: `["Cower in Fear", "Hell Swarm", "Hysterical Blindness", "Infest", "Languish", "Magnify", "Marsh Gas", "Nausea", "Rollick of Abandon", "Shrivel"]`
- Families: `{"xmage_boost_all_or_opponents_creatures_until_eot_spell": 10}`

Files:

- precheck: `../../master_optimizer_reports/pg526_boost_all_new_server_package_precheck.sql`
- apply: `../../master_optimizer_reports/pg526_boost_all_new_server_package_apply.sql`
- rollback: `../../master_optimizer_reports/pg526_boost_all_new_server_package_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg526_boost_all_new_server_package_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg526_boost_all_new_server_package_manifest.json`
- package: `../../master_optimizer_reports/pg526_boost_all_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
