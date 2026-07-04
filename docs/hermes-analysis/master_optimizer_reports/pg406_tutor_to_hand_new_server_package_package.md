# PG406 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T13:03:04+00:00`
- Selected cards: `["Borderland Ranger", "Call the Gatewatch", "Cateran Summons", "Civic Wayfinder", "Daru Cavalier", "Deadeye Quartermaster", "Diabolic Tutor", "District Guide", "Eerie Procession", "Environmental Scientist", "Farfinder", "Gatecreeper Vine", "Goblin Matron", "Heliod's Pilgrim", "Howling Wolf", "Ignite the Beacon", "Merchant Scroll", "Nesting Wurm", "Open the Armory", "Plea for Guidance", "Ranger of Eos", "Rune-Scarred Demon", "Safewright Quest", "Sarkhan's Triumph", "Screaming Seahawk", "Seek the Horizon", "Skyshroud Sentinel", "Solve the Equation", "Squadron Hawk", "Sylvan Ranger", "Time of Need", "Totem-Guide Hartebeest", "Transit Mage", "Trapmaker's Snare", "Tribute Mage"]`
- Families: `{"xmage_creature_etb_library_search_to_hand": 21, "xmage_library_search_spell": 14}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg406_tutor_to_hand_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg406_tutor_to_hand_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg406_tutor_to_hand_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg406_tutor_to_hand_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg406_tutor_to_hand_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg406_tutor_to_hand_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
