# pg662 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-08T14:57:53+00:00`
- Selected cards: `["Confound", "Hindering Light", "Intervene", "Keep Safe", "Laquatus's Disdain", "Rebuff the Wicked", "Turn Aside"]`
- Families: `{"xmage_counter_target_draw_card_spell": 4, "xmage_counter_target_spell": 3}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg662_counter_draw_special_targets_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg662_counter_draw_special_targets_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg662_counter_draw_special_targets_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg662_counter_draw_special_targets_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg662_counter_draw_special_targets_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg662_counter_draw_special_targets_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
