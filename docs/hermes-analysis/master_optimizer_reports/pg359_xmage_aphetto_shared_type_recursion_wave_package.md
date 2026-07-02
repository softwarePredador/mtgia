# PG359 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-02T06:48:50+00:00`
- Selected cards: `["Aphetto Dredging"]`
- Families: `{"xmage_graveyard_to_hand_spell": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
