# pg801 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-12T02:21:03+00:00`
- Selected cards: `["Abomination of Llanowar", "Ancient Ooze", "Awakened Amalgam", "Primalcrux", "Soulless One", "Umbra Stalker"]`
- Families: `{"xmage_static_source_power_toughness_equal_count": 6}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg801_static_count_extended_dynamic_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg801_static_count_extended_dynamic_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg801_static_count_extended_dynamic_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg801_static_count_extended_dynamic_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg801_static_count_extended_dynamic_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg801_static_count_extended_dynamic_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
