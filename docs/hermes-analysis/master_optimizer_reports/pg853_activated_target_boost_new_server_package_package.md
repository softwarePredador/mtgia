# pg853_activated_target_boost_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-13T00:26:50+00:00`
- Selected cards: `["Aegis of the Meek", "Alpha Kavu", "Angelic Page", "Anointer of Champions", "Assembly-Worker", "Crenellated Wall", "Dwarven Lieutenant", "Grassland Crusader", "Hate Weaver", "Hoof Skulkin", "Icatian Lieutenant", "Infantry Veteran", "Kabuto Moth", "Kithkin Daggerdare", "Phyrexian Debaser", "Serra Advocate", "Spirit Weaver", "Sword Dancer", "Sword of the Chosen", "Tuknir Deathlock", "Wilderness Hypnotist"]`
- Families: `{"xmage_permanent_simple_activated_target_boost_until_eot": 21}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg853_activated_target_boost_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg853_activated_target_boost_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg853_activated_target_boost_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg853_activated_target_boost_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg853_activated_target_boost_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg853_activated_target_boost_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
