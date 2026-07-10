# pg721_activated_self_boost_costs_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-10T21:07:35+00:00`
- Selected cards: `["Aven Trooper", "Burning-Fist Minotaur", "Canyon Drake", "Carrion Howler", "Cutthroat Contender", "Fleshgrafter", "Frenetic Ogre", "Grimclaw Bats", "Krosan Archer", "Noose Constrictor", "Pardic Swordsmith", "Putrid Leech", "Ravenous Bloodseeker", "Stalking Bloodsucker", "Wall of Blood"]`
- Families: `{"xmage_permanent_simple_activated_self_boost_until_eot": 15}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg721_activated_self_boost_costs_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
