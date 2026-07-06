# pg562 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T11:09:58+00:00`
- Selected cards: `["Armada Wurm", "Aspiring Aeronaut", "Attended Knight", "Chimney Rabble", "Crested Herdcaller", "Dragoon's Wyvern", "Elturgard Ranger", "Experimental Aviator", "Flamekin Gildweaver", "Gallant Cavalry", "Guarded Heir", "Howling Giant", "Invasion Reinforcements", "Jewel Thief", "Knight of the New Coalition", "News Helicopter", "Oltec Cloud Guard", "Pack Guardian", "Preening Champion", "Prideful Parent", "Rapacious Dragon", "Resolute Reinforcements", "Searchlight Companion", "Treetop Freedom Fighters", "Twin-Silk Spider", "Valorous Steed", "Voice of the Provinces"]`
- Families: `{"xmage_creature_etb_create_tokens": 24, "xmage_creature_etb_create_treasure": 3}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
