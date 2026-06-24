# PG172 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T12:20:41+00:00`
- Selected cards: `["Grim Monolith", "Basalt Monolith"]`
- Families: `{"ramp_permanent": 2}`

Files:

- precheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg172_monolith_mana_rocks_precheck.sql`
- apply: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg172_monolith_mana_rocks_apply.sql`
- rollback: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg172_monolith_mana_rocks_rollback.sql`
- postcheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg172_monolith_mana_rocks_postcheck.sql`
- manifest: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg172_monolith_mana_rocks_manifest.json`
- package: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg172_monolith_mana_rocks_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
