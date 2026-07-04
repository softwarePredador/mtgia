# pg440 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T22:12:46+00:00`
- Selected cards: `["Amrou Scout", "Bogbrew Witch", "Burnished Hart", "Cateran Brute", "Cateran Kidnappers", "Cateran Persuader", "Dawntreader Elk", "Diligent Farmhand", "Embodiment of Spring", "Font of Fertility", "Frontier Guide", "Moggcatcher", "Neverwinter Dryad", "Oashra Cultivator", "Planar Bridge", "Ramosian Commander", "Ramosian Lieutenant", "Ramosian Sergeant", "Seahunter", "Skyshroud Poacher", "Whisper Squad"]`
- Families: `{"xmage_permanent_simple_activated_library_search_to_battlefield": 21}`

Files:

- precheck: `../../master_optimizer_reports/pg440_xmage_activated_tutor_battlefield_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg440_xmage_activated_tutor_battlefield_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg440_xmage_activated_tutor_battlefield_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg440_xmage_activated_tutor_battlefield_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg440_xmage_activated_tutor_battlefield_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg440_xmage_activated_tutor_battlefield_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
