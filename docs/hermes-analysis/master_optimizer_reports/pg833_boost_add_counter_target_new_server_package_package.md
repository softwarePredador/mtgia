# PG833 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-12T13:24:01+00:00`
- Selected cards: `["Free from Flesh", "Fully Grown", "Heightened Reflexes", "Spontaneous Flight"]`
- Families: `{"xmage_boost_target_creature_until_eot_add_counter_spell": 4}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg833_boost_add_counter_target_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg833_boost_add_counter_target_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg833_boost_add_counter_target_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg833_boost_add_counter_target_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg833_boost_add_counter_target_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg833_boost_add_counter_target_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
