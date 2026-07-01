# PG322 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T18:35:52+00:00`
- Selected cards: `["Banners Raised", "Bar the Door", "Burn Bright", "Charge", "Chorus of Woe", "Desperate Charge", "Ethereal Guidance", "Glorious Charge", "Inspired Charge", "Path of Anger's Flame", "Righteous Charge", "Scare Tactics", "Shield Wall", "Solidarity", "Steadfastness", "Virtuous Charge", "Vitalizing Wind", "Warrior's Charge", "Warrior's Honor"]`
- Families: `{"xmage_boost_controlled_creatures_until_eot_spell": 19}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
