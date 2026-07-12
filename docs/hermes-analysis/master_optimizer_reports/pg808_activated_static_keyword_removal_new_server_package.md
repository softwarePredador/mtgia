# pg808 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-12T05:28:44+00:00`
- Selected cards: `["Cathar Commando", "Daraja Griffin", "Goblin Firebomb", "Pit Trap", "Shattered Acolyte", "Tolarian Sentinel", "Tradewind Rider", "Uktabi Faerie", "Undergrowth Leopard", "Visara the Dreadful", "Voracious Varmint"]`
- Families: `{"xmage_permanent_simple_activated_destroy_target": 9, "xmage_permanent_simple_activated_return_to_hand": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg808_activated_static_keyword_removal_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg808_activated_static_keyword_removal_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg808_activated_static_keyword_removal_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg808_activated_static_keyword_removal_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg808_activated_static_keyword_removal_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg808_activated_static_keyword_removal_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
