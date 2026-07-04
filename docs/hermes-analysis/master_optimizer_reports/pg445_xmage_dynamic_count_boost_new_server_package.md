# pg445 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T22:54:31+00:00`
- Selected cards: `["Defile", "Desert's Due", "Drag Down", "Feeding Frenzy", "Gaea's Might", "Hunger of the Nim", "Inner Calm, Outer Strength", "Irradiate", "Might of Alara", "Might of the Masses", "Nightmarish End", "Strength of Cedars", "Warped Physique", "Wirewood Pride"]`
- Families: `{"xmage_dynamic_count_boost_target_creature_until_eot_spell": 14}`

Files:

- precheck: `../../master_optimizer_reports/pg445_xmage_dynamic_count_boost_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg445_xmage_dynamic_count_boost_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg445_xmage_dynamic_count_boost_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg445_xmage_dynamic_count_boost_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg445_xmage_dynamic_count_boost_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg445_xmage_dynamic_count_boost_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
