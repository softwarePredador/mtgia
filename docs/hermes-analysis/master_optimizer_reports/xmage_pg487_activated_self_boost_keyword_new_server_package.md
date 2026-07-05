# PG487 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T06:33:21+00:00`
- Selected cards: `["Almighty Brushwagg", "Anointed Chorister", "Aven Flock", "Balshan Collaborator", "Blistering Dieflyn", "Burrog Banemaker", "Capashen Knight", "Char-Rumbler", "Crypt Ripper", "Dragon Hatchling", "Drifting Shade", "Dungeon Shade", "Ember-Eye Wolf", "Feral Ridgewolf", "Fireborn Knight", "Firefly", "Flowstone Hellion", "Flowstone Kavu", "Flowstone Mauler", "Flowstone Wall", "Flowstone Wyvern", "Furnace Spirit", "Furnace Whelp", "Granite Gargoyle", "Hellkite Punisher", "Hermitic Nautilus", "Inkrise Infiltrator", "Killer Bees", "Lionheart Maverick", "Loxodon Stalwart", "Marble Gargoyle", "Masked Blackguard", "Mesa Falcon", "Metropolis Sprite", "Minotaur Sureshot", "Moonwing Moth", "Nightwing Shade", "Pardic Collaborator", "Pearl Dragon", "Pyre Charger", "Rakdos Trumpeter", "Ravine Raider", "Rune-Cervin Rider", "Sandstone Warrior", "Shivan Dragon", "Steam Spitter", "Sun-Collared Raptor", "Talonrend", "Tattered Apparition", "Thirsting Shade", "Thunder Wall", "Torch Drake", "Tower Drake", "Wall of Faith", "Wall of Fire", "Wall of Lava", "Wall of Opposition", "Wall of Water"]`
- Families: `{"xmage_permanent_simple_activated_self_boost_until_eot": 58}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg487_activated_self_boost_keyword_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg487_activated_self_boost_keyword_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg487_activated_self_boost_keyword_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg487_activated_self_boost_keyword_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg487_activated_self_boost_keyword_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg487_activated_self_boost_keyword_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
