# PG592 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-07T04:12:46+00:00`
- Selected cards: `["Aether Gale", "Captivating Gyre", "Curtains' Call", "Dust to Dust", "Hex", "Into the Core", "Into the Void", "Peace and Quiet", "Quicksilver Geyser", "Rack and Ruin", "Rain of Salt", "Sea God's Scorn", "Undo", "Violent Ultimatum", "Waterwhirl"]`
- Families: `{"xmage_destroy_multi_target_spell": 6, "xmage_exile_multi_target_spell": 2, "xmage_return_multi_target_to_hand_spell": 7}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg592_multi_target_removal_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg592_multi_target_removal_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg592_multi_target_removal_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg592_multi_target_removal_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg592_multi_target_removal_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg592_multi_target_removal_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
