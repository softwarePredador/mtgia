# PG397 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T09:31:52+00:00`
- Selected cards: `["Aven Archer", "Crimson Manticore", "Cunning Sparkmage", "Dive Bomber", "Divebomber Griffin", "Fanatical Firebrand", "Jeska, Warrior Adept", "Kamahl, Pit Fighter", "Mawcor", "Sarpadian Simulacrum", "Scaldkin", "Shivan Hellkite", "Skyway Sniper", "Stinging Barrier", "Storm Spirit", "Thornwind Faeries", "Vulshok Sorcerer"]`
- Families: `{"xmage_permanent_simple_activated_damage": 17}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg397_activated_damage_keywords_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg397_activated_damage_keywords_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg397_activated_damage_keywords_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg397_activated_damage_keywords_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg397_activated_damage_keywords_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg397_activated_damage_keywords_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
