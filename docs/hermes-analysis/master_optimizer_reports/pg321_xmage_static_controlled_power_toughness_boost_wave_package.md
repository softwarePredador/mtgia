# PG321 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T18:17:04+00:00`
- Selected cards: `["Anthem of Champions", "Battle Sliver", "Benalish Marshal", "Bladestitched Skaab", "Blessed Orator", "Broodwarden", "Chief of the Edge", "Chief of the Foundry", "Chief of the Scale", "Cleaving Sliver", "Collective Blessing", "Day of Destiny", "Fire Nation's Conquest", "Flowstone Surge", "Gaea's Anthem", "Glorious Anthem", "Inspiring Veteran", "Kargan Warleader", "King of the Pride", "Kongming, \"Sleeping Dragon\"", "Megantic Sliver", "Pride of the Perfect", "Regal Imperiosaur", "Squirrel Sovereign", "Steelform Sliver", "Tempered Steel", "Thirsting Bloodlord", "Veteran Armorer", "Veteran Armorsmith", "Veteran Swordsmith", "Wizened Cenn", "Yotian Tactician"]`
- Families: `{"xmage_static_controlled_power_toughness_boost": 32}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
