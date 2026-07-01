# PG316 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T16:17:25+00:00`
- Selected cards: `["Bloodtallow Candle", "Cabal Trainee", "Child of Thorns", "Elven Lyre", "Nim Replica", "Phyrexian Defiler", "Phyrexian Denouncer", "Seal of Strength", "Shield Mate"]`
- Families: `{"xmage_permanent_simple_activated_target_boost_until_eot": 9}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
