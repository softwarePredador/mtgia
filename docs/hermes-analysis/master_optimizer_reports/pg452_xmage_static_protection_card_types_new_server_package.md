# pg452 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T23:44:35+00:00`
- Selected cards: `["Angelic Curator", "Azorius First-Wing", "Beloved Chaplain", "Commander Eesha", "Horizon Drake", "Nacatl Savage", "Needlebug", "Tel-Jilad Archers", "Tel-Jilad Chosen", "Tel-Jilad Outrider", "Yavimaya Scion"]`
- Families: `{"xmage_static_self_protection_from_card_types_creature": 11}`

Files:

- precheck: `../../master_optimizer_reports/pg452_xmage_static_protection_card_types_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg452_xmage_static_protection_card_types_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg452_xmage_static_protection_card_types_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg452_xmage_static_protection_card_types_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg452_xmage_static_protection_card_types_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg452_xmage_static_protection_card_types_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
