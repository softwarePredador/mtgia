# PG120 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-23T22:45:32+00:00`
- Selected cards: `["Hedron Archive", "Mind Stone", "Stonespeaker Crystal"]`
- Families: `{"modal_mana_rock": 3}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg120_modal_mana_rock_runtime_restore_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg120_modal_mana_rock_runtime_restore_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg120_modal_mana_rock_runtime_restore_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg120_modal_mana_rock_runtime_restore_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg120_modal_mana_rock_runtime_restore_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg120_modal_mana_rock_runtime_restore_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
