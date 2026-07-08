# PG657 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-08T13:21:40+00:00`
- Selected cards: `["Abyssal Horror", "Black Cat", "Blazing Specter", "Brutal Nightstalker", "Corrupt Court Official", "Deadbridge Shaman", "Ebon Dragon", "Ravenous Rats", "Rottenheart Ghoul", "Sanity Gnawers"]`
- Families: `{"xmage_creature_combat_damage_target_player_discard": 1, "xmage_creature_dies_target_player_discard": 3, "xmage_creature_etb_target_player_discard": 6}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg657_target_player_discard_triggers_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg657_target_player_discard_triggers_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg657_target_player_discard_triggers_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg657_target_player_discard_triggers_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg657_target_player_discard_triggers_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg657_target_player_discard_triggers_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
