# PG219 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-26T02:37:10+00:00`
- Selected cards: `["Purphoros, God of the Forge"]`
- Families: `{"controlled_creature_etb_damage_engine": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg219_purphoros_partial_trigger_preserve_shadow_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg219_purphoros_partial_trigger_preserve_shadow_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg219_purphoros_partial_trigger_preserve_shadow_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg219_purphoros_partial_trigger_preserve_shadow_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg219_purphoros_partial_trigger_preserve_shadow_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg219_purphoros_partial_trigger_preserve_shadow_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
