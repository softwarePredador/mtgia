# pg433 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T21:16:57+00:00`
- Selected cards: `["Arms Dealer", "Aven Archer", "Barrage Ogre", "Bear Trap", "Blazing Hellhound", "Crimson Manticore", "Cunning Sparkmage", "Dive Bomber", "Divebomber Griffin", "Fanatical Firebrand", "Fodder Cannon", "Heartwood Giant", "Hurler Cyclops", "Jeska, Warrior Adept", "Kamahl, Pit Fighter", "Magmaw", "Mawcor", "Orcish Bloodpainter", "Orcish Mechanics", "Orcish Vandal", "Sarpadian Simulacrum", "Scaldkin", "Scorched Rusalka", "Shivan Hellkite", "Skirsdag Cultist", "Skull Catapult", "Skyway Sniper", "Springjaw Trap", "Stinging Barrier", "Storm Spirit", "Tar Pitcher", "Thornwind Faeries", "Vulshok Sorcerer"]`
- Families: `{"xmage_permanent_simple_activated_damage": 33}`

Files:

- precheck: `../../master_optimizer_reports/pg433_xmage_permanent_activated_damage_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg433_xmage_permanent_activated_damage_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg433_xmage_permanent_activated_damage_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg433_xmage_permanent_activated_damage_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg433_xmage_permanent_activated_damage_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg433_xmage_permanent_activated_damage_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
