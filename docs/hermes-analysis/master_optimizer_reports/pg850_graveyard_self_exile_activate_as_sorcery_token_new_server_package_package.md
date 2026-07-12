# pg850_graveyard_self_exile_activate_as_sorcery_token_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-12T23:05:46+00:00`
- Selected cards: `["Dauntless Cathar", "Fairgrounds Patrol", "Ghoulcaller's Accomplice", "Goldmeadow Nomad", "Mother Bear", "Stoic Grove-Guide", "Suspicious Shambler"]`
- Families: `{"xmage_graveyard_self_exile_activated_create_token": 7}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg850_graveyard_self_exile_activate_as_sorcery_token_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg850_graveyard_self_exile_activate_as_sorcery_token_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg850_graveyard_self_exile_activate_as_sorcery_token_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg850_graveyard_self_exile_activate_as_sorcery_token_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg850_graveyard_self_exile_activate_as_sorcery_token_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg850_graveyard_self_exile_activate_as_sorcery_token_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
