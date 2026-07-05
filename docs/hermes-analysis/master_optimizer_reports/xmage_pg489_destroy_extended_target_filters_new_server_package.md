# PG489 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T07:16:56+00:00`
- Selected cards: `["Cast Down", "Chill to the Bone", "Eyeblight's Ending", "Goblin Digging Team", "Human Frailty", "Power Word Kill", "Puncturing Light", "Rend Flesh", "Rend Spirit", "Searing Light", "Terashi's Verdict", "Tunnel", "Urgent Exorcism", "Victim of Night", "Walk the Plank"]`
- Families: `{"xmage_destroy_target_spell": 14, "xmage_permanent_simple_activated_destroy_target": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg489_destroy_extended_target_filters_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg489_destroy_extended_target_filters_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg489_destroy_extended_target_filters_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg489_destroy_extended_target_filters_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg489_destroy_extended_target_filters_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg489_destroy_extended_target_filters_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
