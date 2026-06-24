# PG169 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T11:35:02+00:00`
- Selected cards: `["Exotic Orchard"]`
- Families: `{"land": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg169_exotic_orchard_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg169_exotic_orchard_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg169_exotic_orchard_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg169_exotic_orchard_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg169_exotic_orchard_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg169_exotic_orchard_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
