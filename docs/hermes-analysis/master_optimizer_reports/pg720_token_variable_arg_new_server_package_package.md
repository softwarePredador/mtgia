# pg720_token_variable_arg_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-10T20:32:59+00:00`
- Selected cards: `["Ant Queen", "Broodmate Dragon", "Roc Egg", "Sprouting Thrinax"]`
- Families: `{"xmage_creature_dies_create_tokens": 2, "xmage_creature_etb_create_tokens": 1, "xmage_permanent_simple_activated_create_token": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg720_token_variable_arg_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg720_token_variable_arg_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg720_token_variable_arg_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg720_token_variable_arg_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg720_token_variable_arg_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg720_token_variable_arg_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
