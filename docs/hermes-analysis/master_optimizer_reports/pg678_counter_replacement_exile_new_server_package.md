# PG678 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-09T00:03:13+00:00`
- Selected cards: `["Assert Authority", "Deny Existence", "Deny the Divine", "Dissipate", "Faerie Trickery", "Horribly Awry", "Liquify", "Void Shatter"]`
- Families: `{"xmage_counter_target_exile_replacement_spell": 8}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg678_counter_replacement_exile_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg678_counter_replacement_exile_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg678_counter_replacement_exile_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg678_counter_replacement_exile_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg678_counter_replacement_exile_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg678_counter_replacement_exile_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
