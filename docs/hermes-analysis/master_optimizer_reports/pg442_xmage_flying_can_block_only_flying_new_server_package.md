# pg442 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T22:29:45+00:00`
- Selected cards: `["Belbe's Percher", "Cloud Djinn", "Cloud Dragon", "Cloud Elemental", "Cloud Pirates", "Cloud Spirit", "Cloud Sprite", "Hoverguard Observer", "Long-Finned Skywhale", "Rishadan Airship", "Scrapskin Drake", "Skywinder Drake", "Stratozeppelid", "Stronghold Zeppelin", "Tattered Haunter", "Vaporkin", "Wanderlight Spirit", "Welkin Tern"]`
- Families: `{"xmage_static_flying_can_block_only_flying_creature": 18}`

Files:

- precheck: `../../master_optimizer_reports/pg442_xmage_flying_can_block_only_flying_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg442_xmage_flying_can_block_only_flying_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg442_xmage_flying_can_block_only_flying_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg442_xmage_flying_can_block_only_flying_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg442_xmage_flying_can_block_only_flying_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg442_xmage_flying_can_block_only_flying_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
