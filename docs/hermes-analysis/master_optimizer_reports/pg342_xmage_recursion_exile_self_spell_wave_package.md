# PG342 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_validated`.

This package was generated from XMage batch proposals, then applied through
precheck -> apply -> postcheck, synced from PostgreSQL to Hermes SQLite, and
validated end-to-end.

- Generated at: `2026-07-02T01:00:27+00:00`
- Selected cards: `["Reconstruct History", "Retrieve", "Vivid Revival"]`
- Families: `{"xmage_graveyard_to_hand_exile_self_spell": 1, "xmage_graveyard_to_hand_multi_component_exile_self_spell": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_package.md`

Validation evidence:

- precheck evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_precheck_evidence.md`
- apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_apply_evidence.md`
- postcheck evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_postcheck_evidence.md`
- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_pg_to_sqlite_sync.json`
- E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_e2e_validation.md`
