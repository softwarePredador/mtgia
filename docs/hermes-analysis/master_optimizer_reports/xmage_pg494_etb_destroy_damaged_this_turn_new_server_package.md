# PG494 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T08:37:27+00:00`
- Selected cards: `["Fathom Fleet Cutthroat", "Vraska's Finisher"]`
- Families: `{"xmage_creature_etb_destroy_target": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg494_etb_destroy_damaged_this_turn_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg494_etb_destroy_damaged_this_turn_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg494_etb_destroy_damaged_this_turn_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg494_etb_destroy_damaged_this_turn_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg494_etb_destroy_damaged_this_turn_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg494_etb_destroy_damaged_this_turn_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
