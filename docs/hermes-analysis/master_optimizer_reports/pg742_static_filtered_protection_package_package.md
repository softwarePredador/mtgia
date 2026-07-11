# PG742 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-11T05:23:24+00:00`
- Selected cards: `["Enemy of the Guildpact", "Guardian of the Guildpact", "Mistmeadow Skulk", "Warren-Scourge Elf"]`
- Families: `{"xmage_static_self_protection_from_filtered_creature": 3, "xmage_static_self_protection_from_subtypes_creature": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg742_static_filtered_protection_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
