# PG242 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-26T11:25:44+00:00`
- Selected cards: `["Magmakin Artillerist"]`
- Families: `{"creature": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg242_magmakin_discard_damage_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg242_magmakin_discard_damage_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg242_magmakin_discard_damage_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg242_magmakin_discard_damage_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg242_magmakin_discard_damage_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg242_magmakin_discard_damage_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
