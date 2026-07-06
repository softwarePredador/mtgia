# pg575 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T21:54:52+00:00`
- Selected cards: `["Astrolabe", "Barbed Sextant", "Buried Treasure", "Darkwater Egg", "Generator Servant", "Golden Egg", "Kaleidostone", "Lotus Bloom", "Mossfire Egg", "Omni-Cheese Pizza", "Shadowblood Egg", "Skycloud Egg", "Sungrass Egg", "Terrarion", "Verdant Eidolon"]`
- Families: `{"xmage_self_sacrifice_mana_source_permanent": 15}`

Files:

- precheck: `/tmp/pg575_self_sacrifice_mana_source_auxiliary_package_precheck.sql`
- apply: `/tmp/pg575_self_sacrifice_mana_source_auxiliary_package_apply.sql`
- rollback: `/tmp/pg575_self_sacrifice_mana_source_auxiliary_package_rollback.sql`
- postcheck: `/tmp/pg575_self_sacrifice_mana_source_auxiliary_package_postcheck.sql`
- manifest: `/tmp/pg575_self_sacrifice_mana_source_auxiliary_package_manifest.json`
- package: `/tmp/pg575_self_sacrifice_mana_source_auxiliary_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
