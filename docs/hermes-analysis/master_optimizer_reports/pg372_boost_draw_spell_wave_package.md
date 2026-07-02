# PG372 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-02T10:54:10+00:00`
- Selected cards: `["Afflict", "Aggressive Urge", "Befuddle", "Bewilder", "Defiant Strike", "Fleeting Distraction", "Rebellious Strike", "Shocking Grasp", "Sudden Strength", "Sugar Rush"]`
- Families: `{"xmage_fixed_boost_draw_card_spell": 10}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg372_boost_draw_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg372_boost_draw_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg372_boost_draw_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg372_boost_draw_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg372_boost_draw_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg372_boost_draw_spell_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
