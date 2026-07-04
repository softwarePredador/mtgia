# pg435 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T21:30:45+00:00`
- Selected cards: `["Adamant Will", "Angelic Blessing", "Beaming Defiance", "Blossoming Defense", "Brute Strength", "Chase Inspiration", "Coat with Venom", "Confidence from Strength", "Dive Down", "Glint", "Grotesque Mutation", "Kindled Fury", "Moment of Heroism", "Mortal's Ardor", "Mortal's Resolve", "Predator's Strike", "Ranger's Guile", "Shape the Sands", "Silk Net", "Slaughter Cry", "Snare the Skies", "Sure Strike", "Thunder Strike", "Unlikely Aid", "Woodcutter's Grit"]`
- Families: `{"xmage_boost_keyword_target_creature_until_eot_spell": 25}`

Files:

- precheck: `../../master_optimizer_reports/pg435_xmage_boost_keyword_eot_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg435_xmage_boost_keyword_eot_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg435_xmage_boost_keyword_eot_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg435_xmage_boost_keyword_eot_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg435_xmage_boost_keyword_eot_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg435_xmage_boost_keyword_eot_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
