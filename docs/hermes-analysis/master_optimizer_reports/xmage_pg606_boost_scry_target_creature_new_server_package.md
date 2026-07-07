# PG606 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-07T09:19:10+00:00`
- Selected cards: `["Battlewise Valor", "Chain to Memory", "Cruel Finality", "Ferocious Charge", "Inordinate Rage", "Lose Hope", "Lost in a Labyrinth", "Stand Firm", "Titan's Strength"]`
- Families: `{"xmage_fixed_boost_scry_spell": 9}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg606_boost_scry_target_creature_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg606_boost_scry_target_creature_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg606_boost_scry_target_creature_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg606_boost_scry_target_creature_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg606_boost_scry_target_creature_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg606_boost_scry_target_creature_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
