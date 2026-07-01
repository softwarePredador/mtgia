# PG301 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals, applied to PostgreSQL,
synced to Hermes SQLite, and validated end to end.

- Generated at: `2026-07-01T11:34:23+00:00`
- Selected cards: `["Aven Fisher", "Buzz Bots", "Darkslick Drake", "Exultant Cultist", "Feral Prowler", "Ithilien Kingfisher", "Kingfisher", "Malcator's Watcher", "Messenger Drake", "Oculus", "Outlaw Medic", "Palace Familiar", "Purple-Crystal Crab", "Riptide Crab", "Runewing", "Silverback Shaman", "Spore Crawler", "Summit Sentinel", "Surveilling Sprite", "Youthful Scholar"]`
- Families: `{"xmage_creature_dies_draw_cards": 20}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_package.md`
- PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_pg_apply_evidence.md`
- PG -> SQLite sync evidence: `docs/hermes-analysis/master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_pg_to_sqlite_sync.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_e2e_validation.md`

Apply result:

- PostgreSQL precheck: `20/20` target card rows found, `0` expected rows already present, `0` shadow rows scheduled for deprecation.
- PostgreSQL postcheck: `20/20` promoted rows, `20/20` verified/auto rows, `20/20` matching Oracle hash rows, `0` backup rows.
- PG -> Hermes/SQLite sync: PostgreSQL rows loaded `6752`, SQLite inserted/updated `6546`, canonical snapshot rows `4365`.
- E2E validation: PostgreSQL `20/20`, SQLite `20/20`, canonical snapshot `20/20`, runtime `get_card_effect` `20/20`.
