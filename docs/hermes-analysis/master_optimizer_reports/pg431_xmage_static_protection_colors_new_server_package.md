# pg431 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T21:01:14+00:00`
- Selected cards: `["Abbey Gargoyles", "Akroma, Angel of Wrath", "Aven Smokeweaver", "Black Knight", "Blood Knight", "Cemetery Gate", "Cerulean Wyvern", "Coast Watcher", "Death Speakers", "Defender of Chaos", "Defender of Law", "Duskrider Falcon", "Freewind Falcon", "Galina's Knight", "Goblin Outlander", "Guma", "Hazerider Drake", "Ihsan's Shade", "Iridescent Angel", "Karoo Meerkat", "Llanowar Knight", "Melesse Spirit", "Mirran Crusader", "Nacatl Outlander", "Narwhal", "Nightwind Glider", "Oraxid", "Oversoul of Dusk", "Paladin en-Vec", "Repentant Blacksmith", "Sabertooth Nishoba", "Scalebane's Elite", "Sea Sprite", "Shivan Zombie", "Silver Knight", "Sphinx of the Steel Wind", "Thermal Glider", "Treetop Sentinel", "Valeron Outlander", "Vedalken Outlander", "Vodalian Zombie", "Voice of Duty", "Voice of Grace", "Voice of Law", "Voice of Reason", "Voice of Truth", "Vulshok Refugee", "Wall of Light", "Weatherseed Faeries", "White Knight", "Windreaper Falcon", "Yavimaya Barbarian", "Zombie Outlander"]`
- Families: `{"xmage_static_self_protection_from_colors_creature": 53}`

Files:

- precheck: `../../master_optimizer_reports/pg431_xmage_static_protection_colors_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg431_xmage_static_protection_colors_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg431_xmage_static_protection_colors_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg431_xmage_static_protection_colors_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg431_xmage_static_protection_colors_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg431_xmage_static_protection_colors_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
