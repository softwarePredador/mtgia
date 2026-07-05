# PG532 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T21:55:33+00:00`
- Selected cards: `["Boon of Emrakul", "Chant of the Skifsang", "Clinging Darkness", "Dead Weight", "Debilitating Injury", "Defensive Stance", "Divine Transformation", "Enfeeblement", "Feast of the Unicorn", "Feebleness", "Feral Invocation", "Giant Strength", "Gift of Granite", "Greel's Caress", "Hardened-Scale Armor", "Hero's Resolve", "Holy Strength", "Indomitable Will", "Knight's Pledge", "Mageta's Boon", "Maggot Therapy", "Mire's Grasp", "Oakenform", "Pin to the Earth", "Riot Spikes", "Sensory Deprivation", "Siegecraft", "Slimebind", "Stoneskin", "Torment", "Torpor Dust", "Twisted Experiment", "Unholy Strength", "Weakness", "Weight of the Underworld"]`
- Families: `{"xmage_aura_static_power_toughness_attachment": 35}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg532_aura_static_pt_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg532_aura_static_pt_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg532_aura_static_pt_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg532_aura_static_pt_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg532_aura_static_pt_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg532_aura_static_pt_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
