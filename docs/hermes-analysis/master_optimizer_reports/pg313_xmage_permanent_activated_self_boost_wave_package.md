# PG313 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T15:24:36+00:00`
- Selected cards: `["Abbey Matron", "Adarkar Sentinel", "Angelfire Crusader", "Augmenting Automaton", "Bellows Lizard", "Boa Constrictor", "Bold Impaler", "Breathstealer", "Capashen Templar", "Carrion Ants", "Cavern Thoctar", "Devkarin Dissident", "Dragon Engine", "Dread Shade", "Dross Ripper", "Ebony Treefolk", "Fathom Fleet Firebrand", "Fetid Horror", "Fiery Hellhound", "Firescreamer", "Flame Spirit", "Flamekin Brawler", "Flowstone Crusher", "Flowstone Giant", "Flowstone Shambler", "Folk of the Pines", "Frozen Shade", "Gravel-Hide Goblin", "Greater Forgeling", "Hematite Golem", "Hoar Shade", "Honor Guard", "Igneous Cur", "Iridescent Blademaster", "Jousting Dummy", "Kjeldoran Outrider", "Kranioceros", "Kraul Warrior", "Lavastep Raider", "Llanowar Vanguard", "Looming Shade", "Molten Ravager", "Nantuko Shade", "Narstad Scrapper", "Pavel Maliki", "Perilous Shadow", "Primeval Shambler", "Quilled Wolf", "Retrieval Agent", "Ridgeline Rager", "Scion of Glaciers", "Sea Spirit", "Shambling Strider", "Stonewood Invoker", "Storm Shaman", "Teeterpeak Ambusher", "Tyrranax", "Veiled Shade", "Viashino Slasher", "Watercourser", "Weaselback Redcap", "Yavimaya Ancients", "Zof Shade"]`
- Families: `{"xmage_permanent_simple_activated_self_boost_until_eot": 63}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
