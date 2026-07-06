# pg551_etb_scry_static_keyword_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T05:00:09+00:00`
- Selected cards: `["Augury Owl", "Cloudreader Sphinx", "Faerie Seer", "Glider Kids", "Grey Havens Navigator", "Horizon Scholar", "Senate Griffin", "Silver Raven", "Thaumaturge's Familiar", "Wall of Runes", "Willow-Wind"]`
- Families: `{"xmage_creature_etb_scry": 11}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg551_etb_scry_static_keyword_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
