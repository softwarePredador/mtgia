# PG145 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T05:50:34+00:00`
- Selected cards: `["Treasure Vault"]`
- Families: `{"treasure_maker": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg145_treasure_vault_x_treasure_land_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg145_treasure_vault_x_treasure_land_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg145_treasure_vault_x_treasure_land_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg145_treasure_vault_x_treasure_land_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg145_treasure_vault_x_treasure_land_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg145_treasure_vault_x_treasure_land_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
