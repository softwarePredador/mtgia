# PG166 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T11:10:14+00:00`
- Selected cards: `["Copy Enchantment", "Mirrormade", "Phyrexian Metamorph", "Clever Impersonator", "Copy Artifact"]`
- Families: `{"copy_permanent_etb": 5}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg166_copy_permanent_etb_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg166_copy_permanent_etb_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg166_copy_permanent_etb_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg166_copy_permanent_etb_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg166_copy_permanent_etb_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg166_copy_permanent_etb_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
