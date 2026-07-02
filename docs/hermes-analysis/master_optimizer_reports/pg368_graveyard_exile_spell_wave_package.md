# PG368 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-02T09:49:01+00:00`
- Selected cards: `["Coffin Purge", "Decompose", "Fade from Memory", "Purify the Grave", "Rapid Decay", "Rats' Feast", "Scarab Feast"]`
- Families: `{"xmage_graveyard_exile_spell": 7}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
