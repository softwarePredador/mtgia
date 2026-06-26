# PG236 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-26T09:10:55+00:00`
- Selected cards: `["Authority of the Consuls"]`
- Families: `{"passive": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg236_authority_of_the_consuls_exact_scope_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg236_authority_of_the_consuls_exact_scope_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg236_authority_of_the_consuls_exact_scope_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg236_authority_of_the_consuls_exact_scope_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg236_authority_of_the_consuls_exact_scope_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg236_authority_of_the_consuls_exact_scope_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
