# PG318 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T16:43:50+00:00`
- Selected cards: `["Circuitous Route", "Farseek", "Into the North", "Natural Connection", "Nature's Lore", "Personal Tutor", "Ranger's Path", "Reshape the Earth", "Shared Roots", "Skyshroud Claim", "Spoils of Victory", "Three Visits", "Untamed Wilds"]`
- Families: `{"xmage_library_search_spell": 13}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
