# PG594 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-07T04:56:26+00:00`
- Selected cards: `["Abzan Devotee", "Jeskai Devotee", "Sultai Devotee", "Temur Devotee"]`
- Families: `{"xmage_limited_times_color_choice_mana_source_permanent": 4}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg594_limited_times_color_choice_mana_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg594_limited_times_color_choice_mana_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg594_limited_times_color_choice_mana_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg594_limited_times_color_choice_mana_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg594_limited_times_color_choice_mana_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg594_limited_times_color_choice_mana_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
