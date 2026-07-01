# PG304 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T12:30:04+00:00`
- Selected cards: `["Ambassador Oak", "Aviation Pioneer", "Bear's Companion", "Beetleback Chief", "Clarion Cathars", "Daysquad Marshal", "Dragon Trainer", "Eager Glyphmage", "Elder Auntie", "Elderleaf Mentor", "Enlightened Maniac", "Ferocious Pup", "Ghirapur Gearcrafter", "Goblin Gang Leader", "Goblin Instigator", "Head of the Homestead", "Kyoshi Warriors", "Mechanized Ninja Cavalry", "Nimble Thopterist", "Protector of Gondor", "Seller of Songbirds", "Silvergill Mentor", "Sourbread Auntie", "Tunnel Surveyor", "Urbis Protector", "Watchful Giant", "Yavimaya Sapherd"]`
- Families: `{"xmage_creature_etb_create_tokens": 27}`
- PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg304_xmage_creature_etb_token_wave_pg_apply_evidence.md`
- PG -> Hermes/SQLite sync evidence: `docs/hermes-analysis/master_optimizer_reports/pg304_xmage_creature_etb_token_wave_pg_to_sqlite_sync.json`
- E2E evidence: `docs/hermes-analysis/master_optimizer_reports/pg304_xmage_creature_etb_token_wave_e2e_validation.md`
- Final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg304_creature_etb_token_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg304_creature_etb_token_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg304_creature_etb_token_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg304_creature_etb_token_wave.md`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg304_xmage_creature_etb_token_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg304_xmage_creature_etb_token_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg304_xmage_creature_etb_token_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg304_xmage_creature_etb_token_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg304_xmage_creature_etb_token_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg304_xmage_creature_etb_token_wave_package.md`

Apply gate:

- Applied after explicit global PG authorization for this XMage all-card wave.
- Completed sequence: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, E2E validation, and alignment audits.
