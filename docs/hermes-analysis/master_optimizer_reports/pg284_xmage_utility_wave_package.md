# PG284 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T07:51:50+00:00`
- Selected cards: `["Alloy Myr", "Altar's Light", "Angel's Mercy", "Angelic Edict", "Blessed Light", "Bloodstone Cameo", "Boreal Druid", "Caustic Rain", "Chaplain's Blessing", "Copper Myr", "Drake-Skull Cameo", "Druid of the Cowl", "Erase", "Fade into Antiquity", "Fate Forgotten", "Feed the Serpent", "Final Death", "Final Reward", "Gold Myr", "Golden Hind", "Goobbue Gardener", "Great Forest Druid", "Iona's Judgment", "Iron Myr", "Ironwright's Cleansing", "Leaden Myr", "Leaf Gilder", "Lifespring Druid", "Llanowar Dead", "Manakin", "Nourish", "Opaline Unicorn", "Orochi Sustainer", "Princess Lucrezia", "Revoke Existence", "Riven Turnbull", "Rosethorn Acolyte // Seasonal Ritual", "Sacred Nectar", "Scour from Existence", "Seashell Cameo", "Shattering Blow", "Sisters of the Flame", "Skyshroud Troopers", "Spring of Eternal Peace", "Three Tree Rootweaver", "Tigereye Cameo", "Troll-Horn Cameo", "Unmake", "Utopia Tree", "Utter End", "Wander Off", "Whitesun's Passage", "Wirewood Elf"]`
- Families: `{"xmage_exile_target_spell": 18, "xmage_fixed_life_gain_spell": 6, "xmage_simple_mana_source_permanent": 29}`

Files:

- precheck: `../../master_optimizer_reports/pg284_xmage_utility_wave_precheck.sql`
- apply: `../../master_optimizer_reports/pg284_xmage_utility_wave_apply.sql`
- rollback: `../../master_optimizer_reports/pg284_xmage_utility_wave_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg284_xmage_utility_wave_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg284_xmage_utility_wave_manifest.json`
- package: `../../master_optimizer_reports/pg284_xmage_utility_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
