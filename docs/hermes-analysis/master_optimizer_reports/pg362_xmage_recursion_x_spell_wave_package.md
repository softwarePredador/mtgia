# PG362 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-02T07:50:31+00:00`
- Selected cards: `["Back in Town", "Death Denied", "Stir the Grave"]`
- Families: `{"xmage_graveyard_to_battlefield_spell": 2, "xmage_graveyard_to_hand_x_count_spell": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
