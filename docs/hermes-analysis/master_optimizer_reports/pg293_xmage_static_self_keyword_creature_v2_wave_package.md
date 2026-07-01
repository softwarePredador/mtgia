# PG293 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals. No SQL was executed by
the builder; PostgreSQL apply, sync, and E2E evidence are recorded in the
paired PG293 evidence files.

- Generated at: `2026-07-01T09:48:29+00:00`
- Selected cards: `["Angelic Wall", "Anvilwrought Raptor", "Archers of Qarsi", "Ascended Lawmage", "Aven Fleetwing", "Bassara Tower Archer", "Benthic Giant", "Boros Recruit", "Cloud Crusader", "Cold-Water Snapper", "Conifer Strider", "Consulate Skygate", "Copper Host Crusher", "Daggerdrome Imp", "Darksteel Gargoyle", "Darksteel Myr", "Dawnstrike Paladin", "Deadly Insect", "Deadly Recluse", "Deathgaze Cockatrice", "Deft Duelist", "Elvish Lookout", "Giant Solifuge", "Gladecover Scout", "Grendel, Spawn of Knull", "Griffin Sentinel", "Hawkeater Moth", "Healer's Hawk", "Humble Budoka", "Humongulus", "Kalonian Behemoth", "Kederekt Creeper", "Kessig Recluse", "Knight of Meadowgrain", "Kodama of the North Tree", "Lightning Stormkin", "Midnight Assassin", "Mist Leopard", "Monster Mashup", "Nightveil Predator", "Pegasus Charger", "Peregrine Griffin", "Pincher Beetles", "Plated Crusher", "Plated Slagwurm", "Porcelain Legionnaire", "Primal Huntbeast", "Razorfoot Griffin", "Relic Sloth", "Resistance Skywarden", "Rubbleback Rhino", "Sacred Wolf", "Scaled Behemoth", "Seraph of the Suns", "Serra Angel", "Simic Sky Swallower", "Skyshroud Falcon", "Skysnare Spider", "Skyspear Cavalry", "Slash Panther", "Slippery Bogle", "Soul of the Rapids", "Spined Thopter", "Sungrace Pegasus", "Swiftblade Vindicator", "Tajuru Pathwarden", "Taoist Hermit", "The Terror of Serpent's Pass", "Thornweald Archer", "Thundering Tanadon", "Tidehollow Strix", "Vampire Nighthawk", "Vampire of the Dire Moon", "Vault Skirge", "Venomthrope", "Wall of Denial", "Wall of Razors", "Wall of Spears", "Wall of Swords", "Wall of Vines", "Wardscale Crocodile", "Wind Spirit", "Wrecking Crew", "Zephid", "Zetalpa, Primal Dawn"]`
- Families: `{"xmage_static_self_combat_keyword_creature": 85}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg293_xmage_static_self_keyword_creature_v2_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg293_xmage_static_self_keyword_creature_v2_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg293_xmage_static_self_keyword_creature_v2_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg293_xmage_static_self_keyword_creature_v2_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg293_xmage_static_self_keyword_creature_v2_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg293_xmage_static_self_keyword_creature_v2_wave_package.md`

Completed apply gate:

- PostgreSQL postcheck promoted `85/85` rows as verified/auto with matching
  Oracle hashes.
- PG -> SQLite sync loaded `85` PostgreSQL rows and inserted/updated `85`
  SQLite rows.
- E2E validation passed PostgreSQL, SQLite, canonical snapshot, and runtime
  `get_card_effect` checks for `85/85` cards.
