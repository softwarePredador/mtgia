# PG486 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T06:18:20+00:00`
- Selected cards: `["Boris Devilboon", "Centaur Glade", "Centaur's Herald", "Dragon Roost", "Envoy of Okinec Ahau", "Jade Mage", "Nuisance Engine", "Renowned Weaver", "Sliver Queen", "Whirlermaker"]`
- Families: `{"xmage_permanent_simple_activated_create_token": 10}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg486_activated_token_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg486_activated_token_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg486_activated_token_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg486_activated_token_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg486_activated_token_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg486_activated_token_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
