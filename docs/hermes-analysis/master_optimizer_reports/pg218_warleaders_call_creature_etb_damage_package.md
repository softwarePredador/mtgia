# PG218 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-25T12:28:43+00:00`
- Selected cards: `["Warleader's Call"]`
- Families: `{"controlled_creature_etb_damage_engine": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg218_warleaders_call_creature_etb_damage_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg218_warleaders_call_creature_etb_damage_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg218_warleaders_call_creature_etb_damage_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg218_warleaders_call_creature_etb_damage_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg218_warleaders_call_creature_etb_damage_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg218_warleaders_call_creature_etb_damage_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
