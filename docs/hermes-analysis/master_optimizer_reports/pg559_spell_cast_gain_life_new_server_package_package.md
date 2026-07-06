# pg559_spell_cast_gain_life_new_server XMage Batch PostgreSQL Package

Status: `applied_and_validated_by_evidence`.

This package was generated from XMage batch proposals. SQL was later executed
against the approved new-server PostgreSQL target and validated by the PG559
apply evidence report.

- Generated at: `2026-07-06T10:06:50+00:00`
- Selected cards: `["Contemplation", "Dawnhart Geist", "God-Pharaoh's Faithful", "Student of Ojutai"]`
- Families: `{"xmage_spell_cast_gain_life": 4}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg559_spell_cast_gain_life_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg559_spell_cast_gain_life_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg559_spell_cast_gain_life_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg559_spell_cast_gain_life_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg559_spell_cast_gain_life_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg559_spell_cast_gain_life_new_server_package_package.md`

Apply gate:

- Completed after explicit approval: precheck, apply, postcheck, PG -> SQLite
  sync, focused/family tests, E2E package validation, and final alignment
  audits.
- Evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg559_spell_cast_gain_life_new_server_apply_evidence.md`
