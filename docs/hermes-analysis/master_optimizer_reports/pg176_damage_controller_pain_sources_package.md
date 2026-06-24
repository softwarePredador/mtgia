# PG176 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T13:14:34+00:00`
- Selected cards: `["Elves of Deep Shadow", "Talisman of Curiosity", "Tarnished Citadel"]`
- Families: `{"creature": 1, "land": 1, "ramp_permanent": 1}`

Files:

- precheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg176_damage_controller_pain_sources_precheck.sql`
- apply: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg176_damage_controller_pain_sources_apply.sql`
- rollback: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg176_damage_controller_pain_sources_rollback.sql`
- postcheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg176_damage_controller_pain_sources_postcheck.sql`
- manifest: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg176_damage_controller_pain_sources_manifest.json`
- package: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg176_damage_controller_pain_sources_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
