# PG314 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T15:44:33+00:00`
- Selected cards: `["Akki Drillmaster", "Caller of Gales", "Elvish Herder", "Flying Carpet", "Fyndhorn Bow", "Icatian Scout", "Iron Lance", "Keen Glidemaster", "Noble Steeds", "Taxi Driver", "War Chariot", "Zephyr Charge"]`
- Families: `{"xmage_permanent_simple_activated_target_keyword_until_eot": 12}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
