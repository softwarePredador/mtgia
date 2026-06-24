# PG171 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T12:11:47+00:00`
- Selected cards: `["Mystic Remora", "Rhystic Study", "Crop Rotation", "Elvish Reclaimer"]`
- Families: `{"creature": 1, "draw_engine": 2, "land_ramp": 1}`

Files:

- precheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg171_draw_engines_and_land_tutors_precheck.sql`
- apply: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg171_draw_engines_and_land_tutors_apply.sql`
- rollback: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg171_draw_engines_and_land_tutors_rollback.sql`
- postcheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg171_draw_engines_and_land_tutors_postcheck.sql`
- manifest: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg171_draw_engines_and_land_tutors_manifest.json`
- package: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg171_draw_engines_and_land_tutors_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
