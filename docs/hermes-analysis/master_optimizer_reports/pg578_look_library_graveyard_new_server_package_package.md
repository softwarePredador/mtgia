# PG578 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T22:53:25+00:00`
- Selected cards: `["Forbidden Alchemy", "Nagging Thoughts", "Resentful Revelation", "Tapping at the Window"]`
- Families: `{"xmage_look_library_pick_to_hand_rest_graveyard_spell": 4}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg578_look_library_graveyard_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
