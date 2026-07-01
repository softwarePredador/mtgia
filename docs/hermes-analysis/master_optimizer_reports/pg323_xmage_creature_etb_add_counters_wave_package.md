# PG323 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T19:01:32+00:00`
- Selected cards: `["Backup Agent", "Bond Beetle", "Cultbrand Cinder", "Dauntless Survivor", "Iron Bully", "Ironpaw Aspirant", "Ironshell Beetle", "Jeong Jeong's Deserters", "Pith Driller", "Satyr Grovedancer", "Supply-Line Cranes"]`
- Families: `{"xmage_creature_etb_add_counters_target_creature": 11}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
