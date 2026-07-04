# PG377 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T01:38:42+00:00`
- Selected cards: `["Adamant Will", "Alabaster Mage", "Angelic Blessing", "Axgard Cavalry", "Beaming Defiance", "Bloodlust Inciter", "Blossoming Defense", "Brute Strength", "Chase Inspiration", "Coat with Venom", "Confidence from Strength", "Crimson Mage", "Dive Down", "Glint", "Goblin Motivator", "Grotesque Mutation", "Kindled Fury", "Moment of Heroism", "Mortal's Ardor", "Mortal's Resolve", "Onyx Mage", "Predator's Strike", "Ranger's Guile", "Shape the Sands", "Silk Net", "Slaughter Cry", "Snare the Skies", "Sure Strike", "Thunder Strike", "Unlikely Aid", "Whip Sergeant", "Woodcutter's Grit"]`
- Families: `{"xmage_boost_keyword_target_creature_until_eot_spell": 25, "xmage_permanent_simple_activated_target_keyword_until_eot": 7}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg377_xmage_keyword_reminder_wave_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg377_xmage_keyword_reminder_wave_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg377_xmage_keyword_reminder_wave_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg377_xmage_keyword_reminder_wave_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg377_xmage_keyword_reminder_wave_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg377_xmage_keyword_reminder_wave_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
