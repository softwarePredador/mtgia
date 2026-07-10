# PG724 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-10T22:14:12+00:00`
- Selected cards: `["Face of Fear"]`
- Families: `{"xmage_permanent_simple_activated_self_keyword_until_eot": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg724_face_of_fear_self_keyword_discard_cost_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
