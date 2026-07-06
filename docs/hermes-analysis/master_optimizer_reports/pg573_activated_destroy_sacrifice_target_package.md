# pg573 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T21:11:01+00:00`
- Selected cards: `["Army Ants", "Attrition", "Aura Fracture", "Elvish Skysweeper", "Shivan Harvest", "Stronghold Assassin"]`
- Families: `{"xmage_permanent_simple_activated_destroy_target": 6}`

Files:

- precheck: `/tmp/pg573_activated_destroy_sacrifice_target_package_precheck.sql`
- apply: `/tmp/pg573_activated_destroy_sacrifice_target_package_apply.sql`
- rollback: `/tmp/pg573_activated_destroy_sacrifice_target_package_rollback.sql`
- postcheck: `/tmp/pg573_activated_destroy_sacrifice_target_package_postcheck.sql`
- manifest: `/tmp/pg573_activated_destroy_sacrifice_target_package_manifest.json`
- package: `/tmp/pg573_activated_destroy_sacrifice_target_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
