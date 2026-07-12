# pg800 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-12T01:58:48+00:00`
- Selected cards: `["Aysen Crusader"]`
- Families: `{"xmage_static_source_power_toughness_equal_count": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg800_static_count_base_subtypes_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg800_static_count_base_subtypes_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg800_static_count_base_subtypes_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg800_static_count_base_subtypes_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg800_static_count_base_subtypes_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg800_static_count_base_subtypes_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
