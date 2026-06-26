# PG240 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-26T10:40:58+00:00`
- Selected cards: `["Bolt Bend"]`
- Families: `{"targeted_interaction": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg240_bolt_bend_redirect_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg240_bolt_bend_redirect_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg240_bolt_bend_redirect_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg240_bolt_bend_redirect_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg240_bolt_bend_redirect_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg240_bolt_bend_redirect_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
