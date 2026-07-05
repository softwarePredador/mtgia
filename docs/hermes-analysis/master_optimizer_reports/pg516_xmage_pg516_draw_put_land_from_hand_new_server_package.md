# xmage_pg516_draw_put_land_from_hand_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T16:12:59+00:00`
- Selected cards: `["Embrace the Paradox", "Eureka Moment", "Growth Spiral", "Lessons from Life"]`
- Families: `{"xmage_fixed_draw_put_land_from_hand_spell": 4}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg516_xmage_pg516_draw_put_land_from_hand_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg516_xmage_pg516_draw_put_land_from_hand_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg516_xmage_pg516_draw_put_land_from_hand_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg516_xmage_pg516_draw_put_land_from_hand_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg516_xmage_pg516_draw_put_land_from_hand_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg516_xmage_pg516_draw_put_land_from_hand_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
