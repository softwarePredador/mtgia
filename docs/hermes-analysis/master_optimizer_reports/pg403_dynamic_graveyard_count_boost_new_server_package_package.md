# pg403 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T11:40:49+00:00`
- Selected cards: `["Festive Funeral", "Ghoul's Feast"]`
- Families: `{"xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg403_dynamic_graveyard_count_boost_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg403_dynamic_graveyard_count_boost_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg403_dynamic_graveyard_count_boost_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg403_dynamic_graveyard_count_boost_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg403_dynamic_graveyard_count_boost_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg403_dynamic_graveyard_count_boost_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
