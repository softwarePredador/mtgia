# pg553_self_keyword_until_eot_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T05:54:49+00:00`
- Selected cards: `["Bastion Mastodon", "Bladed Sentinel", "Cabaretti Initiate", "Cobalt Golem", "Disciple of the Old Ways", "Dukhara Peafowl", "Fallaji Chaindancer", "Goblin Balloon Brigade", "Gruul Nodorog", "Gust-Skimmer", "Henge Guardian", "Igneous Golem", "Kessig Wolf", "Killer Whale", "Kor Sky Climber", "Leaping Master", "Llanowar Cavalry", "Malachite Golem", "Manta Riders", "Mardu Hateblade", "Moorland Inquisitor", "Narnam Cobra", "Noble Panther", "Patagia Golem", "Pestilent Wolf", "Prakhata Pillar-Bug", "Riveteers Initiate", "Roofstalker Wight", "Saberclaw Golem", "Serpentine Kavu", "Skittering Heartstopper", "Steeple Creeper", "Stonefare Crocodile", "Stream Hopper", "Titanium Golem", "Towering Thunderfist", "Twilight Panther", "Unyielding Krumar", "Vectis Silencers", "Viashino Grappler", "Weldfast Monitor", "Whiptongue Frog", "Wily Bandar"]`
- Families: `{"xmage_permanent_simple_activated_self_keyword_until_eot": 43}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg553_self_keyword_until_eot_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg553_self_keyword_until_eot_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg553_self_keyword_until_eot_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg553_self_keyword_until_eot_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg553_self_keyword_until_eot_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg553_self_keyword_until_eot_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
