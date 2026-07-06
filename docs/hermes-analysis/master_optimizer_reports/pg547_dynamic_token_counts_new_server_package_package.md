# pg547_dynamic_token_counts_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T03:39:24+00:00`
- Selected cards: `["Crash the Party", "Deploy to the Front", "Fungal Sprouting", "Goblin Gathering", "Howl of the Night Pack"]`
- Families: `{"xmage_controlled_subtype_create_creature_tokens_spell": 1, "xmage_dynamic_count_create_creature_tokens_spell": 4}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg547_dynamic_token_counts_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
