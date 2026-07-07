# pg601_static_filtered_count_pt_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-07T07:27:29+00:00`
- Selected cards: `["Drove of Elves", "Faerie Swarm", "Horde of Boggarts", "Keldon Warlord", "Kithkin Rabble", "Maraxus of Keld", "Matca Rioters", "Plague Rats", "Regal Bunnicorn", "Territorial Maro"]`
- Families: `{"xmage_static_source_power_toughness_equal_count": 10}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg601_static_filtered_count_pt_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg601_static_filtered_count_pt_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg601_static_filtered_count_pt_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg601_static_filtered_count_pt_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg601_static_filtered_count_pt_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg601_static_filtered_count_pt_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
