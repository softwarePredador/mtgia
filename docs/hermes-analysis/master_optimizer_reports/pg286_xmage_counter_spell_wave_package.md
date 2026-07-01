# PG286 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T08:13:05+00:00`
- Selected cards: `["Annul", "Artifact Blast", "Cancel", "Dispel", "Envelop", "Essence Scatter", "Extinguish", "False Summoning", "Flash Counter", "Gainsay", "Preemptive Strike", "Remove Soul"]`
- Families: `{"xmage_counter_target_spell": 12}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg286_xmage_counter_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg286_xmage_counter_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg286_xmage_counter_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg286_xmage_counter_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg286_xmage_counter_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg286_xmage_counter_spell_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
