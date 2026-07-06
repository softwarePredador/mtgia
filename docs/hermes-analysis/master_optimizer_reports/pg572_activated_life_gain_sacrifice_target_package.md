# pg572 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T20:52:22+00:00`
- Selected cards: `["Claws of Gix", "Dark Heart of the Wood", "Gutless Ghoul", "Overgrown Estate", "Ravenous Baloth", "Starved Rusalka"]`
- Families: `{"xmage_permanent_simple_activated_life_gain": 6}`

Files:

- precheck: `/tmp/pg572_activated_life_gain_sacrifice_target_package_precheck.sql`
- apply: `/tmp/pg572_activated_life_gain_sacrifice_target_package_apply.sql`
- rollback: `/tmp/pg572_activated_life_gain_sacrifice_target_package_rollback.sql`
- postcheck: `/tmp/pg572_activated_life_gain_sacrifice_target_package_postcheck.sql`
- manifest: `/tmp/pg572_activated_life_gain_sacrifice_target_package_manifest.json`
- package: `/tmp/pg572_activated_life_gain_sacrifice_target_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
