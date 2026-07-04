# pg434 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T21:23:47+00:00`
- Selected cards: `["Ambush Viper", "Ashcoat Bear", "Aven Reedstalker", "Benalish Knight", "Bounding Wolf", "Cloaked Siren", "Crystacean", "Darksteel Sentinel", "Dawn's Light Archer", "Faerie Invaders", "Fire Nation Ambushers", "Galewind Moose", "Havenwood Wurm", "Hired Blade", "Hussar Patrol", "King Cheetah", "Living Tempest", "Merfolk of the Depths", "Nephalia Seakite", "Plumeveil", "Pouncing Cheetah", "Raging Kavu", "Riptide Turtle", "Sentinels of Glen Elendra", "Skyline Predator", "Spire Monitor", "Stormrider Spirit", "Swift Spinner", "Tangle Spider", "Vexing Gull", "Wind Strider", "Winged Coatl", "Zealous Guardian"]`
- Families: `{"xmage_static_self_combat_keyword_creature": 33}`

Files:

- precheck: `../../master_optimizer_reports/pg434_xmage_static_self_combat_keyword_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg434_xmage_static_self_combat_keyword_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg434_xmage_static_self_combat_keyword_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg434_xmage_static_self_combat_keyword_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg434_xmage_static_self_combat_keyword_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg434_xmage_static_self_combat_keyword_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
