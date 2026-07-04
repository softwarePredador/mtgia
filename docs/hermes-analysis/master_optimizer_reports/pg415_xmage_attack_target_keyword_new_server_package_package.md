# PG415 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T16:41:58+00:00`
- Selected cards: `["Aerial Guide", "Chasm Drake", "Garrison Griffin", "Heavenly Qilin", "Kinsbaile Balloonist", "Majestic Heliopterus", "Pegasus Courser", "Roc Charger", "Trailblazing Historian", "Trained Condor", "Trusted Pegasus"]`
- Families: `{"xmage_creature_attack_target_keyword_until_eot": 10, "xmage_permanent_simple_activated_target_keyword_until_eot": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg415_xmage_attack_target_keyword_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg415_xmage_attack_target_keyword_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg415_xmage_attack_target_keyword_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg415_xmage_attack_target_keyword_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg415_xmage_attack_target_keyword_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg415_xmage_attack_target_keyword_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
