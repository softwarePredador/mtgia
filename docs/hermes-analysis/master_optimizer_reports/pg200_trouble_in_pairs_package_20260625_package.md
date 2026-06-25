# pg200 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-25T02:55:47+00:00`
- Selected cards: `["Trouble in Pairs"]`
- Families: `{"draw_engine": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg200_trouble_in_pairs_package_20260625_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg200_trouble_in_pairs_package_20260625_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg200_trouble_in_pairs_package_20260625_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg200_trouble_in_pairs_package_20260625_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg200_trouble_in_pairs_package_20260625_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg200_trouble_in_pairs_package_20260625_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
