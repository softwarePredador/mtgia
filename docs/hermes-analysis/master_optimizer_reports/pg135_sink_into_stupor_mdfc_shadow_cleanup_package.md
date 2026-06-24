# PG135 XMage Batch PostgreSQL Package

Status: `applied_postchecked_synced_validated`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-24T01:24:27+00:00`
- Selected cards: `["Sink into Stupor"]`
- Families: `{"targeted_interaction": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg135_sink_into_stupor_mdfc_shadow_cleanup_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg135_sink_into_stupor_mdfc_shadow_cleanup_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg135_sink_into_stupor_mdfc_shadow_cleanup_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg135_sink_into_stupor_mdfc_shadow_cleanup_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg135_sink_into_stupor_mdfc_shadow_cleanup_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg135_sink_into_stupor_mdfc_shadow_cleanup_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
