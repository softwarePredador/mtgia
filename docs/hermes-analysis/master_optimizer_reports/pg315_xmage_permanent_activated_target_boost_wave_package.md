# PG315 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T16:00:46+00:00`
- Selected cards: `["Aquus Steed", "Captive Flame", "Devotee of Strength", "Flowstone Overseer", "Ghitu War Cry", "Ghost Warden", "Ghosts of the Damned", "Grandmother Sengir", "Hagra Sharpshooter", "Icatian Priest", "Nantuko Disciple", "Sacred Armory", "Saltfield Recluse", "Smokespew Invoker", "Staff of Zegon", "Thriss, Nantuko Primus", "Tower of Champions", "Ursapine", "Wyluli Wolf"]`
- Families: `{"xmage_permanent_simple_activated_target_boost_until_eot": 19}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
