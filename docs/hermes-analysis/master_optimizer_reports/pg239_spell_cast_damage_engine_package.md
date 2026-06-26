# PG239 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-26T10:19:44+00:00`
- Selected cards: `["Longshot, Rebel Bowman", "Guttersnipe", "Coruscation Mage", "Fiery Inscription", "Vivi Ornitier"]`
- Families: `{"spell_cast_damage_engine": 5}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg239_spell_cast_damage_engine_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg239_spell_cast_damage_engine_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg239_spell_cast_damage_engine_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg239_spell_cast_damage_engine_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg239_spell_cast_damage_engine_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg239_spell_cast_damage_engine_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
