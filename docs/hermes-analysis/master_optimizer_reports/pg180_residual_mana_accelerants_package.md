# PG180 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T14:07:14+00:00`
- Selected cards: `["Bloom Tender", "Circle of Dreams Druid", "Ignoble Hierarch", "Springleaf Drum", "Noble Hierarch", "Relic of Legends", "Talisman of Indulgence", "Moonsnare Prototype"]`
- Families: `{"creature": 4, "ramp_permanent": 4}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg180_residual_mana_accelerants_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg180_residual_mana_accelerants_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg180_residual_mana_accelerants_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg180_residual_mana_accelerants_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg180_residual_mana_accelerants_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg180_residual_mana_accelerants_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
