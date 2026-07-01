# PG302 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals, applied to PostgreSQL,
synced to Hermes SQLite, and validated end to end.

- Generated at: `2026-07-01T11:48:51+00:00`
- Selected cards: `["Akoum Boulderfoot", "Blisterstick Shaman", "Corrupt Eunuchs", "Fire Imp", "Flametongue Kavu", "Goblin Commando", "Skeleton Archer", "Sparkmage Apprentice"]`
- Families: `{"xmage_creature_etb_fixed_damage_target": 8}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_package.md`
- PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_pg_apply_evidence.md`
- PG -> SQLite sync evidence: `docs/hermes-analysis/master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_pg_to_sqlite_sync.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_e2e_validation.md`
- XMage strategy audit: `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg302_creature_etb_damage_wave.md`
- operational surface audit: `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg302_creature_etb_damage_wave.md`
- PG/Hermes/SQLite contract audit: `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg302_creature_etb_damage_wave.md`
- legacy contamination audit: `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg302_creature_etb_damage_wave.md`

Apply result:

- PostgreSQL precheck: `8/8` target card rows found, `0` expected rows already present, `0` shadow rows scheduled for deprecation.
- PostgreSQL postcheck: `8/8` promoted rows, `8/8` verified/auto rows, `8/8` matching Oracle hash rows, `0` backup rows.
- PG -> Hermes/SQLite sync: PostgreSQL rows loaded `6760`, SQLite inserted/updated `6554`, canonical snapshot rows `4373`.
- E2E validation: PostgreSQL `8/8`, SQLite `8/8`, canonical snapshot `8/8`, runtime `get_card_effect` `8/8`.
- Final audits: XMage strategy `26/26` pass; operational surface `pass`; PG/Hermes/SQLite contract `48` pass and `1` known warning; legacy contamination `pass`.
