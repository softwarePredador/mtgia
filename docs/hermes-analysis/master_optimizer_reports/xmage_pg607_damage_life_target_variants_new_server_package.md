# PG607 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-07T09:50:59+00:00`
- Selected cards: `["Deadly Riposte", "Joust Through", "Kiss of Death", "Sorin's Vengeance", "Soul Shred", "Soul Spike", "Spinning Darkness", "Stolen Grain", "Taste of Blood", "Vampiric Touch"]`
- Families: `{"xmage_fixed_damage_gain_life_spell": 10}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg607_damage_life_target_variants_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg607_damage_life_target_variants_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg607_damage_life_target_variants_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg607_damage_life_target_variants_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg607_damage_life_target_variants_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg607_damage_life_target_variants_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
