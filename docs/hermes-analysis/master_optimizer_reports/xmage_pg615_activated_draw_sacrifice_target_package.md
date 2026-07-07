# pg615_activated_draw_sacrifice_target XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-07T12:49:11+00:00`
- Selected cards: `["Sage of Lat-Nam", "Thraxodemon"]`
- Families: `{"xmage_permanent_simple_activated_draw": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg615_activated_draw_sacrifice_target_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg615_activated_draw_sacrifice_target_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg615_activated_draw_sacrifice_target_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg615_activated_draw_sacrifice_target_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg615_activated_draw_sacrifice_target_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg615_activated_draw_sacrifice_target_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
