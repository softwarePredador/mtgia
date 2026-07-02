# PG344 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-02T01:49:30+00:00`
- Selected cards: `["Boneyard Wurm", "Cantivore", "Cognivore", "Lord of Extinction", "Magnivore", "Revenant", "Slag Fiend", "Terravore"]`
- Families: `{"xmage_static_source_power_toughness_equal_graveyard_count": 8}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
