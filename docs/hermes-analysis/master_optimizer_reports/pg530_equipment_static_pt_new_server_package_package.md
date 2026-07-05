# PG530 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T20:56:35+00:00`
- Selected cards: `["Accorder's Shield", "Aeronaut's Wings", "Barbed Battlegear", "Behemoth Sledge", "Bone Saw", "Bonesplitter", "Brawler's Plate", "Bronze Sword", "Cathar's Shield", "Ceremonial Groundbreaker", "Chitinous Cloak", "Crystal Slipper", "Cultist's Staff", "D\u00fanedain Blade", "Gorgon Flail", "Greataxe", "Greatsword", "Honed Khopesh", "Kite Shield", "Kitesail", "Kor Halberd", "Leonin Scimitar", "Loxodon Warhammer", "Marauder's Axe", "Mask of Avacyn", "No-Dachi", "Ogre's Cleaver", "Riot Gear", "Short Bow", "Short Sword", "Shuko", "Slagwurm Armor", "Spidersilk Net", "Steelclaw Lance", "Strider Harness", "Sword of Vengeance", "Team Pennant", "Thinking Cap", "Torch Gauntlet", "Trusty Machete", "Vanquisher's Axe", "Veteran's Powerblade", "Veteran's Sidearm", "Viridian Claw", "Vulshok Battlegear", "Vulshok Morningstar", "Warlord's Axe"]`
- Families: `{"xmage_equipment_static_power_toughness_attachment": 47}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg530_equipment_static_pt_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg530_equipment_static_pt_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg530_equipment_static_pt_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg530_equipment_static_pt_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg530_equipment_static_pt_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg530_equipment_static_pt_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
