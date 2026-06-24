# PG188 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T21:06:04+00:00`
- Selected cards: `["Pyromancer Ascension"]`
- Families: `{"copy_spell_engine": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg188_pyromancer_ascension_quest_copy_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg188_pyromancer_ascension_quest_copy_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg188_pyromancer_ascension_quest_copy_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg188_pyromancer_ascension_quest_copy_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg188_pyromancer_ascension_quest_copy_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg188_pyromancer_ascension_quest_copy_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
