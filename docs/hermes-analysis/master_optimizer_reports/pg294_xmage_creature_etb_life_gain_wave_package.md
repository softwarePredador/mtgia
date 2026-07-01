# PG294 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals and then applied through
the evidence runner.

- Generated at: `2026-07-01T10:02:28+00:00`
- Selected cards: `["Amateur Hero", "Angel of Mercy", "Arashin Cleric", "Arborback Stomper", "Aven Battle Priest", "Aven of Enduring Hope", "Bulwark Giant", "Cathedral Sanctifier", "Centaur Healer", "Courier Griffin", "Dawning Angel", "Devout Monk", "Healer of the Glade", "Hill Giant Herdgorger", "Honey Mammoth", "Inspiring Cleric", "Jedit's Dragoons", "Kemba's Skyguard", "Koala-Sheep", "Lone Missionary", "Mesa Cavalier", "Mossbeard Ancient", "Peace Strider", "Primordial Pachyderm", "Ravenous Lindwurm", "Savannah Sage", "Shu Grain Caravan", "Shu Soldier-Farmers", "Spiritual Guardian", "Springmane Cervin", "Staunch Defenders", "Sylvan Brushstrider", "Temple Acolyte", "Teroh's Faithful", "Tireless Missionaries", "Turntimber Ascetic", "Venerable Monk"]`
- Families: `{"xmage_creature_etb_gain_life": 37}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_package.md`

Apply result:

- PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_pg_apply_evidence.md`
- PG -> Hermes/SQLite sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_sync_report.json`
- E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_e2e_validation.md`
- Postcheck: `37/37` promoted, verified/auto, and matching Oracle hash.
- Sync: `37` PostgreSQL rows loaded and `37` SQLite rows inserted/updated.
- E2E: PostgreSQL, SQLite, canonical snapshot, and runtime lookup all passed
  for `37/37` selected cards.
