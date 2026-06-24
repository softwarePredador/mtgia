# PG168 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T11:30:00+00:00`
- Selected cards: `["Elvish Spirit Guide", "Mountain", "Plains"]`
- Families: `{"land": 2, "ramp_ritual": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg168_land_and_hand_exile_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg168_land_and_hand_exile_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg168_land_and_hand_exile_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg168_land_and_hand_exile_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg168_land_and_hand_exile_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg168_land_and_hand_exile_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
