# PG331 XMage Batch PostgreSQL Package

Status: `applied_synced_validated`.

This package was generated from XMage batch proposals, applied through the
precheck/apply/postcheck path, synced from PostgreSQL to Hermes/SQLite, and
validated through the E2E package gate.

- Generated at: `2026-07-01T21:08:36+00:00`
- Selected cards: `["Dutiful Attendant", "Elderfang Ritualist", "Living Lightning", "Myr Retriever", "Workshop Assistant"]`
- Families: `{"xmage_creature_dies_graveyard_to_hand": 5}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_package.md`

Apply gate:

- Applied under the active global all-card XMage completion goal.
- Evidence: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_pg_apply_evidence.md`.
