# PG307 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals and later promoted by the
master optimizer apply flow.

- Generated at: `2026-07-01T13:13:17+00:00`
- Selected cards: `["Appetite for the Unnatural", "Cursebreak", "Drain the Well", "Grapple with Death", "Invoke the Divine", "Lich's Caress", "Maw of the Mire", "Natural End", "Ray of Dissolution", "Sanctify", "Sephiroth's Intervention", "Solemn Offering", "Springsage Ritual"]`
- Families: `{"xmage_destroy_target_gain_life_spell": 13}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_package.md`
- PG apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_pg_apply_evidence.md`
- PG -> Hermes/SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_pg_to_sqlite_sync.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_e2e_validation.md`

Evidence:

- PostgreSQL apply evidence reports `13/13` promoted rule rows,
  `13/13` verified/auto rows and `13/13` Oracle hash matches.
- PG -> Hermes/SQLite sync loaded `6867` PostgreSQL rows, inserted/updated
  `6661` SQLite rows, and exported `4475` canonical snapshot rows.
- E2E validation reports pass for PostgreSQL source of truth, SQLite Hermes
  cache, canonical snapshot fallback and runtime `get_card_effect`.
- Final alignment audits report XMage strategy `26/26` pass, operational
  surface `pass`, PG/Hermes/SQLite contract `48` pass with `1` known warning,
  and legacy contamination `pass`.
- Local focused tests passed:
  `test_xmage_authoritative_exact_scope_split.py` (`81` tests) and
  `test_xmage_exact_scope_runtime.py` (`40` tests).
