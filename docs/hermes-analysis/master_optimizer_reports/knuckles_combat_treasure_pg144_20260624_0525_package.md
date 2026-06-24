# PG144 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T05:25:24+00:00`
- Selected cards: `["Knuckles the Echidna"]`
- Families: `{"ramp_engine": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/knuckles_combat_treasure_pg144_20260624_0525_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/knuckles_combat_treasure_pg144_20260624_0525_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/knuckles_combat_treasure_pg144_20260624_0525_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/knuckles_combat_treasure_pg144_20260624_0525_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/knuckles_combat_treasure_pg144_20260624_0525_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/knuckles_combat_treasure_pg144_20260624_0525_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
