# PG165 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T10:43:21+00:00`
- Selected cards: `["Fact or Fiction", "Steam Augury"]`
- Families: `{"pile_selection_spell": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg165_pile_selection_draw_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg165_pile_selection_draw_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg165_pile_selection_draw_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg165_pile_selection_draw_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg165_pile_selection_draw_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg165_pile_selection_draw_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
