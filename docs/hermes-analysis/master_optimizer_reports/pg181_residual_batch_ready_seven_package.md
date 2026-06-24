# PG181 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T14:36:55+00:00`
- Selected cards: `["Brass's Bounty", "Bedevil", "Cathartic Reunion", "Crackle with Power", "Invoke Justice", "Steelshaper's Gift", "Locket of Yesterdays"]`
- Families: `{"static_cost_reducer": 1, "targeted_interaction": 4, "treasure_maker": 1, "tutor": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg181_residual_batch_ready_seven_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg181_residual_batch_ready_seven_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg181_residual_batch_ready_seven_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg181_residual_batch_ready_seven_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg181_residual_batch_ready_seven_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg181_residual_batch_ready_seven_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
