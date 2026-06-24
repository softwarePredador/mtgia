# PG139 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T03:06:09+00:00`
- Selected cards: `["Lotho, Corrupt Shirriff", "Prized Statue"]`
- Families: `{"ramp_engine": 1, "ramp_permanent": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg139_current_replay_batch_two_lotho_prized_statue_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg139_current_replay_batch_two_lotho_prized_statue_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg139_current_replay_batch_two_lotho_prized_statue_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg139_current_replay_batch_two_lotho_prized_statue_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg139_current_replay_batch_two_lotho_prized_statue_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg139_current_replay_batch_two_lotho_prized_statue_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
