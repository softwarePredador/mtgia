# PG608 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-07T10:08:06+00:00`
- Selected cards: `["Aerial Predation", "Dark Offering", "Eriette's Lullaby", "Lucky Offering", "Noxious Grasp", "Poison Arrow", "Radiant Strike", "Silverstrike", "Surge of Righteousness", "Triumphant Surge"]`
- Families: `{"xmage_destroy_target_gain_life_spell": 10}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg608_destroy_gain_life_target_variants_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg608_destroy_gain_life_target_variants_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg608_destroy_gain_life_target_variants_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg608_destroy_gain_life_target_variants_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg608_destroy_gain_life_target_variants_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg608_destroy_gain_life_target_variants_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
