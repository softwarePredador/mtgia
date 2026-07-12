# pg802 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-12T02:59:51+00:00`
- Selected cards: `["All That Glitters", "Ancestral Mask", "Blackblade Reforged", "Blessing of the Nephilim", "Civic Saber", "Empyrial Armor", "Empyrial Plate", "Glaive of the Guildpact", "Golem-Skin Gauntlets", "Granite Grip", "Helm of the Gods", "Kagemaro's Clutch", "Manaforce Mace", "Nightmare Lash", "Pennon Blade", "Quag Sickness", "Ravager's Mace"]`
- Families: `{"xmage_aura_static_power_toughness_attachment": 7, "xmage_equipment_static_power_toughness_attachment": 10}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg802_dynamic_attachment_static_pt_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg802_dynamic_attachment_static_pt_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg802_dynamic_attachment_static_pt_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg802_dynamic_attachment_static_pt_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg802_dynamic_attachment_static_pt_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg802_dynamic_attachment_static_pt_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
