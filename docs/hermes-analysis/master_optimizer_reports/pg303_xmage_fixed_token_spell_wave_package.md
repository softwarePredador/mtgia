# PG303 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T12:13:56+00:00`
- Selected cards: `["Allied Reinforcements", "Call of the Conclave", "Captain's Call", "Dragon Fodder", "Elemental Summoning", "Flurry of Horns", "Goblin Rally", "Hive Stirrings", "Hop to It", "Hordeling Outburst", "Icatian Town", "Inkling Summoning", "Join the Ranks", "Krenko's Command", "Mass Production", "Master's Call", "Midnight Haunting", "Raise the Alarm", "Ral's Reinforcements", "Release the Dogs", "Revel of the Fallen God", "Spectral Procession", "Spirit Summoning", "Spore Swarm", "Sprout", "Take Up Arms", "Talrand's Invocation"]`
- Families: `{"xmage_fixed_create_creature_tokens_spell": 27}`
- PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_pg_apply_evidence.md`
- PG -> Hermes/SQLite sync evidence: `docs/hermes-analysis/master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_pg_to_sqlite_sync.json`
- E2E evidence: `docs/hermes-analysis/master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_e2e_validation.md`
- Final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg303_fixed_token_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg303_fixed_token_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg303_fixed_token_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg303_fixed_token_spell_wave.md`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_package.md`

Apply gate:

- Applied after explicit global PG authorization for this XMage all-card wave.
- Completed sequence: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, E2E validation, and alignment audits.
