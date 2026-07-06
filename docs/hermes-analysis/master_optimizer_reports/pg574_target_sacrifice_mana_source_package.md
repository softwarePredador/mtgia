# pg574 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T21:33:00+00:00`
- Selected cards: `["Evendo Brushrazer", "Krark-Clan Stoker", "Skirk Prospector", "Thermopod", "Valleymaker"]`
- Families: `{"xmage_target_sacrifice_mana_source_permanent": 5}`

Files:

- precheck: `/tmp/pg574_target_sacrifice_mana_source_package_precheck.sql`
- apply: `/tmp/pg574_target_sacrifice_mana_source_package_apply.sql`
- rollback: `/tmp/pg574_target_sacrifice_mana_source_package_rollback.sql`
- postcheck: `/tmp/pg574_target_sacrifice_mana_source_package_postcheck.sql`
- manifest: `/tmp/pg574_target_sacrifice_mana_source_package_manifest.json`
- package: `/tmp/pg574_target_sacrifice_mana_source_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
