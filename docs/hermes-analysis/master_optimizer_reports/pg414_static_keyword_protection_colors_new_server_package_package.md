# PG414 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T16:12:46+00:00`
- Selected cards: `["Abbey Gargoyles", "Akroma, Angel of Wrath", "Aven Smokeweaver", "Black Knight", "Blood Knight", "Cemetery Gate", "Cerulean Wyvern", "Coast Watcher", "Duskrider Falcon", "Freewind Falcon", "Hazerider Drake", "Iridescent Angel", "Melesse Spirit", "Mirran Crusader", "Narwhal", "Nightwind Glider", "Paladin en-Vec", "Sabertooth Nishoba", "Sea Sprite", "Silver Knight", "Sphinx of the Steel Wind", "Thermal Glider", "Treetop Sentinel", "Voice of Duty", "Voice of Grace", "Voice of Law", "Voice of Reason", "Voice of Truth", "Wall of Light", "Weatherseed Faeries", "White Knight", "Windreaper Falcon"]`
- Families: `{"xmage_static_self_protection_from_colors_creature": 32}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg414_static_keyword_protection_colors_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg414_static_keyword_protection_colors_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg414_static_keyword_protection_colors_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg414_static_keyword_protection_colors_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg414_static_keyword_protection_colors_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg414_static_keyword_protection_colors_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
