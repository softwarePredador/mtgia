# pg282 XMage Batch PostgreSQL Package

Status: `applied_synced`.

This package was generated from XMage batch proposals, applied to PostgreSQL, synced to Hermes SQLite, and validated E2E on 2026-06-30.

- Generated at: `2026-06-30T15:58:00+00:00`
- Selected cards: `["Blood Moon", "Karn, the Great Creator", "Chandra's Ignition", "Karn's Sylex", "Naktamun Lorespinner // Wheel of Fortune", "Charmbreaker Devils", "Ancient Gold Dragon", "Deathbellow War Cry"]`
- Families: `{"board_wipe_choice": 2, "draw_engine": 1, "passive": 2, "recursion": 1, "token_maker": 1, "tutor": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg282_final_eight_runtime_closure_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg282_final_eight_runtime_closure_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg282_final_eight_runtime_closure_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg282_final_eight_runtime_closure_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg282_final_eight_runtime_closure_20260630_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg282_final_eight_runtime_closure_20260630_package.md`

Apply gate:

- PostgreSQL precheck/apply/postcheck completed successfully.
- PG -> SQLite sync completed successfully.
- E2E validation completed successfully; rollback SQL is retained for emergency restore.
