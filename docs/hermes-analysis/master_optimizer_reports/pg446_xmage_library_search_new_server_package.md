# pg446 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T23:01:07+00:00`
- Selected cards: `["Call the Gatewatch", "Cateran Summons", "Diabolic Tutor", "Eerie Procession", "Ignite the Beacon", "Merchant Scroll", "Open the Armory", "Plea for Guidance", "Safewright Quest", "Sarkhan's Triumph", "Seek the Horizon", "Solve the Equation", "Time of Need", "Trapmaker's Snare"]`
- Families: `{"xmage_library_search_spell": 14}`

Files:

- precheck: `../../master_optimizer_reports/pg446_xmage_library_search_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg446_xmage_library_search_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg446_xmage_library_search_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg446_xmage_library_search_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg446_xmage_library_search_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg446_xmage_library_search_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
