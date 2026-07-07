# PG590 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-07T03:40:04+00:00`
- Selected cards: `["Augur of Bolas", "Courageous Outrider", "Eclipsed Boggart", "Eclipsed Elf", "Eclipsed Flamekin", "Eclipsed Kithkin", "Eclipsed Merrow", "Sea Gate Oracle", "Skalla Wolf", "Staunch Crewmate", "Sumala Woodshaper"]`
- Families: `{"xmage_creature_etb_look_library_pick_to_hand_rest_bottom": 11}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg590_creature_etb_library_pick_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg590_creature_etb_library_pick_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg590_creature_etb_library_pick_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg590_creature_etb_library_pick_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg590_creature_etb_library_pick_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg590_creature_etb_library_pick_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
