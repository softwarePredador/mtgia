# PG173 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T12:34:04+00:00`
- Selected cards: `["Nature's Rhythm", "Chord of Calling", "Green Sun's Zenith", "Whir of Invention"]`
- Families: `{"tutor": 4}`

Files:

- precheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg173_x_tutor_battlefield_spells_precheck.sql`
- apply: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg173_x_tutor_battlefield_spells_apply.sql`
- rollback: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg173_x_tutor_battlefield_spells_rollback.sql`
- postcheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg173_x_tutor_battlefield_spells_postcheck.sql`
- manifest: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg173_x_tutor_battlefield_spells_manifest.json`
- package: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg173_x_tutor_battlefield_spells_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
