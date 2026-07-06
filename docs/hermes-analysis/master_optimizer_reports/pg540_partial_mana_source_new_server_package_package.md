# pg540_partial_mana_source_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T01:04:13+00:00`
- Selected cards: `["Aetheric Amplifier", "Agility Bobblehead", "Ancient Cornucopia", "Arc Reactor", "Arixmethes, Slumbering Isle", "Armored Scrapgorger", "Atarka Monument", "Azorius Keyrune", "Bandit's Haul", "Bonder's Ornament", "Boros Keyrune", "Bounty Board", "Bronze Walrus", "Bugenhagen, Wise Elder", "Canopy Tactician", "Centaur Nurturer", "Ceta Disciple", "Chronatog Totem", "Crossroads Candleguide", "Crystal Skull, Isu Spyglass", "Cultivator's Caravan", "Dawnhart Rejuvenator", "Deathcap Cultivator", "Decanter of Endless Water", "Dimir Keyrune", "Dragon's Hoard", "Dragonstorm Globe", "Dromoka Monument", "Drover of the Mighty", "Drumhunter", "Dungeon Map", "Ebony Fly", "Elvish Aberration", "Elvish Harbinger", "Endurance Bobblehead", "Exuberant Firestoker", "Eye of Ojer Taq // Apex Observatory", "Fieldmist Borderpost", "Firdoch Core", "Firewild Borderpost", "Foriysian Totem", "Fountain of Ichor", "Frog Butler", "Gatewatch Beacon", "Golgari Keyrune", "Gruul Keyrune", "Guardian Idol", "Guy in the Chair", "Hardbristle Bandit", "Hierophant's Chalice", "Honor-Worn Shaku", "Honored Heirloom", "Indatha Crystal", "Inherited Envelope", "Intrepid Paleontologist", "Ketria Crystal", "Kolaghan Monument", "Lantern of Revealing", "Laser Screwdriver", "Lavabrink Floodgates", "Llanowar Loamspeaker", "Lullmage's Familiar", "Magnifying Glass", "Magus of the Library", "Mana Geode", "Meteorite", "Midnight Clock", "Misleading Signpost", "Mistvein Borderpost", "Model of Unity", "Mox Tantalite", "Mystic Skull // Mystic Monstrosity", "Necra Disciple", "Oasis Gardener", "Ojutai Monument", "Orzhov Keyrune", "Paradise Druid", "Patchwork Banner", "Patriar's Seal", "Perception Bobblehead", "Phial of Galadriel", "Phyrexian Atlas", "Phyrexian Totem", "Planar Atlas", "Poison Dart Frog", "Potioner's Trove", "Prize Pig", "Progenitor's Icon", "Radha, Heir to Keld", "Rakdos Keyrune", "Rattleclaw Mystic", "Raugrin Crystal", "Reclusive Taxidermist", "Rift Sower", "Ruby, Daring Tracker", "Runadi, Behemoth Caller", "Savai Crystal", "Scorned Villager // Moonscarred Werewolf", "Scuttlemutt", "Seer's Lantern", "Selesnya Keyrune", "Serum Powder", "Silumgar Monument", "Simic Keyrune", "Skull Prophet", "Skyclave Relic", "Snapping Voidcraw", "Sol Talisman", "Sonic Screwdriver", "Spider Manifestation", "Spinning Wheel", "Starnheim Memento", "Stonework Packbeast", "Strength Bobblehead", "Sunbird Standard // Sunbird Effigy", "Sunseed Nurturer", "Tender Wildguide", "The Celestus", "The Irencrag", "The Lion-Turtle", "Thunder Totem", "Ticket Turbotubes", "Tome of the Guildpact", "Torgal, A Fine Hound", "Trailtracker Scout", "Tunnel Tipster", "Ulvenwald Captive // Ulvenwald Abomination", "Veinfire Borderpost", "Veloheart Bike", "Vessel of Endless Rest", "Visage of Bolas", "Wand of the Worldsoul", "Wandertale Mentor", "Warden of the Wall", "Weatherseed Totem", "Weaver of Blossoms // Blossom-Clad Werewolf", "Werebear", "White Auracite", "Wildfield Borderpost", "Wose Pathfinder", "Zagoth Crystal", "Zhur-Taa Druid", "Zookeeper Mechan"]`
- Families: `{"xmage_simple_mana_source_with_unmodeled_auxiliary": 143}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg540_partial_mana_source_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg540_partial_mana_source_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg540_partial_mana_source_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg540_partial_mana_source_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg540_partial_mana_source_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg540_partial_mana_source_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
