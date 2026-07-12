# PG851 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-12T23:34:44+00:00`
- Selected cards: `["Ambassador Laquatus", "Cathartic Adept", "Drowner of Secrets", "Hair-Strung Koto", "Merfolk Mesmerist", "Millstone", "Tower of Murmurs", "Vedalken Entrancer"]`
- Families: `{"xmage_permanent_simple_activated_target_player_mill": 8}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
