# PG513 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T15:05:47+00:00`
- Selected cards: `["Annihilate", "Eastern Paladin", "Execute", "Slay"]`
- Families: `{"xmage_destroy_target_draw_card_spell": 3, "xmage_permanent_simple_activated_destroy_target": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg513_destroy_draw_color_targets_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
